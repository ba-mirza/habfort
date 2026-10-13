import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import {
  HabitDifficulty,
  RecurringScheduleType,
} from '../../../generated/prisma';

// Edits only ever affect the future: history snapshots and ledger entries
// already hold what past completions earned. Type and requiredDays are fixed
// at creation; which other fields a habit type accepts is checked in the
// service, since it depends on the stored habit.
export class UpdateHabitDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name?: string;

  @IsOptional()
  @IsEnum(HabitDifficulty)
  difficulty?: HabitDifficulty;

  @IsOptional()
  @IsEnum(RecurringScheduleType)
  scheduleType?: RecurringScheduleType;

  @IsOptional()
  @IsArray()
  @ArrayNotEmpty()
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(0, { each: true })
  @Max(6, { each: true })
  scheduleDays?: number[];
}
