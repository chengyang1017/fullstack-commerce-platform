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
            "加载订单失败",
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
          "加载订单详情失败",
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

          <h1>订单管理</h1>

          <p className="page-description">
            查看客户订单、付款状态、商品明细和收货资料
          </p>
        </div>

        <button
          className="secondary-button"
          type="button"
          disabled={isLoading}
          onClick={refreshOrders}
        >
          {isLoading
            ? "正在刷新..."
            : "刷新订单"}
        </button>
      </header>

      <section className="order-summary-grid">
        <article className="summary-card">
          <span>当前结果</span>
          <strong>{orders.length}</strong>
        </article>

        <article className="summary-card">
          <span>待付款</span>
          <strong>
            {pendingPaymentCount}
          </strong>
        </article>

        <article className="summary-card">
          <span>待处理</span>
          <strong>
            {processingCount}
          </strong>
        </article>

        <article className="summary-card">
          <span>已付款金额</span>
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
              placeholder="搜索订单号、客户、电话或邮箱"
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
              搜索
            </button>

            {(keyword.length > 0 ||
              keywordInput.length > 0) && (
              <button
                className="secondary-button"
                type="button"
                onClick={clearSearch}
              >
                清除
              </button>
            )}
          </form>

          <div className="order-filter-group">
            <label>
              <span>订单状态</span>

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
                  全部订单状态
                </option>

                <option value="PENDING_PAYMENT">
                  待付款
                </option>

                <option value="PAID">
                  已付款
                </option>

                <option value="PROCESSING">
                  处理中
                </option>

                <option value="SHIPPED">
                  已发货
                </option>

                <option value="DELIVERED">
                  已送达
                </option>

                <option value="CANCELLED">
                  已取消
                </option>

                <option value="REFUNDED">
                  已退款
                </option>
              </select>
            </label>

            <label>
              <span>付款状态</span>

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
                  全部付款状态
                </option>

                <option value="UNPAID">
                  未付款
                </option>

                <option value="PROCESSING">
                  付款处理中
                </option>

                <option value="PAID">
                  已付款
                </option>

                <option value="FAILED">
                  付款失败
                </option>

                <option value="REFUNDED">
                  已退款
                </option>

                <option value="PARTIALLY_REFUNDED">
                  部分退款
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
              重试
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>正在加载订单...</p>
          </div>
        ) : orders.length === 0 ? (
          <div className="products-state">
            <strong>
              没有符合条件的订单
            </strong>

            <p>
              可以修改筛选条件或清除搜索内容。
            </p>
          </div>
        ) : (
          <div className="product-table-wrapper">
            <table className="product-table orders-table">
              <thead>
                <tr>
                  <th>订单</th>
                  <th>客户</th>
                  <th>收货人</th>
                  <th>商品</th>
                  <th>金额</th>
                  <th>订单状态</th>
                  <th>付款状态</th>
                  <th>创建时间</th>
                  <th>操作</th>
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
                      {" 种 / "}
                      {order.totalQuantity}
                      {" 件"}
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
                        查看详情
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
                "订单详情"}
            </h2>
          </div>

          <button
            className="dialog-close-button"
            type="button"
            disabled={isLoading}
            onClick={onClose}
            aria-label="关闭"
          >
            ×
          </button>
        </header>

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>正在加载订单详情...</p>
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
                <h3>客户资料</h3>

                <dl>
                  <dt>客户名称</dt>
                  <dd>
                    {order.customer.name}
                  </dd>

                  <dt>客户邮箱</dt>
                  <dd>
                    {order.customer.email}
                  </dd>

                  <dt>下单时间</dt>
                  <dd>
                    {formatDateTime(
                      order.createdAt,
                    )}
                  </dd>
                </dl>
              </article>

              <article className="order-detail-section">
                <h3>收货资料</h3>

                <dl>
                  <dt>收货人</dt>
                  <dd>
                    {order.recipientName}
                  </dd>

                  <dt>联系电话</dt>
                  <dd>
                    {order.recipientPhone}
                  </dd>

                  <dt>地址</dt>
                  <dd>
                    {formatAddress(order)}
                  </dd>
                </dl>
              </article>
            </section>

            <section className="order-detail-section">
              <h3>商品明细</h3>

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
                <h3>客户备注</h3>

                <p>
                  {order.customerNote ??
                    "没有备注"}
                </p>
              </article>

              <article className="order-detail-section order-total-section">
                <h3>金额</h3>

                <dl>
                  <dt>商品小计</dt>
                  <dd>
                    {formatMoney(
                      order.subtotalMinor,
                      order.currency,
                    )}
                  </dd>

                  <dt>运费</dt>
                  <dd>
                    {formatMoney(
                      order.shippingMinor,
                      order.currency,
                    )}
                  </dd>

                  <dt>优惠</dt>
                  <dd>
                    -
                    {formatMoney(
                      order.discountMinor,
                      order.currency,
                    )}
                  </dd>

                  <dt className="order-total-label">
                    订单总额
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
    "ms-MY",
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
    "zh-CN",
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
      return "待付款";
    case "PAID":
      return "已付款";
    case "PROCESSING":
      return "处理中";
    case "SHIPPED":
      return "已发货";
    case "DELIVERED":
      return "已送达";
    case "CANCELLED":
      return "已取消";
    case "REFUNDED":
      return "已退款";
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
      return "未付款";
    case "PROCESSING":
      return "付款处理中";
    case "PAID":
      return "已付款";
    case "FAILED":
      return "付款失败";
    case "REFUNDED":
      return "已退款";
    case "PARTIALLY_REFUNDED":
      return "部分退款";
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
    return (
      error.response?.data.message ??
      fallback
    );
  }

  return fallback;
}