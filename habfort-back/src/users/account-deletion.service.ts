import { Injectable } from '@nestjs/common';
import { SupabaseAdminService } from '../auth/supabase-admin.service';
import { UserProvisioningService } from '../auth/user-provisioning.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

/**
 * Deletes everything a user has — required by App Store guideline 5.1.1(v).
 * Order matters for retries: photos first (nothing points at them once the
 * rows are gone), then all rows in one transaction, then the Supabase sign-in
 * account. A failure at any step leaves the next attempt able to finish.
 */
@Injectable()
export class AccountDeletionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly supabaseAdmin: SupabaseAdminService,
    private readonly userProvisioning: UserProvisioningService,
  ) {}

  async delete(userId: string): Promise<void> {
    const withPhotos = await this.prisma.redeem.findMany({
      where: { userId, photoPath: { not: null } },
      select: { photoPath: true },
    });
    await this.storageService.remove(
      withPhotos.flatMap((r) => (r.photoPath ? [r.photoPath] : [])),
    );

    // Children before parents: Habit -> User and the ledger/history/rewards
    // -> User relations have no cascade (logs cascade from habits).
    await this.prisma.$transaction([
      this.prisma.habit.deleteMany({ where: { userId } }),
      this.prisma.habitHistory.deleteMany({ where: { userId } }),
      this.prisma.redeem.deleteMany({ where: { userId } }),
      this.prisma.reward.deleteMany({ where: { userId } }),
      this.prisma.walletTransaction.deleteMany({ where: { userId } }),
      this.prisma.dailyBonusLog.deleteMany({ where: { userId } }),
      this.prisma.user.deleteMany({ where: { id: userId } }),
    ]);
    this.userProvisioning.forget(userId);

    await this.supabaseAdmin.deleteUser(userId);
  }
}
