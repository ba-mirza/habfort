import { registerAs } from '@nestjs/config';

export default registerAs('habits', () => ({
  difficultyCoins: {
    easy: 5,
    medium: 10,
    hard: 20,
  },
  fullDayBonus: {
    weekday: 15,
    weekend: 25,
  },
  // 0 = Sunday .. 6 = Saturday
  weekendDays: [0, 6],
}));
