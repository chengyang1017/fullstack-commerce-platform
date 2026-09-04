# Deployment Guide

This repository is prepared for a public portfolio/demo deployment with three deliverables:

1. **Node.js API + PostgreSQL** — Railway
2. **React admin dashboard** — Cloudflare Pages (or another static Vite host)
3. **Flutter Android app** — release APK connected to the deployed API

## 1. Deploy the API and PostgreSQL

The API lives in `server/` and now includes a production `Dockerfile`.

### Required environment variables

Use `server/.env.example` as the reference. At minimum configure:

```env
DATABASE_URL=postgresql://...
ACCESS_TOKEN_SECRET=...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
ADMIN_ORIGIN=https://YOUR_ADMIN_HOST
NODE_ENV=production
```

The container runs:

```text
npx prisma migrate deploy
node src/app.ts
```

The API exposes a health endpoint:

```text
GET /health
```

Expected response:

```json
{
  "success": true,
  "message": "Shopping API 正常运行"
}
```

### Create the demo administrator

After the database and API environment are ready, temporarily set:

```env
ADMIN_EMAIL=...
ADMIN_PASSWORD=...
ADMIN_NAME=Demo Admin
```

Then run in the API service shell:

```bash
npm run admin:create
```

`ADMIN_PASSWORD` must contain at least 12 characters.

## 2. Configure Stripe test mode

Use Stripe **test-mode** keys for the public demo.

The backend needs:

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Configure the Stripe webhook endpoint as:

```text
https://YOUR_API_HOST/api/stripe/webhook
```

Do not put the Stripe secret key in the Flutter or React applications.

## 3. Deploy the React admin dashboard

The admin app lives in:

```text
apps/admin
```

Build command:

```bash
npm ci && npm run build
```

Output directory:

```text
dist
```

Configure the production environment variable:

```env
VITE_API_BASE_URL=https://YOUR_API_HOST
```

`apps/admin/public/_redirects` is included so React Router routes continue to work after a browser refresh on compatible static hosts such as Cloudflare Pages.

After the admin URL is known, update the API environment variable:

```env
ADMIN_ORIGIN=https://YOUR_ADMIN_HOST
```

The production refresh cookie is configured as `Secure` + `SameSite=None`, allowing the separately hosted admin site to refresh its authenticated session while CORS remains restricted to `ADMIN_ORIGIN`.

## 4. Build the Flutter Android demo

The Flutter app reads its production configuration through `--dart-define`.

From `apps/mobile`:

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://YOUR_API_HOST \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
```

The resulting APK is normally located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Use a Stripe **publishable test key** here. Never place the Stripe secret key in the app.

## 5. Production smoke test

Before linking the demo from the portfolio, verify this sequence:

```text
API /health
  -> Admin login
  -> Create/edit product
  -> Inventory update
  -> Flutter customer registration/login
  -> Load products
  -> Add to cart
  -> Checkout
  -> Stripe test payment
  -> Order appears in admin
```

## Public demo safety

For a portfolio deployment:

- use Stripe test mode only;
- use demo products and accounts, not real customer data;
- use a strong random `ACCESS_TOKEN_SECRET`;
- keep all server secrets in the hosting provider's environment-variable store;
- do not commit `.env` files;
- rotate demo admin credentials if they are ever exposed publicly.
