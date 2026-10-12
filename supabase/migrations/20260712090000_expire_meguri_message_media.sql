-- iter1226.462: めぐりメッセージの画像は送信から14日で有効期限切れ＝削除する。
-- テキストのやりとりは保持し続ける。クライアントは期限切れ画像を
-- 写真アイコンのプレースホルダで表示する（MeguriMessageMediaPolicy と日数を揃える）。
--
-- storage.objects への直接SQL削除はSupabaseにより禁止（Storage API必須）のため、
-- 実削除は Edge Function `expire-meguri-message-media`（service role）が行い、
-- この関数は pg_cron から net.http_post でそれを起動するだけにする。
-- URL・シークレットは APNs 配送（app.settings.apns_dispatch_url / apns_dispatch_secret）を
-- 流用し、関数名だけ置き換えて導出する（追加の手動設定を不要にするため）。

create or replace function public.expire_meguri_message_media()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  apns_dispatch_url text;
  dispatch_secret text;
  media_dispatch_url text;
begin
  apns_dispatch_url := nullif(current_setting('app.settings.apns_dispatch_url', true), '');
  dispatch_secret := nullif(current_setting('app.settings.apns_dispatch_secret', true), '');

  if apns_dispatch_url is null then
    return;
  end if;

  media_dispatch_url := replace(apns_dispatch_url, 'send-apns-notification', 'expire-meguri-message-media');
  if media_dispatch_url = apns_dispatch_url then
    return;
  end if;

  perform net.http_post(
    url := media_dispatch_url,
    headers := jsonb_build_object(
      'Accept', 'application/json',
      'Content-Type', 'application/json',
      'x-megrum-dispatch-secret', coalesce(dispatch_secret, '')
    ),
    body := jsonb_build_object('reason', 'scheduled'),
    timeout_milliseconds := 10000
  );
end
$$;

revoke all on function public.expire_meguri_message_media() from public, anon, authenticated;

-- 毎日 03:20 UTC に削除ジョブを回す（pg_cron が無い環境では静かにスキップ）。
do $$
begin
  begin
    create extension if not exists pg_cron with schema extensions;
  exception when others then
    null;
  end;

  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      perform cron.unschedule('expire-meguri-message-media');
    exception when others then
      null;
    end;

    begin
      perform cron.schedule(
        'expire-meguri-message-media',
        '20 3 * * *',
        'select public.expire_meguri_message_media();'
      );
    exception when others then
      null;
    end;
  end if;
end
$$;

-- 既存の期限切れぶんを即時反映する（ベストエフォート）。
select public.expire_meguri_message_media();
