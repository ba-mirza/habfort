import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { CreateHabitForm } from './create-habit-form';

describe('CreateHabitForm', () => {
  it('submits an INSTANT habit with just name/type/difficulty', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<CreateHabitForm onSubmit={onSubmit} isSubmitting={false} />);

    await user.type(screen.getByLabelText(/name/i), 'Drink water');
    await user.click(screen.getByRole('button', { name: /create habit/i }));

    expect(onSubmit.mock.calls[0]?.[0]).toEqual(expect.objectContaining({ name: 'Drink water', type: 'INSTANT', difficulty: 'EASY' }));
  });

  it('reveals the required-days field for a conditional habit', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<CreateHabitForm onSubmit={onSubmit} isSubmitting={false} />);

    await user.type(screen.getByLabelText(/name/i), 'Streak');
    await user.click(screen.getByRole('button', { name: /streak challenge/i }));
    await user.type(screen.getByLabelText(/required days/i), '30');
    await user.click(screen.getByRole('button', { name: /create habit/i }));

    expect(onSubmit.mock.calls[0]?.[0]).toEqual(expect.objectContaining({ name: 'Streak', type: 'CONDITIONAL', requiredDays: 30 }));
  });

  it('requires at least one weekday for a recurring days-of-week habit', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<CreateHabitForm onSubmit={onSubmit} isSubmitting={false} />);

    await user.type(screen.getByLabelText(/name/i), 'Gym');
    await user.click(screen.getByRole('button', { name: 'Recurring' }));
    await user.click(screen.getByRole('button', { name: /specific days/i }));
    await user.click(screen.getByRole('button', { name: /create habit/i }));

    expect(onSubmit).not.toHaveBeenCalled();
    expect(await screen.findByText(/pick at least one day/i)).toBeInTheDocument();
  });
});
