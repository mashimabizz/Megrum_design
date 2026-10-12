-- iter1226.427: APNsプッシュ配送の設定をGUCから専用テーブルへ移す。
--
-- send_mobile_push_for_notification は app.settings.apns_dispatch_url /
-- apns_dispatch_secret の GUC を読む設計だったが、マネージドPostgresでは
-- ALTER DATABASE/ROLE ... SET が permission denied となり永続設定できない。
-- そのため APNs 分岐が一度も発火せず、モバイルプッシュが全く届いていなかった。
--
-- 対応：SECURITY DEFINER（postgres所有）のトリガー関数だけが読める
-- private.app_config テーブルに移す。シークレット値はマイグレーションに
-- 含めず、運用側で直接 INSERT する（README方針どおりソース管理に残さない）。

create schema if not exists private;

create table if not exists private.app_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

revoke all on schema private from public, anon, authenticated;
revoke all on private.app_config from public, anon, authenticated;

create or replace function private.app_config_value(config_key text)
returns text
language sql
security definer set search_path = private
as $$
  select value from private.app_config where key = config_key
$$;

revoke all on function private.app_config_value(text) from public, anon, authenticated;

-- 既存トリガー関数の GUC 読みを app_config 読みへ差し替える（他は不変）。
create or replace function public.send_mobile_push_for_notification()
returns trigger
language plpgsql
security definer set search_path = public, net, private
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

  -- iter1226.427: GUC ではなく private.app_config から読む。
  apns_dispatch_url := private.app_config_value('apns_dispatch_url');
  apns_dispatch_secret := private.app_config_value('apns_dispatch_secret');

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
