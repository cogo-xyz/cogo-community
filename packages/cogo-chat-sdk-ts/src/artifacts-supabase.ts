// Minimal supabase storage helpers (requires @supabase/supabase-js client instance)
export async function storageHead(sb: any, bucket: string, key: string): Promise<{ contentType?: string | null; size?: number | null }> {
  const { data, error } = await sb.storage.from(bucket).download(key);
  if (error) return { contentType: null, size: null };
  return { contentType: data.type, size: data.size };
}

export async function storageDownloadJson<T = unknown>(sb: any, bucket: string, key: string): Promise<T> {
  const { data, error } = await sb.storage.from(bucket).download(key);
  if (error) throw error;
  const text = await data.text();
  return JSON.parse(text) as T;
}


