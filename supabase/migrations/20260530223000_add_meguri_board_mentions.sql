-- =====================================================================
-- iter175: Meguri board @mention notifications
-- =====================================================================
-- Mentions let a reply explicitly call another user into a thread by
-- typing @handle. Mentioned users receive a dedicated notification.

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
      'meguri_board_reply',
      'meguri_board_mention'
    )
  );

create or replace function public.meguri_board_mentioned_user_ids(p_body text)
returns table (user_id uuid)
language sql
stable
security definer
set search_path = public
as $$
  with mentioned_handles as (
    select distinct lower(hit.match[2]) as handle
    from regexp_matches(
      coalesce(p_body, ''),
      '(^|[^a-z0-9_])@([a-z0-9_]{3,20})',
      'gi'
    ) as hit(match)
    where hit.match[2] is not null
  )
  select profile.id
  from public.users profile
  join mentioned_handles handle_match
    on profile.handle = handle_match.handle;
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
    and subscription.user_id <> new.author_id
    and not exists (
      select 1
      from public.meguri_board_mentioned_user_ids(new.body) mentioned
      where mentioned.user_id = subscription.user_id
    );

  return new;
end;
$$;

create or replace function public.notify_meguri_board_reply_mentions()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  thread_scope text;
  reply_author_name text;
  link_scope text;
begin
  select thread.audience_scope
    into thread_scope
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
    mentioned.user_id,
    'meguri_board_mention',
    '返信でメンションされました',
    left(coalesce(reply_author_name, 'めぐりユーザー') || ': ' || btrim(new.body), 180),
    '/meguri-board-thread?id=' || new.thread_id::text || '&viewMode=' || link_scope,
    new.thread_id,
    new.id
  from public.meguri_board_mentioned_user_ids(new.body) mentioned
  where mentioned.user_id <> new.author_id
    and public.can_view_meguri_board_thread(new.thread_id, mentioned.user_id);

  return new;
end;
$$;

drop trigger if exists trg_meguri_board_reply_notify_mentions
  on public.meguri_board_replies;
create trigger trg_meguri_board_reply_notify_mentions
  after insert on public.meguri_board_replies
  for each row execute function public.notify_meguri_board_reply_mentions();

revoke all on function public.meguri_board_mentioned_user_ids(text) from public;

grant execute on function public.meguri_board_mentioned_user_ids(text) to authenticated;
