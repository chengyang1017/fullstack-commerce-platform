export type OrderStatus =
  | "PENDING_PAYMENT"
  | "PAID"
  | "PROCESSING"
  | "SHIPPED"
  | "DELIVERED"
  | "CANCELLED"
  | "REFUNDED";

export type PaymentStatus =
  | "UNPAID"
  | "PROCESSING"
  | "PAID"
  | "FAILED"
  | "REFUNDED"
  | "PARTIALLY_REFUNDED";

export interface AdminOrderCustomer {
  id: string;
  email: string;
  name: string;
}

export interface AdminOrderSummary {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  currency: string;

  subtotalMinor: number;
  shippingMinor: number;
  discountMinor: number;
  totalMinor: number;

  recipientName: string;
  recipientPhone: string;
  city: string;
  state: string;
  countryCode: string;

  itemCount: number;
  totalQuantity: number;

  customer: AdminOrderCustomer;

  paidAt: string | null;
  cancelledAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminOrderItem {
  id: string;
  productId: string;
  productTitle: string;
  productImage: string;
  unitPriceMinor: number;
  quantity: number;
  lineTotalMinor: number;
  createdAt: string;
}

export interface AdminOrderDetail {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  currency: string;

  subtotalMinor: number;
  shippingMinor: number;
  discountMinor: number;
  totalMinor: number;

  recipientName: string;
  recipientPhone: string;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  state: string;
  postalCode: string;
  countryCode: string;

  customerNote: string | null;

  paidAt: string | null;
  cancelledAt: string | null;
  createdAt: string;
  updatedAt: string;

  customer: AdminOrderCustomer;
  items: AdminOrderItem[];
}

export interface GetAdminOrdersInput {
  status?: OrderStatus;
  paymentStatus?: PaymentStatus;
  keyword?: string;
  limit?: number;
}