-- iter1226.434: めぐり地図のズームアウト時に「おおよその件数」だけを軽量に返す密度RPC。
-- 実データ（画像URL等）を読み込む前に、セル単位のグルーム/チャットルーム件数を表示するために使う。
-- 「大体でいい」件数なので、非表示（hidden）・ブロックの個人別フィルタは意図的に省いて安く保つ。

create index if not exists idx_groom_posts_origin_coords
  on public.groom_posts (origin_lat, origin_lng)
  where origin_lat is not null and origin_lng is not null;

create index if not exists idx_meguri_board_threads_origin_coords
  on public.meguri_board_threads (origin_lat, origin_lng)
  where origin_lat is not null and origin_lng is not null;

create or replace function public.meguri_map_density(
  p_min_lat double precision,
  p_min_lng double precision,
  p_max_lat double precision,
  p_max_lng double precision,
  p_cell_deg double precision default 0.1
)
returns table (
  cell_lat double precision,
  cell_lng double precision,
  groom_count integer,
  thread_count integer
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  -- セルサイズは 0.005度(約550m) 〜 5度 にクランプ（過細分によるコスト増と過粗を防ぐ）
  cell double precision := least(greatest(coalesce(p_cell_deg, 0.1), 0.005), 5.0);
begin
  if auth.uid() is null then
    return;
  end if;

  return query
  with grooms as (
    select
      floor(gp.origin_lat / cell) as cy,
      floor(gp.origin_lng / cell) as cx,
      count(*)::integer as cnt
    from public.groom_posts gp
    where gp.status = 'published'
      and gp.expires_at > now()
      and gp.origin_lat is not null
      and gp.origin_lng is not null
      and gp.origin_lat between p_min_lat and p_max_lat
      and gp.origin_lng between p_min_lng and p_max_lng
    group by 1, 2
  ),
  threads as (
    select
      floor(t.origin_lat / cell) as cy,
      floor(t.origin_lng / cell) as cx,
      count(*)::integer as cnt
    from public.meguri_board_threads t
    where t.status = 'visible'
      and t.origin_lat is not null
      and t.origin_lng is not null
      and t.origin_lat between p_min_lat and p_max_lat
      and t.origin_lng between p_min_lng and p_max_lng
    group by 1, 2
  )
  select
    (coalesce(g.cy, th.cy) + 0.5) * cell as cell_lat,
    (coalesce(g.cx, th.cx) + 0.5) * cell as cell_lng,
    coalesce(g.cnt, 0) as groom_count,
    coalesce(th.cnt, 0) as thread_count
  from grooms g
  full outer join threads th on th.cy = g.cy and th.cx = g.cx
  order by (coalesce(g.cnt, 0) + coalesce(th.cnt, 0)) desc
  limit 300;
end;
$$;

revoke all on function public.meguri_map_density(
  double precision,
  double precision,
  double precision,
  double precision,
  double precision
) from public;
grant execute on function public.meguri_map_density(
  double precision,
  double precision,
  double precision,
  double precision,
  double precision
) to authenticated;
