import { IsOptional, Matches } from 'class-validator';

export class UpdateMeDto {
  /** ISO 3166-1 alpha-2 code, e.g. "KZ". */
  @IsOptional()
  @Matches(/^[A-Z]{2}$/, { message: 'country must be a two-letter ISO code' })
  country?: string;
}
