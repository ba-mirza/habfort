import { createBrowserRouter } from 'react-router-dom';
import { AppShell } from '../components/layout/app-shell';
import { AuthenticatedLayout } from '../components/layout/authenticated-layout';
import { LoginPage } from '../features/auth/login-page';
import { SignupPage } from '../features/auth/signup-page';
import { DashboardPage } from '../features/habits/dashboard-page';
import { HistoryPage } from '../features/history/history-page';
import { RewardsPage } from '../features/rewards/rewards-page';
import { SettingsPage } from '../features/settings/settings-page';
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
        children: [
          {
            element: <AuthenticatedLayout />,
            children: [
              { path: '/', element: <DashboardPage /> },
              { path: '/rewards', element: <RewardsPage /> },
              { path: '/history', element: <HistoryPage /> },
              { path: '/settings', element: <SettingsPage /> },
            ],
          },
        ],
      },
    ],
  },
]);
