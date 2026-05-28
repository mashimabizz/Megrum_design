-- =====================================================================
-- iter168.24: 推しマスタのL2必須補完
-- =====================================================================
-- グループ/作品として登録済みだが L2 が空だった推しL1に、
-- 実在するメンバー/キャラクター/公式マスコットを追加する。
-- 新規・既存どちらの L1 でも、kind in ('group','work') は
-- 最低1件以上の characters_master を持つ状態を目指す。

create temporary table _megrum_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _megrum_seed_characters (genre_name, group_name, name, aliases, display_order) values
  -- K-POP男性
  ('K-POP男性','THE BOYZ','サンヨン',array['SANGYEON','상연']::text[],1),
  ('K-POP男性','THE BOYZ','ジェイコブ',array['JACOB','제이콥']::text[],2),
  ('K-POP男性','THE BOYZ','ヨンフン',array['YOUNGHOON','영훈']::text[],3),
  ('K-POP男性','THE BOYZ','ヒョンジェ',array['HYUNJAE','현재']::text[],4),
  ('K-POP男性','THE BOYZ','ジュヨン',array['JUYEON','주연']::text[],5),
  ('K-POP男性','THE BOYZ','ケビン',array['KEVIN','케빈']::text[],6),
  ('K-POP男性','THE BOYZ','ニュー',array['NEW','뉴']::text[],7),
  ('K-POP男性','THE BOYZ','キュー',array['Q','큐']::text[],8),
  ('K-POP男性','THE BOYZ','ハンニョン',array['JU HAKNYEON','주학년']::text[],9),
  ('K-POP男性','THE BOYZ','ソヌ',array['SUNWOO','선우']::text[],10),
  ('K-POP男性','THE BOYZ','エリック',array['ERIC','에릭']::text[],11),
  ('K-POP男性','NCT 127','テヨン',array['TAEYONG','태용']::text[],1),
  ('K-POP男性','NCT 127','ジャニー',array['JOHNNY','쟈니']::text[],2),
  ('K-POP男性','NCT 127','ユウタ',array['YUTA','中本悠太','유타']::text[],3),
  ('K-POP男性','NCT 127','ドヨン',array['DOYOUNG','도영']::text[],4),
  ('K-POP男性','NCT 127','ジェヒョン',array['JAEHYUN','재현']::text[],5),
  ('K-POP男性','NCT 127','ジョンウ',array['JUNGWOO','정우']::text[],6),
  ('K-POP男性','NCT 127','マーク',array['MARK','Mark Lee','마크']::text[],7),
  ('K-POP男性','NCT 127','ヘチャン',array['HAECHAN','해찬']::text[],8),
  ('K-POP男性','SHINee','オンユ',array['ONEW','온유']::text[],1),
  ('K-POP男性','SHINee','キー',array['KEY','키']::text[],2),
  ('K-POP男性','SHINee','ミンホ',array['MINHO','민호']::text[],3),
  ('K-POP男性','SHINee','テミン',array['TAEMIN','태민']::text[],4),
  ('K-POP男性','MONSTA X','ショヌ',array['SHOWNU','셔누']::text[],1),
  ('K-POP男性','MONSTA X','ミニョク',array['MINHYUK','민혁']::text[],2),
  ('K-POP男性','MONSTA X','キヒョン',array['KIHYUN','기현']::text[],3),
  ('K-POP男性','MONSTA X','ヒョンウォン',array['HYUNGWON','형원']::text[],4),
  ('K-POP男性','MONSTA X','ジュホン',array['JOOHONEY','주헌']::text[],5),
  ('K-POP男性','MONSTA X','I.M',array['アイエム','아이엠']::text[],6),
  ('K-POP男性','xikers','ミンジェ',array['MINJAE','민재']::text[],1),
  ('K-POP男性','xikers','ジュンミン',array['JUNMIN','준민']::text[],2),
  ('K-POP男性','xikers','スミン',array['SUMIN','수민']::text[],3),
  ('K-POP男性','xikers','ジンシク',array['JINSIK','진식']::text[],4),
  ('K-POP男性','xikers','ヒョヌ',array['HYUNWOO','현우']::text[],5),
  ('K-POP男性','xikers','ジョンフン',array['JUNGHOON','정훈']::text[],6),
  ('K-POP男性','xikers','セウン',array['SEEUN','세은']::text[],7),
  ('K-POP男性','xikers','ユジュン',array['YUJUN','유준']::text[],8),
  ('K-POP男性','xikers','ハンター',array['HUNTER']::text[],9),
  ('K-POP男性','xikers','イェチャン',array['YECHAN','예찬']::text[],10),

  -- K-POP女性
  ('K-POP女性','STAYC','スミン',array['SUMIN','수민']::text[],1),
  ('K-POP女性','STAYC','シウン',array['SIEUN','시은']::text[],2),
  ('K-POP女性','STAYC','アイサ',array['ISA','아이사']::text[],3),
  ('K-POP女性','STAYC','セウン',array['SEEUN','세은']::text[],4),
  ('K-POP女性','STAYC','ユン',array['YOON','윤']::text[],5),
  ('K-POP女性','STAYC','ジェイ',array['J','재이']::text[],6),
  ('K-POP女性','Kep1er','チェヒョン',array['CHAEHYUN','김채현']::text[],1),
  ('K-POP女性','Kep1er','シャオティン',array['XIAOTING','沈小婷']::text[],2),
  ('K-POP女性','Kep1er','マシロ',array['MASHIRO','坂本舞白']::text[],3),
  ('K-POP女性','Kep1er','ユジン',array['YUJIN','최유진']::text[],4),
  ('K-POP女性','Kep1er','ダヨン',array['DAYEON','김다연']::text[],5),
  ('K-POP女性','Kep1er','ヒカル',array['HIKARU','江崎ひかる']::text[],6),
  ('K-POP女性','Kep1er','ヒュニンバヒエ',array['HUENING BAHIYYIH','휴닝바히에']::text[],7),
  ('K-POP女性','Kep1er','ヨンウン',array['YOUNGEUN','서영은']::text[],8),
  ('K-POP女性','Kep1er','イェソ',array['YESEO','강예서']::text[],9),
  ('K-POP女性','Billlie','ムンスア',array['MOON SUA','문수아']::text[],1),
  ('K-POP女性','Billlie','スヒョン',array['SUHYEON','수현']::text[],2),
  ('K-POP女性','Billlie','ハラム',array['HARAM','하람']::text[],3),
  ('K-POP女性','Billlie','つき',array['TSUKI','福富つき']::text[],4),
  ('K-POP女性','Billlie','ション',array['SHEON','션']::text[],5),
  ('K-POP女性','Billlie','シユン',array['SIYOON','시윤']::text[],6),
  ('K-POP女性','Billlie','ハルナ',array['HARUNA','大里春菜']::text[],7),
  ('K-POP女性','tripleS','ユン・ソヨン',array['Yoon SeoYeon','윤서연']::text[],1),
  ('K-POP女性','tripleS','チョン・ヘリン',array['Jeong HyeRin','정혜린']::text[],2),
  ('K-POP女性','tripleS','イ・ジウ',array['Lee JiWoo','이지우']::text[],3),
  ('K-POP女性','tripleS','キム・チェヨン',array['Kim ChaeYeon','김채연']::text[],4),
  ('K-POP女性','tripleS','キム・ユヨン',array['Kim YooYeon','김유연']::text[],5),
  ('K-POP女性','tripleS','キム・スミン',array['Kim SooMin','김수민']::text[],6),
  ('K-POP女性','tripleS','キム・ナギョン',array['Kim NaKyoung','김나경']::text[],7),
  ('K-POP女性','tripleS','コン・ユビン',array['Gong YuBin','공유빈']::text[],8),
  ('K-POP女性','tripleS','カエデ',array['Kaede','카에데']::text[],9),
  ('K-POP女性','tripleS','ソ・ダヒョン',array['Seo DaHyun','서다현']::text[],10),
  ('K-POP女性','tripleS','コトネ',array['Kotone','카미모토 코토네']::text[],11),
  ('K-POP女性','tripleS','マユ',array['Mayu','마유']::text[],12),

  -- 国内男性
  ('国内男性','WEST.','重岡大毅',array['Daiki Shigeoka']::text[],1),
  ('国内男性','WEST.','桐山照史',array['Akito Kiriyama']::text[],2),
  ('国内男性','WEST.','中間淳太',array['Junta Nakama']::text[],3),
  ('国内男性','WEST.','神山智洋',array['Tomohiro Kamiyama']::text[],4),
  ('国内男性','WEST.','藤井流星',array['Ryusei Fujii']::text[],5),
  ('国内男性','WEST.','濵田崇裕',array['Takahiro Hamada','浜田崇裕']::text[],6),
  ('国内男性','WEST.','小瀧望',array['Nozomu Kotaki']::text[],7),
  ('国内男性','超特急','カイ',array[]::text[],1),
  ('国内男性','超特急','リョウガ',array[]::text[],2),
  ('国内男性','超特急','タクヤ',array[]::text[],3),
  ('国内男性','超特急','ユーキ',array[]::text[],4),
  ('国内男性','超特急','タカシ',array[]::text[],5),
  ('国内男性','超特急','シューヤ',array[]::text[],6),
  ('国内男性','超特急','マサヒロ',array[]::text[],7),
  ('国内男性','超特急','アロハ',array[]::text[],8),
  ('国内男性','超特急','ハル',array[]::text[],9),
  ('国内男性','THE RAMPAGE','LIKIYA',array[]::text[],1),
  ('国内男性','THE RAMPAGE','陣',array[]::text[],2),
  ('国内男性','THE RAMPAGE','RIKU',array[]::text[],3),
  ('国内男性','THE RAMPAGE','神谷健太',array['Kenta Kamiya']::text[],4),
  ('国内男性','THE RAMPAGE','与那嶺瑠唯',array['Rui Yonamine']::text[],5),
  ('国内男性','THE RAMPAGE','山本彰吾',array['Shogo Yamamoto']::text[],6),
  ('国内男性','THE RAMPAGE','川村壱馬',array['Kazuma Kawamura']::text[],7),
  ('国内男性','THE RAMPAGE','吉野北人',array['Hokuto Yoshino']::text[],8),
  ('国内男性','THE RAMPAGE','岩谷翔吾',array['Shogo Iwaya']::text[],9),
  ('国内男性','THE RAMPAGE','浦川翔平',array['Shohei Urakawa']::text[],10),
  ('国内男性','THE RAMPAGE','藤原樹',array['Itsuki Fujiwara']::text[],11),
  ('国内男性','THE RAMPAGE','武知海青',array['Kaisei Takechi']::text[],12),
  ('国内男性','THE RAMPAGE','長谷川慎',array['Makoto Hasegawa']::text[],13),
  ('国内男性','THE RAMPAGE','龍',array['Ryu']::text[],14),
  ('国内男性','THE RAMPAGE','鈴木昂秀',array['Takahide Suzuki']::text[],15),
  ('国内男性','THE RAMPAGE','後藤拓磨',array['Takuma Goto']::text[],16),
  ('国内男性','GENERATIONS','白濱亜嵐',array['Alan Shirahama']::text[],1),
  ('国内男性','GENERATIONS','片寄涼太',array['Ryota Katayose']::text[],2),
  ('国内男性','GENERATIONS','数原龍友',array['Ryuto Kazuhara']::text[],3),
  ('国内男性','GENERATIONS','小森隼',array['Hayato Komori']::text[],4),
  ('国内男性','GENERATIONS','佐野玲於',array['Reo Sano']::text[],5),
  ('国内男性','GENERATIONS','中務裕太',array['Yuta Nakatsuka']::text[],6),

  -- 国内女性
  ('国内女性','乃木坂46','遠藤さくら',array['Sakura Endo']::text[],1),
  ('国内女性','乃木坂46','賀喜遥香',array['Haruka Kaki']::text[],2),
  ('国内女性','乃木坂46','井上和',array['Nagi Inoue']::text[],3),
  ('国内女性','乃木坂46','久保史緒里',array['Shiori Kubo']::text[],4),
  ('国内女性','乃木坂46','梅澤美波',array['Minami Umezawa']::text[],5),
  ('国内女性','櫻坂46','山﨑天',array['Ten Yamasaki','山崎天']::text[],1),
  ('国内女性','櫻坂46','森田ひかる',array['Hikaru Morita']::text[],2),
  ('国内女性','櫻坂46','田村保乃',array['Hono Tamura']::text[],3),
  ('国内女性','櫻坂46','藤吉夏鈴',array['Karin Fujiyoshi']::text[],4),
  ('国内女性','櫻坂46','守屋麗奈',array['Rena Moriya']::text[],5),
  ('国内女性','日向坂46','小坂菜緒',array['Nao Kosaka']::text[],1),
  ('国内女性','日向坂46','金村美玖',array['Miku Kanemura']::text[],2),
  ('国内女性','日向坂46','河田陽菜',array['Hina Kawata']::text[],3),
  ('国内女性','日向坂46','正源司陽子',array['Yoko Shogenji']::text[],4),
  ('国内女性','日向坂46','藤嶌果歩',array['Kaho Fujishima']::text[],5),
  ('国内女性','AKB48','小栗有以',array['Yui Oguri']::text[],1),
  ('国内女性','AKB48','村山彩希',array['Yuiri Murayama']::text[],2),
  ('国内女性','AKB48','倉野尾成美',array['Narumi Kuranoo']::text[],3),
  ('国内女性','AKB48','千葉恵里',array['Erii Chiba']::text[],4),
  ('国内女性','AKB48','向井地美音',array['Mion Mukaichi']::text[],5),
  ('国内女性','SKE48','松井珠理奈',array['Jurina Matsui']::text[],1),
  ('国内女性','SKE48','須田亜香里',array['Akari Suda']::text[],2),
  ('国内女性','SKE48','高柳明音',array['Akane Takayanagi']::text[],3),
  ('国内女性','SKE48','熊崎晴香',array['Haruka Kumazaki']::text[],4),
  ('国内女性','SKE48','末永桜花',array['Oka Suenaga']::text[],5),
  ('国内女性','NMB48','山本彩',array['Sayaka Yamamoto']::text[],1),
  ('国内女性','NMB48','小嶋花梨',array['Karin Kojima']::text[],2),
  ('国内女性','NMB48','上西怜',array['Rei Jonishi']::text[],3),
  ('国内女性','NMB48','安部若菜',array['Wakana Abe']::text[],4),
  ('国内女性','NMB48','塩月希依音',array['Keito Shiotsuki']::text[],5),
  ('国内女性','HKT48','田中美久',array['Miku Tanaka']::text[],1),
  ('国内女性','HKT48','松岡はな',array['Hana Matsuoka']::text[],2),
  ('国内女性','HKT48','豊永阿紀',array['Aki Toyonaga']::text[],3),
  ('国内女性','HKT48','地頭江音々',array['Nene Jitoe']::text[],4),
  ('国内女性','HKT48','石橋颯',array['Ibuki Ishibashi']::text[],5),
  ('国内女性','STU48','瀧野由美子',array['Yumiko Takino']::text[],1),
  ('国内女性','STU48','石田千穂',array['Chiho Ishida']::text[],2),
  ('国内女性','STU48','中村舞',array['Mai Nakamura']::text[],3),
  ('国内女性','STU48','岩田陽菜',array['Hina Iwata']::text[],4),
  ('国内女性','STU48','甲斐心愛',array['Kokoa Kai']::text[],5),
  ('国内女性','ももいろクローバーZ','百田夏菜子',array['Kanako Momota']::text[],1),
  ('国内女性','ももいろクローバーZ','玉井詩織',array['Shiori Tamai']::text[],2),
  ('国内女性','ももいろクローバーZ','佐々木彩夏',array['Ayaka Sasaki']::text[],3),
  ('国内女性','ももいろクローバーZ','高城れに',array['Reni Takagi']::text[],4),
  ('国内女性','私立恵比寿中学','真山りか',array['Rika Mayama']::text[],1),
  ('国内女性','私立恵比寿中学','安本彩花',array['Ayaka Yasumoto']::text[],2),
  ('国内女性','私立恵比寿中学','小林歌穂',array['Kaho Kobayashi']::text[],3),
  ('国内女性','私立恵比寿中学','中山莉子',array['Riko Nakayama']::text[],4),
  ('国内女性','私立恵比寿中学','桜木心菜',array['Cocona Sakuragi']::text[],5),
  ('国内女性','CUTIE STREET','桜庭遥花',array['Haruka Sakuraba']::text[],1),
  ('国内女性','CUTIE STREET','佐野愛花',array['Aika Sano']::text[],2),
  ('国内女性','CUTIE STREET','古澤里紗',array['Risa Furusawa']::text[],3),
  ('国内女性','CUTIE STREET','川本笑瑠',array['Emiru Kawamoto']::text[],4),
  ('国内女性','CUTIE STREET','梅田みゆ',array['Miyu Umeda']::text[],5),
  ('国内女性','高嶺のなでしこ','城月菜央',array['Nao Kizuki']::text[],1),
  ('国内女性','高嶺のなでしこ','橋本桃呼',array['Momoko Hashimoto']::text[],2),
  ('国内女性','高嶺のなでしこ','葉月紗蘭',array['Saran Hazuki']::text[],3),
  ('国内女性','高嶺のなでしこ','松本ももな',array['Momona Matsumoto']::text[],4),
  ('国内女性','高嶺のなでしこ','涼海すう',array['Suu Suzumi']::text[],5),
  ('国内女性','iLiFE!','あいす',array[]::text[],1),
  ('国内女性','iLiFE!','心花りり',array[]::text[],2),
  ('国内女性','iLiFE!','有栖るな',array[]::text[],3),
  ('国内女性','iLiFE!','若葉のあ',array[]::text[],4),
  ('国内女性','モーニング娘。','生田衣梨奈',array['Erina Ikuta']::text[],1),
  ('国内女性','モーニング娘。','小田さくら',array['Sakura Oda']::text[],2),
  ('国内女性','モーニング娘。','野中美希',array['Miki Nonaka']::text[],3),
  ('国内女性','モーニング娘。','牧野真莉愛',array['Maria Makino']::text[],4),
  ('国内女性','モーニング娘。','羽賀朱音',array['Akane Haga']::text[],5),

  -- 歌い手グループ
  ('歌い手','すとぷり','莉犬',array['Rinu']::text[],1),
  ('歌い手','すとぷり','るぅと',array['Root']::text[],2),
  ('歌い手','すとぷり','ころん',array['Colon']::text[],3),
  ('歌い手','すとぷり','さとみ',array['Satomi']::text[],4),
  ('歌い手','すとぷり','ジェル',array['Jel']::text[],5),
  ('歌い手','すとぷり','ななもり。',array['Nanamori']::text[],6),
  ('歌い手','いれいす','りうら',array[]::text[],1),
  ('歌い手','いれいす','hotoke',array['-hotoke-','いむくん']::text[],2),
  ('歌い手','いれいす','初兎',array['しょう']::text[],3),
  ('歌い手','いれいす','ないこ',array[]::text[],4),
  ('歌い手','いれいす','If',array['いふ']::text[],5),
  ('歌い手','いれいす','悠佑',array['ゆうすけ']::text[],6),
  ('歌い手','Knight A - 騎士A -','ばぁう',array[]::text[],1),
  ('歌い手','Knight A - 騎士A -','そうま',array[]::text[],2),
  ('歌い手','Knight A - 騎士A -','しゆん',array[]::text[],3),
  ('歌い手','Knight A - 騎士A -','てるとくん',array[]::text[],4),
  ('歌い手','Knight A - 騎士A -','まひとくん。',array[]::text[],5),
  ('歌い手','浦島坂田船','うらたぬき',array[]::text[],1),
  ('歌い手','浦島坂田船','志麻',array[]::text[],2),
  ('歌い手','浦島坂田船','となりの坂田。',array['あほの坂田。']::text[],3),
  ('歌い手','浦島坂田船','センラ',array[]::text[],4),
  ('歌い手','After the Rain','そらる',array['Soraru']::text[],1),
  ('歌い手','After the Rain','まふまふ',array['Mafumafu']::text[],2),
  ('歌い手','AMPTAKxCOLORS','あっきぃ',array[]::text[],1),
  ('歌い手','AMPTAKxCOLORS','まぜ太',array[]::text[],2),
  ('歌い手','AMPTAKxCOLORS','ぷりっつ',array[]::text[],3),
  ('歌い手','AMPTAKxCOLORS','ちぐさくん',array[]::text[],4),
  ('歌い手','AMPTAKxCOLORS','あっと',array[]::text[],5),
  ('歌い手','AMPTAKxCOLORS','けちゃ',array[]::text[],6),
  ('歌い手','ちょこらび','ポケカメン',array[]::text[],1),
  ('歌い手','ちょこらび','まいたけ',array[]::text[],2),
  ('歌い手','ちょこらび','ゆぺくん☆★',array[]::text[],3),
  ('歌い手','ちょこらび','さくらくん。',array[]::text[],4),
  ('歌い手','ちょこらび','かにちゃん',array[]::text[],5),
  ('歌い手','ちょこらび','ふぇにくろ',array[]::text[],6),
  ('歌い手','めろんぱーかー','なろ屋',array[]::text[],1),
  ('歌い手','めろんぱーかー','サムライ翔',array[]::text[],2),
  ('歌い手','めろんぱーかー','のっき',array[]::text[],3),
  ('歌い手','めろんぱーかー','そらねこ',array[]::text[],4),
  ('歌い手','めろんぱーかー','KAITO',array[]::text[],5),
  ('歌い手','めろんぱーかー','kamome',array[]::text[],6),

  -- 2.5次元・舞台 / 作品系
  ('2.5次元・舞台','A3!','佐久間咲也',array[]::text[],1),
  ('2.5次元・舞台','A3!','碓氷真澄',array[]::text[],2),
  ('2.5次元・舞台','A3!','皆木綴',array[]::text[],3),
  ('2.5次元・舞台','A3!','茅ヶ崎至',array[]::text[],4),
  ('2.5次元・舞台','A3!','皇天馬',array[]::text[],5),
  ('2.5次元・舞台','A3!','瑠璃川幸',array[]::text[],6),
  ('2.5次元・舞台','A3!','摂津万里',array[]::text[],7),
  ('2.5次元・舞台','A3!','月岡紬',array[]::text[],8),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','一十木音也',array[]::text[],1),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','聖川真斗',array[]::text[],2),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','四ノ宮那月',array[]::text[],3),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','一ノ瀬トキヤ',array[]::text[],4),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','神宮寺レン',array[]::text[],5),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','来栖翔',array[]::text[],6),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','愛島セシル',array[]::text[],7),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','寿嶺二',array[]::text[],8),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','黒崎蘭丸',array[]::text[],9),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','美風藍',array[]::text[],10),
  ('2.5次元・舞台','うたの☆プリンスさまっ♪','カミュ',array[]::text[],11),
  ('2.5次元・舞台','魔法使いの約束','オズ',array[]::text[],1),
  ('2.5次元・舞台','魔法使いの約束','アーサー',array[]::text[],2),
  ('2.5次元・舞台','魔法使いの約束','カイン',array[]::text[],3),
  ('2.5次元・舞台','魔法使いの約束','リケ',array[]::text[],4),
  ('2.5次元・舞台','魔法使いの約束','スノウ',array[]::text[],5),
  ('2.5次元・舞台','魔法使いの約束','ホワイト',array[]::text[],6),
  ('2.5次元・舞台','魔法使いの約束','ミスラ',array[]::text[],7),
  ('2.5次元・舞台','魔法使いの約束','オーエン',array[]::text[],8),
  ('2.5次元・舞台','魔法使いの約束','ブラッドリー',array[]::text[],9),
  ('2.5次元・舞台','魔法使いの約束','ファウスト',array[]::text[],10),
  ('2.5次元・舞台','魔法使いの約束','シノ',array[]::text[],11),
  ('2.5次元・舞台','魔法使いの約束','ヒースクリフ',array[]::text[],12),
  ('2.5次元・舞台','Paradox Live','朱雀野アレン',array[]::text[],1),
  ('2.5次元・舞台','Paradox Live','燕夏準',array[]::text[],2),
  ('2.5次元・舞台','Paradox Live','アン・フォークナー',array['Anne Faulkner']::text[],3),
  ('2.5次元・舞台','Paradox Live','西門直明',array[]::text[],4),
  ('2.5次元・舞台','Paradox Live','神林匋平',array[]::text[],5),
  ('2.5次元・舞台','Paradox Live','棗リュウ',array[]::text[],6),
  ('2.5次元・舞台','Paradox Live','闇堂四季',array[]::text[],7),
  ('2.5次元・舞台','Paradox Live','矢戸乃上珂波汰',array[]::text[],8),
  ('2.5次元・舞台','Paradox Live','矢戸乃上那由汰',array[]::text[],9),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','越前リョーマ',array[]::text[],1),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','手塚国光',array[]::text[],2),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','不二周助',array[]::text[],3),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','跡部景吾',array[]::text[],4),
  ('2.5次元・舞台','ミュージカル「テニスの王子様」','幸村精市',array[]::text[],5),
  ('2.5次元・舞台','舞台「刀剣乱舞」','三日月宗近',array[]::text[],1),
  ('2.5次元・舞台','舞台「刀剣乱舞」','山姥切国広',array[]::text[],2),
  ('2.5次元・舞台','舞台「刀剣乱舞」','へし切長谷部',array[]::text[],3),
  ('2.5次元・舞台','舞台「刀剣乱舞」','鶴丸国永',array[]::text[],4),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','三日月宗近',array[]::text[],1),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','小狐丸',array[]::text[],2),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','石切丸',array[]::text[],3),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','岩融',array[]::text[],4),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','今剣',array[]::text[],5),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','加州清光',array[]::text[],6),

  -- ゲーム / キャラクターIP
  ('ゲーム','アイドルマスター シンデレラガールズ','島村卯月',array[]::text[],1),
  ('ゲーム','アイドルマスター シンデレラガールズ','渋谷凛',array[]::text[],2),
  ('ゲーム','アイドルマスター シンデレラガールズ','本田未央',array[]::text[],3),
  ('ゲーム','アイドルマスター シンデレラガールズ','双葉杏',array[]::text[],4),
  ('ゲーム','アイドルマスター シンデレラガールズ','神崎蘭子',array[]::text[],5),
  ('ゲーム','アイドルマスター SideM','天道輝',array[]::text[],1),
  ('ゲーム','アイドルマスター SideM','桜庭薫',array[]::text[],2),
  ('ゲーム','アイドルマスター SideM','柏木翼',array[]::text[],3),
  ('ゲーム','アイドルマスター SideM','天ヶ瀬冬馬',array[]::text[],4),
  ('ゲーム','アイドルマスター SideM','伊集院北斗',array[]::text[],5),
  ('キャラクターIP','mofusand','サメにゃん',array[]::text[],1),
  ('キャラクターIP','mofusand','えびにゃん',array[]::text[],2),
  ('キャラクターIP','mofusand','うさにゃん',array[]::text[],3),
  ('キャラクターIP','mofusand','ハチにゃん',array[]::text[],4),

  -- スポーツ: グッズ化されやすく、メンバー推しとして選べる公式マスコット
  ('スポーツ','阪神タイガース','トラッキー',array[]::text[],1),
  ('スポーツ','読売ジャイアンツ','ジャビット',array[]::text[],1),
  ('スポーツ','東京ヤクルトスワローズ','つば九郎',array[]::text[],1),
  ('スポーツ','オリックス・バファローズ','バファローブル',array[]::text[],1),
  ('スポーツ','北海道日本ハムファイターズ','フレップ・ザ・フォックス',array['フレップ']::text[],1),
  ('スポーツ','福岡ソフトバンクホークス','ハリーホーク',array[]::text[],1),
  ('スポーツ','浦和レッズ','レディア',array[]::text[],1),
  ('スポーツ','鹿島アントラーズ','しかお',array[]::text[],1),
  ('スポーツ','横浜F・マリノス','マリノスケ',array[]::text[],1),
  ('スポーツ','川崎フロンターレ','ふろん太',array[]::text[],1),
  ('スポーツ','ヴィッセル神戸','モーヴィ',array[]::text[],1),
  ('スポーツ','千葉ジェッツ','ジャンボくん',array[]::text[],1),
  ('スポーツ','宇都宮ブレックス','ブレッキー',array[]::text[],1),
  ('スポーツ','アルバルク東京','ルーク',array[]::text[],1),
  ('スポーツ','琉球ゴールデンキングス','ゴーディー',array[]::text[],1),
  ('スポーツ','横浜ビー・コルセアーズ','コルス',array[]::text[],1);

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

