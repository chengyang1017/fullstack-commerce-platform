export interface AdminCategory {
  id: string;
  name: string;
  isActive: boolean;
  sortOrder: number;
  productCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateCategoryInput {
  name: string;
  sortOrder: number;
}

export interface UpdateCategoryInput {
  name?: string;
  sortOrder?: number;
  isActive?: boolean;
}