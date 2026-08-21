import { Injectable } from '@nestjs/common';
import {
  HabitStatus,
  HabitType,
  Prisma,
  RecurringScheduleType,
} from '../../generated/prisma';
import { addDays, normalizeDate, today, toDateKey } from '../habits/date.util';
import { PrismaService } from '../prisma/prisma.service';
import { DateRangeQueryDto } from './dto/date-range-query.dto';
import { ListHistoryQueryDto } from './dto/list-history-query.dto';

/** How far back the discipline window reaches when no range is given. */
const DEFAULT_DISCIPLINE_DAYS = 30;

type ScheduledHabit = {
  id: string;
  type: HabitType;
  scheduleType: RecurringScheduleType | null;
  scheduleDays: number[];
  createdAt: Date;
};

@Injectable()
export class HistoryService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(userId: string, query: ListHistoryQueryDto) {
    return this.prisma.habitHistory.findMany({
      where: {
        userId,
        status: query.status,
        habitType: query.type,
        endedAt: this.dateRange(query),
      },
      orderBy: { endedAt: 'desc' },
      take: query.take,
      skip: query.skip,
    });
  }

  async stats(userId: string, query: DateRangeQueryDto) {
    const where: Prisma.HabitHistoryWhereInput = {
      userId,
      endedAt: this.dateRange(query),
    };

    const [byStatus, byType, totals] = await Promise.all([
      this.prisma.habitHistory.groupBy({
        by: ['status'],
        where,
        _count: { _all: true },
        _sum: { coinsAwarded: true },
      }),
      this.prisma.habitHistory.groupBy({
        by: ['habitType'],
        where,
        _count: { _all: true },
        _sum: { coinsAwarded: true },
      }),
      this.prisma.habitHistory.aggregate({
        where,
        _count: { _all: true },
        _sum: { coinsAwarded: true },
      }),
    ]);

    return {
      totalEntries: totals._count._all,
      totalCoinsAwarded: totals._sum.coinsAwarded ?? 0,
      byStatus: byStatus.map((row) => ({
        status: row.status,
        count: row._count._all,
        coinsAwarded: row._sum.coinsAwarded ?? 0,
      })),
      byType: byType.map((row) => ({
        type: row.habitType,
        count: row._count._all,
        coinsAwarded: row._sum.coinsAwarded ?? 0,
      })),
    };
  }

  /**
   * Share of scheduled habit-days that were actually completed.
   *
   * `habit_history` can't answer this: recurring habits never close, so they
   * write no history at all, and instant habits only ever close as COMPLETED.
   * The daily logs can't answer it alone either — a skipped day writes no row,
   * so counting logs would make every user look perfect. So the denominator is
   * derived from each habit's schedule, and the logs only supply the numerator.
   *
   * Only currently-active habits are known to the schedule, so days that
   * belonged to a since-deleted habit aren't counted.
   */
  async discipline(userId: string, query: DateRangeQueryDto) {
    const end = query.to ? normalizeDate(query.to) : today();
    const start = query.from
      ? normalizeDate(query.from)
      : addDays(end, -(DEFAULT_DISCIPLINE_DAYS - 1));

    const habits = await this.prisma.habit.findMany({
      where: {
        userId,
        status: HabitStatus.ACTIVE,
        // INSTANT habits have no schedule — they're due whenever the user says.
        type: { in: [HabitType.RECURRING, HabitType.CONDITIONAL] },
      },
      select: {
        id: true,
        type: true,
        scheduleType: true,
        scheduleDays: true,
        createdAt: true,
      },
    });

    const logs = await this.prisma.habitLog.findMany({
      where: {
        completed: true,
        date: { gte: start, lte: end },
        habit: { userId },
      },
      select: { habitId: true, date: true },
    });
    const completedKeys = new Set(
      logs.map((log) => `${log.habitId}:${toDateKey(log.date)}`),
    );

    const byDay: { date: string; planned: number; completed: number }[] = [];
    let totalPlanned = 0;
    let totalCompleted = 0;

    for (let day = start; day <= end; day = addDays(day, 1)) {
      const dateKey = toDateKey(day);
      let planned = 0;
      let completed = 0;

      for (const habit of habits) {
        if (!this.isScheduledOn(habit, day)) {
          continue;
        }
        planned += 1;
        if (completedKeys.has(`${habit.id}:${dateKey}`)) {
          completed += 1;
        }
      }

      byDay.push({ date: dateKey, planned, completed });
      totalPlanned += planned;
      totalCompleted += completed;
    }

    return {
      from: toDateKey(start),
      to: toDateKey(end),
      totalPlanned,
      totalCompleted,
      // Null rather than 0 when nothing was scheduled — "no data" and "failed
      // everything" must not look the same to the client.
      rate: totalPlanned > 0 ? totalCompleted / totalPlanned : null,
      byDay,
    };
  }

  private isScheduledOn(habit: ScheduledHabit, day: Date): boolean {
    if (day < normalizeDate(habit.createdAt)) {
      return false;
    }
    if (
      habit.type === HabitType.RECURRING &&
      habit.scheduleType === RecurringScheduleType.DAYS_OF_WEEK
    ) {
      return habit.scheduleDays.includes(day.getUTCDay());
    }
    // Daily recurring habits and running challenges are due every day.
    return true;
  }

  private dateRange(
    query: DateRangeQueryDto,
  ): Prisma.DateTimeFilter | undefined {
    if (!query.from && !query.to) {
      return undefined;
    }
    const range: Prisma.DateTimeFilter = {};
    if (query.from) {
      range.gte = new Date(query.from);
    }
    if (query.to) {
      range.lte = new Date(query.to);
    }
    return range;
  }
}
