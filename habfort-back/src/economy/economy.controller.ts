import { Controller, Get, UseGuards } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { HabitDifficulty } from '../../generated/prisma';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';

type DifficultyCoins = Record<Lowercase<HabitDifficulty>, number>;

/**
 * Read-only view of the coin constants so clients can explain the economy
 * ("Сложная = 20 жетонов") without duplicating the numbers — the config stays
 * the single source of truth, exactly as the awarding logic uses it.
 */
@ApiTags('economy')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('economy')
export class EconomyController {
  constructor(private readonly configService: ConfigService) {}

  @Get()
  get() {
    const difficultyCoins = this.configService.getOrThrow<DifficultyCoins>(
      'habits.difficultyCoins',
    );

    return {
      // Keyed by the enum values the API speaks, not the lowercase config keys.
      difficultyCoins: {
        [HabitDifficulty.EASY]: difficultyCoins.easy,
        [HabitDifficulty.MEDIUM]: difficultyCoins.medium,
        [HabitDifficulty.HARD]: difficultyCoins.hard,
      },
      fullDayBonus: this.configService.getOrThrow<{
        weekday: number;
        weekend: number;
      }>('habits.fullDayBonus'),
      rewardMinCostCoins: this.configService.getOrThrow<number>(
        'rewards.minCostCoins',
      ),
    };
  }
}
