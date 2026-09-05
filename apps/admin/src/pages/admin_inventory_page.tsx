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

    async function loadPageData(): Promise<void> {
      setIsLoading(true);
      setErrorMessage(null);

      try {
        const [productResult, movementResult] =
          await Promise.all([
            getAdminProducts(),
            getInventoryMovements(undefined, 200),
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
                  product.id === currentProductId,
              )
            ) {
              return currentProductId;
            }

            return productResult[0]?.id ?? "";
          },
        );
      } catch (error) {
        if (isCancelled) {
          return;
        }

        setErrorMessage(
          readErrorMessage(
            error,
            "Failed to load inventory data.",
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
    if (movementFilterProductId.length === 0) {
      return movements;
    }

    return movements.filter(
      (movement) =>
        movement.productId === movementFilterProductId,
    );
  }, [movementFilterProductId, movements]);

  const totalStock = products.reduce(
    (total, product) => total + product.stock,
    0,
  );

  const todayMovementCount = movements.filter(
    (movement) =>
      isToday(new Date(movement.createdAt)),
  ).length;

  function refreshInventory(): void {
    setReloadKey((currentValue) => currentValue + 1);
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
        "Select a product before changing inventory.",
      );
      return;
    }

    let input: ChangeInventoryInput;

    if (
      operationType === "STOCK_IN" ||
      operationType === "STOCK_OUT"
    ) {
      const parsedQuantity = Number(quantity);

      if (
        !Number.isInteger(parsedQuantity) ||
        parsedQuantity <= 0
      ) {
        setErrorMessage(
          "Quantity must be a positive integer.",
        );
        return;
      }

      if (
        operationType === "STOCK_OUT" &&
        parsedQuantity > selectedProduct.stock
      ) {
        setErrorMessage(
          `Not enough stock. Current stock is ${selectedProduct.stock}.`,
        );
        return;
      }

      input = {
        productId: selectedProduct.id,
        type: operationType,
        quantity: parsedQuantity,
        note:
          note.trim().length > 0
            ? note.trim()
            : undefined,
      };
    } else {
      const parsedTargetStock = Number(targetStock);

      if (
        !Number.isInteger(parsedTargetStock) ||
        parsedTargetStock < 0
      ) {
        setErrorMessage(
          "Counted stock must be a non-negative integer.",
        );
        return;
      }

      if (parsedTargetStock === selectedProduct.stock) {
        setErrorMessage(
          "The counted stock is the same as the current stock.",
        );
        return;
      }

      input = {
        productId: selectedProduct.id,
        type: "ADJUSTMENT",
        targetStock: parsedTargetStock,
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
      const result = await changeInventory(input);

      setProducts((currentProducts) =>
        currentProducts.map((product) =>
          product.id === result.product.id
            ? result.product
            : product,
        ),
      );

      const createdMovement: AdminInventoryMovement = {
        ...result.movement,
        product: {
          id: result.product.id,
          title: result.product.title,
          image: result.product.image,
        },
      };

      setMovements((currentMovements) => [
        createdMovement,
        ...currentMovements,
      ]);

      setQuantity("");
      setTargetStock("");
      setNote("");

      setSuccessMessage(
        createSuccessMessage(
          operationType,
          result.movement.quantityDelta,
          result.product.stock,
        ),
      );
    } catch (error) {
      setErrorMessage(
        readErrorMessage(
          error,
          "Inventory operation failed.",
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
          <p className="page-eyebrow">INVENTORY</p>
          <h1>Inventory management</h1>
          <p className="page-description">
            Receive stock, remove stock, reconcile counts, and review inventory history.
          </p>
        </div>

        <button
          className="secondary-button"
          type="button"
          disabled={isLoading}
          onClick={refreshInventory}
        >
          {isLoading ? "Refreshing..." : "Refresh inventory"}
        </button>
      </header>

      <section className="product-summary-grid">
        <article className="summary-card">
          <span>Products</span>
          <strong>{products.length}</strong>
        </article>

        <article className="summary-card">
          <span>Total stock</span>
          <strong>{totalStock}</strong>
        </article>

        <article className="summary-card">
          <span>Operations today</span>
          <strong>{todayMovementCount}</strong>
        </article>
      </section>

      <section className="inventory-layout">
        <article className="content-card inventory-operation-card">
          <div className="inventory-section-header">
            <div>
              <h2>Inventory operation</h2>
              <p>Every change creates an immutable inventory movement record.</p>
            </div>
          </div>

          {isLoading ? (
            <div className="products-state inventory-form-state">
              <div className="loading-spinner" />
              <p>Loading products...</p>
            </div>
          ) : products.length === 0 ? (
            <div className="products-state inventory-form-state">
              <strong>No products yet</strong>
              <p>Add a product before managing inventory.</p>
            </div>
          ) : (
            <form
              className="inventory-form"
              onSubmit={handleSubmit}
            >
              <label className="form-field">
                <span>Select product</span>

                <select
                  value={selectedProductId}
                  disabled={isSubmitting}
                  onChange={(event) => {
                    setSelectedProductId(event.target.value);
                    setSuccessMessage(null);
                    setErrorMessage(null);
                  }}
                >
                  {products.map((product) => (
                    <option
                      key={product.id}
                      value={product.id}
                    >
                      {product.title}
                      {" · Current stock: "}
                      {product.stock}
                    </option>
                  ))}
                </select>
              </label>

              {selectedProduct && (
                <div className="selected-inventory-product">
                  <img
                    src={selectedProduct.image}
                    alt={selectedProduct.title}
                  />

                  <div>
                    <strong>{selectedProduct.title}</strong>
                    <span>Current stock</span>
                    <b>{selectedProduct.stock}</b>
                  </div>
                </div>
              )}

              <div className="inventory-operation-tabs">
                <button
                  type="button"
                  className={
                    operationType === "STOCK_IN"
                      ? "inventory-operation-tab active"
                      : "inventory-operation-tab"
                  }
                  disabled={isSubmitting}
                  onClick={() => changeOperationType("STOCK_IN")}
                >
                  Stock in
                </button>

                <button
                  type="button"
                  className={
                    operationType === "STOCK_OUT"
                      ? "inventory-operation-tab active"
                      : "inventory-operation-tab"
                  }
                  disabled={isSubmitting}
                  onClick={() => changeOperationType("STOCK_OUT")}
                >
                  Stock out
                </button>

                <button
                  type="button"
                  className={
                    operationType === "ADJUSTMENT"
                      ? "inventory-operation-tab active"
                      : "inventory-operation-tab"
                  }
                  disabled={isSubmitting}
                  onClick={() => changeOperationType("ADJUSTMENT")}
                >
                  Reconcile
                </button>
              </div>

              {operationType === "ADJUSTMENT" ? (
                <label className="form-field">
                  <span>Counted stock</span>
                  <input
                    type="number"
                    min="0"
                    step="1"
                    value={targetStock}
                    disabled={isSubmitting}
                    placeholder={
                      selectedProduct
                        ? `Current: ${selectedProduct.stock}`
                        : "Enter counted stock"
                    }
                    onChange={(event) => {
                      setTargetStock(event.target.value);
                    }}
                  />
                </label>
              ) : (
                <label className="form-field">
                  <span>
                    {operationType === "STOCK_IN"
                      ? "Quantity received"
                      : "Quantity removed"}
                  </span>

                  <input
                    type="number"
                    min="1"
                    step="1"
                    value={quantity}
                    disabled={isSubmitting}
                    placeholder="Enter quantity"
                    onChange={(event) => {
                      setQuantity(event.target.value);
                    }}
                  />
                </label>
              )}

              <label className="form-field">
                <span>Note</span>

                <textarea
                  rows={4}
                  maxLength={500}
                  value={note}
                  disabled={isSubmitting}
                  placeholder={
                    operationType === "STOCK_IN"
                      ? "e.g. Supplier delivery"
                      : operationType === "STOCK_OUT"
                        ? "e.g. Damaged stock"
                        : "e.g. Month-end stock count"
                  }
                  onChange={(event) => {
                    setNote(event.target.value);
                  }}
                />
              </label>

              {errorMessage && (
                <div className="login-error" role="alert">
                  {errorMessage}
                </div>
              )}

              {successMessage && (
                <div className="inventory-success" role="status">
                  {successMessage}
                </div>
              )}

              <button
                className="primary-button inventory-submit-button"
                type="submit"
                disabled={isSubmitting || !selectedProduct}
              >
                {isSubmitting
                  ? "Processing..."
                  : readSubmitButtonText(operationType)}
              </button>
            </form>
          )}
        </article>

        <article className="content-card inventory-history-card">
          <div className="inventory-history-toolbar">
            <div>
              <h2>Inventory history</h2>
              <p>Latest 200 inventory movements</p>
            </div>

            <label className="inventory-filter">
              <span>Filter by product</span>
              <select
                value={movementFilterProductId}
                onChange={(event) => {
                  setMovementFilterProductId(event.target.value);
                }}
              >
                <option value="">All products</option>
                {products.map((product) => (
                  <option
                    key={product.id}
                    value={product.id}
                  >
                    {product.title}
                  </option>
                ))}
              </select>
            </label>
          </div>

          {isLoading ? (
            <div className="products-state">
              <div className="loading-spinner" />
              <p>Loading inventory history...</p>
            </div>
          ) : filteredMovements.length === 0 ? (
            <div className="products-state">
              <strong>No inventory movements</strong>
              <p>Stock in, stock out, and reconciliation records will appear here.</p>
            </div>
          ) : (
            <div className="product-table-wrapper">
              <table className="product-table inventory-table">
                <thead>
                  <tr>
                    <th>Product</th>
                    <th>Type</th>
                    <th>Change</th>
                    <th>Stock change</th>
                    <th>Note</th>
                    <th>Operator</th>
                    <th>Time</th>
                  </tr>
                </thead>

                <tbody>
                  {filteredMovements.map((movement) => (
                    <tr key={movement.id}>
                      <td>
                        <div className="inventory-product-cell">
                          <img
                            src={movement.product.image}
                            alt={movement.product.title}
                          />
                          <div>
                            <strong>{movement.product.title}</strong>
                            <small>{movement.productId}</small>
                          </div>
                        </div>
                      </td>

                      <td>
                        <span className={readMovementBadgeClass(movement.type)}>
                          {readMovementTypeName(movement.type)}
                        </span>
                      </td>

                      <td>
                        <strong
                          className={
                            movement.quantityDelta > 0
                              ? "inventory-delta positive"
                              : "inventory-delta negative"
                          }
                        >
                          {movement.quantityDelta > 0 ? "+" : ""}
                          {movement.quantityDelta}
                        </strong>
                      </td>

                      <td>
                        {movement.stockBefore}
                        {" → "}
                        <strong>{movement.stockAfter}</strong>
                      </td>

                      <td>{movement.note ?? "—"}</td>
                      <td>{movement.createdByUser?.name ?? "System"}</td>
                      <td>{formatDateTime(movement.createdAt)}</td>
                    </tr>
                  ))}
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
      return "Confirm stock in";
    case "STOCK_OUT":
      return "Confirm stock out";
    case "ADJUSTMENT":
      return "Confirm reconciliation";
  }
}

function readMovementTypeName(
  type: InventoryMovementType,
): string {
  switch (type) {
    case "STOCK_IN":
      return "Stock in";
    case "STOCK_OUT":
      return "Stock out";
    case "ADJUSTMENT":
      return "Reconciliation";
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
      ? `Received ${quantityDelta} units`
      : type === "STOCK_OUT"
        ? `Removed ${Math.abs(quantityDelta)} units`
        : `Stock adjusted ${quantityDelta > 0 ? "+" : ""}${quantityDelta}`;

  return `${movementText}. Current stock: ${stockAfter}.`;
}

function formatDateTime(value: string): string {
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

function isToday(date: Date): boolean {
  const today = new Date();

  return (
    date.getFullYear() === today.getFullYear() &&
    date.getMonth() === today.getMonth() &&
    date.getDate() === today.getDate()
  );
}

function readErrorMessage(
  error: unknown,
  fallback: string,
): string {
  if (axios.isAxiosError<ErrorResponse>(error)) {
    return fallback;
  }

  return fallback;
}
