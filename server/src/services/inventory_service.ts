import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";

export type InventoryOperation =
  | {
      type: "STOCK_IN";
      quantity: number;
      note?: string;
    }
  | {
      type: "STOCK_OUT";
      quantity: number;
      note?: string;
    }
  | {
      type: "ADJUSTMENT";
      targetStock: number;
      note?: string;
    };

interface ChangeInventoryInput {
  productId: string;
  operation: InventoryOperation;
  createdByUserId: string;
}

export async function changeInventory(
  input: ChangeInventoryInput,
) {
  return prisma.$transaction(
    async (transaction) => {
      /*
       * 锁定商品行，避免管理员库存操作、
       * 下单锁库存和付款扣库存同时修改同一商品。
       */
      const lockedProducts =
        await transaction.$queryRaw<
          Array<{
            id: string;
            stock: number;
            reservedStock: number;
          }>
        >`
          SELECT
            "id",
            "stock",
            "reservedStock"
          FROM "Product"
          WHERE "id" = ${input.productId}
          FOR UPDATE
        `;

      const lockedProduct =
        lockedProducts[0];

      if (!lockedProduct) {
        throw new AppError(
          404,
          "商品不存在",
          "PRODUCT_NOT_FOUND",
        );
      }

      const stockBefore =
        lockedProduct.stock;

      const reservedStock =
        lockedProduct.reservedStock;

      const result =
        calculateStockChange(
          stockBefore,
          reservedStock,
          input.operation,
        );

      const normalizedNote =
        normalizeNote(
          input.operation.note,
        );

      const updatedProduct =
        await transaction.product.update({
          where: {
            id: input.productId,
          },

          data: {
            stock: result.stockAfter,
          },

          select: {
            id: true,
            categoryId: true,
            title: true,
            description: true,
            imageUrl: true,
            priceMinor: true,
            stock: true,
            reservedStock: true,
            sold: true,
            isActive: true,
            createdAt: true,
            updatedAt: true,
          },
        });

      const movement =
        await transaction
          .inventoryMovement
          .create({
            data: {
              productId:
                input.productId,

              type:
                input.operation.type,

              quantityDelta:
                result.quantityDelta,

              stockBefore,

              stockAfter:
                result.stockAfter,

              note: normalizedNote,

              createdByUserId:
                input.createdByUserId,
            },

            include: {
              createdByUser: {
                select: {
                  id: true,
                  name: true,
                  email: true,
                },
              },
            },
          });

      return {
        product: {
          id: updatedProduct.id,

          categoryId:
            updatedProduct.categoryId,

          title:
            updatedProduct.title,

          description:
            updatedProduct.description,

          image:
            updatedProduct.imageUrl,

          price:
            updatedProduct.priceMinor /
            100,

          /*
           * stock 是仓库真实总库存。
           */
          stock:
            updatedProduct.stock,

          /*
           * reservedStock 是待付款订单锁定的库存。
           */
          reservedStock:
            updatedProduct.reservedStock,

          /*
           * availableStock 才是还能继续出售的库存。
           */
          availableStock: Math.max(
            0,
            updatedProduct.stock -
              updatedProduct.reservedStock,
          ),

          sold:
            updatedProduct.sold,

          isActive:
            updatedProduct.isActive,

          createdAt:
            updatedProduct.createdAt,

          updatedAt:
            updatedProduct.updatedAt,
        },

        movement: {
          id: movement.id,

          productId:
            movement.productId,

          type: movement.type,

          quantityDelta:
            movement.quantityDelta,

          stockBefore:
            movement.stockBefore,

          stockAfter:
            movement.stockAfter,

          note: movement.note,

          createdAt:
            movement.createdAt,

          createdByUser:
            movement.createdByUser,
        },
      };
    },
  );
}

function calculateStockChange(
  stockBefore: number,
  reservedStock: number,
  operation: InventoryOperation,
): {
  quantityDelta: number;
  stockAfter: number;
} {
  if (
    reservedStock < 0 ||
    reservedStock > stockBefore
  ) {
    throw new AppError(
      409,
      "商品锁定库存资料异常",
      "RESERVED_STOCK_INCONSISTENT",
    );
  }

  const availableStock =
    stockBefore - reservedStock;

  switch (operation.type) {
    case "STOCK_IN": {
      ensurePositiveInteger(
        operation.quantity,
        "入库数量",
      );

      const stockAfter =
        stockBefore +
        operation.quantity;

      ensureSafeStock(stockAfter);

      return {
        quantityDelta:
          operation.quantity,

        stockAfter,
      };
    }

    case "STOCK_OUT": {
      ensurePositiveInteger(
        operation.quantity,
        "出库数量",
      );

      /*
       * 管理员只能移出没有被订单锁定的库存。
       */
      if (
        operation.quantity >
        availableStock
      ) {
        throw new AppError(
          409,
          `可用库存不足，当前总库存 ${stockBefore}，锁定库存 ${reservedStock}，可用库存 ${availableStock}`,
          "AVAILABLE_STOCK_INSUFFICIENT",
        );
      }

      return {
        quantityDelta:
          -operation.quantity,

        stockAfter:
          stockBefore -
          operation.quantity,
      };
    }

    case "ADJUSTMENT": {
      if (
        !Number.isInteger(
          operation.targetStock,
        ) ||
        operation.targetStock < 0
      ) {
        throw new AppError(
          400,
          "盘点后的库存必须是非负整数",
          "INVALID_TARGET_STOCK",
        );
      }

      ensureSafeStock(
        operation.targetStock,
      );

      /*
       * 盘点不能把真实库存调整到锁定库存以下，
       * 否则待付款订单锁定的商品会不存在。
       */
      if (
        operation.targetStock <
        reservedStock
      ) {
        throw new AppError(
          409,
          `盘点库存不能低于锁定库存 ${reservedStock}`,
          "TARGET_STOCK_BELOW_RESERVED",
        );
      }

      const quantityDelta =
        operation.targetStock -
        stockBefore;

      if (quantityDelta === 0) {
        throw new AppError(
          400,
          "调整后的库存与当前库存相同",
          "INVENTORY_NOT_CHANGED",
        );
      }

      return {
        quantityDelta,

        stockAfter:
          operation.targetStock,
      };
    }
  }
}

function ensurePositiveInteger(
  value: number,
  fieldName: string,
): void {
  if (
    !Number.isInteger(value) ||
    value <= 0
  ) {
    throw new AppError(
      400,
      `${fieldName}必须是正整数`,
      "INVALID_INVENTORY_QUANTITY",
    );
  }
}

function ensureSafeStock(
  value: number,
): void {
  if (
    !Number.isSafeInteger(value) ||
    value < 0
  ) {
    throw new AppError(
      400,
      "库存数量超过系统允许范围",
      "INVALID_STOCK_VALUE",
    );
  }
}

function normalizeNote(
  note: string | undefined,
): string | null {
  if (note === undefined) {
    return null;
  }

  const normalizedNote =
    note.trim();

  if (
    normalizedNote.length === 0
  ) {
    return null;
  }

  if (
    normalizedNote.length > 500
  ) {
    throw new AppError(
      400,
      "库存备注不能超过 500 个字符",
      "INVENTORY_NOTE_TOO_LONG",
    );
  }

  return normalizedNote;
}