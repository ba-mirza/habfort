import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/** Supabase Auth admin calls, made with the service-role key. */
@Injectable()
export class SupabaseAdminService {
  constructor(private readonly configService: ConfigService) {}

  async deleteUser(userId: string): Promise<void> {
    const key = this.configService.get<string>('supabase.serviceRoleKey');
    if (!key) {
      throw new ServiceUnavailableException(
        'Account deletion is not configured',
      );
    }
    const base = this.configService.getOrThrow<string>('supabase.url');
    const response = await fetch(`${base}/auth/v1/admin/users/${userId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${key}`, apikey: key },
    });
    // 404: already gone (e.g. a retried deletion) — that's the goal anyway.
    if (!response.ok && response.status !== 404) {
      throw new ServiceUnavailableException(
        `Could not delete the sign-in account (${response.status})`,
      );
    }
  }
}
