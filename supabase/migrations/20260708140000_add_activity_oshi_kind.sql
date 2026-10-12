-- FB8-10 / iter1226.386: 推し種別に 'activity'（アクティビティ）を追加する。
-- 既存の CHECK 制約（group/work/solo）を activity 込みに張り替える。マスタ登録は別途。

alter table public.groups_master
  drop constraint if exists groups_master_kind_check;
alter table public.groups_master
  add constraint groups_master_kind_check
  check (kind in ('group', 'work', 'solo', 'activity'));

alter table public.oshi_requests
  drop constraint if exists oshi_requests_requested_kind_check;
alter table public.oshi_requests
  add constraint oshi_requests_requested_kind_check
  check (requested_kind in ('group', 'work', 'solo', 'activity'));
