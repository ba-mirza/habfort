// Calendar days are handled as UTC midnight `Date`s throughout — there is no
// per-user timezone support in the MVP, so "today" means the current UTC date.
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export function today(): Date {
  return normalizeDate(new Date());
}

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
