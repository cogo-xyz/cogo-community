export type RetryOptions = { retries?: number; backoffMs?: number; timeoutMs?: number };

export async function fetchJson<T = any>(url: string, init: RequestInit = {}, retry: RetryOptions = {}): Promise<T> {
  const { retries = 2, backoffMs = 250, timeoutMs } = retry;
  let attempt = 0;
  while (true) {
    try {
      const controller = timeoutMs ? new AbortController() : undefined;
      const t = timeoutMs ? setTimeout(() => controller!.abort(), timeoutMs) : undefined;
      const res = await fetch(url, { ...init, signal: controller?.signal });
      if (t) clearTimeout(t);
      const ok = res.ok;
      const ct = res.headers.get('content-type') || '';
      const body = ct.includes('application/json') ? await res.json() : await res.text();
      if (!ok) {
        const code = (body && (body.code || body.error)) || res.status;
        const msg = (body && (body.message || body.error)) || res.statusText;
        // retry on 5xx
        if (res.status >= 500 && attempt < retries) {
          attempt++;
          await new Promise(r => setTimeout(r, backoffMs * attempt));
          continue;
        }
        throw new Error(`HTTP ${res.status} ${code}: ${msg}`);
      }
      return body as T;
    } catch (e: any) {
      const retriable = (e?.name === 'AbortError') || (e?.message?.includes('network') || e?.message?.includes('fetch'));
      if (attempt < retries && retriable) {
        attempt++;
        await new Promise(r => setTimeout(r, backoffMs * attempt));
        continue;
      }
      throw e;
    }
  }
}


