-- =====================================================================
-- iter1226.14: Meguri notification events and category push settings
-- =====================================================================
-- Meguri notifications are always written to public.notifications for the
-- in-app notification center. user_notification_settings controls only OS
-- push delivery.

alter table public.user_notification_settings
  add column if not exists groom_activity_push_enabled boolean not null default true,
  add column if not exists chatroom_activity_push_enabled boolean not null default true;

comment on column public.user_notification_settings.groom_activity_push_enabled is
  'グルームのいいね・グルーム経由メッセージを端末プッシュするか。アプリ内通知行は常に残す。';

comment on column public.user_notification_settings.chatroom_activity_push_enabled is
  'チャットルームの投稿・返信を端末プッシュするか。アプリ内通知行は常に残す。';

alter table public.notifications
  add column if not exists groom_reaction_id uuid references public.groom_reactions(id) on delete cascade;

create index if not exists idx_notifications_groom_reaction
  on public.notifications(groom_reaction_id)
  where groom_reaction_id is not null;

alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'proposal_received',
      'proposal_accepted',
      'proposal_rejected',
      'proposal_revised',
      'message_received',
      'evidence_added',
      'trade_completed',
      'evaluation_received',
      'dispute_received',
      'dispute_responded',
      'dispute_closed',
      'cancel_requested',
      'expires_soon',
      'groom_liked',
      'groom_reply',
      'meguri_message',
      'meguri_board_reply',
      'meguri_board_mention',
      'admin_announcement'
    )
  );

comment on constraint notifications_kind_check on public.notifications is
  '通知種別。Meguriはgroom_liked/groom_reply/meguri_message/meguri_board_reply/meguri_board_mentionを使う。';

