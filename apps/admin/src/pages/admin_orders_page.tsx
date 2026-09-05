import axios from "axios";
import {
  type FormEvent,
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  getAdminOrderDetail,
  getAdminOrders,
} from "../features/orders/admin_order_api";

import type {
  AdminOrderDetail,
  AdminOrderSummary,
  OrderStatus,
  PaymentStatus,
} from "../features/orders/order";

interface ErrorResponse {
  message?: string;
}

type OrderStatusFilter =
  | ""
  | OrderStatus;

type PaymentStatusFilter =
  | ""
  | PaymentStatus;

export function AdminOrdersPage() {
  const [orders, setOrders] =
    useState<AdminOrderSummary[]>([]);

  const [status, setStatus] =
    useState<OrderStatusFilter>("");

  const [
    paymentStatus,
    setPaymentStatus,
  ] =
    useState<PaymentStatusFilter>("");

  const [keywordInput, setKeywordInput] =
    useState("");

  const [keyword, setKeyword] =
    useState("");

  const [isLoading, setIsLoading] =
    useState(true);

  const [errorMessage, setErrorMessage] =
    useState<string | null>(null);

  const [reloadKey, setReloadKey] =
    useState(0);

  const [
    selectedOrderId,
    setSelectedOrderId,
  ] = useState<string | null>(null);

  const [
    selectedOrder,
    setSelectedOrder,
  ] =
    useState<AdminOrderDetail | null>(
      null,
    );

  const [
    isDetailLoading,
    setIsDetailLoading,
  ] = useState(false);

  const [
    detailErrorMessage,
    setDetailErrorMessage,
  ] =
    useState<string | null>(null);

  useEffect(() => {
    let isCancelled = false;

    async function loadOrders():
        Promise<void> {
      setIsLoading(true);
      setErrorMessage(null);

      try {
        const result =
          await getAdminOrders({
            status:
              status || undefined,

            paymentStatus:
              paymentStatus ||
              undefined,

            keyword:
              keyword.length > 0
                ? keyword
                : undefined,

            limit: 200,
          });

        if (isCancelled) {
          return;
        }

        setOrders(result);
      } catch (error) {
        if (isCancelled) {
          return;
        }

        setErrorMessage(
          readErrorMessage(
            error,
            "Failed to load orders.",
          ),
        );
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    }

    void loadOrders();

    return () => {
      isCancelled = true;
    };
  }, [
    status,
    paymentStatus,
    keyword,
    reloadKey,
  ]);

  const totalRevenueMinor =
    useMemo(() => {
      return orders
        .filter(
          (order) =>
            order.paymentStatus ===
            "PAID",
        )
        .reduce(
          (total, order) =>
            total +
            order.totalMinor,
          0,
        );
    }, [orders]);

  const pendingPaymentCount =
    orders.filter(
      (order) =>
        order.status ===
        "PENDING_PAYMENT",
    ).length;

  const processingCount =
    orders.filter(
      (order) =>
        order.status ===
          "PROCESSING" ||
        order.status === "PAID",
    ).length;

  function submitSearch(
    event: FormEvent<HTMLFormElement>,
  ): void {
    event.preventDefault();

    setKeyword(
      keywordInput.trim(),
    );
  }

  function clearSearch(): void {
    setKeywordInput("");
    setKeyword("");
  }

  function refreshOrders(): void {
    setReloadKey(
      (currentValue) =>
        currentValue + 1,
    );
  }

  async function openOrderDetail(
    orderId: string,
  ): Promise<void> {
    setSelectedOrderId(orderId);
    setSelectedOrder(null);
    setDetailErrorMessage(null);
    setIsDetailLoading(true);

    try {
      const order =
        await getAdminOrderDetail(
          orderId,
        );

      setSelectedOrder(order);
    } catch (error) {
      setDetailErrorMessage(
        readErrorMessage(
          error,
          "Failed to load order details.",
        ),
      );
    } finally {
      setIsDetailLoading(false);
    }
  }

  function closeOrderDetail(): void {
    if (isDetailLoading) {
      return;
    }

    setSelectedOrderId(null);
    setSelectedOrder(null);
    setDetailErrorMessage(null);
  }

  return (
    <>
      <header className="page-header page-header-row">
        <div>
          <p className="page-eyebrow">
            ORDERS
          </p>

          <h1>Order management</h1>

          <p className="page-description">
            Review customer orders, payments, line items, and shipping details.
          </p>
        </div>

        <button
          className="secondary-button"
          type="button"
          disabled={isLoading}
          onClick={refreshOrders}
        >
          {isLoading
            ? "Refreshing..."
            : "Refresh orders"}
        </button>
      </header>

      <section className="order-summary-grid">
        <article className="summary-card">
          <span>Current results</span>
          <strong>{orders.length}</strong>
        </article>

        <article className="summary-card">
          <span>Pending payment</span>
          <strong>
            {pendingPaymentCount}
          </strong>
        </article>

        <article className="summary-card">
          <span>Pending fulfilment</span>
          <strong>
            {processingCount}
          </strong>
        </article>

        <article className="summary-card">
          <span>Paid amount</span>
          <strong className="order-revenue">
            {formatMoney(
              totalRevenueMinor,
              "MYR",
            )}
          </strong>
        </article>
      </section>

      <section className="content-card orders-card">
        <div className="orders-toolbar">
          <form
            className="order-search-form"
            onSubmit={submitSearch}
          >
            <input
              value={keywordInput}
              placeholder="Search order number, customer, phone, or email"
              onChange={(event) => {
                setKeywordInput(
                  event.target.value,
                );
              }}
            />

            <button
              className="primary-button"
              type="submit"
              disabled={isLoading}
            >
              Search
            </button>

            {(keyword.length > 0 ||
              keywordInput.length > 0) && (
              <button
                className="secondary-button"
                type="button"
                onClick={clearSearch}
              >
                Clear
              </button>
            )}
          </form>

          <div className="order-filter-group">
            <label>
              <span>Order status</span>

              <select
                value={status}
                disabled={isLoading}
                onChange={(event) => {
                  setStatus(
                    event.target
                      .value as
                      OrderStatusFilter,
                  );
                }}
              >
                <option value="">
                  All order statuses
                </option>

                <option value="PENDING_PAYMENT">
                  Pending payment
                </option>

                <option value="PAID">
                  Paid
                </option>

                <option value="PROCESSING">
                  Processing
                </option>

                <option value="SHIPPED">
                  Shipped
                </option>

                <option value="DELIVERED">
                  Delivered
                </option>

                <option value="CANCELLED">
                  Cancelled
                </option>

                <option value="REFUNDED">
                  Refunded
                </option>
              </select>
            </label>

            <label>
              <span>Payment status</span>

              <select
                value={paymentStatus}
                disabled={isLoading}
                onChange={(event) => {
                  setPaymentStatus(
                    event.target
                      .value as
                      PaymentStatusFilter,
                  );
                }}
              >
                <option value="">
                  All payment statuses
                </option>

                <option value="UNPAID">
                  Unpaid
                </option>

                <option value="PROCESSING">
                  Processing
                </option>

                <option value="PAID">
                  Paid
                </option>

                <option value="FAILED">
                  Failed
                </option>

                <option value="REFUNDED">
                  Refunded
                </option>

                <option value="PARTIALLY_REFUNDED">
                  Partially refunded
                </option>
              </select>
            </label>
          </div>
        </div>

        {errorMessage && (
          <div
            className="products-error"
            role="alert"
          >
            <span>{errorMessage}</span>

            <button
              type="button"
              onClick={refreshOrders}
            >
              Retry
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>Loading orders...</p>
          </div>
        ) : orders.length === 0 ? (
          <div className="products-state">
            <strong>
              No orders match your filters
            </strong>

            <p>
              Adjust the filters or clear the search.
            </p>
          </div>
        ) : (
          <div className="product-table-wrapper">
            <table className="product-table orders-table">
              <thead>
                <tr>
                  <th>Order</th>
                  <th>Customer</th>
                  <th>Recipient</th>
                  <th>Items</th>
                  <th>Amount</th>
                  <th>Order status</th>
                  <th>Payment status</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>

              <tbody>
                {orders.map((order) => (
                  <tr key={order.id}>
                    <td>
                      <div className="order-number-cell">
                        <strong>
                          {order.orderNumber}
                        </strong>

                        <small>
                          {order.id}
                        </small>
                      </div>
                    </td>

                    <td>
                      <div className="order-customer-cell">
                        <strong>
                          {order.customer.name}
                        </strong>

                        <span>
                          {order.customer.email}
                        </span>
                      </div>
                    </td>

                    <td>
                      <div className="order-customer-cell">
                        <strong>
                          {order.recipientName}
                        </strong>

                        <span>
                          {order.recipientPhone}
                        </span>
                      </div>
                    </td>

                    <td>
                      {order.itemCount}
                      {" products / "}
                      {order.totalQuantity}
                      {" units"}
                    </td>

                    <td>
                      <strong>
                        {formatMoney(
                          order.totalMinor,
                          order.currency,
                        )}
                      </strong>
                    </td>

                    <td>
                      <span
                        className={
                          readOrderStatusClass(
                            order.status,
                          )
                        }
                      >
                        {readOrderStatusName(
                          order.status,
                        )}
                      </span>
                    </td>

                    <td>
                      <span
                        className={
                          readPaymentStatusClass(
                            order.paymentStatus,
                          )
                        }
                      >
                        {readPaymentStatusName(
                          order.paymentStatus,
                        )}
                      </span>
                    </td>

                    <td>
                      {formatDateTime(
                        order.createdAt,
                      )}
                    </td>

                    <td>
                      <button
                        className="table-action-button"
                        type="button"
                        onClick={() => {
                          void openOrderDetail(
                            order.id,
                          );
                        }}
                      >
                        View details
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {selectedOrderId && (
        <OrderDetailDialog
          order={selectedOrder}
          isLoading={isDetailLoading}
          errorMessage={
            detailErrorMessage
          }
          onClose={closeOrderDetail}
        />
      )}
    </>
  );
}

interface OrderDetailDialogProps {
  order: AdminOrderDetail | null;
  isLoading: boolean;
  errorMessage: string | null;
  onClose(): void;
}

function OrderDetailDialog({
  order,
  isLoading,
  errorMessage,
  onClose,
}: OrderDetailDialogProps) {
  return (
    <div
      className="dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (
          event.target ===
            event.currentTarget &&
          !isLoading
        ) {
          onClose();
        }
      }}
    >
      <section
        className="product-dialog order-detail-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="order-detail-title"
      >
        <header className="dialog-header">
          <div>
            <p className="page-eyebrow">
              ORDER DETAIL
            </p>

            <h2 id="order-detail-title">
              {order?.orderNumber ??
                "Order details"}
            </h2>
          </div>

          <button
            className="dialog-close-button"
            type="button"
            disabled={isLoading}
            onClick={onClose}
            aria-label="Close"
          >
            ×
          </button>
        </header>

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>Loading order details...</p>
          </div>
        ) : errorMessage ? (
          <div className="order-detail-error">
            {errorMessage}
          </div>
        ) : order ? (
          <div className="order-detail-content">
            <section className="order-detail-status-row">
              <span
                className={
                  readOrderStatusClass(
                    order.status,
                  )
                }
              >
                {readOrderStatusName(
                  order.status,
                )}
              </span>

              <span
                className={
                  readPaymentStatusClass(
                    order.paymentStatus,
                  )
                }
              >
                {readPaymentStatusName(
                  order.paymentStatus,
                )}
              </span>
            </section>

            <section className="order-detail-grid">
              <article className="order-detail-section">
                <h3>Customer</h3>

                <dl>
                  <dt>Name</dt>
                  <dd>
                    {order.customer.name}
                  </dd>

                  <dt>Email</dt>
                  <dd>
                    {order.customer.email}
                  </dd>

                  <dt>Ordered at</dt>
                  <dd>
                    {formatDateTime(
                      order.createdAt,
                    )}
                  </dd>
                </dl>
              </article>

              <article className="order-detail-section">
                <h3>Shipping</h3>

                <dl>
                  <dt>Recipient</dt>
                  <dd>
                    {order.recipientName}
                  </dd>

                  <dt>Phone</dt>
                  <dd>
                    {order.recipientPhone}
                  </dd>

                  <dt>Address</dt>
                  <dd>
                    {formatAddress(order)}
                  </dd>
                </dl>
              </article>
            </section>

            <section className="order-detail-section">
              <h3>Line items</h3>

              <div className="order-items-list">
                {order.items.map(
                  (item) => (
                    <article
                      className="order-item-row"
                      key={item.id}
                    >
                      <img
                        src={
                          item.productImage
                        }
                        alt={
                          item.productTitle
                        }
                      />

                      <div className="order-item-information">
                        <strong>
                          {item.productTitle}
                        </strong>

                        <span>
                          {formatMoney(
                            item.unitPriceMinor,
                            order.currency,
                          )}
                          {" × "}
                          {item.quantity}
                        </span>

                        <small>
                          {item.productId}
                        </small>
                      </div>

                      <strong>
                        {formatMoney(
                          item.lineTotalMinor,
                          order.currency,
                        )}
                      </strong>
                    </article>
                  ),
                )}
              </div>
            </section>

            <section className="order-detail-grid">
              <article className="order-detail-section">
                <h3>Customer note</h3>

                <p>
                  {order.customerNote ??
                    "No note"}
                </p>
              </article>

              <article className="order-detail-section order-total-section">
                <h3>Amount</h3>

                <dl>
                  <dt>Subtotal</dt>
                  <dd>
                    {formatMoney(
                      order.subtotalMinor,
                      order.currency,
                    )}
                  </dd>

                  <dt>Shipping</dt>
                  <dd>
                    {formatMoney(
                      order.shippingMinor,
                      order.currency,
                    )}
                  </dd>

                  <dt>Discount</dt>
                  <dd>
                    -
                    {formatMoney(
                      order.discountMinor,
                      order.currency,
                    )}
                  </dd>

                  <dt className="order-total-label">
                    Order total
                  </dt>

                  <dd className="order-total-value">
                    {formatMoney(
                      order.totalMinor,
                      order.currency,
                    )}
                  </dd>
                </dl>
              </article>
            </section>
          </div>
        ) : null}
      </section>
    </div>
  );
}

function formatMoney(
  amountMinor: number,
  currency: string,
): string {
  return new Intl.NumberFormat(
    "en-MY",
    {
      style: "currency",
      currency,
    },
  ).format(amountMinor / 100);
}

function formatDateTime(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "en-MY",
    {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    },
  ).format(new Date(value));
}

