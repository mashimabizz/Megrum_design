-- =====================================================================
-- iter168.18: 推し登録マスタ拡充 第三弾（LAPONE / イコノイ）
-- =====================================================================
-- 邦アイの箱推し登録だけでなく、メンバー単位の推し登録にも使えるように
-- JO1 / INI / ME:I / King & Prince / =LOVE / ≠ME を補完する。

create temporary table _megrum_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _megrum_seed_characters (genre_name, group_name, name, aliases, display_order) values
  ('邦アイ','King & Prince','永瀬廉',array['Ren Nagase']::text[],1),
  ('邦アイ','King & Prince','髙橋海人',array['Kaito Takahashi']::text[],2),
  ('邦アイ','JO1','與那城奨',array['Sho Yonashiro']::text[],1),
  ('邦アイ','JO1','川尻蓮',array['Ren Kawashiri']::text[],2),
  ('邦アイ','JO1','白岩瑠姫',array['Ruki Shiroiwa']::text[],3),
  ('邦アイ','JO1','河野純喜',array['Junki Kono']::text[],4),
  ('邦アイ','JO1','佐藤景瑚',array['Keigo Sato']::text[],5),
  ('邦アイ','JO1','川西拓実',array['Takumi Kawanishi']::text[],6),
  ('邦アイ','JO1','木全翔也',array['Syoya Kimata','Shoya Kimata']::text[],7),
  ('邦アイ','JO1','大平祥生',array['Shosei Ohira']::text[],8),
  ('邦アイ','JO1','金城碧海',array['Sukai Kinjo']::text[],9),
  ('邦アイ','JO1','鶴房汐恩',array['Shion Tsurubo']::text[],10),
  ('邦アイ','JO1','豆原一成',array['Issei Mamehara']::text[],11),
  ('邦アイ','INI','木村柾哉',array['Masaya Kimura']::text[],1),
  ('邦アイ','INI','西洸人',array['Hiroto Nishi']::text[],2),
  ('邦アイ','INI','許豊凡',array['Fengfan Xu','Xu Fengfan']::text[],3),
  ('邦アイ','INI','田島将吾',array['Shogo Tajima']::text[],4),
  ('邦アイ','INI','髙塚大夢',array['Hiromu Takatsuka']::text[],5),
  ('邦アイ','INI','後藤威尊',array['Takeru Goto']::text[],6),
  ('邦アイ','INI','尾崎匠海',array['Takumi Ozaki']::text[],7),
  ('邦アイ','INI','藤牧京介',array['Kyosuke Fujimaki']::text[],8),
  ('邦アイ','INI','佐野雄大',array['Yudai Sano']::text[],9),
  ('邦アイ','INI','池﨑理人',array['Rihito Ikezaki','Rihito Ikesaki']::text[],10),
  ('邦アイ','INI','松田迅',array['Jin Matsuda']::text[],11),
  ('邦アイ','ME:I','笠原桃奈',array['Momona Kasahara']::text[],1),
  ('邦アイ','ME:I','村上璃杏',array['Rinon Murakami']::text[],2),
  ('邦アイ','ME:I','高見文寧',array['Ayane Takami']::text[],3),
  ('邦アイ','ME:I','櫻井美羽',array['Miu Sakurai']::text[],4),
  ('邦アイ','ME:I','山本すず',array['Suzu Yamamoto']::text[],5),
  ('邦アイ','ME:I','清水恵子',array['Keiko Shimizu']::text[],6),
  ('邦アイ','ME:I','海老原鼓',array['Tsuzumi Ebihara']::text[],7),
  ('邦アイ','ME:I','飯田栞月',array['Shizuku Iida']::text[],8),
  ('邦アイ','ME:I','石井蘭',array['Ran Ishii']::text[],9),
  ('邦アイ','ME:I','加藤心',array['Kokoro Kato']::text[],10),
  ('邦アイ','ME:I','佐々木心菜',array['Kokona Sasaki']::text[],11),
  ('邦アイ','=LOVE','音嶋莉沙',array['Risa Otoshima']::text[],1),
  ('邦アイ','=LOVE','大谷映美里',array['Emiri Otani']::text[],2),
  ('邦アイ','=LOVE','大場花菜',array['Hana Oba']::text[],3),
  ('邦アイ','=LOVE','齋藤樹愛羅',array['Kiara Saito']::text[],4),
  ('邦アイ','=LOVE','佐々木舞香',array['Maika Sasaki']::text[],5),
  ('邦アイ','=LOVE','髙松瞳',array['Hitomi Takamatsu']::text[],6),
  ('邦アイ','=LOVE','瀧脇笙古',array['Shoko Takiwaki']::text[],7),
  ('邦アイ','=LOVE','野口衣織',array['Iori Noguchi']::text[],8),
  ('邦アイ','=LOVE','諸橋沙夏',array['Sana Morohashi']::text[],9),
  ('邦アイ','=LOVE','山本杏奈',array['Anna Yamamoto']::text[],10),
  ('邦アイ','≠ME','尾木波菜',array['Hana Ogi']::text[],1),
  ('邦アイ','≠ME','落合希来里',array['Kirari Ochiai']::text[],2),
  ('邦アイ','≠ME','蟹沢萌子',array['Moeko Kanisawa']::text[],3),
  ('邦アイ','≠ME','河口夏音',array['Natsune Kawaguchi']::text[],4),
  ('邦アイ','≠ME','川中子奈月心',array['Natsumi Kawanago']::text[],5),
  ('邦アイ','≠ME','櫻井もも',array['Momo Sakurai']::text[],6),
  ('邦アイ','≠ME','菅波美玲',array['Mirei Suganami']::text[],7),
  ('邦アイ','≠ME','鈴木瞳美',array['Hitomi Suzuki']::text[],8),
  ('邦アイ','≠ME','谷崎早耶',array['Saya Tanizaki']::text[],9),
  ('邦アイ','≠ME','冨田菜々風',array['Nanaka Tomita']::text[],10),
  ('邦アイ','≠ME','永田詩央里',array['Shiori Nagata']::text[],11),
  ('邦アイ','≠ME','本田珠由記',array['Miyuki Honda']::text[],12);

insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
select gm.id, ge.id, sc.name, sc.aliases, sc.display_order
from _megrum_seed_characters sc
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
