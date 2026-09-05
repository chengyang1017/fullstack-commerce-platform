import {
  type FormEvent,
  useState,
} from "react";

import type {
  AdminCategory,
} from "../categories/category";
import type {
  AdminProduct,
  CreateProductInput,
} from "./product";

interface ProductFormDialogProps {
  open: boolean;
  product: AdminProduct | null;
  categories: AdminCategory[];
  isSubmitting: boolean;
  errorMessage: string | null;

  onClose(): void;

  onSubmit(
    input: CreateProductInput,
  ): Promise<void>;
}

export function ProductFormDialog({
  open,
  product,
  categories,
  isSubmitting,
  errorMessage,
  onClose,
  onSubmit,
}: ProductFormDialogProps) {
  if (!open) {
    return null;
  }

  const formKey = product
    ? `edit-${product.id}`
    : "create";

  return (
    <ProductFormContent
      key={formKey}
      product={product}
      categories={categories}
      isSubmitting={isSubmitting}
      errorMessage={errorMessage}
      onClose={onClose}
      onSubmit={onSubmit}
    />
  );
}

interface ProductFormContentProps {
  product: AdminProduct | null;
  categories: AdminCategory[];
  isSubmitting: boolean;
  errorMessage: string | null;

  onClose(): void;

  onSubmit(
    input: CreateProductInput,
  ): Promise<void>;
}

function ProductFormContent({
  product,
  categories,
  isSubmitting,
  errorMessage,
  onClose,
  onSubmit,
}: ProductFormContentProps) {
  const [categoryId, setCategoryId] =
    useState(
      product?.categoryId ??
        categories[0]?.id ??
        "",
    );

  const [title, setTitle] =
    useState(product?.title ?? "");

  const [description, setDescription] =
    useState(
      product?.description ?? "",
    );

  const [imageUrl, setImageUrl] =
    useState(product?.image ?? "");

  const [price, setPrice] =
    useState(
      product
        ? product.price.toString()
        : "",
    );

  const [stock, setStock] =
    useState(
      product
        ? product.stock.toString()
        : "",
    );

  const [
    validationMessage,
    setValidationMessage,
  ] = useState<string | null>(null);

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ): Promise<void> {
    event.preventDefault();

    if (isSubmitting) {
      return;
    }

    const normalizedTitle =
      title.trim();

    const normalizedImageUrl =
      imageUrl.trim();

    const parsedPrice = Number(price);
    const parsedStock = Number(stock);

    if (categoryId.length === 0) {
      setValidationMessage(
        "Select a product category.",
      );
      return;
    }

    if (normalizedTitle.length === 0) {
      setValidationMessage(
        "Enter a product name.",
      );
      return;
    }

    if (
      normalizedImageUrl.length === 0
    ) {
      setValidationMessage(
        "Enter a product image URL.",
      );
      return;
    }

    if (
      !Number.isFinite(parsedPrice) ||
      parsedPrice < 0
    ) {
      setValidationMessage(
        "Enter a valid product price.",
      );
      return;
    }

    if (
      !Number.isInteger(parsedStock) ||
      parsedStock < 0
    ) {
      setValidationMessage(
        "Stock must be a non-negative integer.",
      );
      return;
    }

    setValidationMessage(null);

    await onSubmit({
      categoryId,
      title: normalizedTitle,
      description:
        description.trim(),
      imageUrl: normalizedImageUrl,
      price: parsedPrice,
      stock: parsedStock,
    });
  }

  return (
    <div
      className="dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (
          event.target ===
            event.currentTarget &&
          !isSubmitting
        ) {
          onClose();
        }
      }}
    >
      <section
        className="product-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="product-dialog-title"
      >
        <header className="dialog-header">
          <div>
            <p className="page-eyebrow">
              {product
                ? "EDIT PRODUCT"
                : "CREATE PRODUCT"}
            </p>

            <h2 id="product-dialog-title">
              {product
                ? "Edit product"
                : "Add product"}
            </h2>
          </div>

          <button
            className="dialog-close-button"
            type="button"
            disabled={isSubmitting}
            onClick={onClose}
            aria-label="Close"
          >
            ×
          </button>
        </header>

        <form
          className="product-form"
          onSubmit={handleSubmit}
        >
          <div className="form-grid">
            <label className="form-field">
              <span>Category</span>

              <select
                value={categoryId}
                disabled={isSubmitting}
                onChange={(event) => {
                  setCategoryId(
                    event.target.value,
                  );
                }}
              >
                {categories.map(
                  (category) => (
                    <option
                      key={category.id}
                      value={category.id}
                    >
                      {category.name}
                    </option>
                  ),
                )}
              </select>
            </label>

            <label className="form-field">
              <span>Product name</span>

              <input
                value={title}
                disabled={isSubmitting}
                placeholder="e.g. Smartphone"
                onChange={(event) => {
                  setTitle(
                    event.target.value,
                  );
                }}
              />
            </label>

            <label className="form-field">
              <span>Price (RM)</span>

              <input
                type="number"
                min="0"
                step="0.01"
                value={price}
                disabled={isSubmitting}
                placeholder="1299.00"
                onChange={(event) => {
                  setPrice(
                    event.target.value,
                  );
                }}
              />
            </label>

            <label className="form-field">
              <span>Stock</span>

              <input
                type="number"
                min="0"
                step="1"
                value={stock}
                disabled={isSubmitting}
                placeholder="50"
                onChange={(event) => {
                  setStock(
                    event.target.value,
                  );
                }}
              />
            </label>
          </div>

          <label className="form-field">
            <span>Product image URL</span>

            <input
              type="url"
              value={imageUrl}
              disabled={isSubmitting}
              placeholder="https://..."
              onChange={(event) => {
                setImageUrl(
                  event.target.value,
                );
              }}
            />
          </label>

          {imageUrl.trim().length > 0 && (
            <div className="product-image-preview">
              <img
                src={imageUrl}
                alt="Product preview"
                onError={(event) => {
                  event.currentTarget.src =
                    "https://placehold.co/160x160?text=No+Image";
                }}
              />

              <span>Image preview</span>
            </div>
          )}

          <label className="form-field">
            <span>Description</span>

            <textarea
              rows={5}
              value={description}
              disabled={isSubmitting}
              placeholder="Enter a product description"
              onChange={(event) => {
                setDescription(
                  event.target.value,
                );
              }}
            />
          </label>

          {(validationMessage ||
            errorMessage) && (
            <div
              className="login-error"
              role="alert"
            >
              {validationMessage ??
                errorMessage}
            </div>
          )}

          <footer className="dialog-actions">
            <button
              className="secondary-button"
              type="button"
              disabled={isSubmitting}
              onClick={onClose}
            >
              Cancel
            </button>

            <button
              className="primary-button"
              type="submit"
              disabled={
                isSubmitting ||
                categories.length === 0
              }
            >
              {isSubmitting
                ? "Saving..."
                : product
                  ? "Save changes"
                  : "Create product"}
            </button>
          </footer>
        </form>
      </section>
    </div>
  );
}
