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
import { SupabaseAdminService } from '../src/auth/supabase-admin.service';
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
  // The test user only exists in our database, never in Supabase Auth.
  const supabaseAdmin = { deleteUser: jest.fn().mockResolvedValue(undefined) };

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
      .overrideProvider(SupabaseAdminService)
      .useValue(supabaseAdmin)
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
  it('records each recurring completion in history and keeps it after delete', async () => {
    const created = await request(app.getHttpServer())
      .post('/habits')
      .send({
        name: 'Run 1km',
        type: 'RECURRING',
        difficulty: 'MEDIUM',
        scheduleType: 'DAILY',
      })
      .expect(201);
    const habitId: string = created.body.id;
    const log = (completed: boolean) =>
      request(app.getHttpServer())
        .post(`/habits/${habitId}/log`)
        .send({ completed })
        .expect(201);
    const recurringHistory = async () => {
      const res = await request(app.getHttpServer())
        .get('/history?type=RECURRING')
        .expect(200);
      return res.body as { habitId: string | null; coinsAwarded: number }[];
    };

    await log(true);
    expect(await recurringHistory()).toMatchObject([
      { habitId, coinsAwarded: 10 },
    ]);

    await log(false);
    expect(await recurringHistory()).toHaveLength(0);

    await log(true);
    await request(app.getHttpServer()).delete(`/habits/${habitId}`).expect(204);
    expect(await recurringHistory()).toMatchObject([
      { habitId: null, coinsAwarded: 10 },
    ]);
  });
  it('edits a recurring habit for the future only and rejects locked fields', async () => {
    const created = await request(app.getHttpServer())
      .post('/habits')
      .send({
        name: 'Stretch',
        type: 'RECURRING',
        difficulty: 'EASY',
        scheduleType: 'DAILY',
      })
      .expect(201);
    const habitId: string = created.body.id;
    const balance = async () =>
      (await request(app.getHttpServer()).get('/wallet/balance').expect(200))
        .body.balance as number;

    const before = await balance();
    await request(app.getHttpServer())
      .post(`/habits/${habitId}/log`)
      .send({ completed: true })
      .expect(201);

    const edited = await request(app.getHttpServer())
      .patch(`/habits/${habitId}`)
      .send({
        name: 'Stretch 10 min',
        difficulty: 'HARD',
        scheduleType: 'DAYS_OF_WEEK',
        scheduleDays: [5, 1, 1],
      })
      .expect(200);
    expect(edited.body).toMatchObject({
      name: 'Stretch 10 min',
      difficulty: 'HARD',
      scheduleDays: [1, 5],
    });

    // Unchecking today reverses the 5 actually earned, not the new 20. The
    // edited schedule may exclude today, so restore DAILY before unchecking.
    await request(app.getHttpServer())
      .patch(`/habits/${habitId}`)
      .send({ scheduleType: 'DAILY' })
      .expect(200);
    const afterCredit = await balance();
    await request(app.getHttpServer())
      .post(`/habits/${habitId}/log`)
      .send({ completed: false })
      .expect(201);
    expect(afterCredit - (await balance())).toBe(5);
    expect(afterCredit).toBeGreaterThanOrEqual(before + 5);

    await request(app.getHttpServer())
      .post(`/habits/${habitId}/log`)
      .send({ completed: true, date: '2020-01-01' })
      .expect(400);

    const challenge = await request(app.getHttpServer())
      .post('/habits')
      .send({
        name: 'No sugar',
        type: 'CONDITIONAL',
        difficulty: 'EASY',
        requiredDays: 7,
      })
      .expect(201);
    await request(app.getHttpServer())
      .patch(`/habits/${challenge.body.id}`)
      .send({ difficulty: 'HARD' })
      .expect(400);
    await request(app.getHttpServer())
      .patch(`/habits/${challenge.body.id}`)
      .send({ scheduleType: 'DAILY' })
      .expect(400);
  });
  it('counts completions per day for the activity heatmap', async () => {
    const res = await request(app.getHttpServer())
      .get('/history/activity')
      .expect(200);
    const todayKey = new Date().toISOString().slice(0, 10);
    const history = await request(app.getHttpServer())
      .get('/history?take=100')
      .expect(200);
    // Everything in this suite happened today: 6 instant completions plus the
    // recurring day kept after its habit was deleted.
    expect(res.body.byDay).toEqual([
      { date: todayKey, count: history.body.length },
    ]);
    expect(res.body.total).toBe(history.body.length);
    expect(res.body.bestDay).toEqual({
      date: todayKey,
      count: history.body.length,
    });
  });
  it("buckets days in the caller's time zone, not UTC", async () => {
    // UTC+14 is already tomorrow from 10:00 UTC on, UTC-12 is still
    // yesterday until 12:00 UTC — so one of them always differs from UTC.
    const zone =
      new Date().getUTCHours() >= 10 ? 'Pacific/Kiritimati' : 'Etc/GMT+12';
    const zoneToday = new Intl.DateTimeFormat('en-CA', {
      timeZone: zone,
    }).format(new Date());
    const created = await request(app.getHttpServer())
      .post('/habits')
      .set('X-Timezone', zone)
      .send({
        name: 'Read',
        type: 'RECURRING',
        difficulty: 'EASY',
        scheduleType: 'DAILY',
      })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/habits/${created.body.id}/log`)
      .set('X-Timezone', zone)
      .send({ completed: true })
      .expect(201);

    const habits = await request(app.getHttpServer())
      .get('/habits')
      .set('X-Timezone', zone)
      .expect(200);
    expect(
      habits.body.find((h: { id: string }) => h.id === created.body.id),
    ).toMatchObject({ isCompletedToday: true });

    const activity = await request(app.getHttpServer())
      .get('/history/activity')
      .set('X-Timezone', zone)
      .expect(200);
    expect(activity.body.to).toBe(zoneToday);
    expect(
      activity.body.byDay.find((d: { date: string }) => d.date === zoneToday),
    ).toBeDefined();

    await request(app.getHttpServer())
      .delete(`/habits/${created.body.id}`)
      .expect(204);
  });
  it('keeps at most one goal reward and drops it on archive', async () => {
    const create = async (name: string) =>
      (
        await request(app.getHttpServer())
          .post('/rewards')
          .send({ name, costCoins: 150 })
          .expect(201)
      ).body.id as string;
    const first = await create('Concert');
    const second = await create('Sneakers');
    const goals = async () =>
      (await request(app.getHttpServer()).get('/rewards').expect(200)).body
        .filter((r: { isGoal: boolean }) => r.isGoal)
        .map((r: { id: string }) => r.id);

    await request(app.getHttpServer())
      .put(`/rewards/${first}/goal`)
      .expect(200);
    expect(await goals()).toEqual([first]);

    await request(app.getHttpServer())
      .put(`/rewards/${second}/goal`)
      .expect(200);
    expect(await goals()).toEqual([second]);

    await request(app.getHttpServer()).patch(`/rewards/${second}`).expect(200);
    expect(await goals()).toEqual([]);
    await request(app.getHttpServer())
      .put(`/rewards/${second}/goal`)
      .expect(400);
  });
  it('credits the welcome bonus exactly once when onboarding completes', async () => {
    const balance = async () =>
      (await request(app.getHttpServer()).get('/wallet/balance').expect(200))
        .body.balance as number;
    const me = await request(app.getHttpServer()).get('/me').expect(200);
    expect(me.body.onboardedAt).toBeNull();

    const before = await balance();
    const first = await request(app.getHttpServer())
      .post('/me/onboarding')
      .expect(201);
    expect(first.body.onboardedAt).not.toBeNull();
    await request(app.getHttpServer()).post('/me/onboarding').expect(201);
    expect((await balance()) - before).toBe(60);
  });
  it('saves a diary note on a redeem and rejects foreign photo paths', async () => {
    const redeems = await request(app.getHttpServer())
      .get('/redeems')
      .expect(200);
    const redeemId: string = redeems.body[0].id;

    const updated = await request(app.getHttpServer())
      .patch(`/redeems/${redeemId}`)
      .send({ note: '  Great movie  ' })
      .expect(200);
    expect(updated.body.note).toBe('Great movie');

    await request(app.getHttpServer())
      .patch(`/redeems/${redeemId}`)
      .send({ photoPath: 'someone-else/123/photo.jpg' })
      .expect(400);

    const cleared = await request(app.getHttpServer())
      .patch(`/redeems/${redeemId}`)
      .send({ note: '' })
      .expect(200);
    expect(cleared.body.note).toBeNull();
  });
  it('counts the day streak from days with at least one completion', async () => {
    const res = await request(app.getHttpServer())
      .get('/history/streak')
      .expect(200);
    // Everything in this suite happened today.
    expect(res.body).toEqual({ current: 1, best: 1, completedToday: true });
  });
  it('extends the streak across consecutive past days and stops at a gap', async () => {
    const daysAgo = (n: number) => new Date(Date.now() - n * 86_400_000);
    for (const n of [1, 2, 4]) {
      await prisma.habitHistory.create({
        data: {
          userId,
          habitName: `Past ${n}`,
          habitType: 'INSTANT',
          status: 'COMPLETED',
          coinsAwarded: 5,
          startedAt: daysAgo(n),
          endedAt: daysAgo(n),
        },
      });
    }
    const res = await request(app.getHttpServer())
      .get('/history/streak')
      .expect(200);
    // today, 1 and 2 days ago in a row; 3 days ago is the gap.
    expect(res.body).toEqual({ current: 3, best: 3, completedToday: true });
  });
  it('derives level and achievements from recorded activity', async () => {
    const res = await request(app.getHttpServer()).get('/progress').expect(200);
    const { xp, level, levelXp, levelSpan, metrics, achievements } = res.body;

    expect(xp).toBe(metrics.coinsEarned * 2);
    // Level n starts at 100 * n(n-1)/2 XP.
    const startOf = (n: number) => (100 * n * (n - 1)) / 2;
    expect(xp).toBeGreaterThanOrEqual(startOf(level));
    expect(xp).toBeLessThan(startOf(level + 1));
    expect(levelXp).toBe(xp - startOf(level));
    expect(levelSpan).toBe(100 * level);

    const byId = Object.fromEntries(
      achievements.map((a: { id: string; unlocked: boolean }) => [a.id, a]),
    );
    expect(byId.first_step.unlocked).toBe(true);
    expect(byId.first_reward.unlocked).toBe(true);
    expect(byId.month_streak).toMatchObject({ unlocked: false, target: 30 });
  });
  it('gives every user a short shareable public id', async () => {
    const me = await request(app.getHttpServer()).get('/me').expect(200);
    expect(me.body.publicId).toMatch(/^[A-HJ-NP-Za-km-z2-9]{10}$/);
  });
  // Keep last: it wipes the test user.
  it('deletes the account and every row that belonged to it', async () => {
    await request(app.getHttpServer()).delete('/me').expect(204);

    expect(supabaseAdmin.deleteUser).toHaveBeenCalledWith(userId);
    const remaining = await Promise.all([
      prisma.user.count({ where: { id: userId } }),
      prisma.habit.count({ where: { userId } }),
      prisma.habitHistory.count({ where: { userId } }),
      prisma.walletTransaction.count({ where: { userId } }),
      prisma.reward.count({ where: { userId } }),
      prisma.redeem.count({ where: { userId } }),
      prisma.dailyBonusLog.count({ where: { userId } }),
    ]);
    expect(remaining).toEqual([0, 0, 0, 0, 0, 0, 0]);
  });
});
