import axios from "axios";
import {
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  getAdminCategories,
} from "../features/categories/admin_category_api";
import type {
  AdminCategory,
} from "../features/categories/category";
import {
  activateAdminProduct,
  createAdminProduct,
  deactivateAdminProduct,
  getAdminProducts,
  updateAdminProduct,
} from "../features/products/admin_product_api";
import type {
  AdminProduct,
  CreateProductInput,
} from "../features/products/product";
import {
  ProductFormDialog,
} from "../features/products/product_form_dialog";

type ProductFilter =
  | "all"
  | "active"
  | "inactive";

interface ErrorResponse {
  message?: string;
}

export function AdminProductsPage() {
  const [products, setProducts] =
    useState<AdminProduct[]>([]);

  const [categories, setCategories] =
    useState<AdminCategory[]>([]);

  const [filter, setFilter] =
    useState<ProductFilter>("all");

  const [isLoading, setIsLoading] =
    useState(true);

  const [errorMessage, setErrorMessage] =
    useState<string | null>(null);

  const [busyProductIds, setBusyProductIds] =
    useState<Set<string>>(
      () => new Set(),
    );

  const [reloadKey, setReloadKey] =
    useState(0);

  const [formOpen, setFormOpen] =
    useState(false);

  const [editingProduct, setEditingProduct] =
    useState<AdminProduct | null>(null);

  const [isSaving, setIsSaving] =
    useState(false);

  const [formError, setFormError] =
    useState<string | null>(null);

  useEffect(() => {
    let isCancelled = false;

    async function loadPageData():
        Promise<void> {
      setIsLoading(true);
      setErrorMessage(null);

      try {
        const [
          productResult,
          categoryResult,
        ] = await Promise.all([
          getAdminProducts(),
          getAdminCategories(),
        ]);

        if (isCancelled) {
          return;
        }

        setProducts(productResult);
        setCategories(categoryResult);
      } catch (error) {
        if (isCancelled) {
          return;
        }

        setErrorMessage(
          readErrorMessage(
            error,
            "加载商品资料失败",
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

  const filteredProducts = useMemo(() => {
    switch (filter) {
      case "active":
        return products.filter(
          (product) => product.isActive,
        );

      case "inactive":
        return products.filter(
          (product) => !product.isActive,
        );

      case "all":
        return products;
    }
  }, [filter, products]);

  const activeCount = products.filter(
    (product) => product.isActive,
  ).length;

  const inactiveCount =
    products.length - activeCount;

  function refreshProducts(): void {
    setReloadKey(
      (currentValue) => currentValue + 1,
    );
  }

  function openCreateForm(): void {
    setEditingProduct(null);
    setFormError(null);
    setFormOpen(true);
  }

  function openEditForm(
    product: AdminProduct,
  ): void {
    setEditingProduct(product);
    setFormError(null);
    setFormOpen(true);
  }

  function closeProductForm(): void {
    if (isSaving) {
      return;
    }

    setFormOpen(false);
    setEditingProduct(null);
    setFormError(null);
  }

  async function saveProduct(
    input: CreateProductInput,
  ): Promise<void> {
    if (isSaving) {
      return;
    }

    setIsSaving(true);
    setFormError(null);

    try {
      if (editingProduct) {
        const updatedProduct =
          await updateAdminProduct(
            editingProduct.id,
            input,
          );

        setProducts(
          (currentProducts) =>
            currentProducts.map(
              (product) =>
                product.id ===
                updatedProduct.id
                  ? updatedProduct
                  : product,
            ),
        );
      } else {
        const createdProduct =
          await createAdminProduct(
            input,
          );

        setProducts(
          (currentProducts) => [
            createdProduct,
            ...currentProducts,
          ],
        );
      }

      setFormOpen(false);
      setEditingProduct(null);
      setFormError(null);
    } catch (error) {
      setFormError(
        readErrorMessage(
          error,
          editingProduct
            ? "修改商品失败"
            : "新增商品失败",
        ),
      );
    } finally {
      setIsSaving(false);
    }
  }

  async function toggleProductStatus(
    product: AdminProduct,
  ): Promise<void> {
    if (busyProductIds.has(product.id)) {
      return;
    }

    if (
      product.isActive &&
      !window.confirm(
        `确定下架“${product.title}”吗？`,
      )
    ) {
      return;
    }

    setBusyProductIds((currentIds) => {
      const nextIds = new Set(currentIds);

      nextIds.add(product.id);

      return nextIds;
    });

    setErrorMessage(null);

    try {
      if (product.isActive) {
        await deactivateAdminProduct(
          product.id,
        );

        setProducts((currentProducts) => {
          return currentProducts.map(
            (currentProduct) =>
              currentProduct.id === product.id
                ? {
                    ...currentProduct,
                    isActive: false,
                    updatedAt:
                      new Date().toISOString(),
                  }
                : currentProduct,
          );
        });
      } else {
        const updatedProduct =
          await activateAdminProduct(
            product.id,
          );

        setProducts((currentProducts) => {
          return currentProducts.map(
            (currentProduct) =>
              currentProduct.id === product.id
                ? updatedProduct
                : currentProduct,
          );
        });
      }
    } catch (error) {
      setErrorMessage(
        readErrorMessage(
          error,
          product.isActive
            ? "下架商品失败"
            : "上架商品失败",
        ),
      );
    } finally {
      setBusyProductIds((currentIds) => {
        const nextIds = new Set(currentIds);

        nextIds.delete(product.id);

        return nextIds;
      });
    }
  }

  return (
    <>
      <header className="page-header page-header-row">
        <div>
          <p className="page-eyebrow">
            PRODUCTS
          </p>

          <h1>商品管理</h1>

          <p className="page-description">
            管理商品资料、价格、库存和上下架状态
          </p>
        </div>

        <button
          className="primary-button"
          type="button"
          disabled={
            isLoading ||
            categories.length === 0
          }
          onClick={openCreateForm}
        >
          新增商品
        </button>
      </header>

      <section className="product-summary-grid">
        <article className="summary-card">
          <span>全部商品</span>
          <strong>{products.length}</strong>
        </article>

        <article className="summary-card">
          <span>已上架</span>
          <strong>{activeCount}</strong>
        </article>

        <article className="summary-card">
          <span>已下架</span>
          <strong>{inactiveCount}</strong>
        </article>
      </section>

      <section className="content-card products-card">
        <div className="products-toolbar">
          <div className="filter-group">
            <button
              type="button"
              className={
                filter === "all"
                  ? "filter-button active"
                  : "filter-button"
              }
              onClick={() => {
                setFilter("all");
              }}
            >
              全部
            </button>

            <button
              type="button"
              className={
                filter === "active"
                  ? "filter-button active"
                  : "filter-button"
              }
              onClick={() => {
                setFilter("active");
              }}
            >
              已上架
            </button>

            <button
              type="button"
              className={
                filter === "inactive"
                  ? "filter-button active"
                  : "filter-button"
              }
              onClick={() => {
                setFilter("inactive");
              }}
            >
              已下架
            </button>
          </div>

          <button
            className="secondary-button"
            type="button"
            disabled={isLoading}
            onClick={refreshProducts}
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
              onClick={refreshProducts}
            >
              重试
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="products-state">
            <div className="loading-spinner" />
            <p>正在加载商品...</p>
          </div>
        ) : filteredProducts.length === 0 ? (
          <div className="products-state">
            <strong>
              没有符合条件的商品
            </strong>

            <p>
              可以切换筛选条件或新增商品。
            </p>
          </div>
        ) : (
          <div className="product-table-wrapper">
            <table className="product-table">
              <thead>
                <tr>
                  <th>商品</th>
                  <th>分类</th>
                  <th>价格</th>
                  <th>库存</th>
                  <th>已售</th>
                  <th>状态</th>
                  <th>操作</th>
                </tr>
              </thead>

              <tbody>
                {filteredProducts.map(
                  (product) => {
                    const isBusy =
                      busyProductIds.has(
                        product.id,
                      );

                    return (
                      <tr key={product.id}>
                        <td>
                          <div className="product-identity">
                            <img
                              src={product.image}
                              alt={product.title}
                              onError={(event) => {
                                event.currentTarget.src =
                                  "https://placehold.co/120x120?text=No+Image";
                              }}
                            />

                            <div>
                              <strong>
                                {product.title}
                              </strong>

                              <span>
                                {product.description ||
                                  "暂无描述"}
                              </span>

                              <small>
                                {product.id}
                              </small>
                            </div>
                          </div>
                        </td>

                        <td>
                          {readCategoryName(
                            categories,
                            product.categoryId,
                          )}
                        </td>

                        <td>
                          RM{" "}
                          {product.price.toFixed(
                            2,
                          )}
                        </td>

                        <td>
                          <span
                            className={
                              product.stock <= 5
                                ? "stock-value warning"
                                : "stock-value"
                            }
                          >
                            {product.stock}
                          </span>
                        </td>

                        <td>
                          {product.sold}
                        </td>

                        <td>
                          <span
                            className={
                              product.isActive
                                ? "status-badge active"
                                : "status-badge inactive"
                            }
                          >
                            {product.isActive
                              ? "已上架"
                              : "已下架"}
                          </span>
                        </td>

                        <td>
                          <div className="product-actions">
                            <button
                              className="table-action-button"
                              type="button"
                              disabled={
                                isBusy ||
                                isSaving
                              }
                              onClick={() => {
                                openEditForm(
                                  product,
                                );
                              }}
                            >
                              编辑
                            </button>

                            <button
                              className={
                                product.isActive
                                  ? "table-action-button danger"
                                  : "table-action-button success"
                              }
                              type="button"
                              disabled={isBusy}
                              onClick={() => {
                                void toggleProductStatus(
                                  product,
                                );
                              }}
                            >
                              {isBusy
                                ? "处理中..."
                                : product.isActive
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

      <ProductFormDialog
        open={formOpen}
        product={editingProduct}
        categories={categories}
        isSubmitting={isSaving}
        errorMessage={formError}
        onClose={closeProductForm}
        onSubmit={saveProduct}
      />
    </>
  );
}

function readCategoryName(
  categories: AdminCategory[],
  categoryId: string,
): string {
  const category = categories.find(
    (item) => item.id === categoryId,
  );

  if (!category) {
    return categoryId;
  }

  return category.name;
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