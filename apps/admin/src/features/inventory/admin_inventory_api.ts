import {
  httpClient,
} from "../../api/http_client";

import type {
  AdminInventoryMovement,
  ChangeInventoryInput,
  ChangeInventoryResponse,
} from "./inventory";

export async function getInventoryMovements(
  productId?: string,
  limit = 100,
): Promise<AdminInventoryMovement[]> {
  const response =
    await httpClient.get<
      AdminInventoryMovement[]
    >(
      "/api/admin/inventory/movements",
      {
        params: {
          productId,
          limit,
        },
      },
    );

  return response.data;
}

export async function changeInventory(
  input: ChangeInventoryInput,
): Promise<ChangeInventoryResponse> {
  const response =
    await httpClient.post<
      ChangeInventoryResponse
    >(
      "/api/admin/inventory/movements",
      input,
    );

  return response.data;
}