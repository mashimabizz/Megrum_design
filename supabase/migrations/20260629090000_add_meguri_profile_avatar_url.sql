-- =====================================================================
-- iter1226.175: Meguri custom profile avatar URL
-- =====================================================================
-- Allows Meguri-only profiles to keep a custom uploaded icon while retaining
-- the six preset anonymous avatar choices as the fallback avatar_id.

alter table public.meguri_profiles
  add column if not exists avatar_url text;

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
  new.avatar_url = nullif(btrim(coalesce(new.avatar_url, '')), '');
  new.updated_at = now();
  return new;
end;
$$;

drop function if exists public.set_meguri_profile_for_viewer(text, text);

create or replace function public.set_meguri_profile_for_viewer(
  p_display_name text,
  p_avatar_id text,
  p_avatar_url text default null
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
  v_avatar_url text := nullif(btrim(coalesce(p_avatar_url, '')), '');
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
     and v_existing.avatar_id = v_avatar_id
     and coalesce(v_existing.avatar_url, '') = coalesce(v_avatar_url, '') then
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
    avatar_url,
    last_changed_at
  )
  values (
    v_user_id,
    v_display_name,
    v_display_name_key,
    v_avatar_id,
    v_avatar_url,
    now()
  )
  on conflict (user_id) do update
     set display_name = excluded.display_name,
         display_name_key = excluded.display_name_key,
         avatar_id = excluded.avatar_id,
         avatar_url = excluded.avatar_url,
         last_changed_at = excluded.last_changed_at,
         updated_at = now();

  return query
    select *
      from public.meguri_profiles
     where user_id = v_user_id;
end;
$$;

revoke all on function public.set_meguri_profile_for_viewer(text, text, text) from public;
grant execute on function public.set_meguri_profile_for_viewer(text, text, text) to authenticated;
