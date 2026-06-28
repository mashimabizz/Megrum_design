-- =====================================================================
-- iter1227: Meguri profile names and avatars
-- =====================================================================
-- Stores the public Meguri-only name/avatar used on map grooms, Meguri
-- messages, and board chat rooms. The display name is globally unique and
-- profile changes are limited to once per month.

create table if not exists public.meguri_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  display_name text not null,
  display_name_key text not null,
  avatar_id text not null default 'avatar_1',
  last_changed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.meguri_profiles
  drop constraint if exists meguri_profiles_display_name_check;
alter table public.meguri_profiles
  add constraint meguri_profiles_display_name_check
  check (char_length(btrim(display_name)) between 1 and 24);

alter table public.meguri_profiles
  drop constraint if exists meguri_profiles_avatar_id_check;
alter table public.meguri_profiles
  add constraint meguri_profiles_avatar_id_check
  check (avatar_id in ('avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6'));

create unique index if not exists idx_meguri_profiles_display_name_key
  on public.meguri_profiles(display_name_key);

create or replace function public.normalize_meguri_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.display_name = btrim(coalesce(new.display_name, ''));
  new.display_name_key = lower(regexp_replace(new.display_name, '\s+', '', 'g'));
  new.avatar_id = coalesce(nullif(btrim(new.avatar_id), ''), 'avatar_1');
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_meguri_profiles_normalize on public.meguri_profiles;
create trigger trg_meguri_profiles_normalize
  before insert or update on public.meguri_profiles
  for each row execute function public.normalize_meguri_profile();

alter table public.meguri_profiles enable row level security;

drop policy if exists "Authenticated users can read meguri profiles"
  on public.meguri_profiles;
create policy "Authenticated users can read meguri profiles"
  on public.meguri_profiles
  for select
  using (auth.uid() is not null);

drop policy if exists "Users can insert own meguri profile"
  on public.meguri_profiles;
create policy "Users can insert own meguri profile"
  on public.meguri_profiles
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own meguri profile"
  on public.meguri_profiles;
create policy "Users can update own meguri profile"
  on public.meguri_profiles
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.set_meguri_profile_for_viewer(
  p_display_name text,
  p_avatar_id text
)
returns setof public.meguri_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_display_name text := btrim(coalesce(p_display_name, ''));
  v_display_name_key text := lower(regexp_replace(btrim(coalesce(p_display_name, '')), '\s+', '', 'g'));
  v_avatar_id text := coalesce(nullif(btrim(p_avatar_id), ''), 'avatar_1');
  v_existing public.meguri_profiles%rowtype;
begin
  if v_user_id is null then
    raise exception 'login required' using errcode = '42501';
  end if;

  if char_length(v_display_name) < 1 or char_length(v_display_name) > 24 then
    raise exception 'invalid_meguri_profile_display_name' using errcode = '22023';
  end if;

  if v_avatar_id not in ('avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6') then
    raise exception 'invalid_meguri_profile_avatar' using errcode = '22023';
  end if;

  select *
    into v_existing
    from public.meguri_profiles
   where user_id = v_user_id
   for update;

  if found
     and v_existing.display_name = v_display_name
     and v_existing.avatar_id = v_avatar_id then
    return query
      select *
        from public.meguri_profiles
       where user_id = v_user_id;
    return;
  end if;

  if found and v_existing.last_changed_at > now() - interval '1 month' then
    raise exception 'meguri_profile_change_locked' using errcode = 'P0001';
  end if;

  if exists (
    select 1
      from public.meguri_profiles profile
     where profile.display_name_key = v_display_name_key
       and profile.user_id <> v_user_id
  ) then
    raise exception 'duplicate_meguri_profile_display_name' using errcode = '23505';
  end if;

  insert into public.meguri_profiles (
    user_id,
    display_name,
    display_name_key,
    avatar_id,
    last_changed_at
  )
  values (
    v_user_id,
    v_display_name,
    v_display_name_key,
    v_avatar_id,
    now()
  )
  on conflict (user_id) do update
     set display_name = excluded.display_name,
         display_name_key = excluded.display_name_key,
         avatar_id = excluded.avatar_id,
         last_changed_at = excluded.last_changed_at,
         updated_at = now();

  return query
    select *
      from public.meguri_profiles
     where user_id = v_user_id;
end;
$$;

revoke all on function public.set_meguri_profile_for_viewer(text, text) from public;
grant execute on function public.set_meguri_profile_for_viewer(text, text) to authenticated;
