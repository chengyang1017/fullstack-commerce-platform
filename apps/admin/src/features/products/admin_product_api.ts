import {
  httpClient,
} from "../../api/http_client";

import type {
  AdminProduct,
  CreateProductInput,
  UpdateProductInput,
} from "./product";

interface ProductResponse {
  success: boolean;
  product: AdminProduct;
}

export async function getAdminProducts():
    Promise<AdminProduct[]> {
  const response =
      await httpClient.get<AdminProduct[]>(
    "/api/admin/products",
  );

  return response.data;
}

export async function createAdminProduct(
  input: CreateProductInput,
): Promise<AdminProduct> {
  const response =
      await httpClient.post<ProductResponse>(
    "/api/admin/products",
    input,
  );

  return response.data.product;
}

export async function updateAdminProduct(
  productId: string,
  input: UpdateProductInput,
): Promise<AdminProduct> {
  const response =
      await httpClient.patch<ProductResponse>(
    `/api/admin/products/${productId}`,
    input,
  );

  return response.data.product;
}

export async function deactivateAdminProduct(
  productId: string,
): Promise<void> {
  await httpClient.delete(
    `/api/admin/products/${productId}`,
  );
}

export async function activateAdminProduct(
  productId: string,
): Promise<AdminProduct> {
  return updateAdminProduct(
    productId,
    {
      isActive: true,
    },
  );
}