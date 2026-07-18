import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('./supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn(),
    },
  },
}));

import { supabase } from './supabase';
import { api } from './api';

const mockGetSession = vi.mocked(supabase.auth.getSession);

describe('api', () => {
  beforeEach(() => {
    mockGetSession.mockResolvedValue({
      data: { session: { access_token: 'test-token' } as never },
      error: null,
    });
    vi.stubGlobal('fetch', vi.fn());
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('attaches the Bearer token from the current session', async () => {
    vi.mocked(fetch).mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), { status: 200, headers: { 'Content-Type': 'application/json' } }),
    );

    await api.get('/me');

    const [, init] = vi.mocked(fetch).mock.calls[0];
    expect((init?.headers as Headers).get('Authorization')).toBe('Bearer test-token');
  });

  it('throws ApiError with the backend message on a non-2xx response', async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ statusCode: 400, message: 'Bad input' }), { status: 400 }));

    await expect(api.get('/habits')).rejects.toMatchObject({ status: 400, message: 'Bad input' });
  });

  it('joins array-valued validation messages', async () => {
    vi.mocked(fetch).mockResolvedValue(
      new Response(
        JSON.stringify({ statusCode: 400, message: ['name should not be empty', 'type must be a valid enum value'] }),
        { status: 400 },
      ),
    );

    await expect(api.post('/habits', {})).rejects.toMatchObject({
      message: 'name should not be empty, type must be a valid enum value',
    });
  });

  it('returns undefined for a 204 response without parsing a body', async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(null, { status: 204 }));

    const result = await api.delete('/habits/some-id');
    expect(result).toBeUndefined();
  });
});
