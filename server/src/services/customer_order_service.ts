import { randomUUID } from "node:crypto";

import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";
import { stripe } from "../lib/stripe.ts";

const PAYMENT_RESERVATION_MINUTES = 30;

export type CustomerShippingMethod =
  | "STANDARD"
  | "EXPRESS";

export type CustomerPaymentMethod =
  | "ONLINE_BANKING"
  | "CARD"
  | "CASH_ON_DELIVERY";

export interface CreateOrderItemInput {
  productId: string;
  quantity: number;
}

export interface CreateCustomerOrderInput {
  userId: string;
  items: CreateOrderItemInput[];

  shippingMethod: CustomerShippingMethod;
  paymentMethod: CustomerPaymentMethod;

  recipientName: string;
  recipientPhone: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  countryCode?: string;
  customerNote?: string;
}

export async function createCustomerOrder(
  input: CreateCustomerOrderInput,
) {
  const items = normalizeOrderItems(
    input.items,
  );

  const shippingMethod =
    normalizeShippingMethod(
      input.shippingMethod,
    );

  const paymentMethod =
    normalizePaymentMethod(
      input.paymentMethod,
    );

  const recipientName =
    normalizeRequiredText(
      input.recipientName,
      "收货人姓名",
      100,
    );

  const recipientPhone =
    normalizeRequiredText(
      input.recipientPhone,
      "联系电话",
      30,
    );

  const addressLine1 =
    normalizeRequiredText(
      input.addressLine1,
      "收货地址",
      200,
    );

  const addressLine2 =
    normalizeOptionalText(
      input.addressLine2,
      "地址补充",
      200,
    );

  const city = normalizeRequiredText(
    input.city,
    "城市",
    100,
  );

  const state = normalizeRequiredText(
    input.state,
    "州属",
    100,
  );

  const postalCode =
    normalizeRequiredText(
      input.postalCode,
      "邮政编码",
      20,
    );

  const countryCode =
    normalizeCountryCode(
      input.countryCode,
    );

  const customerNote =
    normalizeOptionalText(
      input.customerNote,
      "客户备注",
      500,
    );

  const orderNumber =
    createOrderNumber();

  return prisma.$transaction(
    async (transaction) => {
      const productIds = items.map(
        (item) => item.productId,
      );

      const products =
        await transaction.product.findMany({
          where: {
            id: {
              in: productIds,
            },
            isActive: true,
            category: {
              isActive: true,
            },
          },
          select: {
            id: true,
            title: true,
            imageUrl: true,
            priceMinor: true,
            stock: true,
            reservedStock: true,
          },
        });

      if (
        products.length !==
        productIds.length
      ) {
        const foundProductIds =
          new Set(
            products.map(
              (product) => product.id,
            ),
          );

        const unavailableProductId =
          productIds.find(
            (productId) =>
              !foundProductIds.has(
                productId,
              ),
          );

        throw new AppError(
          409,
          `商品不存在或已经下架：${
            unavailableProductId ??
            "未知商品"
          }`,
          "PRODUCT_UNAVAILABLE",
        );
      }

      const productMap = new Map(
        products.map((product) => [
          product.id,
          product,
        ]),
      );

      let subtotalMinor = 0;

      const orderItems = items.map(
        (item) => {
          const product =
            productMap.get(
              item.productId,
            );

          if (!product) {
            throw new AppError(
              409,
              "商品不存在或已经下架",
              "PRODUCT_UNAVAILABLE",
            );
          }

          const lineTotalMinor =
            product.priceMinor *
            item.quantity;

          if (
            !Number.isSafeInteger(
              lineTotalMinor,
            )
          ) {
            throw new AppError(
              400,
              "订单金额超过系统限制",
              "ORDER_AMOUNT_TOO_LARGE",
            );
          }

          subtotalMinor +=
            lineTotalMinor;

          if (
            !Number.isSafeInteger(
              subtotalMinor,
            )
          ) {
            throw new AppError(
              400,
              "订单金额超过系统限制",
              "ORDER_AMOUNT_TOO_LARGE",
            );
          }

          return {
            productId: product.id,
            productTitle:
              product.title,
            productImageUrl:
              product.imageUrl,
            unitPriceMinor:
              product.priceMinor,
            quantity: item.quantity,
            lineTotalMinor,
          };
        },
      );

      const shippingMinor =
        readShippingMinor(
          shippingMethod,
        );

      const discountMinor = 0;

      const totalMinor =
        subtotalMinor +
        shippingMinor -
        discountMinor;

      if (
        !Number.isSafeInteger(
          totalMinor,
        )
      ) {
        throw new AppError(
          400,
          "订单金额超过系统限制",
          "ORDER_AMOUNT_TOO_LARGE",
        );
      }

      const isCashOnDelivery =
        paymentMethod ===
        "CASH_ON_DELIVERY";

      const reservationExpiresAt =
        isCashOnDelivery
          ? null
          : new Date(
              Date.now() +
                PAYMENT_RESERVATION_MINUTES *
                  60 *
                  1000,
            );

      for (const item of items) {
        const updatedCount =
          isCashOnDelivery
            ? await transaction.$executeRaw`
                UPDATE "Product"
                SET "stock" = "stock" - ${item.quantity}
                WHERE "id" = ${item.productId}
                  AND "isActive" = TRUE
                  AND ("stock" - "reservedStock") >= ${item.quantity}
              `
            : await transaction.$executeRaw`
                UPDATE "Product"
                SET "reservedStock" = "reservedStock" + ${item.quantity}
                WHERE "id" = ${item.productId}
                  AND "isActive" = TRUE
                  AND ("stock" - "reservedStock") >= ${item.quantity}
              `;

        if (Number(updatedCount) !== 1) {
          const product =
            productMap.get(
              item.productId,
            );

          throw new AppError(
            409,
            `${
              product?.title ??
              "商品"
            }库存不足`,
            "INSUFFICIENT_STOCK",
          );
        }
      }

      const orderStatus =
        isCashOnDelivery
          ? "PROCESSING"
          : "PENDING_PAYMENT";

      const order =
        await transaction.order.create({
          data: {
            orderNumber,
            userId: input.userId,

            status: orderStatus,
            paymentStatus: "UNPAID",
            currency: "MYR",

            shippingMethod,
            paymentMethod,

            subtotalMinor,
            shippingMinor,
            discountMinor,
            totalMinor,

            recipientName,
            recipientPhone,
            addressLine1,
            addressLine2,
            city,
            state,
            postalCode,
            countryCode,
            customerNote,
            reservationExpiresAt,

            items: {
              create: orderItems,
            },
          },
          include: {
            items: true,
          },
        });

      if (isCashOnDelivery) {
        for (const item of items) {
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
              "读取订单库存失败",
              "ORDER_STOCK_READ_FAILED",
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
                  `货到付款订单 ${orderNumber} 扣减库存`,
                createdByUserId:
                  input.userId,
              },
            });
        }
      }

      return mapOrder(order);
    },
  );
}

