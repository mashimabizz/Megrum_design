-- =====================================================================
-- iter168.26: 推しマスタ拡充 batch 4
-- =====================================================================
-- 作品/キャラクターIP/VTuber/配信者を中心に追加。
-- 追加する group/work は必ず L2 を同梱する。

create temporary table _megrum_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _megrum_seed_groups (genre_name, name, aliases, kind, display_order) values
  -- アニメ・マンガ
  ('アニメ・マンガ','NARUTO -ナルト-',array['NARUTO','ナルト']::text[],'work',70),
  ('アニメ・マンガ','HUNTER×HUNTER',array['HUNTER HUNTER','ハンターハンター']::text[],'work',71),
  ('アニメ・マンガ','Dr.STONE',array['ドクターストーン']::text[],'work',72),
  ('アニメ・マンガ','ワールドトリガー',array['ワートリ','World Trigger']::text[],'work',73),
  ('アニメ・マンガ','るろうに剣心',array['Rurouni Kenshin']::text[],'work',74),
  ('アニメ・マンガ','鋼の錬金術師',array['ハガレン','Fullmetal Alchemist']::text[],'work',75),
  ('アニメ・マンガ','BLEACH',array['ブリーチ']::text[],'work',76),
  ('アニメ・マンガ','ワンパンマン',array['One-Punch Man']::text[],'work',77),
  ('アニメ・マンガ','怪獣8号',array['Kaiju No. 8']::text[],'work',78),
  ('アニメ・マンガ','地縛少年花子くん',array[]::text[],'work',79),
  -- ゲーム
  ('ゲーム','ファイナルファンタジーVII',array['FFVII','FF7']::text[],'work',70),
  ('ゲーム','ペルソナ5',array['P5','Persona 5']::text[],'work',71),
  ('ゲーム','ゼルダの伝説',array['The Legend of Zelda']::text[],'work',72),
  ('ゲーム','スプラトゥーン',array['Splatoon']::text[],'work',73),
  ('ゲーム','どうぶつの森',array['Animal Crossing','あつ森']::text[],'work',74),
  ('ゲーム','モンスターハンター',array['Monster Hunter','モンハン']::text[],'work',75),
  ('ゲーム','キングダム ハーツ',array['KINGDOM HEARTS','KH']::text[],'work',76),
  -- キャラクターIP
  ('キャラクターIP','ハローキティ',array['Hello Kitty']::text[],'work',50),
  ('キャラクターIP','マイメロディ',array['My Melody']::text[],'work',51),
  ('キャラクターIP','クロミ',array['Kuromi']::text[],'work',52),
  ('キャラクターIP','ポムポムプリン',array['Pompompurin']::text[],'work',53),
  ('キャラクターIP','シナモロール',array['Cinnamoroll','シナモン']::text[],'work',54),
  ('キャラクターIP','PUI PUI モルカー',array['モルカー']::text[],'work',55),
  ('キャラクターIP','ピングー',array['Pingu']::text[],'work',56),
  ('キャラクターIP','こぎみゅん',array[]::text[],'work',57),
  ('キャラクターIP','カナヘイの小動物',array['ピスケとうさぎ']::text[],'work',58),
  -- VTuber・配信者
  ('VTuber・配信者','hololive English',array['ホロライブEnglish','ホロEN']::text[],'group',50),
  ('VTuber・配信者','hololive DEV_IS',array['ReGLOSS','FLOW GLOW']::text[],'group',51),
  ('VTuber・配信者','NIJISANJI EN',array['にじさんじEN']::text[],'group',52),
  ('VTuber・配信者','QuizKnock',array['クイズノック']::text[],'group',53),
  ('VTuber・配信者','ドズル社',array[]::text[],'group',54),
  -- お笑い
  ('お笑い','千鳥',array[]::text[],'group',50),
  ('お笑い','チョコレートプラネット',array['チョコプラ']::text[],'group',51),
  ('お笑い','ミキ',array[]::text[],'group',52),
  ('お笑い','ダウ90000',array[]::text[],'group',53),
  ('お笑い','ヨネダ2000',array[]::text[],'group',54);

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
  -- アニメ・マンガ
  ('アニメ・マンガ','NARUTO -ナルト-','うずまきナルト',array[]::text[],1),
  ('アニメ・マンガ','NARUTO -ナルト-','うちはサスケ',array[]::text[],2),
  ('アニメ・マンガ','NARUTO -ナルト-','春野サクラ',array[]::text[],3),
  ('アニメ・マンガ','NARUTO -ナルト-','はたけカカシ',array[]::text[],4),
  ('アニメ・マンガ','NARUTO -ナルト-','うちはイタチ',array[]::text[],5),
  ('アニメ・マンガ','HUNTER×HUNTER','ゴン＝フリークス',array[]::text[],1),
  ('アニメ・マンガ','HUNTER×HUNTER','キルア＝ゾルディック',array[]::text[],2),
  ('アニメ・マンガ','HUNTER×HUNTER','クラピカ',array[]::text[],3),
  ('アニメ・マンガ','HUNTER×HUNTER','レオリオ',array[]::text[],4),
  ('アニメ・マンガ','HUNTER×HUNTER','ヒソカ',array[]::text[],5),
  ('アニメ・マンガ','Dr.STONE','石神千空',array[]::text[],1),
  ('アニメ・マンガ','Dr.STONE','大木大樹',array[]::text[],2),
  ('アニメ・マンガ','Dr.STONE','小川杠',array[]::text[],3),
  ('アニメ・マンガ','Dr.STONE','あさぎりゲン',array[]::text[],4),
  ('アニメ・マンガ','Dr.STONE','七海龍水',array[]::text[],5),
  ('アニメ・マンガ','ワールドトリガー','空閑遊真',array[]::text[],1),
  ('アニメ・マンガ','ワールドトリガー','三雲修',array[]::text[],2),
  ('アニメ・マンガ','ワールドトリガー','雨取千佳',array[]::text[],3),
  ('アニメ・マンガ','ワールドトリガー','迅悠一',array[]::text[],4),
  ('アニメ・マンガ','ワールドトリガー','ヒュース',array[]::text[],5),
  ('アニメ・マンガ','るろうに剣心','緋村剣心',array[]::text[],1),
  ('アニメ・マンガ','るろうに剣心','神谷薫',array[]::text[],2),
  ('アニメ・マンガ','るろうに剣心','相楽左之助',array[]::text[],3),
  ('アニメ・マンガ','るろうに剣心','斎藤一',array[]::text[],4),
  ('アニメ・マンガ','鋼の錬金術師','エドワード・エルリック',array[]::text[],1),
  ('アニメ・マンガ','鋼の錬金術師','アルフォンス・エルリック',array[]::text[],2),
  ('アニメ・マンガ','鋼の錬金術師','ロイ・マスタング',array[]::text[],3),
  ('アニメ・マンガ','鋼の錬金術師','リザ・ホークアイ',array[]::text[],4),
  ('アニメ・マンガ','BLEACH','黒崎一護',array[]::text[],1),
  ('アニメ・マンガ','BLEACH','朽木ルキア',array[]::text[],2),
  ('アニメ・マンガ','BLEACH','朽木白哉',array[]::text[],3),
  ('アニメ・マンガ','BLEACH','日番谷冬獅郎',array[]::text[],4),
  ('アニメ・マンガ','ワンパンマン','サイタマ',array[]::text[],1),
  ('アニメ・マンガ','ワンパンマン','ジェノス',array[]::text[],2),
  ('アニメ・マンガ','ワンパンマン','音速のソニック',array[]::text[],3),
  ('アニメ・マンガ','怪獣8号','日比野カフカ',array[]::text[],1),
  ('アニメ・マンガ','怪獣8号','市川レノ',array[]::text[],2),
  ('アニメ・マンガ','怪獣8号','四ノ宮キコル',array[]::text[],3),
  ('アニメ・マンガ','怪獣8号','保科宗四郎',array[]::text[],4),
  ('アニメ・マンガ','地縛少年花子くん','花子くん',array[]::text[],1),
  ('アニメ・マンガ','地縛少年花子くん','八尋寧々',array[]::text[],2),
  ('アニメ・マンガ','地縛少年花子くん','源光',array[]::text[],3),
  ('アニメ・マンガ','地縛少年花子くん','つかさ',array[]::text[],4),
  -- ゲーム
  ('ゲーム','ファイナルファンタジーVII','クラウド・ストライフ',array[]::text[],1),
  ('ゲーム','ファイナルファンタジーVII','ティファ・ロックハート',array[]::text[],2),
  ('ゲーム','ファイナルファンタジーVII','エアリス・ゲインズブール',array[]::text[],3),
  ('ゲーム','ファイナルファンタジーVII','セフィロス',array[]::text[],4),
  ('ゲーム','ペルソナ5','ジョーカー',array['雨宮蓮']::text[],1),
  ('ゲーム','ペルソナ5','坂本竜司',array[]::text[],2),
  ('ゲーム','ペルソナ5','高巻杏',array[]::text[],3),
  ('ゲーム','ペルソナ5','モルガナ',array[]::text[],4),
  ('ゲーム','ペルソナ5','明智吾郎',array[]::text[],5),
  ('ゲーム','ゼルダの伝説','リンク',array[]::text[],1),
  ('ゲーム','ゼルダの伝説','ゼルダ',array[]::text[],2),
  ('ゲーム','ゼルダの伝説','ガノンドロフ',array[]::text[],3),
  ('ゲーム','スプラトゥーン','インクリング',array[]::text[],1),
  ('ゲーム','スプラトゥーン','オクトリング',array[]::text[],2),
  ('ゲーム','スプラトゥーン','アオリ',array[]::text[],3),
  ('ゲーム','スプラトゥーン','ホタル',array[]::text[],4),
  ('ゲーム','どうぶつの森','しずえ',array[]::text[],1),
  ('ゲーム','どうぶつの森','たぬきち',array[]::text[],2),
  ('ゲーム','どうぶつの森','とたけけ',array[]::text[],3),
  ('ゲーム','モンスターハンター','リオレウス',array[]::text[],1),
  ('ゲーム','モンスターハンター','リオレイア',array[]::text[],2),
  ('ゲーム','モンスターハンター','アイルー',array[]::text[],3),
  ('ゲーム','キングダム ハーツ','ソラ',array[]::text[],1),
  ('ゲーム','キングダム ハーツ','リク',array[]::text[],2),
  ('ゲーム','キングダム ハーツ','カイリ',array[]::text[],3),
  ('ゲーム','キングダム ハーツ','ロクサス',array[]::text[],4),
  -- キャラクターIP
  ('キャラクターIP','ハローキティ','ハローキティ',array['キティ']::text[],1),
  ('キャラクターIP','ハローキティ','ミミィ',array[]::text[],2),
  ('キャラクターIP','マイメロディ','マイメロディ',array['マイメロ']::text[],1),
  ('キャラクターIP','マイメロディ','フラット',array[]::text[],2),
  ('キャラクターIP','クロミ','クロミ',array[]::text[],1),
  ('キャラクターIP','クロミ','バク',array[]::text[],2),
  ('キャラクターIP','ポムポムプリン','ポムポムプリン',array[]::text[],1),
  ('キャラクターIP','ポムポムプリン','マフィン',array[]::text[],2),
  ('キャラクターIP','シナモロール','シナモン',array['シナモロール']::text[],1),
  ('キャラクターIP','シナモロール','モカ',array[]::text[],2),
  ('キャラクターIP','シナモロール','みるく',array[]::text[],3),
  ('キャラクターIP','PUI PUI モルカー','ポテト',array[]::text[],1),
  ('キャラクターIP','PUI PUI モルカー','シロモ',array[]::text[],2),
  ('キャラクターIP','PUI PUI モルカー','アビー',array[]::text[],3),
  ('キャラクターIP','ピングー','ピングー',array[]::text[],1),
  ('キャラクターIP','ピングー','ピンガ',array[]::text[],2),
  ('キャラクターIP','こぎみゅん','こぎみゅん',array[]::text[],1),
  ('キャラクターIP','こぎみゅん','エビちゃん',array[]::text[],2),
  ('キャラクターIP','カナヘイの小動物','ピスケ',array[]::text[],1),
  ('キャラクターIP','カナヘイの小動物','うさぎ',array[]::text[],2),
  -- VTuber・配信者
  ('VTuber・配信者','hololive English','Mori Calliope',array['森カリオペ']::text[],1),
  ('VTuber・配信者','hololive English','Takanashi Kiara',array['小鳥遊キアラ']::text[],2),
  ('VTuber・配信者','hololive English','Ninomae Ina''nis',array['一伊那尓栖','Ina']::text[],3),
  ('VTuber・配信者','hololive English','Gawr Gura',array['がうる・ぐら']::text[],4),
  ('VTuber・配信者','hololive English','Watson Amelia',array['ワトソン・アメリア']::text[],5),
  ('VTuber・配信者','hololive DEV_IS','火威青',array[]::text[],1),
  ('VTuber・配信者','hololive DEV_IS','音乃瀬奏',array[]::text[],2),
  ('VTuber・配信者','hololive DEV_IS','一条莉々華',array[]::text[],3),
  ('VTuber・配信者','hololive DEV_IS','儒烏風亭らでん',array[]::text[],4),
  ('VTuber・配信者','hololive DEV_IS','轟はじめ',array[]::text[],5),
  ('VTuber・配信者','NIJISANJI EN','Vox Akuma',array[]::text[],1),
  ('VTuber・配信者','NIJISANJI EN','Luca Kaneshiro',array[]::text[],2),
  ('VTuber・配信者','NIJISANJI EN','Ike Eveland',array[]::text[],3),
  ('VTuber・配信者','NIJISANJI EN','Mysta Rias',array[]::text[],4),
  ('VTuber・配信者','QuizKnock','伊沢拓司',array[]::text[],1),
  ('VTuber・配信者','QuizKnock','ふくらP',array['福良拳']::text[],2),
  ('VTuber・配信者','QuizKnock','須貝駿貴',array[]::text[],3),
  ('VTuber・配信者','QuizKnock','河村拓哉',array[]::text[],4),
  ('VTuber・配信者','ドズル社','ドズル',array[]::text[],1),
  ('VTuber・配信者','ドズル社','ぼんじゅうる',array[]::text[],2),
  ('VTuber・配信者','ドズル社','おんりー',array[]::text[],3),
  ('VTuber・配信者','ドズル社','おらふくん',array[]::text[],4),
  ('VTuber・配信者','ドズル社','おおはらMEN',array[]::text[],5),
  -- お笑い
  ('お笑い','千鳥','大悟',array[]::text[],1),
  ('お笑い','千鳥','ノブ',array[]::text[],2),
  ('お笑い','チョコレートプラネット','長田庄平',array[]::text[],1),
  ('お笑い','チョコレートプラネット','松尾駿',array[]::text[],2),
  ('お笑い','ミキ','昴生',array[]::text[],1),
  ('お笑い','ミキ','亜生',array[]::text[],2),
  ('お笑い','ダウ90000','蓮見翔',array[]::text[],1),
  ('お笑い','ダウ90000','園田祥太',array[]::text[],2),
  ('お笑い','ダウ90000','吉原怜那',array[]::text[],3),
  ('お笑い','ヨネダ2000','誠',array[]::text[],1),
  ('お笑い','ヨネダ2000','愛',array[]::text[],2);

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
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
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
    case
      when gm.kind = 'work'
        or ge.name in ('アニメ・マンガ', 'ゲーム', 'キャラクターIP', '2.5次元・舞台')
        then 'character:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name
      else 'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name
    end as identity_key
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
)
update public.characters_master cm
set entity_id = e.id
from member_entities me
join public.oshi_entities_master e on e.identity_key = me.identity_key
where cm.id = me.character_id
  and cm.entity_id is distinct from e.id;
