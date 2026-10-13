import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WalletSourceType } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';

@Injectable()
export class OnboardingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletService: WalletService,
    private readonly configService: ConfigService,
  ) {}

  // Marks onboarding done and credits the welcome bonus in one transaction.
  // The conditional update is the idempotency guard: only the request that
  // flips onboardedAt from null gets to credit, however often it's retried.
  async complete(userId: string) {
    return this.prisma.$transaction(async (tx) => {
      const { count } = await tx.user.updateMany({
        where: { id: userId, onboardedAt: null },
        data: { onboardedAt: new Date() },
      });
      if (count === 1) {
        await this.walletService.credit(
          userId,
          this.configService.getOrThrow<number>('habits.welcomeBonus'),
          WalletSourceType.WELCOME_BONUS,
          undefined,
          tx,
        );
      }
      return tx.user.findUniqueOrThrow({ where: { id: userId } });
    });
  }
}
