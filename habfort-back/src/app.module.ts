import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { UserThrottlerGuard } from './common/user-throttler.guard';
import appConfig from './config/app.config';
import { validate } from './config/env.validation';
import habitsConfig from './config/habits.config';
import rewardsConfig from './config/rewards.config';
import supabaseConfig from './config/supabase.config';
import { EconomyModule } from './economy/economy.module';
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
    // Two windows: the short one absorbs a stuck refresh loop, the long one
    // caps sustained hammering. Both sit far above normal use — opening a tab
    // costs a handful of requests. The message replaces the default
    // "ThrottlerException: Too Many Requests", which the iOS client would show
    // to the user verbatim.
    ThrottlerModule.forRoot({
      errorMessage: 'Too many requests, try again in a moment',
      throttlers: [
        { name: 'short', ttl: 1000, limit: 20 },
        { name: 'long', ttl: 60_000, limit: 200 },
      ],
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    WalletModule,
    HabitsModule,
    RewardsModule,
    RedeemsModule,
    HistoryModule,
    EconomyModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: UserThrottlerGuard }],
})
export class AppModule {}
