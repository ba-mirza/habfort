import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CreateRewardDto } from './dto/create-reward.dto';
import { ListRewardsQueryDto } from './dto/list-rewards-query.dto';
import { RewardsService } from './rewards.service';

@ApiTags('rewards')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('rewards')
export class RewardsController {
  constructor(private readonly rewardsService: RewardsService) {}

  @Post()
  create(
    @CurrentUser() user: SupabaseJwtPayload,
    @Body() dto: CreateRewardDto,
  ) {
    return this.rewardsService.create(user.sub, dto);
  }

  @Get()
  findAll(
    @CurrentUser() user: SupabaseJwtPayload,
    @Query() query: ListRewardsQueryDto,
  ) {
    return this.rewardsService.findAll(user.sub, query.archived);
  }

  @Patch(':id')
  archive(@CurrentUser() user: SupabaseJwtPayload, @Param('id') id: string) {
    return this.rewardsService.archive(user.sub, id);
  }

  @Patch(':id/restore')
  restore(@CurrentUser() user: SupabaseJwtPayload, @Param('id') id: string) {
    return this.rewardsService.restore(user.sub, id);
  }
}
