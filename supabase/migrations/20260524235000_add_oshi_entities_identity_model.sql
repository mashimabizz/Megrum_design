-- =====================================================================
-- iter168.22: 推しの正規entityモデルを追加
-- =====================================================================
-- ユーザーが選ぶL1/L2の文脈は groups_master / characters_master に残し、
-- 同じ人物・同じキャラクターとして集計したい対象だけ entity_id で束ねる。

create table if not exists public.oshi_entities_master (
  id uuid primary key default gen_random_uuid(),
  identity_key text not null unique,
  canonical_name text not null,
  entity_type text not null check (entity_type in ('person', 'character', 'other')),
  aliases text[] not null default '{}',
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.oshi_entities_master is
  '推し正規entityマスタ。同じ人物/キャラクターを複数の選択文脈から束ねるための内部ID。';
comment on column public.oshi_entities_master.identity_key is
  '運営管理用の安定キー。同名別人を分け、明示した同一人物だけ同じentityへ寄せる。';
comment on column public.oshi_entities_master.canonical_name is
  '代表表示名。芸名・キャラ名などユーザーに自然な名称を使う。';

alter table public.oshi_entities_master enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'oshi_entities_master'
      and policyname = 'Anyone can read oshi_entities_master'
  ) then
    create policy "Anyone can read oshi_entities_master"
      on public.oshi_entities_master for select using (true);
  end if;
end $$;

alter table public.groups_master
  add column if not exists entity_id uuid references public.oshi_entities_master(id) on delete set null;

alter table public.characters_master
  add column if not exists entity_id uuid references public.oshi_entities_master(id) on delete set null;

comment on column public.groups_master.entity_id is
  'kind=solo のL1が表す人物/対象の正規entity。グループ/作品のL1では通常null。';
comment on column public.characters_master.entity_id is
  'メンバー/キャラが表す人物/キャラクターの正規entity。別文脈の同一対象を束ねる。';

create index if not exists idx_oshi_entities_master_type_name
  on public.oshi_entities_master(entity_type, canonical_name);
create index if not exists idx_oshi_entities_master_aliases
  on public.oshi_entities_master using gin(aliases);
create index if not exists idx_groups_master_entity
  on public.groups_master(entity_id);
create index if not exists idx_characters_master_entity
  on public.characters_master(entity_id);

with solo_groups as (
  select
    gm.id as source_id,
    'person:solo:' || ge.name || ':' || gm.name as identity_key,
    gm.name as canonical_name,
    'person'::text as entity_type,
    gm.aliases,
    gm.display_order
  from public.groups_master gm
  join public.genres_master ge on ge.id = gm.genre_id
  where gm.kind = 'solo'
),
selectable_members as (
  select
    cm.id as source_id,
    case
      when gm.kind = 'work'
        or ge.name in ('アニメ・マンガ', 'ゲーム', 'キャラクターIP', '2.5次元・舞台')
        then 'character'
      else 'person'
    end as entity_type,
    case
      when gm.kind = 'work'
        or ge.name in ('アニメ・マンガ', 'ゲーム', 'キャラクターIP', '2.5次元・舞台')
        then 'character:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name
      else 'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name
    end as identity_key,
    cm.name as canonical_name,
    cm.aliases,
    cm.display_order
  from public.characters_master cm
  left join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
),
entity_seed as (
  select identity_key, canonical_name, entity_type, aliases, display_order
  from solo_groups
  union all
  select identity_key, canonical_name, entity_type, aliases, display_order
  from selectable_members
)
insert into public.oshi_entities_master (
  identity_key,
  canonical_name,
  entity_type,
  aliases,
  display_order
)
select
  identity_key,
  canonical_name,
  entity_type,
  array(
    select distinct alias
    from unnest(coalesce(aliases, '{}'::text[])) as a(alias)
    where btrim(alias) <> ''
    order by alias
  ) as aliases,
  min(display_order) as display_order
from entity_seed
where btrim(identity_key) <> ''
  and btrim(canonical_name) <> ''
group by identity_key, canonical_name, entity_type, aliases
on conflict (identity_key) do update
  set canonical_name = excluded.canonical_name,
      entity_type = excluded.entity_type,
      aliases = array(
        select distinct alias
        from unnest(
          coalesce(public.oshi_entities_master.aliases, '{}'::text[])
          || coalesce(excluded.aliases, '{}'::text[])
        ) as a(alias)
        where btrim(alias) <> ''
        order by alias
      );

with solo_group_entities as (
  select
    gm.id as group_id,
    'person:solo:' || ge.name || ':' || gm.name as identity_key
  from public.groups_master gm
  join public.genres_master ge on ge.id = gm.genre_id
  where gm.kind = 'solo'
)
update public.groups_master gm
set entity_id = e.id
from solo_group_entities sge
join public.oshi_entities_master e on e.identity_key = sge.identity_key
where gm.id = sge.group_id
  and gm.entity_id is distinct from e.id;

with member_entities as (
  select
    cm.id as character_id,
    case
      when gm.kind = 'work'
        or ge.name in ('アニメ・マンガ', 'ゲーム', 'キャラクターIP', '2.5次元・舞台')
        then 'character:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name
      else 'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name
    end as identity_key
  from public.characters_master cm
  left join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
)
update public.characters_master cm
set entity_id = e.id
from member_entities me
join public.oshi_entities_master e on e.identity_key = me.identity_key
where cm.id = me.character_id
  and cm.entity_id is distinct from e.id;
