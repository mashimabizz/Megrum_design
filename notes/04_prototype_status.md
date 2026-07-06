# プロトタイプ実装ステータス

（依頼者からの情報に基づき、2026-04-27時点）

## 既存実装：写真撮影・登録フロー

### ファイル位置

- `app/(main)/post/new-v2/page.tsx` ─ Step 0（写真ロジック、1〜350行目あたり）
- `app/(main)/post/new-v2/photo/page.tsx` ─ 独立した試作版（紐付けUI実験）
- `app/api/upload/route.ts` ─ Supabase Storageへの送信
- `app/lib/hooks/useSAM.ts` ─ MobileSAM hook（**MVPでは不要、廃止可**）

### 実装済みフロー

1. **撮影／選択**：「カメラ」（背面1枚ずつ）／「アルバム」（複数選択）
2. **写真表示**：選択写真を画面いっぱいに、下部にサムネイルギャラリー
3. **手動切り抜き**：ドラッグで矩形描画 → 矩形範囲を1グッズ画像化
4. **切り抜き結果**：400×400 正方形 JPEG（品質85%）、白背景
5. **次ステップ**：切り抜き各グッズに **キャラ名・グッズ種別** を割り当て、確認 → サーバーアップロード

### 内部処理

- 写真ファイル → `FileReader` で base64 → React state
- 切り抜き → Canvas API `drawImage()` → data URL（base64）
- 投稿時に base64 を Blob 化 → `/api/upload` → Supabase Storage URL を `user_haves.image_url` に保存
- 座標変換：`getImageLayout` で letterbox 計算

### MVP方針

| 項目 | 状況 | MVP方針 |
|------|------|---------|
| 手動切り抜き | 矩形ドラッグで実装済 | **これで十分**（MobileSAM不要） |
| モバイル操作 | タッチドラッグ対応済み | OK |
| 背景処理 | なし | **不要** |
| 画像圧縮 | 400×400／品質85% | OK |
| 複数選択 | アルバムから可 | OK |
| HEIC対応 | 許可済み | OK |
| 裏面対応 | 1グッズ＝1画像（複数枚はuser_have_imagesに予備） | **不要**（user_have_imagesは後フェーズ余地） |

---

## 既存スキーマ（依頼者から共有 ─ 詳細は 05_data_model.md）

### `user_haves`（=「棚」）─ 既存

ユーザーが「これ手放してもいい」とリストに登録したグッズ1個 = 1行。

| カラム | 型 | 中身 | 例 |
|--------|----|------|----|
| `id` | uuid | グッズの内部ID | (自動生成) |
| `user_id` | uuid | 持ち主のユーザーID | (users.id 参照) |
| `genre_tag_id` | uuid | ジャンルタグへの紐付け | (null許可) |
| `genre_name` | text 必須 | 作品/シリーズ名 | "呪術廻戦" |
| `character_name` | text 必須 | キャラ/人名 | "五条悟" |
| `goods_type` | text 必須 | グッズ種別 | "缶バッジ" |
| `image_url` | text | 切り抜き画像URL | "https://...supabase.co/.../xxx.jpg" |
| `note` | text | フリーテキストメモ | "未開封品です" |
| `exchange_method` | text[] | 交換方法の許容 | ["手渡し","郵送"] |
| `hand_prefecture` | text | 手渡し希望エリア | "東京都" |
| `status` | text | active / reserved / traded / withdrawn | active |
| `created_at` | timestamptz | 登録日時 | (自動) |
| `updated_at` | timestamptz | 更新日時 | (自動) |

### `user_have_images`（複数画像対応の予備）

| カラム | 説明 |
|--------|------|
| `id` | 画像ID |
| `have_id` | どの user_have に紐付くか |
| `image_url` | 画像URL |
| `sort_order` | 表示順 |

現状の new-v2 は `image_url`（user_haves側）を1枚だけ使用。複数枚対応は将来用の予備領域。

### `user_wants`（=「鏡」）

構造はほぼ user_haves と同じ。ただし：
- `character_name`、`goods_type` が **NULL許可**（"このジャンルなら何でも"を表現）
- `flexibility`：exact / character_any / series_any（曖昧度）

### マッチング判定で使われるカラム（既存ロジック）

- `genre_name` ← 完全一致が必要
- `character_name` ← 相手の want.character_name と照合
- `goods_type` ← 相手の want.goods_type と照合（want側でNULLなら無視）
- `exchange_method` ← 相手と重複（&&）必要

---

## ペルソナ視点での改善優先度（更新）

| # | 改善案 | MVP方針 |
|---|--------|---------|
| 1 | **数量入力（×N）** | **採用** ─ ランダム封入グッズ前提では必須 |
| 2 | **キャラの運営マスタ管理**（KPOPからスタート） | **採用** ─ 検索・マッチ精度の要 |
| 3 | **グッズ種別の最低限自動推定** | **任意（あれば嬉しい）** |
| 4 | MobileSAM 統合 | **不要** |
| 5 | 裏面対応 | **不要** |
| 6 | 背景白塗り | **不要** |
| 7 | キャラの自動推定 | **不要**（運営マスタで対応） |
| 8 | **証跡撮影機能**（普通の写真アップ＋両者承認） | **採用**（特殊処理は不要） |

---

## 既存スキーマで「良い設計」と判断した点

- **status の細やか管理**（active / reserved / traded / withdrawn）：MVP取引フローに必要十分
- **`user_have_images` の予備テーブル**：将来の拡大写真・状態確認用に拡張余地あり
- **`user_wants.flexibility`**：希望条件の曖昧さを表現できる

## 既存スキーマで MVP までに変更が必要な点

詳細は [05_data_model.md](05_data_model.md) を参照。

| 変更ポイント | 概要 |
|------------|------|
| マスタ参照の強化 | `genre_tag_id` 必須化、`character_id` 化、運営マスタの新設 |
| 場所粒度 | `hand_prefecture` をユーザープロフへ格下げ／`availability_windows` 新設 |
| 数量 | 1行＝1個維持／UIでN行INSERT |
| 郵送値の表示 | MVPでは非表示（データは保持） |
| 取引チャット／評価／断った記録 | 新規テーブル群 |
