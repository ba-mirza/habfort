import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { ProgressService } from './progress.service';

@ApiTags('progress')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('progress')
export class ProgressController {
  constructor(private readonly progressService: ProgressService) {}

  @Get()
  get(@CurrentUser() user: SupabaseJwtPayload) {
    return this.progressService.get(user.sub);
  }
}
