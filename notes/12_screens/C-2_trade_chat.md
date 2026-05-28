# C-2: 取引チャット（合意後・当日のライブ運用）

> 合意後の当日合流に向けた連絡ハブ。場所・時間は合意前にfix済なので、当日のライブ運用に集中。

最終更新: 2026-05-01（iter41）
関連JSX: `Megrum/c-flow.jsx::ChatScreen`、`CF_MiniMap`
関連HTML: `Megrum/Megrum C Flow.html`
関連 iter: 34

---

## 画面の目的

合意成立（`Proposal.status = agreed` → `Deal` 生成）後の取引チャット。
役割は **当日のライブ連絡＋合流＋証跡撮影への入口**：
- 取引内容＋待ち合わせ情報の常時参照（pinned card）
- 服装写真シェア（合流支援）
- 現在地共有（移動状況の連絡）
- 到着ステータス表示（相手が来るかの不安解消）
- QR本人確認（合流時の本人確認）
- 証跡撮影への入口（C-3 へ）

iter34 で「場所・時間の調整UI（提案カード・時刻チップ）」を削除し、上記6機能に役割を絞り込み。

## 画面ID

`C2-chat`（`notes/11_screen_inventory.md` 参照）

---

## 入力データ

### Props

```ts
{
  tweaks: BrandColors,
}
```

### React state

```ts
// 確定した取引情報（API から取得想定、現状は mock）
const meetup = {
  date: '5/3 (土)',
  time: '14:00〜18:00',
  place: 'TWICE 名古屋ドーム公演',
  area: 'ナゴヤドーム前矢田駅 周辺',
};

// 到着ステータス
const myArrived = false;
const partnerArrived = true;

// 服装写真の共有状況
const myOutfitShared = false;
const partnerOutfitShared = true;
```

実装時は API から `deal` + `messages` + `deal_arrivals` + `deal_outfit_photos` を取得して state に展開。

### 前画面からの引き継ぎ

- `deal_id`（C-1.5 success画面 or 取引タブ "進行中" から）

### データモデル参照

- `deals WHERE id = X`（status, participants, evidence_image_url, sender/receiver_approved 等）
- `proposals WHERE id = deal.proposal_id`（取引内容、待ち合わせ）
- `messages WHERE proposal_id = X ORDER BY created_at`（チャット履歴）
- `deal_arrivals WHERE deal_id = X`（到着ステータス、最大2レコード）
- `deal_outfit_photos WHERE deal_id = X`（服装写真、最新を user_id ごとに）
- `users WHERE id IN deal.participants`（相手プロフ）

---

## 表示要素

### ヘッダー（固定）

- 戻るボタン（`<`）
- 相手アバター（32px）
- @handle ＋ ★rating ＋ 取引N回 ＋ **到着ステータス**：
  - `arrived`: 緑ドット ＋ `会場到着済` ＋ 距離
  - `on_the_way`: 橙ドット ＋ `移動中` ＋ 距離
- **QR ボタン**（lavender bg ＋ QRアイコン）→ QR本人確認モーダル

### Pin card：取引内容＋確定済の待ち合わせ（上部固定）

`borderBottom` でスクロールしても見えるエリア。

```
┌─────────────────────────────────┐
│ 📋 取引内容＋待ち合わせ（確定済）  [合意済] │
│ ───────────────────────         │
│ 受け取る           出す          │
│ スア WT01 トレカ ↔ ヒナ生写真 ×1 │
│       ×3           スア STUDIO ×1│
│ ─── (dashed) ───                 │
│ [mini map      📍 待ち合わせ      │
│   92×60]        5/3 (土)         │
│                  14:00〜18:00     │
│                  TWICE 名古屋ドーム│
│                  📍 ナゴヤドーム前 │
└─────────────────────────────────┘
```

### 服装写真をシェア CTA（強調・条件付き表示）

`!myOutfitShared` の時のみ表示。紫→水色グラデの目立つカード。

```
[gradient bg, 装飾サークル]
👕  服装写真をシェア
    合流時にお互いを見つけやすく

[あなた: 未シェア] [@partner: ✓ 共有済]

[白bg大ボタン] 📷 服装写真を撮影してシェア
```

自分が共有済になると消える。

### メッセージ領域（スクロール）

時系列に並ぶ：

#### A. 通常テキストメッセージ（`message_type='text'`）

- 自分：右寄せ、lavender bg、白文字
- 相手：左寄せ、白bg、黒文字、border

#### B. 服装写真メッセージ（`message_type='outfit_photo'` 風）

