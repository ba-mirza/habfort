-- CreateEnum
CREATE TYPE "HabitHistoryStatus" AS ENUM ('COMPLETED', 'NOT_COMPLETED', 'PARTIAL');

-- CreateTable
CREATE TABLE "HabitHistory" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "habitId" TEXT,
    "habitName" TEXT NOT NULL,
    "habitType" "HabitType" NOT NULL,
    "status" "HabitHistoryStatus" NOT NULL,
    "daysCompleted" INTEGER,
    "daysRequired" INTEGER,
    "coinsAwarded" INTEGER NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL,
    "endedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HabitHistory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "HabitHistory_userId_idx" ON "HabitHistory"("userId");

-- CreateIndex
CREATE INDEX "HabitHistory_userId_status_idx" ON "HabitHistory"("userId", "status");

-- AddForeignKey
ALTER TABLE "HabitHistory" ADD CONSTRAINT "HabitHistory_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "HabitHistory" ADD CONSTRAINT "HabitHistory_habitId_fkey" FOREIGN KEY ("habitId") REFERENCES "Habit"("id") ON DELETE SET NULL ON UPDATE CASCADE;
