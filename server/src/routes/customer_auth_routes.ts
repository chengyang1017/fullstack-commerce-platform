import {
  Router,
  type Request,
  type Response,
} from "express";

import {
  loginCustomer,
  logoutCustomer,
  refreshCustomerSession,
  registerCustomer,
} from "../services/customer_auth_service.ts";

export const customerAuthRouter =
  Router();

customerAuthRouter.post(
  "/register",
  async (
    request: Request,
    response: Response,
  ) => {
    const body =
      request.body as Record<
        string,
        unknown
      >;

    const result =
      await registerCustomer({
        email:
          readBodyString(body.email),

        password:
          readBodyString(body.password),

        name:
          readBodyString(body.name),
      });

    response.status(201).json({
      success: true,
      ...result,
    });
  },
);

customerAuthRouter.post(
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

    const result =
      await loginCustomer(
        readBodyString(body.email),
        readBodyString(
          body.password,
        ),
      );

    response.json({
      success: true,
      ...result,
    });
  },
);

customerAuthRouter.post(
  "/refresh",
  async (
    request: Request,
    response: Response,
  ) => {
    const body =
      request.body as Record<
        string,
        unknown
      >;

    const result =
      await refreshCustomerSession(
        readBodyString(
          body.refreshToken,
        ),
      );

    response.json({
      success: true,
      ...result,
    });
  },
);

customerAuthRouter.post(
  "/logout",
  async (
    request: Request,
    response: Response,
  ) => {
    const body =
      request.body as Record<
        string,
        unknown
      >;

    await logoutCustomer(
      readBodyString(
        body.refreshToken,
      ),
    );

    response.json({
      success: true,
      message: "已退出登录",
    });
  },
);

function readBodyString(
  value: unknown,
): string {
  return typeof value === "string"
    ? value
    : "";
}