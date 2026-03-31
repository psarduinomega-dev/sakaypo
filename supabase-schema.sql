-- ─────────────────────────────────────────────────────────────
-- SakayKo — Supabase Database Schema
-- Run this in your Supabase project → SQL Editor
-- ─────────────────────────────────────────────────────────────

-- 1. PROFILES TABLE
-- Extends Supabase's built-in auth.users table
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name    TEXT NOT NULL,
  last_name     TEXT NOT NULL,
  email         TEXT NOT NULL,
  phone         TEXT,
  role          TEXT NOT NULL DEFAULT 'passenger' CHECK (role IN ('passenger', 'driver', 'admin')),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DRIVER SESSIONS TABLE
-- Stores live driver location (one row per driver)
CREATE TABLE IF NOT EXISTS public.driver_sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id     UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  is_online     BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RIDE REQUESTS TABLE
-- Passengers submit pickup requests here
CREATE TABLE IF NOT EXISTS public.ride_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  passenger_name  TEXT NOT NULL,
  pickup_lat      DOUBLE PRECISION NOT NULL,
  pickup_lng      DOUBLE PRECISION NOT NULL,
  note            TEXT,
  status          TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'accepted', 'picked_up', 'cancelled')),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- AUTO-CREATE PROFILE ON SIGNUP TRIGGER
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, email, phone, role, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'passenger'),
    'pending'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS)
-- ─────────────────────────────────────────────────────────────

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ride_requests ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read all (to see admin status), update only own
CREATE POLICY "Users can read all profiles"
  ON public.profiles FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Admin can update any profile (for approve/reject)
CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Driver sessions: all approved users can read, drivers update own
CREATE POLICY "Approved users can read driver sessions"
  ON public.driver_sessions FOR SELECT TO authenticated
  USING (TRUE);

CREATE POLICY "Drivers can insert own session"
  ON public.driver_sessions FOR INSERT TO authenticated
  WITH CHECK (driver_id = auth.uid());

CREATE POLICY "Drivers can update own session"
  ON public.driver_sessions FOR UPDATE TO authenticated
  USING (driver_id = auth.uid());

-- Ride requests: passengers manage own, drivers can read all active, admins all
CREATE POLICY "Passengers can insert own requests"
  ON public.ride_requests FOR INSERT TO authenticated
  WITH CHECK (passenger_id = auth.uid());

CREATE POLICY "Passengers can read own requests"
  ON public.ride_requests FOR SELECT TO authenticated
  USING (
    passenger_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('driver', 'admin'))
  );

CREATE POLICY "Passengers can update own requests"
  ON public.ride_requests FOR UPDATE TO authenticated
  USING (passenger_id = auth.uid());

CREATE POLICY "Drivers can update requests"
  ON public.ride_requests FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('driver', 'admin'))
  );

-- ─────────────────────────────────────────────────────────────
-- REALTIME — enable for live updates
-- ─────────────────────────────────────────────────────────────
-- In Supabase Dashboard → Database → Replication
-- Enable realtime for: profiles, driver_sessions, ride_requests

-- ─────────────────────────────────────────────────────────────
-- CREATE YOUR FIRST ADMIN ACCOUNT
-- After signing up normally, run this to make yourself admin:
-- ─────────────────────────────────────────────────────────────
-- UPDATE public.profiles
-- SET role = 'admin', status = 'approved'
-- WHERE email = 'your-admin-email@example.com';