import { useState, type KeyboardEvent, type ReactNode, type TransitionEvent } from 'react';

interface HoldToConfirmProps {
  onConfirm: () => void;
  holdDurationMs?: number;
  /** Color of the transient fill while holding — the card itself never carries a status color at rest. */
  fillClassName?: string;
  disabled?: boolean;
  className?: string;
  ariaLabel: string;
  children: ReactNode;
}

const DEFAULT_HOLD_MS = 900;
const RELEASE_MS = 150;

// Hold-to-confirm, not tap-to-confirm: releasing early cancels with no
// effect, so this replaces a separate "are you sure?" dialog for actions
// that credit/debit the wallet — the deliberate hold duration is the guard.
// The fill is purely transient hold-in-progress feedback: it always rests at
// 0% (no persistent status color on the card), regardless of what holding
// this control would do.
export function HoldToConfirm({
  onConfirm,
  holdDurationMs = DEFAULT_HOLD_MS,
  fillClassName = 'bg-green-500/30',
  disabled,
  className = '',
  ariaLabel,
  children,
}: HoldToConfirmProps) {
  const [isHolding, setIsHolding] = useState(false);

  function start() {
    if (!disabled) {
      setIsHolding(true);
    }
  }

  function cancel() {
    setIsHolding(false);
  }

  function handleTransitionEnd(e: TransitionEvent<HTMLDivElement>) {
    if (e.propertyName !== 'width') {
      return;
    }
    // Still holding when the fill reaches 100% = an uninterrupted hold.
    if (isHolding) {
      setIsHolding(false);
      onConfirm();
    }
  }

  function handleKeyDown(e: KeyboardEvent<HTMLDivElement>) {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      start();
    }
  }

  function handleKeyUp(e: KeyboardEvent<HTMLDivElement>) {
    if (e.key === 'Enter' || e.key === ' ') {
      cancel();
    }
  }

  return (
    <div
      role="button"
      tabIndex={disabled ? -1 : 0}
      aria-disabled={disabled}
      aria-label={ariaLabel}
      className={`relative touch-none select-none overflow-hidden ${className}`}
      onPointerDown={start}
      onPointerUp={cancel}
      onPointerLeave={cancel}
      onPointerCancel={cancel}
      onKeyDown={handleKeyDown}
      onKeyUp={handleKeyUp}
    >
      <div
        className={`absolute inset-y-0 left-0 ${fillClassName}`}
        style={{
          width: `${isHolding ? 100 : 0}%`,
          transitionProperty: 'width',
          transitionDuration: `${isHolding ? holdDurationMs : RELEASE_MS}ms`,
          transitionTimingFunction: isHolding ? 'linear' : 'ease-out',
        }}
        onTransitionEnd={handleTransitionEnd}
        aria-hidden
      />
      <div className="relative">{children}</div>
    </div>
  );
}
