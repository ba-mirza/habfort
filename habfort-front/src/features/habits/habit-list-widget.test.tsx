import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen } from '@testing-library/react';
import type { ReactElement } from 'react';
import { describe, expect, it, vi } from 'vitest';
import { api } from '../../lib/api';
import { HabitListWidget } from './habit-list-widget';
import type { Habit } from './use-habits';

vi.mock('../../lib/api', () => ({
  api: { get: vi.fn() },
}));

function renderWithClient(ui: ReactElement) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<QueryClientProvider client={client}>{ui}</QueryClientProvider>);
}

const habits: Habit[] = [
  {
    id: '1',
    userId: 'u',
    name: 'Drink water',
    type: 'INSTANT',
    difficulty: 'EASY',
    requiredDays: null,
    scheduleType: null,
    scheduleDays: [],
    status: 'ACTIVE',
    createdAt: new Date().toISOString(),
  },
  {
    id: '2',
    userId: 'u',
    name: '30-day streak',
    type: 'CONDITIONAL',
    difficulty: 'MEDIUM',
    requiredDays: 30,
    scheduleType: null,
    scheduleDays: [],
    status: 'ACTIVE',
    createdAt: new Date().toISOString(),
    currentStreak: 12,
  },
  {
    id: '3',
    userId: 'u',
    name: 'Gym',
    type: 'RECURRING',
    difficulty: 'HARD',
    requiredDays: null,
    scheduleType: 'DAYS_OF_WEEK',
    scheduleDays: [1, 3, 5],
    status: 'ACTIVE',
    createdAt: new Date().toISOString(),
  },
];

describe('HabitListWidget', () => {
  it('renders each habit type with its type-specific detail', async () => {
    vi.mocked(api.get).mockResolvedValue(habits);

    renderWithClient(<HabitListWidget />);

    expect(await screen.findByText('Drink water')).toBeInTheDocument();
    expect(screen.getByText('12/30 days')).toBeInTheDocument();
    expect(screen.getByText('Mon, Wed, Fri')).toBeInTheDocument();
  });

  it('shows an empty state when there are no habits', async () => {
    vi.mocked(api.get).mockResolvedValue([]);

    renderWithClient(<HabitListWidget />);

    expect(await screen.findByText(/no habits yet/i)).toBeInTheDocument();
  });
});
