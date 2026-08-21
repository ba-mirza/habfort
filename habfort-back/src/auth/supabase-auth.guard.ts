import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import * as jwt from 'jsonwebtoken';
import { JwksClient } from 'jwks-rsa';
import { SupabaseJwtPayload } from './jwt-payload.type';
import { UserProvisioningService } from './user-provisioning.service';

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  private readonly jwksClient: JwksClient;
  private readonly audience: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly userProvisioning: UserProvisioningService,
  ) {
    this.jwksClient = new JwksClient({
      jwksUri: this.configService.getOrThrow<string>('supabase.jwksUri'),
      cache: true,
      rateLimit: true,
    });
    this.audience = this.configService.getOrThrow<string>(
      'supabase.jwtAudience',
    );
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractToken(request);
    if (!token) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const payload = await this.verify(token);
    // Creates the local row if this account has never been seen here before,
    // so downstream inserts can rely on the user existing.
    await this.userProvisioning.ensure(payload);

    request.user = payload;
    return true;
  }

  private extractToken(request: Request): string | undefined {
    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      return undefined;
    }
    return header.slice('Bearer '.length);
  }

  private verify(token: string): Promise<SupabaseJwtPayload> {
    return new Promise((resolve, reject) => {
      jwt.verify(
        token,
        (header, callback) => {
          if (!header.kid) {
            callback(new Error('Missing kid in token header'));
            return;
          }
          this.jwksClient.getSigningKey(header.kid, (err, key) => {
            if (err || !key) {
              callback(err ?? new Error('Signing key not found'));
              return;
            }
            callback(null, key.getPublicKey());
          });
        },
        { audience: this.audience, algorithms: ['RS256', 'ES256'] },
        (err, decoded) => {
          if (err || !decoded) {
            reject(new UnauthorizedException('Invalid token'));
            return;
          }
          resolve(decoded as SupabaseJwtPayload);
        },
      );
    });
  }
}
