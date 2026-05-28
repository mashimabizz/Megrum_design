-- =====================================================================
-- iter168.22: 同一人物設計に合わせた推しマスタ拡充
-- =====================================================================
-- グループ所属・別グループ所属・ソロ活動をまたいで推される実在人物を
-- 追加し、明示的に同じ oshi_entities_master へ紐付ける。

create temporary table _megrum_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _megrum_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('K-POP男性', 'ASTRO', array['아스트로']::text[], 'group', 38),
  ('K-POP女性', 'IZ*ONE', array['아이즈원', 'アイズワン', 'IZONE']::text[], 'group', 39),
  ('国内男性', 'DISH//', array['ディッシュ']::text[], 'group', 40),
  ('声優', 'μ''s', array['ミューズ', 'ラブライブ！ μ''s']::text[], 'group', 40),
  ('声優', 'Aqours', array['アクア', 'ラブライブ！サンシャイン!! Aqours']::text[], 'group', 41),
  ('声優', 'Roselia', array['ロゼリア', 'BanG Dream! Roselia']::text[], 'group', 42),
  ('声優', '宮野真守', array['Mamoru Miyano']::text[], 'solo', 43),
  ('声優', '水瀬いのり', array['Inori Minase']::text[], 'solo', 44),
  ('声優', '内田雄馬', array['Yuma Uchida']::text[], 'solo', 45),
  ('声優', '小野賢章', array['Kensho Ono']::text[], 'solo', 46),
  ('声優', '江口拓也', array['Takuya Eguchi']::text[], 'solo', 47),
  ('声優', '諏訪部順一', array['Junichi Suwabe']::text[], 'solo', 48),
  ('声優', '石川界人', array['Kaito Ishikawa']::text[], 'solo', 49),
  ('声優', '花澤香菜', array['Kana Hanazawa']::text[], 'solo', 50),
  ('声優', '雨宮天', array['Sora Amamiya']::text[], 'solo', 51),
  ('声優', '小倉唯', array['Yui Ogura']::text[], 'solo', 52),
  ('俳優・タレント', '平野紫耀', array['Sho Hirano']::text[], 'solo', 30),
  ('俳優・タレント', '神宮寺勇太', array['Yuta Jinguji']::text[], 'solo', 31),
  ('俳優・タレント', '岸優太', array['Yuta Kishi']::text[], 'solo', 32),
  ('俳優・タレント', '佐野勇斗', array['Hayato Sano']::text[], 'solo', 33);

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
  -- K-POP男性
  ('K-POP男性','ASTRO','MJ',array['エムジェイ','엠제이','Kim Myung-jun']::text[],1),
  ('K-POP男性','ASTRO','ジンジン',array['JINJIN','진진','Park Jin-woo']::text[],2),
  ('K-POP男性','ASTRO','チャ・ウヌ',array['Cha Eun-woo','차은우','Eunwoo']::text[],3),
  ('K-POP男性','ASTRO','ムンビン',array['Moonbin','문빈']::text[],4),
  ('K-POP男性','ASTRO','ラキ',array['Rocky','라키','Park Min-hyuk']::text[],5),
  ('K-POP男性','ASTRO','ユンサナ',array['Yoon San-ha','윤산하','Sanha']::text[],6),
  -- K-POP女性
  ('K-POP女性','IZ*ONE','クォン・ウンビ',array['KWON EUNBI','권은비','ウンビ']::text[],1),
  ('K-POP女性','IZ*ONE','サクラ',array['SAKURA','사쿠라','宮脇咲良','Miyawaki Sakura']::text[],2),
  ('K-POP女性','IZ*ONE','カン・ヘウォン',array['KANG HYEWON','강혜원','ヘウォン']::text[],3),
  ('K-POP女性','IZ*ONE','チェ・イェナ',array['CHOI YENA','최예나','イェナ']::text[],4),
  ('K-POP女性','IZ*ONE','イ・チェヨン',array['LEE CHAEYEON','이채연','チェヨン']::text[],5),
  ('K-POP女性','IZ*ONE','キム・チェウォン',array['KIM CHAEWON','김채원','チェウォン']::text[],6),
  ('K-POP女性','IZ*ONE','キム・ミンジュ',array['KIM MINJU','김민주','ミンジュ']::text[],7),
  ('K-POP女性','IZ*ONE','矢吹奈子',array['Yabuki Nako','야부키 나코','奈子']::text[],8),
  ('K-POP女性','IZ*ONE','本田仁美',array['Honda Hitomi','혼다 히토미','仁美']::text[],9),
  ('K-POP女性','IZ*ONE','チョ・ユリ',array['JO YURI','조유리','ユリ']::text[],10),
  ('K-POP女性','IZ*ONE','ユジン',array['AN YUJIN','안유진','アン・ユジン','アンユジン']::text[],11),
  ('K-POP女性','IZ*ONE','ウォニョン',array['JANG WONYOUNG','장원영','チャン・ウォニョン','チャンウォニョン']::text[],12),
  -- 国内男性
  ('国内男性','FANTASTICS','世界',array['Sekai']::text[],1),
  ('国内男性','FANTASTICS','佐藤大樹',array['Taiki Sato']::text[],2),
  ('国内男性','FANTASTICS','澤本夏輝',array['Natsuki Sawamoto']::text[],3),
  ('国内男性','FANTASTICS','瀬口黎弥',array['Leiya Seguchi']::text[],4),
  ('国内男性','FANTASTICS','堀夏喜',array['Natsuki Hori']::text[],5),
  ('国内男性','FANTASTICS','木村慧人',array['Keito Kimura']::text[],6),
  ('国内男性','FANTASTICS','八木勇征',array['Yusei Yagi']::text[],7),
  ('国内男性','FANTASTICS','中島颯太',array['Sota Nakajima']::text[],8),
  ('国内男性','DISH//','北村匠海',array['Takumi Kitamura']::text[],1),
  ('国内男性','DISH//','矢部昌暉',array['Masaki Yabe']::text[],2),
  ('国内男性','DISH//','橘柊生',array['Toi Tachibana']::text[],3),
  ('国内男性','DISH//','泉大智',array['Daichi Izumi']::text[],4),
  ('国内男性','M!LK','佐野勇斗',array['Hayato Sano']::text[],1),
  ('国内男性','M!LK','塩﨑太智',array['Daichi Shiozaki']::text[],2),
  ('国内男性','M!LK','曽野舜太',array['Shunta Sono']::text[],3),
  ('国内男性','M!LK','山中柔太朗',array['Jyutaro Yamanaka','Jutaro Yamanaka']::text[],4),
  ('国内男性','M!LK','吉田仁人',array['Jinto Yoshida']::text[],5),
  ('国内男性','IMP.','佐藤新',array['Arata Sato']::text[],1),
  ('国内男性','IMP.','影山拓也',array['Takuya Kageyama']::text[],2),
  ('国内男性','IMP.','鈴木大河',array['Taiga Suzuki']::text[],3),
  ('国内男性','IMP.','基俊介',array['Shunsuke Motoi']::text[],4),
  ('国内男性','IMP.','椿泰我',array['Taiga Tsubaki']::text[],5),
  ('国内男性','IMP.','横原悠毅',array['Yuki Yokohara']::text[],6),
  ('国内男性','IMP.','松井奏',array['Minato Matsui']::text[],7),
  -- 声優ユニット
  ('声優','μ''s','新田恵海',array['Emi Nitta']::text[],1),
  ('声優','μ''s','内田彩',array['Aya Uchida']::text[],2),
  ('声優','μ''s','三森すずこ',array['Suzuko Mimori']::text[],3),
  ('声優','μ''s','飯田里穂',array['Riho Iida']::text[],4),
  ('声優','μ''s','Pile',array[]::text[],5),
  ('声優','μ''s','楠田亜衣奈',array['Aina Kusuda']::text[],6),
  ('声優','μ''s','久保ユリカ',array['Yurika Kubo']::text[],7),
  ('声優','μ''s','徳井青空',array['Sora Tokui']::text[],8),
  ('声優','μ''s','南條愛乃',array['Yoshino Nanjo']::text[],9),
  ('声優','Aqours','伊波杏樹',array['Anju Inami']::text[],1),
  ('声優','Aqours','逢田梨香子',array['Rikako Aida']::text[],2),
  ('声優','Aqours','諏訪ななか',array['Nanaka Suwa']::text[],3),
  ('声優','Aqours','小宮有紗',array['Arisa Komiya']::text[],4),
  ('声優','Aqours','斉藤朱夏',array['Shuka Saito']::text[],5),
  ('声優','Aqours','小林愛香',array['Aika Kobayashi']::text[],6),
  ('声優','Aqours','高槻かなこ',array['Kanako Takatsuki']::text[],7),
  ('声優','Aqours','鈴木愛奈',array['Aina Suzuki']::text[],8),
  ('声優','Aqours','降幡愛',array['Ai Furihata']::text[],9),
  ('声優','Roselia','相羽あいな',array['Aina Aiba']::text[],1),
  ('声優','Roselia','工藤晴香',array['Haruka Kudo']::text[],2),
  ('声優','Roselia','中島由貴',array['Yuki Nakashima']::text[],3),
  ('声優','Roselia','櫻川めぐ',array['Megu Sakuragawa']::text[],4),
  ('声優','Roselia','志崎樺音',array['Kanon Shizaki']::text[],5);

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

