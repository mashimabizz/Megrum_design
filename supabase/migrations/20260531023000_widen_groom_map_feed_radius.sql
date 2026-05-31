-- Allow the Swift Native groom map to request surrounding pins up to 3km.
-- The app still enforces the 1km open/view rule client-side; this only widens
-- the map pin feed so out-of-range posts can be displayed as locked markers.

create or replace function public.list_groom_feed_nearby(
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
  distance_m double precision,
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
    public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng) as distance_m,
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
      where hidden.user_id = auth.uid()
        and hidden.groom_post_id = gp.id
    )
    and not exists (
      select 1 from public.groom_user_blocks blocks
      where (blocks.blocker_id = auth.uid() and blocks.blocked_id = gp.user_id)
         or (blocks.blocker_id = gp.user_id and blocks.blocked_id = auth.uid())
    )
    and (
      gp.user_id = auth.uid()
      or (
        p_viewer_lat is not null
        and p_viewer_lng is not null
        and gp.origin_lat is not null
        and gp.origin_lng is not null
        and public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng)
          <= least(greatest(coalesce(p_radius_m, 1000), 100), 3000)
      )
    )
  order by
    case when gp.user_id = auth.uid() then 0 else 1 end,
    distance_m nulls last,
    gp.published_at desc
  limit 80;
end;
$$;

revoke all on function public.list_groom_feed_nearby(
  double precision,
  double precision,
  integer
) from public;
grant execute on function public.list_groom_feed_nearby(
  double precision,
  double precision,
  integer
) to authenticated;