- image bubble（180×200）：シルエット風 SVG ＋ 「👕 服装写真」ラベル
- サブテキスト（説明）：「紫ロンT＋トートバッグ」等

#### C. 現在地共有メッセージ（`message_type='location_share'`）

- 自分から送信：`borderRadius: '14px 14px 4px 14px'`、lavender border
- mini map（120px）：自分位置・相手位置・待ち合わせ地点の3点表示
- ラベル：「📍 現在地を共有 / ナゴヤドーム前矢田駅 1番出口付近 / 13:42 時点」

#### D. システムメッセージ（`message_type='system'`）

緑 pill：「@xxx が会場に到着しました · 13:45」（左に緑ドット）

### Pending evidence chip（中央表示）

dashed border カード：

```
[gradient icon] 合流したら証跡を撮影
                両者の交換物を1枚に収めます  [撮影へ]
```

→ `C3-capture` へ

### Composer + クイックアクション（下部固定）

#### クイックアクション行（横スクロール）

```
[📍 現在地を送る]   ← lavender系 highlight
[👕 服装写真]       ← pink系 highlight
[🖼️ 写真添付]       ← subtle系
```

#### Composer 行

- + ボタン（追加メニュー、subtle bg）
- メッセージ入力欄（角丸 pill）
- 送信ボタン（紙飛行機アイコン、グラデ bg）

---

## アクション

| 操作 | 動作 | 状態変化 |
|---|---|---|
| 「服装写真を撮影してシェア」（CTA or quick action） | カメラ起動 → 撮影 → アップロード | `deal_outfit_photos` に新レコード、 `messages` に system message `event_type='outfit_shared'` 投稿 |
| 「📍 現在地を送る」（quick action） | GPS取得（要許可）→ 位置情報送信 | `messages.message_type='location_share'`、`metadata={lat, lng, accuracy_m, captured_at}` |
| 「🖼️ 写真添付」 | 写真ピッカー → 選択 → 送信 | `messages.message_type='image'` |
| メッセージ送信 | 入力テキストを送信 | `messages.message_type='text'` |
| QR ボタン | QR本人確認モーダル表示（自分のQR表示・相手のQRスキャン） | スキャン成功で `deal_arrivals` 自動INSERT（⚠️ MVPではPost-MVP扱い、現状は手動のみ） |
| 「会場到着」ボタン（⚠️ 未実装、追加要） | 自分が会場到着を報告 | `deal_arrivals` INSERT、`detection_method='manual'`、`messages` に system message |
| 「撮影へ」ボタン（pending evidence chip） | C-3 capture画面へ遷移 | `deals.status = 'evidence_captured'`（撮影完了時） |
| 戻る | 取引タブ進行中へ | （状態変化なし） |

### 遷移

- 撮影へ → `C3-capture` → `C3-approve` → `C3-rate`
- QR スキャン後 → モーダル閉じ、ヘッダーが「到着済」表示に
- キャンセル（⚠️ 別動線必要） → `D-cancel`

---

## バリデーション・エラー

### 服装写真アップロードのバリデーション

- 画像サイズ：5MB 以下推奨 ⚠️
- 形式：JPEG / PNG / HEIC
- 顔認識ブラー（顔写ってる場合の自動加工）⚠️ 要確認

### 現在地共有のバリデーション

- 位置情報の許可が必要（OS レベル）
- 拒否された場合：エラー表示「位置情報の許可が必要です」+ 設定アプリへ誘導

### メッセージ送信のバリデーション

- 入力欄が空でない
- 文字数上限（⚠️ 要確認、500-1000字程度）

---

## エッジケース

| ケース | 挙動 |
|---|---|
| 当日まで日数あり（事前画面） | `agreed` 状態。CTA で「証跡撮影」は無効化、「合流当日まで N日」表示 ⚠️ |
| 当日かつ待ち合わせ時刻前 | `agreed` → 通常表示 |
| 待ち合わせ時刻 30分超過 | キャンセル権発動 → `D-cancel` ボタン表示 ⚠️ 要確認 |
| 相手だけ到着、自分まだ | ヘッダー：「@xxx 会場到着済」緑ドット、メッセージで通知 |
| 両者到着 → 合流→ 証跡撮影 | C-3 へ進む |
| 通信失敗（メッセージ送信） | エラー表示 + retry、ローカルにキュー ⚠️ 要確認 |
| 相手が dispute 申告 | チャット凍結バナー：「⚠️ この取引は申告中です」、メッセージ送信 disabled ⚠️ |
| `deal.status='cancelled'` | 読み取り専用、CTA 全部 disabled |
| 服装写真をすでに共有済（再アップ） | 古い photo を保持し、新photo を最新に。messages にも新規 system message |
| 位置情報許可なし | 「📍 現在地を送る」ボタン disabled、tap時に許可ダイアログ |

