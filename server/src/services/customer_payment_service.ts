import type Stripe from "stripe";

import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";
import { stripe } from "../lib/stripe.ts";

export interface CustomerPaymentIntentResult {
  alreadyPaid: boolean;
  clientSecret?: string;
  paymentIntentId?: string;
}

export interface CustomerPaymentSyncResult {
  paid: boolean;
  orderStatus: string;
  paymentStatus: string;
  paymentIntentStatus?: string;
}

export async function createCustomerPaymentIntent(
  input: {
    orderId: string;
    userId: string;
  },
): Promise<CustomerPaymentIntentResult> {
  const order =
    await prisma.order.findFirst({
      where: {
        id: input.orderId,
        userId: input.userId,
      },
      include: {
        user: {
          select: {
            email: true,
          },
        },
      },
    });

  if (!order) {
    throw new AppError(
      404,
      "订单不存在",
      "ORDER_NOT_FOUND",
    );
  }

  if (
    order.paymentStatus === "PAID" ||
    order.status === "PAID"
  ) {
    return {
      alreadyPaid: true,
      paymentIntentId:
        order.paymentIntentId ?? undefined,
    };
  }

  if (
    order.paymentMethod ===
    "CASH_ON_DELIVERY"
  ) {
    throw new AppError(
      409,
      "货到付款订单不需要在线付款",
      "ORDER_DOES_NOT_REQUIRE_ONLINE_PAYMENT",
    );
  }

  if (
    order.status !== "PENDING_PAYMENT"
  ) {
    throw new AppError(
      409,
      "当前订单状态不允许付款",
      "ORDER_NOT_PAYABLE",
    );
  }

  if (order.paymentIntentId) {
    const existingIntent =
      await stripe.paymentIntents.retrieve(
        order.paymentIntentId,
      );

    if (
      existingIntent.status === "succeeded"
    ) {
      await markOrderPaid(
        existingIntent,
      );

      return {
        alreadyPaid: true,
        paymentIntentId:
          existingIntent.id,
      };
    }

    if (
      existingIntent.status !== "canceled" &&
      existingIntent.client_secret
    ) {
      return {
        alreadyPaid: false,
        clientSecret:
          existingIntent.client_secret,
        paymentIntentId:
          existingIntent.id,
      };
    }

    throw new AppError(
      409,
      "原付款已取消，请联系管理员重新建立付款",
      "PAYMENT_INTENT_CANCELLED",
    );
  }

  const paymentIntent =
    await stripe.paymentIntents.create(
      {
        amount: order.totalMinor,
        currency:
          order.currency.toLowerCase(),

        automatic_payment_methods: {
          enabled: true,
        },

        receipt_email:
          order.user.email,

        description:
          `订单 ${order.orderNumber}`,

        metadata: {
          orderId: order.id,
          orderNumber:
            order.orderNumber,
          userId: order.userId,
        },

        shipping: {
          name: order.recipientName,
          phone:
            order.recipientPhone,
          address: {
            line1:
              order.addressLine1,
            line2:
              order.addressLine2 ??
              undefined,
            city: order.city,
            state: order.state,
            postal_code:
              order.postalCode,
            country:
              order.countryCode,
          },
        },
      },
      {
        idempotencyKey:
          `order-payment-intent:${order.id}`,
      },
    );

  if (!paymentIntent.client_secret) {
    throw new AppError(
      502,
      "Stripe 没有返回付款凭证",
      "STRIPE_CLIENT_SECRET_MISSING",
    );
  }

  await prisma.order.update({
    where: {
      id: order.id,
    },
    data: {
      paymentIntentId:
        paymentIntent.id,
    },
  });

  return {
    alreadyPaid: false,
    clientSecret:
      paymentIntent.client_secret,
    paymentIntentId:
      paymentIntent.id,
  };
}

