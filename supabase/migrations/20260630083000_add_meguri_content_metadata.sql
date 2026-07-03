-- Add optional oshi and series metadata to grooms and Meguri board threads.

alter table public.groom_posts
  add column if not exists group_id uuid references public.groups_master(id) on delete set null,
  add column if not exists character_id uuid references public.characters_master(id) on delete set null,
  add column if not exists series_name text;

alter table public.meguri_board_threads
  add column if not exists group_id uuid references public.groups_master(id) on delete set null,
  add column if not exists character_id uuid references public.characters_master(id) on delete set null,
  add column if not exists series_name text;

create index if not exists idx_groom_posts_group_published
  on public.groom_posts(group_id, published_at desc)
  where group_id is not null and status = 'published';

create index if not exists idx_groom_posts_character_published
  on public.groom_posts(character_id, published_at desc)
  where character_id is not null and status = 'published';

create index if not exists idx_meguri_board_threads_group_activity
  on public.meguri_board_threads(group_id, latest_activity_at desc)
  where group_id is not null and status in ('visible', 'locked');

create index if not exists idx_meguri_board_threads_character_activity
  on public.meguri_board_threads(character_id, latest_activity_at desc)
  where character_id is not null and status in ('visible', 'locked');

drop function if exists public.list_groom_feed_nearby(double precision, double precision, integer);
create function public.list_groom_feed_nearby(
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
  group_id uuid,
  character_id uuid,
  series_name text,
  distance_m double precision,
  like_count integer,
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
    gp.group_id,
    gp.character_id,
    gp.series_name,
    public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng) as distance_m,
    (
      select count(*)::integer
        from public.groom_reactions reaction
       where reaction.groom_post_id = gp.id
         and reaction.reaction_type = 'like'
    ) as like_count,
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
          <= least(greatest(coalesce(p_radius_m, 1000), 100), 3000)
      )
    )
  order by
    case when gp.user_id = auth.uid() then 0 else 1 end,
    distance_m nulls last,
    gp.published_at desc
  limit 80;
end;
$$;

revoke all on function public.list_groom_feed_nearby(double precision, double precision, integer) from public;
grant execute on function public.list_groom_feed_nearby(double precision, double precision, integer) to authenticated;

