-- =====================================================================
-- iter1226.415: 通知に右端サムネイル（対象コンテンツの画像）を持たせる
-- =====================================================================
-- 背景（iter1226.413 の残課題）:
--   Instagram型の通知行に「対象の画像」を右端に出したい。
--   goods-photos は公開バケット（安定した公開URL）だが、groom-posts /
--   meguri-board-media は非公開のため署名URLが必要で、URLを焼き込むと失効する。
--
-- 方針:
--   - 公開URLで済むもの（グッズ写真）→ thumbnail_url に焼き込み
--   - 非公開バケット（グルーム/ボード画像）→ thumbnail_bucket + thumbnail_path
--     を保存し、アプリが表示時に署名URLへ解決する
--   - サムネは呼び出し側からではなく、**中央ヘルパー内で参照IDから導出**する
--     （proposal_id → 提示グッズの写真、groom_reply/reaction/メッセージ → グルーム画像、
--      board_thread → 添付1枚目）。呼び出し側の変更ゼロ。

-- ---------------------------------------------------------------------
-- 1. 列追加
-- ---------------------------------------------------------------------
alter table public.notifications
  add column if not exists thumbnail_url text
    check (thumbnail_url is null or length(thumbnail_url) <= 1000),
  add column if not exists thumbnail_bucket text
    check (thumbnail_bucket is null or length(thumbnail_bucket) <= 100),
  add column if not exists thumbnail_path text
    check (thumbnail_path is null or length(thumbnail_path) <= 500);

comment on column public.notifications.thumbnail_url is
  '対象コンテンツの公開画像URL（goods-photos等の公開バケット由来。失効しない）';
comment on column public.notifications.thumbnail_bucket is
  '非公開バケットの画像のバケットID（groom-posts / meguri-board-media）。表示時に署名URLへ解決';
comment on column public.notifications.thumbnail_path is
  '非公開バケットの画像のオブジェクトパス';

-- ---------------------------------------------------------------------
-- 2. 導出ヘルパー
-- ---------------------------------------------------------------------

-- 取引系：打診の提示グッズ（相手が求める自分のグッズ→無ければ受け取るグッズ）の公開写真URL。
create or replace function public.megrum_notification_trade_thumbnail_url(p_proposal_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  with proposal as (
    select receiver_have_ids, sender_have_ids
      from public.proposals
     where id = p_proposal_id
  )
  select gi.photo_urls[1]
    from public.goods_inventory gi, proposal p
   where gi.id in (p.receiver_have_ids[1], p.sender_have_ids[1])
     and coalesce(array_length(gi.photo_urls, 1), 0) > 0
   order by case when gi.id = p.receiver_have_ids[1] then 0 else 1 end
   limit 1
$$;

-- グルーム画像パス（非公開 groom-posts バケット）。
create or replace function public.megrum_notification_groom_image_path(p_groom_post_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select nullif(btrim(post.image_path), '')
    from public.groom_posts post
   where post.id = p_groom_post_id
$$;

-- ---------------------------------------------------------------------
-- 3. 取引系中央ヘルパー：proposal からサムネURLを導出して保存
--    （20260710150000 の本体＋ thumbnail_url を追加）
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
    actor_avatar_url,
    thumbnail_url
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
         else left(public.megrum_notification_actor_avatar_url(p_actor_id), 1000) end,
    case when p_proposal_id is null then null
         else left(public.megrum_notification_trade_thumbnail_url(p_proposal_id), 1000) end
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
-- 4. めぐり系中央ヘルパー：参照IDからグルーム/ボード画像を導出して保存
--    （20260710150000 の本体＋ thumbnail_bucket/path を追加）
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
  v_groom_post_id uuid;
  v_thumbnail_bucket text;
  v_thumbnail_path text;
begin
  if p_user_id is null then
    return null;
  end if;

  if p_actor_id is not null and p_user_id = p_actor_id then
    return null;
  end if;

  -- 参照IDから対象グルームを辿り、画像パスをサムネとして焼き込む。
  v_groom_post_id := coalesce(
    (select reply.groom_post_id from public.groom_replies reply where reply.id = p_groom_reply_id),
    (select reaction.groom_post_id from public.groom_reactions reaction where reaction.id = p_groom_reaction_id),
    (select message.source_groom_post_id from public.meguri_messages message where message.id = p_meguri_message_id)
  );

  if v_groom_post_id is not null then
    v_thumbnail_path := public.megrum_notification_groom_image_path(v_groom_post_id);
    if v_thumbnail_path is not null then
      v_thumbnail_bucket := 'groom-posts';
    end if;
  elsif p_meguri_board_thread_id is not null then
    select nullif(btrim(thread.image_paths[1]), '')
      into v_thumbnail_path
      from public.meguri_board_threads thread
     where thread.id = p_meguri_board_thread_id;
    if v_thumbnail_path is not null then
      v_thumbnail_bucket := 'meguri-board-media';
    end if;
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
    actor_avatar_url,
    thumbnail_bucket,
    thumbnail_path
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
         else left(public.megrum_notification_actor_avatar_url(p_actor_id), 1000) end,
    left(v_thumbnail_bucket, 100),
    left(v_thumbnail_path, 500)
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
-- 5. 圏内グルーム新着：投稿画像をサムネとして焼き込む
--    （20260710150000 の本体＋ thumbnail 列を追加）
-- ---------------------------------------------------------------------
create or replace function public.notify_groom_post_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_image_path text;
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

  v_image_path := nullif(btrim(new.image_path), '');

  insert into public.notifications (
    user_id, kind, title, body, link_path, groom_post_id,
    actor_user_id, actor_display_name, actor_avatar_url,
    thumbnail_bucket, thumbnail_path
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
    left(public.megrum_notification_actor_avatar_url(new.user_id), 1000),
    case when v_image_path is null then null else 'groom-posts' end,
    left(v_image_path, 500)
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
-- 6. チャットルーム新着：添付1枚目をサムネとして焼き込む
--    （20260710150000 の本体＋ thumbnail 列を追加）
-- ---------------------------------------------------------------------
create or replace function public.notify_meguri_board_thread_posted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_image_path text;
begin
  if new.status not in ('visible', 'locked') then
    return new;
  end if;

  v_image_path := nullif(btrim(new.image_paths[1]), '');

  insert into public.notifications (
    user_id, kind, title, body, link_path, meguri_board_thread_id,
    actor_user_id, actor_display_name, actor_avatar_url,
    thumbnail_bucket, thumbnail_path
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
    left(public.megrum_notification_actor_avatar_url(new.author_id), 1000),
    case when v_image_path is null then null else 'meguri-board-media' end,
    left(v_image_path, 500)
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
