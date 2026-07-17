import { Controller, Get, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { UsersService } from './users.service';

@UseGuards(SupabaseAuthGuard)
@Controller('me')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  getCurrentUser(@CurrentUser() jwtUser: SupabaseJwtPayload) {
    return this.usersService.upsertFromJwt(jwtUser);
  }
}
