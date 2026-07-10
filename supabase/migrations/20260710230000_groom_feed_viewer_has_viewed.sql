-- iter1226.443: グルームの「自分が閲覧済みか」をフィードRPCで返す。
-- これまで既読状態はクライアントのメモリにしか無く（groom_views への書き込みのみ）、
-- アプリ再起動後に既読グルームのレール枠がグラデ（未読扱い）へ戻っていた。
-- 定義本体は 20260709120000 の最新版を踏襲し、viewer_has_viewed を追加する。

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
  viewer_has_viewed boolean,
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
    exists (
      select 1 from public.groom_views viewer_view
       where viewer_view.groom_post_id = gp.id and viewer_view.user_id = auth.uid()
    ) as viewer_has_viewed,
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
