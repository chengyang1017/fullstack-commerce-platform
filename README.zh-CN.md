# 商城平台

**[English](README.md) | 简体中文**

一个全栈电商平台，包含 **Flutter 客户端应用**、**React 管理后台** 和 **Node.js / Express 后端**，并由 **Prisma、PostgreSQL 和 Stripe** 提供支持。

该项目以 monorepo 形式构建，用于展示完整的电商业务流程，而不是一个独立的 UI Demo：客户可以浏览商品、管理购物车、结账、支付和跟踪订单，而管理员则可以通过独立的后台管理商品、分类、库存和订单。

---

## 截图

> 这里特意保留截图占位说明。准备好后，将图片添加到 `docs/screenshots/` 下并替换相应占位内容。

### 移动商店

### 移动应用

<p align="center">
  <img src="docs/screenshots/home.jpeg" alt="首页" width="240">
  <img src="docs/screenshots/product-detail.jpeg" alt="商品详情" width="240">
  <img src="docs/screenshots/checkout.jpeg" alt="结账" width="240">
</p>

### 订单

<p align="center">
  <img src="docs/screenshots/payment.jpeg" alt="订单" width="240">
  <img src="docs/screenshots/orders.jpeg" alt="订单" width="240">
  <img src="docs/screenshots/profile.jpeg" alt="订单" width="240">
</p>

### 管理后台

<p align="center">
  <img src="docs/screenshots/admin-dashboard.png" alt="管理后台" width="800">
</p>

### 库存管理

<p align="center">
  <img src="docs/screenshots/inventory.png" alt="库存管理" width="800">
</p>

---

## 包含内容

### Flutter 客户端应用

位于 `apps/mobile`。

- 客户认证
- 商品浏览和分类
- 商品详情
- 购物车
- 结账
- 地址管理
- Stripe 支付流程
- 订单历史和订单详情
- 浅色 / 深色 / 跟随系统主题
- 英文和简体中文本地化

Flutter 应用使用 **BLoC / Cubit** 进行状态管理，并将表现层与 Repository 和 Service 分离。

### React 管理后台

位于 `apps/admin`。

- 管理员认证
- 受保护路由
- 商品管理
- 分类管理
- 订单管理
- 库存管理
- 库存变动历史
- Access Token 刷新流程

使用 **React、TypeScript、Vite、React Router 和 Axios** 构建。

### Node.js 后端

位于 `server`。

- 认证
- 商品和分类 API
- 客户和管理员订单 API
- 库存操作
- Stripe 集成
- 业务逻辑
- Prisma 数据库访问

使用 **Node.js、TypeScript、Express、Prisma ORM、PostgreSQL、Argon2、JOSE 和 Stripe** 构建。

---

## 架构

```text
Flutter 客户端应用
        │
        │ REST API
        ▼
Node.js / Express API
        │
   ┌────┴────┐
   │         │
   ▼         ▼
Prisma     Stripe
   │
   ▼
PostgreSQL
   ▲
   │ REST API
   │
React 管理后台
```

两个前端应用都与同一个后端和业务领域通信。

一个典型的客户商品流程如下：

```text
Flutter UI
   ↓
ProductCubit
   ↓
Repository
   ↓
Service
   ↓
REST API
   ↓
Express
   ↓
Prisma
   ↓
PostgreSQL
```

---

## Flutter 状态管理

主要 Cubit 包括：

```text
CustomerAuthCubit
ProductCubit
CartCubit
CheckoutCubit
OrderCubit
PaymentCubit
LocaleCubit
ThemeModeCubit
```

总价等派生状态与 UI Widget 分离，而数据变更会通知对应的状态层，并使 UI 根据当前状态重新构建。

---

## 支付

Stripe 通过后端集成。

客户端可以发起支付流程，但后端仍然是支付状态的权威来源。这样可以避免在服务器端验证完成之前，仅因为客户端提交了请求就将支付视为最终确认。

---

## 库存

管理端包含库存跟踪和变动历史，使库存变化能够被记录，而不是仅仅覆盖单一的库存数量值。

管理端示例路由包括：

```text
GET  /api/admin/inventory/movements
POST /api/admin/inventory/movements
```

---

## 认证

项目将客户认证和管理员认证的职责分离。

管理后台使用受保护路由和 Access Token 刷新流程，而后端负责凭证验证以及与授权相关的业务逻辑。

---

## 技术栈

### 移动端

- Flutter
- Dart
- flutter_bloc
- Firebase 服务
- Flutter Stripe
- SharedPreferences
- Flutter Secure Storage
- Flutter Localizations / Intl

### 管理后台

- React
- TypeScript
- Vite
- React Router
- Axios

### 后端

- Node.js
- TypeScript
- Express
- Prisma ORM
- PostgreSQL
- Stripe
- Argon2
- JOSE

---

## Monorepo 结构

```text
fullstack-commerce-platform/
├── apps/
│   ├── mobile/        # Flutter 客户端应用
│   └── admin/         # React 管理后台
├── server/            # Node.js / Express API
├── firebase.json
└── README.md
```

---

## 开始使用

### Flutter 客户端应用

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter run
```

### React 管理后台

```bash
cd apps/admin
npm install
npm run dev
```

构建：

```bash
npm run build
```

### 后端

```bash
cd server
npm install
npm run typecheck
npm run dev
```

后端需要为 PostgreSQL 和 Stripe 等服务配置环境变量。真实密钥绝不应该提交到仓库中。

---

## 为什么存在这个项目

这个仓库旨在展示跨多个层级的完整产品流程：

```text
移动端 UI
  +
状态管理
  +
REST API
  +
认证
  +
支付
  +
订单
  +
库存
  +
管理后台
  +
数据库
```

它被设计为一个实用的全栈电商项目，而不是一组彼此断开的 Demo 页面。

---

## 状态

**积极开发中。**

核心客户购物流程、管理模块、后端 API、认证、订单、库存、本地化、主题和支付集成都已经实现。目前的工作重点是 UI 打磨、架构改进、测试、部署和生产环境就绪准备。
