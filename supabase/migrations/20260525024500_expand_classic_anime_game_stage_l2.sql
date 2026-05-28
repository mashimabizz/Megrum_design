-- =====================================================================
-- iter168.30: 定番アニメ/ゲーム/2.5次元のL2厚増し
-- =====================================================================
-- 大型IPとしてL2候補がまだ薄い定番アニメ・ゲーム・舞台作品を補完する。

create temporary table _megrum_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _megrum_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- アニメ・マンガ: 主要キャラ補完
  ('アニメ・マンガ','ワンパンマン','サイタマ',array[]::text[],4),
  ('アニメ・マンガ','ワンパンマン','ジェノス',array[]::text[],5),
  ('アニメ・マンガ','ワンパンマン','音速のソニック',array[]::text[],6),
  ('アニメ・マンガ','ワンパンマン','戦慄のタツマキ',array[]::text[],7),
  ('アニメ・マンガ','ワンパンマン','地獄のフブキ',array[]::text[],8),
  ('アニメ・マンガ','ワンパンマン','キング',array[]::text[],9),
  ('アニメ・マンガ','ワンパンマン','ガロウ',array[]::text[],10),
  ('アニメ・マンガ','るろうに剣心','緋村剣心',array[]::text[],5),
  ('アニメ・マンガ','るろうに剣心','神谷薫',array[]::text[],6),
  ('アニメ・マンガ','るろうに剣心','相楽左之助',array[]::text[],7),
  ('アニメ・マンガ','るろうに剣心','明神弥彦',array[]::text[],8),
  ('アニメ・マンガ','るろうに剣心','斎藤一',array[]::text[],9),
  ('アニメ・マンガ','るろうに剣心','四乃森蒼紫',array[]::text[],10),
  ('アニメ・マンガ','るろうに剣心','志々雄真実',array[]::text[],11),
  ('アニメ・マンガ','るろうに剣心','瀬田宗次郎',array[]::text[],12),
  ('アニメ・マンガ','地縛少年花子くん','花子くん',array[]::text[],5),
  ('アニメ・マンガ','地縛少年花子くん','八尋寧々',array[]::text[],6),
  ('アニメ・マンガ','地縛少年花子くん','源光',array[]::text[],7),
  ('アニメ・マンガ','地縛少年花子くん','源輝',array[]::text[],8),
  ('アニメ・マンガ','地縛少年花子くん','赤根葵',array[]::text[],9),
  ('アニメ・マンガ','地縛少年花子くん','蒼井茜',array[]::text[],10),
  ('アニメ・マンガ','地縛少年花子くん','つかさ',array[]::text[],11),
  ('アニメ・マンガ','地縛少年花子くん','ミツバ',array[]::text[],12),
  ('アニメ・マンガ','怪獣8号','日比野カフカ',array[]::text[],5),
  ('アニメ・マンガ','怪獣8号','市川レノ',array[]::text[],6),
  ('アニメ・マンガ','怪獣8号','四ノ宮キコル',array[]::text[],7),
  ('アニメ・マンガ','怪獣8号','亜白ミナ',array[]::text[],8),
  ('アニメ・マンガ','怪獣8号','保科宗四郎',array[]::text[],9),
  ('アニメ・マンガ','怪獣8号','鳴海弦',array[]::text[],10),
  ('アニメ・マンガ','怪獣8号','古橋伊春',array[]::text[],11),
  ('アニメ・マンガ','薬屋のひとりごと','猫猫',array['マオマオ']::text[],5),
  ('アニメ・マンガ','薬屋のひとりごと','壬氏',array[]::text[],6),
  ('アニメ・マンガ','薬屋のひとりごと','高順',array[]::text[],7),
  ('アニメ・マンガ','薬屋のひとりごと','玉葉妃',array[]::text[],8),
  ('アニメ・マンガ','薬屋のひとりごと','梨花妃',array[]::text[],9),
  ('アニメ・マンガ','薬屋のひとりごと','小蘭',array[]::text[],10),
  ('アニメ・マンガ','薬屋のひとりごと','羅漢',array[]::text[],11),
  ('アニメ・マンガ','鋼の錬金術師','エドワード・エルリック',array[]::text[],5),
  ('アニメ・マンガ','鋼の錬金術師','アルフォンス・エルリック',array[]::text[],6),
  ('アニメ・マンガ','鋼の錬金術師','ウィンリィ・ロックベル',array[]::text[],7),
  ('アニメ・マンガ','鋼の錬金術師','ロイ・マスタング',array[]::text[],8),
  ('アニメ・マンガ','鋼の錬金術師','リザ・ホークアイ',array[]::text[],9),
  ('アニメ・マンガ','鋼の錬金術師','マース・ヒューズ',array[]::text[],10),
  ('アニメ・マンガ','鋼の錬金術師','スカー',array[]::text[],11),
  ('アニメ・マンガ','鋼の錬金術師','リン・ヤオ',array[]::text[],12),
  -- ゲーム: 定番タイトルの主要キャラ補完
  ('ゲーム','ファイナルファンタジーVII','クラウド・ストライフ',array[]::text[],5),
  ('ゲーム','ファイナルファンタジーVII','ティファ・ロックハート',array[]::text[],6),
  ('ゲーム','ファイナルファンタジーVII','エアリス・ゲインズブール',array[]::text[],7),
  ('ゲーム','ファイナルファンタジーVII','セフィロス',array[]::text[],8),
  ('ゲーム','ファイナルファンタジーVII','ザックス・フェア',array[]::text[],9),
  ('ゲーム','ファイナルファンタジーVII','バレット・ウォーレス',array[]::text[],10),
  ('ゲーム','ファイナルファンタジーVII','ユフィ・キサラギ',array[]::text[],11),
  ('ゲーム','ファイナルファンタジーVII','ヴィンセント・ヴァレンタイン',array[]::text[],12),
  ('ゲーム','ペルソナ5','主人公',array['ジョーカー']::text[],6),
  ('ゲーム','ペルソナ5','坂本竜司',array[]::text[],7),
  ('ゲーム','ペルソナ5','モルガナ',array[]::text[],8),
  ('ゲーム','ペルソナ5','高巻杏',array[]::text[],9),
  ('ゲーム','ペルソナ5','喜多川祐介',array[]::text[],10),
  ('ゲーム','ペルソナ5','新島真',array[]::text[],11),
  ('ゲーム','ペルソナ5','佐倉双葉',array[]::text[],12),
  ('ゲーム','ペルソナ5','奥村春',array[]::text[],13),
  ('ゲーム','ペルソナ5','明智吾郎',array[]::text[],14),
  ('ゲーム','スプラトゥーン','アオリ',array[]::text[],5),
  ('ゲーム','スプラトゥーン','ホタル',array[]::text[],6),
  ('ゲーム','スプラトゥーン','ヒメ',array[]::text[],7),
  ('ゲーム','スプラトゥーン','イイダ',array[]::text[],8),
  ('ゲーム','スプラトゥーン','フウカ',array[]::text[],9),
  ('ゲーム','スプラトゥーン','ウツホ',array[]::text[],10),
  ('ゲーム','スプラトゥーン','マンタロー',array[]::text[],11),
  ('ゲーム','キングダム ハーツ','ソラ',array[]::text[],5),
  ('ゲーム','キングダム ハーツ','リク',array[]::text[],6),
  ('ゲーム','キングダム ハーツ','カイリ',array[]::text[],7),
  ('ゲーム','キングダム ハーツ','ロクサス',array[]::text[],8),
  ('ゲーム','キングダム ハーツ','アクセル',array[]::text[],9),
  ('ゲーム','キングダム ハーツ','シオン',array[]::text[],10),
  ('ゲーム','キングダム ハーツ','アクア',array[]::text[],11),
  ('ゲーム','キングダム ハーツ','テラ',array[]::text[],12),
  ('ゲーム','キングダム ハーツ','ヴェントゥス',array[]::text[],13),
  ('ゲーム','刀剣乱舞ONLINE','三日月宗近',array[]::text[],5),
  ('ゲーム','刀剣乱舞ONLINE','小狐丸',array[]::text[],6),
  ('ゲーム','刀剣乱舞ONLINE','石切丸',array[]::text[],7),
  ('ゲーム','刀剣乱舞ONLINE','加州清光',array[]::text[],8),
  ('ゲーム','刀剣乱舞ONLINE','大和守安定',array[]::text[],9),
  ('ゲーム','刀剣乱舞ONLINE','和泉守兼定',array[]::text[],10),
  ('ゲーム','刀剣乱舞ONLINE','堀川国広',array[]::text[],11),
  ('ゲーム','刀剣乱舞ONLINE','鶴丸国永',array[]::text[],12),
  ('ゲーム','刀剣乱舞ONLINE','燭台切光忠',array[]::text[],13),
  ('ゲーム','刀剣乱舞ONLINE','薬研藤四郎',array[]::text[],14),
  ('ゲーム','刀剣乱舞ONLINE','へし切長谷部',array[]::text[],15),
  ('ゲーム','刀剣乱舞ONLINE','山姥切国広',array[]::text[],16),
  ('ゲーム','刀剣乱舞ONLINE','髭切',array[]::text[],17),
  ('ゲーム','刀剣乱舞ONLINE','膝丸',array[]::text[],18),
  -- 2.5次元・舞台: キャラクター選択として使いやすいL2補完
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','三日月宗近',array[]::text[],7),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','小狐丸',array[]::text[],8),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','石切丸',array[]::text[],9),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','加州清光',array[]::text[],10),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','大和守安定',array[]::text[],11),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','和泉守兼定',array[]::text[],12),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','堀川国広',array[]::text[],13),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','膝丸',array[]::text[],14),
  ('2.5次元・舞台','舞台「刀剣乱舞」','三日月宗近',array[]::text[],5),
  ('2.5次元・舞台','舞台「刀剣乱舞」','山姥切国広',array[]::text[],6),
  ('2.5次元・舞台','舞台「刀剣乱舞」','へし切長谷部',array[]::text[],7),
  ('2.5次元・舞台','舞台「刀剣乱舞」','鶴丸国永',array[]::text[],8),
  ('2.5次元・舞台','舞台「刀剣乱舞」','燭台切光忠',array[]::text[],9),
  ('2.5次元・舞台','舞台「刀剣乱舞」','薬研藤四郎',array[]::text[],10),
  ('2.5次元・舞台','舞台「刀剣乱舞」','一期一振',array[]::text[],11),
  ('2.5次元・舞台','舞台「刀剣乱舞」','歌仙兼定',array[]::text[],12),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','越前リョーマ',array[]::text[],6),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','手塚国光',array[]::text[],7),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','不二周助',array[]::text[],8),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','大石秀一郎',array[]::text[],9),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','菊丸英二',array[]::text[],10),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','跡部景吾',array[]::text[],11),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','幸村精市',array[]::text[],12);

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
