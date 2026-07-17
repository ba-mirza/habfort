-- CreateTable
CREATE TABLE "DailyBonusLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DailyBonusLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "DailyBonusLog_userId_date_key" ON "DailyBonusLog"("userId", "date");

-- AddForeignKey
ALTER TABLE "DailyBonusLog" ADD CONSTRAINT "DailyBonusLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
