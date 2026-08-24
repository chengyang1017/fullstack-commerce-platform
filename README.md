# Commerce Platform

A full-stack e-commerce platform consisting of a Flutter customer application, a React administration dashboard, and a Node.js backend API.

The project is organized as a monorepo so that the customer application, administration tools, and backend can evolve together while remaining clearly separated.

---

## Applications

### Flutter Customer App

Located in:

```text
apps/mobile
```

The customer-facing application provides the shopping experience.

Main features include:

- Customer authentication
- Product browsing
- Product categories
- Product details
- Shopping cart
- Checkout
- Address management
- Order management
- Stripe payment integration
- Light and dark themes
- English and Chinese localization

The application uses Flutter with BLoC / Cubit for state management.

---

### React Admin Dashboard

Located in:

```text
apps/admin
```

The administration dashboard provides tools for managing the commerce system.

Main features include:

- Admin authentication
- Protected routes
- Product management
- Category management
- Order management
- Inventory management
- Inventory movement history
- Automatic access-token refresh

The dashboard is built with React, TypeScript, Vite, React Router, and Axios.

---

### Node.js Backend

Located in:

```text
server
```

The backend provides the REST API shared by both the Flutter application and React administration dashboard.

Main responsibilities include:

- Authentication
- Product management
- Category management
- Customer orders
- Admin orders
- Inventory management
- Payment integration
- Database access
- Business logic

The backend uses:

- Node.js
- TypeScript
- Express
- Prisma ORM
- PostgreSQL
- Stripe

---

## Architecture

```text
┌─────────────────────────┐
│ Flutter Customer App    │
│ apps/mobile             │
└────────────┬────────────┘
             │
             │ REST API
             │
             ▼
┌─────────────────────────┐
│ Node.js / Express API   │
│ server                  │
└────────────┬────────────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
┌───────────┐   ┌───────────┐
│  Prisma   │   │  Stripe   │
└─────┬─────┘   └───────────┘
      │
      ▼
┌───────────────┐
│  PostgreSQL   │
└───────────────┘
      ▲
      │
      │ REST API
      │
┌─────┴───────────────────┐
│ React Admin Dashboard   │
│ apps/admin              │
└─────────────────────────┘
```

Both frontend applications communicate with the same backend and business data.

---

## Monorepo Structure

```text
.
├── apps/
│   ├── mobile/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── lib/
│   │   ├── linux/
│   │   ├── macos/
│   │   ├── test/
│   │   ├── web/
│   │   ├── windows/
│   │   ├── analysis_options.yaml
│   │   ├── l10n.yaml
│   │   ├── pubspec.lock
│   │   └── pubspec.yaml
│   │
│   └── admin/
│       ├── public/
│       ├── src/
│       ├── .env.example
│       ├── package.json
│       ├── package-lock.json
│       ├── tsconfig.json
│       └── vite.config.ts
│
├── server/
│   ├── prisma/
│   ├── src/
│   ├── package.json
│   └── ...
│
├── .firebaserc
├── firebase.json
├── .gitignore
└── README.md
```

---

## Technology Stack

### Mobile

- Flutter
- Dart
- flutter_bloc
- Firebase
- Stripe
- SharedPreferences
- Flutter Secure Storage

### Admin

- React
- TypeScript
- Vite
- React Router
- Axios
- CSS

### Backend

- Node.js
- TypeScript
- Express
- Prisma ORM
- PostgreSQL
- Stripe

### Supporting Services

- Firebase
- REST APIs

---

## State Management

The Flutter application uses BLoC / Cubit for application state.

Major state modules include:

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

Business logic is separated from presentation code through repositories, services, and Cubits.

Example:

```text
UI
 ↓
Cubit
 ↓
Repository
 ↓
Service
 ↓
REST API
 ↓
Node.js
 ↓
Prisma
 ↓
PostgreSQL
```

---

## Authentication

