import { registerAs } from '@nestjs/config';

export default registerAs('supabase', () => ({
  url: process.env.SUPABASE_URL,
  jwksUri: `${process.env.SUPABASE_URL}/auth/v1/.well-known/jwks.json`,
  jwtAudience: process.env.SUPABASE_JWT_AUDIENCE,
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  photoBucket: 'reward-photos',
  photoUrlTtlSeconds: 60 * 60,
}));
