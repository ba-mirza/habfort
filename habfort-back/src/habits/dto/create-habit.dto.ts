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
  Validate,
} from 'class-validator';
import {
  HabitDifficulty,
  HabitType,
  RecurringScheduleType,
} from '../../../generated/prisma';
import { HabitFieldsMatchTypeConstraint } from '../validators/habit-fields-match-type.validator';

export class CreateHabitDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;

  @IsEnum(HabitType)
  @Validate(HabitFieldsMatchTypeConstraint)
  type!: HabitType;

  @IsEnum(HabitDifficulty)
  difficulty!: HabitDifficulty;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  requiredDays?: number;

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
