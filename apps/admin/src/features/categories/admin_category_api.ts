import {
  httpClient,
} from "../../api/http_client";

import type {
  AdminCategory,
  CreateCategoryInput,
  UpdateCategoryInput,
} from "./category";

interface CategoryResponse {
  success: boolean;
  category: AdminCategory;
}

export async function getAdminCategories():
    Promise<AdminCategory[]> {
  const response =
      await httpClient.get<AdminCategory[]>(
    "/api/admin/categories",
  );

  return response.data;
}

export async function createAdminCategory(
  input: CreateCategoryInput,
): Promise<AdminCategory> {
  const response =
      await httpClient.post<CategoryResponse>(
    "/api/admin/categories",
    input,
  );

  return response.data.category;
}

export async function updateAdminCategory(
  categoryId: string,
  input: UpdateCategoryInput,
): Promise<AdminCategory> {
  const response =
      await httpClient.patch<CategoryResponse>(
    `/api/admin/categories/${categoryId}`,
    input,
  );

  return response.data.category;
}

export async function deactivateAdminCategory(
  categoryId: string,
): Promise<void> {
  await httpClient.delete(
    `/api/admin/categories/${categoryId}`,
  );
}

export async function activateAdminCategory(
  categoryId: string,
): Promise<AdminCategory> {
  return updateAdminCategory(
    categoryId,
    {
      isActive: true,
    },
  );
}