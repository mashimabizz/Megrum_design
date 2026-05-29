-- =====================================================================
-- iter168.89: Location-scoped Groom and Meguri board
-- =====================================================================
-- - Groom feed: show posts created within 1km of the viewer.
-- - Meguri board: show threads either by prefecture or within 3km of
--   the thread creation coordinate.

create or replace function public.haversine_meters(
  lat1 double precision,
  lng1 double precision,
  lat2 double precision,
  lng2 double precision
)
returns double precision
language sql
immutable
as $$
  select case
    when lat1 is null or lng1 is null or lat2 is null or lng2 is null then null
    else
      6371000 * 2 * asin(
        least(
          1,
          sqrt(
            power(sin(radians(lat2 - lat1) / 2), 2)
            + cos(radians(lat1))
            * cos(radians(lat2))
            * power(sin(radians(lng2 - lng1) / 2), 2)
          )
        )
      )
  end;
$$;

grant execute on function public.haversine_meters(
  double precision,
  double precision,
  double precision,
  double precision
) to authenticated;

alter table public.groom_posts
  add column if not exists origin_lat double precision,
  add column if not exists origin_lng double precision;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'groom_posts_origin_lat_range'
  ) then
    alter table public.groom_posts
      add constraint groom_posts_origin_lat_range
      check (origin_lat is null or (origin_lat between -90 and 90));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'groom_posts_origin_lng_range'
  ) then
    alter table public.groom_posts
      add constraint groom_posts_origin_lng_range
      check (origin_lng is null or (origin_lng between -180 and 180));
  end if;
end $$;

create index if not exists idx_groom_posts_origin
  on public.groom_posts(origin_lat, origin_lng, published_at desc)
  where origin_lat is not null and origin_lng is not null;

create or replace function public.list_groom_feed_nearby(
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_radius_m integer default 1000
)
returns table (
  id uuid,
  user_id uuid,
  image_url text,
  image_path text,
  caption text,
  status text,
  audience_scope text,
  area_key text,
  place_hint text,
  image_transform jsonb,
  text_overlays jsonb,
  stickers jsonb,
  doodles jsonb,
  published_at timestamptz,
  expires_at timestamptz,
  origin_lat double precision,
  origin_lng double precision,
  distance_m double precision,
  author_id uuid,
  author_display_name text,
  author_handle text,
  author_avatar_url text,
  author_primary_area text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    gp.id,
    gp.user_id,
    gp.image_url,
    gp.image_path,
    gp.caption,
    gp.status,
    gp.audience_scope,
    gp.area_key,
    gp.place_hint,
    gp.image_transform,
    gp.text_overlays,
    gp.stickers,
    gp.doodles,
    gp.published_at,
    gp.expires_at,
    gp.origin_lat,
    gp.origin_lng,
    public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng) as distance_m,
    u.id as author_id,
    u.display_name as author_display_name,
    u.handle as author_handle,
    u.avatar_url as author_avatar_url,
    u.primary_area as author_primary_area
  from public.groom_posts gp
  join public.users u on u.id = gp.user_id
  where auth.uid() is not null
    and gp.status = 'published'
    and gp.expires_at > now()
    and not exists (
      select 1 from public.groom_hidden_posts hidden
      where hidden.user_id = auth.uid()
        and hidden.groom_post_id = gp.id
    )
    and not exists (
      select 1 from public.groom_user_blocks blocks
      where (blocks.blocker_id = auth.uid() and blocks.blocked_id = gp.user_id)
         or (blocks.blocker_id = gp.user_id and blocks.blocked_id = auth.uid())
    )
    and (
      gp.user_id = auth.uid()
      or (
        p_viewer_lat is not null
        and p_viewer_lng is not null
        and gp.origin_lat is not null
        and gp.origin_lng is not null
        and public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng)
          <= least(greatest(coalesce(p_radius_m, 1000), 100), 1000)
      )
    )
  order by
    case when gp.user_id = auth.uid() then 0 else 1 end,
    distance_m nulls last,
    gp.published_at desc
  limit 80;
end;
$$;

revoke all on function public.list_groom_feed_nearby(
  double precision,
  double precision,
  integer
) from public;
grant execute on function public.list_groom_feed_nearby(
  double precision,
  double precision,
  integer
) to authenticated;

alter table public.meguri_board_threads
  add column if not exists origin_lat double precision,
  add column if not exists origin_lng double precision;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'meguri_board_threads_origin_lat_range'
  ) then
    alter table public.meguri_board_threads
      add constraint meguri_board_threads_origin_lat_range
      check (origin_lat is null or (origin_lat between -90 and 90));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'meguri_board_threads_origin_lng_range'
  ) then
    alter table public.meguri_board_threads
      add constraint meguri_board_threads_origin_lng_range
      check (origin_lng is null or (origin_lng between -180 and 180));
  end if;
end $$;

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_audience_scope_check;

alter table public.meguri_board_threads
  add constraint meguri_board_threads_audience_scope_check
  check (audience_scope in ('nearby_3km', 'same_prefecture', 'same_spot', 'global'));

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_scope_context;

alter table public.meguri_board_threads
  add constraint meguri_board_scope_context check (
    case audience_scope
      when 'nearby_3km' then origin_lat is not null and origin_lng is not null and prefecture is not null
      when 'same_spot' then spot_key is not null and spot_label is not null and prefecture is not null
      when 'same_prefecture' then prefecture is not null
      else true
    end
  );

