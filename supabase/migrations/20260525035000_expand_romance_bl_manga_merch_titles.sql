-- =====================================================================
-- iter168.33: 恋愛/BL/女性向け寄りアニメ・マンガを追加
-- =====================================================================
-- 交換需要が出やすいアクリルスタンド・缶バッジ等のグッズ展開がある作品を補完する。

create temporary table _megrum_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _megrum_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('アニメ・マンガ','ゆびさきと恋々',array['A Sign of Affection']::text[],'work',106),
  ('アニメ・マンガ','山田くんとLv999の恋をする',array['山田999','My Love Story with Yamada-kun at Lv999']::text[],'work',107),
  ('アニメ・マンガ','佐々木と宮野',array['Sasaki and Miyano']::text[],'work',108),
  ('アニメ・マンガ','ギヴン',array['given']::text[],'work',109),
  ('アニメ・マンガ','ホリミヤ',array['Horimiya']::text[],'work',110),
  ('アニメ・マンガ','ブルーピリオド',array['Blue Period']::text[],'work',111),
  ('アニメ・マンガ','彼女、お借りします',array['かのかり','Rent-A-Girlfriend']::text[],'work',112);

insert into public.groups_master (genre_id, name, aliases, kind, display_order)
select
  ge.id,
  sg.name,
  sg.aliases,
  sg.kind,
  sg.display_order
from _megrum_seed_groups sg
join public.genres_master ge on ge.name = sg.genre_name
on conflict (genre_id, name) do update
  set aliases = excluded.aliases,
      kind = excluded.kind,
      display_order = excluded.display_order;

create temporary table _megrum_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _megrum_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- ゆびさきと恋々
  ('アニメ・マンガ','ゆびさきと恋々','糸瀬雪',array[]::text[],1),
  ('アニメ・マンガ','ゆびさきと恋々','波岐逸臣',array[]::text[],2),
  ('アニメ・マンガ','ゆびさきと恋々','芦沖桜志',array[]::text[],3),
  ('アニメ・マンガ','ゆびさきと恋々','波岐京弥',array[]::text[],4),
  ('アニメ・マンガ','ゆびさきと恋々','藤白りん',array[]::text[],5),
  ('アニメ・マンガ','ゆびさきと恋々','中園エマ',array[]::text[],6),
  ('アニメ・マンガ','ゆびさきと恋々','伊柳心',array[]::text[],7),
  -- 山田くんとLv999の恋をする
  ('アニメ・マンガ','山田くんとLv999の恋をする','木之下茜',array[]::text[],1),
  ('アニメ・マンガ','山田くんとLv999の恋をする','山田秋斗',array[]::text[],2),
  ('アニメ・マンガ','山田くんとLv999の恋をする','佐々木瑛太',array[]::text[],3),
  ('アニメ・マンガ','山田くんとLv999の恋をする','佐々木瑠奈',array[]::text[],4),
  ('アニメ・マンガ','山田くんとLv999の恋をする','前田桃子',array[]::text[],5),
  ('アニメ・マンガ','山田くんとLv999の恋をする','鴨田たけぞう',array[]::text[],6),
  ('アニメ・マンガ','山田くんとLv999の恋をする','岡本武明',array[]::text[],7),
  ('アニメ・マンガ','山田くんとLv999の恋をする','椿ゆかり',array[]::text[],8),
  -- 佐々木と宮野
  ('アニメ・マンガ','佐々木と宮野','佐々木秀鳴',array[]::text[],1),
  ('アニメ・マンガ','佐々木と宮野','宮野由美',array[]::text[],2),
  ('アニメ・マンガ','佐々木と宮野','平野大河',array[]::text[],3),
  ('アニメ・マンガ','佐々木と宮野','小笠原次郎',array[]::text[],4),
  ('アニメ・マンガ','佐々木と宮野','半澤雅人',array[]::text[],5),
  ('アニメ・マンガ','佐々木と宮野','暮沢丞',array[]::text[],6),
  ('アニメ・マンガ','佐々木と宮野','田代権三郎',array[]::text[],7),
  ('アニメ・マンガ','佐々木と宮野','鍵浦昭',array[]::text[],8),
  -- ギヴン
  ('アニメ・マンガ','ギヴン','佐藤真冬',array[]::text[],1),
  ('アニメ・マンガ','ギヴン','上ノ山立夏',array[]::text[],2),
  ('アニメ・マンガ','ギヴン','中山春樹',array[]::text[],3),
  ('アニメ・マンガ','ギヴン','梶秋彦',array[]::text[],4),
  ('アニメ・マンガ','ギヴン','村田雨月',array[]::text[],5),
  ('アニメ・マンガ','ギヴン','鹿島柊',array[]::text[],6),
  ('アニメ・マンガ','ギヴン','八木玄純',array[]::text[],7),
  ('アニメ・マンガ','ギヴン','吉田由紀',array[]::text[],8),
  -- ホリミヤ
  ('アニメ・マンガ','ホリミヤ','堀京子',array[]::text[],1),
  ('アニメ・マンガ','ホリミヤ','宮村伊澄',array[]::text[],2),
  ('アニメ・マンガ','ホリミヤ','石川透',array[]::text[],3),
  ('アニメ・マンガ','ホリミヤ','吉川由紀',array[]::text[],4),
  ('アニメ・マンガ','ホリミヤ','仙石翔',array[]::text[],5),
  ('アニメ・マンガ','ホリミヤ','綾崎レミ',array[]::text[],6),
  ('アニメ・マンガ','ホリミヤ','河野桜',array[]::text[],7),
  ('アニメ・マンガ','ホリミヤ','井浦秀',array[]::text[],8),
  ('アニメ・マンガ','ホリミヤ','柳明音',array[]::text[],9),
  ('アニメ・マンガ','ホリミヤ','進藤晃一',array[]::text[],10),
  -- ブルーピリオド
  ('アニメ・マンガ','ブルーピリオド','矢口八虎',array[]::text[],1),
  ('アニメ・マンガ','ブルーピリオド','鮎川龍二',array['ユカちゃん']::text[],2),
  ('アニメ・マンガ','ブルーピリオド','高橋世田介',array[]::text[],3),
  ('アニメ・マンガ','ブルーピリオド','橋田悠',array[]::text[],4),
  ('アニメ・マンガ','ブルーピリオド','桑名マキ',array[]::text[],5),
  ('アニメ・マンガ','ブルーピリオド','森まる',array[]::text[],6),
  ('アニメ・マンガ','ブルーピリオド','佐伯昌子',array[]::text[],7),
  ('アニメ・マンガ','ブルーピリオド','大葉真由',array[]::text[],8),
  -- 彼女、お借りします
  ('アニメ・マンガ','彼女、お借りします','木ノ下和也',array[]::text[],1),
  ('アニメ・マンガ','彼女、お借りします','水原千鶴',array['一ノ瀬ちづる']::text[],2),
  ('アニメ・マンガ','彼女、お借りします','七海麻美',array[]::text[],3),
  ('アニメ・マンガ','彼女、お借りします','更科瑠夏',array[]::text[],4),
  ('アニメ・マンガ','彼女、お借りします','桜沢墨',array[]::text[],5),
  ('アニメ・マンガ','彼女、お借りします','八重森みに',array[]::text[],6);

insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
select
  gm.id,
  ge.id,
  sc.name,
  sc.aliases,
  sc.display_order
from _megrum_seed_characters sc
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
