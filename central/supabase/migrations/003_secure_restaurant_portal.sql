-- NQ CENTRAL — CONEXIÓN SEGURA DEL PORTAL DE RESTAURANTES
-- Ejecutar una sola vez en Supabase > SQL Editor del proyecto qcvhxrudzjlgqlhvnkkl.
-- Es aditiva: conserva las tablas y los eventos originales. El portal cliente leerá app_events,
-- protegida por RLS, y nunca consultará directamente los eventos de todos los restaurantes.

begin;

-- El portal necesita el dispositivo y una referencia para evitar duplicar importaciones.
alter table public.app_events
  add column if not exists device_type text,
  add column if not exists legacy_event_id bigint;

create unique index if not exists app_events_legacy_event_id_uidx
  on public.app_events (legacy_event_id)
  where legacy_event_id is not null;

-- Separar los recuentos manuales de apertura y cierre de reseñas.
alter table public.app_review_snapshots
  add column if not exists platform text not null default 'Google cierre';

-- Importar los eventos históricos de los tres restaurantes sin duplicarlos.
insert into public.app_events
  (restaurant_id, event_type, created_at, source, device_type, legacy_event_id)
select r.id, e.event, e.created_at, 'legacy_nfc_events', e.device_type, e.id
from public.nfc_events e
join public.app_restaurants r on (
  (lower(trim(e.restaurant)) = 'feral steakhouse' and r.slug = 'feral-steakhouse')
  or (lower(trim(e.restaurant)) = 'tzura steak house' and r.slug = 'tzura-steak-house')
  or (lower(trim(e.restaurant)) = 'veta steak house' and r.slug = 'veta-steak-house')
)
where e.event in ('nfc_tap', 'qr_scan')
  and e.created_at is not null
on conflict (legacy_event_id) where legacy_event_id is not null do nothing;

-- Cada evento nuevo de las páginas NFC/QR se refleja en app_events.
create or replace function public.app_mirror_nfc_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_slug text;
  target_restaurant_id uuid;
begin
  if new.event not in ('nfc_tap', 'qr_scan') then
    return new;
  end if;

  target_slug := case lower(trim(new.restaurant))
    when 'feral steakhouse' then 'feral-steakhouse'
    when 'tzura steak house' then 'tzura-steak-house'
    when 'veta steak house' then 'veta-steak-house'
    else null
  end;

  if target_slug is null then
    return new;
  end if;

  select id into target_restaurant_id
  from public.app_restaurants
  where slug = target_slug and status = 'approved'
  limit 1;

  if target_restaurant_id is null then
    return new;
  end if;

  insert into public.app_events
    (restaurant_id, event_type, created_at, source, device_type, legacy_event_id)
  values
    (target_restaurant_id, new.event, coalesce(new.created_at, now()),
     'legacy_nfc_events', new.device_type, new.id)
  on conflict (legacy_event_id) where legacy_event_id is not null do nothing;

  return new;
end;
$$;

drop trigger if exists app_mirror_nfc_event_trigger on public.nfc_events;
create trigger app_mirror_nfc_event_trigger
after insert on public.nfc_events
for each row execute function public.app_mirror_nfc_event();

-- Los usuarios aprobados pueden guardar solo capturas de apertura/cierre de reseñas
-- en restaurantes a los que están asignados.
drop policy if exists app_review_snapshots_member_insert on public.app_review_snapshots;
create policy app_review_snapshots_member_insert
on public.app_review_snapshots
for insert to authenticated
with check (
  public.app_is_approved_member(restaurant_id)
  and platform in ('Google apertura', 'Google cierre')
  and source = 'manual'
);

-- Permitir que el usuario edite su nombre en el perfil, sin poder aprobarse ni cambiar de rol.
create or replace function public.app_protect_profile_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) = old.user_id and not public.app_is_admin() then
    new.role := old.role;
    new.status := old.status;
    new.email := old.email;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists app_profiles_protect_fields on public.app_profiles;
create trigger app_profiles_protect_fields
before update on public.app_profiles
for each row execute function public.app_protect_profile_fields();

drop policy if exists app_profiles_self_update on public.app_profiles;
create policy app_profiles_self_update
on public.app_profiles
for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

grant select, insert on public.app_events to authenticated;
grant select, insert on public.app_review_snapshots to authenticated;
grant update on public.app_profiles to authenticated;

commit;

-- Verificación: debe mostrar los recuentos históricos por restaurante y canal.
select r.name, e.event_type, count(*) as total
from public.app_events e
join public.app_restaurants r on r.id = e.restaurant_id
where r.slug in ('feral-steakhouse','tzura-steak-house','veta-steak-house')
group by r.name, e.event_type
order by r.name, e.event_type;
