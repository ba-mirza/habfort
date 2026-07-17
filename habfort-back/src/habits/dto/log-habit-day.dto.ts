import { IsBoolean, IsISO8601, IsOptional } from 'class-validator';

export class LogHabitDayDto {
  @IsOptional()
  @IsISO8601({ strict: true })
  date?: string;

  @IsBoolean()
  completed!: boolean;
}
