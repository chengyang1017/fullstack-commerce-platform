import {
  Router,
  type Request,
  type Response,
} from "express";

import {
  getAdminOrderDetail,
  getAdminOrders,
} from "../services/admin_order_service.ts";

export const adminOrderRouter =
  Router();

adminOrderRouter.get(
  "/",
  async (
    request: Request,
    response: Response,
  ) => {
    const orders =
      await getAdminOrders({
        status:
          readOptionalString(
            request.query.status,
          ),

        paymentStatus:
          readOptionalString(
            request.query
              .paymentStatus,
          ),

        keyword:
          readOptionalString(
            request.query.keyword,
          ),

        limit:
          readOptionalInteger(
            request.query.limit,
          ),
      });

    response.json(orders);
  },
);

adminOrderRouter.get(
  "/:id",
  async (
    request: Request<{
      id: string;
    }>,
    response: Response,
  ) => {
    const order =
      await getAdminOrderDetail(
        request.params.id,
      );

    response.json(order);
  },
);

function readOptionalString(
  value: unknown,
): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalizedValue =
    value.trim();

  return normalizedValue.length > 0
    ? normalizedValue
    : undefined;
}

function readOptionalInteger(
  value: unknown,
): number | undefined {
  if (value === undefined) {
    return undefined;
  }

  if (typeof value !== "string") {
    return Number.NaN;
  }

  return Number(value);
}