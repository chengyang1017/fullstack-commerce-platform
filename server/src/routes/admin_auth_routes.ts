import {
  Router,
  type CookieOptions,
  type Request,
  type Response,
} from "express";

import {
  loginAdmin,
  logoutAdmin,
  refreshAdminSession,
} from "../services/admin_auth_service.ts";

export const adminAuthRouter = Router();

const refreshCookieName =
    "admin_refresh_token";

const isProduction =
  process.env.NODE_ENV === "production";

const refreshCookieOptions: CookieOptions = {
  httpOnly: true,
  secure: isProduction,
  sameSite: isProduction ? "none" : "lax",
  path: "/api/auth/admin",
};

adminAuthRouter.post(
  "/login",
  async (
    request: Request,
    response: Response,
  ) => {
    const body =
        request.body as Record<
          string,
          unknown
        >;

    const email =
        typeof body.email === "string"
            ? body.email
            : "";

    const password =
        typeof body.password === "string"
            ? body.password
            : "";

    const result = await loginAdmin(
      email,
      password,
    );

    setRefreshCookie(
      response,
      result.refreshToken,
      result.refreshTokenExpiresAt,
    );

    response.json({
      success: true,
      accessToken: result.accessToken,
      expiresInSeconds: 15 * 60,
      user: result.user,
    });
  },
);

adminAuthRouter.post(
  "/refresh",
  async (
    request: Request,
    response: Response,
  ) => {
    const refreshToken =
        readRefreshCookie(request);

    const result =
        await refreshAdminSession(
      refreshToken,
    );

    setRefreshCookie(
      response,
      result.refreshToken,
      result.refreshTokenExpiresAt,
    );

    response.json({
      success: true,
      accessToken: result.accessToken,
      expiresInSeconds: 15 * 60,
      user: result.user,
    });
  },
);

adminAuthRouter.post(
  "/logout",
  async (
    request: Request,
    response: Response,
  ) => {
    const refreshToken =
        readRefreshCookie(request);

    await logoutAdmin(refreshToken);

    response.clearCookie(
      refreshCookieName,
      refreshCookieOptions,
    );

    response.json({
      success: true,
      message: "已退出管理员账号",
    });
  },
);

function readRefreshCookie(
  request: Request,
): string {
  const cookies =
      request.cookies as Record<
        string,
        unknown
      >;

  const value =
      cookies[refreshCookieName];

  return typeof value === "string"
      ? value
      : "";
}

function setRefreshCookie(
  response: Response,
  refreshToken: string,
  expiresAt: Date,
): void {
  response.cookie(
    refreshCookieName,
    refreshToken,
    {
      ...refreshCookieOptions,
      maxAge: Math.max(
        0,
        expiresAt.getTime() -
            Date.now(),
      ),
    },
  );
}
