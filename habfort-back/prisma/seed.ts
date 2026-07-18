import { HabitDifficulty, HabitType, PrismaClient, RecurringScheduleType } from '../generated/prisma';

const prisma = new PrismaClient();

// Override with your own Supabase user id (SEED_USER_ID=<uuid> npx prisma db seed)
// to get sample data you can immediately exercise through the API with a real JWT.
const SEED_USER_ID = process.env.SEED_USER_ID ?? '00000000-0000-0000-0000-000000000000';
const SEED_USER_EMAIL = process.env.SEED_USER_EMAIL ?? 'demo@habits.local';

async function main() {
  const user = await prisma.user.upsert({
    where: { id: SEED_USER_ID },
    update: {},
    create: { id: SEED_USER_ID, email: SEED_USER_EMAIL },
  });

  await prisma.habit.createMany({
    data: [
      { userId: user.id, name: 'Drink a glass of water', type: HabitType.INSTANT, difficulty: HabitDifficulty.EASY },
      {
        userId: user.id,
        name: '30-day reading streak',
        type: HabitType.CONDITIONAL,
        difficulty: HabitDifficulty.MEDIUM,
        requiredDays: 30,
      },
      {
        userId: user.id,
        name: 'Morning stretch',
        type: HabitType.RECURRING,
        difficulty: HabitDifficulty.EASY,
        scheduleType: RecurringScheduleType.DAILY,
      },
      {
        userId: user.id,
        name: 'Gym session',
        type: HabitType.RECURRING,
        difficulty: HabitDifficulty.HARD,
        scheduleType: RecurringScheduleType.DAYS_OF_WEEK,
        scheduleDays: [1, 3, 5],
      },
    ],
  });

  await prisma.reward.createMany({
    data: [
      { userId: user.id, name: 'Movie night', costCoins: 100 },
      { userId: user.id, name: 'New book', costCoins: 250 },
    ],
  });

  console.log(`Seeded demo data for user ${user.id} (${user.email})`);
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
