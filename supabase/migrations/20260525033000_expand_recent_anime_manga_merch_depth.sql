-- =====================================================================
-- iter168.32: 最近人気アニメ・マンガのL2深掘り
-- =====================================================================
-- グッズ交換でキャラ別需要が出やすい最近人気作の新規追加と既存L2補完を行う。

create temporary table _ihub_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _ihub_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('アニメ・マンガ','薫る花は凛と咲く',array['Kaoru Hana wa Rin to Saku','The Fragrant Flower Blooms with Dignity']::text[],'work',103),
  ('アニメ・マンガ','カグラバチ',array['Kagurabachi']::text[],'work',104),
  ('アニメ・マンガ','ふつうの軽音部',array['Futsuu no Keionbu']::text[],'work',105);

insert into public.groups_master (genre_id, name, aliases, kind, display_order)
select
  ge.id,
  sg.name,
  sg.aliases,
  sg.kind,
  sg.display_order
from _ihub_seed_groups sg
join public.genres_master ge on ge.name = sg.genre_name
on conflict (genre_id, name) do update
  set aliases = excluded.aliases,
      kind = excluded.kind,
      display_order = excluded.display_order;

create temporary table _ihub_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _ihub_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- 新規追加: 薫る花は凛と咲く
  ('アニメ・マンガ','薫る花は凛と咲く','紬凛太郎',array[]::text[],1),
  ('アニメ・マンガ','薫る花は凛と咲く','和栗薫子',array[]::text[],2),
  ('アニメ・マンガ','薫る花は凛と咲く','宇佐美翔平',array[]::text[],3),
  ('アニメ・マンガ','薫る花は凛と咲く','夏沢朔',array[]::text[],4),
  ('アニメ・マンガ','薫る花は凛と咲く','依田絢斗',array[]::text[],5),
  ('アニメ・マンガ','薫る花は凛と咲く','保科昴',array[]::text[],6),
  -- 新規追加: カグラバチ
  ('アニメ・マンガ','カグラバチ','六平千鉱',array[]::text[],1),
  ('アニメ・マンガ','カグラバチ','柴登吾',array[]::text[],2),
  ('アニメ・マンガ','カグラバチ','香刈緋雪',array[]::text[],3),
  ('アニメ・マンガ','カグラバチ','漣伯理',array[]::text[],4),
  ('アニメ・マンガ','カグラバチ','双城厳一',array[]::text[],5),
  ('アニメ・マンガ','カグラバチ','漣京羅',array[]::text[],6),
  ('アニメ・マンガ','カグラバチ','美原多福',array[]::text[],7),
  ('アニメ・マンガ','カグラバチ','座村清市',array[]::text[],8),
  -- 新規追加: ふつうの軽音部
  ('アニメ・マンガ','ふつうの軽音部','鳩野ちひろ',array[]::text[],1),
  ('アニメ・マンガ','ふつうの軽音部','内田桃',array[]::text[],2),
  ('アニメ・マンガ','ふつうの軽音部','幸山厘',array[]::text[],3),
  ('アニメ・マンガ','ふつうの軽音部','藤井彩目',array[]::text[],4),
  -- 既存人気作のL2補完: ダンダダン
  ('アニメ・マンガ','ダンダダン','バモラ',array[]::text[],7),
  ('アニメ・マンガ','ダンダダン','坂田金太',array[]::text[],8),
  ('アニメ・マンガ','ダンダダン','邪視',array[]::text[],9),
  ('アニメ・マンガ','ダンダダン','セルポ星人',array[]::text[],10),
  ('アニメ・マンガ','ダンダダン','シャコ星人',array[]::text[],11),
  -- WIND BREAKER
  ('アニメ・マンガ','WIND BREAKER','柊登馬',array[]::text[],9),
  ('アニメ・マンガ','WIND BREAKER','椿野佑',array[]::text[],10),
  ('アニメ・マンガ','WIND BREAKER','桐生三輝',array[]::text[],11),
  ('アニメ・マンガ','WIND BREAKER','柘浦大河',array[]::text[],12),
  ('アニメ・マンガ','WIND BREAKER','水木聡久',array[]::text[],13),
  ('アニメ・マンガ','WIND BREAKER','桃瀬匠',array[]::text[],14),
  ('アニメ・マンガ','WIND BREAKER','佐狐浩太',array[]::text[],15),
  ('アニメ・マンガ','WIND BREAKER','榎本健史',array[]::text[],16),
  -- SAKAMOTO DAYS
  ('アニメ・マンガ','SAKAMOTO DAYS','眞霜平助',array[]::text[],10),
  ('アニメ・マンガ','SAKAMOTO DAYS','豹',array[]::text[],11),
  ('アニメ・マンガ','SAKAMOTO DAYS','篁',array[]::text[],12),
  ('アニメ・マンガ','SAKAMOTO DAYS','X',array['スラー','有月憬']::text[],13),
  ('アニメ・マンガ','SAKAMOTO DAYS','鹿島',array[]::text[],14),
  ('アニメ・マンガ','SAKAMOTO DAYS','勢羽真冬',array[]::text[],15),
  ('アニメ・マンガ','SAKAMOTO DAYS','赤尾リオン',array[]::text[],16),
  ('アニメ・マンガ','SAKAMOTO DAYS','京',array[]::text[],17),
  -- 【推しの子】
  ('アニメ・マンガ','【推しの子】','姫川大輝',array[]::text[],7),
  ('アニメ・マンガ','【推しの子】','不知火フリル',array[]::text[],8),
  ('アニメ・マンガ','【推しの子】','寿みなみ',array[]::text[],9),
  ('アニメ・マンガ','【推しの子】','鳴嶋メルト',array[]::text[],10),
  ('アニメ・マンガ','【推しの子】','ぴえヨン',array[]::text[],11),
  ('アニメ・マンガ','【推しの子】','斉藤ミヤコ',array[]::text[],12),
  ('アニメ・マンガ','【推しの子】','五反田泰志',array[]::text[],13),
  -- 葬送のフリーレン
  ('アニメ・マンガ','葬送のフリーレン','デンケン',array[]::text[],9),
  ('アニメ・マンガ','葬送のフリーレン','ヴィアベル',array[]::text[],10),
  ('アニメ・マンガ','葬送のフリーレン','ゼーリエ',array[]::text[],11),
  ('アニメ・マンガ','葬送のフリーレン','フランメ',array[]::text[],12),
  ('アニメ・マンガ','葬送のフリーレン','リヒター',array[]::text[],13),
  ('アニメ・マンガ','葬送のフリーレン','ラオフェン',array[]::text[],14),
  ('アニメ・マンガ','葬送のフリーレン','カンネ',array[]::text[],15),
  ('アニメ・マンガ','葬送のフリーレン','ラヴィーネ',array[]::text[],16),
  -- ブルーロック
  ('アニメ・マンガ','ブルーロック','アレクシス・ネス',array[]::text[],11),
  ('アニメ・マンガ','ブルーロック','氷織羊',array[]::text[],12),
  ('アニメ・マンガ','ブルーロック','黒名蘭世',array[]::text[],13),
  ('アニメ・マンガ','ブルーロック','烏旅人',array[]::text[],14),
  ('アニメ・マンガ','ブルーロック','乙夜影汰',array[]::text[],15),
  ('アニメ・マンガ','ブルーロック','雪宮剣優',array[]::text[],16),
  ('アニメ・マンガ','ブルーロック','士道龍聖',array[]::text[],17),
  ('アニメ・マンガ','ブルーロック','蟻生十兵衛',array[]::text[],18),
  ('アニメ・マンガ','ブルーロック','我牙丸吟',array[]::text[],19),
  -- 薬屋のひとりごと
  ('アニメ・マンガ','薬屋のひとりごと','阿多妃',array[]::text[],12),
  ('アニメ・マンガ','薬屋のひとりごと','楼蘭妃',array[]::text[],13),
  ('アニメ・マンガ','薬屋のひとりごと','子翠',array[]::text[],14),
  ('アニメ・マンガ','薬屋のひとりごと','翠苓',array[]::text[],15),
  ('アニメ・マンガ','薬屋のひとりごと','李白',array[]::text[],16),
  ('アニメ・マンガ','薬屋のひとりごと','馬閃',array[]::text[],17),
  ('アニメ・マンガ','薬屋のひとりごと','里樹妃',array[]::text[],18),
  -- 怪獣8号
  ('アニメ・マンガ','怪獣8号','出雲ハルイチ',array[]::text[],12),
  ('アニメ・マンガ','怪獣8号','神楽木葵',array[]::text[],13),
  ('アニメ・マンガ','怪獣8号','小此木このみ',array[]::text[],14),
  ('アニメ・マンガ','怪獣8号','東雲りん',array[]::text[],15),
  ('アニメ・マンガ','怪獣8号','緒方ジュウゴ',array[]::text[],16),
  ('アニメ・マンガ','怪獣8号','怪獣9号',array[]::text[],17),
  ('アニメ・マンガ','怪獣8号','怪獣10号',array[]::text[],18);

insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
select
  gm.id,
  ge.id,
  sc.name,
  sc.aliases,
  sc.display_order
from _ihub_seed_characters sc
join public.genres_master ge on ge.name = sc.genre_name
join public.groups_master gm on gm.genre_id = ge.id and gm.name = sc.group_name
where not exists (
  select 1
  from public.characters_master c
  where c.group_id = gm.id
    and c.name = sc.name
);

with selectable_members as (
  select
    'character'::text as entity_type,
    'character:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name as identity_key,
    cm.name as canonical_name,
    cm.aliases,
    cm.display_order
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
  where gm.kind = 'work'
    or ge.name in ('アニメ・マンガ', 'ゲーム', 'キャラクターIP', '2.5次元・舞台')
),
entity_seed as (
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

with member_entities as (
  select
    cm.id as character_id,
    'character:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name as identity_key
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
  where gm.kind = 'work'
    or ge.name in ('アニメ・マンガ', 'ゲーム', 'キャラクターIP', '2.5次元・舞台')
)
update public.characters_master cm
set entity_id = e.id
from member_entities me
join public.oshi_entities_master e on e.identity_key = me.identity_key
where cm.id = me.character_id
  and cm.entity_id is distinct from e.id;
