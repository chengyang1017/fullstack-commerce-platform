-- CreateEnum
CREATE TYPE "ShippingMethod" AS ENUM ('STANDARD', 'EXPRESS');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('ONLINE_BANKING', 'CARD', 'CASH_ON_DELIVERY');

-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "paymentMethod" "PaymentMethod" NOT NULL DEFAULT 'ONLINE_BANKING',
ADD COLUMN     "shippingMethod" "ShippingMethod" NOT NULL DEFAULT 'STANDARD';
