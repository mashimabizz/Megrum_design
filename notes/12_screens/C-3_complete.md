# C-3: 取引完了フロー（証跡撮影・両者承認・評価）

> 物理交換が終わったあとの3ステップ。証跡を残し、内容に間違いがないか相互確認し、評価する。

最終更新: 2026-05-01（iter41）
関連JSX: `Megrum/c-flow.jsx::CompleteScreen`、`CaptureStep`、`ApproveStep`、`RateStep`
関連HTML: `Megrum/Megrum C Flow.html`
関連 iter: 4（証跡レイアウト確定設計）/ 22（評価＋コレクション連携）

---

## 画面の目的

C-2 取引チャットの「合流したら証跡を撮影」CTA からの3ステップ：

1. **C-3① 証跡撮影**：両者の交換物を1枚に撮影（左=相手 / 右=自分）
2. **C-3② 両者承認**：内容に間違いがないか相互確認
3. **C-3③ 評価**：1-5星 + コメント、コレクション更新、X連携

トリプル承認を経て `Deal.status = 'rated'` になり、関連 `user_haves.status = 'traded'` も更新される。

## 画面ID

このファイルでカバーする 3 サブ画面：

| 画面ID | step | 関連JSX関数 |
|---|---|---|
| `C3-capture` | `'capture'` | `CaptureStep` |
| `C3-approve` | `'approve'` | `ApproveStep` |
| `C3-rate` | `'rate'` / `'done'` | `RateStep` |

`CompleteScreen({ tweaks, step })` で step を切替。

---

## 入力データ

### Props

```ts
{
  tweaks: BrandColors,
  step: 'capture' | 'approve' | 'rate' | 'done',
}
```

### 前画面からの引き継ぎ

- `deal_id`（C-2 の「撮影へ」ボタンから）
- 現在の `deals.status` は `arrived_both` または `evidence_captured`

### データモデル参照

- `deals WHERE id = X`
- `proposals WHERE id = deal.proposal_id`（取引内容詳細）
- `user_evaluations`（rate ステップで読み書き）

---

## 表示要素

### A. C-3① CaptureStep（証跡撮影）

**全画面ダーク背景**（黒に近い、`#0a0810`）。

```
[ヘッダー（半透明）]
  [×戻る]                  [● オフライン保存]    [スペーサー]

[タイトル]
  取引証跡を撮影
  両者の交換物を1枚に収めてください

[ファインダー（紫 border、中央 split frame）]
  ┌─────────────┬─────────────┐
  │  相手の譲    │  自分の譲    │
  │  [シルエット]│  [シルエット]│
  │              │              │
  └─────────────┴─────────────┘
  
[ガイドテキスト]
  💡 横並びで撮影してください
  
[シャッターボタン（大きい白丸）]
[フラッシュ・反転・タイマー（小アイコン）]
```

**重要**：レイアウトは「左=相手 / 右=自分」固定（撮影者が誰でも、画面上は相手左／自分右）。iter4 の確定設計。

### B. C-3② ApproveStep（両者承認）

```
[戻る]   両者承認   [スペーサー]

[撮影画像（大表示）]
  [先ほど撮影された evidence image]

[内容確認]
  📋 取引内容
  受け取った       出した
  スア WT01 トレカ ↔ ヒナ生写真 ×1
        ×3        スア STUDIO ×1

[両者承認状態]
  あなた: ☐ 未承認       @partner: ☑ 承認済（先に承認）
  
[CTA]
  ✓ 承認する  ／  ✗ 内容に相違あり

[補足]
  双方の承認で取引完了
  相違あり → D-flow（dispute）へ
```

### C. C-3③ RateStep（評価）

