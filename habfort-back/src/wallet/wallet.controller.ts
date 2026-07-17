import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { ListTransactionsQueryDto } from './dto/list-transactions-query.dto';
import { WalletService } from './wallet.service';

@UseGuards(SupabaseAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('balance')
  async getBalance(@CurrentUser() user: SupabaseJwtPayload) {
    const balance = await this.walletService.getBalance(user.sub);
    return { balance };
  }

  @Get('transactions')
  getTransactions(
    @CurrentUser() user: SupabaseJwtPayload,
    @Query() query: ListTransactionsQueryDto,
  ) {
    return this.walletService.listTransactions(
      user.sub,
      query.take,
      query.skip,
    );
  }
}
