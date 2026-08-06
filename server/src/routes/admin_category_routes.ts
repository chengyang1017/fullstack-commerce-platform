import { randomUUID } from "node:crypto";

import {
  Router,
  type Request,
  type Response,
} from "express";

import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";

export const adminCategoryRouter =
  Router();

adminCategoryRouter.get(
  "/",
  async (
    _request: Request,
    response: Response,
  ) => {
    const categories =
      await prisma.category.findMany({
        orderBy: [
          {
            sortOrder: "asc",
          },
          {
            createdAt: "asc",
          },
        ],
        include: {
          _count: {
            select: {
              products: true,
            },
          },
        },
      });

    response.json(
      categories.map((category) => {
        return {
          id: category.id,
          name: category.name,
          isActive: category.isActive,
          sortOrder: category.sortOrder,
          productCount:
            category._count.products,
          createdAt: category.createdAt,
          updatedAt: category.updatedAt,
        };
      }),
    );
  },
);

adminCategoryRouter.post(
  "/",
  async (
    request: Request,
    response: Response,
  ) => {
    const body =
      request.body as Record<
        string,
        unknown
      >;

    const name =
      typeof body.name === "string"
        ? body.name.trim()
        : "";

    const sortOrder =
      body.sortOrder === undefined
        ? 0
        : Number(body.sortOrder);

    if (name.length === 0) {
      throw new AppError(
        400,
        "分类名称不能为空",
        "CATEGORY_NAME_REQUIRED",
      );
    }

    if (
      !Number.isInteger(sortOrder) ||
      sortOrder < 0
    ) {
      throw new AppError(
        400,
        "排序值必须是非负整数",
        "INVALID_CATEGORY_SORT_ORDER",
      );
    }

    const duplicateCategory =
      await prisma.category.findFirst({
        where: {
          name: {
            equals: name,
            mode: "insensitive",
          },
        },
        select: {
          id: true,
        },
      });

    if (duplicateCategory) {
      throw new AppError(
        409,
        "已经存在相同名称的分类",
        "CATEGORY_NAME_EXISTS",
      );
    }

    const category =
      await prisma.category.create({
        data: {
          id: randomUUID(),
          name,
          sortOrder,
          isActive: true,
        },
      });

    response.status(201).json({
      success: true,
      category: {
        id: category.id,
        name: category.name,
        isActive: category.isActive,
        sortOrder: category.sortOrder,
        productCount: 0,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      },
    });
  },
);

adminCategoryRouter.patch(
  "/:id",
  async (
    request: Request<{ id: string }>,
    response: Response,
  ) => {
    const categoryId =
      request.params.id;

    const body =
      request.body as Record<
        string,
        unknown
      >;

    const existingCategory =
      await prisma.category.findUnique({
        where: {
          id: categoryId,
        },
      });

    if (!existingCategory) {
      throw new AppError(
        404,
        "分类不存在",
        "CATEGORY_NOT_FOUND",
      );
    }

    const data: {
      name?: string;
      sortOrder?: number;
      isActive?: boolean;
    } = {};

    if (body.name !== undefined) {
      if (
        typeof body.name !== "string" ||
        body.name.trim().length === 0
      ) {
        throw new AppError(
          400,
          "分类名称不能为空",
          "CATEGORY_NAME_REQUIRED",
        );
      }

      const name = body.name.trim();

      const duplicateCategory =
        await prisma.category.findFirst({
          where: {
            id: {
              not: categoryId,
            },
            name: {
              equals: name,
              mode: "insensitive",
            },
          },
          select: {
            id: true,
          },
        });

      if (duplicateCategory) {
        throw new AppError(
          409,
          "已经存在相同名称的分类",
          "CATEGORY_NAME_EXISTS",
        );
      }

      data.name = name;
    }

    if (body.sortOrder !== undefined) {
      const sortOrder =
        Number(body.sortOrder);

      if (
        !Number.isInteger(sortOrder) ||
        sortOrder < 0
      ) {
        throw new AppError(
          400,
          "排序值必须是非负整数",
          "INVALID_CATEGORY_SORT_ORDER",
        );
      }

      data.sortOrder = sortOrder;
    }

    if (body.isActive !== undefined) {
      if (
        typeof body.isActive !==
        "boolean"
      ) {
        throw new AppError(
          400,
          "isActive 必须是布尔值",
          "INVALID_CATEGORY_STATUS",
        );
      }

      if (!body.isActive) {
        await ensureCategoryCanDeactivate(
          categoryId,
        );
      }

      data.isActive = body.isActive;
    }

    if (Object.keys(data).length === 0) {
      throw new AppError(
        400,
        "没有提供需要修改的字段",
        "NO_CATEGORY_UPDATE_FIELDS",
      );
    }

    const category =
  await prisma.category.update({
    where: {
      id: categoryId,
    },
    data,
    include: {
      _count: {
        select: {
          products: true,
        },
      },
    },
  });

    response.json({
      success: true,
      category: {
        id: category.id,
        name: category.name,
        isActive: category.isActive,
        sortOrder: category.sortOrder,
        productCount:
          category._count.products,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      },
    });
  },
);

adminCategoryRouter.delete(
  "/:id",
  async (
    request: Request<{ id: string }>,
    response: Response,
  ) => {
    const categoryId =
      request.params.id;

    const category =
      await prisma.category.findUnique({
        where: {
          id: categoryId,
        },
      });

    if (!category) {
      throw new AppError(
        404,
        "分类不存在",
        "CATEGORY_NOT_FOUND",
      );
    }

    if (!category.isActive) {
      throw new AppError(
        400,
        "分类已经下架",
        "CATEGORY_ALREADY_INACTIVE",
      );
    }

    await ensureCategoryCanDeactivate(
      categoryId,
    );

    await prisma.category.update({
      where: {
        id: categoryId,
      },
      data: {
        isActive: false,
      },
    });

    response.json({
      success: true,
      message: "分类已下架",
    });
  },
);

async function ensureCategoryCanDeactivate(
  categoryId: string,
): Promise<void> {
  const activeProductCount =
    await prisma.product.count({
      where: {
        categoryId,
        isActive: true,
      },
    });

  if (activeProductCount > 0) {
    throw new AppError(
      409,
      `该分类下还有 ${activeProductCount} 件已上架商品，请先处理这些商品`,
      "CATEGORY_HAS_ACTIVE_PRODUCTS",
    );
  }
}