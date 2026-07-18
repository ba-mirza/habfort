import { fireEvent, render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { HoldToConfirm } from './hold-to-confirm';

describe('HoldToConfirm', () => {
  it('confirms when the hold completes uninterrupted', () => {
    const onConfirm = vi.fn();
    render(
      <HoldToConfirm onConfirm={onConfirm} ariaLabel="Hold to complete">
        Complete
      </HoldToConfirm>,
    );

    const control = screen.getByRole('button', { name: 'Hold to complete' });
    fireEvent.pointerDown(control);
    fireEvent.transitionEnd(screen.getByTestId('hold-fill'), { propertyName: 'width' });

    expect(onConfirm).toHaveBeenCalledOnce();
  });

  it('does not confirm when released before the hold completes', () => {
    const onConfirm = vi.fn();
    render(
      <HoldToConfirm onConfirm={onConfirm} ariaLabel="Hold to complete">
        Complete
      </HoldToConfirm>,
    );

    const control = screen.getByRole('button', { name: 'Hold to complete' });
    const fill = screen.getByTestId('hold-fill');

    fireEvent.pointerDown(control);
    fireEvent.pointerUp(control);
    // The release-back transition also fires transitionend — must not confirm.
    fireEvent.transitionEnd(fill, { propertyName: 'width' });

    expect(onConfirm).not.toHaveBeenCalled();
  });

  it('does not confirm when the pointer leaves before the hold completes', () => {
    const onConfirm = vi.fn();
    render(
      <HoldToConfirm onConfirm={onConfirm} ariaLabel="Hold to complete">
        Complete
      </HoldToConfirm>,
    );

    const control = screen.getByRole('button', { name: 'Hold to complete' });
    fireEvent.pointerDown(control);
    fireEvent.pointerLeave(control);
    fireEvent.transitionEnd(screen.getByTestId('hold-fill'), { propertyName: 'width' });

    expect(onConfirm).not.toHaveBeenCalled();
  });

  it('supports keyboard hold via Enter', () => {
    const onConfirm = vi.fn();
    render(
      <HoldToConfirm onConfirm={onConfirm} ariaLabel="Hold to complete">
        Complete
      </HoldToConfirm>,
    );

    const control = screen.getByRole('button', { name: 'Hold to complete' });
    fireEvent.keyDown(control, { key: 'Enter' });
    fireEvent.transitionEnd(screen.getByTestId('hold-fill'), { propertyName: 'width' });

    expect(onConfirm).toHaveBeenCalledOnce();
  });

  it('does not start a hold when disabled', () => {
    const onConfirm = vi.fn();
    render(
      <HoldToConfirm onConfirm={onConfirm} ariaLabel="Hold to complete" disabled>
        Complete
      </HoldToConfirm>,
    );

    const control = screen.getByRole('button', { name: 'Hold to complete' });
    fireEvent.pointerDown(control);
    fireEvent.transitionEnd(screen.getByTestId('hold-fill'), { propertyName: 'width' });

    expect(onConfirm).not.toHaveBeenCalled();
  });
});
