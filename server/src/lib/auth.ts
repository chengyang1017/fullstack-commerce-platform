import "dotenv/config";

import {
  createHash,
  randomBytes,
} from "node:crypto";

import {
  jwtVerify,
  SignJWT,
} from "jose";

const accessTokenSecret =
  process.env.ACCESS_TOKEN_SECRET;

if (!accessTokenSecret) {
  throw new Error(
    "缺少 ACCESS_TOKEN_SECRET",
  );
}

const accessTokenKey =
  new TextEncoder().encode(
    accessTokenSecret,
  );

const issuer = "shopping-api";

const adminAudience =
  "shopping-admin";

const customerAudience =
  "shopping-customer";

interface AdminTokenUser {
  id: string;
  email: string;
  name: string;
  role: "ADMIN";
}

interface CustomerTokenUser {
  id: string;
  email: string;
  name: string;
  role: "CUSTOMER";
}

export interface VerifiedAdminToken {
  userId: string;
  email: string;
  name: string;
  role: "ADMIN";
}

export interface VerifiedCustomerToken {
  userId: string;
  email: string;
  name: string;
  role: "CUSTOMER";
}

export async function createAdminAccessToken(
  user: AdminTokenUser,
): Promise<string> {
  return createAccessToken(
    user,
    adminAudience,
  );
}

export async function createCustomerAccessToken(
  user: CustomerTokenUser,
): Promise<string> {
  return createAccessToken(
    user,
    customerAudience,
  );
}

export async function verifyAdminAccessToken(
  token: string,
): Promise<VerifiedAdminToken> {
  const payload =
    await verifyAccessTokenPayload(
      token,
      adminAudience,
    );

  if (payload.role !== "ADMIN") {
    throw new Error(
      "管理员访问令牌内容无效",
    );
  }

  return {
    userId: payload.userId,
    email: payload.email,
    name: payload.name,
    role: "ADMIN",
  };
}

export async function verifyCustomerAccessToken(
  token: string,
): Promise<VerifiedCustomerToken> {
  const payload =
    await verifyAccessTokenPayload(
      token,
      customerAudience,
    );

  if (payload.role !== "CUSTOMER") {
    throw new Error(
      "客户访问令牌内容无效",
    );
  }

  return {
    userId: payload.userId,
    email: payload.email,
    name: payload.name,
    role: "CUSTOMER",
  };
}

export function createRefreshToken(): {
  token: string;
  tokenHash: string;
  expiresAt: Date;
} {
  const token =
    randomBytes(48).toString(
      "base64url",
    );

  const tokenHash =
    hashRefreshToken(token);

  const expiresAt = new Date();

  expiresAt.setDate(
    expiresAt.getDate() + 30,
  );

  return {
    token,
    tokenHash,
    expiresAt,
  };
}

export function hashRefreshToken(
  token: string,
): string {
  return createHash("sha256")
    .update(token)
    .digest("hex");
}

interface AccessTokenUser {
  id: string;
  email: string;
  name: string;
  role: "ADMIN" | "CUSTOMER";
}

async function createAccessToken(
  user: AccessTokenUser,
  audience: string,
): Promise<string> {
  return new SignJWT({
    email: user.email,
    name: user.name,
    role: user.role,
  })
    .setProtectedHeader({
      alg: "HS256",
      typ: "JWT",
    })
    .setSubject(user.id)
    .setIssuer(issuer)
    .setAudience(audience)
    .setIssuedAt()
    .setExpirationTime("15m")
    .sign(accessTokenKey);
}

interface VerifiedAccessTokenPayload {
  userId: string;
  email: string;
  name: string;
  role: "ADMIN" | "CUSTOMER";
}

async function verifyAccessTokenPayload(
  token: string,
  audience: string,
): Promise<VerifiedAccessTokenPayload> {
  const { payload } = await jwtVerify(
    token,
    accessTokenKey,
    {
      algorithms: ["HS256"],
      issuer,
      audience,
    },
  );

  if (
    typeof payload.sub !== "string" ||
    typeof payload.email !== "string" ||
    typeof payload.name !== "string" ||
    (
      payload.role !== "ADMIN" &&
      payload.role !== "CUSTOMER"
    )
  ) {
    throw new Error(
      "访问令牌内容无效",
    );
  }

  return {
    userId: payload.sub,
    email: payload.email,
    name: payload.name,
    role: payload.role,
  };
}