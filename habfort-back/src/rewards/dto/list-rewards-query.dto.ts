import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';

export class ListRewardsQueryDto {
  // Query strings arrive as "true"/"false", which @IsBoolean would reject.
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  archived: boolean = false;
}
