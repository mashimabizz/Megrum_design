-- =====================================================================
-- iter1226.413: 通知に行為者（actor）を持たせる
-- =====================================================================
-- 背景（iter1226.408 の将来課題）:
--   通知センターのX/Instagram風刷新で「行為者アバター先頭・いいね集約」を
--   実現するには、通知行に「誰がやったか」が必要。
--
-- 方針:
--   - actor_user_id / actor_display_name / actor_avatar_url を追加
--   - 表示名・アバターは挿入時に非正規化（title が既に「◯◯さんから…」と
--     名前を焼き込んでいる方式に合わせる。JOIN・grants・RLSの複雑化を回避）
--   - 通知の挿入経路は4つ:
--       1. create_trade_notification（取引系の中央ヘルパー・p_actor_id 受領済み）
--       2. create_meguri_notification（めぐり系の中央ヘルパー・p_actor_id 受領済み）
--       3. notify_groom_post_published（圏内グルーム新着・直接insert）
--       4. notify_meguri_board_thread_posted（チャットルーム新着・直接insert）
--     1・2 は保存だけ追加、3・4 は投稿者を actor として焼き込む。
--   - 管理者アナウンス等 actor 不在の通知は null のまま（UIは種別アイコンに
--     フォールバック）。

-- ---------------------------------------------------------------------
-- 1. 列追加
-- ---------------------------------------------------------------------
alter table public.notifications
  add column if not exists actor_user_id uuid references public.users(id) on delete set null,
  add column if not exists actor_display_name text
    check (actor_display_name is null or length(actor_display_name) <= 60),
  add column if not exists actor_avatar_url text
    check (actor_avatar_url is null or length(actor_avatar_url) <= 1000);

comment on column public.notifications.actor_user_id is
  '通知を発生させたユーザー（いいねした人・打診した人など）。運営通知等は null';
comment on column public.notifications.actor_display_name is
  '挿入時点の行為者表示名スナップショット（title の名前焼き込みと同方式）';
comment on column public.notifications.actor_avatar_url is
  '挿入時点の行為者アバターURLスナップショット';

