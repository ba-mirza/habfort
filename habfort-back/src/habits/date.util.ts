import { AsyncLocalStorage } from 'async_hooks';

// Calendar days are handled as UTC-midnight `Date`s throughout (a "date" with
// no time). Which day it currently is — and which day a timestamp falls on —
// depends on the user's time zone, set per request by TimeZoneMiddleware.
const MS_PER_DAY = 24 * 60 * 60 * 1000;

const timeZoneStorage = new AsyncLocalStorage<string>();

export function runInTimeZone<T>(timeZone: string, fn: () => T): T {
  return timeZoneStorage.run(timeZone, fn);
}

export function currentTimeZone(): string {
  return timeZoneStorage.getStore() ?? 'UTC';
}

/** The user's current calendar day. */
export function today(): Date {
  return localDate(new Date());
}

/** The user's calendar day a moment in time falls on. */
export function localDate(moment: Date): Date {
  // en-CA formats as YYYY-MM-DD.
  const key = new Intl.DateTimeFormat('en-CA', {
    timeZone: currentTimeZone(),
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(moment);
  return normalizeDate(key);
}

/** A calendar date ("2026-10-13", or a date-only Date) as UTC midnight. */
export function normalizeDate(input: string | Date): Date {
  const d = typeof input === 'string' ? new Date(input) : input;
  return new Date(
    Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()),
  );
}

export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setUTCDate(result.getUTCDate() + days);
  return result;
}

export function diffDays(from: Date, to: Date): number {
  return Math.round((to.getTime() - from.getTime()) / MS_PER_DAY);
}

export function toDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}
