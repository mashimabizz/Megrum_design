-- =====================================================================
-- iter168.28: ビッグ作品/ゲームのL2厚増し batch 2
-- =====================================================================
-- まだ主要キャラが薄かった大型作品・大型ゲームを補完する。

create temporary table _megrum_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _megrum_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- アニメ・マンガ: 既存大型作品の補完
  ('アニメ・マンガ','黒執事','グレル・サトクリフ',array[]::text[],3),
  ('アニメ・マンガ','黒執事','アンダーテイカー',array[]::text[],4),
  ('アニメ・マンガ','黒執事','エリザベス・ミッドフォード',array[]::text[],5),
  ('アニメ・マンガ','黒執事','劉',array[]::text[],6),
  ('アニメ・マンガ','黒執事','藍猫',array[]::text[],7),
  ('アニメ・マンガ','Free!','七瀬遙',array[]::text[],4),
  ('アニメ・マンガ','Free!','橘真琴',array[]::text[],5),
  ('アニメ・マンガ','Free!','松岡凛',array[]::text[],6),
  ('アニメ・マンガ','Free!','葉月渚',array[]::text[],7),
  ('アニメ・マンガ','Free!','竜ヶ崎怜',array[]::text[],8),
  ('アニメ・マンガ','Free!','山崎宗介',array[]::text[],9),
  ('アニメ・マンガ','夏目友人帳','名取周一',array[]::text[],3),
  ('アニメ・マンガ','夏目友人帳','田沼要',array[]::text[],4),
  ('アニメ・マンガ','夏目友人帳','多軌透',array[]::text[],5),
  ('アニメ・マンガ','夏目友人帳','的場静司',array[]::text[],6),
  ('アニメ・マンガ','夏目友人帳','ヒノエ',array[]::text[],7),
  ('アニメ・マンガ','SAKAMOTO DAYS','神々廻',array[]::text[],5),
  ('アニメ・マンガ','SAKAMOTO DAYS','大佛',array[]::text[],6),
  ('アニメ・マンガ','SAKAMOTO DAYS','勢羽夏生',array[]::text[],7),
  ('アニメ・マンガ','SAKAMOTO DAYS','赤尾晶',array[]::text[],8),
  ('アニメ・マンガ','SAKAMOTO DAYS','楽',array[]::text[],9),
  ('アニメ・マンガ','WITCH WATCH','宮尾音夢',array[]::text[],5),
  ('アニメ・マンガ','WITCH WATCH','霧生見晴',array[]::text[],6),
  ('アニメ・マンガ','WITCH WATCH','真桑悠里',array[]::text[],7),
  ('アニメ・マンガ','WITCH WATCH','嬉野久々実',array[]::text[],8),
  ('アニメ・マンガ','カードキャプターさくら','木之本桃矢',array[]::text[],5),
  ('アニメ・マンガ','カードキャプターさくら','月城雪兎',array[]::text[],6),
  ('アニメ・マンガ','カードキャプターさくら','月',array['ユエ']::text[],7),
  ('アニメ・マンガ','カードキャプターさくら','詩之本秋穂',array[]::text[],8),
  ('アニメ・マンガ','弱虫ペダル','金城真護',array[]::text[],5),
  ('アニメ・マンガ','弱虫ペダル','田所迅',array[]::text[],6),
  ('アニメ・マンガ','弱虫ペダル','真波山岳',array[]::text[],7),
  ('アニメ・マンガ','弱虫ペダル','東堂尽八',array[]::text[],8),
  ('アニメ・マンガ','弱虫ペダル','荒北靖友',array[]::text[],9),
  ('アニメ・マンガ','弱虫ペダル','新開隼人',array[]::text[],10),
  ('アニメ・マンガ','ゴールデンカムイ','鶴見篤四郎',array[]::text[],5),
  ('アニメ・マンガ','ゴールデンカムイ','月島基',array[]::text[],6),
  ('アニメ・マンガ','ゴールデンカムイ','鯉登音之進',array[]::text[],7),
  ('アニメ・マンガ','ゴールデンカムイ','谷垣源次郎',array[]::text[],8),
  ('アニメ・マンガ','ゴールデンカムイ','牛山辰馬',array[]::text[],9),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','山本武',array[]::text[],5),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','雲雀恭弥',array[]::text[],6),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','六道骸',array[]::text[],7),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','笹川了平',array[]::text[],8),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','ランボ',array[]::text[],9),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','クローム髑髏',array[]::text[],10),
  -- ゲーム: 大型タイトルの補完
  ('ゲーム','原神','ウェンティ',array[]::text[],9),
  ('ゲーム','原神','鍾離',array[]::text[],10),
  ('ゲーム','原神','雷電将軍',array[]::text[],11),
  ('ゲーム','原神','ナヒーダ',array[]::text[],12),
  ('ゲーム','原神','フリーナ',array[]::text[],13),
  ('ゲーム','原神','ヌヴィレット',array[]::text[],14),
  ('ゲーム','原神','魈',array[]::text[],15),
  ('ゲーム','原神','タルタリヤ',array[]::text[],16),
  ('ゲーム','原神','放浪者',array[]::text[],17),
  ('ゲーム','原神','神里綾華',array[]::text[],18),
  ('ゲーム','崩壊:スターレイル','丹恒',array[]::text[],6),
  ('ゲーム','崩壊:スターレイル','カフカ',array[]::text[],7),
  ('ゲーム','崩壊:スターレイル','銀狼',array[]::text[],8),
  ('ゲーム','崩壊:スターレイル','景元',array[]::text[],9),
  ('ゲーム','崩壊:スターレイル','刃',array[]::text[],10),
  ('ゲーム','崩壊:スターレイル','アベンチュリン',array[]::text[],11),
  ('ゲーム','崩壊:スターレイル','ホタル',array[]::text[],12),
  ('ゲーム','崩壊:スターレイル','黄泉',array[]::text[],13),
  ('ゲーム','ゼンレスゾーンゼロ','エレン・ジョー',array[]::text[],5),
  ('ゲーム','ゼンレスゾーンゼロ','朱鳶',array['シュエン']::text[],6),
  ('ゲーム','ゼンレスゾーンゼロ','ジェーン・ドゥ',array[]::text[],7),
  ('ゲーム','ゼンレスゾーンゼロ','星見雅',array[]::text[],8),
  ('ゲーム','ゼンレスゾーンゼロ','ビリー・キッド',array[]::text[],9),
  ('ゲーム','ゼンレスゾーンゼロ','ニコ・デマラ',array[]::text[],10),
  ('ゲーム','アークナイツ','アーミヤ',array[]::text[],4),
  ('ゲーム','アークナイツ','チェン',array[]::text[],5),
  ('ゲーム','アークナイツ','シルバーアッシュ',array[]::text[],6),
  ('ゲーム','アークナイツ','エクシア',array[]::text[],7),
  ('ゲーム','アークナイツ','テキサス',array[]::text[],8),
  ('ゲーム','アークナイツ','W',array[]::text[],9),
  ('ゲーム','アークナイツ','ケルシー',array[]::text[],10),
  ('ゲーム','アークナイツ','スルト',array[]::text[],11),
  ('ゲーム','ウマ娘 プリティーダービー','スペシャルウィーク',array[]::text[],5),
  ('ゲーム','ウマ娘 プリティーダービー','サイレンススズカ',array[]::text[],6),
  ('ゲーム','ウマ娘 プリティーダービー','トウカイテイオー',array[]::text[],7),
  ('ゲーム','ウマ娘 プリティーダービー','メジロマックイーン',array[]::text[],8),
  ('ゲーム','ウマ娘 プリティーダービー','ライスシャワー',array[]::text[],9),
  ('ゲーム','ウマ娘 プリティーダービー','キタサンブラック',array[]::text[],10),
  ('ゲーム','ウマ娘 プリティーダービー','サトノダイヤモンド',array[]::text[],11),
  ('ゲーム','ブルーアーカイブ','空崎ヒナ',array[]::text[],5),
  ('ゲーム','ブルーアーカイブ','聖園ミカ',array[]::text[],6),
  ('ゲーム','ブルーアーカイブ','浅黄ムツキ',array[]::text[],7),
  ('ゲーム','ブルーアーカイブ','天童アリス',array[]::text[],8),
  ('ゲーム','ブルーアーカイブ','阿慈谷ヒフミ',array[]::text[],9),
  ('ゲーム','ブルーアーカイブ','白洲アズサ',array[]::text[],10),
  ('ゲーム','学園アイドルマスター','篠澤広',array[]::text[],5),
  ('ゲーム','学園アイドルマスター','紫雲清夏',array[]::text[],6),
  ('ゲーム','学園アイドルマスター','有村麻央',array[]::text[],7),
  ('ゲーム','学園アイドルマスター','姫崎莉波',array[]::text[],8),
  ('ゲーム','学園アイドルマスター','倉本千奈',array[]::text[],9),
  ('ゲーム','Identity V 第五人格','医師',array['エミリー・ダイアー']::text[],5),
  ('ゲーム','Identity V 第五人格','傭兵',array['ナワーブ・サベダー']::text[],6),
  ('ゲーム','Identity V 第五人格','囚人',array['ルカ・バルサー']::text[],7),
  ('ゲーム','Identity V 第五人格','納棺師',array['イソップ・カール']::text[],8),
  ('ゲーム','Identity V 第五人格','白黒無常',array[]::text[],9),
  ('ゲーム','Identity V 第五人格','血の女王',array['マリー']::text[],10),
  ('ゲーム','魔法使いの約束','スノウ',array[]::text[],5),
  ('ゲーム','魔法使いの約束','ホワイト',array[]::text[],6),
  ('ゲーム','魔法使いの約束','オーエン',array[]::text[],7),
  ('ゲーム','魔法使いの約束','ブラッドリー',array[]::text[],8),
  ('ゲーム','魔法使いの約束','ファウスト',array[]::text[],9),
  ('ゲーム','魔法使いの約束','シノ',array[]::text[],10),
  ('ゲーム','魔法使いの約束','ヒースクリフ',array[]::text[],11);

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