-- ---------------------------------------------------------------------
-- 2. 行為者アバター取得ヘルパー
-- ---------------------------------------------------------------------
create or replace function public.megrum_notification_actor_avatar_url(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select nullif(btrim(profile.avatar_url), '')
  from public.users profile
  where profile.id = p_user_id
$$;

-- ---------------------------------------------------------------------
-- 3. 取引系中央ヘルパー：actor を保存する（呼び出し側は不変）
--    （20260627003000 の最新本体＋ actor 列の保存を追加）
-- ---------------------------------------------------------------------
create or replace function public.create_trade_notification(
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_link_path text,
  p_proposal_id uuid default null,
  p_actor_id uuid default null,
  p_message_id uuid default null,
  p_evidence_photo_id uuid default null,
  p_evaluation_id uuid default null
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
    proposal_id,
    message_id,
    evidence_photo_id,
    evaluation_id,
    actor_user_id,
    actor_display_name,
    actor_avatar_url
  )
  select
    p_user_id,
    p_kind,
    left(coalesce(nullif(btrim(p_title), ''), '通知'), 100),
    case
      when p_body is null then null
      else left(p_body, 500)
    end,
    coalesce(nullif(btrim(p_link_path), ''), '/notifications'),
    p_proposal_id,
    p_message_id,
    p_evidence_photo_id,
    p_evaluation_id,
    p_actor_id,
    case when p_actor_id is null then null
         else left(public.megrum_notification_actor_name(p_actor_id), 60) end,
    case when p_actor_id is null then null
         else left(public.megrum_notification_actor_avatar_url(p_actor_id), 1000) end
  where not exists (
    select 1
    from public.notifications existing
    where existing.user_id = p_user_id
      and existing.kind = p_kind
      and (
        (p_message_id is not null and existing.message_id = p_message_id)
        or (p_evidence_photo_id is not null and existing.evidence_photo_id = p_evidence_photo_id)
        or (p_evaluation_id is not null and existing.evaluation_id = p_evaluation_id)
        or (
          p_message_id is null
          and p_evidence_photo_id is null
          and p_evaluation_id is null
          and p_proposal_id is not null
          and existing.proposal_id = p_proposal_id
        )
      )
  )
  returning id into v_notification_id;

  return v_notification_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. めぐり系中央ヘルパー：actor を保存する（呼び出し側は不変）
--    （20260627103000 の最新本体＋ actor 列の保存を追加）
-- ---------------------------------------------------------------------
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
    meguri_board_reply_id,
    actor_user_id,
    actor_display_name,
    actor_avatar_url
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
    p_meguri_board_reply_id,
    p_actor_id,
    case when p_actor_id is null then null
         else left(public.megrum_notification_actor_name(p_actor_id), 60) end,
    case when p_actor_id is null then null
         else left(public.megrum_notification_actor_avatar_url(p_actor_id), 1000) end
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

-- ---------------------------------------------------------------------
-- 5. 圏内グルーム新着：投稿者を actor として焼き込む
--    （20260708170000 の最新本体＋ actor 列を追加）
-- ---------------------------------------------------------------------
create or replace function public.notify_groom_post_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  if new.status <> 'published' then
    return new;
  end if;
  if new.audience_scope not in ('encountered_people', 'same_area') then
    return new;
  end if;

  v_group_id := coalesce(
    new.group_id,
    (select cm.group_id from public.characters_master cm where cm.id = new.character_id)
  );

  if v_group_id is null then
    return new;
  end if;

  insert into public.notifications (
    user_id, kind, title, body, link_path, groom_post_id,
    actor_user_id, actor_display_name, actor_avatar_url
  )
  select
    s.user_id,
    'groom_posted',
    '推しの近くの新しいグルーム',
    coalesce(nullif(btrim(new.caption), ''), 'グルームが投稿されました'),
    '/meguri',
    new.id,
    new.user_id,
    left(public.megrum_notification_actor_name(new.user_id), 60),
    left(public.megrum_notification_actor_avatar_url(new.user_id), 1000)
  from public.user_notification_settings s
  where s.user_id <> new.user_id
    and coalesce(s.push_enabled, true)
    and coalesce(s.groom_oshi_push_enabled, false)
    and new.origin_lat is not null
    and new.origin_lng is not null
    and s.push_location_lat is not null
    and s.push_location_lng is not null
    and s.push_location_updated_at > now() - interval '7 days'
    and public.haversine_meters(
      new.origin_lat, new.origin_lng,
      s.push_location_lat, s.push_location_lng
    ) <= 3000
    and exists (
      select 1
        from public.user_oshi uo
        left join public.user_groom_notify_prefs p
          on p.user_id = s.user_id and p.group_id = v_group_id
       where uo.user_id = s.user_id
         and uo.group_id = v_group_id
         and coalesce(p.enabled, true)
         and (
           not coalesce(p.members_only, false)
           or (
             new.character_id is not null
             and exists (
               select 1 from public.user_oshi uo2
                where uo2.user_id = s.user_id
                  and uo2.character_id = new.character_id
             )
           )
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

-- ---------------------------------------------------------------------
-- 6. チャットルーム新着：作成者を actor として焼き込む
--    （20260704120000 の最新本体＋ actor 列を追加）
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

  insert into public.notifications (
    user_id, kind, title, body, link_path, meguri_board_thread_id,
    actor_user_id, actor_display_name, actor_avatar_url
  )
  select
    s.user_id,
    'meguri_board_posted',
    case
      when oshi_matched.user_id is not null then '推しの新しいチャットルーム'
      else '近くで新しいチャットルーム'
    end,
    coalesce(nullif(btrim(new.title), ''), 'チャットルームが作成されました'),
    '/meguri-board-thread?id=' || new.id::text,
    new.id,
    new.author_id,
    left(public.megrum_notification_actor_name(new.author_id), 60),
    left(public.megrum_notification_actor_avatar_url(new.author_id), 1000)
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
