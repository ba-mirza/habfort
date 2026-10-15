import { Module } from '@nestjs/common';
import { SupabaseAdminService } from './supabase-admin.service';
import { SupabaseAuthGuard } from './supabase-auth.guard';
import { UserProvisioningService } from './user-provisioning.service';

@Module({
  providers: [SupabaseAuthGuard, UserProvisioningService, SupabaseAdminService],
  exports: [SupabaseAuthGuard, UserProvisioningService, SupabaseAdminService],
})
export class AuthModule {}
