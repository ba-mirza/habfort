import { Module } from '@nestjs/common';
import { SupabaseAuthGuard } from './supabase-auth.guard';
import { UserProvisioningService } from './user-provisioning.service';

@Module({
  providers: [SupabaseAuthGuard, UserProvisioningService],
  exports: [SupabaseAuthGuard, UserProvisioningService],
})
export class AuthModule {}
