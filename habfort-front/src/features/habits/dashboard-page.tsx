import { Plus } from 'lucide-react';
import { useState } from 'react';
import { Dialog } from '../../components/ui/dialog';
import { CreateHabitForm } from './create-habit-form';
import { toCreateHabitPayload } from './create-habit-schema';
import { HabitListWidget } from './habit-list-widget';
import { useCreateHabit } from './use-habits';

export function DashboardPage() {
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const createHabit = useCreateHabit();

  return (
    <div>
      <div className="flex items-center justify-between px-4 pt-4">
        <h1 className="text-xl font-semibold">Habits</h1>
        <button
          type="button"
          onClick={() => setIsCreateOpen(true)}
          aria-label="Create habit"
          className="flex size-10 items-center justify-center rounded-full bg-black text-white dark:bg-white dark:text-black"
        >
          <Plus className="size-5" aria-hidden />
        </button>
      </div>

      <HabitListWidget />

      <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen} title="New habit">
        <CreateHabitForm
          isSubmitting={createHabit.isPending}
          onSubmit={(values) => {
            createHabit.mutate(toCreateHabitPayload(values), {
              onSuccess: () => setIsCreateOpen(false),
            });
          }}
        />
        {createHabit.isError && <p className="mt-2 text-sm text-red-600">{createHabit.error.message}</p>}
      </Dialog>
    </div>
  );
}
