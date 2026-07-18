import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

// Explicit rather than relying on RTL's auto-detection, so DOM — and mock
// call history — from one test never leaks into the next.
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});
