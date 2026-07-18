import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import { HabitHistoryStatus, HabitType } from '../../../generated/prisma';
import { DateRangeQueryDto } from './date-range-query.dto';

export class ListHistoryQueryDto extends DateRangeQueryDto {
  @IsOptional()
  @IsEnum(HabitHistoryStatus)
  status?: HabitHistoryStatus;

  @IsOptional()
  @IsEnum(HabitType)
  type?: HabitType;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  take: number = 20;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  skip: number = 0;
}
