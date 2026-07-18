import { zodResolver } from '@hookform/resolvers/zod';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { authSchema, type AuthFormValues } from './auth-schema';

export function SignupPage() {
  const navigate = useNavigate();
  const [serverError, setServerError] = useState<string | null>(null);
  const [confirmationSent, setConfirmationSent] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<AuthFormValues>({ resolver: zodResolver(authSchema) });

  const onSubmit = async (values: AuthFormValues) => {
    setServerError(null);
    const { data, error } = await supabase.auth.signUp(values);
    if (error) {
      setServerError(error.message);
      return;
    }
    if (data.session) {
      void navigate('/', { replace: true });
      return;
    }
    setConfirmationSent(true);
  };

  if (confirmationSent) {
    return (
      <div className="flex min-h-svh flex-col justify-center gap-4 p-6 text-center">
        <h1 className="text-2xl font-semibold">Check your email</h1>
        <p>We sent a confirmation link — log in once you&apos;ve confirmed your address.</p>
        <Link to="/login" className="underline">
          Back to log in
        </Link>
      </div>
    );
  }

  return (
    <div className="flex min-h-svh flex-col justify-center gap-4 p-6">
      <h1 className="text-2xl font-semibold">Sign up</h1>
      <form onSubmit={(e) => void handleSubmit(onSubmit)(e)} className="flex flex-col gap-3">
        <div>
          <label className="block text-sm font-medium" htmlFor="email">
            Email
          </label>
          <input
            id="email"
            type="email"
            autoComplete="email"
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-800"
            {...register('email')}
          />
          {errors.email && <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>}
        </div>
        <div>
          <label className="block text-sm font-medium" htmlFor="password">
            Password
          </label>
          <input
            id="password"
            type="password"
            autoComplete="new-password"
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 dark:border-gray-600 dark:bg-gray-800"
            {...register('password')}
          />
          {errors.password && <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>}
        </div>
        {serverError && <p className="text-sm text-red-600">{serverError}</p>}
        <button
          type="submit"
          disabled={isSubmitting}
          className="rounded bg-black px-4 py-2 text-white disabled:opacity-50 dark:bg-white dark:text-black"
        >
          {isSubmitting ? 'Signing up…' : 'Sign up'}
        </button>
      </form>
      <p className="text-sm">
        Already have an account?{' '}
        <Link to="/login" className="underline">
          Log in
        </Link>
      </p>
    </div>
  );
}
