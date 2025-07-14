
import { createClient, SupabaseClient } from '@supabase/supabase-js'

export const SupabaseWrapper = {
    _supabase: null as SupabaseClient | null,
    init: () => {
        SupabaseWrapper._supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)

    },
    get: () => {
        if (!SupabaseWrapper._supabase) {
            throw new Error('SupabaseWrapper not initialized')
        }
        return SupabaseWrapper._supabase
    },

}