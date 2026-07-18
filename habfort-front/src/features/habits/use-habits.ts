import { useQuery } from '@tanstack/react-query';
import { api } from '../../lib/api';

export type HabitType = 'INSTANT' | 'CONDITIONAL' | 'RECURRING';
export type HabitDifficulty = 'EASY' | 'MEDIUM' | 'HARD';
export type RecurringScheduleType = 'DAILY' | 'DAYS_OF_WEEK';

export interface Habit {
  id: string;
  userId: string;
  name: string;
  type: HabitType;
  difficulty: HabitDifficulty;
  requiredDays: number | null;
  scheduleType: RecurringScheduleType | null;
  scheduleDays: number[];
  status: 'ACTIVE';
  createdAt: string;
  // CONDITIONAL only — computed at read time by the backend, not persisted.
  currentStreak?: number;
}

export function useHabits() {
  return useQuery({
    queryKey: ['habits'],
    queryFn: () => api.get<Habit[]>('/habits'),
  });
}
