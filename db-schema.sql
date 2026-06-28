-- ============================================================================
-- ozxpress-routes — Supabase schema
-- Run this in the Supabase SQL Editor (Ozxpress-routes project, ref bxlpoxqckfrikvjhbcju)
-- Safe to re-run: uses IF NOT EXISTS / CREATE OR REPLACE where possible.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- 1. REPS  (one row per user; id mirrors auth.users.id)
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.reps (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text not null,
  email      text not null,
  phone      text,
  role       text not null default 'salesperson' check (role in ('admin','salesperson')),
  active     boolean not null default true,
  created_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────────────
-- 2. BUSINESSES  (claimed territory — a business belongs to the rep who claimed it)
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.businesses (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  address       text not null,
  neighborhood  text not null,
  type          text,
  tier          int default 1,
  bio           text,
  pitch         text,
  -- contact info reps add later (Phase 4)
  contact_name  text,
  contact_email text,
  contact_phone text,
  notes         text,
  -- ownership
  claimed_by    uuid references public.reps(id) on delete set null,
  claimed_at    timestamptz,
  status        text not null default 'claimed' check (status in ('claimed','visited','released','booked')),
  created_at    timestamptz not null default now()
);
create index if not exists businesses_neighborhood_idx on public.businesses (neighborhood);
create index if not exists businesses_claimed_by_idx   on public.businesses (claimed_by);

-- ─────────────────────────────────────────────────────────────────────────
-- 3. APPOINTMENTS  (a rep's visit history against a business)
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.appointments (
  id             uuid primary key default gen_random_uuid(),
  business_id    uuid references public.businesses(id) on delete cascade,
  rep_id         uuid references public.reps(id) on delete set null,
  neighborhood   text,
  scheduled_time text,
  visited_at     timestamptz,
  outcome        text,
  notes          text,
  created_at     timestamptz not null default now()
);
create index if not exists appointments_rep_idx      on public.appointments (rep_id);
create index if not exists appointments_business_idx on public.appointments (business_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 4. ROUTES  (saved route history — optional, Phase 2)
-- ─────────────────────────────────────────────────────────────────────────
create table if not exists public.routes (
  id           uuid primary key default gen_random_uuid(),
  rep_id       uuid references public.reps(id) on delete set null,
  neighborhood text not null,
  start_time   text,
  stop_ids     uuid[],
  created_at   timestamptz not null default now()
);
create index if not exists routes_rep_idx on public.routes (rep_id);

-- ─────────────────────────────────────────────────────────────────────────
-- HELPER: is the current user an admin?
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from public.reps
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ─────────────────────────────────────────────────────────────────────────
-- TRIGGER: auto-create a reps row whenever an auth user is created.
-- Pulls name / phone / role from the user's metadata (defaults to salesperson).
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.reps (id, name, email, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    new.email,
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'role', 'salesperson')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.reps         enable row level security;
alter table public.businesses   enable row level security;
alter table public.appointments enable row level security;
alter table public.routes       enable row level security;

-- ── REPS ──
drop policy if exists reps_select_self_or_admin on public.reps;
create policy reps_select_self_or_admin on public.reps
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists reps_admin_write on public.reps;
create policy reps_admin_write on public.reps
  for all using (public.is_admin()) with check (public.is_admin());

drop policy if exists reps_update_self on public.reps;
create policy reps_update_self on public.reps
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ── BUSINESSES ──
-- A salesperson sees only the businesses he claimed; admin sees all.
drop policy if exists biz_select_own_or_admin on public.businesses;
create policy biz_select_own_or_admin on public.businesses
  for select using (claimed_by = auth.uid() or public.is_admin());

-- A salesperson can claim (insert) businesses for himself; admin can insert any.
drop policy if exists biz_insert_own_or_admin on public.businesses;
create policy biz_insert_own_or_admin on public.businesses
  for insert with check (claimed_by = auth.uid() or public.is_admin());

-- A salesperson can update his own claimed businesses; admin can update any
-- (admin update is how a business gets reassigned or released back to the pool).
drop policy if exists biz_update_own_or_admin on public.businesses;
create policy biz_update_own_or_admin on public.businesses
  for update using (claimed_by = auth.uid() or public.is_admin())
  with check (public.is_admin() or claimed_by = auth.uid());

drop policy if exists biz_delete_admin on public.businesses;
create policy biz_delete_admin on public.businesses
  for delete using (public.is_admin());

-- ── APPOINTMENTS ──
drop policy if exists appt_select_own_or_admin on public.appointments;
create policy appt_select_own_or_admin on public.appointments
  for select using (rep_id = auth.uid() or public.is_admin());

drop policy if exists appt_write_own_or_admin on public.appointments;
create policy appt_write_own_or_admin on public.appointments
  for all using (rep_id = auth.uid() or public.is_admin())
  with check (rep_id = auth.uid() or public.is_admin());

-- ── ROUTES ──
drop policy if exists routes_select_own_or_admin on public.routes;
create policy routes_select_own_or_admin on public.routes
  for select using (rep_id = auth.uid() or public.is_admin());

drop policy if exists routes_write_own_or_admin on public.routes;
create policy routes_write_own_or_admin on public.routes
  for all using (rep_id = auth.uid() or public.is_admin())
  with check (rep_id = auth.uid() or public.is_admin());

-- ============================================================================
-- DONE. Next: create the admin user (see instructions), then:
--   update public.reps set role = 'admin' where email = 'YOUR_ADMIN_EMAIL';
-- ============================================================================
