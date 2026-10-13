-- Plataforma central NFC + QR
-- Migración aditiva: crea tablas nuevas app_* y no modifica tablas actuales.
-- Hacer backup y revisar antes de ejecutar.

create extension if not exists pgcrypto;

create table if not exists public.app_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'restaurant' check (role in ('admin', 'restaurant')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status text not null default 'pending' check (status in ('pending', 'approved', 'suspended')),
  created_at timestamptz not null default now()
);

create table if not exists public.app_restaurant_members (
  restaurant_id uuid not null references public.app_restaurants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  member_role text not null default 'owner' check (member_role in ('owner', 'manager', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (restaurant_id, user_id)
);

create table if not exists public.app_events (
  id bigint generated always as identity primary key,
  restaurant_id uuid not null references public.app_restaurants(id) on delete cascade,
  event_type text not null check (event_type in ('nfc_tap', 'qr_scan')),
  created_at timestamptz not null default now(),
  source text not null default 'central_app'
);
create index if not exists app_events_restaurant_created_idx
  on public.app_events (restaurant_id, created_at desc);

create table if not exists public.app_review_snapshots (
  id bigint generated always as identity primary key,
  restaurant_id uuid not null references public.app_restaurants(id) on delete cascade,
  review_count integer not null check (review_count >= 0),
  captured_at timestamptz not null default now(),
  source text not null default 'manual' check (source in ('manual', 'verified_import', 'api'))
);
create index if not exists app_review_snapshots_restaurant_time_idx
  on public.app_review_snapshots (restaurant_id, captured_at desc);

-- Cada alta nueva obtiene rol restaurant y estado pending. Nunca se autoconcede admin.
create or replace function public.app_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.app_profiles (user_id, full_name, role, status)
  values (new.id, nullif(new.raw_user_meta_data ->> 'full_name', ''), 'restaurant', 'pending')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists app_auth_user_created on auth.users;
create trigger app_auth_user_created
after insert on auth.users
for each row execute procedure public.app_handle_new_user();

create or replace function public.app_is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.app_profiles p
    where p.user_id = (select auth.uid())
      and p.role = 'admin' and p.status = 'approved'
  );
$$;

create or replace function public.app_is_approved_member(target_restaurant uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.app_profiles p
    join public.app_restaurant_members m on m.user_id = p.user_id
    join public.app_restaurants r on r.id = m.restaurant_id
    where p.user_id = (select auth.uid())
      and p.status = 'approved' and r.status = 'approved'
      and m.restaurant_id = target_restaurant
  );
$$;

alter table public.app_profiles enable row level security;
alter table public.app_restaurants enable row level security;
alter table public.app_restaurant_members enable row level security;
alter table public.app_events enable row level security;
alter table public.app_review_snapshots enable row level security;

drop policy if exists app_profiles_select_self_or_admin on public.app_profiles;
create policy app_profiles_select_self_or_admin
on public.app_profiles for select to authenticated
using (user_id = (select auth.uid()) or public.app_is_admin());

drop policy if exists app_profiles_admin_update on public.app_profiles;
create policy app_profiles_admin_update
on public.app_profiles for update to authenticated
using (public.app_is_admin()) with check (public.app_is_admin());

drop policy if exists app_restaurants_select_member_or_admin on public.app_restaurants;
create policy app_restaurants_select_member_or_admin
on public.app_restaurants for select to authenticated
using (public.app_is_admin() or public.app_is_approved_member(id));

drop policy if exists app_restaurants_admin_write on public.app_restaurants;
create policy app_restaurants_admin_write
on public.app_restaurants for all to authenticated
using (public.app_is_admin()) with check (public.app_is_admin());

drop policy if exists app_members_select_member_or_admin on public.app_restaurant_members;
create policy app_members_select_member_or_admin
on public.app_restaurant_members for select to authenticated
using (user_id = (select auth.uid()) or public.app_is_admin());

drop policy if exists app_members_admin_write on public.app_restaurant_members;
create policy app_members_admin_write
on public.app_restaurant_members for all to authenticated
using (public.app_is_admin()) with check (public.app_is_admin());

drop policy if exists app_events_select_member_or_admin on public.app_events;
create policy app_events_select_member_or_admin
on public.app_events for select to authenticated
using (public.app_is_admin() or public.app_is_approved_member(restaurant_id));

-- Solo admin puede insertar en app_events desde el cliente; eventos públicos se migrarán
-- a un endpoint seguro cuando se conecten las páginas NFC/QR.
drop policy if exists app_events_admin_insert on public.app_events;
create policy app_events_admin_insert
on public.app_events for insert to authenticated
with check (public.app_is_admin());

drop policy if exists app_review_snapshots_select_member_or_admin on public.app_review_snapshots;
create policy app_review_snapshots_select_member_or_admin
on public.app_review_snapshots for select to authenticated
using (public.app_is_admin() or public.app_is_approved_member(restaurant_id));

drop policy if exists app_review_snapshots_admin_write on public.app_review_snapshots;
create policy app_review_snapshots_admin_write
on public.app_review_snapshots for all to authenticated
using (public.app_is_admin()) with check (public.app_is_admin());

grant select, update on public.app_profiles to authenticated;
grant select, insert, update, delete on public.app_restaurants to authenticated;
grant select, insert, update, delete on public.app_restaurant_members to authenticated;
grant select, insert on public.app_events to authenticated;
grant select, insert, update, delete on public.app_review_snapshots to authenticated;