create or replace function public.create_meguri_notification(
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_link_path text,
  p_groom_reply_id uuid default null,
  p_groom_reaction_id uuid default null,
  p_meguri_message_id uuid default null,
  p_meguri_board_thread_id uuid default null,
  p_meguri_board_reply_id uuid default null,
  p_actor_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_notification_id uuid;
begin
  if p_user_id is null then
    return null;
  end if;

  if p_actor_id is not null and p_user_id = p_actor_id then
    return null;
  end if;

  insert into public.notifications (
    user_id,
    kind,
    title,
    body,
    link_path,
    groom_reply_id,
    groom_reaction_id,
    meguri_message_id,
    meguri_board_thread_id,
    meguri_board_reply_id
  )
  select
    p_user_id,
    p_kind,
    left(coalesce(nullif(btrim(p_title), ''), '通知'), 100),
    case
      when p_body is null then null
      else left(nullif(btrim(p_body), ''), 500)
    end,
    coalesce(nullif(btrim(p_link_path), ''), '/notifications'),
    p_groom_reply_id,
    p_groom_reaction_id,
    p_meguri_message_id,
    p_meguri_board_thread_id,
    p_meguri_board_reply_id
  where not exists (
    select 1
      from public.notifications existing
     where existing.user_id = p_user_id
       and existing.kind = p_kind
       and (
         (p_groom_reply_id is not null and existing.groom_reply_id = p_groom_reply_id)
         or (p_groom_reaction_id is not null and existing.groom_reaction_id = p_groom_reaction_id)
         or (p_meguri_message_id is not null and existing.meguri_message_id = p_meguri_message_id)
         or (p_meguri_board_reply_id is not null and existing.meguri_board_reply_id = p_meguri_board_reply_id)
       )
  )
  returning id into v_notification_id;

  return v_notification_id;
end;
$$;

create or replace function public.notify_groom_like_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
  v_actor_name text;
begin
  if new.reaction_type <> 'like' then
    return new;
  end if;

  select post.user_id
    into v_owner_id
    from public.groom_posts post
   where post.id = new.groom_post_id;

  if v_owner_id is null or v_owner_id = new.user_id then
    return new;
  end if;

  v_actor_name := coalesce(public.megrum_notification_actor_name(new.user_id), '相手');

  perform public.create_meguri_notification(
    v_owner_id,
    'groom_liked',
    v_actor_name || 'さんからいいねされました！',
    null,
    '/grooms/' || new.groom_post_id::text,
    null,
    new.id,
    null,
    null,
    null,
    new.user_id
  );

  return new;
end;
$$;

drop trigger if exists trg_groom_reaction_like_notify
  on public.groom_reactions;
create trigger trg_groom_reaction_like_notify
  after insert on public.groom_reactions
  for each row execute function public.notify_groom_like_insert();

create or replace function public.notify_groom_reply_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_name text;
begin
  v_actor_name := coalesce(public.megrum_notification_actor_name(new.sender_id), '相手');

  perform public.create_meguri_notification(
    new.recipient_id,
    'groom_reply',
    v_actor_name || 'さんからメッセージが届きました！',
    null,
    '/meguri-messages?open=1&userId=' || new.sender_id::text,
    new.id,
    null,
    null,
    null,
    null,
    new.sender_id
  );

  return new;
end;
$$;

drop trigger if exists trg_groom_reply_insert_notify
  on public.groom_replies;
create trigger trg_groom_reply_insert_notify
  after insert on public.groom_replies
  for each row execute function public.notify_groom_reply_insert();

create or replace function public.notify_meguri_message_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_name text;
begin
  if new.source_groom_reply_id is not null then
    return new;
  end if;

  v_actor_name := coalesce(public.megrum_notification_actor_name(new.sender_id), '相手');

  perform public.create_meguri_notification(
    new.recipient_id,
    'meguri_message',
    v_actor_name || 'さんからメッセージが届きました！',
    null,
    '/meguri-messages?open=1&userId=' || new.sender_id::text,
    null,
    null,
    new.id,
    null,
    null,
    new.sender_id
  );

  return new;
end;
$$;

drop trigger if exists trg_meguri_message_insert_notify
  on public.meguri_messages;
create trigger trg_meguri_message_insert_notify
  after insert on public.meguri_messages
  for each row execute function public.notify_meguri_message_insert();

create or replace function public.notify_meguri_board_reply_subscribers()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  thread_scope text;
  thread_author_id uuid;
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
    thread.audience_scope,
    thread.author_id
  into thread_scope, thread_author_id
  from public.meguri_board_threads thread
  where thread.id = new.thread_id;

  link_scope := case
    when thread_scope in ('same_prefecture', 'global') then 'same_prefecture'
    else 'nearby_3km'
  end;

  perform public.create_meguri_notification(
    subscription.user_id,
    'meguri_board_reply',
    case
      when subscription.user_id = thread_author_id then 'チャットルームに投稿されました'
      else 'チャットルームに新しい投稿がありました'
    end,
    null,
    '/meguri-board-thread?id=' || new.thread_id::text || '&viewMode=' || link_scope,
    null,
    null,
    null,
    new.thread_id,
    new.id,
    new.author_id
  )
  from public.meguri_board_thread_subscriptions subscription
  where subscription.thread_id = new.thread_id
    and subscription.notification_enabled
    and subscription.user_id <> new.author_id
    and public.can_view_meguri_board_thread(new.thread_id, subscription.user_id)
    and not exists (
      select 1 from public.groom_user_blocks block
      where (
        block.blocker_id = subscription.user_id
        and block.blocked_id = new.author_id
      )
      or (
        block.blocker_id = new.author_id
        and block.blocked_id = subscription.user_id
      )
    )
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
  link_scope text;
begin
  select thread.audience_scope
    into thread_scope
  from public.meguri_board_threads thread
  where thread.id = new.thread_id;

  link_scope := case
    when thread_scope in ('same_prefecture', 'global') then 'same_prefecture'
    else 'nearby_3km'
  end;

  perform public.create_meguri_notification(
    mentioned.user_id,
    'meguri_board_mention',
    'チャットルームで返信が届きました',
    null,
    '/meguri-board-thread?id=' || new.thread_id::text || '&viewMode=' || link_scope,
    null,
    null,
    null,
    new.thread_id,
    new.id,
    new.author_id
  )
  from public.meguri_board_mentioned_user_ids(new.body) mentioned
  where mentioned.user_id <> new.author_id
    and public.can_view_meguri_board_thread(new.thread_id, mentioned.user_id)
    and not exists (
      select 1 from public.groom_user_blocks block
      where (
        block.blocker_id = mentioned.user_id
        and block.blocked_id = new.author_id
      )
      or (
        block.blocker_id = new.author_id
        and block.blocked_id = mentioned.user_id
      )
    );

  return new;
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
  else
    delete from public.meguri_board_thread_reactions
    where thread_id = p_thread_id and user_id = auth.uid();
  end if;
end;
$$;

create or replace function public.send_mobile_push_for_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  push_enabled boolean := true;
  groom_activity_push_enabled boolean := true;
  chatroom_activity_push_enabled boolean := true;
  unread_count integer;
  push_payload jsonb;
  apns_dispatch_url text;
  apns_dispatch_secret text;
  apns_device_count integer;
begin
  select
    coalesce(settings.push_enabled, true),
    coalesce(settings.groom_activity_push_enabled, true),
    coalesce(settings.chatroom_activity_push_enabled, true)
  into
    push_enabled,
    groom_activity_push_enabled,
    chatroom_activity_push_enabled
  from public.user_notification_settings settings
  where settings.user_id = new.user_id;

  if coalesce(push_enabled, true) is false then
    return new;
  end if;

  if new.kind in ('groom_liked', 'groom_reply', 'meguri_message')
     and coalesce(groom_activity_push_enabled, true) is false then
    return new;
  end if;

  if new.kind in ('meguri_board_reply', 'meguri_board_mention')
     and coalesce(chatroom_activity_push_enabled, true) is false then
    return new;
  end if;

  select count(*)::integer
    into unread_count
    from public.notifications
   where user_id = new.user_id
     and read_at is null;

  select jsonb_agg(
    jsonb_build_object(
      'to', device.expo_push_token,
      'sound', 'default',
      'title', new.title,
      'body', coalesce(new.body, ''),
      'badge', unread_count,
      'data', jsonb_build_object(
        'notificationId', new.id::text,
        'linkPath', coalesce(new.link_path, '/notifications')
      )
    )
  )
    into push_payload
    from public.notification_devices device
   where device.user_id = new.user_id
     and device.revoked_at is null
     and device.push_provider = 'expo'
     and device.expo_push_token is not null;

  if push_payload is not null then
    perform net.http_post(
      url := 'https://exp.host/--/api/v2/push/send',
      headers := jsonb_build_object(
        'Accept', 'application/json',
        'Content-Type', 'application/json'
      ),
      body := push_payload,
      timeout_milliseconds := 3000
    );
  end if;

  select count(*)::integer
    into apns_device_count
    from public.notification_devices device
   where device.user_id = new.user_id
     and device.revoked_at is null
     and device.push_provider = 'apns'
     and device.native_device_token is not null;

  apns_dispatch_url := nullif(current_setting('app.settings.apns_dispatch_url', true), '');
  apns_dispatch_secret := nullif(current_setting('app.settings.apns_dispatch_secret', true), '');

  if apns_device_count > 0
     and apns_dispatch_url is not null
     and apns_dispatch_secret is not null then
    perform net.http_post(
      url := apns_dispatch_url,
      headers := jsonb_build_object(
        'Accept', 'application/json',
        'Content-Type', 'application/json',
        'x-megrum-dispatch-secret', apns_dispatch_secret
      ),
      body := jsonb_build_object('notification_id', new.id::text),
      timeout_milliseconds := 3000
    );
  end if;

  return new;
end;
$$;

-- =====================================================================
-- 完了
-- =====================================================================
