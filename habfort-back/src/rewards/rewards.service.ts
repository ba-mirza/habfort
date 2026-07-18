import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRewardDto } from './dto/create-reward.dto';

@Injectable()
export class RewardsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  create(userId: string, dto: CreateRewardDto) {
    const minCostCoins = this.configService.getOrThrow<number>(
      'rewards.minCostCoins',
    );
    if (dto.costCoins < minCostCoins) {
      throw new BadRequestException(
        `Reward cost must be at least ${minCostCoins} coins`,
      );
    }
    return this.prisma.reward.create({
      data: { userId, name: dto.name, costCoins: dto.costCoins },
    });
  }

  findAll(userId: string) {
    return this.prisma.reward.findMany({
      where: { userId, archivedAt: null },
      orderBy: { createdAt: 'desc' },
    });
  }

  async archive(userId: string, id: string) {
    const reward = await this.getOwnedReward(userId, id);
    if (reward.archivedAt) {
      return reward;
    }
    return this.prisma.reward.update({
      where: { id },
      data: { archivedAt: new Date() },
    });
  }

  // Public — RedeemsService reuses this to look up + verify ownership rather
  // than duplicating the query.
  async getOwnedReward(userId: string, id: string) {
    const reward = await this.prisma.reward.findFirst({
      where: { id, userId },
    });
    if (!reward) {
      throw new NotFoundException('Reward not found');
    }
    return reward;
  }
}
