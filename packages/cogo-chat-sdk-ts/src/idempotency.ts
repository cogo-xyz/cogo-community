export function newIdempotencyKey(prefix = 'idem'): string {
  // RFC4122 v4 surrogate
  const s = crypto.randomUUID();
  return `${prefix}:${s}`;
}
