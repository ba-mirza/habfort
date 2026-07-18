import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RewardsModule } from '../rewards/rewards.module';
import { WalletModule } from '../wallet/wallet.module';
import { RedeemsController } from './redeems.controller';
import { RedeemsService } from './redeems.service';

@Module({
  imports: [AuthModule, WalletModule, RewardsModule],
  controllers: [RedeemsController],
  providers: [RedeemsService],
})
export class RedeemsModule {}
