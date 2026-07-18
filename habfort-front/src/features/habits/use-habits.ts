import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
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
  // CONDITIONAL/RECURRING only — computed at read time, not persisted.
  isCompletedToday?: boolean;
}

export function useHabits() {
  return useQuery({
    queryKey: ['habits'],
    queryFn: () => api.get<Habit[]>('/habits'),
  });
}

export interface CreateHabitPayload {
  name: string;
  type: HabitType;
  difficulty: HabitDifficulty;
  requiredDays?: number;
  scheduleType?: RecurringScheduleType;
  scheduleDays?: number[];
}

export function useCreateHabit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateHabitPayload) => api.post<Habit>('/habits', payload),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['habits'] });
    },
  });
}

function invalidateHabitsAndBalance(queryClient: ReturnType<typeof useQueryClient>) {
  void queryClient.invalidateQueries({ queryKey: ['habits'] });
  void queryClient.invalidateQueries({ queryKey: ['wallet', 'balance'] });
}

export function useCompleteHabit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (habitId: string) => api.post(`/habits/${habitId}/complete`),
    onSuccess: () => invalidateHabitsAndBalance(queryClient),
  });
}

export interface LogHabitDayPayload {
  habitId: string;
  completed: boolean;
}

export function useLogHabitDay() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ habitId, completed }: LogHabitDayPayload) => api.post(`/habits/${habitId}/log`, { completed }),
    onSuccess: () => invalidateHabitsAndBalance(queryClient),
  });
}