```
[戻る]   評価   [スペーサー]

[完了演出]
  🎉 取引完了！
  @partner との取引、ありがとうございました

[Trade summary（小カード）]
  受け取った       出した
  [サムネ]          [サムネ]
  スア WT01 ×3     ヒナ生写真 ×1, スア STUDIO ×1

[評価セクション]
  ★★★★★（5段階タップ）

  [コメント入力欄（任意・複数行）]
  プレースホルダ：「取引の感想を一言（任意）」

  [細分化評価（任意・iter39で要確認）]
  時間厳守度    ☆☆☆☆☆
  実物状態     ☆☆☆☆☆
  メッセージ対応 ☆☆☆☆☆

[コレクション更新通知]
  ✨ 新しいアイテムが追加されました
  [図鑑を見る → POK-list]

[X連携 CTA（任意）]
  📤 取引を X にシェアする

[完了ボタン]
  完了して取引タブへ
```

---

## アクション

### A. CaptureStep

| 操作 | 動作 |
|---|---|
| シャッターボタン | カメラで撮影 → 確認モーダル「この写真で OK？」→ アップロード |
| ×戻る | C-2 へ戻る（撮影なし） |
| フラッシュ・反転 | カメラ設定切替（実装は OS 依存） |

撮影完了で：
- `deals.evidence_image_url` を更新
- `deals.status = 'evidence_captured'`
- `step = 'approve'` へ遷移

### B. ApproveStep

| 操作 | 動作 | 状態変化 |
|---|---|---|
| 「✓ 承認する」 | 自分の承認フラグ ON | `deals.{sender_or_receiver}_approved = true` |
| 「✗ 内容に相違あり」 | 確認モーダル → D-flow へ遷移 | `deals.status = 'disputed'`、D-1 カテゴリ選択画面へ |
| 戻る | （撮影画面へ戻る、再撮影） | `evidence_image_url` 維持 |

両者承認完了時：
- `deals.status = 'approved'`
- 関連 `user_haves.status = 'traded'`
- `step = 'rate'` へ遷移
- 相手にプッシュ通知

### C. RateStep

| 操作 | 動作 | 状態変化 |
|---|---|---|
| ★ 1-5 タップ | 評価値セット（state） | （送信前） |
| コメント入力 | 入力（state） | （送信前） |
| 「完了して取引タブへ」 | 評価データ送信、`user_evaluations` INSERT | 自分の評価記録、`deals.status = 'rated'`（双方完了時） |
| 「📤 取引を X にシェアする」 | 自動生成テキスト + 画像で X 投稿 | （状態変化なし、外部連携） |
| 「図鑑を見る」 | `POK-list` へ遷移 | （状態変化なし） |
| 戻る | 取引タブへ | （状態変化なし） |

---

## バリデーション・エラー

### CaptureStep

- **写真サイズ**：最低 800×600 推奨 ⚠️
- **両者の品物が映っているか**：自動検証は不可（信頼ベース）
- **画像形式**：JPEG / PNG / HEIC

### ApproveStep

- **両者承認のロック**：両者が承認後は再撮影不可。再撮影したい時は dispute 経由 ⚠️ 要確認

### RateStep

- **評価必須**：rating（1-5）は必須、コメントは任意
- **重複評価防止**：1 deal × 1 user で 1 評価
- **編集**：評価後の編集可否（⚠️ 要確認、おそらく7日以内なら可？）

---

## エッジケース

| ケース | 挙動 |
|---|---|
| カメラ権限なし | 「設定アプリで許可してください」+ 設定アプリ起動 |
| 通信失敗（撮影アップロード） | ローカル保持 + retry。`オフライン保存` 表示 |
| 片方だけ承認 → 相手が dispute | dispute 申告で `deals.status='disputed'` に変化、自分の承認はそのまま記録 |
| 承認後の評価未完了で取引タブに戻る | `deals.status='approved'` で待機、後で再開可能 |
| 双方 rated 後の状態確認 | `deals.status='rated'`、編集不可 |
| 相手が rated せず長期放置 | リマインド通知（⚠️ 要確認）、最終的に片方だけ rated でも問題なし？ |
| dispute 中に C-3 にアクセス | 「⚠️ この取引は申告中です」表示で操作不可 |
| 画像アップロード失敗 | エラー表示 + retry。アップロード前は `evidence_image_url=null` |

