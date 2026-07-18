import { createClient } from '@supabase/supabase-js';

// Auth only — the app never talks to Supabase Postgres directly from the
// frontend; all data goes through the NestJS API with this client's token.
export const supabase = createClient(import.meta.env.VITE_SUPABASE_URL, import.meta.env.VITE_SUPABASE_ANON_KEY);
