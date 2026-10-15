import { randomUUID } from 'crypto';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { WalletSourceType } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { RewardsService } from '../rewards/rewards.service';
import { StorageService } from '../storage/storage.service';
import { WalletService } from '../wallet/wallet.service';
import { UpdateRedeemDto } from './dto/update-redeem.dto';

@Injectable()
export class RedeemsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rewardsService: RewardsService,
    private readonly walletService: WalletService,
    private readonly storageService: StorageService,
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

  // Includes the reward name: archived rewards are filtered out of
  // GET /rewards, so a client can't resolve the name from that list alone.
  // Photos get a short-lived signed URL; the bucket itself is private.
  async findAll(userId: string) {
    const redeems = await this.prisma.redeem.findMany({
      where: { userId },
      orderBy: { redeemedAt: 'desc' },
      include: { reward: { select: { id: true, name: true } } },
    });
    const photoPaths = redeems.flatMap((r) =>
      r.photoPath ? [r.photoPath] : [],
    );
    // A storage hiccup shouldn't take the whole spend log down with it.
    const urls = await this.storageService
      .createSignedUrls(photoPaths)
      .catch(() => new Map<string, string>());
    return redeems.map((redeem) => ({
      ...redeem,
      photoUrl: redeem.photoPath ? (urls.get(redeem.photoPath) ?? null) : null,
    }));
  }

  /** Where the client uploads a diary photo for one of its redeems. */
  async createPhotoUpload(userId: string, redeemId: string) {
    await this.getOwnedRedeem(userId, redeemId);
    const path = `${this.photoPrefix(userId, redeemId)}${randomUUID()}.jpg`;
    const uploadUrl = await this.storageService.createSignedUploadUrl(path);
    return { path, uploadUrl };
  }

  async update(userId: string, redeemId: string, dto: UpdateRedeemDto) {
    const redeem = await this.getOwnedRedeem(userId, redeemId);
    if (
      dto.photoPath !== undefined &&
      !dto.photoPath.startsWith(this.photoPrefix(userId, redeemId))
    ) {
      throw new BadRequestException('photoPath does not belong to this redeem');
    }

    // An empty note clears it; an omitted one leaves it alone.
    const note = dto.note === undefined ? undefined : dto.note.trim() || null;
    const updated = await this.prisma.redeem.update({
      where: { id: redeemId },
      data: { note, photoPath: dto.photoPath },
    });
    // The replaced photo is unreachable now; clean it up, best effort.
    if (
      dto.photoPath &&
      redeem.photoPath &&
      redeem.photoPath !== dto.photoPath
    ) {
      await this.storageService
        .remove([redeem.photoPath])
        .catch(() => undefined);
    }
    return updated;
  }

  private photoPrefix(userId: string, redeemId: string): string {
    return `${userId}/${redeemId}/`;
  }

  private async getOwnedRedeem(userId: string, id: string) {
    const redeem = await this.prisma.redeem.findFirst({
      where: { id, userId },
    });
    if (!redeem) {
      throw new NotFoundException('Redeem not found');
    }
    return redeem;
  }
}
