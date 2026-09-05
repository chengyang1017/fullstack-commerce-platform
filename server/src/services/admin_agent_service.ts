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
      "销售额",
      "营收",
      "营业额",
      "revenue",
      "overview",
      "summary",
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
      "库存",
      "缺货",
      "补货",
      "stock",
      "low stock",
      "inventory",
    ])
  ) {
    return "low_stock";
  }

  if (
    containsAny(normalized, [
      "付款",
      "支付",
      "payment",
      "失败付款",
      "支付失败",
    ])
  ) {
    return "payment_risk";
  }

  if (
    containsAny(normalized, [
      "热销",
      "销量",
      "卖得最好",
      "畅销",
      "top product",
      "best seller",
      "best-selling",
    ])
  ) {
    return "top_products";
  }

  if (
    containsAny(normalized, [
      "订单",
      "待处理",
      "出货",
      "发货",
      "order",
      "processing",
      "ship",
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
        ? `当前有 ${pendingOrderCount} 笔待处理订单，${lowStockCount} 个商品处于低库存状态。建议先处理订单，再检查补货。`
        : "当前订单和库存没有明显风险，可以继续关注热销商品和付款状态。",
    cards: [
      {
        label: "在售商品",
        value: String(activeProductCount),
        description: "当前处于上架状态的商品",
      },
      {
        label: "全部订单",
        value: String(totalOrderCount),
        description: "系统累计订单数",
      },
      {
        label: "待处理订单",
        value: String(pendingOrderCount),
        description: "PAID + PROCESSING",
        tone:
          pendingOrderCount > 0 ? "warning" : "success",
      },
      {
        label: "低库存商品",
        value: String(lowStockCount),
        description: "可用库存 ≤ 5",
        tone: lowStockCount > 0 ? "danger" : "success",
      },
      {
        label: "已付款订单金额",
        value: formatMoney(paidRevenue._sum.totalMinor ?? 0),
        description: "按 paymentStatus=PAID 汇总",
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
        ? "目前没有低库存商品，可用库存都高于 5。"
        : `发现 ${lowStockProducts.length} 个低库存商品，其中 ${outOfStockCount} 个已经没有可用库存。`,
    cards: [
      {
        label: "低库存",
        value: String(lowStockProducts.length),
        description: "可用库存 ≤ 5",
        tone:
          lowStockProducts.length > 0 ? "warning" : "success",
      },
      {
        label: "缺货",
        value: String(outOfStockCount),
        description: "可用库存 = 0",
        tone: outOfStockCount > 0 ? "danger" : "success",
      },
    ],
    items: lowStockProducts.map((product) => ({
      title: product.title,
      subtitle: `可用 ${product.availableStock} · 总库存 ${product.stock} · 预留 ${product.reservedStock}`,
      meta: `累计售出 ${product.sold}`,
      href: "/inventory",
    })),
    suggestions: [
      "查看待处理订单",
      "看看热销商品",
      "给我后台总览",
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
        ? "目前没有需要处理的已付款或处理中订单。"
        : `目前有 ${paidOrders + processingOrders} 笔待处理订单，列表按最早下单时间优先排列。`,
    cards: [
      {
        label: "已付款待处理",
        value: String(paidOrders),
        description: "status=PAID",
        tone: paidOrders > 0 ? "warning" : "success",
      },
      {
        label: "处理中",
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
      "检查库存风险",
      "检查付款异常",
      "给我后台总览",
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
        ? "目前没有上架商品数据。"
        : `当前热销榜第一是「${products[0]?.title ?? "—"}」。前 ${products.length} 个商品累计售出 ${totalSold} 件。`,
    cards: [
      {
        label: "榜首销量",
        value: String(products[0]?.sold ?? 0),
        description: products[0]?.title ?? "暂无商品",
        tone: "success",
      },
      {
        label: "前十累计销量",
        value: String(totalSold),
        description: "按 sold 字段排序",
      },
    ],
    items: products.map((product, index) => ({
      title: `#${index + 1} ${product.title}`,
      subtitle: `已售 ${product.sold} · ${formatMoney(product.priceMinor)}`,
      meta: `可用库存 ${Math.max(0, product.stock - product.reservedStock)}`,
      href: "/products",
    })),
    suggestions: [
      "检查库存风险",
      "查看待处理订单",
      "给我后台总览",
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
        ? "没有发现失败或处理中付款。"
        : `发现 ${failed} 笔失败付款、${processing} 笔处理中付款；建议优先查看失败订单。`,
    cards: [
      {
        label: "付款失败",
        value: String(failed),
        description: "paymentStatus=FAILED",
        tone: failed > 0 ? "danger" : "success",
      },
      {
        label: "付款处理中",
        value: String(processing),
        description: "paymentStatus=PROCESSING",
        tone: processing > 0 ? "warning" : "success",
      },
      {
        label: "待付款",
        value: String(unpaidPending),
        description: "PENDING_PAYMENT + UNPAID",
      },
    ],
    items: recentFailed.map((order) => ({
      title: order.orderNumber,
      subtitle: `${order.user.name} · ${formatMoney(order.totalMinor)}`,
      meta: `最近更新 ${formatDate(order.updatedAt)}`,
      href: "/orders",
    })),
    suggestions: [
      "查看待处理订单",
      "检查库存风险",
      "给我后台总览",
    ],
    generatedAt: new Date().toISOString(),
  };
}

function buildHelpResult(): AdminAgentResult {
  return {
    intent: "help",
    reply:
      "我现在可以读取商城实时数据，帮你检查后台总览、低库存、待处理订单、付款异常和热销商品。当前版本不会自动修改订单或库存，避免误操作。",
    cards: [],
    items: [],
    suggestions: defaultSuggestions(),
    generatedAt: new Date().toISOString(),
  };
}

function defaultSuggestions(): string[] {
  return [
    "给我后台总览",
    "检查库存风险",
    "查看待处理订单",
    "检查付款异常",
    "看看热销商品",
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
  return value.toLocaleString("zh-CN", {
    timeZone: "Asia/Kuala_Lumpur",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}
