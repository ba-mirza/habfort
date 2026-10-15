import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { StorageModule } from '../storage/storage.module';
import { WalletModule } from '../wallet/wallet.module';
import { AccountDeletionService } from './account-deletion.service';
import { OnboardingService } from './onboarding.service';
import { UsersController } from './users.controller';

@Module({
  imports: [AuthModule, WalletModule, StorageModule],
  controllers: [UsersController],
  providers: [OnboardingService, AccountDeletionService],
})
export class UsersModule {}
