import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  HabitStatus,
  HabitType,
  Prisma,
  RecurringScheduleType,
  WalletSourceType,
} from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';

const PRISMA_UNIQUE_CONSTRAINT_VIOLATION = 'P2002';

@Injectable()
export class BonusService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletService: WalletService,
    private readonly configService: ConfigService,
  ) {}

  // Only RECURRING habits scheduled for `date` count toward "everything due
  // today" — instant/conditional habits have no fixed schedule, so they're
  // excluded from this calculation entirely (a deliberate scope decision).
  async checkAndAwardFullDayBonus(userId: string, date: Date): Promise<void> {
    const recurringHabits = await this.prisma.habit.findMany({
      where: { userId, type: HabitType.RECURRING, status: HabitStatus.ACTIVE },
    });
    const dueToday = recurringHabits.filter((habit) =>
      this.isScheduledOn(habit, date),
    );
    if (dueToday.length === 0) {
      return;
    }

    const completedLogs = await this.prisma.habitLog.findMany({
      where: {
        habitId: { in: dueToday.map((habit) => habit.id) },
        date,
        completed: true,
      },
      select: { habitId: true },
    });
    const doneHabitIds = new Set(completedLogs.map((log) => log.habitId));
    const allDone = dueToday.every((habit) => doneHabitIds.has(habit.id));
    if (!allDone) {
      return;
    }

    await this.award(userId, date);
  }

  private isScheduledOn(
    habit: {
      scheduleType: RecurringScheduleType | null;
      scheduleDays: number[];
    },
    date: Date,
  ): boolean {
    if (habit.scheduleType === RecurringScheduleType.DAILY) {
      return true;
    }
    if (habit.scheduleType === RecurringScheduleType.DAYS_OF_WEEK) {
      return habit.scheduleDays.includes(date.getUTCDay());
    }
    return false;
  }

  private async award(userId: string, date: Date): Promise<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        const bonusLog = await tx.dailyBonusLog.create({
          data: { userId, date },
        });
        await this.walletService.credit(
          userId,
          this.bonusAmountFor(date),
          WalletSourceType.FULL_BONUS,
          bonusLog.id,
          tx,
        );
      });
    } catch (error) {
      const isAlreadyAwarded =
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === PRISMA_UNIQUE_CONSTRAINT_VIOLATION;
      if (!isAlreadyAwarded) {
        throw error;
      }
      // The unique (userId, date) constraint — not this catch block — is what
      // makes this race-proof; a concurrent request hitting it just no-ops here.
    }
  }

  private bonusAmountFor(date: Date): number {
    const weekendDays =
      this.configService.getOrThrow<number[]>('habits.weekendDays');
    const key = weekendDays.includes(date.getUTCDay()) ? 'weekend' : 'weekday';
    return this.configService.getOrThrow<number>(`habits.fullDayBonus.${key}`);
  }
}
