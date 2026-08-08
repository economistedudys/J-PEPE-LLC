// J Pepe LLC — Supabase project connection
// Publishable key is safe to expose in client-side code (protected by Row Level Security)
const SUPABASE_URL = "https://dulluppehkhubsglmfwg.supabase.co";
const SUPABASE_KEY = "sb_publishable_RIAo201rzt0CxHDu8CIc5g_3XMe3blS";

function getSupabaseClient() {
  return window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
}
