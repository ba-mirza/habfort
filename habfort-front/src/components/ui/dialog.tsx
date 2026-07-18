import * as RadixDialog from '@radix-ui/react-dialog';
import type { ReactNode } from 'react';

interface DialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  children: ReactNode;
}

// Bottom sheet, not a centered desktop modal — matches the mobile app feel:
// pinned to the bottom edge, rounded top corners, small drag-handle bar.
export function Dialog({ open, onOpenChange, title, children }: DialogProps) {
  return (
    <RadixDialog.Root open={open} onOpenChange={onOpenChange}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className="fixed inset-0 bg-black/40" />
        <RadixDialog.Content className="fixed inset-x-0 bottom-0 mx-auto max-h-[85svh] w-full max-w-[480px] overflow-y-auto rounded-t-2xl bg-white p-4 dark:bg-gray-900">
          <div className="mx-auto mb-3 h-1 w-10 rounded-full bg-gray-300 dark:bg-gray-600" aria-hidden />
          <RadixDialog.Title className="text-lg font-semibold">{title}</RadixDialog.Title>
          <div className="mt-3">{children}</div>
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}
