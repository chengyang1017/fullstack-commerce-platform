const {
  defineSecret,
} = require("firebase-functions/params");

const STRIPE_SECRET_KEY =
  defineSecret("STRIPE_SECRET_KEY");

const STRIPE_WEBHOOK_SECRET =
  defineSecret("STRIPE_WEBHOOK_SECRET");

const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

const Stripe = require("stripe");

initializeApp();

const db = getFirestore();

const REGION = "asia-southeast1";

/**
 * 建立 Stripe PaymentIntent。
 *
 * Flutter 只能傳 orderId。
 * 金額一定從 Firestore 訂單讀取。
 */
exports.createStripePayment = onCall(
    {
      region: REGION,
      secrets: [STRIPE_SECRET_KEY],
      enforceAppCheck: false,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "請先登入",
        );
      }

      const orderId = request.data?.orderId;

      if (
        typeof orderId !== "string" ||
      orderId.trim().length === 0
      ) {
        throw new HttpsError(
            "invalid-argument",
            "缺少 orderId",
        );
      }

      const orderRef = db
          .collection("orders")
          .doc(orderId);

      const orderSnapshot =
      await orderRef.get();

      if (!orderSnapshot.exists) {
        throw new HttpsError(
            "not-found",
            "找不到訂單",
        );
      }

      const order = orderSnapshot.data();
      const userId = request.auth.uid;

      if (order.userId !== userId) {
        throw new HttpsError(
            "permission-denied",
            "無權支付這筆訂單",
        );
      }

      if (order.status !== "pendingPayment") {
        throw new HttpsError(
            "failed-precondition",
            "這筆訂單目前不能付款",
        );
      }

      if (
        !Number.isInteger(order.totalMinor) ||
      order.totalMinor <= 0
      ) {
        throw new HttpsError(
            "failed-precondition",
            "訂單金額無效",
        );
      }

      const stripe = new Stripe(
          STRIPE_SECRET_KEY.value(),
      );

      /*
     * 如果已經建立過 PaymentIntent，
     * 優先重用，避免重複付款。
     */
      if (order.paymentIntentId) {
        const existingIntent =
        await stripe.paymentIntents.retrieve(
            order.paymentIntentId,
        );

        const reusableStatuses = new Set([
          "requires_payment_method",
          "requires_confirmation",
          "requires_action",
          "processing",
        ]);

        if (
          reusableStatuses.has(
              existingIntent.status,
          )
        ) {
          return {
            orderId,
            paymentIntentId:
            existingIntent.id,
            clientSecret:
            existingIntent.client_secret,
            amountMinor:
            existingIntent.amount,
            currency:
            existingIntent.currency,
          };
        }

        if (
          existingIntent.status ===
        "succeeded"
        ) {
          return {
            orderId,
            paymentIntentId:
            existingIntent.id,
            alreadyPaid: true,
          };
        }
      }

      const intent =
      await stripe.paymentIntents.create(
          {
            amount: order.totalMinor,
            currency: order.currency || "myr",

            /*
           * Dashboard 啟用了哪些支付方式，
           * Stripe 就根據條件顯示哪些。
           */
            automatic_payment_methods: {
              enabled: true,
            },

            metadata: {
              orderId,
              userId,
            },

            description:
            `Order ${orderId}`,
          },
          {
          /*
           * 相同訂單重試時不重複建立付款。
           */
            idempotencyKey:
            `order_${orderId}_payment_v1`,
          },
      );

      await orderRef.update({
        paymentIntentId: intent.id,
        paymentStatus: intent.status,
        paymentUpdatedAt:
        FieldValue.serverTimestamp(),
      });

      return {
        orderId,
        paymentIntentId: intent.id,
        clientSecret: intent.client_secret,
        amountMinor: intent.amount,
        currency: intent.currency,
      };
    },
);

/**
 * Stripe webhook。
 *
 * 只有這裡可以正式將訂單改成 paid。
 */
exports.stripeWebhook = onRequest(
    {
      region: REGION,
      secrets: [
        STRIPE_SECRET_KEY,
        STRIPE_WEBHOOK_SECRET,
      ],
    },
    async (request, response) => {
      const stripe = new Stripe(
          STRIPE_SECRET_KEY.value(),
      );

      const signature =
      request.headers["stripe-signature"];

      let event;

      try {
        event =
        stripe.webhooks.constructEvent(
            request.rawBody,
            signature,
            STRIPE_WEBHOOK_SECRET.value(),
        );
      } catch (error) {
        console.error(
            "Stripe signature error:",
            error,
        );

        response.status(400).send(
            "Invalid webhook signature",
        );

        return;
      }

      const intent = event.data.object;
      const orderId =
      intent.metadata?.orderId;

      if (!orderId) {
        response.status(200).send(
            "Ignored: no orderId",
        );

        return;
      }

      const eventRef = db
          .collection("stripeEvents")
          .doc(event.id);

      const orderRef = db
          .collection("orders")
          .doc(orderId);

      try {
        await db.runTransaction(
            async (transaction) => {
              const eventSnapshot =
            await transaction.get(
                eventRef,
            );

              /*
           * Stripe 可能重送 webhook。
           * 已處理過就直接返回。
           */
              if (eventSnapshot.exists) {
                return;
              }

              const orderSnapshot =
            await transaction.get(
                orderRef,
            );

              if (!orderSnapshot.exists) {
                throw new Error(
                    `Order ${orderId} not found`,
                );
              }

              const order =
            orderSnapshot.data();

              const updateData = {
                paymentIntentId: intent.id,
                paymentStatus: intent.status,
                paymentUpdatedAt:
              FieldValue.serverTimestamp(),
              };

              switch (event.type) {
                case "payment_intent.succeeded": {
                  if (
                    intent.amount_received !==
                order.totalMinor
                  ) {
                    throw new Error(
                        "Payment amount mismatch",
                    );
                  }

                  if (
                    intent.currency !==
                (order.currency || "myr")
                  ) {
                    throw new Error(
                        "Payment currency mismatch",
                    );
                  }

                  updateData.status = "paid";
                  updateData.paymentStatus =
                "paid";
                  updateData.paidAt =
                FieldValue.serverTimestamp();

                  break;
                }

                case "payment_intent.processing":
                  updateData.paymentStatus =
                "processing";
                  break;

                case "payment_intent.payment_failed":
                  updateData.paymentStatus =
                "failed";
                  updateData.paymentError =
                intent.last_payment_error
                    ?.message || null;
                  break;

                case "payment_intent.canceled":
                  updateData.paymentStatus =
                "cancelled";
                  break;

                default:
                  break;
              }

              transaction.update(
                  orderRef,
                  updateData,
              );

              transaction.set(eventRef, {
                eventId: event.id,
                type: event.type,
                orderId,
                createdAt:
              FieldValue.serverTimestamp(),
              });
            },
        );

        response.status(200).send(
            "Webhook processed",
        );
      } catch (error) {
        console.error(
            "Webhook processing error:",
            error,
        );

        response.status(500).send(
            "Webhook processing failed",
        );
      }
    },
);
