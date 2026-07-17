import { Test } from '@nestjs/testing';
import { WalletSourceType } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from './wallet.service';

describe('WalletService', () => {
  let service: WalletService;
  let prisma: {
    walletTransaction: {
      aggregate: jest.Mock;
      create: jest.Mock;
      findMany: jest.Mock;
    };
  };

  beforeEach(async () => {
    prisma = {
      walletTransaction: {
        aggregate: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
      },
    };

    const module = await Test.createTestingModule({
      providers: [WalletService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(WalletService);
  });

  describe('getBalance', () => {
    it('sums mixed positive and negative transactions', async () => {
      prisma.walletTransaction.aggregate.mockResolvedValue({
        _sum: { amount: 35 },
      });

      const balance = await service.getBalance('user-1');

      expect(balance).toBe(35);
      expect(prisma.walletTransaction.aggregate).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        _sum: { amount: true },
      });
    });

    it('returns 0 when the user has no transactions', async () => {
      prisma.walletTransaction.aggregate.mockResolvedValue({
        _sum: { amount: null },
      });

      const balance = await service.getBalance('user-1');

      expect(balance).toBe(0);
    });
  });

  describe('credit', () => {
    it('always records a positive amount, even if called with a negative number', async () => {
      await service.credit('user-1', -10, WalletSourceType.HABIT_COMPLETION);

      expect(prisma.walletTransaction.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-1',
          amount: 10,
          sourceType: WalletSourceType.HABIT_COMPLETION,
          sourceId: undefined,
        },
      });
    });
  });

  describe('debit', () => {
    it('always records a negative amount, even if called with a positive number', async () => {
      await service.debit('user-1', 10, WalletSourceType.REDEEM, 'reward-1');

      expect(prisma.walletTransaction.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-1',
          amount: -10,
          sourceType: WalletSourceType.REDEEM,
          sourceId: 'reward-1',
        },
      });
    });
  });
});
