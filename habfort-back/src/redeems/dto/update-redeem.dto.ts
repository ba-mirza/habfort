import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateRedeemDto {
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  /** Must be the path a prior photo-upload call returned for this redeem. */
  @IsOptional()
  @IsString()
  @MaxLength(300)
  photoPath?: string;
}
