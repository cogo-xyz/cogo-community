export async function head(url: string): Promise<{ contentType?: string | null; size?: number | null }> {
  const res = await fetch(url, { method: 'HEAD' });
  return {
    contentType: res.headers.get('content-type'),
    size: (() => { const n = Number(res.headers.get('content-length')); return Number.isFinite(n) ? n : null; })()
  };
}

export async function downloadJson<T = unknown>(url: string): Promise<T> {
  const res = await fetch(url);
  return await res.json() as T;
}


