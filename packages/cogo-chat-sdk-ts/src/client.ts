import type { Capabilities } from './types.js';
import { fetchJson } from './http.js';

export type CogoClientOptions = {
  edgeBase: string;
  anonKey: string;
};

export function createHeaders(anonKey: string): Record<string, string> {
  return { apikey: anonKey, Authorization: `Bearer ${anonKey}` };
}

export class CogoClient {
  private base: string;
  private anon: string;
  constructor(opts: CogoClientOptions) {
    this.base = opts.edgeBase.replace(/\/$/, '');
    this.anon = opts.anonKey;
  }
  headers(): Record<string, string> { return createHeaders(this.anon); }
  baseUrl(): string { return this.base; }
  anonKey(): string { return this.anon; }

  async getCapabilities(): Promise<Capabilities> {
    return await fetchJson<Capabilities>(`${this.base}/intent-resolve/info`, { headers: this.headers() }, { retries: 1, backoffMs: 200, timeoutMs: 8000 });
  }
}

export function createCogoClient(opts: CogoClientOptions): CogoClient {
  return new CogoClient(opts);
}
