-- =====================================================================
-- iter172: Meguri board edit / close / delete controls
-- =====================================================================
-- Adds ordinary thread operations for owner moderation: edit a thread,
-- close/reopen it, archive it, and edit/delete own replies.

alter table public.meguri_board_replies
  add column if not exists status text not null default 'visible',
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists deleted_at timestamptz;

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_status_check;
alter table public.meguri_board_replies
  add constraint meguri_board_replies_status_check
  check (status in ('visible', 'deleted'));

drop trigger if exists trg_meguri_board_replies_updated_at on public.meguri_board_replies;
create trigger trg_meguri_board_replies_updated_at
  before update on public.meguri_board_replies
  for each row execute function public.set_updated_at();

create index if not exists idx_meguri_board_replies_visible_thread
  on public.meguri_board_replies(thread_id, created_at asc)
  where status in ('visible', 'deleted');

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
  created_at timestamptz,
  updated_at timestamptz,
  viewer_bookmarked boolean,
  viewer_reacted boolean,
  viewer_hidden boolean,
  viewer_reported boolean,
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
    thread.created_at,
    thread.updated_at,
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
    and not exists (
      select 1 from public.meguri_board_hidden_threads hidden
      where hidden.thread_id = thread.id and hidden.user_id = auth.uid()
    )
  order by thread.is_pinned desc, thread.latest_activity_at desc
  limit 120;
end;
$$;

drop function if exists public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text);
create function public.list_meguri_board_replies_for_viewer(
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
  status text,
  reaction_count integer,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz,
  viewer_reacted boolean,
  viewer_reported boolean,
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
    reply.status,
    reply.reaction_count,
    reply.created_at,
    reply.updated_at,
    reply.deleted_at,
    exists (
      select 1 from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id and reaction.user_id = auth.uid()
    ) as viewer_reacted,
    exists (
      select 1 from public.meguri_board_reports report
      where report.reply_id = reply.id and report.reporter_id = auth.uid()
    ) as viewer_reported,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.meguri_board_replies reply
  join public.users author on author.id = reply.author_id
  where reply.thread_id = p_thread_id
    and reply.status in ('visible', 'deleted')
  order by reply.created_at asc
  limit 300;
end;
$$;

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
  reaction_count integer,
  created_at timestamptz,
  viewer_reacted boolean,
  viewer_reported boolean,
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

  if not exists (
    select 1
    from public.meguri_board_threads thread
    where thread.id = p_thread_id
      and thread.status = 'visible'
  ) then
    raise exception 'thread is closed';
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
    inserted.reaction_count,
    inserted.created_at,
    false as viewer_reacted,
    false as viewer_reported,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.users author
  where author.id = inserted.author_id;
end;
$$;

create or replace function public.update_meguri_board_thread(
  p_thread_id uuid,
  p_title text,
  p_body text,
  p_category text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.meguri_board_threads
     set title = btrim(p_title),
         body = btrim(p_body),
         category = coalesce(nullif(p_category, ''), category),
         latest_activity_at = greatest(latest_activity_at, now()),
         updated_at = now()
   where id = p_thread_id
     and author_id = auth.uid()
     and status in ('visible', 'locked');
end;
$$;

create or replace function public.set_meguri_board_thread_status(
  p_thread_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('visible', 'locked', 'archived') then
    raise exception 'invalid thread status';
  end if;

  update public.meguri_board_threads
     set status = p_status,
         latest_activity_at = greatest(latest_activity_at, now()),
         updated_at = now()
   where id = p_thread_id
     and author_id = auth.uid()
     and (status <> 'archived' or p_status = 'archived');
end;
$$;

create or replace function public.update_meguri_board_reply(
  p_reply_id uuid,
  p_body text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.meguri_board_replies
     set body = btrim(p_body),
         status = 'visible',
         deleted_at = null,
         updated_at = now()
   where id = p_reply_id
     and author_id = auth.uid()
     and status = 'visible';
end;
$$;

create or replace function public.delete_meguri_board_reply(p_reply_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.meguri_board_replies
     set body = 'この返信は削除されました',
         status = 'deleted',
         deleted_at = now(),
         updated_at = now()
   where id = p_reply_id
     and author_id = auth.uid()
     and status = 'visible';
end;
$$;

revoke all on function public.update_meguri_board_thread(uuid, text, text, text) from public;
revoke all on function public.set_meguri_board_thread_status(uuid, text) from public;
revoke all on function public.update_meguri_board_reply(uuid, text) from public;
revoke all on function public.delete_meguri_board_reply(uuid) from public;
revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;
revoke all on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) from public;

grant execute on function public.update_meguri_board_thread(uuid, text, text, text) to authenticated;
grant execute on function public.set_meguri_board_thread_status(uuid, text) to authenticated;
grant execute on function public.update_meguri_board_reply(uuid, text) to authenticated;
grant execute on function public.delete_meguri_board_reply(uuid) to authenticated;
grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;
grant execute on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) to authenticated;
