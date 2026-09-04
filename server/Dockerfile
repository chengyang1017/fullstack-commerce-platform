FROM node:24-bookworm-slim

WORKDIR /app

# Prisma needs OpenSSL both while generating the client and at runtime.
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY prisma ./prisma
COPY prisma.config.ts tsconfig.json ./

# Prisma 7 loads prisma.config.ts even for `prisma generate` and therefore
# expects DATABASE_URL to exist at build time. Client generation does not
# connect to the database, so a harmless placeholder is sufficient here.
# Railway injects the real DATABASE_URL at runtime and overrides this value.
ENV DATABASE_URL=postgresql://placeholder:placeholder@127.0.0.1:5432/placeholder
RUN npx prisma generate

COPY src ./src

ENV NODE_ENV=production
EXPOSE 3000

CMD ["sh", "-c", "npx prisma migrate deploy && node src/app.ts"]
