import { prisma } from "../lib/prisma.ts";

export type AdminAgentIntent =
  | "overview"
  | "low_stock"
  | "pending_orders"
  | "top_products"
  | "payment_risk"
  | "help";

export interface AdminAgentCard {
  label: string;
  value: string;
  description: string;
  tone?: "default" | "success" | "warning" | "danger";
}

export interface AdminAgentItem {
  title: string;
  subtitle: string;
  meta?: string;
  href?: string;
}

export interface AdminAgentResult {
  intent: AdminAgentIntent;
  reply: string;
  cards: AdminAgentCard[];
  items: AdminAgentItem[];
  suggestions: string[];
  generatedAt: string;
}

export async function runAdminAgent(
  rawMessage: string,
): Promise<AdminAgentResult> {
  const message = rawMessage.trim();
  const intent = resolveIntent(message);

  switch (intent) {
    case "overview":
      return buildOverview();
    case "low_stock":
      return buildLowStockReport();
    case "pending_orders":
      return buildPendingOrderReport();
    case "top_products":
      return buildTopProductsReport();
    case "payment_risk":
      return buildPaymentRiskReport();
    case "help":
      return buildHelpResult();
  }
}

function resolveIntent(message: string): AdminAgentIntent {
  const normalized = message.toLowerCase();

  if (
    containsAny(normalized, [
      "revenue",
      "overview",
      "summary",
      "business overview",
      "sales overview",
      "销售额",
      "营收",
      "营业额",
      "概况",
      "总览",
      "整体",
      "经营情况",
    ])
  ) {
    return "overview";
  }

  if (
    containsAny(normalized, [
      "stock",
      "low stock",
      "inventory",
      "restock",
      "out of stock",
      "库存",
      "缺货",
      "补货",
    ])
  ) {
    return "low_stock";
  }

  if (
    containsAny(normalized, [
      "payment",
      "failed payment",
      "payment issue",
      "付款",
      "支付",
      "失败付款",
      "支付失败",
    ])
  ) {
    return "payment_risk";
  }

  if (
    containsAny(normalized, [
      "top product",
      "top-selling",
      "top selling",
      "best seller",
      "best-selling",
      "sales ranking",
      "热销",
      "销量",
      "卖得最好",
      "畅销",
    ])
  ) {
    return "top_products";
  }

  if (
    containsAny(normalized, [
      "order",
      "pending order",
      "processing",
      "ship",
      "fulfilment",
      "fulfillment",
      "订单",
      "待处理",
      "出货",
      "发货",
    ])
  ) {
    return "pending_orders";
  }

  return "help";
}

async function buildOverview(): Promise<AdminAgentResult> {
  const [
    activeProductCount,
    totalOrderCount,
    paidOrderCount,
    processingOrderCount,
    paidRevenue,
    activeProducts,
    recentOrders,
  ] = await Promise.all([
    prisma.product.count({
      where: { isActive: true },
    }),
    prisma.order.count(),
    prisma.order.count({
      where: { status: "PAID" },
    }),
    prisma.order.count({
      where: { status: "PROCESSING" },
    }),
    prisma.order.aggregate({
      where: { paymentStatus: "PAID" },
      _sum: { totalMinor: true },
    }),
    prisma.product.findMany({
      where: { isActive: true },
      select: {
        stock: true,
        reservedStock: true,
      },
    }),
    prisma.order.findMany({
      orderBy: { createdAt: "desc" },
      take: 5,
      select: {
        orderNumber: true,
        status: true,
        paymentStatus: true,
        totalMinor: true,
        createdAt: true,
        user: {
          select: { name: true },
        },
      },
    }),
  ]);

  const lowStockCount = activeProducts.filter(
    (product) =>
      Math.max(0, product.stock - product.reservedStock) <= 5,
  ).length;

  const pendingOrderCount =
    paidOrderCount + processingOrderCount;

  return {
    intent: "overview",
    reply:
      pendingOrderCount > 0 || lowStockCount > 0
        ? `There are ${pendingOrderCount} orders waiting for fulfilment and ${lowStockCount} low-stock products. Handle fulfilment first, then review restocking.`
        : "No obvious order or inventory risks right now. Keep an eye on top-selling products and payment status.",
    cards: [
      {
        label: "Active products",
        value: String(activeProductCount),
        description: "Products currently available for sale",
      },
      {
        label: "All orders",
        value: String(totalOrderCount),
        description: "Total orders in the system",
      },
      {
        label: "Pending fulfilment",
        value: String(pendingOrderCount),
        description: "PAID + PROCESSING",
        tone:
          pendingOrderCount > 0 ? "warning" : "success",
      },
      {
        label: "Low-stock products",
        value: String(lowStockCount),
        description: "Available stock ≤ 5",
        tone: lowStockCount > 0 ? "danger" : "success",
      },
      {
        label: "Paid order value",
        value: formatMoney(paidRevenue._sum.totalMinor ?? 0),
        description: "Sum where paymentStatus=PAID",
        tone: "success",
      },
    ],
    items: recentOrders.map((order) => ({
      title: order.orderNumber,
      subtitle: `${order.user.name} · ${formatMoney(order.totalMinor)}`,
      meta: `${order.status} · ${order.paymentStatus} · ${formatDate(order.createdAt)}`,
      href: "/orders",
    })),
    suggestions: defaultSuggestions(),
    generatedAt: new Date().toISOString(),
  };
}

