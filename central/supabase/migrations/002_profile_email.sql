-- NQ Central: email visible para administración, sin exponerlo a otros restaurantes.
-- Ejecutar después de 001_app_core.sql.

alter table public.app_profiles
  add column if not exists email text;

update public.app_profiles p
set email = u.email
from auth.users u
where u.id = p.user_id
  and p.email is distinct from u.email;

create or replace function public.app_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.app_profiles (user_id, full_name, email, role, status)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    'restaurant',
    'pending'
  )
  on conflict (user_id) do update
    set email = excluded.email,
        full_name = coalesce(excluded.full_name, public.app_profiles.full_name);
  return new;
end;
$$;

-- La política existente permite leer perfiles propios o todos los perfiles al admin aprobado.
grant select, update on public.app_profiles to authenticated;
