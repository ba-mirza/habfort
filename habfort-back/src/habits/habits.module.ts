import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { WalletModule } from '../wallet/wallet.module';
import { BonusService } from './bonus.service';
import { HabitsController } from './habits.controller';
import { HabitsService } from './habits.service';

@Module({
  imports: [AuthModule, WalletModule],
  controllers: [HabitsController],
  providers: [HabitsService, BonusService],
})
export class HabitsModule {}
