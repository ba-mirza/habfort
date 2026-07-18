import { Outlet } from 'react-router-dom';

// Mobile-only app: no desktop layout exists, so this constrains every route
// to a fixed mobile-width column and centers it, even on a wide viewport.
export function AppShell() {
  return (
    <div className="mx-auto min-h-svh w-full max-w-[480px] bg-white dark:bg-gray-950 dark:text-gray-100">
      <Outlet />
    </div>
  );
}
