# C-1 受信: 打診を受け取った側の画面

> 提案者から打診が届いた時の最初の画面。承諾／反対提案／拒否 の3択で次のフローを分岐。

最終更新: 2026-05-01（iter41）
関連JSX: `Megrum/nego-flow.jsx::C1ReceiveScreen`
関連HTML: `Megrum/Megrum Nego Flow.html`
関連 iter: 30 / 33

---

## 画面の目的

打診の通知（プッシュ or アプリ内）から開かれる画面。受諾者が提案内容（アイテム + 待ち合わせ）を確認し、3択で意思表示する。
- **承諾する** → そのまま合意成立、C-2 へ進む
- **反対提案する** → C-1.5 ネゴチャットで条件交渉
- **拒否する** → 終了

## 画面ID

`C1-receive`（`notes/11_screen_inventory.md` 参照）

---

## 入力データ

### Props

```ts
{
  tweaks: BrandColors,
  daysLeft: number,  // 期限までの残日数（default 6 = 最大の意味）
}
```

### React state

なし（静的な閲覧画面、選択は次画面に持ち越し）

### 前画面からの引き継ぎ

- `proposal_id`（通知タップ or 取引タブからのリンク経由）
- `proposal.status` は `sent`

### データモデル参照

- `proposals` 1件（sender_id, receiver_id, match_type, sender_have_ids, receiver_have_ids, message, meetup_*, created_at, expires_at）
- `users WHERE id = sender_id`（送信者プロフ）
- `user_haves` × proposals.sender_have_ids / receiver_have_ids（アイテム詳細）
- `availability_windows WHERE id = meetup_scheduled_aw_id`（待ち合わせの場所詳細）
- 自動添付情報（評価サマリ、直近トラブル等は集計ビュー）

---

## 表示要素

### ヘッダー（固定）

- 戻るボタン（`<`）
- タイトル「打診が届きました」
- サブテキスト：`残り {daysLeft}日 ・ 7日後に自動終了`（iter30）

### 本体

#### 1. Sender card（送信者情報）

- アバター（H 文字、紫→ピンクグラデ）
- @handle ＋ ★rating ＋ 取引N回 ＋ 距離m
- 「プロフ」ボタン（→ `PRO-other` へ）

#### 2. 提案内容カード（中核）

`linear-gradient(135deg, lavender, sky)` 背景の大カード。

```
📩 提案内容

あなたが受け取る
[サムネ] スア WT01 トレカ ×3

  ↔（紫 swap アイコン）

あなたが出す
[サムネ] ヒナ 5th Mini 生写真 ×2

─── （dashed divider）

📍 待ち合わせ
[★ あなたのAWと一致 バッジ]
5/3 (土) 14:00〜18:00
TWICE 名古屋ドーム公演
📍 ナゴヤドーム前矢田駅 周辺
[mini map preview 86px]
```

#### 3. メッセージカード

提案者からのフリーテキストメッセージ表示。

#### 4. 自動添付情報カード

iter33 で「推奨合流ポイント」削除（meetupに統合）。残り：

- 相手の服装写真：`直前撮影で更新`
- 評価サマリ：`★4.9 ・ 取引89回`
- 直近トラブル：`なし`（@Megrum バッジ）

#### 5. アクション 3択

縦スタック：

| ボタン | スタイル | 動作 |
|---|---|---|
| **承諾する** | グラデ filled（紫→水色） | 直接 agreed |
| **反対提案する** | white + lavender border | C-1.5 ネゴへ |
| 拒否する | 透明 + mute色 | 拒否確認モーダル → rejected |

---

## アクション（ユーザー操作と遷移先）

| 操作 | 動作 | 状態変化 |
|---|---|---|
| 「承諾する」タップ | 確認モーダル表示「この内容で取引成立しますか？」→ OK | `proposals.status = 'agreed'`、`agreed_by_receiver=true`、`agreed_by_sender=true`（直接合意で双方true）→ `C15-success` |
| 「反対提案する」タップ | C-1.5 ネゴチャット画面へ遷移 | `proposals.status = 'negotiating'` |
| 「拒否する」タップ | 確認モーダル「この打診を拒否しますか？」＋ 任意で定型文選択 → OK | `proposals.status = 'rejected'`、`rejected_template` セット（任意） |
| 「プロフ」ボタン | 送信者プロフへ遷移 | （状態変化なし） |
| 戻る | 通知一覧 or 取引タブへ | （状態変化なし） |

### 遷移先

- 承諾 → `C15-success`（取引成立画面）→ `C2-chat`
- 反対提案 → `C15-normal`（ネゴチャット）
- 拒否 → 元の画面（取引タブ "過去取引" に rejected として表示）

