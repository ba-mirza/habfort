import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { DateRangeQueryDto } from './dto/date-range-query.dto';
import { ListHistoryQueryDto } from './dto/list-history-query.dto';
import { HistoryService } from './history.service';

@ApiTags('history')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('history')
export class HistoryController {
  constructor(private readonly historyService: HistoryService) {}

  @Get()
  findAll(
    @CurrentUser() user: SupabaseJwtPayload,
    @Query() query: ListHistoryQueryDto,
  ) {
    return this.historyService.findAll(user.sub, query);
  }

  @Get('stats')
  stats(
    @CurrentUser() user: SupabaseJwtPayload,
    @Query() query: DateRangeQueryDto,
  ) {
    return this.historyService.stats(user.sub, query);
  }
}
