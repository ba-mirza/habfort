import { randomInt } from 'crypto';

// No 0/O, 1/l/I — the id gets read aloud and retyped.
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
const LENGTH = 10;

/** ~57^10 ≈ 3.6e17 combinations; uniqueness is still enforced by the DB. */
export function generatePublicId(): string {
  let id = '';
  for (let i = 0; i < LENGTH; i++) {
    id += ALPHABET[randomInt(ALPHABET.length)];
  }
  return id;
}
