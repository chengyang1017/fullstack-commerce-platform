# Commerce Admin Dashboard

A web-based administration dashboard for a full-stack e-commerce platform.

The dashboard is built with **React, TypeScript, and Vite** and communicates with the same **Node.js / Express REST API** used by the Flutter customer application.

It provides administrators with tools for managing products, categories, orders, and inventory through a protected admin interface.

---

## Features

### Admin Authentication

- Administrator login
- Protected admin routes
- Access token authentication
- Automatic access token refresh
- Session restoration after page reload
- Logout support
- Automatic redirect when authentication expires

### Product Management

- View products
- Create products
- Edit product information
- Activate products
- Deactivate products
- Manage product availability

### Category Management

- View product categories
- Create and manage categories
- Organize products by category

### Order Management

- View customer orders
- Filter orders
- Search orders
- View order details
- Inspect payment and order status

### Inventory Management

- View inventory records
- Adjust product stock
- Record inventory movements
- View inventory movement history

---

## Tech Stack

### Frontend

- React
- TypeScript
- Vite
- React Router
- Axios
- CSS

### Backend Integration

The dashboard communicates with a separate backend service built with:

- Node.js
- Express
- TypeScript
- Prisma ORM
- PostgreSQL
- Stripe

---

## System Architecture

```text
┌───────────────────────┐
│ Flutter Customer App  │
└───────────┬───────────┘
            │
            │ REST API
            │
            ▼
┌───────────────────────┐
│ Node.js / Express API │
└───────────┬───────────┘
            │
       ┌────┴────┐
       │         │
       ▼         ▼
┌───────────┐  ┌───────────┐
│  Prisma   │  │  Stripe   │
└─────┬─────┘  └───────────┘
      │
      ▼
┌───────────────┐
│  PostgreSQL   │
└───────────────┘
      ▲
      │
      │
┌─────┴─────────────────┐
│ React Admin Dashboard │
└───────────────────────┘
```

Both the Flutter customer application and this administration dashboard use the same backend API and database.

---

## Authentication Architecture

The admin dashboard uses an access-token and refresh-session authentication flow.

```text
Admin Login
    │
    ▼
POST /api/auth/admin/login
    │
    ▼
Access Token
    │
    ├── Stored in memory
    │
    └── Added to API requests
            │
            ▼
       Bearer Token
```

When the access token expires:

```text
API Request
    │
    ▼
401 Unauthorized
    │
    ▼
POST /api/auth/admin/refresh
    │
    ▼
New Access Token
    │
    ▼
Retry Original Request
```

The HTTP client handles this process automatically.

Access tokens are kept in memory instead of being persisted in local storage.

---

## API Integration

The dashboard communicates with the backend through a shared Axios client.

The API base URL is configured through:

```env
VITE_API_BASE_URL=http://localhost:3000
```

Examples of currently used API routes include:

```text
POST   /api/auth/admin/login
POST   /api/auth/admin/refresh
POST   /api/auth/admin/logout

GET    /api/admin/products
POST   /api/admin/products
PATCH  /api/admin/products/:id
DELETE /api/admin/products/:id

GET    /api/admin/orders
GET    /api/admin/orders/:id

GET    /api/admin/inventory/movements
POST   /api/admin/inventory/movements
```

Category management also communicates with the administration API.

---

## Project Structure

```text
src/
├── api/
│   └── http_client.ts
│
├── auth/
│   ├── access_token_store.ts
│   ├── admin_auth_api.ts
│   ├── admin_auth_context.tsx
│   └── admin_auth_provider.tsx
│
├── features/
│   ├── categories/
│   ├── inventory/
│   ├── orders/
│   └── products/
│
├── layouts/
│   └── admin_layout.tsx
│
├── pages/
│   ├── admin_categories_page.tsx
│   ├── admin_dashboard_page.tsx
│   ├── admin_inventory_page.tsx
│   ├── admin_login_page.tsx
│   ├── admin_orders_page.tsx
│   └── admin_products_page.tsx
│
├── assets/
├── App.tsx
├── App.css
├── index.css
└── main.tsx
```

---

## Routes

```text
/login
```

Administrator login page.

Protected routes:

```text
/
├── products
├── categories
├── orders
└── inventory
```

Unauthenticated users attempting to access protected routes are redirected to `/login`.

Authenticated administrators attempting to access `/login` are redirected to the dashboard.

---

## Environment Setup

Create a local `.env` file in the project root.

You can copy the provided example:

```bash
cp .env.example .env
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Example configuration:

```env
VITE_API_BASE_URL=http://localhost:3000
```

The real `.env` file is excluded from Git and should not be committed.

---

## Installation

Install dependencies:

```bash
npm install
```

---

## Development

Start the Vite development server:

```bash
npm run dev
```

The admin dashboard requires the backend API to be running as well.

For local development, the API is typically available at:

```text
http://localhost:3000
```

---

## Build

Create a production build:

```bash
npm run build
```

The production output will be generated in:

```text
dist/
```

---

## Lint

Run ESLint:

```bash
npm run lint
```

---

## Main Modules

### Products

The product module communicates with:

```text
/api/admin/products
```

It supports product retrieval, creation, updates, activation, and deactivation.

### Categories

The category module provides administration functionality for organizing the product catalog.

### Orders

The order module communicates with:

```text
/api/admin/orders
```

It supports order listing, filtering, searching, and detailed order inspection.

### Inventory

The inventory module communicates with:

```text
/api/admin/inventory/movements
```

It supports stock adjustments and inventory movement history.

---

## Related Applications

This dashboard is one part of a larger e-commerce system.

```text
Commerce Platform

├── Flutter Customer Application
├── React Admin Dashboard
└── Node.js Backend
    ├── Express REST API
    ├── Prisma ORM
    ├── PostgreSQL
    └── Stripe Integration
```

The customer application and administration dashboard share the same backend business data.

---

## Current Development Status

The main administration modules are implemented and connected to the backend API:

- Admin authentication
- Product management
- Category management
- Order management
- Inventory management

Further development will focus on improving the dashboard overview, user experience, reporting, and production deployment.

---

## Purpose

This project demonstrates the administration side of a full-stack e-commerce system, including:

- Frontend architecture
- REST API integration
- Authentication and session handling
- Product administration
- Order administration
- Inventory management
- Separation between customer-facing and administrative applications

It is designed to work together with the Flutter customer application and Node.js backend as a complete commerce platform.