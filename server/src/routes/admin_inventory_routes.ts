import {
  Router,
  type Request,
  type Response,
} from "express";

import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";
import {
  changeInventory,
  type InventoryOperation,
} from "../services/inventory_service.ts";

export const adminInventoryRouter =
  Router();

adminInventoryRouter.get(
  "/movements",
  async (
    request: Request,
    response: Response,
  ) => {
    const productId =
      readOptionalQueryString(
        request.query.productId,
      );

    const limit =
      readMovementLimit(
        request.query.limit,
      );

    const movements =
      await prisma
        .inventoryMovement
        .findMany({
          where: productId
            ? {
                productId,
              }
            : undefined,

          orderBy: {
            createdAt: "desc",
          },

          take: limit,

          include: {
            product: {
              select: {
                id: true,
                title: true,
                imageUrl: true,
              },
            },

            createdByUser: {
              select: {
                id: true,
                name: true,
                email: true,
              },
            },
          },
        });

    response.json(
      movements.map((movement) => {
        return {
          id: movement.id,

          productId:
            movement.productId,

          product: {
            id: movement.product.id,

            title:
              movement.product.title,

            image:
              movement.product.imageUrl,
          },

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
        };
      }),
    );
  },
);

adminInventoryRouter.post(
  "/movements",
  async (
    request: Request,
    response: Response,
  ) => {
    const body =
      request.body as Record<
        string,
        unknown
      >;

    const productId =
      readRequiredString(
        body.productId,
        "productId",
      );

    const operation =
      readInventoryOperation(body);

    const admin = response.locals.admin as
  | {
      id: string;
      email: string;
      name: string;
      role: string;
    }
  | undefined;

if (
  !admin ||
  typeof admin.id !== "string" ||
  admin.id.length === 0
) {
  throw new AppError(
    401,
    "无法识别当前管理员",
    "ADMIN_ID_MISSING",
  );
}

const result =
  await changeInventory({
    productId,
    operation,
    createdByUserId: admin.id,
  });

    response.status(201).json({
      success: true,
      ...result,
    });
  },
);

function readInventoryOperation(
  body: Record<string, unknown>,
): InventoryOperation {
  const type =
    readRequiredString(
      body.type,
      "type",
    );

  const note =
    readOptionalBodyString(
      body.note,
      "note",
    );

  switch (type) {
    case "STOCK_IN":
      return {
        type: "STOCK_IN",

        quantity:
          readInteger(
            body.quantity,
            "quantity",
          ),

        note,
      };

    case "STOCK_OUT":
      return {
        type: "STOCK_OUT",

        quantity:
          readInteger(
            body.quantity,
            "quantity",
          ),

        note,
      };

    case "ADJUSTMENT":
      return {
        type: "ADJUSTMENT",

        targetStock:
          readInteger(
            body.targetStock,
            "targetStock",
          ),

        note,
      };

    default:
      throw new AppError(
        400,
        "库存操作类型无效",
        "INVALID_INVENTORY_TYPE",
      );
  }
}

function readRequiredString(
  value: unknown,
  fieldName: string,
): string {
  if (
    typeof value !== "string" ||
    value.trim().length === 0
  ) {
    throw new AppError(
      400,
      `${fieldName} 不能为空`,
      "REQUIRED_FIELD_MISSING",
    );
  }

  return value.trim();
}

function readOptionalBodyString(
  value: unknown,
  fieldName: string,
): string | undefined {
  if (value === undefined) {
    return undefined;
  }

  if (typeof value !== "string") {
    throw new AppError(
      400,
      `${fieldName} 必须是字符串`,
      "INVALID_STRING_FIELD",
    );
  }

  return value;
}

function readInteger(
  value: unknown,
  fieldName: string,
): number {
  const parsedValue =
    typeof value === "number"
      ? value
      : Number(value);

  if (
    !Number.isInteger(parsedValue)
  ) {
    throw new AppError(
      400,
      `${fieldName} 必须是整数`,
      "INVALID_INTEGER_FIELD",
    );
  }

  return parsedValue;
}

function readOptionalQueryString(
  value: unknown,
): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const normalizedValue =
    value.trim();

  return normalizedValue.length > 0
    ? normalizedValue
    : undefined;
}

function readMovementLimit(
  value: unknown,
): number {
  if (value === undefined) {
    return 100;
  }

  const parsedValue = Number(value);

  if (
    !Number.isInteger(parsedValue) ||
    parsedValue < 1
  ) {
    throw new AppError(
      400,
      "limit 必须是正整数",
      "INVALID_MOVEMENT_LIMIT",
    );
  }

  return Math.min(
    parsedValue,
    200,
  );
}