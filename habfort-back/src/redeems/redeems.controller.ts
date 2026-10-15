import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CreateRedeemDto } from './dto/create-redeem.dto';
import { UpdateRedeemDto } from './dto/update-redeem.dto';
import { RedeemsService } from './redeems.service';

@ApiTags('redeems')
@ApiBearerAuth()
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

  @Post(':id/photo-upload')
  createPhotoUpload(
    @CurrentUser() user: SupabaseJwtPayload,
    @Param('id') id: string,
  ) {
    return this.redeemsService.createPhotoUpload(user.sub, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: SupabaseJwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateRedeemDto,
  ) {
    return this.redeemsService.update(user.sub, id, dto);
  }
}
