import { plainToInstance } from 'class-transformer';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  validateSync,
} from 'class-validator';

class EnvironmentVariables {
  @IsString()
  @IsNotEmpty()
  DATABASE_URL!: string;

  @IsUrl({ require_tld: false })
  SUPABASE_URL!: string;

  @IsString()
  @IsNotEmpty()
  SUPABASE_JWT_AUDIENCE!: string;

  // Optional so the API still boots without it; only the reward-photo
  // endpoints need it, and they answer 503 until it's set.
  @IsOptional()
  @IsString()
  SUPABASE_SERVICE_ROLE_KEY?: string;

  @IsNumber()
  PORT!: number;
}

export function validate(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`Config validation error: ${errors.toString()}`);
  }

  return validatedConfig;
}
