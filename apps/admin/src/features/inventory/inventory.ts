import type {
  AdminProduct,
} from "../products/product";

export type InventoryMovementType =
  | "STOCK_IN"
  | "STOCK_OUT"
  | "ADJUSTMENT";

export interface InventoryOperator {
  id: string;
  name: string;
  email: string;
}

export interface InventoryMovementProduct {
  id: string;
  title: string;
  image: string;
}

export interface AdminInventoryMovement {
  id: string;
  productId: string;
  product: InventoryMovementProduct;
  type: InventoryMovementType;
  quantityDelta: number;
  stockBefore: number;
  stockAfter: number;
  note: string | null;
  createdAt: string;
  createdByUser: InventoryOperator | null;
}

export interface CreatedInventoryMovement {
  id: string;
  productId: string;
  type: InventoryMovementType;
  quantityDelta: number;
  stockBefore: number;
  stockAfter: number;
  note: string | null;
  createdAt: string;
  createdByUser: InventoryOperator | null;
}

export type ChangeInventoryInput =
  | {
      productId: string;
      type: "STOCK_IN";
      quantity: number;
      note?: string;
    }
  | {
      productId: string;
      type: "STOCK_OUT";
      quantity: number;
      note?: string;
    }
  | {
      productId: string;
      type: "ADJUSTMENT";
      targetStock: number;
      note?: string;
    };

export interface ChangeInventoryResponse {
  success: boolean;
  product: AdminProduct;
  movement: CreatedInventoryMovement;
}