drop function if exists public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text);
create function public.list_meguri_board_threads_for_viewer(
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
  image_paths text[],
  group_id uuid,
  character_id uuid,
  series_name text,
  category text,
  status text,
  is_pinned boolean,
  audience_scope text,
  spot_key text,
  spot_label text,
  prefecture text,
  origin_lat double precision,
  origin_lng double precision,
  distance_m double precision,
  reply_count integer,
  reaction_count integer,
  good_reaction_count integer,
  bad_reaction_count integer,
  bookmark_count integer,
  view_count integer,
  latest_reply_preview text,
  latest_activity_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  anonymous_display_name text,
  anonymous_avatar_id text,
  viewer_bookmarked boolean,
  viewer_reacted boolean,
  viewer_reaction_type text,
  viewer_hidden boolean,
  viewer_reported boolean,
  viewer_subscribed boolean,
  viewer_participated boolean,
  viewer_read_at timestamptz,
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
    thread.image_paths,
    thread.group_id,
    thread.character_id,
    thread.series_name,
    thread.category,
    thread.status,
    thread.is_pinned,
    thread.audience_scope,
    thread.spot_key,
    thread.spot_label,
    thread.prefecture,
    thread.origin_lat,
    thread.origin_lng,
    public.haversine_meters(p_viewer_lat, p_viewer_lng, thread.origin_lat, thread.origin_lng) as distance_m,
    thread.reply_count,
    thread.reaction_count,
    (
      select count(*)::integer
      from public.meguri_board_thread_reactions reaction
      where reaction.thread_id = thread.id
        and reaction.reaction_type in ('useful', 'good')
    ) as good_reaction_count,
    (
      select count(*)::integer
      from public.meguri_board_thread_reactions reaction
      where reaction.thread_id = thread.id
        and reaction.reaction_type = 'bad'
    ) as bad_reaction_count,
    thread.bookmark_count,
    thread.view_count,
    thread.latest_reply_preview,
    thread.latest_activity_at,
    thread.expires_at,
    thread.created_at,
    thread.updated_at,
    thread.anonymous_display_name,
    thread.anonymous_avatar_id,
    exists (
      select 1 from public.meguri_board_thread_bookmarks bookmark
      where bookmark.thread_id = thread.id and bookmark.user_id = auth.uid()
    ) as viewer_bookmarked,
    exists (
      select 1 from public.meguri_board_thread_reactions reaction
      where reaction.thread_id = thread.id and reaction.user_id = auth.uid()
    ) as viewer_reacted,
    (
      select case
        when reaction.reaction_type = 'useful' then 'good'
        else reaction.reaction_type
      end
      from public.meguri_board_thread_reactions reaction
      where reaction.thread_id = thread.id and reaction.user_id = auth.uid()
      order by reaction.created_at desc
      limit 1
    ) as viewer_reaction_type,
    exists (
      select 1 from public.meguri_board_hidden_threads hidden
      where hidden.thread_id = thread.id and hidden.user_id = auth.uid()
    ) as viewer_hidden,
    exists (
      select 1 from public.meguri_board_reports report
      where report.thread_id = thread.id and report.reporter_id = auth.uid()
    ) as viewer_reported,
    exists (
      select 1 from public.meguri_board_thread_subscriptions subscription
      where subscription.thread_id = thread.id
        and subscription.user_id = auth.uid()
        and subscription.notification_enabled
    ) as viewer_subscribed,
    (
      thread.author_id = auth.uid()
      or exists (
        select 1 from public.meguri_board_replies reply
        where reply.thread_id = thread.id
          and reply.author_id = auth.uid()
          and reply.status = 'visible'
      )
    ) as viewer_participated,
    reads.read_at as viewer_read_at,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.meguri_board_threads thread
  join public.users author on author.id = thread.author_id
  left join public.meguri_board_thread_reads reads
    on reads.thread_id = thread.id and reads.user_id = auth.uid()
  where public.can_view_meguri_board_thread_with_context(
    thread.id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  )
    and thread.status in ('visible', 'locked')
    and thread.expires_at > now()
    and not exists (
      select 1 from public.meguri_board_hidden_threads hidden
      where hidden.thread_id = thread.id and hidden.user_id = auth.uid()
    )
  order by thread.is_pinned desc, thread.latest_activity_at desc
  limit 120;
end;
$$;

drop function if exists public.create_meguri_board_thread_for_viewer(text, text, text, double precision, double precision, text, text[], text, text);
create function public.create_meguri_board_thread_for_viewer(
  p_title text,
  p_body text,
  p_scope text default 'nearby_3km',
  p_origin_lat double precision default null,
  p_origin_lng double precision default null,
  p_prefecture text default null,
  p_image_paths text[] default array[]::text[],
  p_anonymous_display_name text default null,
  p_anonymous_avatar_id text default null,
  p_group_id uuid default null,
  p_character_id uuid default null,
  p_series_name text default null
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
  group_id uuid,
  character_id uuid,
  series_name text,
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
    group_id,
    character_id,
    series_name,
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
    p_group_id,
    p_character_id,
    nullif(btrim(coalesce(p_series_name, '')), ''),
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
    inserted.group_id,
    inserted.character_id,
    inserted.series_name,
    inserted.status,
    inserted.reply_count,
    inserted.latest_activity_at,
    inserted.expires_at,
    inserted.created_at,
    inserted.anonymous_display_name,
    inserted.anonymous_avatar_id;
end;
$$;

revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;
grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;

revoke all on function public.create_meguri_board_thread_for_viewer(
  text,
  text,
  text,
  double precision,
  double precision,
  text,
  text[],
  text,
  text,
  uuid,
  uuid,
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
  text,
  uuid,
  uuid,
  text
) to authenticated;
