import "dotenv/config";

import { randomUUID } from "node:crypto";

import cookieParser from "cookie-parser";
import cors from "cors";
import express, {
  type ErrorRequestHandler,
} from "express";

import { AppError } from "./lib/app_error.ts";
import { prisma } from "./lib/prisma.ts";
import { adminAuthRouter } from "./routes/admin_auth_routes.ts";

import {
  requireAdmin,
} from "./middleware/require_admin.ts";

import {
  adminAgentRouter,
} from "./routes/admin_agent_routes.ts";

import {
  adminCategoryRouter,
} from "./routes/admin_category_routes.ts";

import {
  adminInventoryRouter,
} from "./routes/admin_inventory_routes.ts";

import {
  customerAuthRouter,
} from "./routes/customer_auth_routes.ts";

import {
  requireCustomer,
} from "./middleware/require_customer.ts";

import {
  customerOrderRouter,
} from "./routes/customer_order_routes.ts";

import {
  adminOrderRouter,
} from "./routes/admin_order_routes.ts";

import {
  stripeWebhookHandler,
} from "./routes/stripe_webhook_routes.ts";

import {
  startOrderExpirationWorker,
} from "./services/order_expiration_service.ts";

import {
  customerAvatarAssetRouter,
  customerProfileRouter,
} from "./routes/customer_profile_routes.ts";

const app = express();
const adminOrigin =
    process.env.ADMIN_ORIGIN ??
    "http://localhost:5173";

app.use(
  cors({
    origin: adminOrigin,
    credentials: true,
  }),
);

/*
 * Stripe 验证 webhook 签名时必须使用原始请求体。
 * 此路由必须放在 express.json() 之前。
 */
app.post(
  "/api/stripe/webhook",
  express.raw({
    type: "application/json",
  }),
  stripeWebhookHandler,
);

app.use(express.json());
app.use(cookieParser());

app.use(
  "/uploads/avatars",
  customerAvatarAssetRouter,
);

app.use(
  "/api/auth/customer",
  customerAuthRouter,
);
app.use(
  "/api/auth/admin",
  adminAuthRouter,
);

app.get("/health", (_request, response) => {
  response.json({
    success: true,
    message: "Shopping API 正常运行",
  });
});

