import { Injectable } from '@nestjs/common';
import { User } from '../../generated/prisma';
import { PrismaService } from '../prisma/prisma.service';
import { generatePublicId } from '../users/public-id';
import { SupabaseJwtPayload } from './jwt-payload.type';

// Supabase Auth and our database are separate stores: an account can be signed
// up in Supabase (or created by hand in its dashboard) and still have no row
// here, in which case every insert referencing userId fails on the foreign key.
// So the row is created on the first authenticated request rather than relying
// on any particular client call.
const REFRESH_INTERVAL_MS = 60 * 60 * 1000;

@Injectable()
export class UserProvisioningService {
  // Keeps the guard from writing on every single request: one upsert per user
  // per hour per instance is enough to create missing rows and pick up an
  // email change.
  private readonly lastSyncedAt = new Map<string, number>();

  constructor(private readonly prisma: PrismaService) {}

  async ensure(payload: SupabaseJwtPayload): Promise<void> {
    const syncedAt = this.lastSyncedAt.get(payload.sub);
    if (syncedAt !== undefined && Date.now() - syncedAt < REFRESH_INTERVAL_MS) {
      return;
    }
    await this.sync(payload);
  }

  async sync(payload: SupabaseJwtPayload): Promise<User> {
    const user = await this.prisma.user.upsert({
      where: { id: payload.sub },
      update: { email: payload.email },
      create: {
        id: payload.sub,
        email: payload.email,
        publicId: generatePublicId(),
      },
    });
    this.lastSyncedAt.set(payload.sub, Date.now());
    return user;
  }

  /** Drops the sync cache after the account is deleted, so a still-valid
   *  token can't skip re-creating (or rather, finding) the row. */
  forget(userId: string): void {
    this.lastSyncedAt.delete(userId);
  }
}
