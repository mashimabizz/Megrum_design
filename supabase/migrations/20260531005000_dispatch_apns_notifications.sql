-- =====================================================================
-- iter345: dispatch APNs notifications through Edge Function
-- =====================================================================
-- Swift Native iOS版のAPNs配送は秘密鍵をEdge Function secretsへ閉じ込める。
-- DB triggerは通知作成時に、プロジェクト側で設定済みの場合だけ
-- send-apns-notification Edge Functionへnotification_idを渡す。
--
-- Required DB settings on the target project:
--   app.settings.apns_dispatch_url
--   app.settings.apns_dispatch_secret
--
-- Example:
--   alter database postgres
--     set app.settings.apns_dispatch_url =
--       'https://<project-ref>.supabase.co/functions/v1/send-apns-notification';
--   alter database postgres
--     set app.settings.apns_dispatch_secret = '<random-dispatch-secret>';
-- =====================================================================

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
  apns_dispatch_url text;
  apns_dispatch_secret text;
  apns_device_count integer;
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
