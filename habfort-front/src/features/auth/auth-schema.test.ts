import { describe, expect, it } from 'vitest';
import { authSchema } from './auth-schema';

describe('authSchema', () => {
  it('accepts a valid email and a 6+ char password', () => {
    const result = authSchema.safeParse({ email: 'user@example.com', password: 'secret1' });
    expect(result.success).toBe(true);
  });

  it('rejects an invalid email', () => {
    const result = authSchema.safeParse({ email: 'not-an-email', password: 'secret1' });
    expect(result.success).toBe(false);
  });

  it('rejects a password shorter than 6 characters', () => {
    const result = authSchema.safeParse({ email: 'user@example.com', password: '123' });
    expect(result.success).toBe(false);
  });
});
