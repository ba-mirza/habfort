import { z } from 'zod';

export const HABIT_TYPES = ['INSTANT', 'CONDITIONAL', 'RECURRING'] as const;
export const HABIT_DIFFICULTIES = ['EASY', 'MEDIUM', 'HARD'] as const;
export const RECURRING_SCHEDULE_TYPES = ['DAILY', 'DAYS_OF_WEEK'] as const;

const baseSchema = z.object({
  name: z.string().min(1, 'Name is required').max(200),
  type: z.enum(HABIT_TYPES),
  difficulty: z.enum(HABIT_DIFFICULTIES),
  requiredDays: z.number().int().min(1).optional(),
  scheduleType: z.enum(RECURRING_SCHEDULE_TYPES).optional(),
  scheduleDays: z.array(z.number().int().min(0).max(6)).optional(),
});

// Mirrors the backend's HabitFieldsMatchTypeConstraint
// (habfort-back/src/habits/validators/habit-fields-match-type.validator.ts) —
// keep these in sync if that rule ever changes.
export const createHabitSchema = baseSchema.superRefine((data, ctx) => {
  if (data.type === 'CONDITIONAL') {
    if (data.requiredDays === undefined) {
      ctx.addIssue({ code: 'custom', message: 'Required for a conditional habit', path: ['requiredDays'] });
    }
    if (data.scheduleType !== undefined) {
      ctx.addIssue({ code: 'custom', message: 'Only allowed for recurring habits', path: ['scheduleType'] });
    }
    return;
  }

  if (data.type === 'RECURRING') {
    if (data.requiredDays !== undefined) {
      ctx.addIssue({ code: 'custom', message: 'Only allowed for conditional habits', path: ['requiredDays'] });
    }
    if (data.scheduleType === undefined) {
      ctx.addIssue({ code: 'custom', message: 'Required for a recurring habit', path: ['scheduleType'] });
    } else if (data.scheduleType === 'DAYS_OF_WEEK' && (!data.scheduleDays || data.scheduleDays.length === 0)) {
      ctx.addIssue({ code: 'custom', message: 'Pick at least one day of the week', path: ['scheduleDays'] });
    }
    return;
  }

  // INSTANT
  if (data.requiredDays !== undefined) {
    ctx.addIssue({ code: 'custom', message: 'Only allowed for conditional habits', path: ['requiredDays'] });
  }
  if (data.scheduleType !== undefined) {
    ctx.addIssue({ code: 'custom', message: 'Only allowed for recurring habits', path: ['scheduleType'] });
  }
});

export type CreateHabitFormValues = z.infer<typeof baseSchema>;

// The backend rejects irrelevant-for-this-type fields outright (whitelist +
// forbidNonWhitelisted, plus @ArrayNotEmpty on scheduleDays — an empty array
// is not the same as omitting the key). Build a payload that only includes
// what this type actually uses, rather than sending the raw form values.
export function toCreateHabitPayload(values: CreateHabitFormValues) {
  return {
    name: values.name,
    type: values.type,
    difficulty: values.difficulty,
    ...(values.type === 'CONDITIONAL' ? { requiredDays: values.requiredDays } : {}),
    ...(values.type === 'RECURRING' ? { scheduleType: values.scheduleType } : {}),
    ...(values.type === 'RECURRING' && values.scheduleType === 'DAYS_OF_WEEK' ? { scheduleDays: values.scheduleDays } : {}),
  };
}