export async function syncCustomerPaymentStatus(
  input: {
    orderId: string;
    userId: string;
  },
): Promise<CustomerPaymentSyncResult> {
  const order =
    await prisma.order.findFirst({
      where: {
        id: input.orderId,
        userId: input.userId,
      },
      select: {
        id: true,
        status: true,
        paymentStatus: true,
        paymentMethod: true,
        paymentIntentId: true,
      },
    });

  if (!order) {
    throw new AppError(
      404,
      "订单不存在",
      "ORDER_NOT_FOUND",
    );
  }

  if (
    order.paymentStatus === "PAID" ||
    order.status === "PAID"
  ) {
    return {
      paid: true,
      orderStatus: order.status,
      paymentStatus:
        order.paymentStatus,
    };
  }

  if (
    order.paymentMethod ===
    "CASH_ON_DELIVERY"
  ) {
    throw new AppError(
      409,
      "货到付款订单不需要在线付款",
      "ORDER_DOES_NOT_REQUIRE_ONLINE_PAYMENT",
    );
  }

  if (!order.paymentIntentId) {
    throw new AppError(
      409,
      "订单还没有建立 Stripe 付款",
      "PAYMENT_INTENT_NOT_CREATED",
    );
  }

  const paymentIntent =
    await stripe.paymentIntents.retrieve(
      order.paymentIntentId,
    );

  switch (paymentIntent.status) {
    case "succeeded": {
      await markOrderPaid(paymentIntent);
      break;
    }

    case "processing": {
      await updatePaymentStatus(
        paymentIntent,
        "PROCESSING",
      );
      break;
    }

    case "canceled":
    case "requires_payment_method": {
      await updatePaymentStatus(
        paymentIntent,
        "FAILED",
      );
      break;
    }

    default:
      break;
  }

  const updatedOrder =
    await prisma.order.findUnique({
      where: {
        id: order.id,
      },
      select: {
        status: true,
        paymentStatus: true,
      },
    });

  if (!updatedOrder) {
    throw new AppError(
      404,
      "订单不存在",
      "ORDER_NOT_FOUND",
    );
  }

  return {
    paid:
      updatedOrder.paymentStatus ===
        "PAID" ||
      updatedOrder.status === "PAID",
    orderStatus:
      updatedOrder.status,
    paymentStatus:
      updatedOrder.paymentStatus,
    paymentIntentStatus:
      paymentIntent.status,
  };
}

export async function handleStripeEvent(
  event: Stripe.Event,
): Promise<void> {
  switch (event.type) {
    case "payment_intent.succeeded": {
      await markOrderPaid(
        event.data.object,
      );
      return;
    }

    case "payment_intent.processing": {
      await updatePaymentStatus(
        event.data.object,
        "PROCESSING",
      );
      return;
    }

    case "payment_intent.payment_failed":
    case "payment_intent.canceled": {
      await updatePaymentStatus(
        event.data.object,
        "FAILED",
      );
      return;
    }

    default:
      return;
  }
}

