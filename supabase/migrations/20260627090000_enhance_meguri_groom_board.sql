-- =====================================================================
-- iter1225: Meguri map clusters, groom like extension, board anonymity
-- =====================================================================
-- Adds server-side primitives for the Swift Native Meguri expansion:
-- - groom likes extend the post lifetime by 3 hours in one RPC transaction
-- - board threads carry anonymous per-thread display metadata
-- - board threads expire 7 days after the latest write and lock at 1000 replies
-- - each user can create at most two board threads per day

-- ---------------------------------------------------------------------
-- 1. Groom like toggle with lifetime extension
-- ---------------------------------------------------------------------
create or replace function public.set_groom_like_for_viewer(
  p_post_id uuid,
  p_is_liked boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_like_count integer := 0;
begin
  if auth.uid() is null then
    raise exception 'login required';
  end if;

  if p_is_liked then
    if not public.can_view_groom_post(p_post_id, auth.uid()) then
      raise exception 'groom post is not visible';
    end if;

    if exists (
      select 1
        from public.groom_posts gp
       where gp.id = p_post_id
         and gp.user_id = auth.uid()
    ) then
      raise exception 'cannot like own groom post';
    end if;

    insert into public.groom_reactions (
      groom_post_id,
      user_id,
      reaction_type
    )
    values (
      p_post_id,
      auth.uid(),
      'like'
    )
    on conflict (groom_post_id, user_id, reaction_type) do nothing;

    get diagnostics inserted_like_count = row_count;

    if inserted_like_count > 0 then
      update public.groom_posts
         set expires_at = greatest(coalesce(expires_at, now()), now()) + interval '3 hours',
             updated_at = now()
       where id = p_post_id
         and status = 'published';
    end if;
  else
    delete from public.groom_reactions
     where groom_post_id = p_post_id
       and user_id = auth.uid()
       and reaction_type = 'like';
  end if;
end;
$$;

revoke all on function public.set_groom_like_for_viewer(uuid, boolean) from public;
grant execute on function public.set_groom_like_for_viewer(uuid, boolean) to authenticated;

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

-- ---------------------------------------------------------------------
-- 2. Meguri board anonymity, expiry, and rate/size limits
-- ---------------------------------------------------------------------
alter table public.meguri_board_threads
  add column if not exists expires_at timestamptz,
  add column if not exists anonymous_display_name text,
  add column if not exists anonymous_avatar_id text;

update public.meguri_board_threads
   set expires_at = coalesce(expires_at, latest_activity_at + interval '7 days')
 where expires_at is null;

alter table public.meguri_board_threads
  alter column expires_at set not null;

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_anonymous_name_check;
alter table public.meguri_board_threads
  add constraint meguri_board_threads_anonymous_name_check
  check (
    anonymous_display_name is null
    or char_length(btrim(anonymous_display_name)) between 1 and 24
  );

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_anonymous_avatar_check;
alter table public.meguri_board_threads
  add constraint meguri_board_threads_anonymous_avatar_check
  check (
    anonymous_avatar_id is null
    or anonymous_avatar_id in ('avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6')
  );

create index if not exists idx_meguri_board_threads_expiry
  on public.meguri_board_threads(expires_at, latest_activity_at desc)
  where status in ('visible', 'locked');

create or replace function public.set_meguri_board_thread_expiry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.anonymous_display_name = nullif(btrim(coalesce(new.anonymous_display_name, '')), '');
  new.anonymous_avatar_id = nullif(btrim(coalesce(new.anonymous_avatar_id, '')), '');
  new.expires_at = coalesce(new.expires_at, coalesce(new.latest_activity_at, now()) + interval '7 days');
  return new;
end;
$$;

drop trigger if exists trg_meguri_board_threads_expiry on public.meguri_board_threads;
create trigger trg_meguri_board_threads_expiry
  before insert or update on public.meguri_board_threads
  for each row execute function public.set_meguri_board_thread_expiry();

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

  if created_today >= 2 then
    raise exception 'board daily create limit exceeded';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_meguri_board_daily_create_limit on public.meguri_board_threads;
create trigger trg_meguri_board_daily_create_limit
  before insert on public.meguri_board_threads
  for each row execute function public.enforce_meguri_board_daily_create_limit();

create or replace function public.enforce_meguri_board_reply_open()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1
    from public.meguri_board_threads thread
   where thread.id = new.thread_id
     and thread.status = 'visible'
     and thread.expires_at > now()
     and thread.reply_count < 1000
   for update;

  if not found then
    raise exception 'thread is closed';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_meguri_board_reply_open on public.meguri_board_replies;
create trigger trg_meguri_board_reply_open
  before insert on public.meguri_board_replies
  for each row execute function public.enforce_meguri_board_reply_open();

create or replace function public.sync_meguri_board_thread_after_reply()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.meguri_board_threads
     set reply_count = reply_count + 1,
         latest_reply_preview = left(new.body, 160),
         latest_activity_at = coalesce(new.created_at, now()),
         expires_at = coalesce(new.created_at, now()) + interval '7 days',
         status = case
           when reply_count + 1 >= 1000 then 'locked'
           else status
         end,
         updated_at = now()
   where id = new.thread_id;

  return new;
end;
$$;

revoke all on function public.sync_meguri_board_thread_after_reply() from public;
grant execute on function public.sync_meguri_board_thread_after_reply() to authenticated;

drop trigger if exists trg_meguri_board_replies_after_insert
  on public.meguri_board_replies;
create trigger trg_meguri_board_replies_after_insert
  after insert on public.meguri_board_replies
  for each row execute function public.sync_meguri_board_thread_after_reply();

create or replace function public.expire_meguri_board_threads()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.meguri_board_threads
     set status = 'archived',
         updated_at = now()
   where status in ('visible', 'locked')
     and expires_at <= now();
end;
$$;

revoke all on function public.expire_meguri_board_threads() from public;
grant execute on function public.expire_meguri_board_threads() to authenticated;

create or replace function public.can_view_meguri_board_thread(
  target_thread_id uuid,
  viewer_id uuid
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
      left join public.users viewer on viewer.id = viewer_id
     where thread.id = target_thread_id
       and viewer_id is not null
       and thread.status in ('visible', 'locked')
       and thread.expires_at > now()
       and not exists (
         select 1 from public.groom_user_blocks block
          where (
            block.blocker_id = viewer_id
            and block.blocked_id = thread.author_id
          )
          or (
            block.blocker_id = thread.author_id
            and block.blocked_id = viewer_id
          )
       )
       and (
         thread.author_id = viewer_id
         or thread.audience_scope = 'global'
         or (
           thread.audience_scope in ('same_prefecture', 'same_spot', 'nearby_3km')
           and thread.prefecture is not null
           and viewer.primary_area is not null
           and replace(viewer.primary_area, ' ', '') = replace(thread.prefecture, ' ', '')
         )
       )
  );
$$;

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
       and thread.status in ('visible', 'locked')
       and thread.expires_at > now()
       and not exists (
         select 1 from public.groom_user_blocks block
          where (
            block.blocker_id = viewer_id
            and block.blocked_id = thread.author_id
          )
          or (
            block.blocker_id = thread.author_id
            and block.blocked_id = viewer_id
          )
       )
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
         or (
           coalesce(p_scope, thread.audience_scope) = 'global'
           and thread.audience_scope = 'global'
         )
       )
  );
$$;

revoke all on function public.can_view_meguri_board_thread(uuid, uuid) from public;
revoke all on function public.can_view_meguri_board_thread_with_context(uuid, uuid, double precision, double precision, text, text) from public;
grant execute on function public.can_view_meguri_board_thread(uuid, uuid) to authenticated;
grant execute on function public.can_view_meguri_board_thread_with_context(uuid, uuid, double precision, double precision, text, text) to authenticated;

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

revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;
grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;
