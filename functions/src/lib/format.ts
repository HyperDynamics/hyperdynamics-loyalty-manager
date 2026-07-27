export function digitsOnly(input: string): string {
  return (input ?? "").replace(/\D/g, "");
}

/** Mirrors the Flutter client's `pointsForAmount` — server is the source of truth. */
export function pointsForAmount(amount: number, ratio: number): number {
  if (!ratio || ratio <= 0) return 0;
  return Math.floor(amount / ratio);
}

export function randomDigits(length: number): string {
  let out = "";
  for (let i = 0; i < length; i++) out += Math.floor(Math.random() * 10).toString();
  return out;
}

const SLUG_ALPHABET = "abcdefghjkmnpqrstuvwxyz23456789"; // no ambiguous chars
export function randomSlugSuffix(length = 5): string {
  let out = "";
  for (let i = 0; i < length; i++) {
    out += SLUG_ALPHABET[Math.floor(Math.random() * SLUG_ALPHABET.length)];
  }
  return out;
}

export function slugify(input: string): string {
  const base = input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return base.length > 0 ? base.slice(0, 24) : "business";
}
