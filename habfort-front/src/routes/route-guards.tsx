import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../stores/auth.store';

export function ProtectedRoute() {
  const { session, isLoading } = useAuthStore();
  if (isLoading) {
    return null;
  }
  if (!session) {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}

export function PublicOnlyRoute() {
  const { session, isLoading } = useAuthStore();
  if (isLoading) {
    return null;
  }
  if (session) {
    return <Navigate to="/" replace />;
  }
  return <Outlet />;
}