create index if not exists idx_meguri_board_threads_origin
  on public.meguri_board_threads(origin_lat, origin_lng, latest_activity_at desc)
  where origin_lat is not null and origin_lng is not null;

create or replace function public.can_view_meguri_board_thread_with_context(
  target_thread_id uuid,
  viewer_id uuid,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.meguri_board_threads thread
     where thread.id = target_thread_id
       and viewer_id is not null
       and (
         thread.author_id = viewer_id
         or (
           coalesce(p_scope, thread.audience_scope) = 'nearby_3km'
           and thread.audience_scope in ('nearby_3km', 'same_spot')
           and p_viewer_lat is not null
           and p_viewer_lng is not null
           and thread.origin_lat is not null
           and thread.origin_lng is not null
           and public.haversine_meters(
             p_viewer_lat,
             p_viewer_lng,
             thread.origin_lat,
             thread.origin_lng
           ) <= 3000
         )
         or (
           coalesce(p_scope, thread.audience_scope) = 'same_prefecture'
           and thread.audience_scope in ('same_prefecture', 'global')
           and thread.prefecture is not null
           and p_prefecture is not null
           and replace(thread.prefecture, ' ', '') = replace(p_prefecture, ' ', '')
         )
       )
  );
$$;

revoke all on function public.can_view_meguri_board_thread_with_context(
  uuid,
  uuid,
  double precision,
  double precision,
  text,
  text
) from public;
grant execute on function public.can_view_meguri_board_thread_with_context(
  uuid,
  uuid,
  double precision,
  double precision,
  text,
  text
) to authenticated;

create or replace function public.list_meguri_board_threads_for_viewer(
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default 'nearby_3km'
)
returns table (
  id uuid,
  author_id uuid,
  title text,
  body text,
  audience_scope text,
  spot_key text,
  spot_label text,
  prefecture text,
  origin_lat double precision,
  origin_lng double precision,
  distance_m double precision,
  reply_count integer,
  latest_reply_preview text,
  latest_activity_at timestamptz,
  created_at timestamptz,
  author_display_name text,
  author_handle text,
  author_primary_area text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    thread.id,
    thread.author_id,
    thread.title,
    thread.body,
    thread.audience_scope,
    thread.spot_key,
    thread.spot_label,
    thread.prefecture,
    thread.origin_lat,
    thread.origin_lng,
    public.haversine_meters(p_viewer_lat, p_viewer_lng, thread.origin_lat, thread.origin_lng) as distance_m,
    thread.reply_count,
    thread.latest_reply_preview,
    thread.latest_activity_at,
    thread.created_at,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.meguri_board_threads thread
  join public.users author on author.id = thread.author_id
  where public.can_view_meguri_board_thread_with_context(
    thread.id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  )
  order by thread.latest_activity_at desc
  limit 120;
end;
$$;

revoke all on function public.list_meguri_board_threads_for_viewer(
  double precision,
  double precision,
  text,
  text
) from public;
grant execute on function public.list_meguri_board_threads_for_viewer(
  double precision,
  double precision,
  text,
  text
) to authenticated;

create or replace function public.list_meguri_board_replies_for_viewer(
  p_thread_id uuid,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null
)
returns table (
  id uuid,
  thread_id uuid,
  author_id uuid,
  body text,
  created_at timestamptz,
  author_display_name text,
  author_handle text,
  author_primary_area text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread_with_context(
    p_thread_id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  ) then
    return;
  end if;

  return query
  select
    reply.id,
    reply.thread_id,
    reply.author_id,
    reply.body,
    reply.created_at,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.meguri_board_replies reply
  join public.users author on author.id = reply.author_id
  where reply.thread_id = p_thread_id
  order by reply.created_at asc
  limit 300;
end;
$$;

revoke all on function public.list_meguri_board_replies_for_viewer(
  uuid,
  double precision,
  double precision,
  text,
  text
) from public;
grant execute on function public.list_meguri_board_replies_for_viewer(
  uuid,
  double precision,
  double precision,
  text,
  text
) to authenticated;

create or replace function public.append_meguri_board_reply_for_viewer(
  p_thread_id uuid,
  p_body text,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null
)
returns table (
  id uuid,
  thread_id uuid,
  author_id uuid,
  body text,
  created_at timestamptz,
  author_display_name text,
  author_handle text,
  author_primary_area text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted public.meguri_board_replies%rowtype;
begin
  if auth.uid() is null then
    raise exception 'login required';
  end if;

  if not public.can_view_meguri_board_thread_with_context(
    p_thread_id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  ) then
    raise exception 'thread is not visible from this location';
  end if;

  insert into public.meguri_board_replies (thread_id, author_id, body)
  values (p_thread_id, auth.uid(), btrim(p_body))
  returning * into inserted;

  return query
  select
    inserted.id,
    inserted.thread_id,
    inserted.author_id,
    inserted.body,
    inserted.created_at,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.users author
  where author.id = inserted.author_id;
end;
$$;

revoke all on function public.append_meguri_board_reply_for_viewer(
  uuid,
  text,
  double precision,
  double precision,
  text,
  text
) from public;
grant execute on function public.append_meguri_board_reply_for_viewer(
  uuid,
  text,
  double precision,
  double precision,
  text,
  text
) to authenticated;
