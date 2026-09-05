export interface AdminCategory {
  id: string;
  name: string;
  isActive: boolean;
  sortOrder: number;
  iconName: string;
  iconColorStart: string;
  iconColorEnd: string;
  productCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateCategoryInput {
  name: string;
  sortOrder: number;
  iconName: string;
  iconColorStart: string;
  iconColorEnd: string;
}

export interface UpdateCategoryInput {
  name?: string;
  sortOrder?: number;
  iconName?: string;
  iconColorStart?: string;
  iconColorEnd?: string;
  isActive?: boolean;
}
