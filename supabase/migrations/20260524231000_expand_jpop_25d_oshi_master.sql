-- =====================================================================
-- iter168.18: 推し登録マスタ拡充 第二弾（邦アイ / 2.5次元）
-- =====================================================================
-- 邦アイと2.5次元ジャンルが空だったため、グッズ・生写真・ランダム
-- ブロマイド/缶バッジ/アクスタ交換で使われやすい主要グループ/作品を追加する。

create temporary table _ihub_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _ihub_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('邦アイ', 'Snow Man', array['スノーマン', 'すの']::text[], 'group', 1),
  ('邦アイ', 'SixTONES', array['ストーンズ', 'スト']::text[], 'group', 2),
  ('邦アイ', 'なにわ男子', array['Naniwa Danshi', '728']::text[], 'group', 3),
  ('邦アイ', 'King & Prince', array['キンプリ']::text[], 'group', 4),
  ('邦アイ', 'Number_i', array['ナンバーアイ']::text[], 'group', 5),
  ('邦アイ', 'JO1', array['ジェイオーワン']::text[], 'group', 6),
  ('邦アイ', 'INI', array['アイエヌアイ']::text[], 'group', 7),
  ('邦アイ', 'ME:I', array['ミーアイ']::text[], 'group', 8),
  ('邦アイ', 'BE:FIRST', array['ビーファースト', 'BEFIRST']::text[], 'group', 9),
  ('邦アイ', 'FRUITS ZIPPER', array['ふるっぱー', 'フルーツジッパー']::text[], 'group', 10),
  ('邦アイ', '=LOVE', array['イコラブ', 'Equal Love']::text[], 'group', 11),
  ('邦アイ', '≠ME', array['ノイミー', 'Not Equal Me']::text[], 'group', 12),
  ('邦アイ', '乃木坂46', array['乃木坂']::text[], 'group', 13),
  ('邦アイ', '櫻坂46', array['櫻坂']::text[], 'group', 14),
  ('邦アイ', '日向坂46', array['日向坂']::text[], 'group', 15),
  ('2.5次元', '刀剣乱舞', array['Touken Ranbu', 'とうらぶ']::text[], 'work', 1),
  ('2.5次元', 'ヒプノシスマイク', array['Hypnosis Mic', 'ヒプマイ']::text[], 'work', 2),
  ('2.5次元', 'アイドリッシュセブン', array['IDOLiSH7', 'アイナナ']::text[], 'work', 3),
  ('2.5次元', 'A3!', array['エースリー']::text[], 'work', 4),
  ('2.5次元', 'うたの☆プリンスさまっ♪', array['うたプリ', 'Uta no Prince-sama']::text[], 'work', 5),
  ('2.5次元', '魔法使いの約束', array['まほやく', 'Mahoyaku']::text[], 'work', 6),
  ('2.5次元', 'Paradox Live', array['パラライ']::text[], 'work', 7);

