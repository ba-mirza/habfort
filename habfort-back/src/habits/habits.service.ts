import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  Habit,
  HabitDifficulty,
  HabitHistoryStatus,
  HabitStatus,
  HabitType,
  WalletSourceType,
} from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { BonusService } from './bonus.service';
import {
  addDays,
  diffDays,
  normalizeDate,
  today,
  toDateKey,
} from './date.util';
import { CreateHabitDto } from './dto/create-habit.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';

@Injectable()
export class HabitsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletService: WalletService,
    private readonly bonusService: BonusService,
    private readonly configService: ConfigService,
  ) {}

  create(userId: string, dto: CreateHabitDto) {
    return this.prisma.habit.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type,
        difficulty: dto.difficulty,
        requiredDays: dto.requiredDays,
        scheduleType: dto.scheduleType,
        scheduleDays: dto.scheduleDays ?? [],
      },
    });
  }

  async findAll(userId: string) {
    await this.reconcileConditionalGaps(userId);
    const habits = await this.prisma.habit.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    // currentStreak is a read-time-only field for the frontend's progress
    // display (e.g. "12/30 days") — it isn't persisted anywhere, since the
    // authoritative streak calculation only matters at closure time.
    return Promise.all(
      habits.map(async (habit) => {
        if (habit.type !== HabitType.CONDITIONAL) {
          return habit;
        }
        const startDate = normalizeDate(habit.createdAt);
        const currentStreak = await this.computeConsecutiveStreak(
          habit.id,
          startDate,
          today(),
        );
        return { ...habit, currentStreak };
      }),
    );
  }

  async findOne(userId: string, id: string) {
    return this.getOwnedHabit(userId, id);
  }

  async update(userId: string, id: string, dto: UpdateHabitDto) {
    await this.getOwnedHabit(userId, id);
    return this.prisma.habit.update({
      where: { id },
      data: { name: dto.name },
    });
  }

  async remove(userId: string, id: string): Promise<void> {
    await this.getOwnedHabit(userId, id);
    await this.prisma.habit.delete({ where: { id } });
  }

  async completeHabit(userId: string, habitId: string) {
    const habit = await this.getOwnedHabit(userId, habitId, HabitType.INSTANT);
    return this.closeHabit(
      habit,
      HabitHistoryStatus.COMPLETED,
      this.coinsFor(habit.difficulty),
    );
  }

  async logHabitDay(
    userId: string,
    habitId: string,
    dateInput: string | undefined,
    completed: boolean,
  ) {
    const habit = await this.getOwnedHabit(userId, habitId);

    if (habit.type === HabitType.CONDITIONAL) {
      return this.logConditionalDay(habit, dateInput, completed);
    }
    if (habit.type === HabitType.RECURRING) {
      return this.logRecurringDay(habit, dateInput, completed);
    }
    throw new BadRequestException(
      'INSTANT habits are completed via POST /habits/:id/complete, not /log',
    );
  }

  private async logConditionalDay(
    habit: Habit,
    dateInput: string | undefined,
    completed: boolean,
  ) {
    const date = this.resolveLogDate(habit, dateInput);

    await this.prisma.habitLog.upsert({
      where: { habitId_date: { habitId: habit.id, date } },
      update: { completed },
      create: { habitId: habit.id, date, completed },
    });

    if (!completed) {
      // No per-day coins are ever awarded for conditional habits, so unmarking
      // a day before the streak closes has no wallet side effect to reverse.
      return habit;
    }

    const startDate = normalizeDate(habit.createdAt);
    const streak = await this.computeConsecutiveStreak(
      habit.id,
      startDate,
      date,
    );
    const daysSinceStart = diffDays(startDate, date) + 1;
    const requiredDays = habit.requiredDays!;

    if (streak >= requiredDays) {
      return this.closeHabit(
        habit,
        HabitHistoryStatus.COMPLETED,
        this.coinsFor(habit.difficulty),
        streak,
        requiredDays,
      );
    }
    if (streak < daysSinceStart) {
      const coins = Math.round(
        (this.coinsFor(habit.difficulty) * streak) / requiredDays,
      );
      return this.closeHabit(
        habit,
        HabitHistoryStatus.PARTIAL,
        coins,
        streak,
        requiredDays,
      );
    }
    return habit;
  }

  private async logRecurringDay(
    habit: Habit,
    dateInput: string | undefined,
    completed: boolean,
  ) {
    const date = this.resolveLogDate(habit, dateInput);
    const existing = await this.prisma.habitLog.findUnique({
      where: { habitId_date: { habitId: habit.id, date } },
    });

    if (existing && existing.completed === completed) {
      return existing;
    }

    const log = await this.prisma.$transaction(async (tx) => {
      const log = await tx.habitLog.upsert({
        where: { habitId_date: { habitId: habit.id, date } },
        update: { completed },
        create: { habitId: habit.id, date, completed },
      });

      const coins = this.coinsFor(habit.difficulty);
      if (completed) {
        await this.walletService.credit(
          habit.userId,
          coins,
          WalletSourceType.HABIT_COMPLETION,
          log.id,
          tx,
        );
      } else {
        await this.walletService.debit(
          habit.userId,
          coins,
          WalletSourceType.HABIT_COMPLETION,
          log.id,
          tx,
        );
      }
      return log;
    });

    // Only a fresh completion can newly satisfy "everything due today" —
    // unchecking can't, so the bonus check only runs on the credit path.
    if (completed) {
      await this.bonusService.checkAndAwardFullDayBonus(habit.userId, date);
    }
    return log;
  }

  // Silence, not a visit, is what closes a broken conditional streak: once a
  // calendar day has fully passed without a completed log, the streak is
  // broken as of that day regardless of whether the user opened the app.
  // Checked lazily whenever the habit list is read.
  private async reconcileConditionalGaps(userId: string): Promise<void> {
    const yesterday = addDays(today(), -1);
    const activeConditionals = await this.prisma.habit.findMany({
      where: {
        userId,
        type: HabitType.CONDITIONAL,
        status: HabitStatus.ACTIVE,
      },
    });

    for (const habit of activeConditionals) {
      const startDate = normalizeDate(habit.createdAt);
      if (yesterday < startDate) {
        continue; // created today (or later) — nothing to check yet
      }

      const requiredDays = habit.requiredDays!;
      const streak = await this.computeConsecutiveStreak(
        habit.id,
        startDate,
        yesterday,
      );
      const daysSinceStart = diffDays(startDate, yesterday) + 1;

      if (streak < daysSinceStart) {
        const coins = Math.round(
          (this.coinsFor(habit.difficulty) * streak) / requiredDays,
        );
        await this.closeHabit(
          habit,
          HabitHistoryStatus.PARTIAL,
          coins,
          streak,
          requiredDays,
        );
      }
    }
  }

  private async computeConsecutiveStreak(
    habitId: string,
    startDate: Date,
    uptoDate: Date,
  ): Promise<number> {
    const logs = await this.prisma.habitLog.findMany({
      where: {
        habitId,
        completed: true,
        date: { gte: startDate, lte: uptoDate },
      },
      select: { date: true },
    });
    const completedDates = new Set(logs.map((log) => toDateKey(log.date)));

    let streak = 0;
    let cursor = startDate;
    while (cursor <= uptoDate) {
      if (!completedDates.has(toDateKey(cursor))) {
        break;
      }
      streak++;
      cursor = addDays(cursor, 1);
    }
    return streak;
  }

  private async closeHabit(
    habit: Habit,
    status: HabitHistoryStatus,
    coinsAwarded: number,
    daysCompleted?: number,
    daysRequired?: number,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const history = await tx.habitHistory.create({
        data: {
          userId: habit.userId,
          habitId: habit.id,
          habitName: habit.name,
          habitType: habit.type,
          status,
          daysCompleted,
          daysRequired,
          coinsAwarded,
          startedAt: habit.createdAt,
        },
      });
      if (coinsAwarded > 0) {
        await this.walletService.credit(
          habit.userId,
          coinsAwarded,
          WalletSourceType.HABIT_COMPLETION,
          history.id,
          tx,
        );
      }
      await tx.habit.delete({ where: { id: habit.id } });
      // Deleting the habit triggers the SetNull FK action on habitId, but the
      // in-memory `history` object from `create()` above still holds the
      // pre-delete value — re-fetch so the response reflects what's actually
      // persisted (habitId: null), not a stale snapshot.
      return tx.habitHistory.findUniqueOrThrow({ where: { id: history.id } });
    });
  }

  private resolveLogDate(habit: Habit, dateInput: string | undefined): Date {
    const date = dateInput ? normalizeDate(dateInput) : today();
    const startDate = normalizeDate(habit.createdAt);
    if (date < startDate) {
      throw new BadRequestException('Date is before the habit was created');
    }
    if (date > today()) {
      throw new BadRequestException('Cannot log a future date');
    }
    return date;
  }

  private coinsFor(difficulty: HabitDifficulty): number {
    const key = difficulty.toLowerCase() as 'easy' | 'medium' | 'hard';
    return this.configService.getOrThrow<number>(
      `habits.difficultyCoins.${key}`,
    );
  }

  private async getOwnedHabit(
    userId: string,
    id: string,
    expectedType?: HabitType,
  ): Promise<Habit> {
    const habit = await this.prisma.habit.findFirst({ where: { id, userId } });
    if (!habit) {
      throw new NotFoundException('Habit not found');
    }
    if (expectedType && habit.type !== expectedType) {
      throw new BadRequestException(
        `This action only applies to ${expectedType} habits`,
      );
    }
    return habit;
  }
}
