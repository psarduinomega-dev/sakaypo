// ─── Supabase Configuration ───
// Replace these with your actual Supabase project credentials
// Get them from: https://supabase.com → Your Project → Settings → API

const SUPABASE_URL = 'https://iyxhpexusyjntgxgynfw.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eGhwZXh1c3lqbnRneGd5bmZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NTY0ODYsImV4cCI6MjA5MDQzMjQ4Nn0.gVWhI8uApPXznKfDqFtAUsgZzS6PDll_FzTPCGgru7k';

// Initialize Supabase client
// This uses the Supabase CDN loaded in each HTML page
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ─── Auth Helpers ───

async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) return null;
  return data;
}

async function signOut() {
  await supabase.auth.signOut();
  window.location.href = '/pages/login.html';
}

// ─── Route Guards ───

async function requireAuth(redirectTo = '/pages/login.html') {
  const user = await getCurrentUser();
  if (!user) {
    window.location.href = redirectTo;
    return null;
  }
  return user;
}

async function requireApproved() {
  const user = await requireAuth();
  if (!user) return null;
  const profile = await getProfile(user.id);
  if (!profile) { window.location.href = '/pages/login.html'; return null; }
  if (profile.status === 'pending') { window.location.href = '/pages/pending.html'; return null; }
  if (profile.status === 'rejected') { window.location.href = '/pages/rejected.html'; return null; }
  return { user, profile };
}

async function requireAdmin() {
  const result = await requireApproved();
  if (!result) return null;
  if (result.profile.role !== 'admin') { window.location.href = '/pages/map.html'; return null; }
  return result;
}

// ─── Realtime location helpers ───

function watchDriverLocation(onUpdate) {
  return supabase
    .channel('driver-location')
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'driver_sessions'
    }, payload => onUpdate(payload.new))
    .subscribe();
}