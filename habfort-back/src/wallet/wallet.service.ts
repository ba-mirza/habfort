import { Injectable } from '@nestjs/common';
import { Prisma, WalletSourceType } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';

type Db = PrismaService | Prisma.TransactionClient;

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  credit(
    userId: string,
    amount: number,
    sourceType: WalletSourceType,
    sourceId?: string,
    db: Db = this.prisma,
  ) {
    return this.record(db, userId, Math.abs(amount), sourceType, sourceId);
  }

  debit(
    userId: string,
    amount: number,
    sourceType: WalletSourceType,
    sourceId?: string,
    db: Db = this.prisma,
  ) {
    return this.record(db, userId, -Math.abs(amount), sourceType, sourceId);
  }

  async getBalance(userId: string, db: Db = this.prisma): Promise<number> {
    const result = await db.walletTransaction.aggregate({
      where: { userId },
      _sum: { amount: true },
    });
    return result._sum.amount ?? 0;
  }

  listTransactions(
    userId: string,
    take: number,
    skip: number,
    db: Db = this.prisma,
  ) {
    return db.walletTransaction.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take,
      skip,
    });
  }

  private record(
    db: Db,
    userId: string,
    amount: number,
    sourceType: WalletSourceType,
    sourceId?: string,
  ) {
    return db.walletTransaction.create({
      data: { userId, amount, sourceType, sourceId },
    });
  }
}