---

## 関連 API（仮）

⚠️ 要確認（`notes/13_api_spec.md` で確定予定）

| 用途 | エンドポイント案 | メソッド |
|---|---|---|
| Deal 詳細取得 | `/api/deals/:id` | GET（status, participants, evidence_image_url, *_approved 等） |
| Proposal 詳細取得 | `/api/proposals/:id` | GET（取引内容、待ち合わせ） |
| メッセージ取得 | `/api/proposals/:id/messages?cursor=...` | GET |
| メッセージ送信 | `/api/proposals/:id/messages` | POST（body: `{message_type, body?, attachment_url?, metadata?}`） |
| 服装写真アップロード | `/api/deals/:id/outfit-photos` | POST（multipart） |
| 服装写真取得（最新） | `/api/deals/:id/outfit-photos/latest` | GET |
| 到着報告（手動） | `/api/deals/:id/arrivals` | POST（body: `{user_id, detection_method: 'manual'}`） |
| 現在地共有送信 | `/api/proposals/:id/messages`（type=location_share） | POST |
| QR コード取得 | `/api/users/:id/qr` | GET |
| QR スキャン検証 | `/api/deals/:id/verify-qr` | POST |

### 服装写真アップロードの payload（仮）

```
POST /api/deals/:id/outfit-photos
Content-Type: multipart/form-data

image: <file>
```

レスポンス：
```json
{
  "id": "uuid",
  "deal_id": "uuid",
  "user_id": "uuid",
  "image_url": "https://...",
  "shared_at": "2026-05-03T13:30:00Z"
}
```

サーバ側で以下を実行：
1. `deal_outfit_photos` に INSERT
2. `messages` に system message INSERT（`event_type='outfit_shared'`）
3. 相手にプッシュ通知

### 到着報告の payload

```
POST /api/deals/:id/arrivals
Content-Type: application/json

{
  "detection_method": "manual",
  "arrival_lat": 35.18 (任意, optional),
  "arrival_lng": 136.97 (任意, optional)
}
```

サーバ側：
1. `deal_arrivals` に INSERT
2. `messages` に system message（`event_type='arrival'`）
3. `deals.status` を更新（`agreed → arrived_one` または `arrived_one → arrived_both`）

---

## 状態遷移（09 との対応）

`09_state_machines.md` §2 Deal Lifecycle のうち、C-2 が担当する範囲：

```
agreed
  → outfit_shared_self / outfit_shared_partner / outfit_shared_both
  → on_the_way
  → arrived_one
  → arrived_both
  → evidence_captured  （C-3 へ）

agreed → cancelled（当日前キャンセル）
on_the_way / arrived_one → cancelled（30分以上遅刻でキャンセル権発動）
* → disputed（申告）
```

`outfit_shared_*` はサブステート（部分状態）として 09 で定義。実装上は `deal_outfit_photos` の有無で判定。

---

## 関連 docs

- [`notes/05_data_model.md`](../05_data_model.md) §6 deals / deal_arrivals / deal_outfit_photos / messages
- [`notes/09_state_machines.md`](../09_state_machines.md) §2 Deal Lifecycle
- [`notes/10_glossary.md`](../10_glossary.md) §H Message types / §F 待ち合わせ・到着ステータス
- [`notes/11_screen_inventory.md`](../11_screen_inventory.md) §B-4
- [`notes/12_screens/C-1.5_nego_chat.md`](C-1.5_nego_chat.md) 前段階（合意成立まで）
- [`notes/12_screens/C-3_complete.md`](C-3_complete.md) 次段階（合流後）

---

## 未確定項目

| # | 項目 | 解決時期 |
|---|---|---|
| 1 | 「会場到着」ボタンの配置（ヘッダー or 特定タイミング表示） | 設計詰め |
| 2 | 当日まで日数ある時の見え方（事前のヒマつぶしモード） | 設計詰め |
| 3 | 30分以上遅刻時のキャンセル権 UI（自動表示？手動？） | 設計詰め |
| 4 | 服装写真の顔ブラー処理 | 実装フェーズ |
| 5 | 通信切断時のローカルキュー仕様 | 実装フェーズ |
| 6 | dispute 中のチャット凍結の表示・挙動 | 設計詰め |
| 7 | + ボタンメニューの内容（クイックアクションと重複しない範囲） | 実装フェーズ |
| 8 | QR モーダルの仕様（自分のQR表示と相手のQRスキャンを同時表示？切替？） | 設計詰め |
