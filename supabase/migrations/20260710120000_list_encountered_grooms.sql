-- FB(iter1226.392): ホームのグルーム列に、近くに無くても「出会った(遭遇済み)」グルームを出すための取得RPC。
-- 距離条件なしで、自分が遭遇記録したグルームを返す（無料会員は圏外だとロック表示・閲覧不可）。

create or replace function public.list_encountered_grooms(
  p_viewer_lat double precision,
  p_viewer_lng double precision
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
    gp.id, gp.user_id, gp.image_url, gp.image_path, gp.caption, gp.status,
    gp.audience_scope, gp.area_key, gp.place_hint, gp.image_transform,
    gp.text_overlays, gp.stickers, gp.doodles, gp.published_at, gp.expires_at,
    gp.origin_lat, gp.origin_lng, gp.group_id, gp.character_id, gp.series_name,
    case
      when p_viewer_lat is not null and p_viewer_lng is not null
        and gp.origin_lat is not null and gp.origin_lng is not null
      then public.haversine_meters(p_viewer_lat, p_viewer_lng, gp.origin_lat, gp.origin_lng)
      else null
    end as distance_m,
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
    true as viewer_encountered,
    u.id, u.display_name, u.handle, u.avatar_url, u.primary_area
  from public.groom_encounters enc
  join public.groom_posts gp on gp.id = enc.groom_post_id
  join public.users u on u.id = gp.user_id
  where enc.user_id = auth.uid()
    and gp.user_id <> auth.uid()
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
  order by gp.published_at desc nulls last, gp.created_at desc
  limit 100;
end;
$$;

revoke all on function public.list_encountered_grooms(double precision, double precision) from public;
grant execute on function public.list_encountered_grooms(double precision, double precision) to authenticated;
