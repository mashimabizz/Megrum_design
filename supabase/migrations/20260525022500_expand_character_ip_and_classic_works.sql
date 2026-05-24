-- =====================================================================
-- iter168.29: キャラクターIP/定番作品のL2厚増し
-- =====================================================================
-- グッズ交換の母数が大きい定番キャラクターIP・長寿作品の主要キャラを補完する。

create temporary table _ihub_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _ihub_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- キャラクターIP: 長寿/定番IP
  ('キャラクターIP','クレヨンしんちゃん','野原ひろし',array[]::text[],3),
  ('キャラクターIP','クレヨンしんちゃん','野原みさえ',array[]::text[],4),
  ('キャラクターIP','クレヨンしんちゃん','野原ひまわり',array[]::text[],5),
  ('キャラクターIP','クレヨンしんちゃん','シロ',array[]::text[],6),
  ('キャラクターIP','クレヨンしんちゃん','風間トオル',array[]::text[],7),
  ('キャラクターIP','クレヨンしんちゃん','桜田ネネ',array[]::text[],8),
  ('キャラクターIP','クレヨンしんちゃん','佐藤マサオ',array[]::text[],9),
  ('キャラクターIP','クレヨンしんちゃん','ボーちゃん',array[]::text[],10),
  ('キャラクターIP','ドラえもん','野比のび太',array['のび太']::text[],4),
  ('キャラクターIP','ドラえもん','源静香',array['しずかちゃん']::text[],5),
  ('キャラクターIP','ドラえもん','剛田武',array['ジャイアン']::text[],6),
  ('キャラクターIP','ドラえもん','骨川スネ夫',array['スネ夫']::text[],7),
  ('キャラクターIP','ドラえもん','ドラミ',array[]::text[],8),
  ('キャラクターIP','ドラえもん','出木杉英才',array['出木杉']::text[],9),
  ('キャラクターIP','ムーミン','ムーミンパパ',array[]::text[],3),
  ('キャラクターIP','ムーミン','ムーミンママ',array[]::text[],4),
  ('キャラクターIP','ムーミン','スナフキン',array[]::text[],5),
  ('キャラクターIP','ムーミン','リトルミイ',array[]::text[],6),
  ('キャラクターIP','ムーミン','ニョロニョロ',array[]::text[],7),
  ('キャラクターIP','ムーミン','スノークのおじょうさん',array[]::text[],8),
  ('キャラクターIP','PEANUTS','スヌーピー',array[]::text[],4),
  ('キャラクターIP','PEANUTS','チャーリー・ブラウン',array[]::text[],5),
  ('キャラクターIP','PEANUTS','ウッドストック',array[]::text[],6),
  ('キャラクターIP','PEANUTS','ルーシー',array[]::text[],7),
  ('キャラクターIP','PEANUTS','ライナス',array[]::text[],8),
  ('キャラクターIP','PEANUTS','サリー',array[]::text[],9),
  ('キャラクターIP','星のカービィ','ワドルディ',array[]::text[],5),
  ('キャラクターIP','星のカービィ','バンダナワドルディ',array[]::text[],6),
  ('キャラクターIP','星のカービィ','メタナイト',array[]::text[],7),
  ('キャラクターIP','星のカービィ','デデデ大王',array[]::text[],8),
  ('キャラクターIP','星のカービィ','マホロア',array[]::text[],9),
  ('キャラクターIP','すみっコぐらし','ざっそう',array[]::text[],7),
  ('キャラクターIP','すみっコぐらし','ふろしき',array[]::text[],8),
  ('キャラクターIP','すみっコぐらし','ほこり',array[]::text[],9),
  ('キャラクターIP','すみっコぐらし','えびふらいのしっぽ',array[]::text[],10),
  ('キャラクターIP','すみっコぐらし','あじふらいのしっぽ',array[]::text[],11),
  ('キャラクターIP','すみっコぐらし','たぴおか',array[]::text[],12),
  ('キャラクターIP','ちいかわ','ラッコ',array[]::text[],7),
  ('キャラクターIP','ちいかわ','シーサー',array[]::text[],8),
  ('キャラクターIP','ちいかわ','カブトムシ',array[]::text[],9),
  ('キャラクターIP','ちいかわ','古本屋',array['カニちゃん']::text[],10),
  ('キャラクターIP','ちいかわ','あのこ',array[]::text[],11),
  ('キャラクターIP','ちいかわ','でかつよ',array[]::text[],12),
  ('キャラクターIP','ハローキティ','ミミィ',array['ミミィ・ホワイト']::text[],3),
  ('キャラクターIP','ハローキティ','ディアダニエル',array[]::text[],4),
  ('キャラクターIP','ハローキティ','ジョージ・ホワイト',array[]::text[],5),
  ('キャラクターIP','ハローキティ','メアリー・ホワイト',array[]::text[],6),
  ('キャラクターIP','ハローキティ','チャーミーキティ',array[]::text[],7),
  ('キャラクターIP','マイメロディ','フラット',array[]::text[],3),
  ('キャラクターIP','マイメロディ','マイスウィートピアノ',array['ピアノちゃん']::text[],4),
  ('キャラクターIP','マイメロディ','リズム',array[]::text[],5),
  ('キャラクターIP','マイメロディ','歌ちゃん',array[]::text[],6),
  ('キャラクターIP','クロミ','バク',array[]::text[],3),
  ('キャラクターIP','クロミ','バコ',array[]::text[],4),
  ('キャラクターIP','クロミ','ニャンミ',array[]::text[],5),
  ('キャラクターIP','クロミ','ワンミ',array[]::text[],6),
  ('キャラクターIP','クロミ','コンミ',array[]::text[],7),
  ('キャラクターIP','シナモロール','カプチーノ',array[]::text[],4),
  ('キャラクターIP','シナモロール','モカ',array[]::text[],5),
  ('キャラクターIP','シナモロール','シフォン',array[]::text[],6),
  ('キャラクターIP','シナモロール','エスプレッソ',array[]::text[],7),
  ('キャラクターIP','シナモロール','みるく',array[]::text[],8),
  ('キャラクターIP','ポムポムプリン','マフィン',array[]::text[],3),
  ('キャラクターIP','ポムポムプリン','スコーン',array[]::text[],4),
  ('キャラクターIP','ポムポムプリン','ベーグル',array[]::text[],5),
  ('キャラクターIP','ポムポムプリン','タルト',array[]::text[],6),
  ('キャラクターIP','ポムポムプリン','カスタード',array[]::text[],7),
  -- アニメ・マンガ: 長寿/定番作品
  ('アニメ・マンガ','NARUTO -ナルト-','うずまきナルト',array[]::text[],6),
  ('アニメ・マンガ','NARUTO -ナルト-','うちはサスケ',array[]::text[],7),
  ('アニメ・マンガ','NARUTO -ナルト-','春野サクラ',array[]::text[],8),
  ('アニメ・マンガ','NARUTO -ナルト-','はたけカカシ',array[]::text[],9),
  ('アニメ・マンガ','NARUTO -ナルト-','日向ヒナタ',array[]::text[],10),
  ('アニメ・マンガ','NARUTO -ナルト-','我愛羅',array[]::text[],11),
  ('アニメ・マンガ','NARUTO -ナルト-','うちはイタチ',array[]::text[],12),
  ('アニメ・マンガ','NARUTO -ナルト-','奈良シカマル',array[]::text[],13),
  ('アニメ・マンガ','BLEACH','黒崎一護',array[]::text[],5),
  ('アニメ・マンガ','BLEACH','朽木ルキア',array[]::text[],6),
  ('アニメ・マンガ','BLEACH','井上織姫',array[]::text[],7),
  ('アニメ・マンガ','BLEACH','石田雨竜',array[]::text[],8),
  ('アニメ・マンガ','BLEACH','阿散井恋次',array[]::text[],9),
  ('アニメ・マンガ','BLEACH','朽木白哉',array[]::text[],10),
  ('アニメ・マンガ','BLEACH','日番谷冬獅郎',array[]::text[],11),
  ('アニメ・マンガ','BLEACH','藍染惣右介',array[]::text[],12),
  ('アニメ・マンガ','BLEACH','浦原喜助',array[]::text[],13),
  ('アニメ・マンガ','HUNTER×HUNTER','ゴン＝フリークス',array[]::text[],6),
  ('アニメ・マンガ','HUNTER×HUNTER','キルア＝ゾルディック',array[]::text[],7),
  ('アニメ・マンガ','HUNTER×HUNTER','クラピカ',array[]::text[],8),
  ('アニメ・マンガ','HUNTER×HUNTER','レオリオ',array[]::text[],9),
  ('アニメ・マンガ','HUNTER×HUNTER','ヒソカ',array[]::text[],10),
  ('アニメ・マンガ','HUNTER×HUNTER','クロロ＝ルシルフル',array[]::text[],11),
  ('アニメ・マンガ','HUNTER×HUNTER','イルミ＝ゾルディック',array[]::text[],12),
  ('アニメ・マンガ','ワールドトリガー','空閑遊真',array[]::text[],6),
  ('アニメ・マンガ','ワールドトリガー','三雲修',array[]::text[],7),
  ('アニメ・マンガ','ワールドトリガー','雨取千佳',array[]::text[],8),
  ('アニメ・マンガ','ワールドトリガー','迅悠一',array[]::text[],9),
  ('アニメ・マンガ','ワールドトリガー','ヒュース',array[]::text[],10),
  ('アニメ・マンガ','ワールドトリガー','太刀川慶',array[]::text[],11),
  ('アニメ・マンガ','ワールドトリガー','風間蒼也',array[]::text[],12),
  ('アニメ・マンガ','Dr.STONE','石神千空',array[]::text[],6),
  ('アニメ・マンガ','Dr.STONE','大木大樹',array[]::text[],7),
  ('アニメ・マンガ','Dr.STONE','小川杠',array[]::text[],8),
  ('アニメ・マンガ','Dr.STONE','コハク',array[]::text[],9),
  ('アニメ・マンガ','Dr.STONE','クロム',array[]::text[],10),
  ('アニメ・マンガ','Dr.STONE','あさぎりゲン',array[]::text[],11),
  ('アニメ・マンガ','Dr.STONE','七海龍水',array[]::text[],12),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','後藤ひとり',array['ぼっち']::text[],5),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','伊地知虹夏',array[]::text[],6),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','山田リョウ',array[]::text[],7),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','喜多郁代',array[]::text[],8),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','廣井きくり',array[]::text[],9),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','伊地知星歌',array[]::text[],10),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','PAさん',array[]::text[],11),
  -- ゲーム: 定番タイトルの主要キャラ補完
  ('ゲーム','ゼルダの伝説','リンク',array[]::text[],4),
  ('ゲーム','ゼルダの伝説','ゼルダ',array[]::text[],5),
  ('ゲーム','ゼルダの伝説','ガノンドロフ',array[]::text[],6),
  ('ゲーム','ゼルダの伝説','ミファー',array[]::text[],7),
  ('ゲーム','ゼルダの伝説','シド',array[]::text[],8),
  ('ゲーム','どうぶつの森','しずえ',array[]::text[],4),
  ('ゲーム','どうぶつの森','たぬきち',array[]::text[],5),
  ('ゲーム','どうぶつの森','とたけけ',array[]::text[],6),
  ('ゲーム','どうぶつの森','まめきち',array[]::text[],7),
  ('ゲーム','どうぶつの森','つぶきち',array[]::text[],8),
  ('ゲーム','どうぶつの森','ジャック',array[]::text[],9),
  ('ゲーム','モンスターハンター','アイルー',array[]::text[],4),
  ('ゲーム','モンスターハンター','メラルー',array[]::text[],5),
  ('ゲーム','モンスターハンター','リオレウス',array[]::text[],6),
  ('ゲーム','モンスターハンター','リオレイア',array[]::text[],7),
  ('ゲーム','モンスターハンター','ナルガクルガ',array[]::text[],8);

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
