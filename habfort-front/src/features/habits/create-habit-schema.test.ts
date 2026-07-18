import { describe, expect, it } from 'vitest';
import { createHabitSchema, toCreateHabitPayload } from './create-habit-schema';

describe('createHabitSchema', () => {
  it('accepts a valid INSTANT habit', () => {
    expect(createHabitSchema.safeParse({ name: 'Drink water', type: 'INSTANT', difficulty: 'EASY' }).success).toBe(true);
  });

  it('accepts a valid CONDITIONAL habit', () => {
    expect(
      createHabitSchema.safeParse({ name: 'Streak', type: 'CONDITIONAL', difficulty: 'MEDIUM', requiredDays: 30 }).success,
    ).toBe(true);
  });

  it('accepts a valid RECURRING DAILY habit', () => {
    expect(
      createHabitSchema.safeParse({ name: 'Run', type: 'RECURRING', difficulty: 'HARD', scheduleType: 'DAILY' }).success,
    ).toBe(true);
  });

  it('accepts a valid RECURRING DAYS_OF_WEEK habit', () => {
    expect(
      createHabitSchema.safeParse({
        name: 'Gym',
        type: 'RECURRING',
        difficulty: 'MEDIUM',
        scheduleType: 'DAYS_OF_WEEK',
        scheduleDays: [1, 3, 5],
      }).success,
    ).toBe(true);
  });

  it('rejects CONDITIONAL without requiredDays', () => {
    expect(createHabitSchema.safeParse({ name: 'Streak', type: 'CONDITIONAL', difficulty: 'MEDIUM' }).success).toBe(false);
  });

  it('rejects INSTANT with requiredDays present', () => {
    expect(
      createHabitSchema.safeParse({ name: 'Bad', type: 'INSTANT', difficulty: 'EASY', requiredDays: 10 }).success,
    ).toBe(false);
  });

  it('rejects RECURRING without scheduleType', () => {
    expect(createHabitSchema.safeParse({ name: 'Bad', type: 'RECURRING', difficulty: 'EASY' }).success).toBe(false);
  });

  it('rejects RECURRING + DAYS_OF_WEEK without scheduleDays', () => {
    expect(
      createHabitSchema.safeParse({ name: 'Bad', type: 'RECURRING', difficulty: 'EASY', scheduleType: 'DAYS_OF_WEEK' })
        .success,
    ).toBe(false);
  });
});

describe('toCreateHabitPayload', () => {
  it('strips scheduleType/scheduleDays for an INSTANT habit', () => {
    const payload = toCreateHabitPayload({
      name: 'Drink water',
      type: 'INSTANT',
      difficulty: 'EASY',
      scheduleDays: [],
    });
    expect(payload).toEqual({ name: 'Drink water', type: 'INSTANT', difficulty: 'EASY' });
  });

  it('keeps only requiredDays for a CONDITIONAL habit', () => {
    const payload = toCreateHabitPayload({
      name: 'Streak',
      type: 'CONDITIONAL',
      difficulty: 'MEDIUM',
      requiredDays: 30,
      scheduleDays: [],
    });
    expect(payload).toEqual({ name: 'Streak', type: 'CONDITIONAL', difficulty: 'MEDIUM', requiredDays: 30 });
  });

  it('omits scheduleDays for a RECURRING DAILY habit', () => {
    const payload = toCreateHabitPayload({
      name: 'Run',
      type: 'RECURRING',
      difficulty: 'HARD',
      scheduleType: 'DAILY',
      scheduleDays: [],
    });
    expect(payload).toEqual({ name: 'Run', type: 'RECURRING', difficulty: 'HARD', scheduleType: 'DAILY' });
  });

  it('keeps scheduleDays for a RECURRING DAYS_OF_WEEK habit', () => {
    const payload = toCreateHabitPayload({
      name: 'Gym',
      type: 'RECURRING',
      difficulty: 'MEDIUM',
      scheduleType: 'DAYS_OF_WEEK',
      scheduleDays: [1, 3, 5],
    });
    expect(payload).toEqual({
      name: 'Gym',
      type: 'RECURRING',
      difficulty: 'MEDIUM',
      scheduleType: 'DAYS_OF_WEEK',
      scheduleDays: [1, 3, 5],
    });
  });
});
