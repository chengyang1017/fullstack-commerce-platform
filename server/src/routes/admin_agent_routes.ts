import {
  Router,
  type Request,
  type Response,
} from "express";

import {
  AppError,
} from "../lib/app_error.ts";

import {
  runOpenAIAdminAgent,
} from "../services/openai_admin_agent_service.ts";

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

    const previousResponseId =
      typeof body.previousResponseId === "string" &&
      body.previousResponseId.trim().length > 0
        ? body.previousResponseId.trim()
        : undefined;

    if (message.length === 0) {
      throw new AppError(
        400,
        "Enter a message for the operations agent.",
        "ADMIN_AGENT_MESSAGE_REQUIRED",
      );
    }

    if (message.length > 500) {
      throw new AppError(
        400,
        "Agent messages cannot exceed 500 characters.",
        "ADMIN_AGENT_MESSAGE_TOO_LONG",
      );
    }

    const adminId =
      typeof response.locals.admin?.id === "string"
        ? response.locals.admin.id
        : "";

    if (adminId.length === 0) {
      throw new AppError(
        401,
        "The current administrator could not be identified.",
        "ADMIN_ID_MISSING",
      );
    }

    const result = await runOpenAIAdminAgent({
      message,
      adminId,
      previousResponseId,
    });

    response.json({
      success: true,
      ...result,
    });
  },
);
