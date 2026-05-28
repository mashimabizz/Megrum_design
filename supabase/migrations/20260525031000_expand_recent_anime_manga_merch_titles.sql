-- =====================================================================
-- iter168.31: 最近人気/グッズ展開ありのアニメ・マンガを追加
-- =====================================================================
-- 2024-2026に話題化し、公式サイト/公式ショップ/専門店でグッズ展開が確認できる作品を中心に追加する。

create temporary table _megrum_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _megrum_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('アニメ・マンガ','メダリスト',array['Medalist']::text[],'work',90),
  ('アニメ・マンガ','アオのハコ',array['Blue Box']::text[],'work',91),
  ('アニメ・マンガ','忘却バッテリー',array['Boukyaku Battery']::text[],'work',92),
  ('アニメ・マンガ','桃源暗鬼',array['Tougen Anki']::text[],'work',93),
  ('アニメ・マンガ','ガチアクタ',array['Gachiakuta']::text[],'work',94),
  ('アニメ・マンガ','光が死んだ夏',array['The Summer Hikaru Died']::text[],'work',95),
  ('アニメ・マンガ','逃げ上手の若君',array['逃げ若','The Elusive Samurai']::text[],'work',96),
  ('アニメ・マンガ','MASHLE',array['マッシュル','MASHLE: MAGIC AND MUSCLES']::text[],'work',97),
  ('アニメ・マンガ','ダンジョン飯',array['Delicious in Dungeon']::text[],'work',98),
  ('アニメ・マンガ','らんま1/2',array['Ranma 1/2']::text[],'work',99),
  ('アニメ・マンガ','その着せ替え人形は恋をする',array['着せ恋','My Dress-Up Darling']::text[],'work',100),
  ('アニメ・マンガ','シャングリラ・フロンティア',array['シャンフロ','Shangri-La Frontier']::text[],'work',101),
  ('アニメ・マンガ','地獄楽',array['Hell''s Paradise']::text[],'work',102);

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
  -- メダリスト
  ('アニメ・マンガ','メダリスト','結束いのり',array[]::text[],1),
  ('アニメ・マンガ','メダリスト','明浦路司',array[]::text[],2),
  ('アニメ・マンガ','メダリスト','狼嵜光',array[]::text[],3),
  ('アニメ・マンガ','メダリスト','夜鷹純',array[]::text[],4),
  ('アニメ・マンガ','メダリスト','鴗鳥理凰',array[]::text[],5),
  ('アニメ・マンガ','メダリスト','三家田涼佳',array[]::text[],6),
  ('アニメ・マンガ','メダリスト','大和絵馬',array[]::text[],7),
  ('アニメ・マンガ','メダリスト','鹿本すず',array[]::text[],8),
  -- アオのハコ
  ('アニメ・マンガ','アオのハコ','猪股大喜',array[]::text[],1),
  ('アニメ・マンガ','アオのハコ','鹿野千夏',array[]::text[],2),
  ('アニメ・マンガ','アオのハコ','蝶野雛',array[]::text[],3),
  ('アニメ・マンガ','アオのハコ','笠原匡',array[]::text[],4),
  ('アニメ・マンガ','アオのハコ','針生健吾',array[]::text[],5),
  ('アニメ・マンガ','アオのハコ','西田諒介',array[]::text[],6),
  ('アニメ・マンガ','アオのハコ','船見渚',array[]::text[],7),
  ('アニメ・マンガ','アオのハコ','島崎にいな',array[]::text[],8),
  ('アニメ・マンガ','アオのハコ','兵藤将太',array[]::text[],9),
  ('アニメ・マンガ','アオのハコ','遊佐柊仁',array[]::text[],10),
  ('アニメ・マンガ','アオのハコ','守屋花恋',array[]::text[],11),
  ('アニメ・マンガ','アオのハコ','守屋菖蒲',array[]::text[],12),
  -- 忘却バッテリー
  ('アニメ・マンガ','忘却バッテリー','清峰葉流火',array[]::text[],1),
  ('アニメ・マンガ','忘却バッテリー','要圭',array[]::text[],2),
  ('アニメ・マンガ','忘却バッテリー','藤堂葵',array[]::text[],3),
  ('アニメ・マンガ','忘却バッテリー','千早瞬平',array[]::text[],4),
  ('アニメ・マンガ','忘却バッテリー','山田太郎',array[]::text[],5),
  ('アニメ・マンガ','忘却バッテリー','土屋和季',array[]::text[],6),
  ('アニメ・マンガ','忘却バッテリー','国都英一郎',array[]::text[],7),
  ('アニメ・マンガ','忘却バッテリー','巻田広伸',array[]::text[],8),
  ('アニメ・マンガ','忘却バッテリー','桐島秋斗',array[]::text[],9),
  -- 桃源暗鬼
  ('アニメ・マンガ','桃源暗鬼','一ノ瀬四季',array[]::text[],1),
  ('アニメ・マンガ','桃源暗鬼','無陀野無人',array[]::text[],2),
  ('アニメ・マンガ','桃源暗鬼','皇后崎迅',array[]::text[],3),
  ('アニメ・マンガ','桃源暗鬼','屏風ヶ浦帆稀',array[]::text[],4),
  ('アニメ・マンガ','桃源暗鬼','矢颪碇',array[]::text[],5),
  ('アニメ・マンガ','桃源暗鬼','遊摺部従児',array[]::text[],6),
  ('アニメ・マンガ','桃源暗鬼','漣水鶏',array[]::text[],7),
  ('アニメ・マンガ','桃源暗鬼','花魁坂京夜',array[]::text[],8),
  ('アニメ・マンガ','桃源暗鬼','桃宮唾切',array[]::text[],9),
  ('アニメ・マンガ','桃源暗鬼','桃草蓬',array[]::text[],10),
  -- ガチアクタ
  ('アニメ・マンガ','ガチアクタ','ルド',array['Rudo']::text[],1),
  ('アニメ・マンガ','ガチアクタ','エンジン',array['Enjin']::text[],2),
  ('アニメ・マンガ','ガチアクタ','ザンカ',array['Zanka']::text[],3),
  ('アニメ・マンガ','ガチアクタ','リヨウ',array['Riyo']::text[],4),
  ('アニメ・マンガ','ガチアクタ','タムジー',array['Tamsy']::text[],5),
  ('アニメ・マンガ','ガチアクタ','デルモン',array['Delmon']::text[],6),
  ('アニメ・マンガ','ガチアクタ','グリス',array['Gris']::text[],7),
  ('アニメ・マンガ','ガチアクタ','フォロ',array['Follo']::text[],8),
  ('アニメ・マンガ','ガチアクタ','コルバス',array['Corvus']::text[],9),
  ('アニメ・マンガ','ガチアクタ','セミュ',array['Semiu']::text[],10),
  ('アニメ・マンガ','ガチアクタ','ゾディル',array['Zodyl']::text[],11),
  ('アニメ・マンガ','ガチアクタ','ジャバー',array['Jabber']::text[],12),
  ('アニメ・マンガ','ガチアクタ','レグト',array['Regto']::text[],13),
  ('アニメ・マンガ','ガチアクタ','アモ',array['Amo']::text[],14),
  -- 光が死んだ夏
  ('アニメ・マンガ','光が死んだ夏','よしき',array['辻中佳紀']::text[],1),
  ('アニメ・マンガ','光が死んだ夏','ヒカル',array['光']::text[],2),
  ('アニメ・マンガ','光が死んだ夏','山岸朝子',array[]::text[],3),
  ('アニメ・マンガ','光が死んだ夏','巻ゆうた',array[]::text[],4),
  ('アニメ・マンガ','光が死んだ夏','暮林理恵',array[]::text[],5),
  ('アニメ・マンガ','光が死んだ夏','田中',array[]::text[],6),
  ('アニメ・マンガ','光が死んだ夏','田所結希',array[]::text[],7),
  -- 逃げ上手の若君
  ('アニメ・マンガ','逃げ上手の若君','北条時行',array[]::text[],1),
  ('アニメ・マンガ','逃げ上手の若君','雫',array[]::text[],2),
  ('アニメ・マンガ','逃げ上手の若君','弧次郎',array[]::text[],3),
  ('アニメ・マンガ','逃げ上手の若君','亜也子',array[]::text[],4),
  ('アニメ・マンガ','逃げ上手の若君','風間玄蕃',array[]::text[],5),
  ('アニメ・マンガ','逃げ上手の若君','吹雪',array[]::text[],6),
  ('アニメ・マンガ','逃げ上手の若君','諏訪頼重',array[]::text[],7),
  ('アニメ・マンガ','逃げ上手の若君','足利尊氏',array[]::text[],8),
  ('アニメ・マンガ','逃げ上手の若君','小笠原貞宗',array[]::text[],9),
  -- MASHLE
  ('アニメ・マンガ','MASHLE','マッシュ・バーンデッド',array[]::text[],1),
  ('アニメ・マンガ','MASHLE','フィン・エイムズ',array[]::text[],2),
  ('アニメ・マンガ','MASHLE','ランス・クラウン',array[]::text[],3),
  ('アニメ・マンガ','MASHLE','ドット・バレット',array[]::text[],4),
  ('アニメ・マンガ','MASHLE','レモン・アーヴィン',array[]::text[],5),
  ('アニメ・マンガ','MASHLE','レイン・エイムズ',array[]::text[],6),
  ('アニメ・マンガ','MASHLE','アベル・ウォーカー',array[]::text[],7),
  ('アニメ・マンガ','MASHLE','アビス・レイザー',array[]::text[],8),
  ('アニメ・マンガ','MASHLE','オーター・マドル',array[]::text[],9),
  ('アニメ・マンガ','MASHLE','マーガレット・マカロン',array[]::text[],10),
  -- ダンジョン飯
  ('アニメ・マンガ','ダンジョン飯','ライオス',array[]::text[],1),
  ('アニメ・マンガ','ダンジョン飯','マルシル',array[]::text[],2),
  ('アニメ・マンガ','ダンジョン飯','チルチャック',array[]::text[],3),
  ('アニメ・マンガ','ダンジョン飯','センシ',array[]::text[],4),
  ('アニメ・マンガ','ダンジョン飯','イヅツミ',array[]::text[],5),
  ('アニメ・マンガ','ダンジョン飯','ファリン',array[]::text[],6),
  ('アニメ・マンガ','ダンジョン飯','ナマリ',array[]::text[],7),
  ('アニメ・マンガ','ダンジョン飯','シュロー',array[]::text[],8),
  ('アニメ・マンガ','ダンジョン飯','カブルー',array[]::text[],9),
  ('アニメ・マンガ','ダンジョン飯','ミスルン',array[]::text[],10),
  -- らんま1/2
  ('アニメ・マンガ','らんま1/2','早乙女乱馬',array[]::text[],1),
  ('アニメ・マンガ','らんま1/2','らんま',array[]::text[],2),
  ('アニメ・マンガ','らんま1/2','天道あかね',array[]::text[],3),
  ('アニメ・マンガ','らんま1/2','天道なびき',array[]::text[],4),
  ('アニメ・マンガ','らんま1/2','天道かすみ',array[]::text[],5),
  ('アニメ・マンガ','らんま1/2','早乙女玄馬',array[]::text[],6),
  ('アニメ・マンガ','らんま1/2','響良牙',array[]::text[],7),
  ('アニメ・マンガ','らんま1/2','シャンプー',array[]::text[],8),
  ('アニメ・マンガ','らんま1/2','九能帯刀',array[]::text[],9),
  ('アニメ・マンガ','らんま1/2','久遠寺右京',array[]::text[],10),
  ('アニメ・マンガ','らんま1/2','ムース',array[]::text[],11),
  -- その着せ替え人形は恋をする
  ('アニメ・マンガ','その着せ替え人形は恋をする','五条新菜',array[]::text[],1),
  ('アニメ・マンガ','その着せ替え人形は恋をする','喜多川海夢',array[]::text[],2),
  ('アニメ・マンガ','その着せ替え人形は恋をする','乾紗寿叶',array['ジュジュ']::text[],3),
  ('アニメ・マンガ','その着せ替え人形は恋をする','乾心寿',array[]::text[],4),
  ('アニメ・マンガ','その着せ替え人形は恋をする','菅谷乃羽',array[]::text[],5),
  ('アニメ・マンガ','その着せ替え人形は恋をする','大空',array[]::text[],6),
  -- シャングリラ・フロンティア
  ('アニメ・マンガ','シャングリラ・フロンティア','サンラク',array['陽務楽郎']::text[],1),
  ('アニメ・マンガ','シャングリラ・フロンティア','サイガ-0',array['斎賀玲']::text[],2),
  ('アニメ・マンガ','シャングリラ・フロンティア','アーサー・ペンシルゴン',array['天音永遠']::text[],3),
  ('アニメ・マンガ','シャングリラ・フロンティア','オイカッツォ',array['魚臣慧']::text[],4),
  ('アニメ・マンガ','シャングリラ・フロンティア','エムル',array[]::text[],5),
  ('アニメ・マンガ','シャングリラ・フロンティア','ヴァイスアッシュ',array[]::text[],6),
  ('アニメ・マンガ','シャングリラ・フロンティア','ウェザエモン',array[]::text[],7),
  ('アニメ・マンガ','シャングリラ・フロンティア','サイガ-100',array['斎賀百']::text[],8),
  -- 地獄楽
  ('アニメ・マンガ','地獄楽','画眉丸',array[]::text[],1),
  ('アニメ・マンガ','地獄楽','山田浅ェ門佐切',array[]::text[],2),
  ('アニメ・マンガ','地獄楽','杠',array[]::text[],3),
  ('アニメ・マンガ','地獄楽','亜左弔兵衛',array[]::text[],4),
  ('アニメ・マンガ','地獄楽','山田浅ェ門桐馬',array[]::text[],5),
  ('アニメ・マンガ','地獄楽','山田浅ェ門士遠',array[]::text[],6),
  ('アニメ・マンガ','地獄楽','山田浅ェ門典坐',array[]::text[],7),
  ('アニメ・マンガ','地獄楽','ヌルガイ',array[]::text[],8),
  ('アニメ・マンガ','地獄楽','山田浅ェ門付知',array[]::text[],9),
  ('アニメ・マンガ','地獄楽','山田浅ェ門殊現',array[]::text[],10);

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
