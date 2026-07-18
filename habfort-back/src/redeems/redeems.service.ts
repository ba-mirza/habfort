import { BadRequestException, Injectable } from '@nestjs/common';
import { WalletSourceType } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { RewardsService } from '../rewards/rewards.service';
import { WalletService } from '../wallet/wallet.service';

@Injectable()
export class RedeemsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rewardsService: RewardsService,
    private readonly walletService: WalletService,
  ) {}

  async redeem(userId: string, rewardId: string) {
    const reward = await this.rewardsService.getOwnedReward(userId, rewardId);
    if (reward.archivedAt) {
      throw new BadRequestException(
        'This reward has been archived and can no longer be redeemed',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      // Serializes concurrent redeems for the same user so two simultaneous
      // requests can't both read a sufficient balance before either commits —
      // Read Committed alone wouldn't stop that race. Auto-released at commit.
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${userId}))`;

      const balance = await this.walletService.getBalance(userId, tx);
      if (balance < reward.costCoins) {
        throw new BadRequestException(
          'Insufficient coins to redeem this reward',
        );
      }

      const redeem = await tx.redeem.create({
        data: { userId, rewardId: reward.id, amountSpent: reward.costCoins },
      });
      await this.walletService.debit(
        userId,
        reward.costCoins,
        WalletSourceType.REDEEM,
        redeem.id,
        tx,
      );
      return redeem;
    });
  }

  findAll(userId: string) {
    return this.prisma.redeem.findMany({
      where: { userId },
      orderBy: { redeemedAt: 'desc' },
    });
  }
}
