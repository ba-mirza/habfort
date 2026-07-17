export interface SupabaseJwtPayload {
  sub: string;
  email?: string;
  aud: string;
  exp: number;
  [key: string]: unknown;
}