async function buildLowStockReport(): Promise<AdminAgentResult> {
  const products = await prisma.product.findMany({
    where: { isActive: true },
    select: {
      id: true,
      title: true,
      stock: true,
      reservedStock: true,
      sold: true,
    },
  });

  const lowStockProducts = products
    .map((product) => ({
      ...product,
      availableStock: Math.max(
        0,
        product.stock - product.reservedStock,
      ),
    }))
    .filter((product) => product.availableStock <= 5)
    .sort((a, b) => a.availableStock - b.availableStock)
    .slice(0, 10);

  const outOfStockCount = lowStockProducts.filter(
    (product) => product.availableStock === 0,
  ).length;

  return {
    intent: "low_stock",
    reply:
      lowStockProducts.length === 0
        ? "No low-stock products were found. Every active product has more than 5 units available."
        : `Found ${lowStockProducts.length} low-stock products. ${outOfStockCount} are currently out of available stock.`,
    cards: [
      {
        label: "Low stock",
        value: String(lowStockProducts.length),
        description: "Available stock ≤ 5",
        tone:
          lowStockProducts.length > 0 ? "warning" : "success",
      },
      {
        label: "Out of stock",
        value: String(outOfStockCount),
        description: "Available stock = 0",
        tone: outOfStockCount > 0 ? "danger" : "success",
      },
    ],
    items: lowStockProducts.map((product) => ({
      title: product.title,
      subtitle: `Available ${product.availableStock} · Total ${product.stock} · Reserved ${product.reservedStock}`,
      meta: `${product.sold} sold to date`,
      href: "/inventory",
    })),
    suggestions: [
      "Show pending orders",
      "Show top-selling products",
      "Give me an overview",
    ],
    generatedAt: new Date().toISOString(),
  };
}

async function buildPendingOrderReport(): Promise<AdminAgentResult> {
  const [paidOrders, processingOrders] = await Promise.all([
    prisma.order.count({
      where: { status: "PAID" },
    }),
    prisma.order.count({
      where: { status: "PROCESSING" },
    }),
  ]);

  const orders = await prisma.order.findMany({
    where: {
      OR: [
        { status: "PAID" },
        { status: "PROCESSING" },
      ],
    },
    orderBy: { createdAt: "asc" },
    take: 10,
    select: {
      orderNumber: true,
      status: true,
      paymentStatus: true,
      totalMinor: true,
      createdAt: true,
      recipientName: true,
      user: {
        select: { name: true },
      },
    },
  });

  return {
    intent: "pending_orders",
    reply:
      orders.length === 0
        ? "There are no paid or processing orders waiting for fulfilment."
        : `There are ${paidOrders + processingOrders} orders waiting for fulfilment. The list is sorted by oldest order first.`,
    cards: [
      {
        label: "Paid, awaiting fulfilment",
        value: String(paidOrders),
        description: "status=PAID",
        tone: paidOrders > 0 ? "warning" : "success",
      },
      {
        label: "Processing",
        value: String(processingOrders),
        description: "status=PROCESSING",
        tone:
          processingOrders > 0 ? "warning" : "success",
      },
    ],
    items: orders.map((order) => ({
      title: order.orderNumber,
      subtitle: `${order.recipientName || order.user.name} · ${formatMoney(order.totalMinor)}`,
      meta: `${order.status} · ${order.paymentStatus} · ${formatDate(order.createdAt)}`,
      href: "/orders",
    })),
    suggestions: [
      "Check low-stock products",
      "Check payment issues",
      "Give me an overview",
    ],
    generatedAt: new Date().toISOString(),
  };
}

