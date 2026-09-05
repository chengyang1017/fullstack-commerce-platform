import axios from "axios";
import {
  type FormEvent,
  useEffect,
  useState,
} from "react";

import {
  activateAdminCategory,
  createAdminCategory,
  deactivateAdminCategory,
  getAdminCategories,
  updateAdminCategory,
} from "../features/categories/admin_category_api";

import type {
  AdminCategory,
} from "../features/categories/category";

interface ErrorResponse {
  message?: string;
}

export function AdminCategoriesPage() {
  const [categories, setCategories] =
    useState<AdminCategory[]>([]);

  const [isLoading, setIsLoading] =
    useState(true);

  const [errorMessage, setErrorMessage] =
    useState<string | null>(null);

  const [
    editingCategory,
    setEditingCategory,
  ] = useState<AdminCategory | null>(null);

  const [formOpen, setFormOpen] =
    useState(false);

  const [isSaving, setIsSaving] =
    useState(false);

  const [busyCategoryId, setBusyCategoryId] =
    useState<string | null>(null);

  const [reloadKey, setReloadKey] =
    useState(0);

  useEffect(() => {
    let isCancelled = false;

    async function loadCategories():
        Promise<void> {
      setIsLoading(true);
      setErrorMessage(null);

      try {
        const result =
          await getAdminCategories();

        if (isCancelled) {
          return;
        }

        setCategories(result);
      } catch (error) {
        if (isCancelled) {
          return;
        }

        setErrorMessage(
          readErrorMessage(
            error,
            "Failed to load categories.",
          ),
        );
      } finally {
        if (!isCancelled) {
          setIsLoading(false);
        }
      }
    }

    void loadCategories();

    return () => {
      isCancelled = true;
    };
  }, [reloadKey]);

  function refreshCategories(): void {
    setReloadKey(
      (currentValue) => currentValue + 1,
    );
  }

  function openCreateForm(): void {
    setEditingCategory(null);
    setFormOpen(true);
    setErrorMessage(null);
  }

  function openEditForm(
    category: AdminCategory,
  ): void {
    setEditingCategory(category);
    setFormOpen(true);
    setErrorMessage(null);
  }

  function closeForm(): void {
    if (isSaving) {
      return;
    }

    setFormOpen(false);
    setEditingCategory(null);
  }

  async function saveCategory(
    name: string,
    sortOrder: number,
  ): Promise<void> {
    if (isSaving) {
      return;
    }

    setIsSaving(true);
    setErrorMessage(null);

    try {
      if (editingCategory) {
        const updatedCategory =
          await updateAdminCategory(
            editingCategory.id,
            {
              name,
              sortOrder,
            },
          );

        setCategories(
          (currentCategories) =>
            currentCategories
              .map((category) =>
                category.id ===
                updatedCategory.id
                  ? updatedCategory
                  : category,
              )
              .sort(compareCategories),
        );
      } else {
        const createdCategory =
          await createAdminCategory({
            name,
            sortOrder,
          });

        setCategories(
          (currentCategories) =>
            [
              ...currentCategories,
              createdCategory,
            ].sort(compareCategories),
        );
      }

      setFormOpen(false);
      setEditingCategory(null);
    } catch (error) {
      setErrorMessage(
        readErrorMessage(
          error,
          editingCategory
            ? "Failed to update the category."
            : "Failed to create the category.",
        ),
      );
    } finally {
      setIsSaving(false);
    }
  }

  async function toggleCategoryStatus(
    category: AdminCategory,
  ): Promise<void> {
    if (busyCategoryId !== null) {
      return;
    }

    if (
      category.isActive &&
      !window.confirm(
        `Deactivate the “${category.name}” category?`,
      )
    ) {
      return;
    }

    setBusyCategoryId(category.id);
    setErrorMessage(null);

    try {
      if (category.isActive) {
        await deactivateAdminCategory(
          category.id,
        );

        setCategories(
          (currentCategories) =>
            currentCategories.map(
              (currentCategory) =>
                currentCategory.id ===
                category.id
                  ? {
                      ...currentCategory,
                      isActive: false,
                    }
                  : currentCategory,
            ),
        );
      } else {
        const updatedCategory =
          await activateAdminCategory(
            category.id,
          );

        setCategories(
          (currentCategories) =>
            currentCategories.map(
              (currentCategory) =>
                currentCategory.id ===
                updatedCategory.id
                  ? updatedCategory
                  : currentCategory,
            ),
        );
      }
    } catch (error) {
      setErrorMessage(
        readErrorMessage(
          error,
          category.isActive
            ? "Failed to deactivate the category."
            : "Failed to activate the category.",
        ),
      );
    } finally {
      setBusyCategoryId(null);
    }
  }

  const activeCount = categories.filter(
    (category) => category.isActive,
  ).length;

  return (
    <>
      <header className="page-header page-header-row">
        <div>
          <p className="page-eyebrow">
            CATEGORIES
          </p>

          <h1>Category management</h1>

          <p className="page-description">
            Manage product categories, display order, and availability.
          </p>
        </div>

        <button
          className="primary-button"
          type="button"
          onClick={openCreateForm}
        >
          Add category
        </button>
      </header>

      <section className="product-summary-grid">
        <article className="summary-card">
          <span>All categories</span>
          <strong>{categories.length}</strong>
        </article>

        <article className="summary-card">
          <span>Active</span>
          <strong>{activeCount}</strong>
        </article>

        <article className="summary-card">
          <span>Inactive</span>
          <strong>
            {categories.length - activeCount}
          </strong>
        </article>
      </section>

      <section className="content-card products-card">
        <div className="products-toolbar">
          <strong>Category list</strong>

          <button
            className="secondary-button"
            type="button"
            disabled={isLoading}
            onClick={refreshCategories}
          >
            {isLoading
              ? "Refreshing..."
              : "Refresh"}
          </button>
        </div>

        {errorMessage && (
          <div
            className="products-error"
            role="alert"
          >
            <span>{errorMessage}</span>

            <button
              type="button"
              onClick={() => {
                setErrorMessage(null);
              }}
            >
              Close
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>Loading categories...</p>
          </div>
        ) : categories.length === 0 ? (
          <div className="products-state">
            <strong>No categories yet</strong>
            <p>Create your first product category.</p>
          </div>
        ) : (
          <div className="product-table-wrapper">
            <table className="product-table">
              <thead>
                <tr>
                  <th>Category name</th>
                  <th>Category ID</th>
                  <th>Sort order</th>
                  <th>Products</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>

              <tbody>
                {categories.map(
                  (category) => {
                    const isBusy =
                      busyCategoryId ===
                      category.id;

                    return (
                      <tr key={category.id}>
                        <td>
                          <strong>
                            {category.name}
                          </strong>
                        </td>

                        <td>
                          <code>
                            {category.id}
                          </code>
                        </td>

                        <td>
                          {category.sortOrder}
                        </td>

                        <td>
                          {category.productCount}
                        </td>

                        <td>
                          <span
                            className={
                              category.isActive
                                ? "status-badge active"
                                : "status-badge inactive"
                            }
                          >
                            {category.isActive
                              ? "Active"
                              : "Inactive"}
                          </span>
                        </td>

                        <td>
                          <div className="product-actions">
                            <button
                              className="table-action-button"
                              type="button"
                              disabled={isBusy}
                              onClick={() => {
                                openEditForm(
                                  category,
                                );
                              }}
                            >
                              Edit
                            </button>

                            <button
                              className={
                                category.isActive
                                  ? "table-action-button danger"
                                  : "table-action-button success"
                              }
                              type="button"
                              disabled={isBusy}
                              onClick={() => {
                                void toggleCategoryStatus(
                                  category,
                                );
                              }}
                            >
                              {isBusy
                                ? "Processing..."
                                : category.isActive
                                  ? "Deactivate"
                                  : "Activate"}
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  },
                )}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {formOpen && (
        <CategoryFormDialog
          key={
            editingCategory
              ? editingCategory.id
              : "create"
          }
          category={editingCategory}
          isSubmitting={isSaving}
          onClose={closeForm}
          onSubmit={saveCategory}
        />
      )}
    </>
  );
}

interface CategoryFormDialogProps {
  category: AdminCategory | null;
  isSubmitting: boolean;

  onClose(): void;

  onSubmit(
    name: string,
    sortOrder: number,
  ): Promise<void>;
}

function CategoryFormDialog({
  category,
  isSubmitting,
  onClose,
  onSubmit,
}: CategoryFormDialogProps) {
  const [name, setName] =
    useState(category?.name ?? "");

  const [sortOrder, setSortOrder] =
    useState(
      category
        ? category.sortOrder.toString()
        : "0",
    );

  const [
    validationMessage,
    setValidationMessage,
  ] = useState<string | null>(null);

  async function handleSubmit(
    event: FormEvent<HTMLFormElement>,
  ): Promise<void> {
    event.preventDefault();

    const normalizedName = name.trim();
    const parsedSortOrder =
      Number(sortOrder);

    if (normalizedName.length === 0) {
      setValidationMessage(
        "Enter a category name.",
      );
      return;
    }

    if (
      !Number.isInteger(parsedSortOrder) ||
      parsedSortOrder < 0
    ) {
      setValidationMessage(
        "Sort order must be a non-negative integer.",
      );
      return;
    }

    setValidationMessage(null);

    await onSubmit(
      normalizedName,
      parsedSortOrder,
    );
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
        className="product-dialog category-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="category-dialog-title"
      >
        <header className="dialog-header">
          <div>
            <p className="page-eyebrow">
              {category
                ? "EDIT CATEGORY"
                : "CREATE CATEGORY"}
            </p>

            <h2 id="category-dialog-title">
              {category
                ? "Edit category"
                : "Add category"}
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
          <label className="form-field">
            <span>Category name</span>

            <input
              value={name}
              disabled={isSubmitting}
              placeholder="e.g. Phones"
              onChange={(event) => {
                setName(event.target.value);
              }}
            />
          </label>

          <label className="form-field">
            <span>Display order</span>

            <input
              type="number"
              min="0"
              step="1"
              value={sortOrder}
              disabled={isSubmitting}
              onChange={(event) => {
                setSortOrder(
                  event.target.value,
                );
              }}
            />
          </label>

          {validationMessage && (
            <div
              className="login-error"
              role="alert"
            >
              {validationMessage}
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
              disabled={isSubmitting}
            >
              {isSubmitting
                ? "Saving..."
                : category
                  ? "Save changes"
                  : "Create category"}
            </button>
          </footer>
        </form>
      </section>
    </div>
  );
}

function compareCategories(
  first: AdminCategory,
  second: AdminCategory,
): number {
  if (
    first.sortOrder !==
    second.sortOrder
  ) {
    return (
      first.sortOrder -
      second.sortOrder
    );
  }

  return first.createdAt.localeCompare(
    second.createdAt,
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
    return fallback;
  }

  return fallback;
}
