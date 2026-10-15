import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HabitHistoryStatus, HabitType } from '../../generated/prisma';
import { AchievementMetric } from '../config/progress.config';
import { HistoryService } from '../history/history.service';
import { PrismaService } from '../prisma/prisma.service';

type AchievementDef = { id: string; metric: AchievementMetric; target: number };

/**
 * Levels and achievements, derived on every read from what's already
 * recorded — habit_history (coins earned, completions), redeems and FULL-day
 * bonuses. Nothing is stored, so changing the curve or adding an achievement
 * applies retroactively to everyone.
 */
@Injectable()
export class ProgressService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly historyService: HistoryService,
    private readonly configService: ConfigService,
  ) {}

  async get(userId: string) {
    const done = {
      userId,
      status: { not: HabitHistoryStatus.NOT_COMPLETED },
    };
    const [earned, challengesCompleted, redeems, fullDays, streak] =
      await Promise.all([
        this.prisma.habitHistory.aggregate({
          where: done,
          _count: { _all: true },
          _sum: { coinsAwarded: true },
        }),
        this.prisma.habitHistory.count({
          where: {
            userId,
            habitType: HabitType.CONDITIONAL,
            status: HabitHistoryStatus.COMPLETED,
          },
        }),
        this.prisma.redeem.count({ where: { userId } }),
        this.prisma.dailyBonusLog.count({ where: { userId } }),
        this.historyService.streak(userId),
      ]);

    const coinsEarned = earned._sum.coinsAwarded ?? 0;
    const metrics: Record<AchievementMetric, number> = {
      completions: earned._count._all,
      bestStreak: streak.best,
      redeems,
      challengesCompleted,
      fullDays,
      coinsEarned,
    };

    const xp =
      coinsEarned * this.configService.getOrThrow<number>('habits.xpPerCoin');
    const achievements = this.configService
      .getOrThrow<AchievementDef[]>('progress.achievements')
      .map(({ id, metric, target }) => ({
        id,
        current: Math.min(metrics[metric], target),
        target,
        unlocked: metrics[metric] >= target,
      }));

    return { ...this.level(xp), metrics, achievements };
  }

  private level(xp: number) {
    const base = this.configService.getOrThrow<number>('progress.levelBaseXp');
    const startOf = (level: number) => (base * level * (level - 1)) / 2;
    let level = 1;
    while (startOf(level + 1) <= xp) {
      level++;
    }
    return {
      xp,
      level,
      // XP gathered inside the current level, and how much the level spans.
      levelXp: xp - startOf(level),
      levelSpan: startOf(level + 1) - startOf(level),
    };
  }
}
