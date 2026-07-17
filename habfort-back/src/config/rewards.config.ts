import { registerAs } from '@nestjs/config';

export default registerAs('rewards', () => ({
  minCostCoins: 100,
}));