function formatAddress(
  order: AdminOrderDetail,
): string {
  return [
    order.addressLine1,
    order.addressLine2,
    order.postalCode,
    order.city,
    order.state,
    order.countryCode,
  ]
    .filter(
      (value) =>
        typeof value === "string" &&
        value.length > 0,
    )
    .join(", ");
}

function readOrderStatusName(
  status: OrderStatus,
): string {
  switch (status) {
    case "PENDING_PAYMENT":
      return "Pending payment";
    case "PAID":
      return "Paid";
    case "PROCESSING":
      return "Processing";
    case "SHIPPED":
      return "Shipped";
    case "DELIVERED":
      return "Delivered";
    case "CANCELLED":
      return "Cancelled";
    case "REFUNDED":
      return "Refunded";
  }
}

function readOrderStatusClass(
  status: OrderStatus,
): string {
  return `order-status-badge order-${status.toLowerCase()}`;
}

function readPaymentStatusName(
  status: PaymentStatus,
): string {
  switch (status) {
    case "UNPAID":
      return "Unpaid";
    case "PROCESSING":
      return "Processing";
    case "PAID":
      return "Paid";
    case "FAILED":
      return "Failed";
    case "REFUNDED":
      return "Refunded";
    case "PARTIALLY_REFUNDED":
      return "Partially refunded";
  }
}

function readPaymentStatusClass(
  status: PaymentStatus,
): string {
  return `payment-status-badge payment-${status.toLowerCase()}`;
}

function readErrorMessage(
  error: unknown,
  fallback: string,
): string {
  if (
    axios.isAxiosError<ErrorResponse>(
      error,
    )
  ) {
    return fallback;
  }

  return fallback;
}