export async function getCustomerOrders(
  userId: string,
) {
  const orders =
    await prisma.order.findMany({
      where: {
        userId,
      },
      orderBy: {
        createdAt: "desc",
      },
      include: {
        items: true,
      },
    });

  return orders.map(mapOrder);
}


export async function cancelCustomerOrder(
  input: {
    orderId: string;
    userId: string;
  },
) {
  const order =
    await prisma.order.findFirst({
      where: {
        id: input.orderId,
        userId: input.userId,
      },
      select: {
        id: true,
        orderNumber: true,
        status: true,
        paymentStatus: true,
        paymentIntentId: true,
        reservationExpiresAt: true,
      },
    });

  if (!order) {
    throw new AppError(
      404,
      "订单不存在",
      "ORDER_NOT_FOUND",
    );
  }

  if (order.status === "CANCELLED") {
    const cancelledOrder =
      await prisma.order.findUnique({
        where: {
          id: order.id,
        },
        include: {
          items: true,
        },
      });

    if (!cancelledOrder) {
      throw new AppError(
        404,
        "订单不存在",
        "ORDER_NOT_FOUND",
      );
    }

    return mapOrder(cancelledOrder);
  }

  if (
    order.status !==
      "PENDING_PAYMENT" ||
    order.paymentStatus === "PAID"
  ) {
    throw new AppError(
      409,
      "只有待付款订单可以取消",
      "ORDER_NOT_CANCELLABLE",
    );
  }

  if (order.paymentIntentId) {
    await cancelStripePaymentIntent(
      order.paymentIntentId,
    );
  }

  return prisma.$transaction(
    async (transaction) => {
      const currentOrder =
        await transaction.order.findFirst({
          where: {
            id: input.orderId,
            userId: input.userId,
          },
          include: {
            items: true,
          },
        });

      if (!currentOrder) {
        throw new AppError(
          404,
          "订单不存在",
          "ORDER_NOT_FOUND",
        );
      }

      if (
        currentOrder.status ===
        "CANCELLED"
      ) {
        return mapOrder(
          currentOrder,
        );
      }

      if (
        currentOrder.status !==
          "PENDING_PAYMENT" ||
        currentOrder.paymentStatus ===
          "PAID"
      ) {
        throw new AppError(
          409,
          "订单状态已经改变，不能取消",
          "ORDER_STATUS_CHANGED",
        );
      }

      const updated =
        await transaction.order
          .updateMany({
            where: {
              id: currentOrder.id,
              userId: input.userId,
              status:
                "PENDING_PAYMENT",
              paymentStatus: {
                not: "PAID",
              },
            },
            data: {
              status: "CANCELLED",
              paymentStatus:
                currentOrder
                    .paymentStatus ===
                  "PROCESSING"
                  ? "FAILED"
                  : currentOrder
                      .paymentStatus,
              cancelledAt:
                new Date(),
            },
          });

      if (updated.count !== 1) {
        throw new AppError(
          409,
          "订单状态已经改变，请重新载入",
          "ORDER_STATUS_CHANGED",
        );
      }

      const usesReservedStock =
        currentOrder
          .reservationExpiresAt !==
        null;

      for (
        const item of
          currentOrder.items
      ) {
        if (usesReservedStock) {
          const released =
            await transaction.product
              .updateMany({
                where: {
                  id: item.productId,
                  reservedStock: {
                    gte: item.quantity,
                  },
                },
                data: {
                  reservedStock: {
                    decrement:
                      item.quantity,
                  },
                },
              });

          if (released.count !== 1) {
            throw new AppError(
              409,
              "订单锁定库存资料异常，请重新载入",
              "RESERVED_STOCK_INCONSISTENT",
            );
          }

          continue;
        }

        const updatedProduct =
          await transaction.product
            .update({
              where: {
                id: item.productId,
              },
              data: {
                stock: {
                  increment:
                    item.quantity,
                },
              },
              select: {
                stock: true,
              },
            });

        await transaction
          .inventoryMovement
          .create({
            data: {
              productId:
                item.productId,
              type: "STOCK_IN",
              quantityDelta:
                item.quantity,
              stockBefore:
                updatedProduct.stock -
                item.quantity,
              stockAfter:
                updatedProduct.stock,
              note:
                `旧订单 ${currentOrder.orderNumber} 取消，恢复库存`,
              createdByUserId:
                input.userId,
            },
          });
      }

      const cancelledOrder =
        await transaction.order
          .findUnique({
            where: {
              id: currentOrder.id,
            },
            include: {
              items: true,
            },
          });

      if (!cancelledOrder) {
        throw new AppError(
          500,
          "取消订单后读取资料失败",
          "CANCELLED_ORDER_READ_FAILED",
        );
      }

      return mapOrder(
        cancelledOrder,
      );
    },
  );
}

