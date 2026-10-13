import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import { runInTimeZone } from '../habits/date.util';

export const TIME_ZONE_HEADER = 'x-timezone';

/**
 * Runs each request in the caller's IANA time zone (`X-Timezone`), so "today"
 * and every calendar day the services derive are the user's, not UTC's.
 * A missing or unknown zone falls back to UTC.
 */
@Injectable()
export class TimeZoneMiddleware implements NestMiddleware {
  use(req: Request, _res: Response, next: NextFunction) {
    const header = req.headers[TIME_ZONE_HEADER];
    const zone = typeof header === 'string' ? header : undefined;
    runInTimeZone(zone && isValidTimeZone(zone) ? zone : 'UTC', next);
  }
}

function isValidTimeZone(zone: string): boolean {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: zone });
    return true;
  } catch {
    return false;
  }
}
