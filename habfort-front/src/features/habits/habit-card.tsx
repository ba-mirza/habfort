import { Trash2 } from 'lucide-react';
import { HoldToConfirm } from '../../components/ui/hold-to-confirm';
import type { Habit } from './use-habits';
import { useCompleteHabit, useDeleteHabit, useLogHabitDay } from './use-habits';

const DIFFICULTY_LABEL: Record<Habit['difficulty'], string> = {
  EASY: 'Easy',
  MEDIUM: 'Medium',
  HARD: 'Hard',
};

const WEEKDAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function isScheduledToday(habit: Habit): boolean {
  if (habit.type !== 'RECURRING' || habit.scheduleType !== 'DAYS_OF_WEEK') {
    return true;
  }
  return habit.scheduleDays.includes(new Date().getUTCDay());
}

function DeleteButton({ habitId, habitName }: { habitId: string; habitName: string }) {
  const deleteHabit = useDeleteHabit();
  return (
    <HoldToConfirm
      onConfirm={() => deleteHabit.mutate(habitId)}
      disabled={deleteHabit.isPending}
      fillClassName="bg-red-500/25"
      ariaLabel={`Hold to delete ${habitName}`}
      className="flex size-8 items-center justify-center rounded-full text-gray-400"
    >
      <Trash2 className="size-4" aria-hidden />
    </HoldToConfirm>
  );
}

function CardHeader({ habit }: { habit: Habit }) {
  return (
    <div className="flex items-center justify-between gap-2 pr-6">
      <h3 className="font-medium">{habit.name}</h3>
      <span className="shrink-0 rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-600 dark:bg-gray-800 dark:text-gray-300">
        {DIFFICULTY_LABEL[habit.difficulty]}
      </span>
    </div>
  );
}

// Status is communicated with text, never a persistent card color — a
// half-finished conditional streak (e.g. 1/3) isn't a warning, and "done
// today" isn't an error state either.
function CardStatus({ habit }: { habit: Habit }) {
  if (habit.type === 'CONDITIONAL' && habit.requiredDays !== null) {
    return (
      <p className="mt-1 text-sm text-gray-500">
        {habit.currentStreak ?? 0}/{habit.requiredDays} days
      </p>
    );
  }
  if (habit.type === 'RECURRING') {
    const schedule = habit.scheduleType === 'DAILY' ? 'Every day' : habit.scheduleDays.map((d) => WEEKDAY_LABELS[d]).join(', ');
    const notes = [
      habit.isCompletedToday && 'Done today',
      !isScheduledToday(habit) && 'Not scheduled today',
    ].filter(Boolean);
    return (
      <p className="mt-1 text-sm text-gray-500">
        {schedule}
        {notes.length > 0 ? ` · ${notes.join(' · ')}` : ''}
      </p>
    );
  }
  return null;
}

function InstantHabitCard({ habit }: { habit: Habit }) {
  const completeHabit = useCompleteHabit();

  return (
    <li className="relative rounded-2xl border border-gray-200 dark:border-gray-800">
      <HoldToConfirm
        onConfirm={() => completeHabit.mutate(habit.id)}
        disabled={completeHabit.isPending}
        fillClassName="bg-green-500/25"
        ariaLabel={`Hold to complete ${habit.name}`}
        className="rounded-2xl p-4"
      >
        <CardHeader habit={habit} />
      </HoldToConfirm>
      <div className="absolute right-2 top-2">
        <DeleteButton habitId={habit.id} habitName={habit.name} />
      </div>
    </li>
  );
}

function ToggleableHabitCard({ habit }: { habit: Habit }) {
  const logDay = useLogHabitDay();
  const isDone = habit.isCompletedToday ?? false;
  const disabled = logDay.isPending || !isScheduledToday(habit);

  return (
    <li className="relative rounded-2xl border border-gray-200 dark:border-gray-800">
      <HoldToConfirm
        onConfirm={() => logDay.mutate({ habitId: habit.id, completed: !isDone })}
        disabled={disabled}
        fillClassName={isDone ? 'bg-gray-400/25' : 'bg-green-500/25'}
        ariaLabel={isDone ? `Hold to undo ${habit.name}` : `Hold to mark ${habit.name} done today`}
        className="rounded-2xl p-4"
      >
        <CardHeader habit={habit} />
        <CardStatus habit={habit} />
      </HoldToConfirm>
      <div className="absolute right-2 top-2">
        <DeleteButton habitId={habit.id} habitName={habit.name} />
      </div>
    </li>
  );
}

export function HabitCard({ habit }: { habit: Habit }) {
  if (habit.type === 'INSTANT') {
    return <InstantHabitCard habit={habit} />;
  }
  return <ToggleableHabitCard habit={habit} />;
}
