import { Gift, History as HistoryIcon, ListChecks } from 'lucide-react';
import { NavLink } from 'react-router-dom';

const tabs = [
  { to: '/', label: 'Habits', icon: ListChecks },
  { to: '/rewards', label: 'Rewards', icon: Gift },
  { to: '/history', label: 'History', icon: HistoryIcon },
];

export function TabBar() {
  return (
    <nav className="fixed inset-x-0 bottom-0 mx-auto flex w-full max-w-[480px] border-t border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-950">
      {tabs.map(({ to, label, icon: Icon }) => (
        <NavLink
          key={to}
          to={to}
          end={to === '/'}
          className={({ isActive }) =>
            `flex flex-1 flex-col items-center gap-1 py-2 text-xs ${isActive ? 'text-black dark:text-white' : 'text-gray-400'}`
          }
        >
          <Icon className="size-5" aria-hidden />
          {label}
        </NavLink>
      ))}
    </nav>
  );
}
