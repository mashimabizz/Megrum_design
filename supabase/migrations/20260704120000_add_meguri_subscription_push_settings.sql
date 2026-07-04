-- グルーム/チャットルームの「新着投稿」購読通知設定と、圏内判定用の
-- 最終位置（オプトイン時のみ更新）を追加する。
-- 通知の飛ばし方（推し・シリーズ一致／圏内）はユーザーごとの設定で、
-- groom_posts / meguri_board_threads の insert 時にファンアウトする。

-- ---------------------------------------------------------------------
-- 1. user_notification_settings へ購読設定と位置を追加
-- ---------------------------------------------------------------------

alter table public.user_notification_settings
  add column if not exists groom_oshi_push_enabled boolean not null default false,
  add column if not exists groom_nearby_push_enabled boolean not null default false,
  add column if not exists chatroom_oshi_push_enabled boolean not null default false,
  add column if not exists chatroom_nearby_push_enabled boolean not null default false,
  add column if not exists push_location_lat double precision,
  add column if not exists push_location_lng double precision,
  add column if not exists push_location_updated_at timestamptz;

comment on column public.user_notification_settings.groom_oshi_push_enabled is
  '自分の推し（グループ/メンバー）に一致するグルーム新着投稿を通知するか。';
comment on column public.user_notification_settings.groom_nearby_push_enabled is
  '圏内（約3km）のグルーム新着投稿を通知するか。push_location を基準にする。';
comment on column public.user_notification_settings.chatroom_oshi_push_enabled is
  '自分の推しに一致するチャットルーム新規スレッドを通知するか。';
comment on column public.user_notification_settings.chatroom_nearby_push_enabled is
  '圏内（約3km）のチャットルーム新規スレッドを通知するか。';
comment on column public.user_notification_settings.push_location_lat is
  '圏内通知の基準位置（緯度）。圏内通知オプトイン時のみアプリが更新する。';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'user_notification_settings_push_location_lat_range'
  ) then
    alter table public.user_notification_settings
      add constraint user_notification_settings_push_location_lat_range
      check (push_location_lat is null or (push_location_lat between -90 and 90));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'user_notification_settings_push_location_lng_range'
  ) then
    alter table public.user_notification_settings
      add constraint user_notification_settings_push_location_lng_range
      check (push_location_lng is null or (push_location_lng between -180 and 180));
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 2. notifications: 新kindと groom_post_id 参照
-- ---------------------------------------------------------------------

alter table public.notifications
  add column if not exists groom_post_id uuid references public.groom_posts(id) on delete cascade;

create index if not exists idx_notifications_groom_post
  on public.notifications(groom_post_id)
  where groom_post_id is not null;

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
      'groom_posted',
      'meguri_message',
      'meguri_board_reply',
      'meguri_board_mention',
      'meguri_board_posted',
      'admin_announcement'
    )
  );

comment on constraint notifications_kind_check on public.notifications is
  '通知種別。groom_posted / meguri_board_posted は購読設定（推し一致・圏内）による新着投稿通知。';

-- ---------------------------------------------------------------------
-- 3. グルーム新着投稿のファンアウト
--    ・推し一致: user_oshi の group_id / character_id と投稿メタデータの一致
--    ・圏内: push_location（7日以内更新）と投稿 origin の距離 3km 以内
--    ・自分の投稿・private 投稿は対象外。1投稿あたり最大500人で打ち切り。
-- ---------------------------------------------------------------------

create or replace function public.notify_groom_post_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status <> 'published' then
    return new;
  end if;
  if new.audience_scope not in ('encountered_people', 'same_area') then
    return new;
  end if;

  insert into public.notifications (user_id, kind, title, body, link_path, groom_post_id)
  select
    s.user_id,
    'groom_posted',
    case
      when oshi_matched.user_id is not null then '推しの新しいグルーム'
      else '近くで新しいグルーム'
    end,
    coalesce(nullif(btrim(new.caption), ''), 'グルームが投稿されました'),
    '/meguri',
    new.id
  from public.user_notification_settings s
  left join lateral (
    select uo.user_id
      from public.user_oshi uo
     where uo.user_id = s.user_id
       and (
         (new.character_id is not null and uo.character_id = new.character_id)
         or (new.group_id is not null and uo.group_id = new.group_id)
       )
     limit 1
  ) oshi_matched on true
  where s.user_id <> new.user_id
    and coalesce(s.push_enabled, true)
    and (
      (coalesce(s.groom_oshi_push_enabled, false) and oshi_matched.user_id is not null)
      or (
        coalesce(s.groom_nearby_push_enabled, false)
        and new.origin_lat is not null
        and new.origin_lng is not null
        and s.push_location_lat is not null
        and s.push_location_lng is not null
        and s.push_location_updated_at > now() - interval '7 days'
        and public.haversine_meters(
          new.origin_lat, new.origin_lng,
          s.push_location_lat, s.push_location_lng
        ) <= 3000
      )
    )
    and not exists (
      select 1
        from public.notifications existing
       where existing.user_id = s.user_id
         and existing.kind = 'groom_posted'
         and existing.groom_post_id = new.id
    )
  limit 500;

  return new;
end;
$$;

drop trigger if exists trg_groom_post_published_notify on public.groom_posts;
create trigger trg_groom_post_published_notify
  after insert on public.groom_posts
  for each row
  execute function public.notify_groom_post_published();

-- ---------------------------------------------------------------------
-- 4. チャットルーム新規スレッドのファンアウト（グルームと同じ条件系）
-- ---------------------------------------------------------------------

create or replace function public.notify_meguri_board_thread_posted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status not in ('visible', 'locked') then
    return new;
  end if;

  insert into public.notifications (user_id, kind, title, body, link_path, meguri_board_thread_id)
  select
    s.user_id,
    'meguri_board_posted',
    case
      when oshi_matched.user_id is not null then '推しの新しいチャットルーム'
      else '近くで新しいチャットルーム'
    end,
    coalesce(nullif(btrim(new.title), ''), 'チャットルームが作成されました'),
    '/meguri-board-thread?id=' || new.id::text,
    new.id
  from public.user_notification_settings s
  left join lateral (
    select uo.user_id
      from public.user_oshi uo
     where uo.user_id = s.user_id
       and (
         (new.character_id is not null and uo.character_id = new.character_id)
         or (new.group_id is not null and uo.group_id = new.group_id)
       )
     limit 1
  ) oshi_matched on true
  where s.user_id <> new.author_id
    and coalesce(s.push_enabled, true)
    and (
      (coalesce(s.chatroom_oshi_push_enabled, false) and oshi_matched.user_id is not null)
      or (
        coalesce(s.chatroom_nearby_push_enabled, false)
        and new.origin_lat is not null
        and new.origin_lng is not null
        and s.push_location_lat is not null
        and s.push_location_lng is not null
        and s.push_location_updated_at > now() - interval '7 days'
        and public.haversine_meters(
          new.origin_lat, new.origin_lng,
          s.push_location_lat, s.push_location_lng
        ) <= 3000
      )
    )
    and not exists (
      select 1
        from public.notifications existing
       where existing.user_id = s.user_id
         and existing.kind = 'meguri_board_posted'
         and existing.meguri_board_thread_id = new.id
    )
  limit 500;

  return new;
end;
$$;

drop trigger if exists trg_meguri_board_thread_posted_notify on public.meguri_board_threads;
create trigger trg_meguri_board_thread_posted_notify
  after insert on public.meguri_board_threads
  for each row
  execute function public.notify_meguri_board_thread_posted();
