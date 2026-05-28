-- =====================================================================
-- iter168.24: 推しマスタ拡充 batch 2
-- =====================================================================
-- 日本市場でグッズ交換・推し活対象になりやすい実在グループ/作品を追加。
-- kind in ('group','work') の L1 は、同一 migration 内で必ず L2 を追加する。

create temporary table _megrum_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _megrum_seed_groups (genre_name, name, aliases, kind, display_order) values
  -- K-POP男性
  ('K-POP男性','P1Harmony',array['피원하모니']::text[],'group',50),
  ('K-POP男性','CRAVITY',array['크래비티']::text[],'group',51),
  ('K-POP男性','BTOB',array['비투비']::text[],'group',52),
  ('K-POP男性','SUPER JUNIOR',array['슈퍼주니어','スーパージュニア']::text[],'group',53),
  ('K-POP男性','WayV',array['威神V','웨이션브이']::text[],'group',54),
  ('K-POP男性','ONEUS',array['원어스']::text[],'group',55),
  ('K-POP男性','SF9',array['에스에프나인']::text[],'group',56),
  ('K-POP男性','CIX',array['씨아이엑스']::text[],'group',57),
  ('K-POP男性','EVNNE',array['이븐']::text[],'group',58),
  ('K-POP男性','TEMPEST',array['템페스트']::text[],'group',59),
  -- K-POP女性
  ('K-POP女性','MAMAMOO',array['마마무']::text[],'group',50),
  ('K-POP女性','Apink',array['에이핑크']::text[],'group',51),
  ('K-POP女性','Dreamcatcher',array['드림캐쳐']::text[],'group',52),
  ('K-POP女性','fromis_9',array['프로미스나인','プロミスナイン']::text[],'group',53),
  ('K-POP女性','WJSN',array['宇宙少女','우주소녀','Cosmic Girls']::text[],'group',54),
  ('K-POP女性','EVERGLOW',array['에버글로우']::text[],'group',55),
  ('K-POP女性','Weeekly',array['위클리']::text[],'group',56),
  ('K-POP女性','MEOVV',array['미야오']::text[],'group',57),
  ('K-POP女性','izna',array['이즈나']::text[],'group',58),
  ('K-POP女性','QWER',array['큐더블유이알']::text[],'group',59),
  -- 国内男性
  ('国内男性','Da-iCE',array['ダイス']::text[],'group',50),
  ('国内男性','MAZZEL',array['マーゼル']::text[],'group',51),
  ('国内男性','WATWING',array['ワトウィン']::text[],'group',52),
  ('国内男性','OCTPATH',array['オクトパス']::text[],'group',53),
  ('国内男性','DXTEEN',array['ディエックスティーン']::text[],'group',54),
  ('国内男性','LIL LEAGUE',array['LIL LEAGUE from EXILE TRIBE']::text[],'group',55),
  ('国内男性','BALLISTIK BOYZ',array['BALLISTIK BOYZ from EXILE TRIBE']::text[],'group',56),
  ('国内男性','PSYCHIC FEVER',array['PSYCHIC FEVER from EXILE TRIBE']::text[],'group',57),
  ('国内男性','BUDDiiS',array['バディーズ']::text[],'group',58),
  -- 国内女性
  ('国内女性','IS:SUE',array['イッシュ']::text[],'group',50),
  ('国内女性','アンジュルム',array['ANGERME']::text[],'group',51),
  ('国内女性','Juice=Juice',array[]::text[],'group',52),
  ('国内女性','超ときめき♡宣伝部',array['とき宣','超とき宣']::text[],'group',53),
  ('国内女性','わーすた',array['The World Standard']::text[],'group',54),
  ('国内女性','Appare!',array[]::text[],'group',55),
  ('国内女性','タイトル未定',array[]::text[],'group',56),
  -- アニメ・マンガ
  ('アニメ・マンガ','薬屋のひとりごと',array['The Apothecary Diaries']::text[],'work',50),
  ('アニメ・マンガ','SAKAMOTO DAYS',array['サカモトデイズ']::text[],'work',51),
  ('アニメ・マンガ','WITCH WATCH',array['ウィッチウォッチ']::text[],'work',52),
  ('アニメ・マンガ','カードキャプターさくら',array['CCさくら','Cardcaptor Sakura']::text[],'work',53),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！',array['ぼざろ']::text[],'work',54),
  ('アニメ・マンガ','弱虫ペダル',array['弱ペダ']::text[],'work',55),
  ('アニメ・マンガ','夏目友人帳',array[]::text[],'work',56),
  ('アニメ・マンガ','ゴールデンカムイ',array['金カム']::text[],'work',57),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!',array['REBORN','リボーン']::text[],'work',58),
  -- ゲーム
  ('ゲーム','ブルーアーカイブ',array['Blue Archive','ブルアカ']::text[],'work',50),
  ('ゲーム','学園アイドルマスター',array['学マス']::text[],'work',51),
  ('ゲーム','刀剣乱舞ONLINE',array['刀剣乱舞-ONLINE-','とうらぶ']::text[],'work',52),
  ('ゲーム','Identity V 第五人格',array['第五人格','Identity V']::text[],'work',53),
  ('ゲーム','魔法使いの約束',array['まほやく']::text[],'work',54),
  -- キャラクターIP
  ('キャラクターIP','たまごっち',array['Tamagotchi']::text[],'work',30),
  ('キャラクターIP','シルバニアファミリー',array['Sylvanian Families']::text[],'work',31),
  ('キャラクターIP','ドラえもん',array['Doraemon']::text[],'work',32),
  ('キャラクターIP','クレヨンしんちゃん',array['Crayon Shin-chan']::text[],'work',33),
  ('キャラクターIP','ムーミン',array['Moomin']::text[],'work',34),
  ('キャラクターIP','リカちゃん',array['Licca-chan']::text[],'work',35),
  -- VTuber・配信者 / お笑い
  ('VTuber・配信者','ホロスターズ',array['HOLOSTARS']::text[],'group',30),
  ('VTuber・配信者','あおぎり高校',array[]::text[],'group',31),
  ('お笑い','見取り図',array[]::text[],'group',30),
  ('お笑い','ラランド',array[]::text[],'group',31),
  ('お笑い','ロングコートダディ',array[]::text[],'group',32),
  ('お笑い','金属バット',array[]::text[],'group',33),
  ('お笑い','紅しょうが',array[]::text[],'group',34),
  ('お笑い','Aマッソ',array[]::text[],'group',35);

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
  ('K-POP男性','P1Harmony','ギホ',array['KEEHO','기호']::text[],1),
  ('K-POP男性','P1Harmony','テオ',array['THEO','테오']::text[],2),
  ('K-POP男性','P1Harmony','ジウン',array['JIUNG','지웅']::text[],3),
  ('K-POP男性','P1Harmony','インタク',array['INTAK','인탁']::text[],4),
  ('K-POP男性','P1Harmony','ソウル',array['SOUL','소울']::text[],5),
  ('K-POP男性','P1Harmony','ジョンソプ',array['JONGSEOB','종섭']::text[],6),
  ('K-POP男性','CRAVITY','セリム',array['SERIM','세림']::text[],1),
  ('K-POP男性','CRAVITY','アレン',array['ALLEN','앨런']::text[],2),
  ('K-POP男性','CRAVITY','ジョンモ',array['JUNGMO','정모']::text[],3),
  ('K-POP男性','CRAVITY','ミニ',array['MINHEE','민희']::text[],4),
  ('K-POP男性','CRAVITY','ヒョンジュン',array['HYEONGJUN','형준']::text[],5),
  ('K-POP男性','BTOB','ウングァン',array['EUNKWANG','은광']::text[],1),
  ('K-POP男性','BTOB','ミンヒョク',array['MINHYUK','민혁']::text[],2),
  ('K-POP男性','BTOB','チャンソプ',array['CHANGSUB','창섭']::text[],3),
  ('K-POP男性','BTOB','ヒョンシク',array['HYUNSIK','현식']::text[],4),
  ('K-POP男性','BTOB','プニエル',array['PENIEL','프니엘']::text[],5),
  ('K-POP男性','BTOB','ソンジェ',array['SUNGJAE','성재']::text[],6),
  ('K-POP男性','SUPER JUNIOR','イトゥク',array['LEETEUK','이특']::text[],1),
  ('K-POP男性','SUPER JUNIOR','ヒチョル',array['HEECHUL','희철']::text[],2),
  ('K-POP男性','SUPER JUNIOR','イェソン',array['YESUNG','예성']::text[],3),
  ('K-POP男性','SUPER JUNIOR','シンドン',array['SHINDONG','신동']::text[],4),
  ('K-POP男性','SUPER JUNIOR','ウニョク',array['EUNHYUK','은혁']::text[],5),
  ('K-POP男性','SUPER JUNIOR','ドンヘ',array['DONGHAE','동해']::text[],6),
  ('K-POP男性','SUPER JUNIOR','シウォン',array['SIWON','시원']::text[],7),
  ('K-POP男性','WayV','クン',array['KUN','钱锟']::text[],1),
  ('K-POP男性','WayV','テン',array['TEN','李永钦']::text[],2),
  ('K-POP男性','WayV','ウィンウィン',array['WINWIN','董思成']::text[],3),
  ('K-POP男性','WayV','シャオジュン',array['XIAOJUN','肖俊']::text[],4),
  ('K-POP男性','WayV','ヘンドリー',array['HENDERY','黄冠亨']::text[],5),
  ('K-POP男性','WayV','ヤンヤン',array['YANGYANG','刘扬扬']::text[],6),
  ('K-POP男性','ONEUS','ソホ',array['SEOHO','서호']::text[],1),
  ('K-POP男性','ONEUS','イド',array['LEEDO','이도']::text[],2),
  ('K-POP男性','ONEUS','ゴニ',array['KEONHEE','건희']::text[],3),
  ('K-POP男性','ONEUS','ファヌン',array['HWANWOONG','환웅']::text[],4),
  ('K-POP男性','ONEUS','シオン',array['XION','시온']::text[],5),
  ('K-POP男性','SF9','ヨンビン',array['YOUNGBIN','영빈']::text[],1),
  ('K-POP男性','SF9','インソン',array['INSEONG','인성']::text[],2),
  ('K-POP男性','SF9','ジェユン',array['JAEYOON','재윤']::text[],3),
  ('K-POP男性','SF9','ダウォン',array['DAWON','다원']::text[],4),
  ('K-POP男性','SF9','ロウン',array['ROWOON','로운']::text[],5),
  ('K-POP男性','SF9','チャニ',array['CHANI','찬희']::text[],6),
  ('K-POP男性','CIX','BX',array['ビョンゴン','BX']::text[],1),
  ('K-POP男性','CIX','スンフン',array['SEUNGHUN','승훈']::text[],2),
  ('K-POP男性','CIX','ベ・ジニョン',array['BAE JINYOUNG','배진영']::text[],3),
  ('K-POP男性','CIX','ヨンヒ',array['YONGHEE','용희']::text[],4),
  ('K-POP男性','CIX','ヒョンソク',array['HYUNSUK','현석']::text[],5),
  ('K-POP男性','EVNNE','ケイタ',array['KEITA','寺園佳汰']::text[],1),
  ('K-POP男性','EVNNE','パク・ハンビン',array['PARK HANBIN','박한빈']::text[],2),
  ('K-POP男性','EVNNE','イ・ジョンヒョン',array['LEE JEONGHYEON','이정현']::text[],3),
  ('K-POP男性','EVNNE','ユ・スンオン',array['YOO SEUNGEON','유승언']::text[],4),
  ('K-POP男性','EVNNE','チ・ユンソ',array['JI YUNSEO','지윤서']::text[],5),
  ('K-POP男性','TEMPEST','ハンビン',array['HANBIN','한빈']::text[],1),
  ('K-POP男性','TEMPEST','ヒョンソプ',array['HYEONGSEOP','형섭']::text[],2),
  ('K-POP男性','TEMPEST','ヒョク',array['HYUK','혁']::text[],3),
  ('K-POP男性','TEMPEST','ウンチャン',array['EUNCHAN','은찬']::text[],4),
  ('K-POP男性','TEMPEST','ファラン',array['HWARANG','화랑']::text[],5),

  -- K-POP女性
  ('K-POP女性','MAMAMOO','ソラ',array['Solar','솔라']::text[],1),
  ('K-POP女性','MAMAMOO','ムンビョル',array['Moonbyul','문별']::text[],2),
  ('K-POP女性','MAMAMOO','フィイン',array['Wheein','휘인']::text[],3),
  ('K-POP女性','MAMAMOO','ファサ',array['Hwasa','화사']::text[],4),
  ('K-POP女性','Apink','チョロン',array['Chorong','초롱']::text[],1),
  ('K-POP女性','Apink','ボミ',array['Bomi','보미']::text[],2),
  ('K-POP女性','Apink','ウンジ',array['Eunji','은지']::text[],3),
  ('K-POP女性','Apink','ナムジュ',array['Namjoo','남주']::text[],4),
  ('K-POP女性','Apink','ハヨン',array['Hayoung','하영']::text[],5),
  ('K-POP女性','Dreamcatcher','ジユ',array['JIU','지유']::text[],1),
  ('K-POP女性','Dreamcatcher','スア',array['SUA','수아']::text[],2),
  ('K-POP女性','Dreamcatcher','シヨン',array['SIYEON','시연']::text[],3),
  ('K-POP女性','Dreamcatcher','ハンドン',array['HANDONG','한동']::text[],4),
  ('K-POP女性','Dreamcatcher','ユヒョン',array['YOOHYEON','유현']::text[],5),
  ('K-POP女性','fromis_9','セロム',array['SAEROM','새롬']::text[],1),
  ('K-POP女性','fromis_9','ハヨン',array['HAYOUNG','하영']::text[],2),
  ('K-POP女性','fromis_9','ジウォン',array['JIWON','지원']::text[],3),
  ('K-POP女性','fromis_9','ジソン',array['JISUN','지선']::text[],4),
  ('K-POP女性','fromis_9','ナギョン',array['NAKYUNG','나경']::text[],5),
  ('K-POP女性','WJSN','ソラ',array['SEOLA','설아']::text[],1),
  ('K-POP女性','WJSN','ボナ',array['BONA','보나']::text[],2),
  ('K-POP女性','WJSN','エクシ',array['EXY','엑시']::text[],3),
  ('K-POP女性','WJSN','スビン',array['SOOBIN','수빈']::text[],4),
  ('K-POP女性','WJSN','ヨルム',array['YEOREUM','여름']::text[],5),
  ('K-POP女性','EVERGLOW','イユ',array['E:U','이유']::text[],1),
  ('K-POP女性','EVERGLOW','シヒョン',array['SIHYEON','시현']::text[],2),
  ('K-POP女性','EVERGLOW','ミア',array['MIA','미아']::text[],3),
  ('K-POP女性','EVERGLOW','オンダ',array['ONDA','온다']::text[],4),
  ('K-POP女性','EVERGLOW','アシャ',array['AISHA','아샤']::text[],5),
  ('K-POP女性','Weeekly','スジン',array['SOOJIN','수진']::text[],1),
  ('K-POP女性','Weeekly','マンデー',array['MONDAY','먼데이']::text[],2),
  ('K-POP女性','Weeekly','ソウン',array['SOEUN','소은']::text[],3),
  ('K-POP女性','Weeekly','ジェヒ',array['JAEHEE','재희']::text[],4),
  ('K-POP女性','Weeekly','ゾア',array['ZOA','조아']::text[],5),
  ('K-POP女性','MEOVV','スイン',array['SOOIN','수인']::text[],1),
  ('K-POP女性','MEOVV','ガウォン',array['GAWON','가원']::text[],2),
  ('K-POP女性','MEOVV','アンナ',array['ANNA']::text[],3),
  ('K-POP女性','MEOVV','ナリン',array['NARIN','나린']::text[],4),
  ('K-POP女性','MEOVV','エラ',array['ELLA']::text[],5),
  ('K-POP女性','izna','マイ',array['MAI']::text[],1),
  ('K-POP女性','izna','バン・ジミン',array['BANG JEEMIN','방지민']::text[],2),
  ('K-POP女性','izna','ユン・ジユン',array['YOON JIYOON','윤지윤']::text[],3),
  ('K-POP女性','izna','ココ',array['KOKO']::text[],4),
  ('K-POP女性','izna','リュ・サラン',array['RYU SARANG','유사랑']::text[],5),
  ('K-POP女性','QWER','チョダン',array['Chodan','쵸단']::text[],1),
  ('K-POP女性','QWER','マゼンタ',array['Magenta','마젠타']::text[],2),
  ('K-POP女性','QWER','ヒナ',array['Hina','히나']::text[],3),
  ('K-POP女性','QWER','シヨン',array['Siyeon','시연']::text[],4),

  -- 国内男性
  ('国内男性','Da-iCE','工藤大輝',array['Taiki Kudo']::text[],1),
  ('国内男性','Da-iCE','岩岡徹',array['Toru Iwaoka']::text[],2),
  ('国内男性','Da-iCE','大野雄大',array['Yudai Ohno']::text[],3),
  ('国内男性','Da-iCE','花村想太',array['Sota Hanamura']::text[],4),
  ('国内男性','Da-iCE','和田颯',array['Hayate Wada']::text[],5),
  ('国内男性','MAZZEL','KAIRYU',array[]::text[],1),
  ('国内男性','MAZZEL','NAOYA',array[]::text[],2),
  ('国内男性','MAZZEL','RAN',array[]::text[],3),
  ('国内男性','MAZZEL','SEITO',array[]::text[],4),
  ('国内男性','MAZZEL','RYUKI',array[]::text[],5),
  ('国内男性','WATWING','髙橋颯',array['Hayate Takahashi','高橋颯']::text[],1),
  ('国内男性','WATWING','鈴木曉',array['Asahi Suzuki']::text[],2),
  ('国内男性','WATWING','桑山隆太',array['Ryuta Kuwayama']::text[],3),
  ('国内男性','WATWING','福澤希空',array['Noa Fukuzawa']::text[],4),
  ('国内男性','WATWING','八村倫太郎',array['Rintaro Hachimura']::text[],5),
  ('国内男性','OCTPATH','太田駿静',array['Shunsei Ota']::text[],1),
  ('国内男性','OCTPATH','海帆',array['Kaiho']::text[],2),
  ('国内男性','OCTPATH','栗田航兵',array['Kohei Kurita']::text[],3),
  ('国内男性','OCTPATH','古瀬直輝',array['Naoki Kose']::text[],4),
  ('国内男性','OCTPATH','四谷真佑',array['Shinsuke Yotsuya']::text[],5),
  ('国内男性','DXTEEN','大久保波留',array['Nalu Okubo']::text[],1),
  ('国内男性','DXTEEN','田中笑太郎',array['Shotaro Tanaka']::text[],2),
  ('国内男性','DXTEEN','谷口太一',array['Taichi Taniguchi']::text[],3),
  ('国内男性','DXTEEN','寺尾香信',array['Koshin Terao']::text[],4),
  ('国内男性','DXTEEN','平本健',array['Ken Hiramoto']::text[],5),
  ('国内男性','LIL LEAGUE','岩城星那',array['Sena Iwaki']::text[],1),
  ('国内男性','LIL LEAGUE','中村竜大',array['Tatsuhiro Nakamura']::text[],2),
  ('国内男性','LIL LEAGUE','山田晃大',array['Kota Yamada']::text[],3),
  ('国内男性','LIL LEAGUE','岡尾真虎',array['Matra Okao']::text[],4),
  ('国内男性','LIL LEAGUE','百田隼麻',array['Haima Momoda']::text[],5),
  ('国内男性','BALLISTIK BOYZ','日髙竜太',array['Ryuta Hidaka']::text[],1),
  ('国内男性','BALLISTIK BOYZ','加納嘉将',array['Yoshiyuki Kano']::text[],2),
  ('国内男性','BALLISTIK BOYZ','海沼流星',array['Ryusei Kainuma']::text[],3),
  ('国内男性','BALLISTIK BOYZ','深堀未来',array['Miku Fukahori']::text[],4),
  ('国内男性','BALLISTIK BOYZ','奥田力也',array['Rikiya Okuda']::text[],5),
  ('国内男性','PSYCHIC FEVER','剣',array['Tsurugi']::text[],1),
  ('国内男性','PSYCHIC FEVER','中西椋雅',array['Ryoga Nakanishi']::text[],2),
  ('国内男性','PSYCHIC FEVER','渡邉廉',array['Ren Watanabe']::text[],3),
  ('国内男性','PSYCHIC FEVER','JIMMY',array[]::text[],4),
  ('国内男性','PSYCHIC FEVER','小波津志',array['Kokoro Kohatsu']::text[],5),
  ('国内男性','BUDDiiS','FUMINORI',array[]::text[],1),
  ('国内男性','BUDDiiS','KEVIN',array[]::text[],2),
  ('国内男性','BUDDiiS','MORRIE',array[]::text[],3),
  ('国内男性','BUDDiiS','SEIYA',array[]::text[],4),
  ('国内男性','BUDDiiS','SHOOT',array[]::text[],5),

  -- 国内女性
  ('国内女性','IS:SUE','NANO',array['ナノ']::text[],1),
  ('国内女性','IS:SUE','RINO',array['リノ']::text[],2),
  ('国内女性','IS:SUE','YUUKI',array['ユウキ']::text[],3),
  ('国内女性','IS:SUE','RIN',array['リン']::text[],4),
  ('国内女性','アンジュルム','上國料萌衣',array['Moe Kamikokuryo']::text[],1),
  ('国内女性','アンジュルム','川村文乃',array['Ayano Kawamura']::text[],2),
  ('国内女性','アンジュルム','佐々木莉佳子',array['Rikako Sasaki']::text[],3),
  ('国内女性','アンジュルム','伊勢鈴蘭',array['Layla Ise']::text[],4),
  ('国内女性','アンジュルム','橋迫鈴',array['Rin Hashisako']::text[],5),
  ('国内女性','Juice=Juice','段原瑠々',array['Ruru Dambara']::text[],1),
  ('国内女性','Juice=Juice','井上玲音',array['Rei Inoue']::text[],2),
  ('国内女性','Juice=Juice','工藤由愛',array['Yume Kudo']::text[],3),
  ('国内女性','Juice=Juice','松永里愛',array['Riai Matsunaga']::text[],4),
  ('国内女性','Juice=Juice','有澤一華',array['Ichika Arisawa']::text[],5),
  ('国内女性','超ときめき♡宣伝部','辻野かなみ',array['Kanami Tsujino']::text[],1),
  ('国内女性','超ときめき♡宣伝部','杏ジュリア',array['Julia An']::text[],2),
  ('国内女性','超ときめき♡宣伝部','坂井仁香',array['Hitoka Sakai']::text[],3),
  ('国内女性','超ときめき♡宣伝部','小泉遥香',array['Haruka Koizumi']::text[],4),
  ('国内女性','超ときめき♡宣伝部','菅田愛貴',array['Aki Suda']::text[],5),
  ('国内女性','わーすた','廣川奈々聖',array['Nanase Hirokawa']::text[],1),
  ('国内女性','わーすた','三品瑠香',array['Ruka Mishina']::text[],2),
  ('国内女性','わーすた','松田美里',array['Miri Matsuda']::text[],3),
  ('国内女性','わーすた','小玉梨々華',array['Ririka Kodama']::text[],4),
  ('国内女性','Appare!','朝比奈れい',array[]::text[],1),
  ('国内女性','Appare!','橋本あみ',array[]::text[],2),
  ('国内女性','Appare!','藍井すず',array[]::text[],3),
  ('国内女性','Appare!','七瀬れあ',array[]::text[],4),
  ('国内女性','タイトル未定','冨樫優花',array[]::text[],1),
  ('国内女性','タイトル未定','谷乃愛',array[]::text[],2),
  ('国内女性','タイトル未定','川本空',array[]::text[],3),
  ('国内女性','タイトル未定','阿部葉菜',array[]::text[],4),

  -- 作品・キャラクター
  ('アニメ・マンガ','薬屋のひとりごと','猫猫',array['マオマオ']::text[],1),
  ('アニメ・マンガ','薬屋のひとりごと','壬氏',array[]::text[],2),
  ('アニメ・マンガ','薬屋のひとりごと','高順',array[]::text[],3),
  ('アニメ・マンガ','薬屋のひとりごと','玉葉妃',array[]::text[],4),
  ('アニメ・マンガ','SAKAMOTO DAYS','坂本太郎',array[]::text[],1),
  ('アニメ・マンガ','SAKAMOTO DAYS','朝倉シン',array[]::text[],2),
  ('アニメ・マンガ','SAKAMOTO DAYS','陸少糖',array['ルーシャオタン']::text[],3),
  ('アニメ・マンガ','SAKAMOTO DAYS','南雲',array[]::text[],4),
  ('アニメ・マンガ','WITCH WATCH','若月ニコ',array[]::text[],1),
  ('アニメ・マンガ','WITCH WATCH','乙木守仁',array[]::text[],2),
  ('アニメ・マンガ','WITCH WATCH','風祭監志',array[]::text[],3),
  ('アニメ・マンガ','WITCH WATCH','真神圭護',array[]::text[],4),
  ('アニメ・マンガ','カードキャプターさくら','木之本桜',array[]::text[],1),
  ('アニメ・マンガ','カードキャプターさくら','大道寺知世',array[]::text[],2),
  ('アニメ・マンガ','カードキャプターさくら','李小狼',array[]::text[],3),
  ('アニメ・マンガ','カードキャプターさくら','ケロちゃん',array['ケルベロス']::text[],4),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','後藤ひとり',array[]::text[],1),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','伊地知虹夏',array[]::text[],2),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','山田リョウ',array[]::text[],3),
  ('アニメ・マンガ','ぼっち・ざ・ろっく！','喜多郁代',array[]::text[],4),
  ('アニメ・マンガ','弱虫ペダル','小野田坂道',array[]::text[],1),
  ('アニメ・マンガ','弱虫ペダル','今泉俊輔',array[]::text[],2),
  ('アニメ・マンガ','弱虫ペダル','鳴子章吉',array[]::text[],3),
  ('アニメ・マンガ','弱虫ペダル','巻島裕介',array[]::text[],4),
  ('アニメ・マンガ','夏目友人帳','夏目貴志',array[]::text[],1),
  ('アニメ・マンガ','夏目友人帳','ニャンコ先生',array['斑']::text[],2),
  ('アニメ・マンガ','ゴールデンカムイ','杉元佐一',array[]::text[],1),
  ('アニメ・マンガ','ゴールデンカムイ','アシリパ',array[]::text[],2),
  ('アニメ・マンガ','ゴールデンカムイ','白石由竹',array[]::text[],3),
  ('アニメ・マンガ','ゴールデンカムイ','尾形百之助',array[]::text[],4),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','沢田綱吉',array[]::text[],1),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','リボーン',array[]::text[],2),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','獄寺隼人',array[]::text[],3),
  ('アニメ・マンガ','家庭教師ヒットマンREBORN!','雲雀恭弥',array[]::text[],4),
  ('ゲーム','ブルーアーカイブ','砂狼シロコ',array[]::text[],1),
  ('ゲーム','ブルーアーカイブ','小鳥遊ホシノ',array[]::text[],2),
  ('ゲーム','ブルーアーカイブ','陸八魔アル',array[]::text[],3),
  ('ゲーム','ブルーアーカイブ','早瀬ユウカ',array[]::text[],4),
  ('ゲーム','学園アイドルマスター','花海咲季',array[]::text[],1),
  ('ゲーム','学園アイドルマスター','月村手毬',array[]::text[],2),
  ('ゲーム','学園アイドルマスター','藤田ことね',array[]::text[],3),
  ('ゲーム','学園アイドルマスター','葛城リーリヤ',array[]::text[],4),
  ('ゲーム','刀剣乱舞ONLINE','三日月宗近',array[]::text[],1),
  ('ゲーム','刀剣乱舞ONLINE','加州清光',array[]::text[],2),
  ('ゲーム','刀剣乱舞ONLINE','山姥切国広',array[]::text[],3),
  ('ゲーム','刀剣乱舞ONLINE','へし切長谷部',array[]::text[],4),
  ('ゲーム','Identity V 第五人格','庭師',array['エマ・ウッズ']::text[],1),
  ('ゲーム','Identity V 第五人格','占い師',array['イライ・クラーク']::text[],2),
  ('ゲーム','Identity V 第五人格','探鉱者',array['ノートン・キャンベル']::text[],3),
  ('ゲーム','Identity V 第五人格','写真家',array['ジョゼフ']::text[],4),
  ('ゲーム','魔法使いの約束','オズ',array[]::text[],1),
  ('ゲーム','魔法使いの約束','アーサー',array[]::text[],2),
  ('ゲーム','魔法使いの約束','カイン',array[]::text[],3),
  ('ゲーム','魔法使いの約束','ミスラ',array[]::text[],4),
  ('キャラクターIP','たまごっち','まめっち',array[]::text[],1),
  ('キャラクターIP','たまごっち','くちぱっち',array[]::text[],2),
  ('キャラクターIP','たまごっち','めめっち',array[]::text[],3),
  ('キャラクターIP','シルバニアファミリー','ショコラウサギの女の子',array['フレア']::text[],1),
  ('キャラクターIP','シルバニアファミリー','くるみリスの男の子',array[]::text[],2),
  ('キャラクターIP','ドラえもん','ドラえもん',array[]::text[],1),
  ('キャラクターIP','ドラえもん','野比のび太',array[]::text[],2),
  ('キャラクターIP','ドラえもん','しずかちゃん',array['源静香']::text[],3),
  ('キャラクターIP','クレヨンしんちゃん','野原しんのすけ',array[]::text[],1),
  ('キャラクターIP','クレヨンしんちゃん','シロ',array[]::text[],2),
  ('キャラクターIP','ムーミン','ムーミントロール',array['ムーミン']::text[],1),
  ('キャラクターIP','ムーミン','スナフキン',array[]::text[],2),
  ('キャラクターIP','リカちゃん','リカちゃん',array['香山リカ']::text[],1),
  ('キャラクターIP','リカちゃん','はるとくん',array[]::text[],2),

  -- VTuber・配信者 / お笑い
  ('VTuber・配信者','ホロスターズ','花咲みやび',array[]::text[],1),
  ('VTuber・配信者','ホロスターズ','奏手イヅル',array[]::text[],2),
  ('VTuber・配信者','ホロスターズ','アルランディス',array[]::text[],3),
  ('VTuber・配信者','ホロスターズ','律可',array[]::text[],4),
  ('VTuber・配信者','あおぎり高校','音霊魂子',array[]::text[],1),
  ('VTuber・配信者','あおぎり高校','石狩あかり',array[]::text[],2),
  ('VTuber・配信者','あおぎり高校','大代真白',array[]::text[],3),
  ('VTuber・配信者','あおぎり高校','栗駒こまる',array[]::text[],4),
  ('お笑い','見取り図','盛山晋太郎',array[]::text[],1),
  ('お笑い','見取り図','リリー',array[]::text[],2),
  ('お笑い','ラランド','サーヤ',array[]::text[],1),
  ('お笑い','ラランド','ニシダ',array[]::text[],2),
  ('お笑い','ロングコートダディ','堂前透',array[]::text[],1),
  ('お笑い','ロングコートダディ','兎',array[]::text[],2),
  ('お笑い','金属バット','小林圭輔',array[]::text[],1),
  ('お笑い','金属バット','友保隼平',array[]::text[],2),
  ('お笑い','紅しょうが','熊元プロレス',array[]::text[],1),
  ('お笑い','紅しょうが','稲田美紀',array[]::text[],2),
  ('お笑い','Aマッソ','加納',array[]::text[],1),
  ('お笑い','Aマッソ','村上',array[]::text[],2);

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

