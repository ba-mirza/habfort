import { Coins, Settings } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useBalance } from '../../features/wallet/use-balance';
import { useAuthStore } from '../../stores/auth.store';

function initialsFromEmail(email: string | null | undefined): string {
  return email ? email[0]!.toUpperCase() : '?';
}

export function TopBar() {
  const { data, isLoading } = useBalance();
  const email = useAuthStore((state) => state.session?.user.email);

  return (
    <header className="flex items-center justify-between border-b border-gray-200 px-4 py-3 dark:border-gray-800">
      <div className="flex items-center gap-1.5 font-semibold">
        <Coins className="size-5 text-amber-500" aria-hidden />
        <span>{isLoading ? '—' : data?.balance}</span>
      </div>
      <div className="flex items-center gap-2">
        <div
          className="flex size-8 items-center justify-center rounded-full bg-gray-200 text-sm font-medium dark:bg-gray-700"
          aria-hidden
        >
          {initialsFromEmail(email)}
        </div>
        <Link
          to="/settings"
          aria-label="Settings"
          className="flex size-9 items-center justify-center rounded-full border border-gray-200 dark:border-gray-800"
        >
          <Settings className="size-5" aria-hidden />
        </Link>
      </div>
    </header>
  );
}
