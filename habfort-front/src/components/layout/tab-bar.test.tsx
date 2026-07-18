import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, expect, it } from 'vitest';
import { TabBar } from './tab-bar';

describe('TabBar', () => {
  it('links to the three main tabs', () => {
    render(
      <MemoryRouter initialEntries={['/']}>
        <TabBar />
      </MemoryRouter>,
    );

    expect(screen.getByRole('link', { name: /habits/i })).toHaveAttribute('href', '/');
    expect(screen.getByRole('link', { name: /rewards/i })).toHaveAttribute('href', '/rewards');
    expect(screen.getByRole('link', { name: /history/i })).toHaveAttribute('href', '/history');
  });

  it('marks the current route as active', () => {
    render(
      <MemoryRouter initialEntries={['/rewards']}>
        <TabBar />
      </MemoryRouter>,
    );

    expect(screen.getByRole('link', { name: /rewards/i }).className).toContain('text-black');
    expect(screen.getByRole('link', { name: /habits/i }).className).toContain('text-gray-400');
  });
});