### Customer Authentication

The Flutter application communicates with the backend authentication system and maintains customer session state through `CustomerAuthCubit`.

### Administrator Authentication

The React administration dashboard uses a separate protected administrator authentication flow.

The admin client:

- Stores access tokens in memory
- Sends Bearer tokens with authenticated requests
- Uses refresh sessions when access tokens expire
- Automatically retries requests after successful token refresh
- Clears authentication state when the session expires

---

## Product Flow

Customer product data follows this flow:

```text
Flutter UI
    ↓
ProductCubit
    ↓
ProductRepository
    ↓
ProductService
    ↓
GET /api/products
    ↓
Express
    ↓
Prisma
    ↓
PostgreSQL
```

Administration operations use protected endpoints such as:

```text
GET    /api/admin/products
POST   /api/admin/products
PATCH  /api/admin/products/:id
DELETE /api/admin/products/:id
```

---

## Orders

The commerce platform supports customer order creation and administration-side order inspection.

The Flutter application handles:

- Checkout
- Order creation
- Order history
- Order details
- Order cancellation where allowed
- Payment status synchronization

The administration dashboard provides order listing, filtering, searching, and order details.

---

## Inventory

Inventory is managed through the administration dashboard and backend API.

Administration endpoints support:

- Inventory movement history
- Stock adjustments
- Product inventory tracking

Example routes:

```text
GET  /api/admin/inventory/movements
POST /api/admin/inventory/movements
```

---

## Payments

Stripe is integrated through the backend.

Payment submission on the client does not by itself determine the final payment result.

The backend remains the authoritative source for final payment status.

This prevents the client application from treating a submitted payment request as a confirmed successful payment before backend verification.

---

## Localization

The Flutter application currently supports:

- English
- Simplified Chinese

Localization files are stored under:

```text
apps/mobile/lib/l10n
```

---

## Themes

The Flutter application supports:

- Light mode
- Dark mode
- System theme

The selected theme is persisted locally.

---

# Development

## Flutter Customer App

**Working directory:**

```text
apps/mobile
```

Install dependencies:

```bash
flutter pub get
```

Analyze the project:

```bash
flutter analyze
```

Run the application:

```bash
flutter run
```

---

## React Admin Dashboard

**Working directory:**

```text
apps/admin
```

Install dependencies:

```bash
npm install
```

Create the environment file:

```bash
cp .env.example .env
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Example:

```env
VITE_API_BASE_URL=http://localhost:3000
```

Start development:

```bash
npm run dev
```

Build:

```bash
npm run build
```

Lint:

```bash
npm run lint
```

---

## Backend

**Working directory:**

```text
server
```

Install dependencies:

```bash
npm install
```

Configure the backend environment variables according to the server configuration.

Prisma is used for database access and migrations.

---

## Environment Files

Real environment files must not be committed.

The repository ignores:

```text
.env
.env.*
**/.env
**/.env.*
```

Safe example files may be committed:

```text
.env.example
```

Never commit database credentials, Stripe secret keys, private service-account credentials, or signing keys.

---

## Repository Goals

This repository demonstrates a complete commerce application rather than a standalone UI project.

It includes:

- Mobile application development
- Web administration
- REST API design
- Authentication
- State management
- Database integration
- Payment processing
- Inventory management
- Order management
- Localization
- Theme management
- Monorepo organization

The goal is to keep each application independently maintainable while sharing the same backend and business domain.

---

## Current Structure

```text
Commerce Platform
│
├── Customer Experience
│   └── Flutter App
│
├── Administration
│   └── React Admin Dashboard
│
└── Backend
    ├── Node.js / Express
    ├── Prisma
    ├── PostgreSQL
    └── Stripe
```

---

## Status

Active development.

The core customer shopping flow, administration modules, backend API, authentication, orders, inventory, and payment integration are implemented.

Ongoing work focuses on product polish, architecture refinement, and production readiness.