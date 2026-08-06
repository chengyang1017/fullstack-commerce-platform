import type {
  NextFunction,
  Request,
  Response,
} from "express";

import { AppError } from "../lib/app_error.ts";
import {
  verifyAdminAccessToken,
} from "../lib/auth.ts";
import { prisma } from "../lib/prisma.ts";

export async function requireAdmin(
  request: Request,
  response: Response,
  next: NextFunction,
): Promise<void> {
  const authorization =
      request.headers.authorization;

  if (
    !authorization ||
    !authorization.startsWith("Bearer ")
  ) {
    next(
      new AppError(
        401,
        "缺少管理员访问令牌",
        "ACCESS_TOKEN_REQUIRED",
      ),
    );
    return;
  }

  const token = authorization
    .slice("Bearer ".length)
    .trim();

  if (token.length === 0) {
    next(
      new AppError(
        401,
        "管理员访问令牌无效",
        "INVALID_ACCESS_TOKEN",
      ),
    );
    return;
  }

  try {
    const tokenUser =
        await verifyAdminAccessToken(token);

    const user = await prisma.user.findUnique({
      where: {
        id: tokenUser.userId,
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        status: true,
      },
    });

    if (
      !user ||
      user.role !== "ADMIN" ||
      user.status !== "ACTIVE"
    ) {
      next(
        new AppError(
          403,
          "没有管理员权限",
          "ADMIN_ACCESS_DENIED",
        ),
      );
      return;
    }

    response.locals.admin = {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    };

    next();
  } catch {
    next(
      new AppError(
        401,
        "管理员登录已失效，请重新登录",
        "INVALID_ACCESS_TOKEN",
      ),
    );
  }
}