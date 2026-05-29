-- =====================================================================
-- iter173: Meguri board quoted replies and in-thread search support
-- =====================================================================
-- Adds quoted reply metadata so thread replies can preserve context even
-- after the original reply is edited or soft-deleted.

alter table public.meguri_board_replies
  add column if not exists parent_reply_id uuid references public.meguri_board_replies(id) on delete set null,
  add column if not exists quote_author_name text,
  add column if not exists quote_body text;

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_quote_body_length_check;
alter table public.meguri_board_replies
  add constraint meguri_board_replies_quote_body_length_check
  check (quote_body is null or char_length(quote_body) <= 160);

create index if not exists idx_meguri_board_replies_parent_reply
  on public.meguri_board_replies(parent_reply_id)
  where parent_reply_id is not null;

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

drop function if exists public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text);
create function public.append_meguri_board_reply_for_viewer(
  p_thread_id uuid,
  p_body text,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null,
  p_parent_reply_id uuid default null,
  p_quote_author_name text default null,
  p_quote_body text default null
)
returns table (
  id uuid,
  thread_id uuid,
  author_id uuid,
  body text,
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

  insert into public.meguri_board_replies (
    thread_id,
    author_id,
    body,
    parent_reply_id,
    quote_author_name,
    quote_body
  )
  values (
    p_thread_id,
    auth.uid(),
    btrim(p_body),
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

revoke all on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) from public;
revoke all on function public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text, uuid, text, text) from public;

grant execute on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) to authenticated;
grant execute on function public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text, uuid, text, text) to authenticated;
