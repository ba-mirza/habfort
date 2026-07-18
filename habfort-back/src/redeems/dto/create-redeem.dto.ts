import { IsNotEmpty, IsString } from 'class-validator';

export class CreateRedeemDto {
  @IsString()
  @IsNotEmpty()
  rewardId!: string;
}
