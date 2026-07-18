import type { Habit } from './use-habits';
import { useHabits } from './use-habits';

const DIFFICULTY_LABEL: Record<Habit['difficulty'], string> = {
  EASY: 'Easy',
  MEDIUM: 'Medium',
  HARD: 'Hard',
};

const WEEKDAY_LABELS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

function HabitCard({ habit }: { habit: Habit }) {
  return (
    <li className="rounded-2xl border border-gray-200 p-4 dark:border-gray-800">
      <div className="flex items-center justify-between">
        <h3 className="font-medium">{habit.name}</h3>
        <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-600 dark:bg-gray-800 dark:text-gray-300">
          {DIFFICULTY_LABEL[habit.difficulty]}
        </span>
      </div>
      {habit.type === 'CONDITIONAL' && habit.requiredDays !== null && (
        <p className="mt-1 text-sm text-gray-500">
          {habit.currentStreak ?? 0}/{habit.requiredDays} days
        </p>
      )}
      {habit.type === 'RECURRING' && (
        <p className="mt-1 text-sm text-gray-500">
          {habit.scheduleType === 'DAILY' ? 'Every day' : habit.scheduleDays.map((d) => WEEKDAY_LABELS[d]).join(', ')}
        </p>
      )}
    </li>
  );
}

export function HabitListWidget() {
  const { data, isLoading, error } = useHabits();

  if (isLoading) {
    return <p className="p-4 text-sm text-gray-500">Loading…</p>;
  }
  if (error) {
    return <p className="p-4 text-sm text-red-600">{error.message}</p>;
  }
  if (!data || data.length === 0) {
    return <p className="p-4 text-sm text-gray-500">No habits yet.</p>;
  }

  return (
    <ul className="flex flex-col gap-3 p-4">
      {data.map((habit) => (
        <HabitCard key={habit.id} habit={habit} />
      ))}
    </ul>
  );
}
