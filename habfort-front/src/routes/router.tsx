import { createBrowserRouter } from 'react-router-dom';
import { AppShell } from '../components/layout/app-shell';
import { LoginPage } from '../features/auth/login-page';
import { SignupPage } from '../features/auth/signup-page';
import { HomePage } from '../features/home/home-page';
import { ProtectedRoute, PublicOnlyRoute } from './route-guards';

export const router = createBrowserRouter([
  {
    element: <AppShell />,
    children: [
      {
        element: <PublicOnlyRoute />,
        children: [
          { path: '/login', element: <LoginPage /> },
          { path: '/signup', element: <SignupPage /> },
        ],
      },
      {
        element: <ProtectedRoute />,
        children: [{ path: '/', element: <HomePage /> }],
      },
    ],
  },
]);
