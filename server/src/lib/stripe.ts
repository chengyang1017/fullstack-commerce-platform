import Stripe from "stripe";

const stripeSecretKey =
  process.env.STRIPE_SECRET_KEY;

if (
  typeof stripeSecretKey !== "string" ||
  stripeSecretKey.trim().length === 0
) {
  throw new Error(
    "缺少 STRIPE_SECRET_KEY，请在 server/.env 中配置 Stripe Secret Key",
  );
}

export const stripe = new Stripe(
  stripeSecretKey.trim(),
);

export function requireStripeWebhookSecret():
  string {
  const webhookSecret =
    process.env.STRIPE_WEBHOOK_SECRET;

  if (
    typeof webhookSecret !== "string" ||
    webhookSecret.trim().length === 0
  ) {
    throw new Error(
      "缺少 STRIPE_WEBHOOK_SECRET，请在 server/.env 中配置 Stripe Webhook Secret",
    );
  }

  return webhookSecret.trim();
}