-- 追加した L2 / solo L1 に entity を付与する。
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

-- 複数の選択文脈に出る同一人物・同一キャラを明示リンクする。
create temporary table _megrum_manual_group_entities (
  genre_name text not null,
  group_name text not null,
  identity_key text not null,
  canonical_name text not null,
  entity_type text not null,
  aliases text[] not null default '{}',
  display_order integer not null default 0
) on commit drop;

insert into _megrum_manual_group_entities (genre_name, group_name, identity_key, canonical_name, entity_type, aliases, display_order) values
  ('歌い手','まふまふ','person:mafumafu','まふまふ','person',array['Mafumafu']::text[],1),
  ('歌い手','そらる','person:soraru','そらる','person',array['Soraru']::text[],2);

insert into public.oshi_entities_master (identity_key, canonical_name, entity_type, aliases, display_order)
select identity_key, canonical_name, entity_type, aliases, display_order
from _megrum_manual_group_entities
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

update public.groups_master gm
set entity_id = e.id
from _megrum_manual_group_entities mge
join public.genres_master ge on ge.name = mge.genre_name
join public.oshi_entities_master e on e.identity_key = mge.identity_key
where gm.genre_id = ge.id
  and gm.name = mge.group_name
  and gm.entity_id is distinct from e.id;

