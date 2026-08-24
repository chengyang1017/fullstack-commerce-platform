export interface AdminProduct {
  id: string;
  categoryId: string;
  title: string;
  description: string;
  image: string;
  price: number;
  stock: number;
  sold: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateProductInput {
  categoryId: string;
  title: string;
  description: string;
  imageUrl: string;
  price: number;
  stock: number;
}

export interface UpdateProductInput {
  categoryId?: string;
  title?: string;
  description?: string;
  imageUrl?: string;
  price?: number;
  stock?: number;
  isActive?: boolean;
}