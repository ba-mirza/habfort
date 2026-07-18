import { supabase } from '../../lib/supabase';

// What else lives here is undecided — for now this is just the logout action's home.
export function SettingsPage() {
  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold">Settings</h1>
      <p className="mt-2 text-sm text-gray-500">More settings coming soon.</p>
      <button
        onClick={() => void supabase.auth.signOut()}
        className="mt-6 rounded border border-gray-300 px-3 py-1.5 text-sm dark:border-gray-600"
      >
        Log out
      </button>
    </div>
  );
}
