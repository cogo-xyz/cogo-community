// Lazily import supabase-js to keep it optional for consumers
export async function createSupabaseClient(url: string, key: string) {
  const mod = await import('@supabase/supabase-js');
  const createClient = (mod as any).createClient as (u: string, k: string, o?: any) => any;
  return createClient(url.replace(/\/$/, ''), key, { auth: { persistSession: false } });
}


