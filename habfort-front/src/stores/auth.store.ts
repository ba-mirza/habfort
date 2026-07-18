import type { Session } from '@supabase/supabase-js';
import { create } from 'zustand';
import { supabase } from '../lib/supabase';

interface AuthState {
  session: Session | null;
  isLoading: boolean;
}

export const useAuthStore = create<AuthState>(() => ({
  session: null,
  isLoading: true,
}));

void supabase.auth.getSession().then(({ data: { session } }) => {
  useAuthStore.setState({ session, isLoading: false });
});

supabase.auth.onAuthStateChange((_event, session) => {
  useAuthStore.setState({ session, isLoading: false });
});
