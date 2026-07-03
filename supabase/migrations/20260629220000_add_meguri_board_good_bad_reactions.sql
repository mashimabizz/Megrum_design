-- Add good/bad reactions for Meguri board chat messages.

alter table public.meguri_board_thread_reactions
  drop constraint if exists meguri_board_thread_reactions_reaction_type_check;
alter table public.meguri_board_thread_reactions
  add constraint meguri_board_thread_reactions_reaction_type_check
  check (reaction_type in ('useful', 'good', 'bad'));

alter table public.meguri_board_reply_reactions
  drop constraint if exists meguri_board_reply_reactions_reaction_type_check;
alter table public.meguri_board_reply_reactions
  add constraint meguri_board_reply_reactions_reaction_type_check
  check (reaction_type in ('useful', 'good', 'bad'));

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
  good_reaction_count integer,
  bad_reaction_count integer,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz,
  viewer_reacted boolean,
  viewer_reaction_type text,
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
    (
      select count(*)::integer
      from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id
        and reaction.reaction_type in ('useful', 'good')
    ) as good_reaction_count,
    (
      select count(*)::integer
      from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id
        and reaction.reaction_type = 'bad'
    ) as bad_reaction_count,
    reply.created_at,
    reply.updated_at,
    reply.deleted_at,
    exists (
      select 1 from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id and reaction.user_id = auth.uid()
    ) as viewer_reacted,
    (
      select case
        when reaction.reaction_type = 'useful' then 'good'
        else reaction.reaction_type
      end
      from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id and reaction.user_id = auth.uid()
      order by reaction.created_at desc
      limit 1
    ) as viewer_reaction_type,
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
    and not exists (
      select 1 from public.groom_user_blocks block
      where (
        block.blocker_id = auth.uid()
        and block.blocked_id = reply.author_id
      )
      or (
        block.blocker_id = reply.author_id
        and block.blocked_id = auth.uid()
      )
    )
  order by reply.created_at asc
  limit 300;
end;
$$;

create or replace function public.set_meguri_board_thread_message_reaction(
  p_thread_id uuid,
  p_reaction_type text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  safe_reaction_type text := lower(nullif(btrim(coalesce(p_reaction_type, '')), ''));
begin
  if not public.can_view_meguri_board_thread(p_thread_id, auth.uid()) then
    return;
  end if;

  if safe_reaction_type not in ('good', 'bad') then
    safe_reaction_type := null;
  end if;

  delete from public.meguri_board_thread_reactions
  where thread_id = p_thread_id and user_id = auth.uid();

  if safe_reaction_type is not null then
    insert into public.meguri_board_thread_reactions (thread_id, user_id, reaction_type)
    values (p_thread_id, auth.uid(), safe_reaction_type)
    on conflict do nothing;

    insert into public.meguri_board_thread_subscriptions (
      thread_id,
      user_id,
      notification_enabled
    )
    values (p_thread_id, auth.uid(), true)
    on conflict (thread_id, user_id)
    do update
       set notification_enabled = true,
           updated_at = now();
  end if;
end;
$$;

create or replace function public.set_meguri_board_reply_message_reaction(
  p_reply_id uuid,
  p_reaction_type text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_thread uuid;
  safe_reaction_type text := lower(nullif(btrim(coalesce(p_reaction_type, '')), ''));
begin
  select reply.thread_id into target_thread
  from public.meguri_board_replies reply
  where reply.id = p_reply_id;

  if target_thread is null or not public.can_view_meguri_board_thread(target_thread, auth.uid()) then
    return;
  end if;

  if safe_reaction_type not in ('good', 'bad') then
    safe_reaction_type := null;
  end if;

  delete from public.meguri_board_reply_reactions
  where reply_id = p_reply_id and user_id = auth.uid();

  if safe_reaction_type is not null then
    insert into public.meguri_board_reply_reactions (reply_id, user_id, reaction_type)
    values (p_reply_id, auth.uid(), safe_reaction_type)
    on conflict do nothing;
  end if;
end;
$$;

revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;
revoke all on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) from public;
revoke all on function public.set_meguri_board_thread_message_reaction(uuid, text) from public;
revoke all on function public.set_meguri_board_reply_message_reaction(uuid, text) from public;

grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;
grant execute on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) to authenticated;
grant execute on function public.set_meguri_board_thread_message_reaction(uuid, text) to authenticated;
grant execute on function public.set_meguri_board_reply_message_reaction(uuid, text) to authenticated;
