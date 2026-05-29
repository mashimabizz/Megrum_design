-- =====================================================================
-- iter171: Meguri board thread feature expansion
-- =====================================================================
-- Adds common thread primitives: categories, status, pinning metadata,
-- reactions, bookmarks, reads/views, local hide sync, and reports.

alter table public.meguri_board_threads
  add column if not exists category text not null default 'chat',
  add column if not exists status text not null default 'visible',
  add column if not exists is_pinned boolean not null default false,
  add column if not exists view_count integer not null default 0 check (view_count >= 0),
  add column if not exists reaction_count integer not null default 0 check (reaction_count >= 0),
  add column if not exists bookmark_count integer not null default 0 check (bookmark_count >= 0);

alter table public.meguri_board_replies
  add column if not exists reaction_count integer not null default 0 check (reaction_count >= 0);

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_category_check;
alter table public.meguri_board_threads
  add constraint meguri_board_threads_category_check
  check (category in ('question', 'info', 'chat', 'trade', 'lost_found'));

alter table public.meguri_board_threads
  drop constraint if exists meguri_board_threads_status_check;
alter table public.meguri_board_threads
  add constraint meguri_board_threads_status_check
  check (status in ('visible', 'hidden', 'archived', 'locked'));

create index if not exists idx_meguri_board_threads_category
  on public.meguri_board_threads(category, latest_activity_at desc)
  where status = 'visible';

create index if not exists idx_meguri_board_threads_hot
  on public.meguri_board_threads(is_pinned desc, reply_count desc, reaction_count desc, latest_activity_at desc)
  where status = 'visible';

