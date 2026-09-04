# 商城平台 / Commerce Platform

**[English](README.md) | 简体中文**

一个完整的全栈电商项目，由 **Flutter 客户端**、**React 管理后台** 和 **Node.js / Express 后端** 组成，并使用 **Prisma、PostgreSQL 和 Stripe**。

这个项目不是单纯的商城 UI Demo，而是一个完整的商业流程：用户可以浏览商品、加入购物车、结账、支付并查看订单；管理员可以通过独立后台管理商品、分类、库存和订单。

---

## 截图

> 这里先保留截图占位。之后把图片放进 `docs/screenshots/`，再把占位替换成真正图片即可。

### 商城首页

📸 **截图占位：** `docs/screenshots/home.png`

### 商品详情

📸 **截图占位：** `docs/screenshots/product-detail.png`

### 购物车与结账

📸 **截图占位：** `docs/screenshots/checkout.png`

### 订单页面

📸 **截图占位：** `docs/screenshots/orders.png`

### 管理后台

📸 **截图占位：** `docs/screenshots/admin-dashboard.png`

### 库存管理

📸 **截图占位：** `docs/screenshots/inventory.png`

### 深色模式

📸 **截图占位：** `docs/screenshots/dark-mode.png`

---

## 项目组成

### Flutter 客户端

位于 `apps/mobile`。

- 用户认证
- 商品浏览与分类
- 商品详情
- 购物车
- 结账
- 地址管理
- Stripe 支付流程
- 订单历史与订单详情
- 浅色 / 深色 / 跟随系统主题
- 英文与简体中文本地化

Flutter 客户端使用 **BLoC / Cubit** 管理状态，并把 UI、Repository 和 Service 分开。

### React 管理后台

位于 `apps/admin`。

- 管理员认证
- 受保护路由
- 商品管理
- 分类管理
- 订单管理
- 库存管理
- 库存变动记录
- Access Token 自动刷新

使用 **React、TypeScript、Vite、React Router 和 Axios**。

### Node.js 后端

位于 `server`。

- 用户与管理员认证
- 商品与分类 API
- 用户订单与管理员订单 API
- 库存业务
- Stripe 集成
- 服务器端业务逻辑
- Prisma 数据库访问

使用 **Node.js、TypeScript、Express、Prisma ORM、PostgreSQL、Argon2、JOSE 和 Stripe**。

---

## 架构

```text
Flutter 客户端
      │
      │ REST API
      ▼
Node.js / Express API
      │
   ┌──┴───┐
   │      │
   ▼      ▼
Prisma  Stripe
   │
   ▼
PostgreSQL
   ▲
   │ REST API
   │
React 管理后台
```

两个前端应用共同连接同一个后端和业务数据。

一个典型的商品数据流程：

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

价格总计等派生状态不会直接堆在 UI Widget 中，而是根据当前业务状态计算，并由状态变化触发界面重新构建。

---

## 支付

项目通过后端集成 Stripe。

客户端负责发起支付流程，但最终支付状态由后端作为权威来源确认，避免客户端一提交请求就错误地把支付视为成功。

---

## 库存

管理后台不仅维护商品数量，也包含库存变动记录，使库存修改拥有可追踪的历史。

示例接口：

```text
GET  /api/admin/inventory/movements
POST /api/admin/inventory/movements
```

---

## 认证

项目区分普通用户认证和管理员认证。

管理员后台包含受保护页面和 Access Token 刷新机制，后端负责凭证校验与授权相关业务逻辑。

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
│   ├── mobile/        # Flutter 客户端
│   └── admin/         # React 管理后台
├── server/            # Node.js / Express API
├── firebase.json
└── README.md
```

---

## 本地运行

### Flutter 客户端

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

后端需要配置 PostgreSQL、Stripe 等环境变量。真实密钥不应提交到仓库。

---

## 这个项目展示什么

这个仓库的重点是展示完整的全栈商业系统，而不是几个互不连接的页面：

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

---

## 状态

**持续开发中。**

目前已经实现核心购物流程、管理后台模块、后端 API、认证、订单、库存、本地化、主题和支付集成。后续重点是 UI 打磨、架构优化、测试、部署和生产环境准备。
