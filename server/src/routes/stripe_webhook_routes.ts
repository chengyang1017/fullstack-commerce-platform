import {
  type NextFunction,
  type Request,
  type Response,
} from "express";

import {
  requireStripeWebhookSecret,
  stripe,
} from "../lib/stripe.ts";

import {
  handleStripeEvent,
} from "../services/customer_payment_service.ts";

export async function stripeWebhookHandler(
  request: Request,
  response: Response,
  next: NextFunction,
): Promise<void> {
  const signature =
    request.headers["stripe-signature"];

  if (typeof signature !== "string") {
    response.status(400).json({
      success: false,
      message:
        "缺少 Stripe-Signature 请求头",
    });
    return;
  }

  try {
    const event =
      stripe.webhooks.constructEvent(
        request.body,
        signature,
        requireStripeWebhookSecret(),
      );

    await handleStripeEvent(event);

    response.json({
      received: true,
    });
  } catch (error) {
    if (
      error instanceof Error &&
      error.name ===
        "StripeSignatureVerificationError"
    ) {
      response.status(400).json({
        success: false,
        message:
          "Stripe Webhook 签名验证失败",
      });
      return;
    }

    next(error);
  }
}
