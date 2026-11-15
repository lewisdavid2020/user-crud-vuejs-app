interface RandomSource {
  randomUUID?: () => string;
  getRandomValues: (array: Uint8Array) => Uint8Array;
}

/**
 * Generates a UUID v4.
 *
 * `crypto.randomUUID()` only exists in secure contexts, so it is unavailable when
 * the app is opened over plain HTTP on a LAN address. `crypto.getRandomValues()`
 * works in insecure contexts, so it is used as the fallback.
 */
export function createUuid(source: RandomSource = crypto): string {
  if (typeof source.randomUUID === 'function') return source.randomUUID();
  const bytes = new Uint8Array(16);
  source.getRandomValues(bytes);
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
