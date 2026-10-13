-- AlterEnum
ALTER TYPE "WalletSourceType" ADD VALUE 'WELCOME_BONUS';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "onboardedAt" TIMESTAMP(3);

-- Everyone who signed up before onboarding existed has already been using
-- the app: treat them as onboarded so they neither see the welcome flow nor
-- get the welcome bonus retroactively.
UPDATE "User" SET "onboardedAt" = CURRENT_TIMESTAMP WHERE "onboardedAt" IS NULL;
