import {
  Router,
  type Request,
  type Response,
} from "express";

import {
  createCustomerPaymentIntent,
  syncCustomerPaymentStatus,
} from "../services/customer_payment_service.ts";

import {
  cancelCustomerOrder,
  createCustomerOrder,
  getCustomerOrders,
  type CreateOrderItemInput,
  type CustomerPaymentMethod,
  type CustomerShippingMethod,
} from "../services/customer_order_service.ts";

interface CreateCustomerOrderBody {
  items: CreateOrderItemInput[];

  shippingMethod:
    CustomerShippingMethod;

  paymentMethod:
    CustomerPaymentMethod;

  recipientName: string;
  recipientPhone: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  countryCode?: string;
  customerNote?: string;
}

export const customerOrderRouter =
  Router();

customerOrderRouter.get(
  "/",
  async (
    _request: Request,
    response: Response,
  ) => {
    const customerId =
      response.locals.customer.id;

    const orders =
      await getCustomerOrders(
        customerId,
      );

    response.json(orders);
  },
);

customerOrderRouter.post(
  "/",
  async (
    request: Request<
      Record<string, never>,
      unknown,
      CreateCustomerOrderBody
    >,
    response: Response,
  ) => {
    const customerId =
      response.locals.customer.id;

    const body = request.body;

    const order =
      await createCustomerOrder({
        userId: customerId,
        items: body.items,

        shippingMethod:
          body.shippingMethod,

        paymentMethod:
          body.paymentMethod,

        recipientName:
          body.recipientName,

        recipientPhone:
          body.recipientPhone,

        addressLine1:
          body.addressLine1,

        addressLine2:
          body.addressLine2,

        city: body.city,
        state: body.state,

        postalCode:
          body.postalCode,

        countryCode:
          body.countryCode,

        customerNote:
          body.customerNote,
      });

    response.status(201).json(order);
  },
);



customerOrderRouter.post(
  "/:id/cancel",
  async (
    request: Request<{
      id: string;
    }>,
    response: Response,
  ) => {
    const customerId =
      response.locals.customer.id;

    const order =
      await cancelCustomerOrder({
        orderId:
          request.params.id,
        userId: customerId,
      });

    response.json(order);
  },
);

customerOrderRouter.post(
  "/:id/payment-intent",
  async (
    request: Request<{
      id: string;
    }>,
    response: Response,
  ) => {
    const customerId =
      response.locals.customer.id;

    const result =
      await createCustomerPaymentIntent({
        orderId:
          request.params.id,
        userId: customerId,
      });

    response.json(result);
  },
);


customerOrderRouter.post(
  "/:id/payment-sync",
  async (
    request: Request<{
      id: string;
    }>,
    response: Response,
  ) => {
    const customerId =
      response.locals.customer.id;

    const result =
      await syncCustomerPaymentStatus({
        orderId:
          request.params.id,
        userId: customerId,
      });

    response.json(result);
  },
);