async function cancelStripePaymentIntent(
  paymentIntentId: string,
): Promise<void> {
  const paymentIntent =
    await stripe.paymentIntents.retrieve(
      paymentIntentId,
    );

  if (
    paymentIntent.status ===
    "succeeded"
  ) {
    throw new AppError(
      409,
      "付款已经完成，不能取消订单",
      "ORDER_ALREADY_PAID",
    );
  }

  if (
    paymentIntent.status ===
    "canceled"
  ) {
    return;
  }

  try {
    await stripe.paymentIntents.cancel(
      paymentIntent.id,
      {
        cancellation_reason:
          "requested_by_customer",
      },
    );
  } catch (_) {
    const latestPaymentIntent =
      await stripe.paymentIntents.retrieve(
        paymentIntent.id,
      );

    if (
      latestPaymentIntent.status ===
      "succeeded"
    ) {
      throw new AppError(
        409,
        "付款已经完成，不能取消订单",
        "ORDER_ALREADY_PAID",
      );
    }

    if (
      latestPaymentIntent.status ===
      "canceled"
    ) {
      return;
    }

    throw new AppError(
      409,
      "付款正在处理，当前不能取消订单",
      "PAYMENT_NOT_CANCELLABLE",
    );
  }
}

function normalizeOrderItems(
  rawItems: CreateOrderItemInput[],
): CreateOrderItemInput[] {
  if (
    !Array.isArray(rawItems) ||
    rawItems.length === 0
  ) {
    throw new AppError(
      400,
      "订单至少需要一件商品",
      "ORDER_ITEMS_REQUIRED",
    );
  }

  if (rawItems.length > 100) {
    throw new AppError(
      400,
      "单个订单的商品种类不能超过 100 种",
      "TOO_MANY_ORDER_ITEMS",
    );
  }

  const quantityByProductId =
    new Map<string, number>();

  for (const item of rawItems) {
    if (
      typeof item?.productId !==
        "string" ||
      item.productId.trim().length ===
        0
    ) {
      throw new AppError(
        400,
        "商品 ID 不能为空",
        "PRODUCT_ID_REQUIRED",
      );
    }

    if (
      !Number.isInteger(
        item.quantity,
      ) ||
      item.quantity <= 0
    ) {
      throw new AppError(
        400,
        "商品数量必须是正整数",
        "INVALID_ORDER_QUANTITY",
      );
    }

    const productId =
      item.productId.trim();

    const nextQuantity =
      (
        quantityByProductId.get(
          productId,
        ) ?? 0
      ) + item.quantity;

    if (nextQuantity > 999) {
      throw new AppError(
        400,
        "单件商品购买数量不能超过 999",
        "ORDER_QUANTITY_TOO_LARGE",
      );
    }

    quantityByProductId.set(
      productId,
      nextQuantity,
    );
  }

  return Array.from(
    quantityByProductId.entries(),
  ).map(
    ([productId, quantity]) => ({
      productId,
      quantity,
    }),
  );
}

