import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { WalletModule } from '../wallet/wallet.module';
import { OnboardingService } from './onboarding.service';
import { UsersController } from './users.controller';

@Module({
  imports: [AuthModule, WalletModule],
  controllers: [UsersController],
  providers: [OnboardingService],
})
export class UsersModule {}
