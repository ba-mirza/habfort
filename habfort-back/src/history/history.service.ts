import { Injectable } from '@nestjs/common';
import { Prisma } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { DateRangeQueryDto } from './dto/date-range-query.dto';
import { ListHistoryQueryDto } from './dto/list-history-query.dto';

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
