import { describe, expect, it, vi } from 'vitest';
import { createUuid } from '../../src/shared/uuid';

describe('createUuid', () => {
  it('prefers crypto.randomUUID when available', () => {
    const getRandomValues = vi.fn((bytes: Uint8Array) => bytes);
    expect(createUuid({ randomUUID: () => 'uuid-secure', getRandomValues })).toBe('uuid-secure');
    expect(getRandomValues).not.toHaveBeenCalled();
  });

  it('generates a valid v4 UUID when randomUUID is unavailable', () => {
    const source = {
      getRandomValues: (bytes: Uint8Array) => {
        bytes.fill(0);
        return bytes;
      },
    };
    expect(createUuid(source)).toBe('00000000-0000-4000-8000-000000000000');
  });
});
