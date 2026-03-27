const DEFAULT_SUPABASE_URL = 'https://jrqjysycoqhlnyufhliy.supabase.co';
const DEFAULT_SUPABASE_ANON =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpycWp5c3ljb3FobG55dWZobGl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI0MzM0NTIsImV4cCI6MjA2ODAwOTQ1Mn0.3BVA-Ar9YtLGGO12Gt6NQkMl2cn18E_b48PGtlFxxCw';

const supabaseLoadMessages = {
  en: 'Supabase library failed to load. Check your network or replace with local copies.',
  it: 'Impossibile caricare la libreria Supabase. Controlla la rete o sostituiscila con copie locali.',
};

export const getBrowserLocale = () =>
  (navigator.language || '').toLowerCase().startsWith('it') ? 'it' : 'en';

export const getSupabaseLoadMessage = (locale) =>
  supabaseLoadMessages[locale] || supabaseLoadMessages.en;

const getRuntimeConfig = () => {
  const g = window;
  const config = g.__CALISYNC_CONFIG__ || g.CALISYNC_CONFIG || {};

  return {
    url: config.supabaseUrl || config.SUPABASE_URL || DEFAULT_SUPABASE_URL,
    anonKey:
      config.supabaseAnonKey || config.SUPABASE_ANON_KEY || DEFAULT_SUPABASE_ANON,
  };
};

export const createSupabaseClient = () => {
  const g = window;
  const createClient =
    (g.supabase && g.supabase.createClient) ||
    (g.Supabase && g.Supabase.createClient) ||
    g.SUPABASE_CREATE_CLIENT;

  if (!createClient) {
    return {
      supabase: null,
      error: 'Supabase JS failed to load from all CDNs (jsDelivr/ESM).',
    };
  }

  const { url, anonKey } = getRuntimeConfig();

  if (!url || !anonKey) {
    return {
      supabase: null,
      error: 'Supabase configuration is missing. Define window.__CALISYNC_CONFIG__ before app.js.',
    };
  }

  return {
    supabase: createClient(url, anonKey),
    error: null,
  };
};
