import axios from "axios";
import {
  type FormEvent,
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  changeInventory,
  getInventoryMovements,
} from "../features/inventory/admin_inventory_api";

import type {
  AdminInventoryMovement,
  ChangeInventoryInput,
  InventoryMovementType,
} from "../features/inventory/inventory";

import {
  getAdminProducts,
} from "../features/products/admin_product_api";

import type {
  AdminProduct,
} from "../features/products/product";

interface ErrorResponse {
  message?: string;
}

export function AdminInventoryPage() {
  const [products, setProducts] =
    useState<AdminProduct[]>([]);

  const [movements, setMovements] =
    useState<AdminInventoryMovement[]>([]);

  const [
    selectedProductId,
    setSelectedProductId,
  ] = useState("");

  const [
    movementFilterProductId,
    setMovementFilterProductId,
  ] = useState("");

  const [operationType, setOperationType] =
    useState<InventoryMovementType>(
      "STOCK_IN",
    );

  const [quantity, setQuantity] =
    useState("");

  const [targetStock, setTargetStock] =
    useState("");

  const [note, setNote] =
    useState("");

  const [isLoading, setIsLoading] =
    useState(true);

  const [isSubmitting, setIsSubmitting] =
    useState(false);

  const [errorMessage, setErrorMessage] =
    useState<string | null>(null);

  const [successMessage, setSuccessMessage] =
    useState<string | null>(null);

  const [reloadKey, setReloadKey] =
    useState(0);

  useEffect(() => {
    let isCancelled = false;

    async function loadPageData():
        Promise<void> {
      setIsLoading(true);
      setErrorMessage(null);

      try {
        const [
          productResult,
          movementResult,
        ] = await Promise.all([
          getAdminProducts(),
          getInventoryMovements(
            undefined,
            200,
          ),
        ]);

        if (isCancelled) {
          return;
        }

        setProducts(productResult);
        setMovements(movementResult);

        setSelectedProductId(
          (currentProductId) => {
            if (
              currentProductId.length > 0 &&
              productResult.some(
                (product) =>
                  product.id ===
                  currentProductId,
              )
            ) {
              return currentProductId;
            }

            return (
              productResult[0]?.id ?? ""
            );
          },
        );
      } catch (error) {
        if (isCancelled) {
          return;
        }

        setErrorMessage(
          readErrorMessage(
            error,
            "加载库存资料失败",
          ),
        );
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    }

    void loadPageData();

    return () => {
      isCancelled = true;
    };
  }, [reloadKey]);

  const selectedProduct = useMemo(() => {
    return products.find(
      (product) =>
        product.id === selectedProductId,
    );
  }, [products, selectedProductId]);

  const filteredMovements = useMemo(() => {
    if (
      movementFilterProductId.length === 0
    ) {
      return movements;
    }

    return movements.filter(
      (movement) =>
        movement.productId ===
        movementFilterProductId,
    );
  }, [
    movementFilterProductId,
    movements,
  ]);

  const totalStock = products.reduce(
    (total, product) =>
      total + product.stock,
    0,
  );

  const todayMovementCount =
    movements.filter((movement) => {
      return isToday(
        new Date(movement.createdAt),
      );
    }).length;

  function refreshInventory(): void {
    setReloadKey(
      (currentValue) =>
        currentValue + 1,
    );
  }

  function changeOperationType(
    nextType: InventoryMovementType,
  ): void {
    setOperationType(nextType);
    setQuantity("");
    setTargetStock("");
    setErrorMessage(null);
    setSuccessMessage(null);
  }

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ): Promise<void> {
    event.preventDefault();

    if (isSubmitting) {
      return;
    }

    if (!selectedProduct) {
      setErrorMessage(
        "请选择需要调整库存的商品",
      );
      return;
    }

    let input: ChangeInventoryInput;

    if (
      operationType === "STOCK_IN" ||
      operationType === "STOCK_OUT"
    ) {
      const parsedQuantity =
        Number(quantity);

      if (
        !Number.isInteger(
          parsedQuantity,
        ) ||
        parsedQuantity <= 0
      ) {
        setErrorMessage(
          "库存数量必须是正整数",
        );
        return;
      }

      if (
        operationType === "STOCK_OUT" &&
        parsedQuantity >
          selectedProduct.stock
      ) {
        setErrorMessage(
          `库存不足，当前库存为 ${selectedProduct.stock}`,
        );
        return;
      }

      input = {
        productId:
          selectedProduct.id,
        type: operationType,
        quantity: parsedQuantity,
        note:
          note.trim().length > 0
            ? note.trim()
            : undefined,
      };
    } else {
      const parsedTargetStock =
        Number(targetStock);

      if (
        !Number.isInteger(
          parsedTargetStock,
        ) ||
        parsedTargetStock < 0
      ) {
        setErrorMessage(
          "盘点库存必须是非负整数",
        );
        return;
      }

      if (
        parsedTargetStock ===
        selectedProduct.stock
      ) {
        setErrorMessage(
          "盘点后的库存与当前库存相同",
        );
        return;
      }

      input = {
        productId:
          selectedProduct.id,
        type: "ADJUSTMENT",
        targetStock:
          parsedTargetStock,
        note:
          note.trim().length > 0
            ? note.trim()
            : undefined,
      };
    }

    setIsSubmitting(true);
    setErrorMessage(null);
    setSuccessMessage(null);

    try {
      const result =
        await changeInventory(input);

      setProducts(
        (currentProducts) =>
          currentProducts.map(
            (product) =>
              product.id ===
              result.product.id
                ? result.product
                : product,
          ),
      );

      const createdMovement:
          AdminInventoryMovement = {
        ...result.movement,
        product: {
          id: result.product.id,
          title:
            result.product.title,
          image:
            result.product.image,
        },
      };

      setMovements(
        (currentMovements) => [
          createdMovement,
          ...currentMovements,
        ],
      );

      setQuantity("");
      setTargetStock("");
      setNote("");

      setSuccessMessage(
        createSuccessMessage(
          operationType,
          result.movement
            .quantityDelta,
          result.product.stock,
        ),
      );
    } catch (error) {
      setErrorMessage(
        readErrorMessage(
          error,
          "库存操作失败",
        ),
      );
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <>
      <header className="page-header page-header-row">
        <div>
          <p className="page-eyebrow">
            INVENTORY
          </p>

          <h1>库存管理</h1>

          <p className="page-description">
            进行商品入库、出库、盘点调整并查看库存流水
          </p>
        </div>

        <button
          className="secondary-button"
          type="button"
          disabled={isLoading}
          onClick={refreshInventory}
        >
          {isLoading
            ? "正在刷新..."
            : "刷新库存"}
        </button>
      </header>

      <section className="product-summary-grid">
        <article className="summary-card">
          <span>商品数量</span>
          <strong>{products.length}</strong>
        </article>

        <article className="summary-card">
          <span>当前总库存</span>
          <strong>{totalStock}</strong>
        </article>

        <article className="summary-card">
          <span>今日库存操作</span>
          <strong>
            {todayMovementCount}
          </strong>
        </article>
      </section>

      <section className="inventory-layout">
        <article className="content-card inventory-operation-card">
          <div className="inventory-section-header">
            <div>
              <h2>库存操作</h2>

              <p>
                每次操作都会产生不可覆盖的库存流水
              </p>
            </div>
          </div>

          {isLoading ? (
            <div className="products-state inventory-form-state">
              <div className="loading-spinner" />
              <p>正在加载商品...</p>
            </div>
          ) : products.length === 0 ? (
            <div className="products-state inventory-form-state">
              <strong>目前没有商品</strong>
              <p>
                请先在商品管理中新增商品。
              </p>
            </div>
          ) : (
            <form
              className="inventory-form"
              onSubmit={handleSubmit}
            >
              <label className="form-field">
                <span>选择商品</span>

                <select
                  value={selectedProductId}
                  disabled={isSubmitting}
                  onChange={(event) => {
                    setSelectedProductId(
                      event.target.value,
                    );

                    setSuccessMessage(null);
                    setErrorMessage(null);
                  }}
                >
                  {products.map(
                    (product) => (
                      <option
                        key={product.id}
                        value={product.id}
                      >
                        {product.title}
                        {" · "}
                        当前库存：
                        {product.stock}
                      </option>
                    ),
                  )}
                </select>
              </label>

              {selectedProduct && (
                <div className="selected-inventory-product">
                  <img
                    src={
                      selectedProduct.image
                    }
                    alt={
                      selectedProduct.title
                    }
                  />

                  <div>
                    <strong>
                      {selectedProduct.title}
                    </strong>

                    <span>
                      当前库存
                    </span>

                    <b>
                      {selectedProduct.stock}
                    </b>
                  </div>
                </div>
              )}

              <div className="inventory-operation-tabs">
                <button
                  type="button"
                  className={
                    operationType ===
                    "STOCK_IN"
                      ? "inventory-operation-tab active"
                      : "inventory-operation-tab"
                  }
                  disabled={isSubmitting}
                  onClick={() => {
                    changeOperationType(
                      "STOCK_IN",
                    );
                  }}
                >
                  商品入库
                </button>

                <button
                  type="button"
                  className={
                    operationType ===
                    "STOCK_OUT"
                      ? "inventory-operation-tab active"
                      : "inventory-operation-tab"
                  }
                  disabled={isSubmitting}
                  onClick={() => {
                    changeOperationType(
                      "STOCK_OUT",
                    );
                  }}
                >
                  商品出库
                </button>

                <button
                  type="button"
                  className={
                    operationType ===
                    "ADJUSTMENT"
                      ? "inventory-operation-tab active"
                      : "inventory-operation-tab"
                  }
                  disabled={isSubmitting}
                  onClick={() => {
                    changeOperationType(
                      "ADJUSTMENT",
                    );
                  }}
                >
                  盘点调整
                </button>
              </div>

              {operationType ===
              "ADJUSTMENT" ? (
                <label className="form-field">
                  <span>
                    盘点后的实际库存
                  </span>

                  <input
                    type="number"
                    min="0"
                    step="1"
                    value={targetStock}
                    disabled={isSubmitting}
                    placeholder={
                      selectedProduct
                        ? `当前为 ${selectedProduct.stock}`
                        : "输入实际库存"
                    }
                    onChange={(event) => {
                      setTargetStock(
                        event.target.value,
                      );
                    }}
                  />
                </label>
              ) : (
                <label className="form-field">
                  <span>
                    {operationType ===
                    "STOCK_IN"
                      ? "入库数量"
                      : "出库数量"}
                  </span>

                  <input
                    type="number"
                    min="1"
                    step="1"
                    value={quantity}
                    disabled={isSubmitting}
                    placeholder="输入数量"
                    onChange={(event) => {
                      setQuantity(
                        event.target.value,
                      );
                    }}
                  />
                </label>
              )}

              <label className="form-field">
                <span>操作备注</span>

                <textarea
                  rows={4}
                  maxLength={500}
                  value={note}
                  disabled={isSubmitting}
                  placeholder={
                    operationType ===
                    "STOCK_IN"
                      ? "例如：供应商到货"
                      : operationType ===
                          "STOCK_OUT"
                        ? "例如：仓库报损"
                        : "例如：月末盘点"
                  }
                  onChange={(event) => {
                    setNote(
                      event.target.value,
                    );
                  }}
                />
              </label>

              {errorMessage && (
                <div
                  className="login-error"
                  role="alert"
                >
                  {errorMessage}
                </div>
              )}

              {successMessage && (
                <div
                  className="inventory-success"
                  role="status"
                >
                  {successMessage}
                </div>
              )}

              <button
                className="primary-button inventory-submit-button"
                type="submit"
                disabled={
                  isSubmitting ||
                  !selectedProduct
                }
              >
                {isSubmitting
                  ? "正在处理..."
                  : readSubmitButtonText(
                      operationType,
                    )}
              </button>
            </form>
          )}
        </article>

        <article className="content-card inventory-history-card">
          <div className="inventory-history-toolbar">
            <div>
              <h2>库存流水</h2>

              <p>
                最近 200 条库存变更记录
              </p>
            </div>

            <label className="inventory-filter">
              <span>筛选商品</span>

              <select
                value={
                  movementFilterProductId
                }
                onChange={(event) => {
                  setMovementFilterProductId(
                    event.target.value,
                  );
                }}
              >
                <option value="">
                  全部商品
                </option>

                {products.map(
                  (product) => (
                    <option
                      key={product.id}
                      value={product.id}
                    >
                      {product.title}
                    </option>
                  ),
                )}
              </select>
            </label>
          </div>

          {isLoading ? (
            <div className="products-state">
              <div className="loading-spinner" />
              <p>正在加载库存流水...</p>
            </div>
          ) : filteredMovements.length ===
            0 ? (
            <div className="products-state">
              <strong>
                暂无库存流水
              </strong>

              <p>
                完成一次入库、出库或盘点后会显示在这里。
              </p>
            </div>
          ) : (
            <div className="product-table-wrapper">
              <table className="product-table inventory-table">
                <thead>
                  <tr>
                    <th>商品</th>
                    <th>类型</th>
                    <th>变动</th>
                    <th>库存变化</th>
                    <th>备注</th>
                    <th>操作人</th>
                    <th>时间</th>
                  </tr>
                </thead>

                <tbody>
                  {filteredMovements.map(
                    (movement) => (
                      <tr key={movement.id}>
                        <td>
                          <div className="inventory-product-cell">
                            <img
                              src={
                                movement.product
                                  .image
                              }
                              alt={
                                movement.product
                                  .title
                              }
                            />

                            <div>
                              <strong>
                                {
                                  movement.product
                                    .title
                                }
                              </strong>

                              <small>
                                {
                                  movement.productId
                                }
                              </small>
                            </div>
                          </div>
                        </td>

                        <td>
                          <span
                            className={
                              readMovementBadgeClass(
                                movement.type,
                              )
                            }
                          >
                            {readMovementTypeName(
                              movement.type,
                            )}
                          </span>
                        </td>

                        <td>
                          <strong
                            className={
                              movement
                                .quantityDelta >
                              0
                                ? "inventory-delta positive"
                                : "inventory-delta negative"
                            }
                          >
                            {movement
                              .quantityDelta >
                            0
                              ? "+"
                              : ""}
                            {
                              movement.quantityDelta
                            }
                          </strong>
                        </td>

                        <td>
                          {movement.stockBefore}
                          {" → "}
                          <strong>
                            {
                              movement.stockAfter
                            }
                          </strong>
                        </td>

                        <td>
                          {movement.note ??
                            "—"}
                        </td>

                        <td>
                          {movement
                            .createdByUser
                            ?.name ??
                            "系统"}
                        </td>

                        <td>
                          {formatDateTime(
                            movement.createdAt,
                          )}
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>
              </table>
            </div>
          )}
        </article>
      </section>
    </>
  );
}

function readSubmitButtonText(
  type: InventoryMovementType,
): string {
  switch (type) {
    case "STOCK_IN":
      return "确认入库";

    case "STOCK_OUT":
      return "确认出库";

    case "ADJUSTMENT":
      return "确认盘点调整";
  }
}

function readMovementTypeName(
  type: InventoryMovementType,
): string {
  switch (type) {
    case "STOCK_IN":
      return "入库";

    case "STOCK_OUT":
      return "出库";

    case "ADJUSTMENT":
      return "盘点";
  }
}

function readMovementBadgeClass(
  type: InventoryMovementType,
): string {
  switch (type) {
    case "STOCK_IN":
      return "inventory-type-badge stock-in";

    case "STOCK_OUT":
      return "inventory-type-badge stock-out";

    case "ADJUSTMENT":
      return "inventory-type-badge adjustment";
  }
}

function createSuccessMessage(
  type: InventoryMovementType,
  quantityDelta: number,
  stockAfter: number,
): string {
  const movementText =
    type === "STOCK_IN"
      ? `成功入库 ${quantityDelta} 件`
      : type === "STOCK_OUT"
        ? `成功出库 ${Math.abs(
            quantityDelta,
          )} 件`
        : `库存已调整 ${quantityDelta > 0 ? "+" : ""}${quantityDelta}`;

  return `${movementText}，当前库存为 ${stockAfter}`;
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

function isToday(date: Date): boolean {
  const today = new Date();

  return (
    date.getFullYear() ===
      today.getFullYear() &&
    date.getMonth() ===
      today.getMonth() &&
    date.getDate() ===
      today.getDate()
  );
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