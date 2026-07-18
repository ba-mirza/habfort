import { Outlet } from 'react-router-dom';
import { TabBar } from './tab-bar';
import { TopBar } from './top-bar';

export function AuthenticatedLayout() {
  return (
    <div className="flex min-h-svh flex-col">
      <TopBar />
      <main className="flex-1 overflow-y-auto pb-16">
        <Outlet />
      </main>
      <TabBar />
    </div>
  );
}
