-- =====================================================================
-- iter174: Meguri board thread subscriptions and reply notifications
-- =====================================================================
-- Adds watch-style subscriptions for board threads. Thread authors and
-- reply authors are automatically subscribed, and subscribers receive a
-- notification when another user replies.

alter table public.notifications
  add column if not exists meguri_board_thread_id uuid references public.meguri_board_threads(id) on delete cascade,
  add column if not exists meguri_board_reply_id uuid references public.meguri_board_replies(id) on delete cascade;

create index if not exists idx_notifications_meguri_board_thread
  on public.notifications(meguri_board_thread_id, created_at desc)
  where meguri_board_thread_id is not null;

create index if not exists idx_notifications_meguri_board_reply
  on public.notifications(meguri_board_reply_id)
  where meguri_board_reply_id is not null;

alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'proposal_received',
      'proposal_accepted',
      'proposal_rejected',
      'proposal_revised',
      'evidence_added',
      'trade_completed',
      'evaluation_received',
      'dispute_received',
      'dispute_responded',
      'dispute_closed',
      'cancel_requested',
      'expires_soon',
      'groom_reply',
      'meguri_message',
      'meguri_board_reply'
    )
  );

create table if not exists public.meguri_board_thread_subscriptions (
  thread_id uuid not null references public.meguri_board_threads(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  notification_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (thread_id, user_id)
);

create index if not exists idx_meguri_board_thread_subscriptions_user
  on public.meguri_board_thread_subscriptions(user_id, notification_enabled, updated_at desc);

create index if not exists idx_meguri_board_thread_subscriptions_thread_enabled
  on public.meguri_board_thread_subscriptions(thread_id, user_id)
  where notification_enabled;

alter table public.meguri_board_thread_subscriptions enable row level security;

drop policy if exists "Users can read own meguri board subscriptions"
  on public.meguri_board_thread_subscriptions;
create policy "Users can read own meguri board subscriptions"
  on public.meguri_board_thread_subscriptions for select
  using (auth.uid() = user_id);

drop policy if exists "Users can manage own meguri board subscriptions"
  on public.meguri_board_thread_subscriptions;
create policy "Users can manage own meguri board subscriptions"
  on public.meguri_board_thread_subscriptions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop trigger if exists trg_meguri_board_thread_subscriptions_updated_at
  on public.meguri_board_thread_subscriptions;
create trigger trg_meguri_board_thread_subscriptions_updated_at
  before update on public.meguri_board_thread_subscriptions
  for each row execute function public.set_updated_at();

create or replace function public.set_meguri_board_thread_subscription(
  p_thread_id uuid,
  p_enabled boolean default true
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return;
  end if;

  if not exists (
    select 1
    from public.meguri_board_threads thread
    where thread.id = p_thread_id
      and thread.status in ('visible', 'locked')
  ) then
    return;
  end if;

  insert into public.meguri_board_thread_subscriptions (
    thread_id,
    user_id,
    notification_enabled
  )
  values (
    p_thread_id,
    auth.uid(),
    coalesce(p_enabled, true)
  )
  on conflict (thread_id, user_id)
  do update
     set notification_enabled = excluded.notification_enabled,
         updated_at = now();
end;
$$;

create or replace function public.auto_subscribe_meguri_board_thread_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.meguri_board_thread_subscriptions (
    thread_id,
    user_id,
    notification_enabled
  )
  values (new.id, new.author_id, true)
  on conflict (thread_id, user_id)
  do update
     set notification_enabled = true,
         updated_at = now();

  return new;
end;
$$;

create or replace function public.notify_meguri_board_reply_subscribers()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  thread_title text;
  thread_scope text;
  reply_author_name text;
  link_scope text;
begin
  insert into public.meguri_board_thread_subscriptions (
    thread_id,
    user_id,
    notification_enabled
  )
  values (new.thread_id, new.author_id, true)
  on conflict (thread_id, user_id)
  do update
     set notification_enabled = true,
         updated_at = now();

  select
    thread.title,
    thread.audience_scope
  into thread_title, thread_scope
  from public.meguri_board_threads thread
  where thread.id = new.thread_id;

  select coalesce(nullif(btrim(profile.display_name), ''), nullif(btrim(profile.handle), ''), 'めぐりユーザー')
    into reply_author_name
  from public.users profile
  where profile.id = new.author_id;

  link_scope := case
    when thread_scope in ('same_prefecture', 'global') then 'same_prefecture'
    else 'nearby_3km'
  end;

  insert into public.notifications (
    user_id,
    kind,
    title,
    body,
    link_path,
    meguri_board_thread_id,
    meguri_board_reply_id
  )
  select
    subscription.user_id,
    'meguri_board_reply',
    '購読中のスレッドに返信がありました',
    left(coalesce(reply_author_name, 'めぐりユーザー') || ': ' || btrim(new.body), 180),
    '/meguri-board-thread?id=' || new.thread_id::text || '&viewMode=' || link_scope,
    new.thread_id,
    new.id
  from public.meguri_board_thread_subscriptions subscription
  where subscription.thread_id = new.thread_id
    and subscription.notification_enabled
    and subscription.user_id <> new.author_id;

  return new;
end;
$$;

drop trigger if exists trg_meguri_board_thread_auto_subscribe
  on public.meguri_board_threads;
create trigger trg_meguri_board_thread_auto_subscribe
  after insert on public.meguri_board_threads
  for each row execute function public.auto_subscribe_meguri_board_thread_author();

drop trigger if exists trg_meguri_board_reply_notify_subscribers
  on public.meguri_board_replies;
create trigger trg_meguri_board_reply_notify_subscribers
  after insert on public.meguri_board_replies
  for each row execute function public.notify_meguri_board_reply_subscribers();

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

revoke all on function public.set_meguri_board_thread_subscription(uuid, boolean) from public;
revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;

grant execute on function public.set_meguri_board_thread_subscription(uuid, boolean) to authenticated;
grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;
