import { HabitListWidget } from './habit-list-widget';

export function DashboardPage() {
  return (
    <div>
      <h1 className="px-4 pt-4 text-xl font-semibold">Habits</h1>
      <HabitListWidget />
    </div>
  );
}
