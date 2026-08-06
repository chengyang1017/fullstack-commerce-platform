import "dotenv/config";

import * as argon2 from "argon2";

import { prisma } from "./lib/prisma.ts";

async function main(): Promise<void> {
  const email =
      process.env.ADMIN_EMAIL
          ?.trim()
          .toLowerCase() ?? "";

  const password =
      process.env.ADMIN_PASSWORD ?? "";

  const name =
      process.env.ADMIN_NAME?.trim() ??
      "系统管理员";

  if (email.length === 0) {
    throw new Error("缺少 ADMIN_EMAIL");
  }

  if (!email.includes("@")) {
    throw new Error("ADMIN_EMAIL 格式不正确");
  }

  if (password.length < 12) {
    throw new Error(
      "ADMIN_PASSWORD 至少需要 12 个字符",
    );
  }

  const passwordHash = await argon2.hash(
    password,
    {
      type: argon2.argon2id,
      memoryCost: 19456,
      timeCost: 2,
      parallelism: 1,
    },
  );

  const admin = await prisma.user.upsert({
    where: {
      email,
    },
    update: {
      name,
      passwordHash,
      role: "ADMIN",
      status: "ACTIVE",
    },
    create: {
      email,
      name,
      passwordHash,
      role: "ADMIN",
      status: "ACTIVE",
    },
    select: {
      id: true,
      email: true,
      name: true,
      role: true,
      status: true,
    },
  });

  console.log("管理员账号创建成功：");
  console.log(admin);
}

main()
  .catch((error: unknown) => {
    console.error("创建管理员失败：", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });