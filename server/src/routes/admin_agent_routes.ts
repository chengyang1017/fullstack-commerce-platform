import {
  Router,
  type Request,
  type Response,
} from "express";

import {
  AppError,
} from "../lib/app_error.ts";

import {
  runAdminAgent,
} from "../services/admin_agent_service.ts";

export const adminAgentRouter = Router();

adminAgentRouter.post(
  "/",
  async (
    request: Request,
    response: Response,
  ) => {
    const body = request.body as Record<string, unknown>;
    const message =
      typeof body.message === "string"
        ? body.message.trim()
        : "";

    if (message.length === 0) {
      throw new AppError(
        400,
        "请输入要让 Agent 检查的内容",
        "ADMIN_AGENT_MESSAGE_REQUIRED",
      );
    }

    if (message.length > 500) {
      throw new AppError(
        400,
        "Agent 指令不能超过 500 个字符",
        "ADMIN_AGENT_MESSAGE_TOO_LONG",
      );
    }

    const result = await runAdminAgent(message);

    response.json({
      success: true,
      ...result,
    });
  },
);
