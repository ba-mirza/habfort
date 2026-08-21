import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { Request } from 'express';

// Rate limits per user rather than per IP: testers can share an IP (office
// wifi, mobile carrier NAT), and one of them refreshing hard shouldn't lock
// out the rest.
//
// The subject is read straight out of the JWT payload without verifying the
// signature — this guard runs before the auth guard, and a forged token would
// only let someone spend their own quota under a different key. Verification
// still happens in SupabaseAuthGuard before any data is touched.
@Injectable()
export class UserThrottlerGuard extends ThrottlerGuard {
  // Bursty e2e runs would otherwise trip the per-second limit and fail for
  // reasons that have nothing to do with what they assert.
  protected shouldSkip(): Promise<boolean> {
    return Promise.resolve(process.env.NODE_ENV === 'test');
  }

  protected getTracker(req: Request): Promise<string> {
    const subject = this.subjectFromAuthHeader(req.headers.authorization);
    return Promise.resolve(subject ?? req.ip ?? 'unknown');
  }

  private subjectFromAuthHeader(header?: string): string | undefined {
    const token = header?.startsWith('Bearer ') ? header.slice(7) : undefined;
    const payload = token?.split('.')[1];
    if (!payload) {
      return undefined;
    }
    try {
      const decoded: unknown = JSON.parse(
        Buffer.from(payload, 'base64url').toString('utf8'),
      );
      const sub = (decoded as { sub?: unknown }).sub;
      return typeof sub === 'string' ? sub : undefined;
    } catch {
      return undefined;
    }
  }
}