with solo_groups as (
  select
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

create temporary table _megrum_manual_entities (
  identity_key text not null,
  canonical_name text not null,
  entity_type text not null,
  aliases text[] not null default '{}',
  display_order integer not null default 0
) on commit drop;

insert into _megrum_manual_entities (identity_key, canonical_name, entity_type, aliases, display_order) values
  ('person:sakura-miyawaki','サクラ','person',array['SAKURA','宮脇咲良','Miyawaki Sakura','사쿠라']::text[],1),
  ('person:kim-chaewon','キム・チェウォン','person',array['KIM CHAEWON','チェウォン','김채원']::text[],2),
  ('person:ahn-yujin','ユジン','person',array['AN YUJIN','アン・ユジン','アンユジン','안유진']::text[],3),
  ('person:jang-wonyoung','ウォニョン','person',array['JANG WONYOUNG','チャン・ウォニョン','チャンウォニョン','장원영']::text[],4),
  ('person:cha-eunwoo','チャ・ウヌ','person',array['Cha Eun-woo','Eunwoo','차은우']::text[],5),
  ('person:hirano-sho','平野紫耀','person',array['Sho Hirano']::text[],6),
  ('person:jinguji-yuta','神宮寺勇太','person',array['Yuta Jinguji']::text[],7),
  ('person:kishi-yuta','岸優太','person',array['Yuta Kishi']::text[],8),
  ('person:yagi-yusei','八木勇征','person',array['Yusei Yagi']::text[],9),
  ('person:kitamura-takumi','北村匠海','person',array['Takumi Kitamura']::text[],10),
  ('person:sano-hayato','佐野勇斗','person',array['Hayato Sano']::text[],11);

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
  aliases,
  display_order
from _megrum_manual_entities
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
      ),
      display_order = excluded.display_order;

