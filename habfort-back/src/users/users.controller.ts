import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { UserProvisioningService } from '../auth/user-provisioning.service';

@ApiTags('me')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('me')
export class UsersController {
  constructor(private readonly userProvisioning: UserProvisioningService) {}

  @Get()
  getCurrentUser(@CurrentUser() jwtUser: SupabaseJwtPayload) {
    return this.userProvisioning.sync(jwtUser);
  }
}
