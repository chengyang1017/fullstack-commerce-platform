import { prisma } from "./lib/prisma.ts";

async function main(): Promise<void> {
  await prisma.category.upsert({
    where: {
      id: "phone",
    },
    update: {
      name: "手機",
    },
    create: {
      id: "phone",
      name: "手機",
    },
  });

  await prisma.product.upsert({
    where: {
      id: "product_001",
    },
    update: {
      categoryId: "phone",
      title: "智能手機",
      description: "智能手機商品",
      imageUrl: "https://picsum.photos/id/160/600/600",
      priceMinor: 129900,
      stock: 50,
      sold: 328,
      isActive: true,
    },
    create: {
      id: "product_001",
      categoryId: "phone",
      title: "智能手機",
      description: "智能手機商品",
      imageUrl: "https://picsum.photos/id/160/600/600",
      priceMinor: 129900,
      stock: 50,
      sold: 328,
    },
  });

  console.log("商品数据创建完成");
}

main()
  .catch((error: unknown) => {
    console.error("创建商品失败：", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });