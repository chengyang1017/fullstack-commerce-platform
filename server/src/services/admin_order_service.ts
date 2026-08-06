import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";

interface GetAdminOrdersInput {
  status?: string;
  paymentStatus?: string;
  keyword?: string;
  limit?: number;
}

export async function getAdminOrders(
  input: GetAdminOrdersInput,
) {
  const limit = normalizeLimit(
    input.limit,
  );

  const keyword =
    input.keyword?.trim();

  const orders =
    await prisma.order.findMany({
      where: {
        status:
          readOrderStatus(
            input.status,
          ),

        paymentStatus:
          readPaymentStatus(
            input.paymentStatus,
          ),

        ...(keyword
          ? {
              OR: [
                {
                  orderNumber: {
                    contains: keyword,
                    mode: "insensitive",
                  },
                },
                {
                  recipientName: {
                    contains: keyword,
                    mode: "insensitive",
                  },
                },
                {
                  recipientPhone: {
                    contains: keyword,
                    mode: "insensitive",
                  },
                },
                {
                  user: {
                    email: {
                      contains: keyword,
                      mode: "insensitive",
                    },
                  },
                },
              ],
            }
          : {}),
      },

      orderBy: {
        createdAt: "desc",
      },

      take: limit,

      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },

        items: {
          select: {
            id: true,
            quantity: true,
            lineTotalMinor: true,
          },
        },
      },
    });

  return orders.map((order) => {
    const totalQuantity =
      order.items.reduce(
        (total, item) =>
          total + item.quantity,
        0,
      );

    return {
      id: order.id,
      orderNumber:
        order.orderNumber,

      status: order.status,

      paymentStatus:
        order.paymentStatus,

      currency: order.currency,

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

      city: order.city,
      state: order.state,
      countryCode:
        order.countryCode,

      itemCount:
        order.items.length,

      totalQuantity,

      customer: order.user,

      paidAt: order.paidAt,

      cancelledAt:
        order.cancelledAt,

      createdAt:
        order.createdAt,

      updatedAt:
        order.updatedAt,
    };
  });
}

export async function getAdminOrderDetail(
  orderId: string,
) {
  const order =
    await prisma.order.findUnique({
      where: {
        id: orderId,
      },

      include: {
        user: {
          select: {
            id: true,
            email: true,
            name: true,
          },
        },

        items: {
          orderBy: {
            createdAt: "asc",
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

  return {
    id: order.id,

    orderNumber:
      order.orderNumber,

    status: order.status,

    paymentStatus:
      order.paymentStatus,

    currency:
      order.currency,

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

    paidAt:
      order.paidAt,

    cancelledAt:
      order.cancelledAt,

    createdAt:
      order.createdAt,

    updatedAt:
      order.updatedAt,

    customer:
      order.user,

    items:
      order.items.map(
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

          createdAt:
            item.createdAt,
        }),
      ),
  };
}

function normalizeLimit(
  value: number | undefined,
): number {
  if (value === undefined) {
    return 100;
  }

  if (
    !Number.isInteger(value) ||
    value < 1
  ) {
    throw new AppError(
      400,
      "limit 必须是正整数",
      "INVALID_ORDER_LIMIT",
    );
  }

  return Math.min(value, 200);
}

function readOrderStatus(
  value: string | undefined,
):
  | "PENDING_PAYMENT"
  | "PAID"
  | "PROCESSING"
  | "SHIPPED"
  | "DELIVERED"
  | "CANCELLED"
  | "REFUNDED"
  | undefined {
  if (
    value === undefined ||
    value.length === 0
  ) {
    return undefined;
  }

  switch (value) {
    case "PENDING_PAYMENT":
    case "PAID":
    case "PROCESSING":
    case "SHIPPED":
    case "DELIVERED":
    case "CANCELLED":
    case "REFUNDED":
      return value;

    default:
      throw new AppError(
        400,
        "订单状态无效",
        "INVALID_ORDER_STATUS",
      );
  }
}

function readPaymentStatus(
  value: string | undefined,
):
  | "UNPAID"
  | "PROCESSING"
  | "PAID"
  | "FAILED"
  | "REFUNDED"
  | "PARTIALLY_REFUNDED"
  | undefined {
  if (
    value === undefined ||
    value.length === 0
  ) {
    return undefined;
  }

  switch (value) {
    case "UNPAID":
    case "PROCESSING":
    case "PAID":
    case "FAILED":
    case "REFUNDED":
    case "PARTIALLY_REFUNDED":
      return value;

    default:
      throw new AppError(
        400,
        "付款状态无效",
        "INVALID_PAYMENT_STATUS",
      );
  }
}