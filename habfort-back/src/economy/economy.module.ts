import { Module } from '@nestjs/common';
import { EconomyController } from './economy.controller';

@Module({
  controllers: [EconomyController],
})
export class EconomyModule {}
