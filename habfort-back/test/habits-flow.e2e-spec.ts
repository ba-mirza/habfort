import { randomUUID } from 'crypto';
import {
  ExecutionContext,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { SupabaseAuthGuard } from '../src/auth/supabase-auth.guard';
import { AllExceptionsFilter } from '../src/common/all-exceptions.filter';
import { PrismaService } from '../src/prisma/prisma.service';

// Bypasses real Supabase JWT verification with a fixed test user, so this
// suite runs offline against the local Docker Postgres — no network calls to
// Supabase Auth. Requires `docker compose up -d` in habfort-back first.
describe('Habits full flow (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const userId = randomUUID();
  const email = `e2e-${userId}@test.local`;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideGuard(SupabaseAuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          const req = context.switchToHttp().getRequest();
          req.user = {
            sub: userId,
            email,
            aud: 'authenticated',
            exp: Math.floor(Date.now() / 1000) + 3600,
          };
          return true;
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    await app.init();

    prisma = moduleFixture.get(PrismaService);
  });

  afterAll(async () => {
    // Deletion order respects FK constraints (Habit -> User has no cascade).
    await prisma.habit.deleteMany({ where: { userId } });
    await prisma.habitHistory.deleteMany({ where: { userId } });
    await prisma.redeem.deleteMany({ where: { userId } });
    await prisma.reward.deleteMany({ where: { userId } });
    await prisma.walletTransaction.deleteMany({ where: { userId } });
    await prisma.dailyBonusLog.deleteMany({ where: { userId } });
    await prisma.user.deleteMany({ where: { id: userId } });
    await app.close();
  });

  it('creates the user row via JIT upsert on GET /me', async () => {
    const res = await request(app.getHttpServer()).get('/me').expect(200);
    expect(res.body.id).toBe(userId);
  });

  it('completes an instant habit: ledger, history, and balance all agree', async () => {
    const created = await request(app.getHttpServer())
      .post('/habits')
      .send({ name: 'Drink water', type: 'INSTANT', difficulty: 'EASY' })
      .expect(201);
    const habitId: string = created.body.id;

    const completed = await request(app.getHttpServer())
      .post(`/habits/${habitId}/complete`)
      .expect(201);
    expect(completed.body).toMatchObject({
      status: 'COMPLETED',
      coinsAwarded: 5,
      habitId: null,
    });

    await request(app.getHttpServer()).get(`/habits/${habitId}`).expect(404);

    const balance = await request(app.getHttpServer())
      .get('/wallet/balance')
      .expect(200);
    expect(balance.body.balance).toBe(5);
  });

  it('tops up the balance, creates a reward, and redeems it', async () => {
    for (let i = 0; i < 5; i++) {
      const created = await request(app.getHttpServer())
        .post('/habits')
        .send({ name: `Topup ${i}`, type: 'INSTANT', difficulty: 'HARD' })
        .expect(201);
      await request(app.getHttpServer())
        .post(`/habits/${created.body.id}/complete`)
        .expect(201);
    }
    // 5 (from the previous test) + 5 * 20 = 105
    const balanceAfterTopup = await request(app.getHttpServer())
      .get('/wallet/balance')
      .expect(200);
    expect(balanceAfterTopup.body.balance).toBe(105);

    const rejectedReward = await request(app.getHttpServer())
      .post('/rewards')
      .send({ name: 'Too cheap', costCoins: 50 })
      .expect(400);
    expect(rejectedReward.body.message).toMatch(/at least/i);

    const reward = await request(app.getHttpServer())
      .post('/rewards')
      .send({ name: 'Movie night', costCoins: 100 })
      .expect(201);

    const redeemed = await request(app.getHttpServer())
      .post('/redeems')
      .send({ rewardId: reward.body.id })
      .expect(201);
    expect(redeemed.body).toMatchObject({
      rewardId: reward.body.id,
      amountSpent: 100,
    });

    const balanceAfterRedeem = await request(app.getHttpServer())
      .get('/wallet/balance')
      .expect(200);
    expect(balanceAfterRedeem.body.balance).toBe(5);

    const redeems = await request(app.getHttpServer())
      .get('/redeems')
      .expect(200);
    expect(redeems.body).toHaveLength(1);
  });

  it('history stats match everything the ledger recorded', async () => {
    const stats = await request(app.getHttpServer())
      .get('/history/stats')
      .expect(200);
    expect(stats.body.totalEntries).toBe(6); // 1 easy + 5 hard completions
    expect(stats.body.totalCoinsAwarded).toBe(105); // 5 + 5*20
    const completed = stats.body.byStatus.find(
      (row: { status: string }) => row.status === 'COMPLETED',
    );
    expect(completed).toMatchObject({ count: 6, coinsAwarded: 105 });
  });
});
