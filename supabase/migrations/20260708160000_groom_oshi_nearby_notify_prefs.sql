-- FB8-7 / iter1226.388: グルーム新着通知を「圏内 かつ 同一推し」に統一し、推し(L1)ごとの
-- ON/OFF ＋ メンバー絞り込みを可能にする。圏外の通知済みグルームはプレミアム閲覧の判定に使う。
--
-- 既存（20260704120000）の notify_groom_post_published は
--   (推し一致) OR (圏内) の論理和だった。オーナー仕様は
--   「圏内 かつ 同一推し」の論理積 ＋ 推しごとの制御。ここで張り替える。

-- ---------------------------------------------------------------------
-- 1. 推し(L1グループ)ごとのグルーム通知設定
--    ・行が無ければ既定 = 通知ON・全メンバー
--    ・enabled=false でそのグループの通知を止める
--    ・members_only=true で、登録メンバー(L2)のグルームだけ通知
-- ---------------------------------------------------------------------

create table if not exists public.user_groom_notify_prefs (
  user_id uuid not null references auth.users(id) on delete cascade,
  group_id uuid not null references public.groups_master(id) on delete cascade,
  enabled boolean not null default true,
  members_only boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, group_id)
);

comment on table public.user_groom_notify_prefs is
  '推し(L1グループ)ごとの圏内グルーム通知設定。行が無ければ通知ON・全メンバー。';

alter table public.user_groom_notify_prefs enable row level security;

drop policy if exists user_groom_notify_prefs_select_own on public.user_groom_notify_prefs;
create policy user_groom_notify_prefs_select_own
  on public.user_groom_notify_prefs for select
  using (user_id = auth.uid());

drop policy if exists user_groom_notify_prefs_upsert_own on public.user_groom_notify_prefs;
create policy user_groom_notify_prefs_upsert_own
  on public.user_groom_notify_prefs for insert
  with check (user_id = auth.uid());

drop policy if exists user_groom_notify_prefs_update_own on public.user_groom_notify_prefs;
create policy user_groom_notify_prefs_update_own
  on public.user_groom_notify_prefs for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists user_groom_notify_prefs_delete_own on public.user_groom_notify_prefs;
create policy user_groom_notify_prefs_delete_own
  on public.user_groom_notify_prefs for delete
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- 2. ファンアウトを「圏内 かつ 同一推し ＋ 推しごと設定」に張り替え
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

  -- グルームの所属グループ（group_id 未設定でも character から解決）。
  v_group_id := coalesce(
    new.group_id,
    (select cm.group_id from public.characters_master cm where cm.id = new.character_id)
  );

  -- 推しに紐づかないグルームは「同一推し」通知の対象外。
  if v_group_id is null then
    return new;
  end if;

  insert into public.notifications (user_id, kind, title, body, link_path, groom_post_id)
  select
    s.user_id,
    'groom_posted',
    '推しの近くの新しいグルーム',
    coalesce(nullif(btrim(new.caption), ''), 'グルームが投稿されました'),
    '/grooms/' || new.id::text,
    new.id
  from public.user_notification_settings s
  where s.user_id <> new.user_id
    and coalesce(s.push_enabled, true)
    and coalesce(s.groom_oshi_push_enabled, false)
    -- 圏内（push_location が7日以内更新、3km以内）
    and new.origin_lat is not null
    and new.origin_lng is not null
    and s.push_location_lat is not null
    and s.push_location_lng is not null
    and s.push_location_updated_at > now() - interval '7 days'
    and public.haversine_meters(
      new.origin_lat, new.origin_lng,
      s.push_location_lat, s.push_location_lng
    ) <= 3000
    -- 同一推し（グルームの所属グループが自分の推しグループ）＋ 推しごと設定
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

-- トリガは既存の trg_groom_post_published_notify を再利用（関数差し替えのみ）。

-- ---------------------------------------------------------------------
-- 3. 圏外グルームのプレミアム閲覧判定用：このユーザーが通知を受けたグルームか
-- ---------------------------------------------------------------------

create or replace function public.groom_viewer_was_notified(p_groom_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
      from public.notifications n
     where n.user_id = auth.uid()
       and n.kind = 'groom_posted'
       and n.groom_post_id = p_groom_id
  );
$$;

revoke all on function public.groom_viewer_was_notified(uuid) from public;
grant execute on function public.groom_viewer_was_notified(uuid) to authenticated;

grant select, insert, update, delete on public.user_groom_notify_prefs to authenticated;
