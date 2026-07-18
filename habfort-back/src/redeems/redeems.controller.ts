import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CreateRedeemDto } from './dto/create-redeem.dto';
import { RedeemsService } from './redeems.service';

@UseGuards(SupabaseAuthGuard)
@Controller('redeems')
export class RedeemsController {
  constructor(private readonly redeemsService: RedeemsService) {}

  @Post()
  redeem(
    @CurrentUser() user: SupabaseJwtPayload,
    @Body() dto: CreateRedeemDto,
  ) {
    return this.redeemsService.redeem(user.sub, dto.rewardId);
  }

  @Get()
  findAll(@CurrentUser() user: SupabaseJwtPayload) {
    return this.redeemsService.findAll(user.sub);
  }
}
