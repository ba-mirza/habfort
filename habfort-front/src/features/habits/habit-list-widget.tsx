import { useMemo, useState } from 'react';
import { HabitCard } from './habit-card';
import type { Habit, HabitDifficulty, HabitType } from './use-habits';
import { useHabits } from './use-habits';

const TYPE_FILTERS: { label: string; value: HabitType | 'ALL' }[] = [
  { label: 'All', value: 'ALL' },
  { label: 'One-off', value: 'INSTANT' },
  { label: 'Streaks', value: 'CONDITIONAL' },
  { label: 'Recurring', value: 'RECURRING' },
];

const DIFFICULTY_FILTERS: { label: string; value: HabitDifficulty | 'ALL' }[] = [
  { label: 'All', value: 'ALL' },
  { label: 'Easy', value: 'EASY' },
  { label: 'Medium', value: 'MEDIUM' },
  { label: 'Hard', value: 'HARD' },
];

function FilterRow<T extends string>({
  options,
  value,
  onChange,
}: {
  options: { label: string; value: T }[];
  value: T;
  onChange: (value: T) => void;
}) {
  return (
    <div className="flex gap-1.5 overflow-x-auto">
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          onClick={() => onChange(option.value)}
          className={`shrink-0 rounded-full px-3 py-1 text-xs ${
            value === option.value
              ? 'bg-black text-white dark:bg-white dark:text-black'
              : 'border border-gray-300 dark:border-gray-600'
          }`}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}

export function HabitListWidget() {
  const { data, isLoading, error } = useHabits();
  const [typeFilter, setTypeFilter] = useState<HabitType | 'ALL'>('ALL');
  const [difficultyFilter, setDifficultyFilter] = useState<HabitDifficulty | 'ALL'>('ALL');

  const filtered = useMemo(() => {
    return (data ?? []).filter(
      (habit: Habit) =>
        (typeFilter === 'ALL' || habit.type === typeFilter) && (difficultyFilter === 'ALL' || habit.difficulty === difficultyFilter),
    );
  }, [data, typeFilter, difficultyFilter]);

  if (isLoading) {
    return <p className="p-4 text-sm text-gray-500">Loading…</p>;
  }
  if (error) {
    return <p className="p-4 text-sm text-red-600">{error.message}</p>;
  }

  return (
    <div className="flex flex-col gap-3 p-4">
      {data && data.length > 0 && (
        <div className="flex flex-col gap-2">
          <FilterRow options={TYPE_FILTERS} value={typeFilter} onChange={setTypeFilter} />
          <FilterRow options={DIFFICULTY_FILTERS} value={difficultyFilter} onChange={setDifficultyFilter} />
        </div>
      )}
      {!data || data.length === 0 ? (
        <p className="text-sm text-gray-500">No habits yet.</p>
      ) : filtered.length === 0 ? (
        <p className="text-sm text-gray-500">No habits match these filters.</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {filtered.map((habit) => (
            <HabitCard key={habit.id} habit={habit} />
          ))}
        </ul>
      )}
    </div>
  );
}
