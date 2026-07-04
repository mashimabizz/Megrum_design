# 13. API仕様（REST API Spec）

> **目的**：Megrum のバックエンドAPI（REST）の draft 仕様。実装着手時の正解集。
> 全エンドポイントを `[METHOD /path]` の形式で網羅し、各々で入力・出力・認証要否・状態遷移・備考を定義。

最終更新: 2026-06-26（iter1205）
ステータス: Draft v1.9

---

## このドキュメントの位置付け

- `notes/05_data_model.md` のテーブル設計に対応する CRUD 操作
- `notes/09_state_machines.md` の状態遷移をトリガーするエンドポイント
- `notes/10_glossary.md` の用語と完全整合
- `notes/12_screens/` の各画面の「関連 API」セクションで参照される

## 更新ルール

- データモデル（05）変更時は対応エンドポイントも更新
- 状態遷移（09）変更時は遷移トリガーするエンドポイント仕様を見直し
- 「⚠️ 要確認」は実装着手で詰めて消していく
- 新規エンドポイント追加時は「目次」と該当セクションに同時追加

## 目次

1. [共通仕様](#1-共通仕様)
2. [Auth（認証）](#2-auth認証)
3. [Accounts（自分のアカウント）](#3-accounts自分のアカウント)
4. [Users（他ユーザー参照）](#4-users他ユーザー参照)
5. [Masters（マスタデータ）](#5-mastersマスタデータ)
6. [AWs（活動予定）](#6-aws活動予定)
7. [Items（在庫）](#7-items在庫)
8. [Wishes（ウィッシュ）](#8-wishesウィッシュ)
9. [Matches（マッチング）](#9-matchesマッチング)
10. [Proposals（打診・ネゴ）](#10-proposals打診ネゴ)
11. [Messages（メッセージ）](#11-messagesメッセージ)
12. [Deals（取引）](#12-deals取引)
13. [Disputes（異議申し立て）](#13-disputes異議申し立て)
14. [Reports（通報）](#14-reports通報)
15. [Subscriptions（メグルムプラス / 旧Premium / 旧めぐりPlus）](#15-subscriptionsメグルムプラス--旧premium--旧めぐりplus)
16. [Boosts（ブースト機能）](#16-boostsブースト機能)
17. [Ads（広告配信）](#17-ads広告配信)
18. [Misc（通知・WebSocket）](#18-misc通知websocket)
19. [⚠️ 未確定項目](#19-未確定項目)

---

## 1. 共通仕様

### ベースURL

```
本番:    https://api.megrum.jp/v1
staging: https://api-staging.megrum.jp/v1（or staging.megrum.jp）⚠️ 検討
```

ドメイン: `megrum.jp`（正式ドメインとして取得済）

### 認証スキーム

⚠️ 要確認：候補は **JWT Bearer**（推奨）または **Session Cookie**。

仮で JWT Bearer を採用：

```
Authorization: Bearer <jwt_token>
```

JWT には `user_id` と `account_status`、`exp`（24h 有効）等を含む。

### リクエスト形式

- Content-Type: `application/json`（一部マルチパート例外あり）
- ID 形式: UUID v4
- 日時形式: ISO 8601 UTC（`2026-05-03T14:00:00Z`）
- 文字エンコーディング: UTF-8

### レスポンス形式

成功時：

```json
{
  "data": { ... },
  "meta": {
    "request_id": "abc123",
    "timestamp": "2026-05-01T..."
  }
}
```

エラー時：

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "ユーザー向けメッセージ",
    "details": [
      { "field": "email", "reason": "duplicate" }
    ]
  },
  "meta": { ... }
}
```

### ステータスコード

| コード | 意味 |
|---|---|
| 200 | OK（GET/PUT/PATCH 成功） |
| 201 | Created（POST 成功） |
| 204 | No Content（DELETE 成功） |
| 400 | Bad Request（リクエスト形式不正） |
| 401 | Unauthorized（認証無効・期限切れ） |
| 403 | Forbidden（権限なし） |
| 404 | Not Found |
| 409 | Conflict（重複・状態不整合） |
| 422 | Unprocessable Entity（バリデーション失敗） |
| 429 | Too Many Requests（rate limit） |
| 500 | Internal Server Error |

### エラーコード（ビジネスレイヤー）

| code | 意味 |
|---|---|
| `VALIDATION_ERROR` | 入力バリデーション失敗 |
| `AUTH_REQUIRED` | 認証必要 |
| `AUTH_EXPIRED` | トークン期限切れ |
| `PERMISSION_DENIED` | 権限なし |
| `RESOURCE_NOT_FOUND` | リソース未存在 |
| `STATE_CONFLICT` | 状態遷移不整合（例：rejected な Proposal に agree しようとした） |
| `DUPLICATE` | 重複（email、handle、評価等） |
| `RATE_LIMITED` | 一定期間内のリクエスト数超過 |
| `EXTERNAL_SERVICE_ERROR` | 外部サービス（OAuth、メール等）失敗 |

### ページネーション

カーソルベース（チャットや時系列向き）：

```
GET /api/v1/messages?proposal_id=X&cursor=<base64>&limit=50
```

レスポンス：
```json
{
  "data": [...],
  "meta": {
    "next_cursor": "...",
    "has_more": true
  }
}
```

オフセットベース（リスト系）：

```
GET /api/v1/items?page=2&per_page=20
```

### Rate Limiting

⚠️ 要確認：基本方針：

- 認証なし：60 req/min/IP
- 認証あり：300 req/min/user
- アップロード系：10 req/min/user

### ファイルアップロード

⚠️ 要確認：方針候補：

- **A. 直接 multipart/form-data**：実装シンプル、サーバ負荷高
- **B. 署名付きURL（S3互換）**：パフォーマンス良、実装複雑

MVP は A、Post-MVP で B に移行。

---

## 2. Auth（認証）

`notes/09_state_machines.md` §7 Account Lifecycle に対応。

### POST /api/v1/auth/register

新規登録（メアド経路）。

- **Auth**: 不要
- **Request**: `{ email, password, handle, accepted_terms: true }`
- **Response 201**: `{ user_id, email, handle, account_status: "registered" }`
- **Errors**: 409（email/handle 重複）, 422（バリデーション）
- **Side effects**: 確認メール送信（24h 有効リンク）
- **State**: → `registered`
- **Screen**: `AUTH-signup`

### POST /api/v1/auth/verify-email

メール認証完了。

- **Auth**: 不要（リンクの token で検証）
- **Request**: `{ token }`
- **Response 200**: `{ user_id, account_status: "verified" }`
- **Errors**: 400（token 無効）, 404（token 期限切れ）
- **State**: `registered → verified`
- **Screen**: `AUTH-email-confirmed`

### POST /api/v1/auth/resend-verification

確認メール再送（60秒制限）。

- **Auth**: 不要（email 経由）
- **Request**: `{ email }`
- **Response 202**: `{ throttle_reset_at: "..." }`
- **Errors**: 429（60秒以内に再送）
- **Screen**: `AUTH-email-sent`

### POST /api/v1/auth/login

ログイン。

- **Auth**: 不要
- **Request**: `{ email, password }`
- **Response 200**: `{ token, user_id, account_status, expires_at }`
- **Errors**: 401（認証失敗）, 403（`suspended` / `deleted`）
- **State**: `account_status` 維持（変化なし）
- **Screen**: `AUTH-login`

### POST /api/v1/auth/oauth/google

Google OAuth経由ログイン or 新規登録。

- **Auth**: 不要
- **Request**: `{ id_token, accepted_terms?, handle? }`（新規時に handle と terms 必要）
- **Response 200/201**: `{ token, user_id, account_status, is_new_user }`
- **State**: 新規時 → `verified`（メール認証スキップ）
- **Screen**: `AUTH-google-consent`
- **備考**: ⚠️ 要確認 — OAuth subject の信頼境界、Google Workspace 限定するか

### POST /api/v1/auth/forgot-password

パスワードリセットメール送信。

- **Auth**: 不要
- **Request**: `{ email }`
- **Response 202**: `{}`（成否を問わず一定挙動でenum攻撃防止）
- **Side effects**: リセットメール送信
- **Screen**: `AUTH-pwd-reset`

### POST /api/v1/auth/reset-password

パスワードリセット実行。

- **Auth**: 不要（リンクの token で検証）
- **Request**: `{ token, new_password }`
- **Response 200**: `{ user_id }`
- **Errors**: 400（token 無効）, 422（パスワード強度不足）

### POST /api/v1/auth/logout

ログアウト。

- **Auth**: 必須
- **Request**: `{}`
- **Response 204**: なし
- **Side effects**: トークン無効化（サーバ側ブラックリスト or 短命トークン）

### POST /api/v1/auth/refresh

トークンリフレッシュ。

- **Auth**: refresh token（別 cookie or body）
- **Request**: `{ refresh_token }`
- **Response 200**: `{ token, expires_at }`
- **備考**: ⚠️ 要確認 — refresh token の保存方法（HttpOnly cookie 推奨）

---

## 3. Accounts（自分のアカウント）

### GET /api/v1/accounts/me

自分のアカウント情報取得。

- **Auth**: 必須
- **Response 200**: 全プロフィール（users + user_oshi）
- **Screen**: `PRO-hub`, `PRO-edit`

### PATCH /api/v1/accounts/me

プロフィール更新。

- **Auth**: 必須
- **Request**: `{ display_name?, bio?, avatar_url?, gender?, primary_area?, birth_date?, ... }`
- **Response 200**: 更新後プロフィール
- **備考**: `birth_date` は本人編集用で公開レスポンスへ直接出さず、公開表示は `age` を使う。`bio` は公開プロフィールに表示できる。
- **Screen**: `PRO-edit`

### PUT /api/v1/accounts/me/oshi

推し設定の置き換え（複数推し対応、iter24）。

- **Auth**: 必須
- **Request**: `[{ group_id?, character_id?, kind: "box"|"specific"|"multi", priority }]`
- **Response 200**: 更新後の推しリスト
- **Screen**: `PRO-oshi-edit`、`ONB-group`/`ONB-member`

### POST /api/v1/accounts/me/onboarding

オンボーディング進捗保存。

- **Auth**: 必須
- **Request**: `{ step: "gender"|"group"|"member"|"aw"|"complete", data: {...} }`
- **Response 200**: `{ next_step, account_status }`
- **State**: 全 step 完了で `verified → active`
- **Screen**: `ONB-*` 全5画面

### POST /api/v1/accounts/me/delete-request

アカウント削除申請（30日猶予）。

- **Auth**: 必須
- **Request**: `{ reasons: string[], note?: string }`（複数選択 + 任意メモ。Swift Nativeは `request_account_deletion_for_viewer()` RPC を利用）
- **Response 200**: `{ account_status: "deletion_requested", deletion_requested_at: "...", deletion_scheduled_at: "..." }`
- **Error 409相当**: 進行中取引（`sent` / `negotiating` / `agreement_one_side` / `agreed`）がある場合は退会不可
- **State**: → `deletion_requested`
- **Screen**: Swift Native 設定一覧 > 退会する

### DELETE /api/v1/accounts/me/delete-request

削除申請キャンセル（猶予期間中）の設計候補。

- **Auth**: 必須
- **Response 200**: `{ account_status: "active" }`
- **State**: `deletion_requested → active`
- **Current implementation note（2026-06-29）**: 現行Swift Native / Supabase RPCでは、退会申請作成 `request_account_deletion_for_viewer()` は確認済みだが、キャンセルAPI、ログイン復旧、自動削除完了処理は未確認。公開文面とApp Review Notesでは、キャンセル又は30日後完了を保証しない。

### GET /api/v1/accounts/me/blocks

ブロック中のユーザー一覧。

- **Auth**: 必須
- **Response 200**: `[{ user_id, blocked_at }]`
- **Screen**: `PRO-block-list`

### POST /api/v1/accounts/me/blocks

ユーザーをブロック。

- **Auth**: 必須
- **Request**: `{ user_id }`
- **Response 201**: `{ user_id, blocked_at }`
- **Side effects**: グルーム、めぐりメッセージ、スポット掲示板のスレッド/返信表示、グルーム通知、チャットルーム通知、掲示板メンション通知を相互に抑制する

### DELETE /api/v1/accounts/me/blocks/:user_id

ブロック解除。

- **Auth**: 必須
- **Response 204**: なし

---

## 4. Users（他ユーザー参照）

### GET /api/v1/users/:id

他ユーザーの公開プロフィール取得。

- **Auth**: 必須（認証済ユーザーのみアクセス可）
- **Response 200**: `{ id, handle, display_name, bio, avatar_url, primary_area, gender, age, oshi: [...], rating_summary: {...}, trades_count, recent_disputes_count, ... }`
- **備考**: 生年月日 `birth_date` は返さない。自己紹介 `bio` と年齢 `age` までを公開プロフィール表示に使う。
- **Errors**: 404（存在しない）、403（ブロック中）
- **Screen**: `PRO-other`

### GET /api/v1/users/:id/items

他ユーザーの譲一覧（公開モデル）。

- **Auth**: 必須
- **Query**: `?kind=for_trade`（`keep` は他人からは見えない）
- **Response 200**: `{ data: [items], meta: {...} }`
- **Screen**: `C15-modal-partner-inv`、マッチング詳細

### GET /api/v1/users/:id/aws

他ユーザーのAW（active のみ）。

- **Auth**: 必須
- **Response 200**: `{ data: [aws], meta: {...} }`
- **Screen**: `AW-other`

### GET /api/v1/users/:id/qr

他ユーザーのQRコード（合流時の本人確認用）。

- **Auth**: 必須（同 deal の参加者のみ）
- **Response 200**: `{ qr_data, expires_at }`（短命の検証トークン）
- **備考**: ⚠️ 要確認 — QR の中身（user_id だけ？署名付き？）

---

## 5. Masters（マスタデータ）

iter24 で `genres_master` / `groups_master` / `characters_master` / `goods_types_master` を運営マスタ化。

### GET /api/v1/masters/genres

ジャンル一覧。

- **Auth**: 不要（公開）
- **Response 200**: `[{ id, name, kind, display_order }]`

### GET /api/v1/masters/groups

グループ／作品一覧。

- **Auth**: 不要
- **Query**: `?genre_id=...&search=...`
- **Response 200**: `[{ id, name, aliases, kind, genre_id }]`
- **Screen**: `ONB-group`、`SCH-filter`

### GET /api/v1/masters/characters

メンバー／キャラ一覧。

- **Auth**: 不要
- **Query**: `?group_id=...&genre_id=...&search=...`
- **Response 200**: `[{ id, name, aliases, group_id, genre_id }]`
- **Screen**: `ONB-member`、`SCH-filter`

### GET /api/v1/masters/goods-types

グッズ種別一覧。

- **Auth**: 不要
- **Response 200**: `[{ id, name, category }]`

### GET /api/v1/masters/events

イベントシリーズ一覧（AW・proposals.meetup の `event_id` 用）。

- **Auth**: 必須
- **Query**: `?genre_id=...&group_id=...&from=...&to=...`
- **Response 200**: `[{ id, name, start_at, end_at, lat, lng, venue_name, is_verified }]`

### POST /api/v1/masters/events

イベントシリーズの新規作成（ユーザー作成）。

- **Auth**: 必須
- **Request**: `{ name, start_at, end_at, lat, lng, venue_name, genre_id, group_id? }`
- **Response 201**: `{ id, ..., is_verified: false }`
- **備考**: ⚠️ 要確認 — 即公開 vs 運営承認後（05 §10 未確定#14）

---

## 6. AWs（活動予定）

`notes/09_state_machines.md` §4 AW Lifecycle。

### GET /api/v1/aws

自分のAW一覧。

- **Auth**: 必須
- **Query**: `?status=active|paused|archived&from=...&to=...`
- **Response 200**: `{ data: [aws], meta: {...} }`
- **Screen**: `AW-list`、`SET-aw`

### POST /api/v1/aws

AW 新規作成。

- **Auth**: 必須
- **Request**: `{ start_at, end_at, lat, lng, radius_m?, place_name?, event_id?, note? }`
- **Response 201**: `{ id, status: "active", created_via: "manual", ... }`
- **State**: → `active`
- **Screen**: `AW-edit-event`、`AW-edit-location`

### GET /api/v1/aws/:id

AW詳細取得。

- **Auth**: 必須（自分のAW or 検索でヒット）
- **Response 200**: AW詳細

### PATCH /api/v1/aws/:id

AW更新。

- **Auth**: 必須（自分のAWのみ）
- **Request**: 部分更新
- **Response 200**: 更新後

### POST /api/v1/aws/:id/pause

一時無効化。

- **Auth**: 必須（自分のAWのみ）
- **State**: `active → paused`

### POST /api/v1/aws/:id/resume

再開。

- **Auth**: 必須
- **State**: `paused → active`

### DELETE /api/v1/aws/:id

AW削除。

- **Auth**: 必須（自分のAWのみ、active/paused状態でのみ）
- **Response 204**: なし

### GET /api/v1/aws/intersect

他ユーザーとのAW交差判定（マッチングUI用）。

- **Auth**: 必須
- **Query**: `?other_user_id=...`
- **Response 200**: `[{ my_aw_id, their_aw_id, overlap_start, overlap_end }]`
- **Screen**: `C0-meetup-scheduled`（「★ 相手と一致」バッジ判定）

---

## 7. Items（在庫）

`notes/05_data_model.md` §3 user_haves。

### GET /api/v1/items

自分の在庫一覧。

- **Auth**: 必須
- **Query**: `?kind=for_trade|keep&status=available|in_negotiation|in_deal|traded&page=...`
- **Response 200**: `{ data: [items], meta: {...} }`
- **Screen**: `INV-grid`、`C0-mine-perfect`

### POST /api/v1/items

在庫新規登録。

- **Auth**: 必須
- **Request**: `{ genre_tag_id, character_id, goods_type_id, title, description?, condition_tags?, kind, is_carrying?, carry_event_id? }`
- **Response 201**: `{ id, status: "available", ... }`
- **備考**: 数量×N の場合は N 件 INSERT（iter29、1行=1個）
- **Screen**: `INV-meta`（B-2③）

### POST /api/v1/items/bulk

複数件まとめて登録（数量管理用）。

- **Auth**: 必須
- **Request**: `{ items: [{...}, {...}, ...] }`
- **Response 201**: `{ data: [items], count }`

### GET /api/v1/items/:id

在庫詳細。

- **Auth**: 必須（自分の在庫 or 公開モデルで他人の `for_trade`）
- **Response 200**: 詳細

### PATCH /api/v1/items/:id

在庫更新。

- **Auth**: 必須（自分のもののみ）
- **Request**: 部分更新
- **Response 200**: 更新後
- **State**: `kind` 変更可（ただし `keep → for_trade` は OK、`status='in_negotiation'/'in_deal'` 中は `kind` 変更不可）

### DELETE /api/v1/items/:id

在庫削除。

- **Auth**: 必須（自分のもののみ、`status='available'` のみ）
- **Errors**: 409（提案中・取引中のため削除不可）

### POST /api/v1/items/:id/images

画像アップロード（複数可）。

- **Auth**: 必須
- **Request**: `multipart/form-data`、フィールド `images[]`
- **Response 201**: `[{ id, url, order }]`
- **備考**: 400×400 JPEG リサイズ、最大3枚 ⚠️

### POST /api/v1/items/upload-from-photo

複数アイテム一括登録（B-2 撮影フロー用）。

- **Auth**: 必須
- **Request**: `multipart/form-data`、`{ raw_image, crops: [{x,y,w,h, character_id, goods_type_id}, ...] }`
- **Response 201**: `[{ id, ... }, ...]`
- **Screen**: `INV-shoot` → `INV-crop` → `INV-meta`

### POST /api/v1/items/:id/toggle-carrying

携帯モード切替。

- **Auth**: 必須
- **Request**: `{ is_carrying: true/false, carry_event_id? }`
- **Response 200**: 更新後

---

## 8. Wishes（ウィッシュ）

`notes/05_data_model.md` §3 user_wants。

### GET /api/v1/wishes

自分のウィッシュ一覧。

- **Auth**: 必須
- **Query**: `?status=active|matched|in_negotiation|achieved&priority=...`
- **Response 200**: `{ data: [wishes], meta: {...} }`
- **Screen**: `WSH-list`

### POST /api/v1/wishes

ウィッシュ新規登録。

- **Auth**: 必須
- **Request**: `{ genre_tag_id, character_id?, goods_type_id?, title, description?, flexibility, priority }`
- **Response 201**: `{ id, status: "active", ... }`
- **Screen**: `WSH-edit`

### GET /api/v1/wishes/:id

詳細。

- **Auth**: 必須

### PATCH /api/v1/wishes/:id

更新。

- **Auth**: 必須

### DELETE /api/v1/wishes/:id

削除。

- **Auth**: 必須

### GET /api/v1/wishes/:id/matches

このウィッシュと一致する譲（他人の haves）。

- **Auth**: 必須
- **Response 200**: `[{ user_id, item, score, distance_m? }]`
- **備考**: マッチングロジック（05 §9）

---

## 9. Matches（マッチング）

ホーム画面のマッチ提案表示用。

### GET /api/v1/matches

自分宛のマッチ候補一覧（4タブ）。

- **Auth**: 必須
- **Query**: `?type=perfect|forward|backward|explore&page=...`
  - `perfect`: 完全マッチ
  - `forward`: 私が欲しい譲を持つ人
  - `backward`: 私の譲が欲しい人
  - `explore`: 探索（緩いマッチ）
- **Response 200**: `[{ user, items, match_type, score, last_active_at, distance_m, aw_overlap?, ... }]`
- **Screen**: `HOM-main`（4タブ）

### GET /api/v1/matches/feed

時間順フィード（タイムプレッシャー対応、AW進行中の人優先）。

- **Auth**: 必須
- **Query**: `?cursor=...`
- **Response 200**: cursor pagination
- **Screen**: `HOM-main`（探索タブ）

### GET /api/v1/matches/search

ホーム右下の検索画面。グッズ名・推し・シリーズにヒットする他ユーザーの譲候補を返す。

- **Auth**: 必須
- **Query**: `?q=...`
- **Response 200**:
  ```json
  {
    "results": [
      {
        "item": { "id": "...", "title": "...", "photo_url": "...", "tag_labels": ["会場限定"] },
        "owner_user_id": "...",
        "match_bucket": "matched|possible|none"
      }
    ]
  }
  ```
- **分類**:
  - `matched`: 検索ヒットした相手の譲が自分のwishに合い、相手も自分の譲を求めている
  - `possible`: 自分のwishまたは相手のwishのどちらか一方に合う
  - `none`: 検索にはヒットしたが、交換条件には合わない
- **Screen**: `mobile/app/search.tsx`

### POST /api/v1/matches/search-queries

検索実績を記録する。UI上の「人気の検索」はこの実績から集計し、固定サンプルは使わない。

- **Auth**: 必須
- **Request**: `{ "query": "スア トレカ", "result_count": 12 }`
- **Response 204**: no content
- **DB/RPC**: `search_query_logs`, `record_search_query`

### GET /api/v1/matches/popular-searches

直近30日の検索実績から人気検索語を返す。

- **Auth**: 必須
- **Query**: `?limit=10`
- **Response 200**: `{ "terms": [{ "term": "スア トレカ", "search_count": 18, "last_searched_at": "..." }] }`
- **DB/RPC**: `get_popular_search_terms`

### POST /api/v1/matches/saved-searches

保存検索作成。

- **Auth**: 必須
- **Request**: `{ name, filters: {...}, notification_enabled }`
- **Response 201**: `{ id, ... }`
- **Screen**: `SCH-filter`、`SCH-saved`

### GET /api/v1/matches/saved-searches

保存検索一覧。

- **Auth**: 必須
- **Response 200**: `[{ id, name, filters, count, last_run_at }]`

### POST /api/v1/matches/saved-searches/:id/run

保存検索を実行（最新マッチ取得）。

- **Auth**: 必須
- **Response 200**: マッチ一覧

### DELETE /api/v1/matches/saved-searches/:id

削除。

---

## 10. Proposals（打診・ネゴ）

`notes/09_state_machines.md` §1 Proposal Lifecycle。最大ボリューム。

### POST /api/v1/proposals

新規打診作成（draft）。

- **Auth**: 必須
- **Request**:
  ```json
  {
    "receiver_id": "uuid",
    "match_type": "perfect|forward|backward",
    "sender_have_ids": ["uuid", ...],
    "sender_have_qtys": [2, 1],
	    "receiver_have_ids": ["uuid", ...],
	    "receiver_have_qtys": [3],
	    "message": "string",
	    "meetup_start_at": "2026-05-06T06:00:00.000Z",
	    "meetup_end_at": "2026-05-06T08:00:00.000Z",
	    "meetup_place_name": "守口市駅",
	    "meetup_lat": 34.738,
	    "meetup_lng": 135.563,
	    "meetup_candidates": [
	      {
	        "startAt": "2026-05-06T06:00:00.000Z",
	        "endAt": "2026-05-06T08:00:00.000Z",
	        "placeName": "守口市駅",
	        "lat": 34.738,
	        "lng": 135.563,
	        "mode": "today"
	      }
	    ]
	  }
	  ```
	- **Response 201**: `{ id, status: "draft", ... }`
	- **State**: → `draft`
	- **備考**: `meetup_candidates` は最大3件。候補1は既存 `meetup_*` 5列へもミラーする。`register_as_aw` は使わない。
	- **Screen**: `C0-*`

### POST /api/v1/proposals/:id/send

打診を送信（draft → sent）。

- **Auth**: 必須（sender のみ）
- **Response 200**: `{ id, status: "sent", expires_at }`
- **State**: `draft → sent`
- **Side effects**: 受信者にプッシュ通知

### GET /api/v1/proposals/:id

打診詳細取得。

- **Auth**: 必須（sender or receiver のみ）
- **Response 200**: 全フィールド + sender/receiver 情報 + meetup 詳細展開
- **Screen**: `C1-receive`、`C15-*`

### POST /api/v1/proposals/:id/agree

合意送信（一方）。

- **Auth**: 必須（sender or receiver）
- **Response 200**: `{ status: "agreement_one_side"|"agreed", agreed_by_sender, agreed_by_receiver, deal_id? }`
- **State**: 
  - 自分が合意 → 相手未合意なら `agreement_one_side`
  - 双方合意完了 → `agreed`、`deals` を1件作成して `deal_id` 返却
- **Side effects**: 相手にプッシュ通知、`agreed` 到達時は `deals` レコード生成
- **Errors**: 409（`expired`、`rejected` 状態では実行不可）
- **Screen**: `C1-receive`（直接承諾）、`C15-modal-agreement`

### POST /api/v1/proposals/:id/reject

拒否。

- **Auth**: 必須（sender or receiver、ただし sender は draft/sent 時のみ）
- **Request**: `{ template?: string }`（拒否定型文）
- **Response 200**: `{ status: "rejected" }`
- **State**: `* → rejected`
- **Side effects**: 相手にプッシュ通知、`rejected_partners` に登録（受信者→送信者のみ）

### POST /api/v1/proposals/:id/counter

反対提案（C-1 受信から C-1.5 へ）。

- **Auth**: 必須（receiver のみ、sent 状態のみ）
- **Response 200**: `{ status: "negotiating" }`
- **State**: `sent → negotiating`

### POST /api/v1/proposals/:id/revise

提案修正（C-1.5 中）。

- **Auth**: 必須（sender or receiver、`negotiating`/`agreement_one_side` 中）
- **Request**: 全部または部分（sender_have_ids/qtys, receiver_have_ids/qtys, meetup_* / meetup_candidates, message）
- **Response 200**: 更新後
- **State**: 
  - `negotiating` 維持
  - `agreement_one_side` の場合 → ⚠️ 要確認（`agreed_by_*` リセット？）
- **Side effects**:
  - `proposal_revisions` にスナップショット保存
  - `messages` に system message `event_type='proposal_revised'` 追加
  - `last_action_at` 更新（⚠️ 要確認：7日カウントリセットするか）

### POST /api/v1/proposals/:id/extend

期限延長（+7日）。

- **Auth**: 必須（sender or receiver、`negotiating` 中のみ）
- **Response 200**: `{ extension_count, expires_at }`
- **State**: 状態維持、`extension_count++`、`expires_at = expires_at + 7d`
- **Side effects**: `messages` に system message `event_type='extended'`

### POST /api/v1/proposals/:id/share-inventory

相手の譲一覧をネゴチャットで共有（ボタン押下時）。

- **Auth**: 必須
- **Response 200**: `{ shared_at }`
- **Side effects**: `messages` に system message `event_type='inventory_shared'` 追加
- **Screen**: `C15-normal`

### GET /api/v1/proposals

自分が関与する打診一覧（取引タブ "打診中"）。

- **Auth**: 必須
- **Query**: `?status=sent|negotiating|agreement_one_side&role=sender|receiver`
- **Response 200**: `{ data: [proposals], meta: {...} }`
- **Screen**: `TRD-pending`

### GET /api/v1/proposals/:id/revisions

提案修正履歴。

- **Auth**: 必須（参加者のみ）
- **Response 200**: `[{ revision_id, revised_by, snapshot, revised_at }]`
- **備考**: ⚠️ 要確認 — 履歴保存粒度

---

## 11. Messages（メッセージ）

`notes/05_data_model.md` §5 messages（拡張）。

### GET /api/v1/proposals/:id/messages

メッセージ一覧（チャット履歴）。

- **Auth**: 必須（参加者のみ）
- **Query**: `?cursor=...&limit=50`
- **Response 200**: cursor pagination
- **Screen**: `C15-*`、`C2-chat`

### POST /api/v1/proposals/:id/messages

メッセージ送信。

- **Auth**: 必須（参加者のみ）
- **Request**:
  ```json
  {
    "message_type": "text|image|outfit_photo|location_share",
    "body": "string?",          // text 必須
    "attachment_url": "string?", // image/outfit_photo 用
    "metadata": {                // location_share 必須
      "lat": 35.18, "lng": 136.97, "accuracy_m": 10
    }
  }
  ```
- **Response 201**: 作成された message
- **備考**: `system` message はクライアント送信不可（サーバ側のみ生成）

### POST /api/v1/proposals/:id/messages/upload

画像付きメッセージ用のアップロード（multipart）。

- **Auth**: 必須
- **Request**: `multipart/form-data`、`{ image, message_type: "image"|"outfit_photo" }`
- **Response 201**: 作成された message（attachment_url 設定済）
- **Screen**: `C15-*`、`C2-chat`

### GET /api/v1/meguri-board/threads

スポット掲示板のスレッド一覧。

- **Auth**: 必須（preview fallback ではローカルデータ）
- **Query**:
  - `scope?=nearby_3km|same_prefecture`
  - `viewer_lat?=35.6812`
  - `viewer_lng?=139.7671`
  - `prefecture?=東京都`
  - `limit?=50`
- **Response 200**:
  ```json
  {
    "data": [
      {
        "id": "uuid",
        "title": "物販列いまどれくらい？",
        "body": "string",
        "image_paths": ["storage/path.jpg"],
        "image_urls": ["signed-url"],
        "category": "question|info|chat|trade|lost_found",
        "status": "visible|hidden|archived|locked",
        "is_pinned": false,
        "audience_scope": "nearby_3km|same_prefecture",
        "spot_key": "tokyo-dome-gate25",
        "spot_label": "東京ドーム 25ゲート前",
        "prefecture": "東京都",
        "origin_lat": 35.7056,
        "origin_lng": 139.7519,
        "distance_m": 420,
        "reply_count": 2,
        "reaction_count": 4,
        "bookmark_count": 1,
        "view_count": 12,
        "latest_reply_preview": "string?",
        "latest_activity_at": "2026-05-29T07:12:00Z",
        "updated_at": "2026-05-29T07:18:00Z",
        "viewer_bookmarked": false,
        "viewer_reacted": false,
        "viewer_hidden": false,
        "viewer_reported": false,
        "viewer_subscribed": true,
        "viewer_participated": true,
        "viewer_read_at": "2026-05-29T07:20:00Z",
        "author": { "id": "uuid", "display_name": "string", "handle": "string?" }
      }
    ]
  }
  ```
- **備考**:
  - `nearby_3km` は互換維持のscope名。無料ユーザーはスレッド作成時の `origin_lat/origin_lng` と閲覧者現在地の距離が1km以内の場合に表示する。有効な `megrum_plus` / `meguri_plus` / `premium` 権限を持つユーザーは、チャットルームに限り1km圏外も表示できる
  - `same_prefecture` はスレッド作成時の `prefecture` と閲覧者側の都道府県で判定する
  - 正確な位置情報は一覧表示しない。レスポンスの座標はアプリ内部の距離判定・互換用途に限定する
  - `image_paths` は private Storage path。クライアント表示時は閲覧可能なスレッドだけ署名URLへ変換する
  - `viewer_participated` はスレッド作成者、または可視返信を投稿済みの閲覧者で true。通知購読 `viewer_subscribed` とは別に扱う
- **Screen**: `meguri-board`

### POST /api/v1/meguri-board/threads

スポット掲示板にスレッド作成。

- **Auth**: 必須
- **Request**:
  ```json
  {
    "title": "string",
    "body": "string",
    "image_paths": ["storage/path.jpg"],
    "category": "question|info|chat|trade|lost_found",
    "audience_scope": "nearby_3km|same_prefecture",
    "spot_key": "string?",
    "spot_label": "string?",
    "prefecture": "string?",
    "origin_lat": 35.7056,
    "origin_lng": 139.7519
  }
  ```
- **Response 201**: 作成された thread
- **備考**: `nearby_3km` は互換維持のscope名で、作成時は `origin_lat` / `origin_lng` / `prefecture` 必須。基準地点はスレッドを立てた時の位置情報で、1km圏内の作成だけを許可する。`category` 未指定時は `chat`。作成者は自動でスレッド購読ONになる。画像は最大4枚まで `meguri-board-media` private Storage にアップロードしてから path を保存する
- **Screen**: `meguri-board`

### GET /api/v1/meguri-board/threads/:id

スポット掲示板のスレッド詳細。

- **Auth**: 必須（見える範囲の thread のみ）
- **Query**:
  - `viewer_lat?=35.6812`
  - `viewer_lng?=139.7671`
  - `prefecture?=東京都`
- **Response 200**: `thread` 本体 + `replies[]`
- **Side effects**: 詳細表示時に `meguri_board_thread_reads.read_at` を更新し、`view_count` を増やす
- **備考**: ブロック関係にある相手が作成したスレッド、またはブロック関係にある返信者の返信は返さない
- **Screen**: `meguri-board-thread`

### POST /api/v1/meguri-board/threads/:id/replies

スポット掲示板スレッドに返信。

- **Auth**: 必須（見える範囲の thread のみ）
- **Query**:
  - `viewer_lat?=35.6812`
  - `viewer_lng?=139.7671`
  - `prefecture?=東京都`
- **Request**:
  ```json
  {
    "body": "string",
    "image_paths": ["storage/path.jpg"],
    "parent_reply_id": "uuid?",
    "quote_author_name": "string?",
    "quote_body": "string?"
  }
  ```
- **Response 201**: `{ id, thread_id, body, image_paths, image_urls?, parent_reply_id, quote_author_name, quote_body, status, reaction_count, created_at, updated_at, deleted_at, viewer_reacted, viewer_reported, author }`
- **備考**: `thread.status='locked'` の場合は返信不可。ブロック関係にある相手のスレッドには返信不可。引用返信では `parent_reply_id` と表示用スナップショットを保存する。画像は最大4枚まで `meguri-board-media` private Storage path として保存し、閲覧可能な返信だけ署名URLで表示する
- **Side effects**: 返信者をスレッド購読ONにし、購読中の他ユーザーへ `notifications.kind='meguri_board_reply'` を作成する。本文に `@handle` がある場合は、閲覧可能な対象ユーザーへ `notifications.kind='meguri_board_mention'` を作成し、通常の購読返信通知とは重複させない。返信者と通知先がブロック関係にある場合は通知を作成しない
- **Screen**: `meguri-board-thread`

### Meguri Board Drafts（端末内状態）

スポット掲示板のスレッド作成下書きと返信下書きはAPIを持たない。iOSアプリ内で `meguri.board.composerDrafts.v1` / `meguri.board.replyDrafts.v1` に自動保存し、投稿/返信成功時に削除する。別端末同期は初回リリース対象外。

### PATCH /api/v1/meguri-board/threads/:id

スレッド作成者がタイトル/本文/カテゴリを編集する。

- **Auth**: 必須（author のみ）
- **Request**: `{ "title": "string", "body": "string", "category": "question|info|chat|trade|lost_found" }`
- **Response 204**: no content
- **Side effects**: `updated_at` と `latest_activity_at` を更新
- **Screen**: `meguri-board-thread`

### PUT /api/v1/meguri-board/threads/:id/status

スレッド作成者が締め切り/再開/削除を行う。

- **Auth**: 必須（author のみ）
- **Request**: `{ "status": "visible|locked|archived" }`
- **Response 204**: no content
- **備考**: `locked` は閲覧可能だが返信不可。`archived` は通常ユーザーには表示しない
- **Screen**: `meguri-board-thread`

### PATCH /api/v1/meguri-board/replies/:id

返信作成者が本文を編集する。

- **Auth**: 必須（author のみ）
- **Request**: `{ "body": "string" }`
- **Response 204**: no content
- **Side effects**: `updated_at` を更新
- **Screen**: `meguri-board-thread`

### DELETE /api/v1/meguri-board/replies/:id

返信作成者が返信を削除済み表示へ切り替える。

- **Auth**: 必須（author のみ）
- **Response 204**: no content
- **Side effects**: `status='deleted'` / `deleted_at=now()` / `body='この返信は削除されました'`
- **Screen**: `meguri-board-thread`

### POST /api/v1/meguri-board/threads/:id/read

スポット掲示板スレッドを既読にする。

- **Auth**: 必須（見える範囲の thread のみ）
- **Response 204**: no content
- **Side effects**: `meguri_board_thread_reads` を upsert、`view_count` を加算
- **Screen**: `meguri-board-thread`

### PUT /api/v1/meguri-board/threads/:id/bookmark

スレッド保存/保存解除。

- **Auth**: 必須
- **Request**: `{ "enabled": true }`
- **Response 204**: no content
- **Side effects**: `meguri_board_thread_bookmarks` を insert/delete、`bookmark_count` を同期
- **Screen**: `meguri-board`, `meguri-board-thread`

### PUT /api/v1/meguri-board/threads/:id/reaction

スレッドへの「参考になった」リアクション。

- **Auth**: 必須
- **Request**: `{ "enabled": true, "reaction_type": "useful" }`
- **Response 204**: no content
- **Side effects**: `meguri_board_thread_reactions` を insert/delete、`reaction_count` を同期。ONにした場合は `meguri_board_thread_subscriptions.notification_enabled=true` も upsert し、以後の投稿通知対象にする
- **Screen**: `meguri-board`, `meguri-board-thread`

### PUT /api/v1/meguri-board/threads/:id/subscription

スレッド返信通知の購読ON/OFF。

- **Auth**: 必須
- **Request**: `{ "enabled": true }`
- **Response 204**: no content
- **Side effects**: `meguri_board_thread_subscriptions.notification_enabled` を upsert。ON中のスレッドに自分以外が返信すると `notifications.kind='meguri_board_reply'` が作成される。通知bodyには本文プレビューを入れない
- **Screen**: `meguri-board`, `meguri-board-thread`, `notifications`

### PUT /api/v1/meguri-board/replies/:id/reaction

返信への「参考になった」リアクション。

- **Auth**: 必須
- **Request**: `{ "enabled": true, "reaction_type": "useful" }`
- **Response 204**: no content
- **Side effects**: `meguri_board_reply_reactions` を insert/delete、`reaction_count` を同期
- **Screen**: `meguri-board-thread`

### POST /api/v1/meguri-board/threads/:id/hide

ユーザー単位でスレッドを非表示にする。

- **Auth**: 必須
- **Response 204**: no content
- **Side effects**: `meguri_board_hidden_threads` に保存。以降、本人の一覧から除外
- **Screen**: `meguri-board`, `meguri-board-thread`

### POST /api/v1/meguri-board/users/:user_id/block

掲示板上のユーザーをブロックする。実体は `POST /api/v1/accounts/me/blocks` と同じ `groom_user_blocks`。

- **Auth**: 必須
- **Response 201**: `{ user_id, blocked_at }`
- **Side effects**: 対象ユーザーの掲示板スレッド/返信を即時に一覧・詳細から除外する。対象ユーザーからの掲示板返信通知・掲示板メンション通知も作成しない
- **Screen**: `meguri-board`, `meguri-board-thread`

### POST /api/v1/meguri-board/reports

スレッドまたは返信を通報する。

- **Auth**: 必須
- **Request**:
  ```json
  {
    "thread_id": "uuid?",
    "reply_id": "uuid?",
    "reason": "spam|harassment|privacy|unsafe|off_topic|other",
    "body": "string?"
  }
  ```
- **Response 201**: `{ id, status, created_at }`
- **備考**: `thread_id` と `reply_id` はどちらか一方だけ指定。iOSでは送信前に理由選択のActionSheetを表示する。運営画面で `open` / `reviewing` / `resolved` / `rejected` を管理する
- **Screen**: `meguri-board`, `meguri-board-thread`

---

## 12. Deals（取引）

`notes/09_state_machines.md` §2 Deal Lifecycle。

### GET /api/v1/deals/:id

取引詳細。

- **Auth**: 必須（参加者のみ）
- **Response 200**: 全フィールド + proposal 詳細展開
- **Screen**: `C2-chat`、`C3-*`、`TRD-active`

### GET /api/v1/deals

自分が関与する取引一覧。

- **Auth**: 必須
- **Query**: `?status=agreed|on_the_way|...|rated|cancelled|disputed&role=sender|receiver`
- **Response 200**: `{ data: [deals], meta: {...} }`
- **Screen**: `TRD-active`、`TRD-past`

### POST /api/v1/deals/:id/arrivals

到着報告（手動）。

- **Auth**: 必須（参加者のみ）
- **Request**: `{ arrival_lat?, arrival_lng?, detection_method: "manual" }`
- **Response 201**: `{ arrival_id, deal_status }`
- **State**: 自分のみ到着で `agreed → arrived_one`、双方到着で `arrived_one → arrived_both`
- **Side effects**: `messages` に system message `event_type='arrival'`
- **Screen**: `C2-chat`

### POST /api/v1/deals/:id/outfit-photos

服装写真アップロード。

- **Auth**: 必須（参加者のみ）
- **Request**: `multipart/form-data`、`{ image }`
- **Response 201**: `{ id, image_url, shared_at }`
- **Side effects**:
  - `deal_outfit_photos` に新レコード INSERT
  - `messages` に system message `event_type='outfit_shared'`
  - `deal.status` のサブステート更新（`outfit_shared_self/partner/both`）
- **Screen**: `C2-chat`

### GET /api/v1/deals/:id/outfit-photos/latest

最新の服装写真（自分・相手それぞれ）。

- **Auth**: 必須
- **Response 200**: `{ self?: { url, shared_at }, partner?: { url, shared_at } }`
- **Screen**: `C2-chat`（ヘッダーのステータス表示）

### POST /api/v1/deals/:id/evidence

証跡撮影アップロード。

- **Auth**: 必須（参加者のみ、`arrived_both` 状態）
- **Request**: `multipart/form-data`、`{ image }`
- **Response 201**: `{ image_url, deal_status: "evidence_captured" }`
- **State**: `arrived_both → evidence_captured`
- **Screen**: `C3-capture`
- **Swift Native現行実装**: Supabase Storage `chat-photos` へ保存後、`proposal_evidence_photos` をinsertする。insert行は `approved_by_sender` / `approved_by_receiver` を持ち、アップロードした本人側を初期trueにする。あわせて `messages.meta.action='evidence_added'` のsystem messageを作成し、本文は `XXが取引証跡をアップロードしました` とする。

### POST /api/v1/deals/:id/approve

承認。

- **Auth**: 必須（参加者のみ、`evidence_captured` 状態）
- **Request**: `{ photo_id?: uuid }`
- **Response 200**: `{ sender_approved, receiver_approved, deal_status }`
- **State**: すべての証跡画像で双方承認がそろうと `evidence_captured → approved`
- **Side effects**: 関連 `user_haves.status = 'traded'`（双方承認時）
- **Screen**: `C3-approve`
- **Swift Native現行実装**: Supabase RPC `approve_trade_evidence_for_viewer(p_proposal_id, p_photo_id default null)` を使う。`p_photo_id` 指定時は対象画像だけを閲覧者側承認にし、全画像の承認集約を `proposals.approved_by_sender` / `approved_by_receiver` へ反映する。両者承認後は `proposals.status='completed'` とし、`messages.meta.action='trade_completed'` のsystem messageを追加する。

### POST /api/v1/deals/:id/dispute

異議申告（C-3② or 評価で「相違あり」）。

- **Auth**: 必須（参加者のみ）
- **Request**: `{ category, description, evidence_urls? }`（D-flow 開始）
- **Response 201**: `{ dispute_id, ticket_number, status: "filed" }` → D-1 で詳細記入
- **State**: `deals.status = 'disputed'`
- **Screen**: `C3-approve`、`C3-rate` から → `D-1`

### POST /api/v1/deals/:id/rate

評価送信。

- **Auth**: 必須（参加者のみ、`approved` 以降）
- **Request**:
  ```json
  {
    "rating": 1-5,
    "comment": "string?",
    "punctuality_rating": 1-5 | null,
    "item_condition_rating": 1-5 | null,
    "communication_rating": 1-5 | null
  }
  ```
- **Response 201**: `{ evaluation_id, deal_status }`
- **State**: 双方評価完了で `approved → rated`、`completed_at` セット
- **Side effects**:
  - `user_evaluations` INSERT
  - 関連 `user_wants` のうち wishマッチしたものを `achieved` に
  - 相手にプッシュ通知
- **Screen**: `C3-rate`

### POST /api/v1/deals/:id/cancel

取引キャンセル。

- **Auth**: 必須（参加者のみ、`agreed`〜`arrived_one` まで）
- **Request**: `{ reason: "mutual"|"late_30min"|"system"|"other", note? }`
- **Response 200**: `{ deal_status: "cancelled" }`
- **State**: `* → cancelled`
- **備考**: `late_30min` は 30分超過で発動条件成立時のみ ⚠️
- **Screen**: `D-cancel`

---

## 13. Disputes（異議申し立て）

`notes/09_state_machines.md` §3 Dispute Lifecycle、`notes/05_data_model.md` §8 disputes。

### POST /api/v1/disputes

dispute 申告（D-1〜D-3）。

- **Auth**: 必須（deal 参加者のみ）
- **Request**:
  ```json
  {
    "deal_id": "uuid",
    "category": "no_show|late|mismatch|damage|other",
    "description": "string",
    "evidence_urls": ["string", ...]
  }
  ```
- **Response 201**: `{ id, ticket_number, status: "submitted", reply_deadline_at, arbitration_deadline_at }`
- **State**: → `submitted`
- **Side effects**:
  - 相手にプッシュ通知
  - 両者の新規打診凍結（受信者→送信者を `rejected_partners` 相互登録？⚠️）
- **Screen**: `D-1` → `D-2` → `D-3`

### GET /api/v1/disputes/:id

dispute 詳細。

- **Auth**: 必須（参加者または運営）
- **Response 200**: 全フィールド + replies
- **Screen**: `D-4`、`D-5*`、`D-6*`

### POST /api/v1/disputes/:id/reply

反論。

- **Auth**: 必須（filed_by 以外の deal 参加者）
- **Request**: `{ message, evidence_urls? }`
- **Response 201**: reply
- **State**: `submitted/reply_window → reply_received`
- **Screen**: `D-4`

### POST /api/v1/disputes/:id/withdraw

申告取り下げ。

- **Auth**: 必須（filed_by のみ、`submitted` のみ可）
- **Response 200**: `{ status: "withdrawn" }`
- **State**: `submitted → withdrawn`

### POST /api/v1/disputes/:id/admin-question

運営からの追加質問（D-5d）。

- **Auth**: 運営のみ
- **Request**: `{ question, target_user_id }`
- **Response 200**: 質問送信成功
- **備考**: ⚠️ 要確認 — 運営UI仕様

### POST /api/v1/disputes/:id/resolve

仲裁決定（運営）。

- **Auth**: 運営のみ
- **Request**:
  ```json
  {
    "decision": "sender_fault|receiver_fault|mutual_fault|no_fault|cant_determine",
    "reason": "string",
    "penalty_for_sender": "none|warning|temp_suspend|permanent_suspend",
    "penalty_for_receiver": "none|warning|temp_suspend|permanent_suspend",
    "next_steps": "string"
  }
  ```
- **Response 200**: `{ status: "resolved", resolution }`
- **State**: → `resolved`、関連 `deals.status = 'rated'` または別の終了状態 ⚠️
- **Side effects**: 当事者にプッシュ通知

### POST /api/v1/disputes/:id/reappeal

再審査申立て（D-6c）。

- **Auth**: 必須（参加者のみ、結果通知から7日以内、1取引1回のみ）
- **Request**: `{ message, evidence_urls? }`
- **Response 201**: `{ reappeal_id }`
- **備考**: ⚠️ 要確認 — 再審査の状態管理（disputes に新status追加？別テーブル？）

---

## 14. Reports（通報）

`notes/05_data_model.md` §7 reports。

### POST /api/v1/reports

通報送信。

- **Auth**: 必須
- **Request**:
  ```json
  {
    "target_user_id": "uuid?",
    "target_proposal_id": "uuid?",
    "target_message_id": "uuid?",
    "category": "spam|harassment|fake_item|no_show|other",
    "description": "string",
    "evidence_urls": ["string"]
  }
  ```
- **Response 201**: `{ id, status: "open" }`
- **Screen**: `RPT-form`、`RPT-complete`

### GET /api/v1/reports

自分が出した通報一覧。

- **Auth**: 必須
- **Response 200**: `{ data: [reports], meta: {...} }`

---

## 15. Subscriptions（メグルムプラス / 旧Premium / 旧めぐりPlus）

iter45 で追加。`notes/16_monetization.md` § Premium 会員 に対応。iter168.43 で、めぐりPlus（月額¥1,000）を `feature_key='meguri_plus'` の独立権限として追加。iter1223 で現行課金プランをメグルムプラス（月額¥500）へ寄せ、`feature_key='megrum_plus'` をアプリ横断の有料権限として追加。

### GET /api/v1/subscriptions/me

自分のサブスクリプション情報取得。

- **Auth**: 必須
- **Response 200**: `{ subscription: { plan_type, status, started_at, current_period_end, cancelled_at } | null, is_megrum_plus: boolean, is_premium: boolean, entitlements: { megrum_plus: boolean, premium: boolean, meguri_plus: boolean } }`
- **Screen**: `SET-top`、`PRO-hub`

### POST /api/v1/subscriptions/checkout

メグルムプラス、旧Premium、旧めぐりPlusの決済セッション開始。

- **Auth**: 必須
- **Request**: `{ plan_type: "megrum_plus_monthly" | "premium_monthly" | "premium_yearly" | "meguri_plus_monthly" | "monthly" | "yearly", provider: "stripe" | "apple" | "google" }`
- **Response 200**: `{ checkout_url, session_id }`（Stripe 等の決済画面 URL）
- **備考**: iOSのApple In-App PurchaseはStoreKitで購入し、購入後に `POST /api/v1/subscriptions/apple/sync` でサーバー検証・権限反映する。Stripe等の外部checkoutは、iOSアプリ内のデジタル機能解放導線には使わない。
- **Screen**: 「メグルムプラス」CTA → 決済画面

### POST /api/v1/subscriptions/apple/sync

Swift Native iOS版がStoreKit購入・復元・`currentEntitlements` 読み込み後に、サーバーへApple transactionを同期する。

- **Auth**: 必須
- **Request**: `{ product_id, transaction_id, original_transaction_id, signed_transaction_info?, signed_renewal_info?, environment? }`
- **Response 200**: `{ subscription: { plan_type, status, current_period_end, cancelled_at } | null, entitlements: { megrum_plus: boolean, premium: boolean, meguri_plus: boolean } }`
- **Side effects**:
  - Apple署名済みtransactionをサーバー側で検証
  - `product_id` を `plan_type` に解決
  - `subscriptions.transaction_provider='apple'` の行をupsert
  - `user_entitlements.feature_key='megrum_plus'` / `premium` / `meguri_plus` を更新
  - `transactions.kind='subscription_initial' | 'subscription_renewal'` を必要に応じて記録
- **備考**: iter1223時点のSupabase実装は `sync_megrum_plus_purchase_for_viewer(product_id, transaction_id, original_transaction_id, expires_at, verified_at)` で `megrum.plus.monthly` を `megrum_plus_monthly` / `megrum_plus` に同期する。クライアントは購入直後のUI反映にStoreKitの現在権限を使ってよいが、永続的な機能解放はサーバー集約後の `user_entitlements` を正とする。App Store Server APIでの署名検証は本番前に追加する。

### POST /api/v1/subscriptions/webhooks/apple

App Store Server Notificationsを受け取る。

- **Auth**: Apple署名検証
- **Request**: Apple `signedPayload`
- **Side effects**:
  - 通知IDを保存して冪等化
  - 更新、解約、billing retry、grace period、返金、revocationを `subscriptions` へ反映
  - `user_entitlements` の `active` / `expires_at` を更新
  - 必要に応じて `ad_overrides` と月次ブースト付与ジョブを同期

### POST /api/v1/subscriptions/webhooks/stripe

Stripe webhook 受信。

- **Auth**: webhook 署名検証
- **実装 route**: Web App Router では `/api/stripe/webhook`（iter166）。外部公開API名として `/api/v1/subscriptions/webhooks/stripe` を維持する場合は rewrite で接続する。
- **Side effects**: `stripe_webhook_events` に event_id を保存して冪等化、`subscriptions` レコード作成・更新。`plan_type='megrum_plus_monthly'` は `user_entitlements(feature_key='megrum_plus')`、`plan_type='meguri_plus_monthly'` は `meguri_plus`、それ以外のPremium系は `premium` を更新。広告非表示・boost grant は旧Premium仕様確定後に別ジョブで反映。

### Admin Console（server actions / iter166, iter1222）

`/admin` 配下は一般公開 REST API ではなく、Next.js Server Actions + server-side service role で実装する。

- **Auth**: Supabase Auth 必須。`admin_roles.status='active'` かつ必要 permission 必須
- **MFA**: `admin_roles.requires_mfa=true` の場合 AAL2 セッション必須
- **Actions**:
  - `user.account_status.update`: `users.update_status` 権限、理由必須、`admin_audit_logs` 保存
  - `admin_role.upsert`: `roles.manage` 権限、最後の `owner` 無効化不可、`admin_audit_logs` 保存
  - `entitlement.manual_override`: `entitlements.manage` 権限、`plan_overrides` + `user_entitlements` + `admin_audit_logs` 保存
  - `report.status.update`: `reports.moderate` 権限。`reports` / `goods_reports` / `groom_reports` / `meguri_board_reports` / `disputes` の状態更新を理由必須で保存
  - `oshi_request.approve_new_group` / `oshi_request.merge_group` / `oshi_request.reject`: `oshi_requests.manage` 権限。`groups_master` 登録または既存L1統合後、`oshi_requests` を `approved` / `merged` / `rejected` に更新
  - `character_request.approve_new_character` / `character_request.merge_character` / `character_request.reject`: `oshi_requests.manage` 権限。`characters_master` 登録または既存L2統合後、`character_requests` を更新
  - `notification.admin_announcement.send`: `notifications.send` 権限。任意ユーザーまたは `account_status in ('verified','onboarding','active')` の全ユーザーへ `notifications.kind='admin_announcement'` を作成し、既存モバイル通知配送へ委譲

### POST /api/v1/subscriptions/me/cancel

サブスクリプション解約申請。

- **Auth**: 必須
- **Response 200**: `{ status: "cancelled", current_period_end }`（期間終了まで使える）
- **State**: `subscription.status: active → cancelled`

### POST /api/v1/subscriptions/me/resume

解約済サブスクリプションの再開（期間終了前のみ）。

- **Auth**: 必須
- **Response 200**: `{ status: "active" }`

---

## 16. Boosts（ブースト機能）

`notes/16_monetization.md` § ブースト機能 に対応。

### GET /api/v1/boosts/me

自分のブースト残数・履歴取得。

- **Auth**: 必須
- **Response 200**:
  ```json
  {
    "remaining": 3,
    "active": [{ "id", "consumed_at", "expires_at", "target_type", "target_id" }],
    "history": [{ "id", "granted_at", "consumed_at", "granted_via" }]
  }
  ```

### POST /api/v1/boosts/checkout

ブーストパック購入の決済セッション開始。

- **Auth**: 必須
- **Request**: `{ pack: "single" | "pack5" | "pack10", provider: "stripe" | "apple" | "google" }`
- **Response 200**: `{ checkout_url, session_id }`
- **備考**: Apple/Google の場合は in-app purchase

### POST /api/v1/boosts/:id/consume

ブースト発動。

- **Auth**: 必須（自分のブーストのみ）
- **Request**:
  ```json
  {
    "target_type": "proposal" | "match_view" | "chat",
    "target_id": "uuid"
  }
  ```
- **Response 200**:
  ```json
  {
    "boost_id": "uuid",
    "consumed_at": "...",
    "expires_at": "...",
    "ad_override_until": "..."
  }
  ```
- **State**: `boost.consumed_at = NOW()`、`expires_at = NOW() + 24h`、`ad_overrides` に新レコード INSERT
- **Errors**:
  - 409（残数なし、`{"code": "NO_BOOSTS_REMAINING"}`）
  - 429（1日2個発動上限、`{"code": "BOOST_DAILY_LIMIT"}`）
- **Screen**: マッチング画面・打診作成画面の「⚡ ブースト」ボタン

### GET /api/v1/boosts/active

現在発動中の他ユーザーのブースト一覧（マッチング表示の優先順位計算用）。

- **Auth**: 必須
- **Response 200**: `[{ user_id, target_type, target_id, expires_at }]`
- **備考**: マッチング計算ロジックでこのデータを使い、ブースト中ユーザーを上位表示

---

## 17. Ads（広告配信）

`notes/16_monetization.md` § 広告 に対応。

### GET /api/v1/ads/should-show

広告を表示すべきか判定（ad_overrides を考慮）。

- **Auth**: 必須
- **Query**: `?screen_id=HOM-main&placement=tier1`
- **Response 200**: `{ show: boolean, reason?: "premium" | "boost" | "tier3_screen" | null }`
- **備考**: フロントエンドで広告SDK呼び出し前に判定

### GET /api/v1/ads/native

Native ad（マッチカード型広告）取得。

- **Auth**: 必須
- **Query**: `?screen_id=HOM-main&user_oshi=group_id` （推し情報でターゲティング）
- **Response 200**:
  ```json
  {
    "ads": [{
      "id": "ad_xxx",
      "type": "native",
      "title": "TWICE 公式ペンライト 新色",
      "subtitle": "公式オンラインストア",
      "image_url": "...",
      "cta_text": "見る",
      "cta_url": "...",
      "sponsor_label": "★ Sponsored"
    }]
  }
  ```

### POST /api/v1/ads/:id/impression

広告インプレッション記録（分析用）。

- **Auth**: 必須
- **Request**: `{ screen_id, position }`
- **Response 204**: なし
- **備考**: Post-MVP で詳細分析用

### POST /api/v1/ads/:id/click

広告クリック記録。

- **Auth**: 必須
- **Response 200**: `{ redirect_url }`

---

## 18. Misc（通知・WebSocket）

### POST /api/v1/notifications/devices

プッシュ通知デバイス登録。

- **Auth**: 必須
- **Request**: `{ platform: "ios|android|web", token }`
- **Response 201**: `{ device_id }`
- **DB**: `notification_devices` にExpo Push Tokenを保存。`notifications` INSERT時に有効端末へExpo Pushを配送する

### DELETE /api/v1/notifications/devices/:id

デバイス削除（ログアウト時）。

- **Auth**: 必須
- **Response 204**

### GET /api/v1/notifications/settings

通知設定取得。

- **Auth**: 必須
- **Response 200**: `{ push_enabled, groom_activity_push_enabled, chatroom_activity_push_enabled }`
- **Screen**: `SET-notif`

### PATCH /api/v1/notifications/settings

通知設定更新。

- **Auth**: 必須
- **Request**: 部分更新。MVPでは `{ push_enabled }`、めぐりカテゴリでは `{ groom_activity_push_enabled }` / `{ chatroom_activity_push_enabled }`
- **Side effects**: `push_enabled=false` は全OSプッシュを止める。`groom_activity_push_enabled=false` は `groom_liked` / `groom_reply` / `meguri_message`、`chatroom_activity_push_enabled=false` は `meguri_board_reply` / `meguri_board_mention` のOSプッシュだけを止める。アプリ内通知行は常に作成する

### WS /api/v1/ws

WebSocket でリアルタイム更新。

- **Auth**: 必須（接続時に JWT 検証）
- **Events**:
  - `message.created`: 新メッセージ
  - `proposal.updated`: 提案修正・状態変化
  - `deal.updated`: deal状態変化
  - `arrival.recorded`: 到着検知
- **備考**: ⚠️ 要確認 — MVP は polling で済ませるか WebSocket 採用するか

---

## 19. ⚠️ 未確定項目

各エンドポイントの「⚠️ 要確認」を集約。

### 認証・基盤

| # | 項目 | 解決時期 |
|---|---|---|
| 1 | JWT vs Session Cookie | 実装着手 |
| 2 | refresh token の保存方法（HttpOnly cookie 等） | 実装着手 |
| 3 | OAuth subject の検証境界 | 実装着手 |
| 4 | Rate limit の具体数値 | 実装着手 |
| 5 | API バージョニング戦略（v1 固定？v2 移行時の運用） | Post-MVP |

### Proposal・ネゴ

| # | 項目 | 解決時期 |
|---|---|---|
| 6 | proposals 作成タイミング（C-0 完了時 or 送信時） | 設計詰め |
| 7 | ネゴ中の提案修正で `last_action_at` リセットするか | 設計詰め |
| 8 | `agreement_one_side` 中の提案修正で `agreed_by_*` を reset するか | 設計詰め |
| 9 | proposals に `cancelled` 状態を追加するか | 設計詰め |
| 10 | proposal_revisions の保存粒度（毎修正全部 vs N件） | 設計詰め |
| 11 | system message の `event_type` 値リスト確定 | 実装着手 |
| 12 | proposals に `exchange_method='hand'|'mail'` をどう載せるか | 設計詰め |
| 13 | 郵送交換で住所登録未完了の時、送信前にどの API で弾くか | 設計詰め |

### Deal・dispute

| # | 項目 | 解決時期 |
|---|---|---|
| 14 | 到着検知の追加実装（QR / GPS）の Post-MVP 着手時期 | Post-MVP |
| 15 | 服装写真の顔ブラー処理 | 実装着手 |
| 16 | 細分化評価（punctuality 等）を MVP で採用するか | 設計詰め |
| 17 | dispute reply 期限 24h or 4h カテゴリ依存ルール | 設計詰め |
| 18 | dispute resolved 後の deals.status（rated に戻るか別ステート？） | 設計詰め |
| 19 | 再審査申立てのデータ構造（disputes に status 追加 vs 別テーブル） | 設計詰め |
| 20 | 30分遅刻時のキャンセル権発動条件（自動 vs 手動） | 設計詰め |
| 21 | dispute中のチャット凍結ルール（メッセージ送信不可？） | 設計詰め |
| 22 | 郵送交換を `deals.status` の別フローにするか | 設計詰め |
| 23 | 合意後住所表示の取得 API を proposal / deal のどちら起点にするか | 設計詰め |

### マスタ・周辺

| # | 項目 | 解決時期 |
|---|---|---|
| 24 | events のユーザー作成シリーズの即公開 vs 運営承認 | 設計詰め |
| 25 | events の重複検出・自動マージルール | 実装着手 |
| 26 | QRコードの中身（user_id だけ？署名付き？） | 設計詰め |
| 27 | マッチング計算のバッチ頻度（毎日/6h/1h） | 実装着手 |
| 28 | リアルタイム通知のスロットル | 実装着手 |
| 29 | WebSocket 採用 vs polling（MVP） | 設計詰め |
| 30 | スポット掲示板の `same_spot` 判定に使う「現在のスポット」をユーザー状態のどこへ永続化するか | iter168.89でlegacy化。新規は `nearby_3km` / `same_prefecture` |

### 画像・ストレージ

| # | 項目 | 解決時期 |
|---|---|---|
| 26 | 直接アップロード vs 署名付きURL（S3互換） | 実装着手 |
| 27 | 画像サイズ・形式の上限 | 実装着手 |
| 28 | 画像の保管期間・自動削除（証跡画像は何年保持？） | 設計詰め |

### 通報・運営

| # | 項目 | 解決時期 |
|---|---|---|
| 29 | 運営UIの仕様（dispute resolve、admin-question 等） | 別フェーズ |
| 30 | 通報後の自動処理ロジック（即ブロック？運営確認後？） | 設計詰め |

---

## 関連 docs

- [`notes/05_data_model.md`](05_data_model.md) — テーブル定義
- [`notes/09_state_machines.md`](09_state_machines.md) — 状態遷移
- [`notes/10_glossary.md`](10_glossary.md) — 用語・enum 値
- [`notes/11_screen_inventory.md`](11_screen_inventory.md) — 画面マトリクス
- [`notes/12_screens/`](12_screens/) — 各画面の詳細仕様

各 `12_screens/*.md` の「関連 API」セクションに、ここで定義したエンドポイントへの参照あり。
