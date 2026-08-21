import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { EconomyController } from './economy.controller';

@Module({
  imports: [AuthModule],
  controllers: [EconomyController],
})
export class EconomyModule {}