---

## 関連 API（仮）

⚠️ 要確認（`notes/13_api_spec.md` で確定予定）

| 用途 | エンドポイント案 | メソッド |
|---|---|---|
| 証跡画像アップロード | `/api/deals/:id/evidence` | POST（multipart） |
| 承認 | `/api/deals/:id/approve` | POST |
| 異議申告 | `/api/deals/:id/dispute` | POST → D-flow へ遷移 |
| 評価送信 | `/api/deals/:id/rate` | POST（body: `{rating, comment?, sub_ratings?}`） |
| X 投稿生成 | `/api/social/x/share-trade` | POST（body: `{deal_id}`） |

### 評価送信の payload

```json
{
  "rating": 5,
  "comment": "迅速な対応ありがとうございました！",
  "punctuality_rating": 5,
  "item_condition_rating": 5,
  "communication_rating": 5
}
```

サーバ側：
1. `user_evaluations` INSERT
2. 双方 rated 完了なら `deals.status = 'rated'`、`completed_at = NOW()`
3. 関連 `user_haves.status = 'traded'`
4. コレクション図鑑（wish との連携）：受け取ったアイテムが wish にあれば `user_wants.status = 'achieved'`
5. プッシュ通知（相手に「評価を受け取りました」）

---

## 状態遷移（09 との対応）

`09_state_machines.md` §2 Deal Lifecycle の以下を担当：

```
arrived_both → evidence_captured（C-3① 撮影完了）
evidence_captured → approved（C-3② 双方承認）
approved → rated（C-3③ 双方評価完了）

evidence_captured → disputed（C-3② で「相違あり」）
approved → disputed（C-3③ 評価で問題あり申告）
```

`Item Lifecycle` も連動：
```
in_deal → traded（rated になった瞬間）
```

`Wish Lifecycle`：
```
in_negotiation → achieved（受け取ったアイテムが wish と一致した場合）
```

---

## 関連 docs

- [`notes/05_data_model.md`](../05_data_model.md) §6 deals.evidence_image_url / *_approved / completed_at / §7 user_evaluations
- [`notes/09_state_machines.md`](../09_state_machines.md) §2 Deal Lifecycle / §5 Item / §6 Wish
- [`notes/10_glossary.md`](../10_glossary.md) §D 証跡撮影・両者承認・評価
- [`notes/11_screen_inventory.md`](../11_screen_inventory.md) §B-5
- [`notes/12_screens/C-2_trade_chat.md`](C-2_trade_chat.md) 前段階（合流まで）
- [`notes/08_design_iterations.md`](../08_design_iterations.md) iter4（左=相手 / 右=自分 確定）/ iter22（評価＋コレクション連携）

---

## 未確定項目

| # | 項目 | 解決時期 |
|---|---|---|
| 1 | 細分化評価（時間厳守度・実物状態・メッセージ対応）を MVP で採用するか（05 §10 未確定#23） | 設計詰め |
| 2 | 評価後の編集可否・期間 | 設計詰め |
| 3 | 双方承認後の再撮影可否（dispute 経由のみ？） | 設計詰め |
| 4 | 片方だけ rated で長期放置時のリマインド・自動完了 | 実装フェーズ |
| 5 | X連携の自動生成テキストフォーマット | 実装フェーズ |
| 6 | コレクション図鑑連携の詳細（wishマッチ判定の精度） | 実装フェーズ |
| 7 | 「内容に相違あり」での D-flow 遷移時のデータ受け渡し（証跡画像自動添付の仕組み） | 設計詰め |
| 8 | オフライン保存の同期タイミング・データ整合性 | 実装フェーズ |
