import {
  httpClient,
} from "../../api/http_client";

import type {
  AdminOrderDetail,
  AdminOrderSummary,
  GetAdminOrdersInput,
} from "./order";

export async function getAdminOrders(
  input: GetAdminOrdersInput = {},
): Promise<AdminOrderSummary[]> {
  const response =
    await httpClient.get<
      AdminOrderSummary[]
    >(
      "/api/admin/orders",
      {
        params: {
          status: input.status,
          paymentStatus:
            input.paymentStatus,
          keyword: input.keyword,
          limit: input.limit ?? 100,
        },
      },
    );

  return response.data;
}

export async function getAdminOrderDetail(
  orderId: string,
): Promise<AdminOrderDetail> {
  const response =
    await httpClient.get<
      AdminOrderDetail
    >(
      `/api/admin/orders/${orderId}`,
    );

  return response.data;
}