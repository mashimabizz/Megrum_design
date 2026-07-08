-- FB(iter1226.390): グルーム通知を「自分のリアルタイム1km圏内 かつ 同一推し」に変更する。
-- ・検知はクライアント側（現在地）で行うため、投稿時サーバファンアウトは無効化する。
-- ・圏内で推し一致したグルームは「遭遇(encounter)」として記録し、プレミアムなら圏外でも閲覧可にする。
-- ・推しごと設定にメンバー個別選択（notify_all_members / member_character_ids）を追加。

-- ---------------------------------------------------------------------
-- 1. 遭遇記録（1km圏内 かつ 推し一致で記録。通知の有無に関わらず）
-- ---------------------------------------------------------------------

create table if not exists public.groom_encounters (
  user_id uuid not null references auth.users(id) on delete cascade,
  groom_post_id uuid not null references public.groom_posts(id) on delete cascade,
  encountered_at timestamptz not null default now(),
  primary key (user_id, groom_post_id)
);

comment on table public.groom_encounters is
  '自分の1km圏内で自分の推しに一致したグルームの遭遇記録。プレミアムの圏外閲覧判定に使う。';

create index if not exists idx_groom_encounters_user on public.groom_encounters(user_id);

alter table public.groom_encounters enable row level security;

drop policy if exists groom_encounters_select_own on public.groom_encounters;
create policy groom_encounters_select_own
  on public.groom_encounters for select using (user_id = auth.uid());

drop policy if exists groom_encounters_insert_own on public.groom_encounters;
create policy groom_encounters_insert_own
  on public.groom_encounters for insert with check (user_id = auth.uid());

drop policy if exists groom_encounters_delete_own on public.groom_encounters;
create policy groom_encounters_delete_own
  on public.groom_encounters for delete using (user_id = auth.uid());

grant select, insert, delete on public.groom_encounters to authenticated;

-- ---------------------------------------------------------------------
-- 2. 推しごと通知設定：メンバー個別選択を追加
--    notify_all_members = true  → グループ全体（メンバー未設定の投稿も含む）
--    notify_all_members = false → member_character_ids に含まれる投稿のみ
-- ---------------------------------------------------------------------

alter table public.user_groom_notify_prefs
  add column if not exists notify_all_members boolean not null default true,
  add column if not exists member_character_ids uuid[] not null default '{}';

-- ---------------------------------------------------------------------
-- 3. 投稿時サーバファンアウトは無効化（クライアント側リアルタイム検知に移行）
-- ---------------------------------------------------------------------

create or replace function public.notify_groom_post_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- クライアントが現在地1km圏内で検知して通知/遭遇記録するため、ここでは何もしない。
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 4. 遭遇済みフラグをフィードRPCに追加（viewer_was_notified は互換のため残す）
-- ---------------------------------------------------------------------

drop function if exists public.list_groom_feed_nearby(double precision, double precision, integer);
create function public.list_groom_feed_nearby(
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_radius_m integer default 1000
)
returns table (
  id uuid,
  user_id uuid,
  image_url text,
  image_path text,
  caption text,
  status text,
  audience_scope text,
  area_key text,
  place_hint text,
  image_transform jsonb,
  text_overlays jsonb,
  stickers jsonb,
  doodles jsonb,
  published_at timestamptz,
  expires_at timestamptz,
  origin_lat double precision,
  origin_lng double precision,
  group_id uuid,
  character_id uuid,
  series_name text,
  distance_m double precision,
  like_count integer,
  viewer_has_liked boolean,
  viewer_was_notified boolean,
  viewer_encountered boolean,
  author_id uuid,
  author_display_name text,
  author_handle text,
  author_avatar_url text,
  author_primary_area text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    gp.id,
    gp.user_id,
    gp.image_url,
    gp.image_path,
    gp.caption,
    gp.status,
    gp.audience_scope,
    gp.area_key,
    gp.place_hint,
    gp.image_transform,
    gp.text_overlays,
    gp.stickers,
    gp.doodles,
    gp.published_at,
    gp.expires_at,
    gp.origin_lat,
    gp.origin_lng,
    gp.group_id,
    gp.character_id,
    gp.series_name,
    public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng) as distance_m,
    (
      select count(*)::integer from public.groom_reactions reaction
       where reaction.groom_post_id = gp.id and reaction.reaction_type = 'like'
    ) as like_count,
    exists (
      select 1 from public.groom_reactions viewer_reaction
       where viewer_reaction.groom_post_id = gp.id
         and viewer_reaction.reaction_type = 'like'
         and viewer_reaction.user_id = auth.uid()
    ) as viewer_has_liked,
    exists (
      select 1 from public.notifications viewer_notif
       where viewer_notif.groom_post_id = gp.id
         and viewer_notif.kind = 'groom_posted'
         and viewer_notif.user_id = auth.uid()
    ) as viewer_was_notified,
    exists (
      select 1 from public.groom_encounters enc
       where enc.groom_post_id = gp.id and enc.user_id = auth.uid()
    ) as viewer_encountered,
    u.id as author_id,
    u.display_name as author_display_name,
    u.handle as author_handle,
    u.avatar_url as author_avatar_url,
    u.primary_area as author_primary_area
  from public.groom_posts gp
  join public.users u on u.id = gp.user_id
  where auth.uid() is not null
    and gp.status = 'published'
    and gp.expires_at > now()
    and not exists (
      select 1 from public.groom_hidden_posts hidden
      where hidden.user_id = auth.uid() and hidden.groom_post_id = gp.id
    )
    and not exists (
      select 1 from public.groom_user_blocks blocks
      where (blocks.blocker_id = auth.uid() and blocks.blocked_id = gp.user_id)
         or (blocks.blocker_id = gp.user_id and blocks.blocked_id = auth.uid())
    )
    and (
      gp.user_id = auth.uid()
      or (
        p_viewer_lat is not null and p_viewer_lng is not null
        and gp.origin_lat is not null and gp.origin_lng is not null
        and public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng)
          <= least(greatest(coalesce(p_radius_m, 1000), 100), 100000)
      )
    )
  order by
    case when gp.user_id = auth.uid() then 0 else 1 end,
    distance_m nulls last,
    gp.published_at desc
  limit 300;
