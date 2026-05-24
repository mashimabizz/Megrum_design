-- =====================================================================
-- iter168.25: 推しマスタ拡充 batch 3
-- =====================================================================
-- レガシー/定番K-POP、国内グループ、声優ユニットを追加。
-- 追加する group/work は必ず L2 を同梱する。

create temporary table _ihub_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _ihub_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('K-POP男性','GOT7',array['갓세븐']::text[],'group',70),
  ('K-POP男性','BIGBANG',array['빅뱅']::text[],'group',71),
  ('K-POP男性','2PM',array['투피엠']::text[],'group',72),
  ('K-POP女性','Girls'' Generation',array['少女時代','SNSD','소녀시대']::text[],'group',70),
  ('K-POP女性','KARA',array['카라']::text[],'group',71),
  ('K-POP女性','2NE1',array['투애니원']::text[],'group',72),
  ('国内男性','Hey! Say! JUMP',array['平成ジャンプ']::text[],'group',70),
  ('国内男性','Kis-My-Ft2',array['キスマイ']::text[],'group',71),
  ('国内女性','BEYOOOOONDS',array['ビヨーンズ']::text[],'group',70),
  ('国内女性','つばきファクトリー',array['Tsubaki Factory']::text[],'group',71),
  ('国内女性','OCHA NORMA',array['オチャノーマ']::text[],'group',72),
  ('声優','虹ヶ咲学園スクールアイドル同好会',array['ニジガク']::text[],'group',60),
  ('声優','Liella!',array['リエラ']::text[],'group',61),
  ('声優','TrySail',array['トライセイル']::text[],'group',62),
  ('声優','DIALOGUE+',array['ダイアローグ']::text[],'group',63),
  ('声優','22/7',array['ナナブンノニジュウニ','ナナニジ']::text[],'group',64),
  ('声優','Afterglow',array['BanG Dream! Afterglow']::text[],'group',65),
  ('声優','Morfonica',array['BanG Dream! Morfonica']::text[],'group',66),
  ('声優','RAISE A SUILEN',array['RAS','BanG Dream! RAISE A SUILEN']::text[],'group',67);

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
  ('K-POP男性','GOT7','Mark',array['マーク','마크']::text[],1),
  ('K-POP男性','GOT7','Jay B',array['JB','ジェイビー','제이비']::text[],2),
  ('K-POP男性','GOT7','Jackson',array['ジャクソン','잭슨']::text[],3),
  ('K-POP男性','GOT7','Jinyoung',array['ジニョン','진영']::text[],4),
  ('K-POP男性','GOT7','Youngjae',array['ヨンジェ','영재']::text[],5),
  ('K-POP男性','GOT7','BamBam',array['ベンベン','뱀뱀']::text[],6),
  ('K-POP男性','GOT7','Yugyeom',array['ユギョム','유겸']::text[],7),
  ('K-POP男性','BIGBANG','G-DRAGON',array['ジードラゴン','지드래곤']::text[],1),
  ('K-POP男性','BIGBANG','TAEYANG',array['テヤン','태양']::text[],2),
  ('K-POP男性','BIGBANG','DAESUNG',array['テソン','대성']::text[],3),
  ('K-POP男性','2PM','Jun. K',array['ジュンケイ','준케이']::text[],1),
  ('K-POP男性','2PM','Nichkhun',array['ニックン','닉쿤']::text[],2),
  ('K-POP男性','2PM','Taecyeon',array['テギョン','택연']::text[],3),
  ('K-POP男性','2PM','Wooyoung',array['ウヨン','우영']::text[],4),
  ('K-POP男性','2PM','Junho',array['ジュノ','준호']::text[],5),
  ('K-POP男性','2PM','Chansung',array['チャンソン','찬성']::text[],6),
  ('K-POP女性','Girls'' Generation','Taeyeon',array['テヨン','태연']::text[],1),
  ('K-POP女性','Girls'' Generation','Sunny',array['サニー','써니']::text[],2),
  ('K-POP女性','Girls'' Generation','Tiffany',array['ティファニー','티파니']::text[],3),
  ('K-POP女性','Girls'' Generation','Hyoyeon',array['ヒョヨン','효연']::text[],4),
  ('K-POP女性','Girls'' Generation','Yuri',array['ユリ','유리']::text[],5),
  ('K-POP女性','Girls'' Generation','Sooyoung',array['スヨン','수영']::text[],6),
  ('K-POP女性','Girls'' Generation','Yoona',array['ユナ','윤아']::text[],7),
  ('K-POP女性','Girls'' Generation','Seohyun',array['ソヒョン','서현']::text[],8),
  ('K-POP女性','KARA','ギュリ',array['GYURI','규리']::text[],1),
  ('K-POP女性','KARA','スンヨン',array['SEUNGYEON','승연']::text[],2),
  ('K-POP女性','KARA','ニコル',array['NICOLE','니콜']::text[],3),
  ('K-POP女性','KARA','ジヨン',array['JIYOUNG','지영']::text[],4),
  ('K-POP女性','KARA','ヨンジ',array['YOUNGJI','영지']::text[],5),
  ('K-POP女性','2NE1','CL',array['シーエル','씨엘']::text[],1),
  ('K-POP女性','2NE1','BOM',array['パク・ボム','박봄']::text[],2),
  ('K-POP女性','2NE1','DARA',array['サンダラ・パク','산다라박']::text[],3),
  ('K-POP女性','2NE1','MINZY',array['ミンジ','민지']::text[],4),
  ('国内男性','Hey! Say! JUMP','山田涼介',array['Ryosuke Yamada']::text[],1),
  ('国内男性','Hey! Say! JUMP','知念侑李',array['Yuri Chinen']::text[],2),
  ('国内男性','Hey! Say! JUMP','中島裕翔',array['Yuto Nakajima']::text[],3),
  ('国内男性','Hey! Say! JUMP','有岡大貴',array['Daiki Arioka']::text[],4),
  ('国内男性','Hey! Say! JUMP','髙木雄也',array['Yuya Takaki','高木雄也']::text[],5),
  ('国内男性','Hey! Say! JUMP','伊野尾慧',array['Kei Inoo']::text[],6),
  ('国内男性','Hey! Say! JUMP','八乙女光',array['Hikaru Yaotome']::text[],7),
  ('国内男性','Hey! Say! JUMP','薮宏太',array['Kota Yabu']::text[],8),
  ('国内男性','Kis-My-Ft2','千賀健永',array['Kento Senga']::text[],1),
  ('国内男性','Kis-My-Ft2','宮田俊哉',array['Toshiya Miyata']::text[],2),
  ('国内男性','Kis-My-Ft2','横尾渉',array['Wataru Yokoo']::text[],3),
  ('国内男性','Kis-My-Ft2','藤ヶ谷太輔',array['Taisuke Fujigaya']::text[],4),
  ('国内男性','Kis-My-Ft2','玉森裕太',array['Yuta Tamamori']::text[],5),
  ('国内男性','Kis-My-Ft2','二階堂高嗣',array['Takashi Nikaido']::text[],6),
  ('国内女性','BEYOOOOONDS','一岡伶奈',array['Reina Ichioka']::text[],1),
  ('国内女性','BEYOOOOONDS','島倉りか',array['Rika Shimakura']::text[],2),
  ('国内女性','BEYOOOOONDS','西田汐里',array['Shiori Nishida']::text[],3),
  ('国内女性','BEYOOOOONDS','江口紗耶',array['Saya Eguchi']::text[],4),
  ('国内女性','BEYOOOOONDS','高瀬くるみ',array['Kurumi Takase']::text[],5),
  ('国内女性','つばきファクトリー','谷本安美',array['Ami Tanimoto']::text[],1),
  ('国内女性','つばきファクトリー','小野瑞歩',array['Mizuho Ono']::text[],2),
  ('国内女性','つばきファクトリー','小野田紗栞',array['Saori Onoda']::text[],3),
  ('国内女性','つばきファクトリー','秋山眞緒',array['Mao Akiyama']::text[],4),
  ('国内女性','つばきファクトリー','河西結心',array['Yume Kasai']::text[],5),
  ('国内女性','OCHA NORMA','斉藤円香',array['Madoka Saito']::text[],1),
  ('国内女性','OCHA NORMA','広本瑠璃',array['Ruri Hiromoto']::text[],2),
  ('国内女性','OCHA NORMA','石栗奏美',array['Kanami Ishiguri']::text[],3),
  ('国内女性','OCHA NORMA','米村姫良々',array['Kirara Yonemura']::text[],4),
  ('国内女性','OCHA NORMA','窪田七海',array['Nanami Kubota']::text[],5),
  ('声優','虹ヶ咲学園スクールアイドル同好会','大西亜玖璃',array['Aguri Onishi']::text[],1),
  ('声優','虹ヶ咲学園スクールアイドル同好会','相良茉優',array['Mayu Sagara']::text[],2),
  ('声優','虹ヶ咲学園スクールアイドル同好会','前田佳織里',array['Kaori Maeda']::text[],3),
  ('声優','虹ヶ咲学園スクールアイドル同好会','久保田未夢',array['Miyu Kubota']::text[],4),
  ('声優','虹ヶ咲学園スクールアイドル同好会','村上奈津実',array['Natsumi Murakami']::text[],5),
  ('声優','Liella!','伊達さゆり',array['Sayuri Date']::text[],1),
  ('声優','Liella!','Liyuu',array[]::text[],2),
  ('声優','Liella!','岬なこ',array['Nako Misaki']::text[],3),
  ('声優','Liella!','ペイトン尚未',array['Naomi Payton']::text[],4),
  ('声優','Liella!','青山なぎさ',array['Nagisa Aoyama']::text[],5),
  ('声優','Liella!','鈴原希実',array['Nozomi Suzuhara']::text[],6),
  ('声優','Liella!','薮島朱音',array['Akane Yabushima']::text[],7),
  ('声優','TrySail','麻倉もも',array['Momo Asakura']::text[],1),
  ('声優','TrySail','雨宮天',array['Sora Amamiya']::text[],2),
  ('声優','TrySail','夏川椎菜',array['Shiina Natsukawa']::text[],3),
  ('声優','DIALOGUE+','内山悠里菜',array['Yurina Uchiyama']::text[],1),
  ('声優','DIALOGUE+','稗田寧々',array['Nene Hieda']::text[],2),
  ('声優','DIALOGUE+','守屋亨香',array['Kyoka Moriya']::text[],3),
  ('声優','DIALOGUE+','緒方佑奈',array['Yuna Ogata']::text[],4),
  ('声優','DIALOGUE+','鷹村彩花',array['Ayaka Takamura']::text[],5),
  ('声優','22/7','西條和',array['Nagomi Saijo']::text[],1),
  ('声優','22/7','天城サリー',array['Sally Amaki']::text[],2),
  ('声優','22/7','涼花萌',array['Moe Suzuhana']::text[],3),
  ('声優','22/7','白沢かなえ',array['Kanae Shirosawa']::text[],4),
  ('声優','Afterglow','佐倉綾音',array['Ayane Sakura']::text[],1),
  ('声優','Afterglow','三澤紗千香',array['Sachika Misawa']::text[],2),
  ('声優','Afterglow','加藤英美里',array['Emiri Kato']::text[],3),
  ('声優','Afterglow','日笠陽子',array['Yoko Hikasa']::text[],4),
  ('声優','Afterglow','金元寿子',array['Hisako Kanemoto']::text[],5),
  ('声優','Morfonica','進藤あまね',array['Amane Shindo']::text[],1),
  ('声優','Morfonica','直田姫奈',array['Hina Suguta']::text[],2),
  ('声優','Morfonica','西尾夕香',array['Yuka Nishio']::text[],3),
  ('声優','Morfonica','mika',array[]::text[],4),
  ('声優','Morfonica','Ayasa',array[]::text[],5),
  ('声優','RAISE A SUILEN','Raychell',array[]::text[],1),
  ('声優','RAISE A SUILEN','小原莉子',array['Riko Kohara']::text[],2),
  ('声優','RAISE A SUILEN','夏芽',array['Natsume']::text[],3),
  ('声優','RAISE A SUILEN','倉知玲鳳',array['Reo Kurachi']::text[],4),
  ('声優','RAISE A SUILEN','紡木吏佐',array['Risa Tsumugi']::text[],5);

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
    'person'::text as entity_type,
    'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name as identity_key,
    cm.name as canonical_name,
    cm.aliases,
    cm.display_order
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
  where gm.kind = 'group'
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
    'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name as identity_key
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
  where gm.kind = 'group'
)
update public.characters_master cm
set entity_id = e.id
from member_entities me
join public.oshi_entities_master e on e.identity_key = me.identity_key
where cm.id = me.character_id
  and cm.entity_id is distinct from e.id;
