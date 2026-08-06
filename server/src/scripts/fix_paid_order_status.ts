import { prisma } from "../lib/prisma.ts";

try {
  const result = await prisma.order.updateMany({
    where: {
      paymentStatus: "PAID",
      status: "PAID",
    },
    data: {
      status: "PROCESSING",
    },
  });

  console.log(
    `已把 ${result.count} 笔已付款订单改为处理中。`,
  );
} finally {
  await prisma.$disconnect();
}