async function buildTopProductsReport(): Promise<AdminAgentResult> {
  const products = await prisma.product.findMany({
    where: { isActive: true },
    orderBy: [
      { sold: "desc" },
      { updatedAt: "desc" },
    ],
    take: 10,
    select: {
      title: true,
      sold: true,
      stock: true,
      reservedStock: true,
      priceMinor: true,
    },
  });

  const totalSold = products.reduce(
    (sum, product) => sum + product.sold,
    0,
  );

  return {
    intent: "top_products",
    reply:
      products.length === 0
        ? "There are no active products to rank yet."
        : `The current top-selling product is “${products[0]?.title ?? "—"}”. The top ${products.length} products have sold ${totalSold} units in total.`,
    cards: [
      {
        label: "Top product sales",
        value: String(products[0]?.sold ?? 0),
        description: products[0]?.title ?? "No product",
        tone: "success",
      },
      {
        label: "Top 10 units sold",
        value: String(totalSold),
        description: "Sorted by sold",
      },
    ],
    items: products.map((product, index) => ({
      title: `#${index + 1} ${product.title}`,
      subtitle: `${product.sold} sold · ${formatMoney(product.priceMinor)}`,
      meta: `Available stock ${Math.max(0, product.stock - product.reservedStock)}`,
      href: "/products",
    })),
    suggestions: [
      "Check low-stock products",
      "Show pending orders",
      "Give me an overview",
    ],
    generatedAt: new Date().toISOString(),
  };
}

async function buildPaymentRiskReport(): Promise<AdminAgentResult> {
  const [failed, processing, unpaidPending, recentFailed] =
    await Promise.all([
      prisma.order.count({
        where: { paymentStatus: "FAILED" },
      }),
      prisma.order.count({
        where: { paymentStatus: "PROCESSING" },
      }),
      prisma.order.count({
        where: {
          status: "PENDING_PAYMENT",
          paymentStatus: "UNPAID",
        },
      }),
      prisma.order.findMany({
        where: { paymentStatus: "FAILED" },
        orderBy: { updatedAt: "desc" },
        take: 8,
        select: {
          orderNumber: true,
          totalMinor: true,
          updatedAt: true,
          user: {
            select: { name: true },
          },
        },
      }),
    ]);

  return {
    intent: "payment_risk",
    reply:
      failed === 0 && processing === 0
        ? "No failed or processing payments were found."
        : `Found ${failed} failed payments and ${processing} payments still processing. Review failed orders first.`,
    cards: [
      {
        label: "Failed payments",
        value: String(failed),
        description: "paymentStatus=FAILED",
        tone: failed > 0 ? "danger" : "success",
      },
      {
        label: "Processing payments",
        value: String(processing),
        description: "paymentStatus=PROCESSING",
        tone: processing > 0 ? "warning" : "success",
      },
      {
        label: "Awaiting payment",
        value: String(unpaidPending),
        description: "PENDING_PAYMENT + UNPAID",
      },
    ],
    items: recentFailed.map((order) => ({
      title: order.orderNumber,
      subtitle: `${order.user.name} · ${formatMoney(order.totalMinor)}`,
      meta: `Last updated ${formatDate(order.updatedAt)}`,
      href: "/orders",
    })),
    suggestions: [
      "Show pending orders",
      "Check low-stock products",
      "Give me an overview",
    ],
    generatedAt: new Date().toISOString(),
  };
}

function buildHelpResult(): AdminAgentResult {
  return {
    intent: "help",
    reply:
      "I can read live commerce data and help with overview, low-stock checks, pending orders, payment issues, and top-selling products. This version is read-only and will not change orders or inventory.",
    cards: [],
    items: [],
    suggestions: defaultSuggestions(),
    generatedAt: new Date().toISOString(),
  };
}

function defaultSuggestions(): string[] {
  return [
    "Give me an overview",
    "Check low-stock products",
    "Show pending orders",
    "Check payment issues",
    "Show top-selling products",
  ];
}

function containsAny(
  value: string,
  keywords: string[],
): boolean {
  return keywords.some((keyword) => value.includes(keyword));
}

function formatMoney(minor: number): string {
  return `RM ${(minor / 100).toFixed(2)}`;
}

function formatDate(value: Date): string {
  return value.toLocaleString("en-MY", {
    timeZone: "Asia/Kuala_Lumpur",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}
