import * as argon2 from "argon2";

import {
  createCustomerAccessToken,
  createRefreshToken,
  hashRefreshToken,
} from "../lib/auth.ts";
import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";

interface CustomerSessionResult {
  accessToken: string;
  refreshToken: string;
  refreshTokenExpiresAt: Date;

  user: {
    id: string;
    email: string;
    name: string;
    role: "CUSTOMER";
  };
}

interface RegisterCustomerInput {
  email: string;
  password: string;
  name: string;
}

export async function registerCustomer(
  input: RegisterCustomerInput,
): Promise<CustomerSessionResult> {
  const email =
    normalizeEmail(input.email);

  const name =
    normalizeName(input.name);

  validateEmail(email);
  validatePassword(input.password);

  const existingUser =
    await prisma.user.findUnique({
      where: {
        email,
      },
      select: {
        id: true,
      },
    });

  if (existingUser) {
    throw new AppError(
      409,
      "该邮箱已经注册",
      "EMAIL_ALREADY_REGISTERED",
    );
  }

  const passwordHash =
    await argon2.hash(
      input.password,
    );

  const refresh =
    createRefreshToken();

  try {
    const user =
      await prisma.$transaction(
        async (transaction) => {
          const createdUser =
            await transaction.user.create({
              data: {
                email,
                passwordHash,
                name,
                role: "CUSTOMER",
                status: "ACTIVE",
                lastLoginAt: new Date(),
              },
              select: {
                id: true,
                email: true,
                name: true,
                role: true,
              },
            });

          await transaction
            .refreshToken
            .create({
              data: {
                tokenHash:
                  refresh.tokenHash,
                userId:
                  createdUser.id,
                expiresAt:
                  refresh.expiresAt,
              },
            });

          return createdUser;
        },
      );

    const accessToken =
      await createCustomerAccessToken({
        id: user.id,
        email: user.email,
        name: user.name,
        role: "CUSTOMER",
      });

    return {
      accessToken,
      refreshToken: refresh.token,
      refreshTokenExpiresAt:
        refresh.expiresAt,

      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: "CUSTOMER",
      },
    };
  } catch (error) {
    if (isUniqueConstraintError(error)) {
      throw new AppError(
        409,
        "该邮箱已经注册",
        "EMAIL_ALREADY_REGISTERED",
      );
    }

    throw error;
  }
}

export async function loginCustomer(
  emailInput: string,
  password: string,
): Promise<CustomerSessionResult> {
  const email =
    normalizeEmail(emailInput);

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

  const user =
    await prisma.user.findUnique({
      where: {
        email,
      },
    });

  if (
    !user ||
    user.role !== "CUSTOMER" ||
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
    await createCustomerAccessToken({
      id: user.id,
      email: user.email,
      name: user.name,
      role: "CUSTOMER",
    });

  const refresh =
    createRefreshToken();

  await prisma.$transaction([
    prisma.refreshToken.create({
      data: {
        tokenHash:
          refresh.tokenHash,
        userId: user.id,
        expiresAt:
          refresh.expiresAt,
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
      role: "CUSTOMER",
    },
  };
}

export async function refreshCustomerSession(
  refreshToken: string,
): Promise<CustomerSessionResult> {
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
    await prisma.refreshToken
      .findUnique({
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
    storedToken.user.role !==
      "CUSTOMER" ||
    storedToken.user.status !==
      "ACTIVE"
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
    await createCustomerAccessToken({
      id: storedToken.user.id,
      email:
        storedToken.user.email,
      name:
        storedToken.user.name,
      role: "CUSTOMER",
    });

  await prisma.$transaction(
    async (transaction) => {
      const revokeResult =
        await transaction
          .refreshToken
          .updateMany({
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

      await transaction
        .refreshToken
        .create({
          data: {
            tokenHash:
              nextRefreshToken.tokenHash,

            userId:
              storedToken.user.id,

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
      email:
        storedToken.user.email,
      name:
        storedToken.user.name,
      role: "CUSTOMER",
    },
  };
}

export async function logoutCustomer(
  refreshToken: string,
): Promise<void> {
  if (refreshToken.length === 0) {
    return;
  }

  const tokenHash =
    hashRefreshToken(refreshToken);

  await prisma.refreshToken
    .updateMany({
      where: {
        tokenHash,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
}

function normalizeEmail(
  email: string,
): string {
  return email
    .trim()
    .toLowerCase();
}

function normalizeName(
  name: string,
): string {
  const normalizedName =
    name.trim();

  if (
    normalizedName.length < 2 ||
    normalizedName.length > 60
  ) {
    throw new AppError(
      400,
      "用户名长度必须为 2 至 60 个字符",
      "INVALID_CUSTOMER_NAME",
    );
  }

  return normalizedName;
}

function validateEmail(
  email: string,
): void {
  const emailPattern =
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (
    email.length > 254 ||
    !emailPattern.test(email)
  ) {
    throw new AppError(
      400,
      "邮箱格式无效",
      "INVALID_EMAIL",
    );
  }
}

function validatePassword(
  password: string,
): void {
  if (
    password.length < 8 ||
    password.length > 128
  ) {
    throw new AppError(
      400,
      "密码长度必须为 8 至 128 个字符",
      "INVALID_PASSWORD_LENGTH",
    );
  }
}

function isUniqueConstraintError(
  error: unknown,
): boolean {
  if (
    typeof error !== "object" ||
    error === null ||
    !("code" in error)
  ) {
    return false;
  }

  return (
    (error as {
      code?: unknown;
    }).code === "P2002"
  );
}