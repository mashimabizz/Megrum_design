-- =====================================================================
-- iter1226.293: グッズ種別マスタを66種に更新＋is_active 追加
-- =====================================================================
-- オーナー指定の新リスト（この順で display_order 1..66）。
-- 旧種別のうち新リストに無いもの（生写真・缶バッジ・アクスタ・スマホリング・
-- ぬいぐるみ・シール・定価）は行を残したまま is_active=false にする
-- （既存 goods_inventory / wish の名前解決を壊さないため）。
-- 「定価」行は listing_wish_options.is_cash に置き換わって以降未参照のため非表示化。

alter table public.goods_types_master
  add column if not exists is_active boolean not null default true;

with new_types(display_order, name, category) as (
  values
    (1,  'トレカ', 'card'),
    (2,  'ピンズ・ピンバッジ・缶バッジ', 'pin'),
    (3,  'アクリルスタンド', 'figure'),
    (4,  'キーホルダー', 'other'),
    (5,  'アクリルキーホルダー', 'other'),
    (6,  'ストラップ', 'other'),
    (7,  'ステッカー・シール', 'other'),
    (8,  'ぬいぐるみ・マスコット', 'figure'),
    (9,  '写真・チェキ', 'photo'),
    (10, 'クリアファイル', 'other'),
    (11, 'アクセサリー・ヘアアクセサリー', 'other'),
    (12, 'クリップ', 'other'),
    (13, 'フォンタブ', 'other'),
    (14, 'ポスター', 'photo'),
    (15, 'タペストリー', 'other'),
    (16, 'セル画', 'other'),
    (17, 'タオル', 'other'),
    (18, 'クッション・抱きまくら', 'other'),
    (19, 'Tシャツ・アパレル', 'other'),
    (20, 'マグカップ・食器', 'other'),
    (21, 'カチューシャ・被り物', 'other'),
    (22, 'パワーアップバンド', 'other'),
    (23, 'うちわ', 'other'),
    (24, 'バッグ・ポーチ', 'other'),
    (25, 'ペンライト', 'other'),
    (26, 'メモ用紙・文房具', 'other'),
    (27, 'ラバーバンド', 'other'),
    (28, '切り抜き', 'photo'),
    (29, 'カレンダー', 'other'),
    (30, 'パンフレット', 'other'),
    (31, 'フォトハンガー', 'other'),
    (32, '会報', 'other'),
    (33, '写真', 'photo'),
    (34, 'ペンライト・リングライト・バングルライト', 'other'),
    (35, 'ポストカード', 'photo'),
    (36, 'チケット', 'other'),
    (37, '株主優待券・割引券', 'other'),
    (38, '雑誌', 'other'),
    (39, '本・雑誌・漫画', 'other'),
    (40, 'ハンドメイド・手芸', 'other'),
    (41, 'ファッション', 'other'),
    (42, 'コスメ・美容', 'other'),
    (43, 'CD・DVD・ブルーレイ', 'other'),
    (44, '家具・インテリア', 'other'),
    (45, 'ゲーム・玩具', 'other'),
    (46, 'フィッシング', 'other'),
    (47, 'フラワー・ガーデニング', 'other'),
    (48, 'アート用品', 'other'),
    (49, 'アマチュア無線', 'other'),
    (50, 'コスチューム・コスプレ', 'other'),
    (51, 'ラジコン・ドローン', 'other'),
    (52, '楽器・機材', 'other'),
    (53, '美術品・アンティーク・コレクション', 'other'),
    (54, '模型・プラモデル', 'figure'),
    (55, 'スマホ・タブレット・パソコン', 'other'),
    (56, 'ベビー・キッズ', 'other'),
    (57, 'テレビ・オーディオ・カメラ', 'other'),
    (58, 'アウトドア', 'other'),
    (59, '旅行用品', 'other'),
    (60, 'ダイエット・健康', 'other'),
    (61, '食品・飲料・酒', 'other'),
    (62, 'キッチン・日用品・その他', 'other'),
    (63, 'ペット用品', 'other'),
    (64, 'DIY・工具', 'other'),
    (65, '車・バイク・自転車', 'other'),
    (66, 'その他', 'other')
)
insert into public.goods_types_master (name, category, display_order, is_active)
select name, category, display_order, true
from new_types
on conflict (name) do update
  set category = excluded.category,
      display_order = excluded.display_order,
      is_active = true;

-- 新リストに無い旧種別を非表示化（行は残す）。
-- display_order を 900+ に退避し、is_active を知らない旧クライアント
-- （order=display_order.asc & limit）でも新リストが先頭に来るようにする。
update public.goods_types_master
set is_active = false,
    display_order = 900 + display_order
where name in ('生写真', '缶バッジ', 'アクスタ', 'スマホリング', 'ぬいぐるみ', 'シール', '定価')
  and is_active;

-- =====================================================================
-- 完了
-- =====================================================================