create table if not exists public.meguri_board_thread_bookmarks (
  thread_id uuid not null references public.meguri_board_threads(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.meguri_board_thread_reactions (
  thread_id uuid not null references public.meguri_board_threads(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reaction_type text not null default 'useful' check (reaction_type in ('useful')),
  created_at timestamptz not null default now(),
  primary key (thread_id, user_id, reaction_type)
);

create table if not exists public.meguri_board_reply_reactions (
  reply_id uuid not null references public.meguri_board_replies(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reaction_type text not null default 'useful' check (reaction_type in ('useful')),
  created_at timestamptz not null default now(),
  primary key (reply_id, user_id, reaction_type)
);

create table if not exists public.meguri_board_thread_reads (
  thread_id uuid not null references public.meguri_board_threads(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.meguri_board_hidden_threads (
  thread_id uuid not null references public.meguri_board_threads(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create table if not exists public.meguri_board_reports (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid references public.meguri_board_threads(id) on delete cascade,
  reply_id uuid references public.meguri_board_replies(id) on delete cascade,
  reporter_id uuid not null references public.users(id) on delete cascade,
  reason text not null default 'user_report',
  body text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  constraint meguri_board_reports_target_check check (
    (thread_id is not null and reply_id is null)
    or (thread_id is null and reply_id is not null)
  )
);

alter table public.meguri_board_thread_bookmarks enable row level security;
alter table public.meguri_board_thread_reactions enable row level security;
alter table public.meguri_board_reply_reactions enable row level security;
alter table public.meguri_board_thread_reads enable row level security;
alter table public.meguri_board_hidden_threads enable row level security;
alter table public.meguri_board_reports enable row level security;

drop policy if exists "Users can manage own meguri board bookmarks" on public.meguri_board_thread_bookmarks;
create policy "Users can manage own meguri board bookmarks"
  on public.meguri_board_thread_bookmarks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id and public.can_view_meguri_board_thread(thread_id, auth.uid()));

drop policy if exists "Users can manage own meguri board thread reactions" on public.meguri_board_thread_reactions;
create policy "Users can manage own meguri board thread reactions"
  on public.meguri_board_thread_reactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id and public.can_view_meguri_board_thread(thread_id, auth.uid()));

drop policy if exists "Users can manage own meguri board reply reactions" on public.meguri_board_reply_reactions;
create policy "Users can manage own meguri board reply reactions"
  on public.meguri_board_reply_reactions for all
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.meguri_board_replies reply
      where reply.id = reply_id
        and public.can_view_meguri_board_thread(reply.thread_id, auth.uid())
    )
  );

drop policy if exists "Users can manage own meguri board reads" on public.meguri_board_thread_reads;
create policy "Users can manage own meguri board reads"
  on public.meguri_board_thread_reads for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id and public.can_view_meguri_board_thread(thread_id, auth.uid()));

drop policy if exists "Users can manage own hidden meguri board threads" on public.meguri_board_hidden_threads;
create policy "Users can manage own hidden meguri board threads"
  on public.meguri_board_hidden_threads for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id and public.can_view_meguri_board_thread(thread_id, auth.uid()));

drop policy if exists "Users can insert own meguri board reports" on public.meguri_board_reports;
create policy "Users can insert own meguri board reports"
  on public.meguri_board_reports for insert
  with check (auth.uid() = reporter_id);

drop policy if exists "Users can read own meguri board reports" on public.meguri_board_reports;
create policy "Users can read own meguri board reports"
  on public.meguri_board_reports for select
  using (auth.uid() = reporter_id);

create or replace function public.sync_meguri_board_thread_reaction_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_thread uuid;
begin
  target_thread := coalesce(new.thread_id, old.thread_id);
  update public.meguri_board_threads thread
     set reaction_count = (
       select count(*)::integer
       from public.meguri_board_thread_reactions reaction
       where reaction.thread_id = target_thread
     ),
         updated_at = now()
   where thread.id = target_thread;
  return coalesce(new, old);
end;
$$;

create or replace function public.sync_meguri_board_thread_bookmark_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_thread uuid;
begin
  target_thread := coalesce(new.thread_id, old.thread_id);
  update public.meguri_board_threads thread
     set bookmark_count = (
       select count(*)::integer
       from public.meguri_board_thread_bookmarks bookmark
       where bookmark.thread_id = target_thread
     ),
         updated_at = now()
   where thread.id = target_thread;
  return coalesce(new, old);
end;
$$;

create or replace function public.sync_meguri_board_reply_reaction_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_reply uuid;
begin
  target_reply := coalesce(new.reply_id, old.reply_id);
  update public.meguri_board_replies reply
     set reaction_count = (
       select count(*)::integer
       from public.meguri_board_reply_reactions reaction
       where reaction.reply_id = target_reply
     )
   where reply.id = target_reply;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_meguri_board_thread_reactions_sync on public.meguri_board_thread_reactions;
create trigger trg_meguri_board_thread_reactions_sync
  after insert or delete on public.meguri_board_thread_reactions
  for each row execute function public.sync_meguri_board_thread_reaction_count();

drop trigger if exists trg_meguri_board_thread_bookmarks_sync on public.meguri_board_thread_bookmarks;
create trigger trg_meguri_board_thread_bookmarks_sync
  after insert or delete on public.meguri_board_thread_bookmarks
  for each row execute function public.sync_meguri_board_thread_bookmark_count();

drop trigger if exists trg_meguri_board_reply_reactions_sync on public.meguri_board_reply_reactions;
create trigger trg_meguri_board_reply_reactions_sync
  after insert or delete on public.meguri_board_reply_reactions
  for each row execute function public.sync_meguri_board_reply_reaction_count();

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
       and thread.status = 'visible'
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
       and thread.status = 'visible'
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
  reaction_count integer,
  created_at timestamptz,
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
    reply.reaction_count,
    reply.created_at,
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
  order by reply.created_at asc
  limit 300;
end;
$$;

drop function if exists public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text);

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

create or replace function public.mark_meguri_board_thread_read(p_thread_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread(p_thread_id, auth.uid()) then
    return;
  end if;
  insert into public.meguri_board_thread_reads (thread_id, user_id, read_at)
  values (p_thread_id, auth.uid(), now())
  on conflict (thread_id, user_id)
  do update set read_at = excluded.read_at;

  update public.meguri_board_threads
     set view_count = view_count + 1,
         updated_at = now()
   where id = p_thread_id;
end;
$$;

create or replace function public.set_meguri_board_thread_bookmark(
  p_thread_id uuid,
  p_enabled boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread(p_thread_id, auth.uid()) then
    return;
  end if;
  if coalesce(p_enabled, false) then
    insert into public.meguri_board_thread_bookmarks (thread_id, user_id)
    values (p_thread_id, auth.uid())
    on conflict do nothing;
  else
    delete from public.meguri_board_thread_bookmarks
    where thread_id = p_thread_id and user_id = auth.uid();
  end if;
end;
$$;

create or replace function public.set_meguri_board_thread_reaction(
  p_thread_id uuid,
  p_enabled boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread(p_thread_id, auth.uid()) then
    return;
  end if;
  if coalesce(p_enabled, false) then
    insert into public.meguri_board_thread_reactions (thread_id, user_id)
    values (p_thread_id, auth.uid())
    on conflict do nothing;
  else
    delete from public.meguri_board_thread_reactions
    where thread_id = p_thread_id and user_id = auth.uid();
  end if;
end;
$$;

create or replace function public.set_meguri_board_reply_reaction(
  p_reply_id uuid,
  p_enabled boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_thread uuid;
begin
  select reply.thread_id into target_thread
  from public.meguri_board_replies reply
  where reply.id = p_reply_id;

  if target_thread is null or not public.can_view_meguri_board_thread(target_thread, auth.uid()) then
    return;
  end if;

  if coalesce(p_enabled, false) then
    insert into public.meguri_board_reply_reactions (reply_id, user_id)
    values (p_reply_id, auth.uid())
    on conflict do nothing;
  else
    delete from public.meguri_board_reply_reactions
    where reply_id = p_reply_id and user_id = auth.uid();
  end if;
end;
$$;

create or replace function public.hide_meguri_board_thread(p_thread_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread(p_thread_id, auth.uid()) then
    return;
  end if;
  insert into public.meguri_board_hidden_threads (thread_id, user_id)
  values (p_thread_id, auth.uid())
  on conflict do nothing;
end;
$$;

create or replace function public.report_meguri_board_thread(
  p_thread_id uuid,
  p_reason text default 'user_report'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread(p_thread_id, auth.uid()) then
    return;
  end if;
  insert into public.meguri_board_reports (thread_id, reporter_id, reason)
  values (p_thread_id, auth.uid(), coalesce(nullif(btrim(p_reason), ''), 'user_report'));
end;
$$;

create or replace function public.report_meguri_board_reply(
  p_reply_id uuid,
  p_reason text default 'user_report'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_thread uuid;
begin
  select reply.thread_id into target_thread
  from public.meguri_board_replies reply
  where reply.id = p_reply_id;

  if target_thread is null or not public.can_view_meguri_board_thread(target_thread, auth.uid()) then
    return;
  end if;

  insert into public.meguri_board_reports (reply_id, reporter_id, reason)
  values (p_reply_id, auth.uid(), coalesce(nullif(btrim(p_reason), ''), 'user_report'));
end;
$$;

revoke all on function public.mark_meguri_board_thread_read(uuid) from public;
revoke all on function public.set_meguri_board_thread_bookmark(uuid, boolean) from public;
revoke all on function public.set_meguri_board_thread_reaction(uuid, boolean) from public;
revoke all on function public.set_meguri_board_reply_reaction(uuid, boolean) from public;
revoke all on function public.hide_meguri_board_thread(uuid) from public;
revoke all on function public.report_meguri_board_thread(uuid, text) from public;
revoke all on function public.report_meguri_board_reply(uuid, text) from public;

grant execute on function public.mark_meguri_board_thread_read(uuid) to authenticated;
grant execute on function public.set_meguri_board_thread_bookmark(uuid, boolean) to authenticated;
grant execute on function public.set_meguri_board_thread_reaction(uuid, boolean) to authenticated;
grant execute on function public.set_meguri_board_reply_reaction(uuid, boolean) to authenticated;
grant execute on function public.hide_meguri_board_thread(uuid) to authenticated;
grant execute on function public.report_meguri_board_thread(uuid, text) to authenticated;
grant execute on function public.report_meguri_board_reply(uuid, text) to authenticated;