create temporary table _megrum_manual_entity_links (
  row_kind text not null check (row_kind in ('group', 'character')),
  genre_name text not null,
  group_name text,
  selectable_name text not null,
  identity_key text not null
) on commit drop;

insert into _megrum_manual_entity_links (
  row_kind,
  genre_name,
  group_name,
  selectable_name,
  identity_key
) values
  ('character','K-POP女性','LE SSERAFIM','サクラ','person:sakura-miyawaki'),
  ('character','K-POP女性','IZ*ONE','サクラ','person:sakura-miyawaki'),
  ('character','K-POP女性','LE SSERAFIM','キム・チェウォン','person:kim-chaewon'),
  ('character','K-POP女性','IZ*ONE','キム・チェウォン','person:kim-chaewon'),
  ('character','K-POP女性','IVE','ユジン','person:ahn-yujin'),
  ('character','K-POP女性','IZ*ONE','ユジン','person:ahn-yujin'),
  ('character','K-POP女性','IVE','ウォニョン','person:jang-wonyoung'),
  ('character','K-POP女性','IZ*ONE','ウォニョン','person:jang-wonyoung'),
  ('character','K-POP男性','ASTRO','チャ・ウヌ','person:cha-eunwoo'),
  ('group','海外エンタメ',null,'チャ・ウヌ','person:cha-eunwoo'),
  ('character','国内男性','Number_i','平野紫耀','person:hirano-sho'),
  ('group','俳優・タレント',null,'平野紫耀','person:hirano-sho'),
  ('character','国内男性','Number_i','神宮寺勇太','person:jinguji-yuta'),
  ('group','俳優・タレント',null,'神宮寺勇太','person:jinguji-yuta'),
  ('character','国内男性','Number_i','岸優太','person:kishi-yuta'),
  ('group','俳優・タレント',null,'岸優太','person:kishi-yuta'),
  ('character','国内男性','FANTASTICS','八木勇征','person:yagi-yusei'),
  ('group','俳優・タレント',null,'八木勇征','person:yagi-yusei'),
  ('character','国内男性','DISH//','北村匠海','person:kitamura-takumi'),
  ('group','俳優・タレント',null,'北村匠海','person:kitamura-takumi'),
  ('character','国内男性','M!LK','佐野勇斗','person:sano-hayato'),
  ('group','俳優・タレント',null,'佐野勇斗','person:sano-hayato');

update public.groups_master gm
set entity_id = e.id
from _megrum_manual_entity_links ml
join public.genres_master ge on ge.name = ml.genre_name
join public.oshi_entities_master e on e.identity_key = ml.identity_key
where ml.row_kind = 'group'
  and gm.genre_id = ge.id
  and gm.name = ml.selectable_name
  and gm.entity_id is distinct from e.id;

update public.characters_master cm
set entity_id = e.id
from _megrum_manual_entity_links ml
join public.genres_master ge on ge.name = ml.genre_name
join public.groups_master gm on gm.genre_id = ge.id and gm.name = ml.group_name
join public.oshi_entities_master e on e.identity_key = ml.identity_key
where ml.row_kind = 'character'
  and cm.group_id = gm.id
  and cm.name = ml.selectable_name
  and cm.entity_id is distinct from e.id;

delete from public.oshi_entities_master e
where (
    e.identity_key like 'person:member:%'
    or e.identity_key like 'person:solo:%'
  )
  and not exists (
    select 1
    from public.groups_master gm
    where gm.entity_id = e.id
  )
  and not exists (
    select 1
    from public.characters_master cm
    where cm.entity_id = e.id
  )
  and not exists (
    select 1
    from _megrum_manual_entities me
    where me.identity_key = e.identity_key
  );
