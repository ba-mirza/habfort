import { IsInt, IsNotEmpty, IsString, Min, MaxLength } from 'class-validator';

export class CreateRewardDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;

  // The 100-coin floor itself is enforced in RewardsService against config,
  // not here — @Min(1) just rejects nonsensical/negative input early.
  @IsInt()
  @Min(1)
  costCoins!: number;
}
