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
  CreateCategoryInput,
} from "../features/categories/category";

interface ErrorResponse {
  message?: string;
}

const ICON_OPTIONS = [
  ["category", "Category"],
  ["devices", "Electronics / Devices"],
  ["cable", "Accessories / Cable"],
  ["home", "Home"],
  ["gaming", "Gaming"],
  ["shopping_bag", "Shopping bag"],
  ["phone", "Phone"],
  ["laptop", "Laptop"],
  ["headphones", "Headphones"],
  ["watch", "Watch"],
  ["chair", "Furniture"],
  ["kitchen", "Kitchen"],
  ["book", "Books"],
  ["sports", "Sports"],
  ["spa", "Beauty"],
  ["pets", "Pets"],
  ["gift", "Gift"],
  ["camera", "Camera"],
  ["car", "Car"],
  ["restaurant", "Food"],
] as const;

export function AdminCategoriesPage() {
  const [categories, setCategories] = useState<AdminCategory[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [editingCategory, setEditingCategory] = useState<AdminCategory | null>(null);
  const [formOpen, setFormOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [busyCategoryId, setBusyCategoryId] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let isCancelled = false;

    async function loadCategories(): Promise<void> {
      setIsLoading(true);
      setErrorMessage(null);

      try {
        const result = await getAdminCategories();
        if (!isCancelled) {
          setCategories(result);
        }
      } catch (error) {
        if (!isCancelled) {
          setErrorMessage(readErrorMessage(error, "Failed to load categories."));
        }
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
    setReloadKey((value) => value + 1);
  }

  function openCreateForm(): void {
    setEditingCategory(null);
    setFormOpen(true);
    setErrorMessage(null);
  }

  function openEditForm(category: AdminCategory): void {
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

  async function saveCategory(input: CreateCategoryInput): Promise<void> {
    if (isSaving) {
      return;
    }

    setIsSaving(true);
    setErrorMessage(null);

    try {
      if (editingCategory) {
        const updatedCategory = await updateAdminCategory(
          editingCategory.id,
          input,
        );

        setCategories((current) =>
          current
            .map((category) =>
              category.id === updatedCategory.id ? updatedCategory : category,
            )
            .sort(compareCategories),
        );
      } else {
        const createdCategory = await createAdminCategory(input);
        setCategories((current) =>
          [...current, createdCategory].sort(compareCategories),
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

  async function toggleCategoryStatus(category: AdminCategory): Promise<void> {
    if (busyCategoryId !== null) {
      return;
    }

    if (
      category.isActive &&
      !window.confirm(`Deactivate the “${category.name}” category?`)
    ) {
      return;
    }

    setBusyCategoryId(category.id);
    setErrorMessage(null);

    try {
      if (category.isActive) {
        await deactivateAdminCategory(category.id);
        setCategories((current) =>
          current.map((item) =>
            item.id === category.id ? { ...item, isActive: false } : item,
          ),
        );
      } else {
        const updatedCategory = await activateAdminCategory(category.id);
        setCategories((current) =>
          current.map((item) =>
            item.id === updatedCategory.id ? updatedCategory : item,
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

  const activeCount = categories.filter((category) => category.isActive).length;

  return (
    <>
      <header className="page-header page-header-row">
        <div>
          <p className="page-eyebrow">CATEGORIES</p>
          <h1>Category management</h1>
          <p className="page-description">
            Manage category icons, colors, display order, and availability.
          </p>
        </div>

        <button className="primary-button" type="button" onClick={openCreateForm}>
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
          <strong>{categories.length - activeCount}</strong>
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
            {isLoading ? "Refreshing..." : "Refresh"}
          </button>
        </div>

        {errorMessage && (
          <div className="products-error" role="alert">
            <span>{errorMessage}</span>
            <button type="button" onClick={() => setErrorMessage(null)}>
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
                  <th>Icon</th>
                  <th>Category name</th>
                  <th>Sort order</th>
                  <th>Products</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {categories.map((category) => {
                  const isBusy = busyCategoryId === category.id;
                  return (
                    <tr key={category.id}>
                      <td>
                        <CategoryIconPreview category={category} />
                      </td>
                      <td>
                        <strong>{category.name}</strong>
                        <div style={{ marginTop: 4, fontSize: 12, opacity: 0.62 }}>
                          {category.iconName}
                        </div>
                      </td>
                      <td>{category.sortOrder}</td>
                      <td>{category.productCount}</td>
                      <td>
                        <span
                          className={
                            category.isActive
                              ? "status-badge active"
                              : "status-badge inactive"
                          }
                        >
                          {category.isActive ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td>
                        <div className="product-actions">
                          <button
                            className="table-action-button"
                            type="button"
                            disabled={isBusy}
                            onClick={() => openEditForm(category)}
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
                            onClick={() => void toggleCategoryStatus(category)}
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
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {formOpen && (
        <CategoryFormDialog
          key={editingCategory ? editingCategory.id : "create"}
          category={editingCategory}
          isSubmitting={isSaving}
          onClose={closeForm}
          onSubmit={saveCategory}
        />
      )}
    </>
  );
}

function CategoryIconPreview({ category }: { category: Pick<AdminCategory, "iconName" | "iconColorStart" | "iconColorEnd"> }) {
  return (
    <div
      title={category.iconName}
      style={{
        width: 46,
        height: 46,
        borderRadius: 14,
        display: "grid",
        placeItems: "center",
        background: `linear-gradient(135deg, ${category.iconColorStart}22, ${category.iconColorEnd}35)`,
        border: `1px solid ${category.iconColorStart}33`,
      }}
    >
      <span
        style={{
          fontSize: 23,
          fontWeight: 900,
          lineHeight: 1,
          background: `linear-gradient(135deg, ${category.iconColorStart}, ${category.iconColorEnd})`,
          WebkitBackgroundClip: "text",
          color: "transparent",
        }}
      >
        ◆
      </span>
    </div>
  );
}

interface CategoryFormDialogProps {
  category: AdminCategory | null;
  isSubmitting: boolean;
  onClose(): void;
  onSubmit(input: CreateCategoryInput): Promise<void>;
}

function CategoryFormDialog({
  category,
  isSubmitting,
  onClose,
  onSubmit,
}: CategoryFormDialogProps) {
  const [name, setName] = useState(category?.name ?? "");
  const [sortOrder, setSortOrder] = useState(
    category ? category.sortOrder.toString() : "0",
  );
  const [iconName, setIconName] = useState(category?.iconName ?? "category");
  const [iconColorStart, setIconColorStart] = useState(
    category?.iconColorStart ?? "#7C3AED",
  );
  const [iconColorEnd, setIconColorEnd] = useState(
    category?.iconColorEnd ?? "#06B6D4",
  );
  const [validationMessage, setValidationMessage] = useState<string | null>(null);

  async function handleSubmit(event: FormEvent<HTMLFormElement>): Promise<void> {
    event.preventDefault();

    const normalizedName = name.trim();
    const parsedSortOrder = Number(sortOrder);

    if (normalizedName.length === 0) {
      setValidationMessage("Enter a category name.");
      return;
    }

    if (!Number.isInteger(parsedSortOrder) || parsedSortOrder < 0) {
      setValidationMessage("Sort order must be a non-negative integer.");
      return;
    }

    setValidationMessage(null);
    await onSubmit({
      name: normalizedName,
      sortOrder: parsedSortOrder,
      iconName,
      iconColorStart,
      iconColorEnd,
    });
  }

  const previewCategory = {
    iconName,
    iconColorStart,
    iconColorEnd,
  };

  return (
    <div
      className="dialog-backdrop"
      role="presentation"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !isSubmitting) {
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
              {category ? "EDIT CATEGORY" : "CREATE CATEGORY"}
            </p>
            <h2 id="category-dialog-title">
              {category ? "Edit category" : "Add category"}
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

        <form className="product-form" onSubmit={handleSubmit}>
          <div style={{ display: "flex", gap: 14, alignItems: "center" }}>
            <CategoryIconPreview category={previewCategory} />
            <div>
              <strong>Icon preview</strong>
              <div style={{ marginTop: 3, fontSize: 12, opacity: 0.66 }}>
                The Flutter app renders the selected Material icon with this two-color gradient.
              </div>
            </div>
          </div>

          <label className="form-field">
            <span>Category name</span>
            <input
              value={name}
              disabled={isSubmitting}
              placeholder="e.g. Electronics"
              onChange={(event) => setName(event.target.value)}
            />
          </label>

          <label className="form-field">
            <span>Icon</span>
            <select
              value={iconName}
              disabled={isSubmitting}
              onChange={(event) => setIconName(event.target.value)}
            >
              {ICON_OPTIONS.map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </label>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            <label className="form-field">
              <span>Gradient color 1</span>
              <input
                type="color"
                value={iconColorStart}
                disabled={isSubmitting}
                onChange={(event) => setIconColorStart(event.target.value.toUpperCase())}
              />
            </label>
            <label className="form-field">
              <span>Gradient color 2</span>
              <input
                type="color"
                value={iconColorEnd}
                disabled={isSubmitting}
                onChange={(event) => setIconColorEnd(event.target.value.toUpperCase())}
              />
            </label>
          </div>

          <label className="form-field">
            <span>Display order</span>
            <input
              type="number"
              min="0"
              step="1"
              value={sortOrder}
              disabled={isSubmitting}
              onChange={(event) => setSortOrder(event.target.value)}
            />
          </label>

          {validationMessage && (
            <div className="login-error" role="alert">
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

function compareCategories(first: AdminCategory, second: AdminCategory): number {
  if (first.sortOrder !== second.sortOrder) {
    return first.sortOrder - second.sortOrder;
  }
  return first.createdAt.localeCompare(second.createdAt);
}

function readErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError<ErrorResponse>(error)) {
    return error.response?.data?.message ?? fallback;
  }
  return fallback;
}
