import { Injectable } from '@nestjs/common';
import { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  upsertFromJwt(payload: SupabaseJwtPayload) {
    return this.prisma.user.upsert({
      where: { id: payload.sub },
      update: { email: payload.email },
      create: { id: payload.sub, email: payload.email },
    });
  }
}
