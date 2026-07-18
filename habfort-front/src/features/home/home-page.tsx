import { useQuery } from '@tanstack/react-query';
import { api } from '../../lib/api';
import { supabase } from '../../lib/supabase';

interface Me {
  id: string;
  email: string | null;
  createdAt: string;
}

// Temporary Phase 1 placeholder proving the auth + API round trip end to
// end — Phase 2 replaces this route's element with the real habits dashboard.
export function HomePage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['me'],
    queryFn: () => api.get<Me>('/me'),
  });

  return (
    <div className="p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Habits</h1>
        <button
          onClick={() => void supabase.auth.signOut()}
          className="rounded border border-gray-300 px-3 py-1.5 text-sm dark:border-gray-600"
        >
          Log out
        </button>
      </div>
      {isLoading && <p className="mt-4">Loading…</p>}
      {error && <p className="mt-4 text-red-600">{error.message}</p>}
      {data && <p className="mt-4">Signed in as {data.email}</p>}
    </div>
  );
}
