import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import appConfig from './config/app.config';
import { validate } from './config/env.validation';
import habitsConfig from './config/habits.config';
import rewardsConfig from './config/rewards.config';
import supabaseConfig from './config/supabase.config';
import { HabitsModule } from './habits/habits.module';
import { HistoryModule } from './history/history.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedeemsModule } from './redeems/redeems.module';
import { RewardsModule } from './rewards/rewards.module';
import { UsersModule } from './users/users.module';
import { WalletModule } from './wallet/wallet.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      validate,
      load: [appConfig, supabaseConfig, habitsConfig, rewardsConfig],
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    WalletModule,
    HabitsModule,
    RewardsModule,
    RedeemsModule,
    HistoryModule,
  ],
})
export class AppModule {}
