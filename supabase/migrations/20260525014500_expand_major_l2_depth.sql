-- =====================================================================
-- iter168.27: ビッグ作品/大型グループのL2厚増し
-- =====================================================================
-- 既存の有名L1で、主要キャラ/メンバーが少なかったものを補完する。
-- 新規L1は追加せず、既存 group/work のL2密度を上げる。

create temporary table _ihub_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _ihub_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- ONE PIECE
  ('アニメ・マンガ','ONE PIECE','ウソップ',array[]::text[],9),
  ('アニメ・マンガ','ONE PIECE','ニコ・ロビン',array[]::text[],10),
  ('アニメ・マンガ','ONE PIECE','フランキー',array[]::text[],11),
  ('アニメ・マンガ','ONE PIECE','ブルック',array[]::text[],12),
  ('アニメ・マンガ','ONE PIECE','ジンベエ',array[]::text[],13),
  ('アニメ・マンガ','ONE PIECE','サボ',array[]::text[],14),
  ('アニメ・マンガ','ONE PIECE','ボア・ハンコック',array[]::text[],15),
  ('アニメ・マンガ','ONE PIECE','ヤマト',array[]::text[],16),
  ('アニメ・マンガ','ONE PIECE','バギー',array[]::text[],17),
  ('アニメ・マンガ','ONE PIECE','クロコダイル',array[]::text[],18),
  -- 名探偵コナン
  ('アニメ・マンガ','名探偵コナン','毛利小五郎',array[]::text[],8),
  ('アニメ・マンガ','名探偵コナン','阿笠博士',array[]::text[],9),
  ('アニメ・マンガ','名探偵コナン','服部平次',array[]::text[],10),
  ('アニメ・マンガ','名探偵コナン','遠山和葉',array[]::text[],11),
  ('アニメ・マンガ','名探偵コナン','世良真純',array[]::text[],12),
  ('アニメ・マンガ','名探偵コナン','沖矢昴',array[]::text[],13),
  ('アニメ・マンガ','名探偵コナン','松田陣平',array[]::text[],14),
  ('アニメ・マンガ','名探偵コナン','萩原研二',array[]::text[],15),
  ('アニメ・マンガ','名探偵コナン','諸伏景光',array[]::text[],16),
  ('アニメ・マンガ','名探偵コナン','佐藤美和子',array[]::text[],17),
  ('アニメ・マンガ','名探偵コナン','高木渉',array[]::text[],18),
  ('アニメ・マンガ','名探偵コナン','ジン',array[]::text[],19),
  ('アニメ・マンガ','名探偵コナン','ベルモット',array[]::text[],20),
  -- SPY×FAMILY
  ('アニメ・マンガ','SPY×FAMILY','ユーリ・ブライア',array[]::text[],5),
  ('アニメ・マンガ','SPY×FAMILY','ダミアン・デズモンド',array[]::text[],6),
  ('アニメ・マンガ','SPY×FAMILY','ベッキー・ブラックベル',array[]::text[],7),
  ('アニメ・マンガ','SPY×FAMILY','フィオナ・フロスト',array[]::text[],8),
  ('アニメ・マンガ','SPY×FAMILY','フランキー・フランクリン',array[]::text[],9),
  ('アニメ・マンガ','SPY×FAMILY','シルヴィア・シャーウッド',array[]::text[],10),
  ('アニメ・マンガ','SPY×FAMILY','ヘンリー・ヘンダーソン',array[]::text[],11),
  -- 進撃の巨人
  ('アニメ・マンガ','進撃の巨人','ジャン・キルシュタイン',array[]::text[],5),
  ('アニメ・マンガ','進撃の巨人','コニー・スプリンガー',array[]::text[],6),
  ('アニメ・マンガ','進撃の巨人','サシャ・ブラウス',array[]::text[],7),
  ('アニメ・マンガ','進撃の巨人','ハンジ・ゾエ',array[]::text[],8),
  ('アニメ・マンガ','進撃の巨人','エルヴィン・スミス',array[]::text[],9),
  ('アニメ・マンガ','進撃の巨人','ライナー・ブラウン',array[]::text[],10),
  ('アニメ・マンガ','進撃の巨人','アニ・レオンハート',array[]::text[],11),
  ('アニメ・マンガ','進撃の巨人','ヒストリア・レイス',array[]::text[],12),
  ('アニメ・マンガ','進撃の巨人','ジーク・イェーガー',array[]::text[],13),
  -- 銀魂
  ('アニメ・マンガ','銀魂','桂小太郎',array[]::text[],6),
  ('アニメ・マンガ','銀魂','高杉晋助',array[]::text[],7),
  ('アニメ・マンガ','銀魂','神威',array[]::text[],8),
  ('アニメ・マンガ','銀魂','月詠',array[]::text[],9),
  ('アニメ・マンガ','銀魂','近藤勲',array[]::text[],10),
  ('アニメ・マンガ','銀魂','山崎退',array[]::text[],11),
  ('アニメ・マンガ','銀魂','定春',array[]::text[],12),
  ('アニメ・マンガ','銀魂','志村妙',array[]::text[],13),
  -- 文豪ストレイドッグス
  ('アニメ・マンガ','文豪ストレイドッグス','芥川龍之介',array[]::text[],6),
  ('アニメ・マンガ','文豪ストレイドッグス','泉鏡花',array[]::text[],7),
  ('アニメ・マンガ','文豪ストレイドッグス','与謝野晶子',array[]::text[],8),
  ('アニメ・マンガ','文豪ストレイドッグス','宮沢賢治',array[]::text[],9),
  ('アニメ・マンガ','文豪ストレイドッグス','谷崎潤一郎',array[]::text[],10),
  ('アニメ・マンガ','文豪ストレイドッグス','福沢諭吉',array[]::text[],11),
  ('アニメ・マンガ','文豪ストレイドッグス','森鴎外',array[]::text[],12),
  ('アニメ・マンガ','文豪ストレイドッグス','尾崎紅葉',array[]::text[],13),
  ('アニメ・マンガ','文豪ストレイドッグス','フョードル・D',array[]::text[],14),
  -- 黒子のバスケ / テニスの王子様
  ('アニメ・マンガ','黒子のバスケ','緑間真太郎',array[]::text[],5),
  ('アニメ・マンガ','黒子のバスケ','青峰大輝',array[]::text[],6),
  ('アニメ・マンガ','黒子のバスケ','紫原敦',array[]::text[],7),
  ('アニメ・マンガ','黒子のバスケ','桃井さつき',array[]::text[],8),
  ('アニメ・マンガ','黒子のバスケ','日向順平',array[]::text[],9),
  ('アニメ・マンガ','黒子のバスケ','木吉鉄平',array[]::text[],10),
  ('アニメ・マンガ','テニスの王子様','菊丸英二',array[]::text[],5),
  ('アニメ・マンガ','テニスの王子様','大石秀一郎',array[]::text[],6),
  ('アニメ・マンガ','テニスの王子様','乾貞治',array[]::text[],7),
  ('アニメ・マンガ','テニスの王子様','桃城武',array[]::text[],8),
  ('アニメ・マンガ','テニスの王子様','海堂薫',array[]::text[],9),
  ('アニメ・マンガ','テニスの王子様','幸村精市',array[]::text[],10),
  ('アニメ・マンガ','テニスの王子様','真田弦一郎',array[]::text[],11),
  ('アニメ・マンガ','テニスの王子様','切原赤也',array[]::text[],12),
  ('アニメ・マンガ','テニスの王子様','白石蔵ノ介',array[]::text[],13),
  -- Fate/Grand Order
  ('ゲーム','Fate/Grand Order','マーリン',array[]::text[],5),
  ('ゲーム','Fate/Grand Order','スカサハ',array[]::text[],6),
  ('ゲーム','Fate/Grand Order','カルナ',array[]::text[],7),
  ('ゲーム','Fate/Grand Order','アルジュナ',array[]::text[],8),
  ('ゲーム','Fate/Grand Order','巌窟王 エドモン・ダンテス',array['巌窟王']::text[],9),
  ('ゲーム','Fate/Grand Order','オベロン',array[]::text[],10),
  ('ゲーム','Fate/Grand Order','アルトリア・キャスター',array['キャストリア']::text[],11),
  ('ゲーム','Fate/Grand Order','モルガン',array[]::text[],12),
  ('ゲーム','Fate/Grand Order','エレシュキガル',array[]::text[],13),
  ('ゲーム','Fate/Grand Order','沖田総司',array[]::text[],14),
  ('ゲーム','Fate/Grand Order','ジャンヌ・ダルク〔オルタ〕',array['ジャンヌオルタ']::text[],15),
  -- アイドルマスター系
  ('ゲーム','アイドルマスター シンデレラガールズ','前川みく',array[]::text[],6),
  ('ゲーム','アイドルマスター シンデレラガールズ','アナスタシア',array[]::text[],7),
  ('ゲーム','アイドルマスター シンデレラガールズ','高垣楓',array[]::text[],8),
  ('ゲーム','アイドルマスター シンデレラガールズ','鷺沢文香',array[]::text[],9),
  ('ゲーム','アイドルマスター シンデレラガールズ','速水奏',array[]::text[],10),
  ('ゲーム','アイドルマスター シンデレラガールズ','佐久間まゆ',array[]::text[],11),
  ('ゲーム','アイドルマスター シンデレラガールズ','城ヶ崎美嘉',array[]::text[],12),
  ('ゲーム','アイドルマスター SideM','御手洗翔太',array[]::text[],6),
  ('ゲーム','アイドルマスター SideM','ピエール',array[]::text[],7),
  ('ゲーム','アイドルマスター SideM','鷹城恭二',array[]::text[],8),
  ('ゲーム','アイドルマスター SideM','渡辺みのり',array[]::text[],9),
  ('ゲーム','アイドルマスター SideM','硲道夫',array[]::text[],10),
  ('ゲーム','アイドルマスター SideM','舞田類',array[]::text[],11),
  -- ポケットモンスター / サンリオ
  ('キャラクターIP','ポケットモンスター','ミュウ',array[]::text[],7),
  ('キャラクターIP','ポケットモンスター','ミュウツー',array[]::text[],8),
  ('キャラクターIP','ポケットモンスター','ルカリオ',array[]::text[],9),
  ('キャラクターIP','ポケットモンスター','ニンフィア',array[]::text[],10),
  ('キャラクターIP','ポケットモンスター','ゲッコウガ',array[]::text[],11),
  ('キャラクターIP','ポケットモンスター','ミミッキュ',array[]::text[],12),
  ('キャラクターIP','ポケットモンスター','モクロー',array[]::text[],13),
  ('キャラクターIP','ポケットモンスター','ホゲータ',array[]::text[],14),
  ('キャラクターIP','サンリオキャラクターズ','けろけろけろっぴ',array[]::text[],9),
  ('キャラクターIP','サンリオキャラクターズ','あひるのペックル',array[]::text[],10),
  ('キャラクターIP','サンリオキャラクターズ','バッドばつ丸',array[]::text[],11),
  ('キャラクターIP','サンリオキャラクターズ','こぎみゅん',array[]::text[],12),
  ('キャラクターIP','サンリオキャラクターズ','ウィッシュミーメル',array[]::text[],13),
  ('キャラクターIP','サンリオキャラクターズ','リトルツインスターズ',array['キキララ']::text[],14),
  -- hololive / にじさんじ
  ('VTuber・配信者','hololive','夏色まつり',array[]::text[],8),
  ('VTuber・配信者','hololive','赤井はあと',array['HAACHAMA']::text[],9),
  ('VTuber・配信者','hololive','湊あくあ',array[]::text[],10),
  ('VTuber・配信者','hololive','紫咲シオン',array[]::text[],11),
  ('VTuber・配信者','hololive','百鬼あやめ',array[]::text[],12),
  ('VTuber・配信者','hololive','大空スバル',array[]::text[],13),
  ('VTuber・配信者','hololive','猫又おかゆ',array[]::text[],14),
  ('VTuber・配信者','hololive','戌神ころね',array[]::text[],15),
  ('VTuber・配信者','hololive','白銀ノエル',array[]::text[],16),
  ('VTuber・配信者','hololive','不知火フレア',array[]::text[],17),
  ('VTuber・配信者','hololive','角巻わため',array[]::text[],18),
  ('VTuber・配信者','hololive','姫森ルーナ',array[]::text[],19),
  ('VTuber・配信者','にじさんじ','リゼ・ヘルエスタ',array[]::text[],8),
  ('VTuber・配信者','にじさんじ','アンジュ・カトリーナ',array[]::text[],9),
  ('VTuber・配信者','にじさんじ','戌亥とこ',array[]::text[],10),
  ('VTuber・配信者','にじさんじ','加賀美ハヤト',array[]::text[],11),
  ('VTuber・配信者','にじさんじ','社築',array[]::text[],12),
  ('VTuber・配信者','にじさんじ','笹木咲',array[]::text[],13),
  ('VTuber・配信者','にじさんじ','椎名唯華',array[]::text[],14),
  ('VTuber・配信者','にじさんじ','星川サラ',array[]::text[],15),
  ('VTuber・配信者','にじさんじ','ローレン・イロアス',array[]::text[],16),
  ('VTuber・配信者','にじさんじ','イブラヒム',array[]::text[],17),
  ('VTuber・配信者','にじさんじ','三枝明那',array[]::text[],18),
  ('VTuber・配信者','にじさんじ','甲斐田晴',array[]::text[],19);

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
