import { registerAs } from '@nestjs/config';

export type AchievementMetric =
  | 'completions'
  | 'bestStreak'
  | 'redeems'
  | 'challengesCompleted'
  | 'fullDays'
  | 'coinsEarned';

export default registerAs('progress', () => ({
  // Level n starts at levelBaseXp * n(n-1)/2 cumulative XP: 0, 100, 300,
  // 600, 1000… — each level takes 100 XP more than the one before.
  levelBaseXp: 100,
  // Ids only — titles and icons live in the client. Each unlocks once its
  // metric reaches `target`.
  achievements: [
    { id: 'first_step', metric: 'completions', target: 1 },
    { id: 'week_streak', metric: 'bestStreak', target: 7 },
    { id: 'month_streak', metric: 'bestStreak', target: 30 },
    { id: 'hundred', metric: 'completions', target: 100 },
    { id: 'first_reward', metric: 'redeems', target: 1 },
    { id: 'challenger', metric: 'challengesCompleted', target: 1 },
    { id: 'perfect_day', metric: 'fullDays', target: 1 },
    { id: 'piggy_bank', metric: 'coinsEarned', target: 1000 },
  ] satisfies { id: string; metric: AchievementMetric; target: number }[],
}));
