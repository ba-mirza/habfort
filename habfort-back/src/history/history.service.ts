import { Injectable } from '@nestjs/common';
import {
  HabitStatus,
  HabitType,
  Prisma,
  RecurringScheduleType,
} from '../../generated/prisma';
import {
  addDays,
  normalizeDate,
  today,
  toDateKey,
  localDate,
  currentTimeZone,
} from '../habits/date.util';
import { PrismaService } from '../prisma/prisma.service';
import { DateRangeQueryDto } from './dto/date-range-query.dto';
import { ListHistoryQueryDto } from './dto/list-history-query.dto';

/** How far back the discipline window reaches when no range is given. */
const DEFAULT_DISCIPLINE_DAYS = 30;

/** Activity defaults to a year — the widest view the profile heatmap shows. */
const DEFAULT_ACTIVITY_DAYS = 365;

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
   * Completions per calendar day, for the profile heatmap. A completion is a
   * history entry (every recurring day, every closed instant/challenge) or a
   * day already ticked in a challenge that's still running — those only reach
   * history when the challenge closes. Only days with completions are listed.
   */
  async activity(userId: string, query: DateRangeQueryDto) {
    const end = query.to ? normalizeDate(query.to) : today();
    const start = query.from
      ? normalizeDate(query.from)
      : addDays(end, -(DEFAULT_ACTIVITY_DAYS - 1));

    // endedAt is stored as UTC; shift it into the user's zone before taking
    // the day, so a 1 a.m. completion lands on the user's day, not UTC's.
    const timeZone = currentTimeZone();
    const rows = await this.prisma.$queryRaw<{ day: Date; count: bigint }[]>`
      SELECT day, COUNT(*) AS count FROM (
        SELECT (("endedAt" AT TIME ZONE 'UTC') AT TIME ZONE ${timeZone})::date AS day
        FROM "HabitHistory"
        WHERE "userId" = ${userId}
          AND "status" <> 'NOT_COMPLETED'
        UNION ALL
        SELECT l."date" AS day
        FROM "HabitLog" l
        JOIN "Habit" h ON h."id" = l."habitId"
        WHERE h."userId" = ${userId}
          AND h."type" = 'CONDITIONAL'
          AND l."completed" = true
      ) completions
      WHERE day >= ${start} AND day <= ${end}
      GROUP BY day
      ORDER BY day`;

    const byDay = rows.map((row) => ({
      date: toDateKey(row.day),
      count: Number(row.count),
    }));
    const bestDay = byDay.reduce<(typeof byDay)[number] | null>(
      (best, day) => (!best || day.count > best.count ? day : best),
      null,
    );

    return {
      from: toDateKey(start),
      to: toDateKey(end),
      total: byDay.reduce((sum, day) => sum + day.count, 0),
      bestDay,
      byDay,
    };
  }

  /**
   * Share of scheduled habit-days that were actually completed.
   *
   * `habit_history` can't answer this: it only records what was done (instant
   * habits only ever close as COMPLETED, recurring days only when ticked).
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
    if (day < localDate(habit.createdAt)) {
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
