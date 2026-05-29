-- =====================================================================
-- iter176: Meguri board image attachments
-- =====================================================================
-- Threads and replies can carry up to four image paths. Actual files live
-- in a private Storage bucket and the app signs paths only after the thread
-- is visible to the current viewer.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'meguri-board-media',
  'meguri-board-media',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
   set public = false,
       file_size_limit = excluded.file_size_limit,
       allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Meguri board media readable by authenticated"
  on storage.objects;
create policy "Meguri board media readable by authenticated"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'meguri-board-media');

drop policy if exists "Users can upload own meguri board media"
  on storage.objects;
create policy "Users can upload own meguri board media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'meguri-board-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Users can delete own meguri board media"
  on storage.objects;
create policy "Users can delete own meguri board media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'meguri-board-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

alter table public.meguri_board_threads
  add column if not exists image_paths text[] not null default '{}';

alter table public.meguri_board_replies
  add column if not exists image_paths text[] not null default '{}';

update public.meguri_board_threads
   set image_paths = '{}'
 where image_paths is null;

update public.meguri_board_replies
   set image_paths = '{}'
 where image_paths is null;

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_image_paths_length_check;
alter table public.meguri_board_threads
  add constraint meguri_board_threads_image_paths_length_check
  check (coalesce(array_length(image_paths, 1), 0) <= 4);

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_image_paths_nonblank_check;
alter table public.meguri_board_threads
  add constraint meguri_board_threads_image_paths_nonblank_check
  check (array_position(image_paths, '') is null);

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_image_paths_length_check;
alter table public.meguri_board_replies
  add constraint meguri_board_replies_image_paths_length_check
  check (coalesce(array_length(image_paths, 1), 0) <= 4);

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_image_paths_nonblank_check;
alter table public.meguri_board_replies
  add constraint meguri_board_replies_image_paths_nonblank_check
  check (array_position(image_paths, '') is null);

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
  created_at timestamptz,
  updated_at timestamptz,
  viewer_bookmarked boolean,
  viewer_reacted boolean,
  viewer_hidden boolean,
  viewer_reported boolean,
  viewer_subscribed boolean,
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
    exists (
      select 1 from public.meguri_board_thread_subscriptions subscription
      where subscription.thread_id = thread.id
        and subscription.user_id = auth.uid()
        and subscription.notification_enabled
    ) as viewer_subscribed,
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
  image_paths text[],
  parent_reply_id uuid,
  quote_author_name text,
  quote_body text,
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
    reply.image_paths,
    reply.parent_reply_id,
    reply.quote_author_name,
    reply.quote_body,
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

drop function if exists public.append_meguri_board_reply_for_viewer(
  uuid,
  text,
  double precision,
  double precision,
  text,
  text,
  uuid,
  text,
  text
);
create function public.append_meguri_board_reply_for_viewer(
  p_thread_id uuid,
  p_body text,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null,
  p_parent_reply_id uuid default null,
  p_quote_author_name text default null,
  p_quote_body text default null,
  p_image_paths text[] default '{}'
)
returns table (
  id uuid,
  thread_id uuid,
  author_id uuid,
  body text,
  image_paths text[],
  parent_reply_id uuid,
  quote_author_name text,
  quote_body text,
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
security definer
set search_path = public
as $$
declare
  inserted public.meguri_board_replies%rowtype;
  safe_image_paths text[];
  safe_parent_reply_id uuid;
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

  if p_parent_reply_id is not null then
    select reply.id into safe_parent_reply_id
      from public.meguri_board_replies reply
     where reply.id = p_parent_reply_id
       and reply.thread_id = p_thread_id
       and reply.status = 'visible';
  end if;

  select coalesce(array_agg(clean_path), '{}')
    into safe_image_paths
  from (
    select nullif(btrim(path), '') as clean_path
    from unnest(coalesce(p_image_paths, '{}')) as path
    where nullif(btrim(path), '') is not null
    limit 4
  ) cleaned;

  insert into public.meguri_board_replies (
    thread_id,
    author_id,
    body,
    image_paths,
    parent_reply_id,
    quote_author_name,
    quote_body
  )
  values (
    p_thread_id,
    auth.uid(),
    btrim(p_body),
    coalesce(safe_image_paths, '{}'),
    safe_parent_reply_id,
    nullif(btrim(coalesce(p_quote_author_name, '')), ''),
    left(nullif(btrim(coalesce(p_quote_body, '')), ''), 160)
  )
  returning * into inserted;

  return query
  select
    inserted.id,
    inserted.thread_id,
    inserted.author_id,
    inserted.body,
    inserted.image_paths,
    inserted.parent_reply_id,
    inserted.quote_author_name,
    inserted.quote_body,
    inserted.status,
    inserted.reaction_count,
    inserted.created_at,
    inserted.updated_at,
    inserted.deleted_at,
    false as viewer_reacted,
    false as viewer_reported,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.users author
  where author.id = inserted.author_id;
end;
$$;

revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;
revoke all on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) from public;
revoke all on function public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text, uuid, text, text, text[]) from public;

grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;
grant execute on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) to authenticated;
grant execute on function public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text, uuid, text, text, text[]) to authenticated;