---

## バリデーション・エラー

### 承諾ボタンのバリデーション

承諾は即時実行ではなく、**確認モーダル経由**（誤タップ防止）。

⚠️ 要確認：合意確認モーダル（C-1.5 で使う `C15AgreementConfirmModal`）を C-1 受諾でも流用するか、専用モーダルを作るか。

### 拒否ボタンのバリデーション

拒否時、定型文選択（任意）：
- 「条件が合いません」
- 「すでに別の方と取引中です」
- 「タイミングが合いません」
- 「その他」

⚠️ 要確認：定型文の値リスト確定。

---

## エッジケース

| ケース | 挙動 |
|---|---|
| 期限切れ（receiver が開いた時点で `expires_at` 経過） | アクション3択を表示せず「⏱ この打診は期限切れで終了しました」 |
| sender が打診送信後、receiver が見るまでに撤回（未対応 ⚠️） | proposals.status='cancelled' で読み取り専用表示（要 cancelled state追加 ⚠️） |
| receiver が拒否済み（重複表示） | 「拒否済」表示で読み取り専用 |
| sender が同じ relationship で過去に rejected され、`rejected_partners` に登録済 | この打診は届いてない（送信時にブロック）想定 |
| 期限ギリギリ（残り1日以内） | バナー表示「⚠️ 明日でこの提案は自動終了します」（C-1.5 の reminder6 と同等） |
| 通信失敗（提案取得） | エラー表示 + retry |
| 提案アイテムの一部が `in_deal` で確保不可（sender 側） | 警告表示「[アイテム名] は他の取引で確定済」、承諾ボタン disabled ⚠️ |

---

## 関連 API（仮）

⚠️ 要確認（`notes/13_api_spec.md` で確定予定）

| 用途 | エンドポイント案 | メソッド |
|---|---|---|
| 提案取得 | `/api/proposals/:id` | GET |
| 承諾 | `/api/proposals/:id/agree` | POST |
| 反対提案開始（ネゴへ） | `/api/proposals/:id/counter` | POST |
| 拒否 | `/api/proposals/:id/reject` | POST（body: `{template?: string}`） |

### Proposal 取得レスポンス例

```json
{
  "id": "uuid",
  "sender": { "handle": "@hana_lumi", "rating": 4.9, "trades": 89, "distance_m": 169 },
  "match_type": "perfect",
  "sender_have_items": [{ "id": "uuid", "title": "ヒナ 5th Mini 生写真", "qty": 2, ... }],
  "receiver_have_items": [{ "id": "uuid", "title": "スア WT01 トレカ", "qty": 3, ... }],
  "message": "...",
  "meetup": {
    "type": "scheduled",
    "scheduled": {
      "aw_id": "uuid",
      "date": "5/3 (土)",
      "time": "14:00〜18:00",
      "place": "TWICE 名古屋ドーム公演",
      "area": "ナゴヤドーム前矢田駅 周辺",
      "match_aw": true
    }
  },
  "auto_attached": {
    "outfit_recent": "直前撮影で更新",
    "rating_summary": "★4.9 ・ 取引89回",
    "recent_disputes": "なし"
  },
  "expires_at": "2026-05-08T...",
  "days_left": 6,
  "status": "sent"
}
```

---

## 状態遷移（09 との対応）

`09_state_machines.md` §1 Proposal Lifecycle の以下を担当：

```
sent --[承諾]--> agreed
sent --[反対提案]--> negotiating
sent --[拒否]--> rejected
sent --[7日経過]--> expired
```

---

## 関連 docs

- [`notes/05_data_model.md`](../05_data_model.md) §5 proposals / §4 aws
- [`notes/09_state_machines.md`](../09_state_machines.md) §1 Proposal Lifecycle
- [`notes/10_glossary.md`](../10_glossary.md) §D 取引・プロセス（打診・承諾・拒否）
- [`notes/11_screen_inventory.md`](../11_screen_inventory.md) §B-2
- [`notes/12_screens/C-1.5_nego_chat.md`](C-1.5_nego_chat.md) 反対提案後の遷移先

---

## 未確定項目

| # | 項目 |
|---|---|
| 1 | 承諾の確認モーダルを `C15AgreementConfirmModal` 流用 or 専用 |
| 2 | 拒否の定型文値リスト確定 |
| 3 | sender撤回の仕様（`cancelled` 状態追加？） |
| 4 | 提案アイテムが `in_deal` 確保不可になった時の表示 |
| 5 | 期限切れタイミングの厳密な判定（サーバ時刻 vs クライアント時刻） |
