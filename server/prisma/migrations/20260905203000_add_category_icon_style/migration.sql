ALTER TABLE "Category"
ADD COLUMN "iconName" TEXT NOT NULL DEFAULT 'category',
ADD COLUMN "iconColorStart" TEXT NOT NULL DEFAULT '#7C3AED',
ADD COLUMN "iconColorEnd" TEXT NOT NULL DEFAULT '#06B6D4';

UPDATE "Category"
SET
  "iconName" = 'devices',
  "iconColorStart" = '#2563EB',
  "iconColorEnd" = '#06B6D4'
WHERE lower("name") = 'electronics';

UPDATE "Category"
SET
  "iconName" = 'cable',
  "iconColorStart" = '#7C3AED',
  "iconColorEnd" = '#EC4899'
WHERE lower("name") = 'accessories';

UPDATE "Category"
SET
  "iconName" = 'home',
  "iconColorStart" = '#F97316',
  "iconColorEnd" = '#FACC15'
WHERE lower("name") = 'home & living';

UPDATE "Category"
SET
  "iconName" = 'gaming',
  "iconColorStart" = '#EF4444',
  "iconColorEnd" = '#8B5CF6'
WHERE lower("name") = 'gaming';
