-- iter1226.428: APNs配送のpg_netタイムアウトを3秒→8秒へ。
-- Edge Functionのコールドスタート＋複数端末への逐次送信で3秒を超え、
-- net._http_response にタイムアウトが記録されていた（送信自体は完了するが
-- 早期打ち切りのリスクを避ける）。timeout_milliseconds のみの変更。
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

  -- iter1226.428: 旧Expo送信レグは廃止（全端末がAPNs・Expo行はrevoke済み）。

  select count(*)::integer
    into apns_device_count
    from public.notification_devices device
   where device.user_id = new.user_id
     and device.revoked_at is null
     and device.push_provider = 'apns'
     and device.native_device_token is not null;

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
      timeout_milliseconds := 8000
    );
  end if;

  return new;
end;
$$;
