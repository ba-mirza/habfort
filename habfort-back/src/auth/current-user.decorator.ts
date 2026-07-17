import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Request } from 'express';
import { SupabaseJwtPayload } from './jwt-payload.type';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): SupabaseJwtPayload => {
    const request = ctx.switchToHttp().getRequest<Request>();
    return request.user!;
  },
);
