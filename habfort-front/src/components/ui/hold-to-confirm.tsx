import { useState, type KeyboardEvent, type ReactNode, type TransitionEvent } from 'react';

interface HoldToConfirmProps {
  onConfirm: () => void;
  /** Fill width while at rest (not being held) — 0 for "not done", 100 for "already done". */
  atRestPercent?: number;
  /** Fill width the hold animates toward; reaching it (uninterrupted) fires onConfirm. */
  holdTargetPercent?: number;
  holdDurationMs?: number;
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
export function HoldToConfirm({
  onConfirm,
  atRestPercent = 0,
  holdTargetPercent = 100,
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
    // Still holding when the fill reaches its target = an uninterrupted hold.
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
        data-testid="hold-fill"
        className={`absolute inset-y-0 left-0 ${fillClassName}`}
        style={{
          width: `${isHolding ? holdTargetPercent : atRestPercent}%`,
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
