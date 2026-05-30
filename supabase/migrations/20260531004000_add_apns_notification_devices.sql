-- =====================================================================
-- iter338: native iOS APNs device registration
-- =====================================================================
-- Swift Native iOS版はExpo Push TokenではなくAPNs device tokenを取得する。
-- 既存のExpo配送経路を壊さず、notification_devicesへAPNs tokenも保存できる
-- 互換カラムを追加する。

alter table public.notification_devices
  add column if not exists push_provider text not null default 'expo'
    check (push_provider in ('expo', 'apns')),
  add column if not exists native_device_token text;

alter table public.notification_devices
  alter column expo_push_token drop not null;

alter table public.notification_devices
  drop constraint if exists notification_devices_expo_push_token_check;
alter table public.notification_devices
  drop constraint if exists notification_devices_expo_push_token_length;
alter table public.notification_devices
  drop constraint if exists notification_devices_native_device_token_length;
alter table public.notification_devices
  drop constraint if exists notification_devices_token_present;

alter table public.notification_devices
  add constraint notification_devices_expo_push_token_length
    check (expo_push_token is null or length(expo_push_token) between 20 and 512),
  add constraint notification_devices_native_device_token_length
    check (native_device_token is null or length(native_device_token) between 20 and 512),
  add constraint notification_devices_token_present
    check (expo_push_token is not null or native_device_token is not null);

create unique index if not exists idx_notification_devices_user_native_token
  on public.notification_devices(user_id, native_device_token)
  where native_device_token is not null;

comment on column public.notification_devices.push_provider is
  '端末通知の配送方式。Expo版は expo、Swift Native iOS版は apns。';

comment on column public.notification_devices.native_device_token is
  'Swift Native iOS版がAPNsから受け取るdevice token。';

comment on table public.notification_devices is
  'ユーザーのExpo Push TokenまたはAPNs device tokenを端末単位で保存し、モバイルプッシュ通知の配送先にする。';

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
     and device.revoked_at is null
     and device.push_provider = 'expo'
     and device.expo_push_token is not null;

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

-- =====================================================================
-- 完了
-- =====================================================================
