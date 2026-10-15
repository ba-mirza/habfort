import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import type { SupabaseJwtPayload } from '../auth/jwt-payload.type';
import { UserProvisioningService } from '../auth/user-provisioning.service';
import { AccountDeletionService } from './account-deletion.service';
import { UpdateMeDto } from './dto/update-me.dto';
import { OnboardingService } from './onboarding.service';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('me')
@ApiBearerAuth()
@UseGuards(SupabaseAuthGuard)
@Controller('me')
export class UsersController {
  constructor(
    private readonly userProvisioning: UserProvisioningService,
    private readonly onboardingService: OnboardingService,
    private readonly accountDeletion: AccountDeletionService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getCurrentUser(@CurrentUser() jwtUser: SupabaseJwtPayload) {
    return this.userProvisioning.sync(jwtUser);
  }

  @Patch()
  updateCurrentUser(
    @CurrentUser() jwtUser: SupabaseJwtPayload,
    @Body() dto: UpdateMeDto,
  ) {
    return this.prisma.user.update({
      where: { id: jwtUser.sub },
      data: { country: dto.country },
    });
  }

  @Post('onboarding')
  completeOnboarding(@CurrentUser() jwtUser: SupabaseJwtPayload) {
    return this.onboardingService.complete(jwtUser.sub);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteAccount(@CurrentUser() jwtUser: SupabaseJwtPayload) {
    return this.accountDeletion.delete(jwtUser.sub);
  }
}
