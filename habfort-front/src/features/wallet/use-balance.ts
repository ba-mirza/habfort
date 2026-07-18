import { useQuery } from '@tanstack/react-query';
import { api } from '../../lib/api';

interface WalletBalance {
  balance: number;
}

export function useBalance() {
  return useQuery({
    queryKey: ['wallet', 'balance'],
    queryFn: () => api.get<WalletBalance>('/wallet/balance'),
  });
}
