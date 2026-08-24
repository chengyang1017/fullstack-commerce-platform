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
            "加载分类失败",
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
            ? "修改分类失败"
            : "新增分类失败",
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
        `确定下架“${category.name}”分类吗？`,
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
            ? "下架分类失败"
            : "上架分类失败",
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

          <h1>分类管理</h1>

          <p className="page-description">
            管理商品分类、排序和上下架状态
          </p>
        </div>

        <button
          className="primary-button"
          type="button"
          onClick={openCreateForm}
        >
          新增分类
        </button>
      </header>

      <section className="product-summary-grid">
        <article className="summary-card">
          <span>全部分类</span>
          <strong>{categories.length}</strong>
        </article>

        <article className="summary-card">
          <span>已上架</span>
          <strong>{activeCount}</strong>
        </article>

        <article className="summary-card">
          <span>已下架</span>
          <strong>
            {categories.length - activeCount}
          </strong>
        </article>
      </section>

      <section className="content-card products-card">
        <div className="products-toolbar">
          <strong>分类列表</strong>

          <button
            className="secondary-button"
            type="button"
            disabled={isLoading}
            onClick={refreshCategories}
          >
            {isLoading
              ? "正在刷新..."
              : "刷新"}
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
              关闭
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>正在加载分类...</p>
          </div>
        ) : categories.length === 0 ? (
          <div className="products-state">
            <strong>目前没有分类</strong>
            <p>点击“新增分类”建立第一个分类。</p>
          </div>
        ) : (
          <div className="product-table-wrapper">
            <table className="product-table">
              <thead>
                <tr>
                  <th>分类名称</th>
                  <th>分类 ID</th>
                  <th>排序</th>
                  <th>商品数量</th>
                  <th>状态</th>
                  <th>操作</th>
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
                              ? "已上架"
                              : "已下架"}
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
                              编辑
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
                                ? "处理中..."
                                : category.isActive
                                  ? "下架"
                                  : "上架"}
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
        "请输入分类名称",
      );
      return;
    }

    if (
      !Number.isInteger(parsedSortOrder) ||
      parsedSortOrder < 0
    ) {
      setValidationMessage(
        "排序必须是非负整数",
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
                ? "编辑分类"
                : "新增分类"}
            </h2>
          </div>

          <button
            className="dialog-close-button"
            type="button"
            disabled={isSubmitting}
            onClick={onClose}
          >
            ×
          </button>
        </header>

        <form
          className="product-form"
          onSubmit={handleSubmit}
        >
          <label className="form-field">
            <span>分类名称</span>

            <input
              value={name}
              disabled={isSubmitting}
              placeholder="例如：手机"
              onChange={(event) => {
                setName(event.target.value);
              }}
            />
          </label>

          <label className="form-field">
            <span>显示顺序</span>

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
              取消
            </button>

            <button
              className="primary-button"
              type="submit"
              disabled={isSubmitting}
            >
              {isSubmitting
                ? "正在保存..."
                : category
                  ? "保存修改"
                  : "创建分类"}
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
    return (
      error.response?.data.message ??
      fallback
    );
  }

  return fallback;
}