create temporary table _megrum_manual_character_entities (
  genre_name text not null,
  group_name text not null,
  character_name text not null,
  identity_key text not null,
  canonical_name text not null,
  entity_type text not null,
  aliases text[] not null default '{}',
  display_order integer not null default 0
) on commit drop;

insert into _megrum_manual_character_entities (
  genre_name,
  group_name,
  character_name,
  identity_key,
  canonical_name,
  entity_type,
  aliases,
  display_order
) values
  ('K-POP男性','NCT DREAM','マーク','person:mark-lee','マーク','person',array['MARK','Mark Lee','마크']::text[],1),
  ('K-POP男性','NCT 127','マーク','person:mark-lee','マーク','person',array['MARK','Mark Lee','마크']::text[],1),
  ('K-POP男性','NCT DREAM','ヘチャン','person:haechan','ヘチャン','person',array['HAECHAN','해찬']::text[],2),
  ('K-POP男性','NCT 127','ヘチャン','person:haechan','ヘチャン','person',array['HAECHAN','해찬']::text[],2),
  ('歌い手','After the Rain','まふまふ','person:mafumafu','まふまふ','person',array['Mafumafu']::text[],3),
  ('歌い手','After the Rain','そらる','person:soraru','そらる','person',array['Soraru']::text[],4),
  ('2.5次元・舞台','刀剣乱舞','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('2.5次元・舞台','舞台「刀剣乱舞」','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('2.5次元・舞台','刀剣乱舞','山姥切国広','character:touken-yamanbagiri-kunihiro','山姥切国広','character',array[]::text[],2),
  ('2.5次元・舞台','舞台「刀剣乱舞」','山姥切国広','character:touken-yamanbagiri-kunihiro','山姥切国広','character',array[]::text[],2),
  ('2.5次元・舞台','刀剣乱舞','へし切長谷部','character:touken-heshikiri-hasebe','へし切長谷部','character',array[]::text[],3),
  ('2.5次元・舞台','舞台「刀剣乱舞」','へし切長谷部','character:touken-heshikiri-hasebe','へし切長谷部','character',array[]::text[],3),
  ('2.5次元・舞台','刀剣乱舞','鶴丸国永','character:touken-tsurumaru-kuninaga','鶴丸国永','character',array[]::text[],4),
  ('2.5次元・舞台','舞台「刀剣乱舞」','鶴丸国永','character:touken-tsurumaru-kuninaga','鶴丸国永','character',array[]::text[],4),
  ('2.5次元・舞台','刀剣乱舞','加州清光','character:touken-kashu-kiyomitsu','加州清光','character',array[]::text[],5),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','加州清光','character:touken-kashu-kiyomitsu','加州清光','character',array[]::text[],5),
  ('スポーツ','阪神タイガース','トラッキー','character:sports-mascot:阪神タイガース:トラッキー','トラッキー','character',array[]::text[],1),
  ('スポーツ','読売ジャイアンツ','ジャビット','character:sports-mascot:読売ジャイアンツ:ジャビット','ジャビット','character',array[]::text[],1),
  ('スポーツ','東京ヤクルトスワローズ','つば九郎','character:sports-mascot:東京ヤクルトスワローズ:つば九郎','つば九郎','character',array[]::text[],1),
  ('スポーツ','オリックス・バファローズ','バファローブル','character:sports-mascot:オリックス・バファローズ:バファローブル','バファローブル','character',array[]::text[],1),
  ('スポーツ','北海道日本ハムファイターズ','フレップ・ザ・フォックス','character:sports-mascot:北海道日本ハムファイターズ:フレップ','フレップ・ザ・フォックス','character',array['フレップ']::text[],1),
  ('スポーツ','福岡ソフトバンクホークス','ハリーホーク','character:sports-mascot:福岡ソフトバンクホークス:ハリーホーク','ハリーホーク','character',array[]::text[],1),
  ('スポーツ','浦和レッズ','レディア','character:sports-mascot:浦和レッズ:レディア','レディア','character',array[]::text[],1),
  ('スポーツ','鹿島アントラーズ','しかお','character:sports-mascot:鹿島アントラーズ:しかお','しかお','character',array[]::text[],1),
  ('スポーツ','横浜F・マリノス','マリノスケ','character:sports-mascot:横浜F・マリノス:マリノスケ','マリノスケ','character',array[]::text[],1),
  ('スポーツ','川崎フロンターレ','ふろん太','character:sports-mascot:川崎フロンターレ:ふろん太','ふろん太','character',array[]::text[],1),
  ('スポーツ','ヴィッセル神戸','モーヴィ','character:sports-mascot:ヴィッセル神戸:モーヴィ','モーヴィ','character',array[]::text[],1),
  ('スポーツ','千葉ジェッツ','ジャンボくん','character:sports-mascot:千葉ジェッツ:ジャンボくん','ジャンボくん','character',array[]::text[],1),
  ('スポーツ','宇都宮ブレックス','ブレッキー','character:sports-mascot:宇都宮ブレックス:ブレッキー','ブレッキー','character',array[]::text[],1),
  ('スポーツ','アルバルク東京','ルーク','character:sports-mascot:アルバルク東京:ルーク','ルーク','character',array[]::text[],1),
  ('スポーツ','琉球ゴールデンキングス','ゴーディー','character:sports-mascot:琉球ゴールデンキングス:ゴーディー','ゴーディー','character',array[]::text[],1),
  ('スポーツ','横浜ビー・コルセアーズ','コルス','character:sports-mascot:横浜ビー・コルセアーズ:コルス','コルス','character',array[]::text[],1);

insert into public.oshi_entities_master (identity_key, canonical_name, entity_type, aliases, display_order)
select
  mce.identity_key,
  min(canonical_name) as canonical_name,
  min(entity_type) as entity_type,
  array(
    select distinct alias
    from _megrum_manual_character_entities m2
    cross join unnest(m2.aliases) as a(alias)
    where m2.identity_key = mce.identity_key
      and btrim(alias) <> ''
    order by alias
  ) as aliases,
  min(display_order) as display_order
from _megrum_manual_character_entities mce
group by mce.identity_key
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

update public.characters_master cm
set entity_id = e.id
from _megrum_manual_character_entities mce
join public.genres_master ge on ge.name = mce.genre_name
join public.groups_master gm on gm.genre_id = ge.id and gm.name = mce.group_name
join public.oshi_entities_master e on e.identity_key = mce.identity_key
where cm.genre_id = ge.id
  and cm.group_id = gm.id
  and cm.name = mce.character_name
  and cm.entity_id is distinct from e.id;
