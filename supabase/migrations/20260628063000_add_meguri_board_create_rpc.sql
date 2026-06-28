-- =====================================================================
-- iter1226.101: Meguri board creation RPC
-- =====================================================================

create or replace function public.enforce_meguri_board_daily_create_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  created_today integer;
  jst_day_start timestamptz := date_trunc('day', now() at time zone 'Asia/Tokyo') at time zone 'Asia/Tokyo';
  jst_day_end timestamptz := (date_trunc('day', now() at time zone 'Asia/Tokyo') + interval '1 day') at time zone 'Asia/Tokyo';
begin
  if auth.uid() is null or new.author_id <> auth.uid() then
    raise exception 'login required';
  end if;

  perform pg_advisory_xact_lock(hashtext(auth.uid()::text));

  select count(*)::integer
    into created_today
    from public.meguri_board_threads thread
   where thread.author_id = auth.uid()
     and thread.created_at >= jst_day_start
     and thread.created_at < jst_day_end;

  if created_today >= 20 then
    raise exception 'board daily create limit exceeded';
  end if;

  return new;
end;
$$;

create or replace function public.create_meguri_board_thread_for_viewer(
  p_title text,
  p_body text,
  p_scope text default 'nearby_3km',
  p_origin_lat double precision default null,
  p_origin_lng double precision default null,
  p_prefecture text default null,
  p_image_paths text[] default array[]::text[],
  p_anonymous_display_name text default null,
  p_anonymous_avatar_id text default null
)
returns table (
  id uuid,
  author_id uuid,
  title text,
  body text,
  audience_scope text,
  origin_lat double precision,
  origin_lng double precision,
  prefecture text,
  image_paths text[],
  status text,
  reply_count integer,
  latest_activity_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz,
  anonymous_display_name text,
  anonymous_avatar_id text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted public.meguri_board_threads%rowtype;
begin
  if auth.uid() is null then
    raise exception 'login required';
  end if;

  insert into public.meguri_board_threads (
    author_id,
    title,
    body,
    audience_scope,
    origin_lat,
    origin_lng,
    prefecture,
    image_paths,
    anonymous_display_name,
    anonymous_avatar_id,
    category
  )
  values (
    auth.uid(),
    btrim(coalesce(p_title, '')),
    btrim(coalesce(p_body, '')),
    coalesce(nullif(btrim(coalesce(p_scope, '')), ''), 'nearby_3km'),
    p_origin_lat,
    p_origin_lng,
    nullif(btrim(coalesce(p_prefecture, '')), ''),
    coalesce(p_image_paths, array[]::text[]),
    nullif(btrim(coalesce(p_anonymous_display_name, '')), ''),
    nullif(btrim(coalesce(p_anonymous_avatar_id, '')), ''),
    'chat'
  )
  returning * into inserted;

  return query
  select
    inserted.id,
    inserted.author_id,
    inserted.title,
    inserted.body,
    inserted.audience_scope,
    inserted.origin_lat,
    inserted.origin_lng,
    inserted.prefecture,
    inserted.image_paths,
    inserted.status,
    inserted.reply_count,
    inserted.latest_activity_at,
    inserted.expires_at,
    inserted.created_at,
    inserted.anonymous_display_name,
    inserted.anonymous_avatar_id;
end;
$$;

revoke all on function public.create_meguri_board_thread_for_viewer(
  text,
  text,
  text,
  double precision,
  double precision,
  text,
  text[],
  text,
  text
) from public;

grant execute on function public.create_meguri_board_thread_for_viewer(
  text,
  text,
  text,
  double precision,
  double precision,
  text,
  text[],
  text,
  text
) to authenticated;
