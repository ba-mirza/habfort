import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { CreateHabitDto } from './dto/create-habit.dto';
import { LogHabitDayDto } from './dto/log-habit-day.dto';
import { UpdateHabitDto } from './dto/update-habit.dto';
import { HabitsService } from './habits.service';

@UseGuards(SupabaseAuthGuard)
@Controller('habits')
export class HabitsController {
  constructor(private readonly habitsService: HabitsService) {}

  @Post()
  create(@CurrentUser() user: SupabaseJwtPayload, @Body() dto: CreateHabitDto) {
    return this.habitsService.create(user.sub, dto);
  }

  @Get()
  findAll(@CurrentUser() user: SupabaseJwtPayload) {
    return this.habitsService.findAll(user.sub);
  }

  @Get(':id')
  findOne(@CurrentUser() user: SupabaseJwtPayload, @Param('id') id: string) {
    return this.habitsService.findOne(user.sub, id);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: SupabaseJwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateHabitDto,
  ) {
    return this.habitsService.update(user.sub, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@CurrentUser() user: SupabaseJwtPayload, @Param('id') id: string) {
    return this.habitsService.remove(user.sub, id);
  }

  @Post(':id/complete')
  complete(@CurrentUser() user: SupabaseJwtPayload, @Param('id') id: string) {
    return this.habitsService.completeHabit(user.sub, id);
  }

  @Post(':id/log')
  log(
    @CurrentUser() user: SupabaseJwtPayload,
    @Param('id') id: string,
    @Body() dto: LogHabitDayDto,
  ) {
    return this.habitsService.logHabitDay(
      user.sub,
      id,
      dto.date,
      dto.completed,
    );
  }
}
