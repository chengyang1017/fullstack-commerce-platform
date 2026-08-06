import { prisma } from "../lib/prisma.ts";
import { stripe } from "../lib/stripe.ts";

import {
  syncCustomerPaymentStatus,
} from "./customer_payment_service.ts";

const EXPIRATION_CHECK_INTERVAL_MS =
  60 * 1000;

const EXPIRATION_BATCH_SIZE = 50;

let workerStarted = false;
let workerRunning = false;

export function startOrderExpirationWorker(): void {
  if (workerStarted) {
    return;
  }

  workerStarted = true;

  void runExpirationCheck();

  const timer = setInterval(() => {
    void runExpirationCheck();
  }, EXPIRATION_CHECK_INTERVAL_MS);

  timer.unref();
}

export async function expirePendingOrders(
  limit = EXPIRATION_BATCH_SIZE,
): Promise<number> {
  const now = new Date();

  const expiredOrders =
    await prisma.order.findMany({
      where: {
        status: "PENDING_PAYMENT",

        paymentStatus: {
          not: "PAID",
        },

        paymentMethod: {
          not: "CASH_ON_DELIVERY",
        },

        reservationExpiresAt: {
          not: null,
          lte: now,
        },
      },

      orderBy: {
        reservationExpiresAt: "asc",
      },

      select: {
        id: true,
        userId: true,
        orderNumber: true,
        paymentIntentId: true,
      },

      take: limit,
    });

  let expiredCount = 0;

  for (const order of expiredOrders) {
    try {
      const canExpire =
        await preparePaymentIntentForExpiration({
          orderId: order.id,
          userId: order.userId,
          paymentIntentId:
            order.paymentIntentId,
        });

      if (!canExpire) {
        continue;
      }

      const expired =
        await expireSingleOrder(order.id);

      if (expired) {
        expiredCount++;
      }
    } catch (error) {
      console.error(
        `自动取消订单失败：${order.orderNumber}`,
        error,
      );
    }
  }

  return expiredCount;
}

async function preparePaymentIntentForExpiration(
  input: {
    orderId: string;
    userId: string;
    paymentIntentId: string | null;
  },
): Promise<boolean> {
  if (!input.paymentIntentId) {
    return true;
  }

  let paymentIntent =
    await stripe.paymentIntents.retrieve(
      input.paymentIntentId,
    );

  if (paymentIntent.status === "succeeded") {
    await syncCustomerPaymentStatus({
      orderId: input.orderId,
      userId: input.userId,
    });

    return false;
  }

  if (paymentIntent.status === "processing") {
    return false;
  }

  if (paymentIntent.status === "canceled") {
    return true;
  }

  try {
    paymentIntent =
      await stripe.paymentIntents.cancel(
        paymentIntent.id,
        {
          cancellation_reason:
            "abandoned",
        },
      );

    return (
      paymentIntent.status === "canceled"
    );
  } catch (error) {
    const latestPaymentIntent =
      await stripe.paymentIntents.retrieve(
        input.paymentIntentId,
      );

    if (
      latestPaymentIntent.status ===
      "succeeded"
    ) {
      await syncCustomerPaymentStatus({
        orderId: input.orderId,
        userId: input.userId,
      });

      return false;
    }

    if (
      latestPaymentIntent.status ===
      "processing"
    ) {
      return false;
    }

    if (
      latestPaymentIntent.status ===
      "canceled"
    ) {
      return true;
    }

    console.warn(
      `Stripe PaymentIntent 暂时无法取消：${input.paymentIntentId}`,
      error,
    );

    return false;
  }
}

async function expireSingleOrder(
  orderId: string,
): Promise<boolean> {
  const now = new Date();

  return prisma.$transaction(
    async (transaction) => {
      const order =
        await transaction.order.findFirst({
          where: {
            id: orderId,

            status:
              "PENDING_PAYMENT",

            paymentStatus: {
              not: "PAID",
            },

            reservationExpiresAt: {
              not: null,
              lte: now,
            },
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

      if (!order) {
        return false;
      }

      const updated =
        await transaction.order.updateMany({
          where: {
            id: order.id,

            status:
              "PENDING_PAYMENT",

            paymentStatus: {
              not: "PAID",
            },

            reservationExpiresAt: {
              not: null,
              lte: now,
            },
          },

          data: {
            status: "CANCELLED",
            paymentStatus: "FAILED",
            cancelledAt: now,
            reservationExpiresAt: null,
          },
        });

      if (updated.count !== 1) {
        return false;
      }

      for (const item of order.items) {
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
          throw new Error(
            `订单 ${order.orderNumber} 的锁定库存资料异常`,
          );
        }
      }

      return true;
    },
  );
}

async function runExpirationCheck(): Promise<void> {
  if (workerRunning) {
    return;
  }

  workerRunning = true;

  try {
    const expiredCount =
      await expirePendingOrders();

    if (expiredCount > 0) {
      console.log(
        `已自动取消 ${expiredCount} 笔超时待付款订单`,
      );
    }
  } catch (error) {
    console.error(
      "待付款订单自动取消任务执行失败",
      error,
    );
  } finally {
    workerRunning = false;
  }
}