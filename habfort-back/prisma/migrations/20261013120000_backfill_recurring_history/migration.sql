-- Recurring completions used to live only in HabitLog, so History never saw
-- them. Copy every currently completed recurring log into HabitHistory, the
-- same shape HabitsService now writes on each completion. Coins come from the
-- ledger (net per log) so the snapshot matches what was actually credited.
INSERT INTO "HabitHistory" (
  "id", "userId", "habitId", "habitName", "habitType", "status",
  "coinsAwarded", "startedAt", "endedAt"
)
SELECT
  gen_random_uuid()::text,
  h."userId",
  h."id",
  h."name",
  h."type",
  'COMPLETED',
  COALESCE(
    (SELECT SUM(w."amount") FROM "WalletTransaction" w
      WHERE w."sourceType" = 'HABIT_COMPLETION' AND w."sourceId" = l."id"),
    0
  ),
  l."date",
  CASE WHEN l."createdAt"::date = l."date" THEN l."createdAt" ELSE l."date" END
FROM "HabitLog" l
JOIN "Habit" h ON h."id" = l."habitId"
WHERE h."type" = 'RECURRING' AND l."completed" = true;
