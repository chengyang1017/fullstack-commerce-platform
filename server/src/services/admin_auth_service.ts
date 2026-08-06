import * as argon2 from "argon2";

import {
  createAdminAccessToken,
  createRefreshToken,
  hashRefreshToken,
} from "../lib/auth.ts";
import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";

interface AdminSessionResult {
  accessToken: string;
  refreshToken: string;
  refreshTokenExpiresAt: Date;
  user: {
    id: string;
    email: string;
    name: string;
    role: "ADMIN";
  };
}

export async function loginAdmin(
  emailInput: string,
  password: string,
): Promise<AdminSessionResult> {
  const email = emailInput
    .trim()
    .toLowerCase();

  if (
    email.length === 0 ||
    password.length === 0
  ) {
    throw new AppError(
      400,
      "邮箱和密码不能为空",
      "INVALID_INPUT",
    );
  }

  const user = await prisma.user.findUnique({
    where: {
      email,
    },
  });

  if (
    !user ||
    user.role !== "ADMIN" ||
    user.status !== "ACTIVE"
  ) {
    throw new AppError(
      401,
      "邮箱或密码错误",
      "INVALID_CREDENTIALS",
    );
  }

  const passwordMatches =
      await argon2.verify(
    user.passwordHash,
    password,
  );

  if (!passwordMatches) {
    throw new AppError(
      401,
      "邮箱或密码错误",
      "INVALID_CREDENTIALS",
    );
  }

  const accessToken =
      await createAdminAccessToken({
    id: user.id,
    email: user.email,
    name: user.name,
    role: "ADMIN",
  });

  const refresh = createRefreshToken();

  await prisma.$transaction([
    prisma.refreshToken.create({
      data: {
        tokenHash: refresh.tokenHash,
        userId: user.id,
        expiresAt: refresh.expiresAt,
      },
    }),

    prisma.user.update({
      where: {
        id: user.id,
      },
      data: {
        lastLoginAt: new Date(),
      },
    }),
  ]);

  return {
    accessToken,
    refreshToken: refresh.token,
    refreshTokenExpiresAt:
        refresh.expiresAt,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      role: "ADMIN",
    },
  };
}

export async function refreshAdminSession(
  refreshToken: string,
): Promise<AdminSessionResult> {
  if (refreshToken.length === 0) {
    throw new AppError(
      401,
      "缺少刷新令牌",
      "REFRESH_TOKEN_REQUIRED",
    );
  }

  const tokenHash =
      hashRefreshToken(refreshToken);

  const storedToken =
      await prisma.refreshToken.findUnique({
    where: {
      tokenHash,
    },
    select: {
      id: true,
      expiresAt: true,
      revokedAt: true,
      user: {
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          status: true,
        },
      },
    },
  });

  const now = new Date();

  if (
    !storedToken ||
    storedToken.revokedAt !== null ||
    storedToken.expiresAt <= now ||
    storedToken.user.role !== "ADMIN" ||
    storedToken.user.status !== "ACTIVE"
  ) {
    throw new AppError(
      401,
      "刷新令牌无效或已过期",
      "INVALID_REFRESH_TOKEN",
    );
  }

  const nextRefreshToken =
      createRefreshToken();

  const accessToken =
      await createAdminAccessToken({
    id: storedToken.user.id,
    email: storedToken.user.email,
    name: storedToken.user.name,
    role: "ADMIN",
  });

  await prisma.$transaction(
    async (transaction) => {
      const revokeResult =
          await transaction.refreshToken.updateMany({
        where: {
          id: storedToken.id,
          revokedAt: null,
        },
        data: {
          revokedAt: now,
        },
      });

      if (revokeResult.count !== 1) {
        throw new AppError(
          401,
          "刷新令牌已被使用",
          "REFRESH_TOKEN_ALREADY_USED",
        );
      }

      await transaction.refreshToken.create({
        data: {
          tokenHash:
              nextRefreshToken.tokenHash,
          userId: storedToken.user.id,
          expiresAt:
              nextRefreshToken.expiresAt,
        },
      });
    },
  );

  return {
    accessToken,
    refreshToken:
        nextRefreshToken.token,
    refreshTokenExpiresAt:
        nextRefreshToken.expiresAt,
    user: {
      id: storedToken.user.id,
      email: storedToken.user.email,
      name: storedToken.user.name,
      role: "ADMIN",
    },
  };
}

export async function logoutAdmin(
  refreshToken: string,
): Promise<void> {
  if (refreshToken.length === 0) {
    return;
  }

  const tokenHash =
      hashRefreshToken(refreshToken);

  await prisma.refreshToken.updateMany({
    where: {
      tokenHash,
      revokedAt: null,
    },
    data: {
      revokedAt: new Date(),
    },
  });
}