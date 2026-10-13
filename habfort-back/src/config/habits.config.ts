import { registerAs } from '@nestjs/config';

export default registerAs('habits', () => ({
  difficultyCoins: {
    easy: 5,
    medium: 10,
    hard: 20,
  },
  // One-time grant at the end of onboarding. Deliberately below the minimum
  // reward price (rewards.minCostCoins): the first reward should take a few
  // days of habits, not be redeemable on day zero.
  welcomeBonus: 60,
  fullDayBonus: {
    weekday: 15,
    weekend: 25,
  },
  // 0 = Sunday .. 6 = Saturday
  weekendDays: [0, 6],
}));
