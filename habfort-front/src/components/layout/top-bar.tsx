import { Coins, Settings } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useBalance } from '../../features/wallet/use-balance';

export function TopBar() {
  const { data, isLoading } = useBalance();

  return (
    <header className="flex items-center justify-between border-b border-gray-200 px-4 py-3 dark:border-gray-800">
      <div className="flex items-center gap-1.5 font-semibold">
        <Coins className="size-5 text-amber-500" aria-hidden />
        <span>{isLoading ? '—' : data?.balance}</span>
      </div>
      <Link
        to="/settings"
        aria-label="Settings"
        className="flex size-9 items-center justify-center rounded-full border border-gray-200 dark:border-gray-800"
      >
        <Settings className="size-5" aria-hidden />
      </Link>
    </header>
  );
}
