-- =====================================================================
-- iter276: mobile push notifications
-- =====================================================================
-- Expo Push Token を端末ごとに保存し、notifications 行の INSERT を
-- Expo Push API へ配送する。

create extension if not exists pg_net with schema extensions;

alter table public.user_notification_settings
  add column if not exists push_enabled boolean not null default true;

comment on column public.user_notification_settings.push_enabled is
  'iOS/Android のモバイルプッシュ通知を受け取るか。アプリ内通知一覧は常時ON。';

create table if not exists public.notification_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('ios', 'android', 'web')),
  expo_push_token text not null check (length(expo_push_token) between 20 and 512),
  app_version text,
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, expo_push_token)
);

create trigger trg_notification_devices_updated_at
  before update on public.notification_devices
  for each row execute function public.set_updated_at();

create index if not exists idx_notification_devices_active_user
  on public.notification_devices(user_id, last_seen_at desc)
  where revoked_at is null;

comment on table public.notification_devices is
  'ユーザーのExpo Push Tokenを端末単位で保存し、モバイルプッシュ通知の配送先にする。';

alter table public.notification_devices enable row level security;

create policy "Users manage own notification devices"
  on public.notification_devices for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.send_mobile_push_for_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  push_enabled boolean;
  unread_count integer;
  push_payload jsonb;
begin
  select coalesce(settings.push_enabled, true)
    into push_enabled
    from public.user_notification_settings settings
   where settings.user_id = new.user_id;

  if coalesce(push_enabled, true) is false then
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
     and device.revoked_at is null;

  if push_payload is null then
    return new;
  end if;

  perform net.http_post(
    url := 'https://exp.host/--/api/v2/push/send',
    headers := jsonb_build_object(
      'Accept', 'application/json',
      'Content-Type', 'application/json'
    ),
    body := push_payload,
    timeout_milliseconds := 3000
  );

  return new;
end;
$$;

drop trigger if exists trg_send_mobile_push_for_notification
  on public.notifications;

create trigger trg_send_mobile_push_for_notification
  after insert on public.notifications
  for each row execute function public.send_mobile_push_for_notification();

-- =====================================================================
-- 完了
-- =====================================================================
