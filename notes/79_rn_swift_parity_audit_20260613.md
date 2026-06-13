# 79. RN→Swift パリティ監査 + notes 整合性監査（2026-06-13）

> 目的: 別セッションで進行中の Swift 実装へ渡す「次やることリスト」。
> 方法: `mobile/` と `ios-native/Sources/MegrumApp/` の read-only 突き合わせ + `notes/22`（backlog）/ `notes/76`（画面マップ）の記載検証 + notes/05/09/10/CLAUDE.md と実DB（supabase/migrations）の整合チェック。
> 注意: 監査時点は iter462。コード変更は一切していない。

---

## Part 1. RN→Swift 移植ギャップ

### A. 丸ごと未移植のRN画面（Swift側に対応実装なし・要優先度判断）

| # | RN元 | 規模 | 確認結果 |
|---|---|---|---|
| 1 | `mobile/app/schedules.tsx` + `schedule-editor.tsx` | 1,629行 + 283行 | Swift は schedules の**読み取りのみ**（iter363 の取引チャット内 sheet）。スケジュール作成/編集/削除の境界が `MegrumData` に存在しない |
| 2 | `mobile/app/meguri-letters.tsx` | 1,792行 | Swift `MeguriMessagesScreen`（SettingsScreen.swift 内包）はテキスト送受信+既読化のみ（iter334/336）。RN版の**画像送信**（ImagePicker→sendImage）が未移植 |
| 3 | `mobile/app/meguri-plus.tsx` + `src/lib/meguriPlusPurchase.ts` | 358行 | Swift 未実装（SettingsScreen に価格説明文言が1箇所あるのみ）。**IAP境界ごと未移植** |
| 4 | `mobile/app/meguri-avatar-edit.tsx` + `src/components/meguri/MeguriThreeScene.tsx` | 256行+3D | 3Dアバター（glbモデル）まわりは Swift に SceneKit/RealityKit 実装なし |
| 5 | `mobile/app/meguri-share.tsx` | 259行 | 未実装 |
| 6 | `mobile/app/meguri-plaza.tsx` | 265行 | 未実装 |
| 7 | `mobile/app/meguri-achievements.tsx` | 176行 | 未実装（「実績」文字列が Swift 側に0件） |
| 8 | `mobile/app/meguri-profile-edit.tsx` | — | 未実装（76マップの「要確認」→「未実装」で確定） |

※ 4〜8 は notes/22 の P1#1（Meguri adjacent screens）と一致。Swift版めぐりは新画面案（iter443）で再設計中のため、「RNの見た目再現」ではなく**機能単位の要否判断**から入るのが正しい。

### B. 画面はあるが挙動が欠けるもの

| # | 対象 | 欠落 |
|---|---|---|
| 9 | 掲示板スレッド詳細（Swift `MeguriScreen`） | RN `meguri-board-thread.tsx` にある**通報/ブロック/削除/編集/画像返信**が Swift に一切ない（grep 0件）。notes/22 P1#2 のまま未着手 |
| 10 | notes/22 P0 残のうち未消化 | ①相手から見える現地交換モードの表示確認 ②ホーム上のグルーム導線整理 ③オンボーディング分割設計 ④複数個別募集を完全保持するDB/API拡張 ⑤送信直前の相手条件再検証 ⑥取引詳細へのdispute banner反映 |

### C. notes/22・notes/76 の記載が古い（実装済みなのに「残」「要確認」のまま）

実装セッションが二重着手しないよう、以下は backlog から消し込み推奨：

- **22 P0#4 残「キャンセル申請の相手承認導線」→ 実装済み**（iter381「キャンセルに同意する」CTA + `proposals.status='cancelled'`）
- **22 P0#5 残「取引詳細からの dispute routing」→ 実装済み**（`TradesScreen.swift:321,480,621,729` で `DisputeDetailScreen` へ遷移。banner 反映のみ要確認）
- **22 P1#4「通知 deep link はタブ遷移のみ」→ ほぼ解消**（`NotificationRouteIntent` が tradeDetail / evidenceCapture / evidenceApproval / evaluation / tradeAssistance / disputeDetail / boardThread / meguriMessages / userProfile / userEvaluations をカバー）
- **22 P0#2 残「複数カード切り抜き」→ 実装済み**（`TradingCardBulkRecognizer.swift` が `GoodsEditorScreen.swift` に接続済み）
- **76マップの「要確認」4件（meguri-profile-edit / avatar-edit / achievements / plus）→「未実装」で確定**（上表A参照）
- RN側の以下は実体がなく**移植対象外**と76に明記してよい: `groom-map.tsx`（re-export）、`meguri-intro.tsx`（redirect のみ）、`drawer-visual.tsx` / `transactions-visual.tsx`（Visual QA 用スナップショット）

---

## Part 2. notes 整合性監査

### 2-1. notes/05_data_model.md が実DBとズレ（重大・「実装の正解集」を自称しているため優先修正）

| notes/05 の記載 | 実DB（migrations）+ Swift の実態 |
|---|---|
| `availability_windows`、status: `draft/active/paused/ended/archived` | **`activity_windows`**（20260502120000）、status: **`enabled/disabled/archived`** |
| `dispute_replies` | **`dispute_messages`**（Swift `MegrumData` も同名で16箇所参照） |
| `schedules.aw_id` → availability_windows | 20260503160000 は「meetup_scheduled_aw_id は作らない」方針。列名要再確認 |
| tags 系の記載なし | **`tags_master` / `goods_inventory_tags` / `tag_users`**（20260505100000）が未記載 |

### 2-2. notes/09_state_machines.md

- Proposal/Deal Lifecycle は良好（`agreement_one_side` / `completed` 等、DB check 制約・Swift 実装・09 が三者一致）
- **AW Lifecycle（§4）だけ旧状態名**：09 は `draft/active/paused/ended/archived`、実DBは `enabled/disabled/archived`。05 と同時に直すべき

### 2-3. 廃止用語の混入

- **Swift 1件**: `HomeDiscoveryExperience.swift:291` 「追加で**交換依頼**をする」→「打診」へ要修正（iter46 廃止用語）
- mobile/ は混入なし。notes/ も実質クリーン（17_legal_alignment の出現は規約原典との対照表なので正当）

### 2-4. CLAUDE.md 自体が古い（オーナー判断推奨）

1. 廃止用語表に「郵送」があるが、**iter168.71 で郵送交換は復活済み**（glossary は更新済み、CLAUDE.md が置き去り）
2. 「実装対象の優先方針 = mobile/（iter168.51）」だが、**iter413 で Swift Native（ios-native/）主軸へ転換済み**。チェックリスト8（EAS Update 必須）も旧前提
3. 「検討中: 技術スタック（React Native? Flutter? PWA?）」→ 決定済み

### 2-5. 良好だったもの

- notes/08 は iter462 まで更新済みで新鮮
- glossary の AW 定義（iter392/395 のユーザー向け非表示方針）は最新
- 状態名 snake_case の実装側遵守は AW 以外問題なし