function normalizeShippingMethod(
  value: unknown,
): CustomerShippingMethod {
  if (
    value === "STANDARD" ||
    value === "EXPRESS"
  ) {
    return value;
  }

  throw new AppError(
    400,
    "配送方式无效",
    "INVALID_SHIPPING_METHOD",
  );
}

function normalizePaymentMethod(
  value: unknown,
): CustomerPaymentMethod {
  if (
    value === "ONLINE_BANKING" ||
    value === "CARD" ||
    value === "CASH_ON_DELIVERY"
  ) {
    return value;
  }

  throw new AppError(
    400,
    "付款方式无效",
    "INVALID_PAYMENT_METHOD",
  );
}

function readShippingMinor(
  shippingMethod:
    CustomerShippingMethod,
): number {
  switch (shippingMethod) {
    case "STANDARD":
      return 500;

    case "EXPRESS":
      return 1500;
  }
}

function normalizeRequiredText(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string {
  if (typeof value !== "string") {
    throw new AppError(
      400,
      `${fieldName}不能为空`,
      "REQUIRED_FIELD_MISSING",
    );
  }

  const normalizedValue =
    value.trim();

  if (
    normalizedValue.length === 0
  ) {
    throw new AppError(
      400,
      `${fieldName}不能为空`,
      "REQUIRED_FIELD_MISSING",
    );
  }

  if (
    normalizedValue.length >
    maxLength
  ) {
    throw new AppError(
      400,
      `${fieldName}不能超过 ${maxLength} 个字符`,
      "FIELD_TOO_LONG",
    );
  }

  return normalizedValue;
}

function normalizeOptionalText(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string | null {
  if (
    value === undefined ||
    value === null
  ) {
    return null;
  }

  if (typeof value !== "string") {
    throw new AppError(
      400,
      `${fieldName}必须是字符串`,
      "INVALID_STRING_FIELD",
    );
  }

  const normalizedValue =
    value.trim();

  if (
    normalizedValue.length === 0
  ) {
    return null;
  }

  if (
    normalizedValue.length >
    maxLength
  ) {
    throw new AppError(
      400,
      `${fieldName}不能超过 ${maxLength} 个字符`,
      "FIELD_TOO_LONG",
    );
  }

  return normalizedValue;
}

function normalizeCountryCode(
  value: unknown,
): string {
  const countryCode =
    typeof value === "string"
      ? value.trim().toUpperCase()
      : "MY";

  if (
    !/^[A-Z]{2}$/.test(
      countryCode,
    )
  ) {
    throw new AppError(
      400,
      "国家代码必须是两个英文字母",
      "INVALID_COUNTRY_CODE",
    );
  }

  return countryCode;
}

function createOrderNumber(): string {
  const now = new Date();

  const datePart = [
    now.getFullYear(),
    String(
      now.getMonth() + 1,
    ).padStart(2, "0"),
    String(
      now.getDate(),
    ).padStart(2, "0"),
  ].join("");

  const randomPart =
    randomUUID()
      .replaceAll("-", "")
      .slice(0, 10)
      .toUpperCase();

  return `ORD-${datePart}-${randomPart}`;
}

function mapOrder<
  T extends {
    id: string;
    orderNumber: string;
    status: string;
    paymentStatus: string;
    currency: string;
    shippingMethod: string;
    paymentMethod: string;
    subtotalMinor: number;
    shippingMinor: number;
    discountMinor: number;
    totalMinor: number;
    recipientName: string;
    recipientPhone: string;
    addressLine1: string;
    addressLine2: string | null;
    city: string;
    state: string;
    postalCode: string;
    countryCode: string;
    customerNote: string | null;
    paidAt: Date | null;
    cancelledAt: Date | null;
    reservationExpiresAt:
      Date | null;
    createdAt: Date;
    updatedAt: Date;
    items: Array<{
      id: string;
      productId: string;
      productTitle: string;
      productImageUrl: string;
      unitPriceMinor: number;
      quantity: number;
      lineTotalMinor: number;
    }>;
  },
>(order: T) {
  return {
    id: order.id,
    orderNumber:
      order.orderNumber,
    status: order.status,
    paymentStatus:
      order.paymentStatus,
    currency: order.currency,

    shippingMethod:
      order.shippingMethod,

    paymentMethod:
      order.paymentMethod,

    subtotalMinor:
      order.subtotalMinor,

    shippingMinor:
      order.shippingMinor,

    discountMinor:
      order.discountMinor,

    totalMinor:
      order.totalMinor,

    recipientName:
      order.recipientName,

    recipientPhone:
      order.recipientPhone,

    addressLine1:
      order.addressLine1,

    addressLine2:
      order.addressLine2,

    city: order.city,
    state: order.state,

    postalCode:
      order.postalCode,

    countryCode:
      order.countryCode,

    customerNote:
      order.customerNote,

    paidAt: order.paidAt,

    cancelledAt:
      order.cancelledAt,

    reservationExpiresAt:
      order.reservationExpiresAt,

    createdAt:
      order.createdAt,

    updatedAt:
      order.updatedAt,

    items: order.items.map(
      (item) => ({
        id: item.id,

        productId:
          item.productId,

        productTitle:
          item.productTitle,

        productImage:
          item.productImageUrl,

        unitPriceMinor:
          item.unitPriceMinor,

        quantity:
          item.quantity,

        lineTotalMinor:
          item.lineTotalMinor,
      }),
    ),
  };
}