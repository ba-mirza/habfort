import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '../../generated/prisma';

const CONNECT_MAX_ATTEMPTS = 5;
const CONNECT_RETRY_DELAY_MS = 1500;

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  // The Supabase pooler connection from this environment is intermittently
  // slow/flaky at the initial handshake — retry a few times before giving up
  // rather than crashing the whole app on a transient connect failure.
  async onModuleInit() {
    for (let attempt = 1; attempt <= CONNECT_MAX_ATTEMPTS; attempt++) {
      try {
        await this.$connect();
        return;
      } catch (error) {
        if (attempt === CONNECT_MAX_ATTEMPTS) {
          throw error;
        }
        this.logger.warn(
          `DB connect attempt ${attempt}/${CONNECT_MAX_ATTEMPTS} failed, retrying...`,
        );
        await new Promise((resolve) =>
          setTimeout(resolve, CONNECT_RETRY_DELAY_MS),
        );
      }
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
