// Supabase Edge Function: key-vault
// - GET by name:    /?name=SUPABASE_SERVICE_ROLE_KEY&env=dev
// - GET by fields:  /?provider=anthropic&service=embeddings&resource=text-embedding-3-large&env=dev
// - POST upsert:    { name?, value, env, is_encrypted, provider?, service?, resource?, region?, alias?, status?, version_int? }

import { serve } from 'https://deno.land/std@0.192.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const url = new URL(req.url)
  const method = req.method.toUpperCase()

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

  const json = async (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } })

  try {
    if (method === 'GET') {
      const env = url.searchParams.get('env') || 'dev'
      const name = url.searchParams.get('name')
      const provider = url.searchParams.get('provider')
      const service = url.searchParams.get('service')
      const resource = url.searchParams.get('resource')
      const alias = url.searchParams.get('alias')

      let query = supabase.from('secure_keys').select('*').eq('env', env)

      if (name) query = query.eq('name', name)
      if (alias) query = query.eq('alias', alias)
      if (provider) query = query.eq('provider', provider)
      if (service) query = query.eq('service', service)
      if (resource) query = query.eq('resource', resource)

      // Prefer active, not expired, highest version
      const { data, error } = await query.eq('status', 'active').order('version_int', { ascending: false }).limit(1).maybeSingle()
      if (error) return json(500, { error: error.message })
      if (!data) return json(404, { error: 'not_found' })

      // Touch last_used and usage_count
      await supabase.from('secure_keys').update({ last_used_at: new Date().toISOString(), usage_count: (data.usage_count || 0) + 1 }).eq('id', data.id)
      await supabase.from('secure_keys_audit').insert({ key_id: data.id, name: data.name, env, event: 'read' })

      return json(200, {
        name: data.name,
        env: data.env,
        provider: data.provider,
        service: data.service,
        resource: data.resource,
        region: data.region,
        alias: data.alias,
        is_encrypted: data.is_encrypted,
        value: data.is_encrypted ? null : data.plaintext
      })
    }

    if (method === 'POST') {
      const body = await req.json().catch(() => ({})) as any
      const { name, value, env = 'dev', is_encrypted = false, provider = null, service = null, resource = null, region = null, alias = null, status = 'active', version_int = 1, category = 'service', key_type = 'api_key' } = body
      if ((!name && !provider) || typeof value !== 'string') return json(400, { error: 'name or provider required; and value required' })

      const payload: any = { name, env, is_encrypted, provider, service, resource, region, alias, status, version_int, category, key_type }
      if (is_encrypted) payload.ciphertext = value
      else payload.plaintext = value

      const conflictTarget = alias ? 'alias,env' : (name ? 'name,env' : 'provider,service,resource,env,version_int')

      const { data, error } = await supabase
        .from('secure_keys')
        .upsert(payload, { onConflict: conflictTarget as any, ignoreDuplicates: false })
        .select('id, name, env, is_encrypted, provider, service, resource, alias, version_int')
        .maybeSingle()
      if (error) return json(500, { error: error.message })
      await supabase.from('secure_keys_audit').insert({ key_id: data?.id, name: data?.name, env, event: 'write' })
      return json(200, { ok: true, key: data })
    }

    return json(405, { error: 'method_not_allowed' })
  } catch (e) {
    return json(500, { error: (e as Error).message })
  }
})


