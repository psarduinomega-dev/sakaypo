const SUPABASE_URL = 'https://iyxhpexusyjntgxgynfw.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5eGhwZXh1c3lqbnRneGd5bmZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NTY0ODYsImV4cCI6MjA5MDQzMjQ4Nn0.gVWhI8uApPXznKfDqFtAUsgZzS6PDll_FzTPCGgru7k';

// CDN exposes window.supabase.createClient — we store our client as `db`
// so it never conflicts with the window.supabase namespace
const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function getCurrentUser() {
  const { data: { user } } = await db.auth.getUser();
  return user;
}

async function getProfile(userId) {
  const { data, error } = await db
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) return null;
  return data;
}

async function signOut() {
  await db.auth.signOut();
  window.location.href = '/pages/login.html';
}

async function requireAuth(redirectTo = '/pages/login.html') {
  const user = await getCurrentUser();
  if (!user) { window.location.href = redirectTo; return null; }
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

function watchDriverLocation(onUpdate) {
  return db
    .channel('driver-location')
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'driver_sessions'
    }, payload => onUpdate(payload.new))
    .subscribe();
}