async function markOrderPaid(
  paymentIntent:
    Stripe.PaymentIntent,
): Promise<void> {
  const order =
    await findOrderForPaymentIntent(
      paymentIntent,
    );

  if (!order) {
    console.warn(
      `找不到 Stripe PaymentIntent 对应订单：${paymentIntent.id}`,
    );
    return;
  }

  const receivedAmount =
    paymentIntent.amount_received;

  if (
    paymentIntent.currency.toUpperCase() !==
      order.currency ||
    receivedAmount < order.totalMinor
  ) {
    console.error(
      "Stripe 付款金额或币种与订单不一致",
      {
        orderId: order.id,
        paymentIntentId:
          paymentIntent.id,
        expectedAmount:
          order.totalMinor,
        receivedAmount,
        expectedCurrency:
          order.currency,
        receivedCurrency:
          paymentIntent.currency,
      },
    );
    return;
  }

  await prisma.$transaction(
    async (transaction) => {
      /*
       * 只有仍处于待付款并且尚未标记为已付款的订单
       * 才能完成一次库存转换。
       * 重复 webhook 不会重复扣库存或增加销量。
       */
      const updated =
        await transaction.order
          .updateMany({
            where: {
              id: order.id,
              status:
                "PENDING_PAYMENT",
              paymentStatus: {
                not: "PAID",
              },
            },
            data: {
              paymentIntentId:
                paymentIntent.id,
              paymentStatus: "PAID",
              status: "PROCESSING",
              paidAt: new Date(),
              reservationExpiresAt:
                null,
            },
          });

      if (updated.count !== 1) {
        return;
      }

      /*
       * 新订单拥有 reservationExpiresAt，表示创建订单时
       * 只锁定 reservedStock，还没有扣减真实 stock。
       * 旧订单没有该字段值，库存已经在创建订单时扣过。
       */
      const usesReservedStock =
        order.reservationExpiresAt !==
        null;

      for (const item of order.items) {
        if (!usesReservedStock) {
          await transaction.product.update({
            where: {
              id: item.productId,
            },
            data: {
              sold: {
                increment:
                  item.quantity,
              },
            },
          });

          continue;
        }

        const updatedCount =
          await transaction.$executeRaw`
            UPDATE "Product"
            SET
              "stock" = "stock" - ${item.quantity},
              "reservedStock" = "reservedStock" - ${item.quantity},
              "sold" = "sold" + ${item.quantity}
            WHERE "id" = ${item.productId}
              AND "stock" >= ${item.quantity}
              AND "reservedStock" >= ${item.quantity}
          `;

        if (Number(updatedCount) !== 1) {
          throw new AppError(
            409,
            "锁定库存资料异常，无法完成付款订单",
            "RESERVED_STOCK_INCONSISTENT",
          );
        }

        const updatedProduct =
          await transaction.product
            .findUnique({
              where: {
                id: item.productId,
              },
              select: {
                stock: true,
              },
            });

        if (!updatedProduct) {
          throw new AppError(
            500,
            "付款后读取商品库存失败",
            "PAID_ORDER_STOCK_READ_FAILED",
          );
        }

        await transaction
          .inventoryMovement
          .create({
            data: {
              productId:
                item.productId,
              type: "STOCK_OUT",
              quantityDelta:
                -item.quantity,
              stockBefore:
                updatedProduct.stock +
                item.quantity,
              stockAfter:
                updatedProduct.stock,
              note:
                `订单 ${order.orderNumber} 付款成功，扣减锁定库存`,
              createdByUserId:
                order.userId,
            },
          });
      }
    },
  );
}

async function updatePaymentStatus(
  paymentIntent:
    Stripe.PaymentIntent,
  status:
    | "PROCESSING"
    | "FAILED",
): Promise<void> {
  const order =
    await findOrderForPaymentIntent(
      paymentIntent,
    );

  if (!order) {
    return;
  }

  await prisma.order.updateMany({
    where: {
      id: order.id,
      paymentStatus: {
        not: "PAID",
      },
    },
    data: {
      paymentIntentId:
        paymentIntent.id,
      paymentStatus: status,
    },
  });
}

async function findOrderForPaymentIntent(
  paymentIntent:
    Stripe.PaymentIntent,
) {
  const metadataOrderId =
    paymentIntent.metadata.orderId;

  const orderId =
    typeof metadataOrderId === "string" &&
    metadataOrderId.trim().length > 0
      ? metadataOrderId.trim()
      : undefined;

  return prisma.order.findFirst({
    where: {
      OR: [
        {
          paymentIntentId:
            paymentIntent.id,
        },
        ...(orderId
          ? [
              {
                id: orderId,
              },
            ]
          : []),
      ],
    },
    include: {
      items: {
        select: {
          productId: true,
          quantity: true,
        },
      },
    },
  });
}