-- 別ジャンル/別文脈にある同一キャラを明示的に束ねる。
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
  ('2.5次元・舞台','刀剣乱舞','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('2.5次元・舞台','舞台「刀剣乱舞」','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('ゲーム','刀剣乱舞ONLINE','三日月宗近','character:touken-mikazuki','三日月宗近','character',array[]::text[],1),
  ('2.5次元・舞台','刀剣乱舞','山姥切国広','character:touken-yamanbagiri-kunihiro','山姥切国広','character',array[]::text[],2),
  ('2.5次元・舞台','舞台「刀剣乱舞」','山姥切国広','character:touken-yamanbagiri-kunihiro','山姥切国広','character',array[]::text[],2),
  ('ゲーム','刀剣乱舞ONLINE','山姥切国広','character:touken-yamanbagiri-kunihiro','山姥切国広','character',array[]::text[],2),
  ('2.5次元・舞台','刀剣乱舞','へし切長谷部','character:touken-heshikiri-hasebe','へし切長谷部','character',array[]::text[],3),
  ('2.5次元・舞台','舞台「刀剣乱舞」','へし切長谷部','character:touken-heshikiri-hasebe','へし切長谷部','character',array[]::text[],3),
  ('ゲーム','刀剣乱舞ONLINE','へし切長谷部','character:touken-heshikiri-hasebe','へし切長谷部','character',array[]::text[],3),
  ('2.5次元・舞台','刀剣乱舞','加州清光','character:touken-kashu-kiyomitsu','加州清光','character',array[]::text[],4),
  ('2.5次元・舞台','ミュージカル「刀剣乱舞」','加州清光','character:touken-kashu-kiyomitsu','加州清光','character',array[]::text[],4),
  ('ゲーム','刀剣乱舞ONLINE','加州清光','character:touken-kashu-kiyomitsu','加州清光','character',array[]::text[],4);

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