end;
$$;

revoke all on function public.list_groom_feed_nearby(double precision, double precision, integer) from public;
grant execute on function public.list_groom_feed_nearby(double precision, double precision, integer) to authenticated;

-- ---------------------------------------------------------------------
-- 5. 単一グルーム取得（プッシュのディープリンク用。距離条件なし・可視性は担保）
-- ---------------------------------------------------------------------

create or replace function public.get_groom_feed_item(p_groom_id uuid)
returns table (
  id uuid,
  user_id uuid,
  image_url text,
  image_path text,
  caption text,
  status text,
  audience_scope text,
  area_key text,
  place_hint text,
  image_transform jsonb,
  text_overlays jsonb,
  stickers jsonb,
  doodles jsonb,
  published_at timestamptz,
  expires_at timestamptz,
  origin_lat double precision,
  origin_lng double precision,
  group_id uuid,
  character_id uuid,
  series_name text,
  distance_m double precision,
  like_count integer,
  viewer_has_liked boolean,
  viewer_was_notified boolean,
  viewer_encountered boolean,
  author_id uuid,
  author_display_name text,
  author_handle text,
  author_avatar_url text,
  author_primary_area text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    gp.id, gp.user_id, gp.image_url, gp.image_path, gp.caption, gp.status,
    gp.audience_scope, gp.area_key, gp.place_hint, gp.image_transform,
    gp.text_overlays, gp.stickers, gp.doodles, gp.published_at, gp.expires_at,
    gp.origin_lat, gp.origin_lng, gp.group_id, gp.character_id, gp.series_name,
    null::double precision as distance_m,
    (
      select count(*)::integer from public.groom_reactions reaction
       where reaction.groom_post_id = gp.id and reaction.reaction_type = 'like'
    ) as like_count,
    exists (
      select 1 from public.groom_reactions viewer_reaction
       where viewer_reaction.groom_post_id = gp.id
         and viewer_reaction.reaction_type = 'like'
         and viewer_reaction.user_id = auth.uid()
    ) as viewer_has_liked,
    exists (
      select 1 from public.notifications viewer_notif
       where viewer_notif.groom_post_id = gp.id
         and viewer_notif.kind = 'groom_posted'
         and viewer_notif.user_id = auth.uid()
    ) as viewer_was_notified,
    exists (
      select 1 from public.groom_encounters enc
       where enc.groom_post_id = gp.id and enc.user_id = auth.uid()
    ) as viewer_encountered,
    u.id, u.display_name, u.handle, u.avatar_url, u.primary_area
  from public.groom_posts gp
  join public.users u on u.id = gp.user_id
  where gp.id = p_groom_id
    and auth.uid() is not null
    and gp.status = 'published'
    and gp.expires_at > now()
    and not exists (
      select 1 from public.groom_user_blocks blocks
      where (blocks.blocker_id = auth.uid() and blocks.blocked_id = gp.user_id)
         or (blocks.blocker_id = gp.user_id and blocks.blocked_id = auth.uid())
    )
  limit 1;
end;
$$;

revoke all on function public.get_groom_feed_item(uuid) from public;
grant execute on function public.get_groom_feed_item(uuid) to authenticated;