app.get("/api/products", async (_request, response) => {
  const products = await prisma.product.findMany({
    where: {
      isActive: true,
      category: {
        isActive: true,
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });

  response.json(
    products.map((product) => {
      return {
        id: product.id,
        categoryId: product.categoryId,
        title: product.title,
        description: product.description,
        image: product.imageUrl,
        price: product.priceMinor / 100,
        sold: product.sold,
        stock: Math.max(
          0,
          product.stock -
            product.reservedStock,
        ),
      };
    }),
  );
});

app.get("/api/categories", async (_request, response) => {
  const categories = await prisma.category.findMany({
    where: {
      isActive: true,
    },
    orderBy: [
      {
        sortOrder: "asc",
      },
      {
        createdAt: "asc",
      },
    ],
  });

  response.json(
    categories.map((category) => {
      return {
        id: category.id,
        name: category.name,
        sortOrder: category.sortOrder,
        iconName: category.iconName,
        iconColorStart: category.iconColorStart,
        iconColorEnd: category.iconColorEnd,
      };
    }),
  );
});

app.use(
  "/api/customer/orders",
  requireCustomer,
  customerOrderRouter,
);

app.use(
  "/api/customer/profile",
  requireCustomer,
  customerProfileRouter,
);

app.use(
  "/api/admin",
  requireAdmin,
);

app.use(
  "/api/admin/agent",
  adminAgentRouter,
);

app.use(
  "/api/admin/orders",
  adminOrderRouter,
);

app.use(
  "/api/admin/inventory",
  adminInventoryRouter,
);

app.use(
  "/api/admin/categories",
  adminCategoryRouter,
);

app.post("/api/admin/products", async (request, response) => {
  const body = request.body as Record<string, unknown>;

  const categoryId =
      typeof body.categoryId === "string"
          ? body.categoryId.trim()
          : "";

  const title =
      typeof body.title === "string"
          ? body.title.trim()
          : "";

  const description =
      typeof body.description === "string"
          ? body.description.trim()
          : "";

  const imageUrl =
      typeof body.imageUrl === "string"
          ? body.imageUrl.trim()
          : "";

  const price = Number(body.price);
  const stock = Number(body.stock);

  if (
    categoryId.length === 0 ||
    title.length === 0 ||
    imageUrl.length === 0
  ) {
    response.status(400).json({
      success: false,
      message: "categoryId、title 和 imageUrl 不能为空",
    });
    return;
  }

  if (!Number.isFinite(price) || price < 0) {
    response.status(400).json({
      success: false,
      message: "price 必须是有效的非负数",
    });
    return;
  }

  if (
    !Number.isInteger(stock) ||
    stock < 0
  ) {
    response.status(400).json({
      success: false,
      message: "stock 必须是非负整数",
    });
    return;
  }

  await ensureActiveCategory(categoryId);

  const product = await prisma.product.create({
    data: {
      id: randomUUID(),
      categoryId,
      title,
      description,
      imageUrl,
      priceMinor: Math.round(price * 100),
      stock,
      sold: 0,
      isActive: true,
    },
  });

  response.status(201).json({
    success: true,
    product: {
      id: product.id,
      categoryId: product.categoryId,
      title: product.title,
      description: product.description,
      image: product.imageUrl,
      price: product.priceMinor / 100,
      stock: product.stock,
      reservedStock: product.reservedStock,
      availableStock: Math.max(
        0,
        product.stock - product.reservedStock,
      ),
      sold: product.sold,
      isActive: product.isActive,
    },
  });
});

app.patch(
  "/api/admin/products/:id",
  async (request, response) => {
    const productId = request.params.id;
    const body = request.body as Record<string, unknown>;

    const existingProduct = await prisma.product.findUnique({
      where: {
        id: productId,
      },
    });

    if (!existingProduct) {
      response.status(404).json({
        success: false,
        message: "商品不存在",
      });
      return;
    }

    const data: {
      categoryId?: string;
      title?: string;
      description?: string;
      imageUrl?: string;
      priceMinor?: number;
      isActive?: boolean;
    } = {};

    if (body.categoryId !== undefined) {
      if (
        typeof body.categoryId !== "string" ||
        body.categoryId.trim().length === 0
      ) {
        throw new AppError(
          400,
          "categoryId 不能为空",
          "CATEGORY_ID_REQUIRED",
        );
      }

      const categoryId = body.categoryId.trim();
      await ensureActiveCategory(categoryId);
      data.categoryId = categoryId;
    }

    if (body.title !== undefined) {
      if (
        typeof body.title !== "string" ||
        body.title.trim().length === 0
      ) {
        response.status(400).json({
          success: false,
          message: "title 不能为空",
        });
        return;
      }

      data.title = body.title.trim();
    }

    if (body.description !== undefined) {
      if (typeof body.description !== "string") {
        response.status(400).json({
          success: false,
          message: "description 必须是字符串",
        });
        return;
      }

      data.description = body.description.trim();
    }

    if (body.imageUrl !== undefined) {
      if (
        typeof body.imageUrl !== "string" ||
        body.imageUrl.trim().length === 0
      ) {
        response.status(400).json({
          success: false,
          message: "imageUrl 不能为空",
        });
        return;
      }

      data.imageUrl = body.imageUrl.trim();
    }

    if (body.price !== undefined) {
      const price = Number(body.price);

      if (!Number.isFinite(price) || price < 0) {
        response.status(400).json({
          success: false,
          message: "price 必须是有效的非负数",
        });
        return;
      }

      data.priceMinor = Math.round(price * 100);
    }

    if (body.isActive !== undefined) {
      if (typeof body.isActive !== "boolean") {
        throw new AppError(
          400,
          "isActive 必须是布尔值",
          "INVALID_PRODUCT_STATUS",
        );
      }

      if (body.isActive) {
        const nextCategoryId =
          data.categoryId ?? existingProduct.categoryId;
        await ensureActiveCategory(nextCategoryId);
      }

      data.isActive = body.isActive;
    }

    if (Object.keys(data).length === 0) {
      response.status(400).json({
        success: false,
        message: "没有提供需要修改的字段",
      });
      return;
    }

    const product = await prisma.product.update({
      where: { id: productId },
      data,
    });

    response.json({
      success: true,
      product: {
        id: product.id,
        categoryId: product.categoryId,
        title: product.title,
        description: product.description,
        image: product.imageUrl,
        price: product.priceMinor / 100,
        stock: product.stock,
        reservedStock: product.reservedStock,
        availableStock: Math.max(
          0,
          product.stock - product.reservedStock,
        ),
        sold: product.sold,
        isActive: product.isActive,
      },
    });
  },
);

app.delete(
  "/api/admin/products/:id",
  async (request, response) => {
    const productId = request.params.id;

    const existingProduct = await prisma.product.findUnique({
      where: {
        id: productId,
      },
    });

    if (!existingProduct) {
      response.status(404).json({
        success: false,
        message: "商品不存在",
      });
      return;
    }

    if (!existingProduct.isActive) {
      response.status(400).json({
        success: false,
        message: "商品已经下架",
      });
      return;
    }

    await prisma.product.update({
      where: { id: productId },
      data: { isActive: false },
    });

    response.json({
      success: true,
      message: "商品已下架",
    });
  },
);

app.get(
  "/api/admin/products",
  async (_request, response) => {
    const products = await prisma.product.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });

    response.json(
      products.map((product) => {
        return {
          id: product.id,
          categoryId: product.categoryId,
          title: product.title,
          description: product.description,
          image: product.imageUrl,
          price: product.priceMinor / 100,
          stock: product.stock,
          reservedStock: product.reservedStock,
          availableStock: Math.max(
            0,
            product.stock - product.reservedStock,
          ),
          sold: product.sold,
          isActive: product.isActive,
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
        };
      }),
    );
  },
);

app.get("/", (_request, response) => {
  response.json({
    message: "Shopping API 正常运行",
  });
});

async function ensureActiveCategory(
  categoryId: string,
): Promise<void> {
  const category = await prisma.category.findUnique({
    where: {
      id: categoryId,
    },
    select: {
      id: true,
      isActive: true,
    },
  });

  if (!category) {
    throw new AppError(
      400,
      `分类不存在：${categoryId}`,
      "CATEGORY_NOT_FOUND",
    );
  }

  if (!category.isActive) {
    throw new AppError(
      409,
      "不能使用已下架的商品分类",
      "CATEGORY_INACTIVE",
    );
  }
}

const errorHandler: ErrorRequestHandler = (
  error,
  _request,
  response,
  _next,
) => {
  if (error instanceof AppError) {
    response
      .status(error.statusCode)
      .json({
        success: false,
        code: error.code,
        message: error.message,
      });

    return;
  }

  console.error(error);

  response.status(500).json({
    success: false,
    code: "INTERNAL_SERVER_ERROR",
    message: "服务器内部错误",
  });
};

app.use(errorHandler);

const port = Number(process.env.PORT ?? 3000);

app.listen(port, "0.0.0.0", () => {
  startOrderExpirationWorker();

  console.log(
    `Shopping API 已启动：http://localhost:${port}`,
  );

  console.log(
    "待付款订单自动取消任务已启动",
  );
});
