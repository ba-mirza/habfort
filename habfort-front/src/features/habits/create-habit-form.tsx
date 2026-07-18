import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import {
  createHabitSchema,
  HABIT_DIFFICULTIES,
  HABIT_TYPES,
  RECURRING_SCHEDULE_TYPES,
  type CreateHabitFormValues,
} from './create-habit-schema';

const TYPE_LABEL: Record<(typeof HABIT_TYPES)[number], string> = {
  INSTANT: 'One-off',
  CONDITIONAL: 'Streak challenge',
  RECURRING: 'Recurring',
};

const DIFFICULTY_LABEL: Record<(typeof HABIT_DIFFICULTIES)[number], string> = {
  EASY: 'Easy',
  MEDIUM: 'Medium',
  HARD: 'Hard',
};

const WEEKDAY_LABELS = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

function pillClass(active: boolean): string {
  return `rounded-full px-3 py-1.5 text-sm ${
    active ? 'bg-black text-white dark:bg-white dark:text-black' : 'border border-gray-300 dark:border-gray-600'
  }`;
}

interface CreateHabitFormProps {
  onSubmit: (values: CreateHabitFormValues) => void;
  isSubmitting: boolean;
}

export function CreateHabitForm({ onSubmit, isSubmitting }: CreateHabitFormProps) {
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<CreateHabitFormValues>({
    resolver: zodResolver(createHabitSchema),
    defaultValues: { type: 'INSTANT', difficulty: 'EASY', scheduleDays: [] },
  });

  const type = watch('type');
  const scheduleType = watch('scheduleType');
  const difficulty = watch('difficulty');
  const scheduleDays = watch('scheduleDays') ?? [];

  // Switching type invalidates whatever the other type's fields held.
  useEffect(() => {
    setValue('requiredDays', undefined);
    setValue('scheduleType', undefined);
    setValue('scheduleDays', []);
  }, [type, setValue]);

  function toggleDay(day: number) {
    const next = scheduleDays.includes(day) ? scheduleDays.filter((d) => d !== day) : [...scheduleDays, day];
    setValue('scheduleDays', next, { shouldValidate: true });
  }

  return (
    <form onSubmit={(e) => void handleSubmit(onSubmit)(e)} className="flex flex-col gap-4">
      <div>
        <label className="block text-sm font-medium" htmlFor="name">
          Name
        </label>
        <input
          id="name"
          className="mt-1 w-full rounded border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-800"
          {...register('name')}
        />
        {errors.name && <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>}
      </div>

      <fieldset>
        <legend className="text-sm font-medium">Type</legend>
        <div className="mt-1 flex gap-2">
          {HABIT_TYPES.map((t) => (
            <button key={t} type="button" onClick={() => setValue('type', t, { shouldValidate: true })} className={pillClass(type === t)}>
              {TYPE_LABEL[t]}
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset>
        <legend className="text-sm font-medium">Difficulty</legend>
        <div className="mt-1 flex gap-2">
          {HABIT_DIFFICULTIES.map((d) => (
            <button
              key={d}
              type="button"
              onClick={() => setValue('difficulty', d, { shouldValidate: true })}
              className={pillClass(difficulty === d)}
            >
              {DIFFICULTY_LABEL[d]}
            </button>
          ))}
        </div>
      </fieldset>

      {type === 'CONDITIONAL' && (
        <div>
          <label className="block text-sm font-medium" htmlFor="requiredDays">
            Required days
          </label>
          <input
            id="requiredDays"
            type="number"
            min={1}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-800"
            {...register('requiredDays', { valueAsNumber: true })}
          />
          {errors.requiredDays && <p className="mt-1 text-sm text-red-600">{errors.requiredDays.message}</p>}
        </div>
      )}

      {type === 'RECURRING' && (
        <>
          <fieldset>
            <legend className="text-sm font-medium">Schedule</legend>
            <div className="mt-1 flex gap-2">
              {RECURRING_SCHEDULE_TYPES.map((s) => (
                <button
                  key={s}
                  type="button"
                  onClick={() => setValue('scheduleType', s, { shouldValidate: true })}
                  className={pillClass(scheduleType === s)}
                >
                  {s === 'DAILY' ? 'Every day' : 'Specific days'}
                </button>
              ))}
            </div>
            {errors.scheduleType && <p className="mt-1 text-sm text-red-600">{errors.scheduleType.message}</p>}
          </fieldset>

          {scheduleType === 'DAYS_OF_WEEK' && (
            <fieldset>
              <legend className="text-sm font-medium">Days</legend>
              <div className="mt-1 flex gap-1.5">
                {WEEKDAY_LABELS.map((label, day) => (
                  <button
                    key={day}
                    type="button"
                    onClick={() => toggleDay(day)}
                    aria-pressed={scheduleDays.includes(day)}
                    className={`flex size-8 items-center justify-center rounded-full text-sm ${
                      scheduleDays.includes(day)
                        ? 'bg-black text-white dark:bg-white dark:text-black'
                        : 'border border-gray-300 dark:border-gray-600'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
              {errors.scheduleDays && <p className="mt-1 text-sm text-red-600">{errors.scheduleDays.message}</p>}
            </fieldset>
          )}
        </>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="mt-2 rounded bg-black px-4 py-2 text-white disabled:opacity-50 dark:bg-white dark:text-black"
      >
        {isSubmitting ? 'Creating…' : 'Create habit'}
      </button>
    </form>
  );
}