insert into public.groups_master (genre_id, name, aliases, kind, display_order)
select ge.id, sg.name, sg.aliases, sg.kind, sg.display_order
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
  -- 邦アイ members
  ('邦アイ','Snow Man','岩本照',array['Hikaru Iwamoto']::text[],1),
  ('邦アイ','Snow Man','深澤辰哉',array['Tatsuya Fukazawa']::text[],2),
  ('邦アイ','Snow Man','ラウール',array['Raul']::text[],3),
  ('邦アイ','Snow Man','渡辺翔太',array['Shota Watanabe']::text[],4),
  ('邦アイ','Snow Man','向井康二',array['Koji Mukai']::text[],5),
  ('邦アイ','Snow Man','阿部亮平',array['Ryohei Abe']::text[],6),
  ('邦アイ','Snow Man','目黒蓮',array['Ren Meguro','めめ']::text[],7),
  ('邦アイ','Snow Man','宮舘涼太',array['Ryota Miyadate']::text[],8),
  ('邦アイ','Snow Man','佐久間大介',array['Daisuke Sakuma']::text[],9),
  ('邦アイ','SixTONES','ジェシー',array['Jesse']::text[],1),
  ('邦アイ','SixTONES','京本大我',array['Taiga Kyomoto']::text[],2),
  ('邦アイ','SixTONES','松村北斗',array['Hokuto Matsumura']::text[],3),
  ('邦アイ','SixTONES','髙地優吾',array['Yugo Kochi']::text[],4),
  ('邦アイ','SixTONES','森本慎太郎',array['Shintaro Morimoto']::text[],5),
  ('邦アイ','SixTONES','田中樹',array['Juri Tanaka']::text[],6),
  ('邦アイ','なにわ男子','西畑大吾',array['Daigo Nishihata']::text[],1),
  ('邦アイ','なにわ男子','大西流星',array['Ryusei Onishi']::text[],2),
  ('邦アイ','なにわ男子','道枝駿佑',array['Shunsuke Michieda','みっちー']::text[],3),
  ('邦アイ','なにわ男子','高橋恭平',array['Kyohei Takahashi']::text[],4),
  ('邦アイ','なにわ男子','長尾謙杜',array['Kento Nagao']::text[],5),
  ('邦アイ','なにわ男子','藤原丈一郎',array['Joichiro Fujiwara']::text[],6),
  ('邦アイ','なにわ男子','大橋和也',array['Kazuya Ohashi']::text[],7),
  ('邦アイ','Number_i','平野紫耀',array['Sho Hirano']::text[],1),
  ('邦アイ','Number_i','神宮寺勇太',array['Yuta Jinguji']::text[],2),
  ('邦アイ','Number_i','岸優太',array['Yuta Kishi']::text[],3),
  ('邦アイ','BE:FIRST','SOTA',array['ソウタ']::text[],1),
  ('邦アイ','BE:FIRST','SHUNTO',array['シュント']::text[],2),
  ('邦アイ','BE:FIRST','MANATO',array['マナト']::text[],3),
  ('邦アイ','BE:FIRST','RYUHEI',array['リュウヘイ']::text[],4),
  ('邦アイ','BE:FIRST','JUNON',array['ジュノン']::text[],5),
  ('邦アイ','BE:FIRST','RYOKI',array['リョウキ']::text[],6),
  ('邦アイ','BE:FIRST','LEO',array['レオ']::text[],7),
  ('邦アイ','FRUITS ZIPPER','月足天音',array['Amane Tsukiashi']::text[],1),
  ('邦アイ','FRUITS ZIPPER','鎮西寿々歌',array['Suzuka Chinzei']::text[],2),
  ('邦アイ','FRUITS ZIPPER','櫻井優衣',array['Yui Sakurai']::text[],3),
  ('邦アイ','FRUITS ZIPPER','仲川瑠夏',array['Luna Nakagawa']::text[],4),
  ('邦アイ','FRUITS ZIPPER','真中まな',array['Mana Manaka']::text[],5),
  ('邦アイ','FRUITS ZIPPER','松本かれん',array['Karen Matsumoto']::text[],6),
  ('邦アイ','FRUITS ZIPPER','早瀬ノエル',array['Noel Hayase']::text[],7),
  -- 2.5 / mixed-media characters
  ('2.5次元','刀剣乱舞','三日月宗近',array['Mikazuki Munechika']::text[],1),
  ('2.5次元','刀剣乱舞','加州清光',array['Kashuu Kiyomitsu']::text[],2),
  ('2.5次元','刀剣乱舞','大和守安定',array['Yamatonokami Yasusada']::text[],3),
  ('2.5次元','刀剣乱舞','山姥切国広',array['Yamanbagiri Kunihiro']::text[],4),
  ('2.5次元','刀剣乱舞','鶴丸国永',array['Tsurumaru Kuninaga']::text[],5),
  ('2.5次元','刀剣乱舞','薬研藤四郎',array['Yagen Toushirou']::text[],6),
  ('2.5次元','刀剣乱舞','燭台切光忠',array['Shokudaikiri Mitsutada']::text[],7),
  ('2.5次元','刀剣乱舞','へし切長谷部',array['Heshikiri Hasebe']::text[],8),
  ('2.5次元','ヒプノシスマイク','山田一郎',array['Ichiro Yamada']::text[],1),
  ('2.5次元','ヒプノシスマイク','山田二郎',array['Jiro Yamada']::text[],2),
  ('2.5次元','ヒプノシスマイク','山田三郎',array['Saburo Yamada']::text[],3),
  ('2.5次元','ヒプノシスマイク','碧棺左馬刻',array['Samatoki Aohitsugi']::text[],4),
  ('2.5次元','ヒプノシスマイク','入間銃兎',array['Jyuto Iruma']::text[],5),
  ('2.5次元','ヒプノシスマイク','毒島メイソン理鶯',array['Rio Mason Busujima']::text[],6),
  ('2.5次元','ヒプノシスマイク','飴村乱数',array['Ramuda Amemura']::text[],7),
  ('2.5次元','ヒプノシスマイク','夢野幻太郎',array['Gentaro Yumeno']::text[],8),
  ('2.5次元','ヒプノシスマイク','有栖川帝統',array['Dice Arisugawa']::text[],9),
  ('2.5次元','ヒプノシスマイク','神宮寺寂雷',array['Jakurai Jinguji']::text[],10),
  ('2.5次元','ヒプノシスマイク','伊弉冉一二三',array['Hifumi Izanami']::text[],11),
  ('2.5次元','ヒプノシスマイク','観音坂独歩',array['Doppo Kannonzaka']::text[],12),
  ('2.5次元','アイドリッシュセブン','和泉一織',array['Iori Izumi']::text[],1),
  ('2.5次元','アイドリッシュセブン','二階堂大和',array['Yamato Nikaido']::text[],2),
  ('2.5次元','アイドリッシュセブン','和泉三月',array['Mitsuki Izumi']::text[],3),
  ('2.5次元','アイドリッシュセブン','四葉環',array['Tamaki Yotsuba']::text[],4),
  ('2.5次元','アイドリッシュセブン','逢坂壮五',array['Sogo Osaka']::text[],5),
  ('2.5次元','アイドリッシュセブン','六弥ナギ',array['Nagi Rokuya']::text[],6),
  ('2.5次元','アイドリッシュセブン','七瀬陸',array['Riku Nanase']::text[],7),
  ('2.5次元','アイドリッシュセブン','八乙女楽',array['Gaku Yaotome']::text[],8),
  ('2.5次元','アイドリッシュセブン','九条天',array['Tenn Kujo']::text[],9),
  ('2.5次元','アイドリッシュセブン','十龍之介',array['Ryunosuke Tsunashi']::text[],10),
  ('2.5次元','アイドリッシュセブン','百',array['Momo']::text[],11),
  ('2.5次元','アイドリッシュセブン','千',array['Yuki']::text[],12);

insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
select gm.id, ge.id, sc.name, sc.aliases, sc.display_order
from _ihub_seed_characters sc
join public.genres_master ge on ge.name = sc.genre_name
join public.groups_master gm on gm.genre_id = ge.id and gm.name = sc.group_name
where not exists (
  select 1
    from public.characters_master c
   where c.group_id = gm.id
     and c.name = sc.name
);

-- =====================================================================
-- 完了
-- =====================================================================
