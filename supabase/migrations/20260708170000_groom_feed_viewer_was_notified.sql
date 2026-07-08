-- FB8-7 / iter1226.388: 圏外の「通知が飛んだ」グルームをプレミアムで開けるようにするため、
-- フィードRPCに viewer_was_notified を追加する。あわせて groom_posted 通知のリンクを
-- /meguri に戻す（特定グルームへのディープリンクは未実装のため、めぐりマップ経由で開く）。

-- ---------------------------------------------------------------------
-- 1. 通知リンクを /meguri に戻す（notify_groom_post_published の再定義）
--    条件（圏内 かつ 同一推し ＋ 推しごと設定）は 20260708160000 のまま。
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

  insert into public.notifications (user_id, kind, title, body, link_path, groom_post_id)
  select
    s.user_id,
    'groom_posted',
    '推しの近くの新しいグルーム',
    coalesce(nullif(btrim(new.caption), ''), 'グルームが投稿されました'),
    '/meguri',
    new.id
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
-- 2. フィードRPCに viewer_was_notified を追加（20260706210000 の本体を踏襲）
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
      select count(*)::integer
        from public.groom_reactions reaction
       where reaction.groom_post_id = gp.id
         and reaction.reaction_type = 'like'
    ) as like_count,
    exists (
      select 1
        from public.groom_reactions viewer_reaction
       where viewer_reaction.groom_post_id = gp.id
         and viewer_reaction.reaction_type = 'like'
         and viewer_reaction.user_id = auth.uid()
    ) as viewer_has_liked,
    exists (
      select 1
        from public.notifications viewer_notif
       where viewer_notif.groom_post_id = gp.id
         and viewer_notif.kind = 'groom_posted'
         and viewer_notif.user_id = auth.uid()
    ) as viewer_was_notified,
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
