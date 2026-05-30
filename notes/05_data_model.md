# データモデル設計

> **目的**：Megrum の全エンティティのDBスキーマ設計と、状態・マッチング・取引のデータフロー定義。
> 実装の正解集。`09_state_machines.md` と完全に整合させ、`10_glossary.md` の用語を使う。

最終更新: 2026-05-30
ステータス: Draft v2.27（iter276 モバイル通知を追加）

## 最新化履歴

| Rev | 日付 | 変更 |
|---|---|---|
| v1.0 | 2026-04-27 | 初版（マスタ階層、availability_windows、proposals 等） |
| **v2.0** | **2026-05-01** | **iter24/29/33/34 反映（meetup, outfit, location_share, 状態名統一、deals リネーム）** |
| **v2.1** | **2026-05-03** | **iter67 反映（schedules 新設、proposals.message_tone 追加、meetup_scheduled_aw_id 廃止、expose_calendar の対象を AW → schedules に変更）** |
| **v2.2** | **2026-05-03** | **iter67.1 反映（待ち合わせを「時間帯+地図座標」型に統一：meetup_type/meetup_now_minutes/meetup_scheduled_custom 廃止、meetup_start_at/end_at/place_name/lat/lng 追加）** |
| **v2.3** | **2026-05-03** | **iter67.3 反映（listings を N×M × AND/OR マトリクス化：have_ids[]/have_qtys[]/have_logic + wish_qtys[]/wish_logic 追加、inventory_id/ratio_*/priority/exchange_type 廃止。wish 側の exchange_type は goods_inventory に既存・UI で必須化）** |
| **v2.4** | **2026-05-03** | **iter67.4 反映（求側を「複数選択肢」モデルへ再設計：listing_wish_options 新規、listings から wish_*/wish_logic 廃止、have_group_id/have_goods_type_id 追加で同一性検証、定価交換選択肢サポート）** |
| **v2.5** | **2026-05-03** | **iter67.7 反映（proposals に cash_offer / cash_amount 列追加：定価交換打診サポート。receiver_have_ids 空時の CHECK 緩和）** |
| **v2.6** | **2026-05-03** | **iter68-A 反映（messages テーブル新規：proposal_id × sender_id × type ('text'/'photo'/'outfit_photo'/'location'/'arrival_status'/'system') のチャット追記型）** |
| **v2.7** | **2026-05-03** | **iter68-D/E/F 反映（proposals に evidence_photo_url / evidence_taken_at / evidence_taken_by / approved_by_* / completed_at / status='completed' 追加。user_evaluations テーブル新規（1 取引 1 評価 unique）。Storage chat-photos バケット作成）** |
| **v2.8** | **2026-05-03** | **iter68.1 反映（proposal_evidence_photos テーブル新規：複数枚証跡対応。proposals.evidence_photo_url は最初の写真の互換ミラーとして残す）** |
| **v2.9** | **2026-05-06** | **iter154.34 反映（proposals.meetup_candidates jsonb 追加。最大3件の「交換できる候補」を保存し、候補1を既存 meetup_* 列へミラー）** |
| **v2.10** | **2026-05-23** | **iter162.83 反映（proposal_read_states テーブル新規：取引チャット/ネゴチャットの参加者別読了位置を保存し、実データに基づく既読表示へ変更）** |
| **v2.11** | **2026-05-24** | **iter164 反映（groom_posts / groom_reactions / groom_views / groom_replies と groom-posts Storage を実装。グルームの24時間公開、いいね、閲覧済み、返信通知をDB管理へ移行）** |
| **v2.12** | **2026-05-24** | **iter165 反映（グルーム公開範囲をRLS/Private Storageで厳格化。groom_hidden_posts / groom_user_blocks / groom_reports / meguri_messages と meguri-message-media Storage を追加）** |
| **v2.13** | **2026-05-24** | **iter166 反映（admin_roles / admin_audit_logs / user_entitlements / plan_overrides / stripe_webhook_events と subscriptions 実テーブルを追加。管理者ページ・有料権限・Stripe webhookの土台を定義）** |
| **v2.14** | **2026-05-25** | **iter168.43 反映（めぐりPlusを `user_entitlements(feature_key='meguri_plus')` に分離。`meguri_messages` 本文/画像は無料受信者へ直接返さず、専用RPCでロック済みメタ情報だけ返す）** |
| **v2.15** | **2026-05-29** | **iter168.71 反映（郵送交換を交換手段に再追加。住所テーブル案、proposal.exchange_method、待ち合わせ必須条件の分岐、未確定項目を追記）** |
| **v2.16** | **2026-05-29** | **iter168.73 反映（めぐり配下のスポット掲示板MVPを追加。`meguri_board_threads` / `meguri_board_replies` と scope=`same_spot|same_prefecture|global`、ローカルfallback前提の最小仕様を定義）** |
| **v2.17** | **2026-05-29** | **iter168.74 反映（郵送交換MVPを実装。`user_mailing_addresses` 実テーブル、`proposals.sender_mailing_address/receiver_mailing_address` スナップショット、合意時固定ルールを追記）** |
| **v2.18** | **2026-05-29** | **iter168.82 反映（`exchange_method='both'` を追加し、現地・郵送どちらも対応可の打診を保存できるように更新）** |
| **v2.19** | **2026-05-29** | **iter168.89 反映（グルーム投稿とスポット掲示板スレッドに作成時位置 `origin_lat/origin_lng` を追加。グルームは現在地1km、掲示板は `nearby_3km` / `same_prefecture` で閲覧）** |
| **v2.20** | **2026-05-30** | **iter174 反映（スポット掲示板のスレッド購読と `notifications.kind='meguri_board_reply'` を追加）** |
| **v2.21** | **2026-05-30** | **iter175 反映（スポット掲示板返信の `@handle` メンション通知 `notifications.kind='meguri_board_mention'` を追加）** |
| **v2.22** | **2026-05-30** | **iter176 反映（スポット掲示板のスレッド/返信画像添付と private Storage `meguri-board-media` を追加）** |
| **v2.23** | **2026-05-30** | **iter178 反映（`groom_user_blocks` をスポット掲示板にも適用。スレッド/返信表示、返信通知、メンション通知を相互に抑制）** |
| **v2.24** | **2026-05-30** | **iter179 反映（スポット掲示板の通報理由をUIで選択。`meguri_board_reports.reason` は `spam` / `harassment` / `privacy` / `unsafe` / `off_topic` / `other` を保存）** |
| **v2.25** | **2026-05-30** | **iter180 反映（スポット掲示板のスレッド作成・返信下書きを端末内 `meguri.board.composerDrafts.v1` / `meguri.board.replyDrafts.v1` に自動保存）** |
| **v2.26** | **2026-05-30** | **iter188 反映（`list_meguri_board_threads_for_viewer()` に `viewer_participated` を追加。スレッド作成者または可視返信済みユーザーを参加中として返す）** |
| **v2.27** | **2026-05-30** | **iter276 反映（`notification_devices` と `user_notification_settings.push_enabled` を追加し、`notifications` INSERTからExpo Pushへ配送する）** |
| **v2.20** | **2026-05-29** | **iter168.90 反映（`search_query_logs` と人気検索RPCを追加。検索結果はマッチ分類つきグッズパネルで表示）** |
| **v2.21** | **2026-05-30** | **iter168.97 反映（`schedules.place_name` 追加。合意時に `both` を単一手段へ固定し、現地交換の複数候補は1件へ固定する運用を追記）** |

## このドキュメントの位置付け

- **状態識別子（status等）は `09_state_machines.md` と完全一致**
- **用語は `10_glossary.md` と完全一致**（`deal` を使う、`exchange` は旧）
- **「⚠️ 要確認」は実装着手前に擦り合わせる項目**
- 表記揺れに気づいたら `10_glossary.md` に追加・更新

---

## 目次

1. [マスタテーブル](#1-マスタテーブル)
2. [ユーザー・アカウント](#2-ユーザーアカウント)
3. [在庫・ウィッシュ](#3-在庫ウィッシュ)
4. [活動予定（AW）・イベント](#4-活動予定awイベント)
5. [打診（Proposal）・ネゴ・メッセージ](#5-打診proposalネゴメッセージ)
6. [取引（Deal）・到着・服装・位置共有](#6-取引deal到着服装位置共有)
7. [評価・通報・断った記録](#7-評価通報断った記録)
8. [Dispute（異議申し立て）](#8-dispute異議申し立て)
9. [マネタイズ（Subscriptions・Boosts・Transactions・Ads）](#9-マネタイズ)
10. [管理者・権限管理](#10-管理者権限管理)
11. [マッチング計算ロジック](#11-マッチング計算ロジック)
12. [⚠️ 未確定項目](#12-未確定項目)

---

## 1. マスタテーブル

iter24 で「推し2階層」（グループ/作品 → メンバー/キャラ）を UI で明示化。iter168.22 で、ユーザーが選ぶ文脈（グループ所属・作品所属・ソロ）とは別に、同じ人物/キャラクターを内部で束ねる `oshi_entities_master` を追加した。

### `genres_master`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | "K-POP男性" / "K-POP女性" / "国内男性" / "国内女性" / "歌い手" / "声優" / "2.5次元・舞台" / "アニメ・マンガ" / "ゲーム" / "キャラクターIP" 等 |
| `kind` | text | 'idol' / 'anime' / 'game' / 'other' |
| `display_order` | int | 表示順 |
| `created_at` | timestamptz | |

> **iter168.19 推し分類方針**：UI上は `genres_master` をユーザーが探す入口として扱う。アイドル・音楽領域だけ `K-POP男性` / `K-POP女性` / `国内男性` / `国内女性` / `歌い手` / `声優` に細分化し、それ以外は `2.5次元・舞台` / `アニメ・マンガ` / `ゲーム` / `キャラクターIP` / `VTuber・配信者` / `お笑い` / `スポーツ` / `俳優・タレント` / `海外エンタメ` の大分類を維持する。`groups_master.kind` は対象の形（`group` / `work` / `solo`）として別軸で保持する。

### `oshi_entities_master`

同じ人物・同じキャラクターを、複数の選択文脈から束ねる内部マスタ。たとえば「LE SSERAFIM のサクラ」と「IZ*ONE のサクラ」、または「FANTASTICS の八木勇征」と「俳優・タレントの八木勇征」は、UI上は別文脈で選べるが同じ `entity_id` に紐付く。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `identity_key` | text | 運営管理用の安定キー。同名別人を分け、明示した同一対象だけ同じentityへ寄せる |
| `canonical_name` | text | 代表表示名。芸名・キャラ名などユーザーに自然な名称を使う |
| `entity_type` | text | 'person' / 'character' / 'other' |
| `aliases` | text[] | 表記揺れ |
| `display_order` | int | 管理・候補表示の補助順 |
| `created_at` | timestamptz | |

> **iter168.22 同一人物設計**：`groups_master` / `characters_master` は「ユーザーがどう選ぶか」の文脈、`oshi_entities_master` は「内部的に同じ推しか」を表す。自動で同名を全部統合すると `ユナ` など同名別人を誤統合するため、基本は文脈別entityを作り、兼任・移籍・ソロ活動など同一性が明確なものだけ明示的に同じ `entity_id` に寄せる。

### `groups_master`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `genre_id` | uuid | → genres_master |
| `name` | text | "SEVENTEEN" / "TWICE" / "呪術廻戦" / "Ado" 等 |
| `aliases` | text[] | ["방탄소년단", "防弾少年団"] 等の表記揺れ |
| `kind` | text | 'group' / 'work' / 'solo'（iter24対応：ソロアーティストの取扱い、⚠️要確認） |
| `entity_id` | uuid nullable | → oshi_entities_master（`kind='solo'` が表す人物/対象。グループ/作品では通常NULL） |
| `display_order` | int | |
| `created_at` | timestamptz | |

> **iter168.24 推しL2必須ルール**：`groups_master.kind in ('group','work')` のL1は、推し候補として出す時に空箱にならないよう、運営マスタ上で少なくとも1件以上の `characters_master` を持つ。`kind='solo'` は人物/対象そのものをL1として選ぶためL2必須の対象外。DB制約ではなく、マスタ投入migrationと運用チェックで担保する。

### `characters_master`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `group_id` | uuid nullable | → groups_master（グループ所属の場合） |
| `genre_id` | uuid | → genres_master（グループ非所属でも参照） |
| `name` | text | "ジョングク" / "虎杖悠仁" 等 |
| `aliases` | text[] | |
| `entity_id` | uuid nullable | → oshi_entities_master（同一人物/キャラクターを別文脈と束ねる） |
| `display_order` | int | |
| `created_at` | timestamptz | |

### `goods_types_master`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | "トレカ" / "生写真" / "缶バッジ" / "アクスタ" 等 |
| `category` | text | 'card' / 'photo' / 'pin' / 'figure' / 'other' |
| `display_order` | int | |
| `created_at` | timestamptz | |

---

## 2. ユーザー・アカウント

### `users`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `email` | text unique | |
| `password_hash` | text nullable | OAuth のみの場合は NULL |
| `oauth_provider` | text nullable | 'google' / 'apple' 等 |
| `oauth_subject` | text nullable | OAuth の sub |
| `handle` | text unique | @hana_lumi 等 |
| `display_name` | text | |
| `avatar_url` | text nullable | |
| `gender` | text nullable | 任意（オンボで聞く） |
| `primary_area` | text nullable | "東京都" 等の粗い検索用エリア |
| `account_status` | text | `registered` / `verified` / `onboarding` / `active` / `suspended` / `deletion_requested` / `deleted` (09と一致) |
| `email_verified_at` | timestamptz nullable | |
| `deletion_requested_at` | timestamptz nullable | 30日猶予の起点 |
| `last_login_at` | timestamptz nullable | |
| `created_at` / `updated_at` | timestamptz | |

⚠️ 要確認：
- パスワード以外の auth method（passkey, magic link）対応するか
- `gender` を必須にするか任意にするか（マッチング条件に使う？）

### `user_mailing_addresses`（住所 / iter168.71）

郵送交換で使うユーザー設定の住所。初回リリースでは 1 ユーザー 1 住所を基本とし、設定画面から登録・更新する。本人確認は行わず、自己申告住所として扱う。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | → users。PK 相当（MVPでは1ユーザー1件） |
| `recipient_name` | text | 宛名 |
| `postal_code` | text | 郵便番号 |
| `prefecture` | text | 都道府県 |
| `city` | text | 市区町村 |
| `line1` | text | 番地・建物名など |
| `line2` | text nullable | 補足住所 |
| `phone_number` | text nullable | 任意。郵送トラブル時の補助連絡先 |
| `created_at` / `updated_at` | timestamptz | |

運用ルール：
- 打診で `exchange_method='mail'` または `exchange_method='both'` を含める場合、送信者はこの行が存在しないと送れない
- 合意後にだけ、当事者双方へ相手の住所を表示する
- 取引途中で設定画面の住所が変わっても履歴が壊れないよう、合意時点で取引側へスナップショット保存する前提

### `notifications`（通知一覧 / iter92, iter276）

アプリ内の通知一覧と未読バッジの基礎テーブル。打診、取引チャット、グルーム返信、めぐりメッセージ、スポット掲示板返信/メンションなどの通知を保存する。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | 通知を受け取るユーザー |
| `kind` | text | `proposal_received` / `groom_reply` / `meguri_board_reply` など |
| `title` / `body` | text | 通知一覧と端末通知に表示する内容 |
| `link_path` | text nullable | タップ時の遷移先 |
| `proposal_id` / `dispute_id` ほか | uuid nullable | 関連エンティティ |
| `read_at` | timestamptz nullable | nullなら未読 |
| `created_at` | timestamptz | |

iter276以降、`notifications` に行が追加されると、`notification_devices` の有効トークンへExpo Pushを送るDBトリガーが動く。

### `user_notification_settings`（通知設定 / iter93, iter276）

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | PK |
| `email_enabled` | boolean | 既存互換の通知チャネル設定 |
| `push_enabled` | boolean | iOS/Androidのモバイル通知を受け取るか |
| `created_at` / `updated_at` | timestamptz | |

アプリ内通知一覧は常時残る。`push_enabled=false` の場合は端末通知だけを止める。

### `notification_devices`（モバイル通知端末 / iter276）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → auth.users |
| `platform` | text | `ios` / `android` / `web` |
| `expo_push_token` | text | Expo Push Token |
| `app_version` | text nullable | 登録時のアプリバージョン |
| `last_seen_at` | timestamptz | 最終登録/更新時刻 |
| `revoked_at` | timestamptz nullable | ログアウト等で無効化した時刻 |
| `created_at` / `updated_at` | timestamptz | |

`unique(user_id, expo_push_token)` で同一ユーザー・同一端末の重複登録を防ぐ。`revoked_at is null` の端末だけが配送対象。

### `user_oshi`（推し登録）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `group_id` | uuid nullable | → groups_master（L1） |
| `character_id` | uuid nullable | → characters_master（L2） |
| `oshi_request_id` | uuid nullable | → oshi_requests（承認待ちの推しL1仮登録） |
| `character_request_id` | uuid nullable | → character_requests（承認待ちの推しL2仮登録） |
| `kind` | text | 'box'（箱推し）/ 'specific'（特定メンバー）/ 'multi'（複数メンバー） |
| `priority` | int | 1=メイン推し、2以降=サブ |
| `created_at` | timestamptz | |

> **iter154.33 仮登録**：推し追加リクエストを送った時点で `user_oshi.oshi_request_id` に、メンバー追加リクエストを送った時点で `user_oshi.character_request_id` に紐付けて推し設定へ暫定表示する。運営承認後は既存トリガーで master id へ連鎖変換される。

⚠️ 要確認：
- 1ユーザーが複数推し（DD）登録できる前提でOKか
- L1のみ・L2のみ・両方の組み合わせ可否

### `groom_posts`（グルーム投稿 / iter164）

iter162.49 で iOS めぐりホームに追加した、写真中心の24時間スナップ投稿。iter164 で Supabase Storage + DB 永続化へ移行し、iter165 で `groom-posts` Storage を private bucket 化した。iter168.89 以降、通常フィードは投稿時の `origin_lat/origin_lng` と閲覧者の現在地を使い、1km圏内の投稿だけを `list_groom_feed_nearby()` で返す。空配列は公開フィード扱いにしない。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users（投稿者） |
| `image_url` | text | 互換用。private Storage では path 相当または旧URLを保持し、アプリは署名URLへ差し替えて表示 |
| `image_path` | text nullable | `groom-posts` private Storage path（署名URL発行・削除用） |
| `caption` | text nullable | ひとこと（80字程度） |
| `status` | text | `draft` / `published` / `expired` / `hidden` / `archived`（09 Groom Lifecycleと一致） |
| `audience_scope` | text | `encountered_people`（めぐりあった人）を初期値にする想定 |
| `audience_user_ids` | uuid[] | 閲覧できるユーザー。`encountered_people` / `followers` では含まれるユーザーのみ表示可 |
| `place_hint` | text nullable | 「同じイベント圏内」など丸めた場所表示 |
| `area_key` | text nullable | 厳密位置ではなく、閲覧判定用の粗いエリアキー |
| `origin_lat` / `origin_lng` | double precision nullable | iter168.89 追加。投稿作成時の位置。画面には正確値を出さず、1km圏内フィード判定に使う |
| `image_transform` | jsonb | 編集画面での画像の `rotation` / `scale` / `x` / `y` |
| `text_overlays` | jsonb | テキストオーバーレイ配列 |
| `stickers` | jsonb | スタンプ等の拡張配列 |
| `doodles` | jsonb | 手描き線の配列 |
| `published_at` | timestamptz nullable | 投稿時刻 |
| `expires_at` | timestamptz nullable | 通常は `published_at + interval '24 hours'` |
| `created_at` / `updated_at` | timestamptz | |

### `groom_reactions`（グルームいいね / iter164）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `groom_post_id` | uuid | → groom_posts |
| `user_id` | uuid | → users |
| `reaction_type` | text | 初期は `like` のみ |
| `created_at` | timestamptz | |

`unique (groom_post_id, user_id, reaction_type)` で同一ユーザーの重複いいねを防ぐ。アプリ側は現在ユーザーの liked 状態だけを取得する。

### `groom_views`（グルーム閲覧済み / iter164）

| カラム | 型 | 説明 |
|---|---|---|
| `groom_post_id` | uuid | → groom_posts。PKの一部 |
| `user_id` | uuid | → users。PKの一部 |
| `viewed_at` | timestamptz | 最後に閲覧した時刻 |

丸アイコンの閲覧済みリングや、同一端末外でも既読扱いをそろえるための参加者別閲覧状態。

### `groom_replies`（グルーム返信 / iter164）

グルーム表示画面から送信したメッセージを、めぐりメッセージ導線へ接続するための追記テーブル。投稿写真・キャプションは `groom_snapshot` に保存し、投稿が期限切れになっても返信文脈を残す。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `groom_post_id` | uuid | → groom_posts |
| `sender_id` | uuid | → users |
| `recipient_id` | uuid | → users（投稿者） |
| `body` | text | 返信本文（1〜500字） |
| `groom_snapshot` | jsonb | `caption` / `image_url` / `image_path` など返信時点の投稿スナップショット。`image_path` は投稿期限切れ後も返信参加者に限って署名URL発行を許可する |
| `read_at` | timestamptz nullable | 受信者がめぐりメッセージで開いた時刻 |
| `created_at` | timestamptz | |

`notifications.kind='groom_reply'` と `notifications.groom_reply_id` を追加し、受信者に通知を残す。

### `groom_hidden_posts`（グルーム非表示 / iter165）

ユーザーごとの「このグルームを非表示」を保持する。`can_view_groom_post()` の判定に含め、非表示後はフィード・Storage署名URL発行から除外する。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | → users。PKの一部 |
| `groom_post_id` | uuid | → groom_posts。PKの一部 |
| `created_at` | timestamptz | |

### `groom_user_blocks`（めぐり文脈ユーザーブロック / iter165, iter178）

グルーム/めぐり文脈のユーザーブロック。`blocker_id` と `blocked_id` のどちらかに該当する関係では、相互にグルーム表示・めぐりメッセージ送信・スポット掲示板のスレッド/返信表示・掲示板通知を抑制する。

| カラム | 型 | 説明 |
|---|---|---|
| `blocker_id` | uuid | → users。PKの一部 |
| `blocked_id` | uuid | → users。PKの一部 |
| `created_at` | timestamptz | |

### `groom_reports`（グルーム通報 / iter165）

不適切なグルーム投稿の通報。ユーザーは自分の通報だけ参照できる。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `reporter_id` | uuid | → users |
| `groom_post_id` | uuid | → groom_posts |
| `reported_user_id` | uuid | → users |
| `reason` | text | `spam` / `harassment` / `privacy` / `other` |
| `note` | text nullable | 補足 |
| `status` | text | `open` / `reviewing` / `resolved` / `dismissed` |
| `created_at` / `updated_at` | timestamptz | |

### `meguri_messages`（めぐりあいメッセージ / iter165）

グルーム返信後の通常会話を永続化する追記型メッセージ。静的プレビュー相手などUUIDでない相手はローカルフォールバックを使うが、実ユーザー間ではDB同期される。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `sender_id` | uuid | → users |
| `recipient_id` | uuid | → users |
| `source_groom_reply_id` | uuid nullable | → groom_replies。グルーム返信から始まった会話の起点 |
| `message_type` | text | `text` / `image` |
| `body` | text nullable | 本文 |
| `image_url` | text nullable | 互換用。private Storage では path 相当 |
| `image_path` | text nullable | `meguri-message-media` private Storage path |
| `read_at` | timestamptz nullable | 受信者がスレッドを開いた時刻 |
| `created_at` | timestamptz | |

`notifications.kind='meguri_message'` と `notifications.meguri_message_id` を追加し、受信者に通知を残す。
iter168.43 以降、無料受信者に本文・画像パスを直接返さないため、通常表示は `list_meguri_messages_for_viewer()` RPC を使う。直接 `meguri_messages` をSELECTできるのは送信者本人、または `user_entitlements(feature_key='meguri_plus', active=true)` を持つ受信者に限定する。

### `meguri_board_threads`（スポット掲示板スレッド / iter168.73）

めぐり配下で使う、現地の情報共有・雑談向けのスレッド。交換成立のための打診・取引とは切り離し、現地の温度感や列状況、導線、ゆるい雑談を残す。iter168.89 以降、スレッド作成時の位置を `origin_lat/origin_lng` に保存し、閲覧は `nearby_3km`（作成地点から3km圏内）または `same_prefecture`（都道府県単位）に絞る。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `author_id` | uuid | → users |
| `title` | text | 1〜80字 |
| `body` | text | 1〜500字 |
| `image_paths` | text[] | iter176 追加。`meguri-board-media` private Storage path。最大4枚 |
| `category` | text | `question` / `info` / `chat` / `trade` / `lost_found`。iter171 追加 |
| `status` | text | `visible` / `hidden` / `archived` / `locked`。iter171 追加 |
| `is_pinned` | boolean | 運営/将来管理用の固定表示フラグ。iter171 追加 |
| `audience_scope` | text | `nearby_3km` / `same_prefecture`。`same_spot` / `global` は過去データ互換 |
| `spot_key` | text nullable | 互換用の粗いスポットキー。新規仕様では閲覧判定の主軸にしない |
| `spot_label` | text nullable | 画面表示用のスポット名 |
| `prefecture` | text nullable | 閲覧判定・表示用の都道府県。`nearby_3km` / `same_prefecture` の時は必須 |
| `origin_lat` / `origin_lng` | double precision nullable | iter168.89 追加。スレッド作成時の位置。`nearby_3km` では必須 |
| `reply_count` | integer | 返信数のサマリ |
| `reaction_count` | integer | 「参考になった」の集計。iter171 追加 |
| `bookmark_count` | integer | 保存数の集計。iter171 追加 |
| `view_count` | integer | 詳細を開いた回数の集計。iter171 追加 |
| `latest_reply_preview` | text nullable | 最新返信の先頭160字 |
| `latest_activity_at` | timestamptz | スレッド作成または最新返信時刻 |
| `created_at` / `updated_at` | timestamptz | |

> **公開範囲方針**：`nearby_3km` は現在地と `origin_lat/origin_lng` の距離でRPC判定する。`same_prefecture` はスレッド作成時の都道府県と閲覧者側の都道府県で判定する。正確な緯度経度は画面に表示しない。

> **画像添付方針（iter176）**：スレッド画像は `meguri-board-media` private Storage に保存し、DBには path のみを持つ。アプリは `list_meguri_board_threads_for_viewer()` で閲覧可能なスレッドを取得した後に署名URLを発行して表示する。

> **ブロック方針（iter178）**：`groom_user_blocks` に保存されたブロック関係はスポット掲示板にも適用する。ブロックした/された相手のスレッドは `can_view_meguri_board_thread*()` と一覧RPCで除外し、ローカル表示も即時に消す。

> **参加中判定（iter188）**：`list_meguri_board_threads_for_viewer()` は `viewer_participated` を返す。閲覧者がスレッド作成者、または `status='visible'` の返信を書いている場合に true とする。通知購読 `viewer_subscribed` とは別概念。

### `meguri_board_replies`（スポット掲示板返信 / iter168.73）

スレッド詳細で送るチャット形式の追記返信。iter172 以降、自分の返信は編集でき、削除時は物理削除ではなく `status='deleted'` としてプレースホルダ表示にする。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `thread_id` | uuid | → `meguri_board_threads` |
| `author_id` | uuid | → users |
| `body` | text | 1〜1000字 |
| `image_paths` | text[] | iter176 追加。`meguri-board-media` private Storage path。最大4枚 |
| `parent_reply_id` | uuid nullable | 引用元返信。iter173 追加 |
| `quote_author_name` | text nullable | 引用元の表示名スナップショット。iter173 追加 |
| `quote_body` | text nullable | 引用元本文の先頭160字スナップショット。iter173 追加 |
| `status` | text | `visible` / `deleted`。iter172 追加 |
| `reaction_count` | integer | 返信への「参考になった」の集計。iter171 追加 |
| `deleted_at` | timestamptz nullable | 削除済み表示に切り替えた時刻。iter172 追加 |
| `created_at` / `updated_at` | timestamptz | |

`after insert` trigger で `meguri_board_threads.reply_count / latest_reply_preview / latest_activity_at` を更新する。スレッド作成者は `status` を `locked` にして返信追加を止め、`visible` に戻して再開できる。削除は `archived` にするソフト削除。iter176以降、返信画像も `meguri-board-media` private Storage path として保存し、返信一覧RPCで閲覧可能な返信だけ署名URL化して表示する。iter178以降、`groom_user_blocks` の関係にある返信者の返信は返信一覧RPCとローカル表示から除外する。

### `meguri_board_thread_bookmarks`（スポット掲示板スレッド保存 / iter171）

| カラム | 型 | 説明 |
|---|---|---|
| `thread_id` | uuid | → `meguri_board_threads` |
| `user_id` | uuid | → users |
| `created_at` | timestamptz | |

ユーザーごとの保存状態。`thread_id,user_id` を PK とし、trigger で `bookmark_count` を同期する。

### `meguri_board_thread_reactions` / `meguri_board_reply_reactions`（スポット掲示板リアクション / iter171）

| カラム | 型 | 説明 |
|---|---|---|
| `thread_id` / `reply_id` | uuid | 対象スレッドまたは返信 |
| `user_id` | uuid | → users |
| `reaction_type` | text | MVPでは `useful` のみ |
| `created_at` | timestamptz | |

スレッド/返信への「参考になった」。各対象・ユーザー・reaction_typeで一意。trigger で `reaction_count` を同期する。

### `meguri_board_thread_reads`（スポット掲示板既読 / iter171）

| カラム | 型 | 説明 |
|---|---|---|
| `thread_id` | uuid | → `meguri_board_threads` |
| `user_id` | uuid | → users |
| `read_at` | timestamptz | 最後に詳細を開いた時刻 |

一覧の未読ドット判定に使う。詳細を開くたびに upsert し、`view_count` も増やす。

### `meguri_board_thread_subscriptions`（スポット掲示板スレッド購読 / iter174）

| カラム | 型 | 説明 |
|---|---|---|
| `thread_id` | uuid | → `meguri_board_threads` |
| `user_id` | uuid | → users |
| `notification_enabled` | boolean | 返信通知を受け取るか |
| `created_at` / `updated_at` | timestamptz | |

スレッド作成者と返信者は自動で購読ONになる。ユーザーは一覧/詳細からON/OFFを切り替えられる。購読中スレッドに自分以外が返信した時は `notifications.kind='meguri_board_reply'` を作成し、`meguri_board_thread_id` / `meguri_board_reply_id` と `link_path='/meguri-board-thread?id=...'` を保存する。返信本文に `@handle` が含まれる場合は、本人以外かつスレッドを閲覧できる対象ユーザーに `notifications.kind='meguri_board_mention'` を作成し、通常の購読返信通知とは重複させない。iter178以降、返信者と通知先が `groom_user_blocks` で相互ブロック関係にある場合は返信通知・メンション通知を作成しない。

### `meguri_board_hidden_threads` / `meguri_board_reports`（非表示・通報 / iter171）

ユーザー単位の非表示は `meguri_board_hidden_threads`、通報は `meguri_board_reports` に保存する。通報はスレッドまたは返信のどちらか一方を対象にし、運営側で `open` / `reviewing` / `resolved` / `rejected` を管理する。iter179以降、アプリ側では `reason` を `spam` / `harassment` / `privacy` / `unsafe` / `off_topic` / `other` から選ばせる。

### スポット掲示板下書き（端末内状態 / iter180）

スレッド作成中の下書きは `meguri.board.composerDrafts.v1`、返信中の下書きは `meguri.board.replyDrafts.v1` として端末内に保存する。DBテーブルは作らない。スレッド作成下書きは掲示板文脈（閲覧者・都道府県・スポット）単位、返信下書きは `thread_id` 単位で復元する。投稿または返信の成功時に該当下書きを削除し、空の下書きは保存しない。

---

## 3. 在庫・ウィッシュ

### `user_haves`（=「棚」=在庫）

iter29 で 1行=1個 の方針確定。UI で集約表示し、選択時は N 行を押さえる。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `genre_tag_id` | uuid | → genres_master（**必須**、iter24） |
| `character_id` | uuid nullable | → characters_master（iter24、新マスタ参照、表記揺れ排除） |
| `goods_type_id` | uuid | → goods_types_master（**必須**、iter24） |
| `title` | text | 旧 `genre_name`/`character_name` 由来の表示名 |
| `description` | text nullable | |
| `condition_tags` | text[] | 美品 / コーティング有 / シリアル付き 等 |
| `exchange_method` | text | 'hand'（現地交換）/ 'mail'（郵送交換）。アイテム単位の許容手段の自己申告 |
| `kind` | text | `for_trade`（譲る候補）/ `keep`（自分用キープ） |
| `status` | text | `available` / `in_negotiation` / `in_deal` / `traded`（09 Item Lifecycleと整合） |

> **🔒 制約（iter39 確定）**：`kind='keep'` のアイテムは `status='in_negotiation'` または `status='in_deal'` に**なれない**。
> `keep` を譲りたくなったら、まず `kind='for_trade'` に変更してから提案を受ける。アプリケーションレベルでバリデーション必須。
>
> **iter153 市場残数**：マイ在庫に表示する実在庫 `quantity` は、打診が `agreed` になった時点では減らさない。マッチング市場・打診作成・個別募集作成では、派生値 `market_available_qty = quantity - sum(agreed proposal の未完了承認分 qty)` を使う。取引完了承認時に初めて実在庫 `quantity` を減算する。
>
> **iter154.18 譲り済み履歴の不変性**：`status='traded'` の在庫は取引履歴の証跡として扱い、ユーザー操作による更新・削除を不可にする。画面上は詳細確認のみ、サーバーアクションでも update/delete を拒否する。

| `is_carrying` | boolean | 「今日持参する」フラグ（F2 携帯モード） |
| `carry_event_id` | uuid nullable | → events |
| `created_at` / `updated_at` | timestamptz | |

⚠️ 要確認：
- ~~`kind=keep` のアイテムは `status=in_negotiation` になり得るか~~ → ✅ **確定（iter39）：ならない（完全分離）**
- `traded` のアイテムは `kind` を保つか reset するか
- 旧 `hand_prefecture` カラムは廃止して `users.primary_area` に統合してOKか

### `user_have_images`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_have_id` | uuid | → user_haves |
| `image_url` | text | 400×400 JPEG (F1) |
| `order` | int | 表示順 |
| `created_at` | timestamptz | |

### `user_wants`（=「鏡」=ウィッシュ）

iter62（Phase A）で `exchange_type` 追加。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `genre_tag_id` | uuid | → genres_master（**必須**） |
| `character_id` | uuid nullable | → characters_master（任意、flexibility 考慮） |
| `goods_type_id` | uuid nullable | → goods_types_master（任意、flexibility 考慮） |
| `title` | text | |
| `description` | text nullable | |
| `flexibility` | int | 1（厳格）〜 5（緩い）。character/goods_type の照合スキップ条件 |
| `priority` | int | 1（高）〜 5（低）。マッチング表示順に使用 |
| `exchange_type` | text default `any` | iter62、`same_kind` / `cross_kind` / `any`。**自己申告タグ**、システム判定なし（カードに chip 表示のみ） |
| `status` | text | `active`（探し中）/ `matched`（マッチあり）/ `in_negotiation`（打診中）/ `achieved`（達成）（09 Wish Lifecycleと整合） |
| `created_at` / `updated_at` | timestamptz | |

⚠️ 要確認：
- `flexibility` の具体的な意味（1=完全一致のみ、5=ジャンル一致だけでOK 等）の定義
- `matched` 状態の継続性（09 未確定項目#5 と紐付け）

### `listings`（個別募集）— iter64 → iter67.3 → iter67.4 で「譲 1 バンドル + 求 N 選択肢」へ

UI 表記は **「個別募集」**。`listing` という英語は出さない（10_glossary §A-7）。

iter67.4 で求側を **「複数選択肢」モデル** に再設計。listings は譲側情報のみ持ち、求側は別テーブル `listing_wish_options` に分離。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users（オーナー） |
| `have_ids` | uuid[] | → goods_inventory（譲側、`kind=for_trade`） |
| `have_qtys` | int[] | 各譲の数量（各 1〜99） |
| `have_logic` | text | `'and'`（全部セット）/ `'or'`（いずれか）、default `'and'` |
| `have_group_id` | uuid | trigger で全 haves から自動算出（同一性検証） |
| `have_goods_type_id` | uuid | 同上 |
| `status` | text | `active` / `paused` / `matched` / `closed` |
| `note` | text nullable | |
| `created_at` / `updated_at` | timestamptz | |

制約：
- have_ids 全件が **同 group + 同 goods_type**（trigger 検証）
- have_qtys 各値 1〜99（trigger）
- have_ids 全件が listing 所有者の `kind=for_trade` インベントリ
- iter153: 譲アイテムが削除または非 active 化された場合、開いている個別募集の `have_ids` / `have_qtys` からそのアイテムを除外する。残り譲が 0 件なら `status='closed'`。
- iter153: マッチング市場では `have_qtys` が市場残数を超える個別募集条件は候補から外す（OR 条件は残数のある譲だけに縮退、AND 条件はいずれか不足したら非表示）。

廃止カラム（iter67.4 で削除）：`wish_ids` / `wish_qtys` / `wish_logic`

### `listing_wish_options`（個別募集の求側選択肢）— 新規（iter67.4）

1 listing につき 1〜5 件。選択肢間は **OR**（相手がいずれか 1 つを選んで取引）。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `listing_id` | uuid | → listings（cascade） |
| `position` | int | 1〜5、表示順（listing_id 内で unique） |
| `wish_ids` | uuid[] | → goods_inventory（求側、`kind=wanted`） |
| `wish_qtys` | int[] | 各 wish の数量（各 1〜99） |
| `logic` | text | `'and'`（全部セット）/ `'or'`（いずれか）、default `'or'` |
| `exchange_type` | text | `'same_kind'` / `'cross_kind'` / `'any'`、default `'any'` |
| `is_cash_offer` | bool | true なら定価交換選択肢（マッチング演算対象外） |
| `cash_amount` | int nullable | is_cash_offer=true の時の希望金額（1〜9,999,999） |
| `wish_group_id` | uuid nullable | trigger で自動算出（is_cash_offer=true は無視） |
| `wish_goods_type_id` | uuid nullable | 同上 |
| `created_at` / `updated_at` | timestamptz | |

制約：
- 1 listing につき最大 5 選択肢（trigger）
- 通常選択肢：wish_ids/qtys 長さ一致、qty 1〜99、wish 全件が listing 所有者の `kind=wanted`
- 通常選択肢：wish_ids 全件が **同 group + 同 goods_type**（trigger）
- **OR × OR ガード**：listing.have_logic='or' AND option.logic='or' AND 両側 ≥2 アイテム は禁止
- 定価交換選択肢：wish_ids/qtys 空、cash_amount 必須

RLS：
- listing 所有者は自身の listing 経由オプションを CRUD
- listing.status='active' の listing 経由オプションは誰でも SELECT 可（マッチング用）

### `user_local_mode_settings`（現地モード設定）— 新規（iter63 / Phase B）

ユーザーの「現地交換モード」永続化用。1 ユーザー 1 行。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid PK | → users |
| `enabled` | bool default false | 現地モード ON/OFF |
| `aw_id` | uuid nullable | → availability_windows（使う AW） |
| `radius_m` | int default 500 | 半径（前回値） |
| `selected_carrying_ids` | uuid[] | 選択中の携帯グッズの goods_inventory.id 配列 |
| `selected_wish_ids` | uuid[] | 選択中の wish の user_wants.id 配列 |
| `last_lat` / `last_lng` | numeric(9,6) | 最終 GPS 位置（モード ON 時に上書き） |
| `updated_at` | timestamptz | |

→ 位置情報のみ「ON にした瞬間に GPS で上書き」、その他は前回値を保持。
   一括リセットボタンは `selected_carrying_ids = '{}'` / `selected_wish_ids = '{}'` で実装。

---

## 4. 活動予定（AW）・イベント

### `availability_windows`（=AW）

iter33 で AW自動登録機能追加（C-0 待ち合わせタブから）。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `start_at` / `end_at` | timestamptz | 時間範囲 |
| `lat` / `lng` | double precision | 中心点 |
| `radius_m` | int | デフォルト 500m |
| `place_name` | text nullable | "ナゴヤドーム前矢田駅" 等の表示用 |
| `event_id` | uuid nullable | → events |
| `note` | text nullable | |
| `status` | text | `draft` / `active` / `paused` / `ended` / `archived`（09 AW Lifecycleと一致） |
| `created_via` | text | `manual`（AW画面で作成）/ `auto_from_proposal`（iter33、C-0で「AWに自動登録」チェック） |
| `created_from_proposal_id` | uuid nullable | → proposals（auto_from_proposalの場合） |
| `created_at` / `updated_at` | timestamptz | |

⚠️ 要確認：
- `ended` から `archived` への自動遷移時間（09 未確定項目#2）
- `auto_from_proposal` で作られた AW は、対応する取引が cancel/dispute になったら削除？保持？

### `events`（公演／物販イベントタグ）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | "TWICE 名古屋ドーム公演" 等 |
| `start_at` / `end_at` | timestamptz | |
| `lat` / `lng` | double precision | |
| `venue_name` | text | "ナゴヤドーム" |
| `genre_id` | uuid | → genres_master |
| `group_id` | uuid nullable | → groups_master |
| `created_by` | uuid | → users（ユーザー作成タグ） |
| `is_verified` | boolean | 運営承認済か（重複名寄せ後） |
| `created_at` | timestamptz | |

⚠️ 要確認：
- ユーザー作成タグの即公開 vs 運営承認後公開
- 重複検出（同名・同会場・同時間）の自動マージ運用

### `schedules`（個人スケジュール）— 新規（iter67）

AW とは **別エンティティ**。AW = 「この時間ここに**いる**」（マッチング演算用）／ schedules = 「この時間 **忙しい**」（打診相手にだけ任意公開する個人予定）。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `title` | text | 予定名（例「出張」「友人ランチ」） |
| `place_name` | text nullable | 任意の場所テキスト（例「横浜アリーナ 北口」）。地図座標は持たせない |
| `start_at` | timestamptz | 開始 |
| `end_at` | timestamptz | 終了（CHECK: end_at > start_at） |
| `all_day` | bool default false | 終日フラグ |
| `note` | text nullable | 補足メモ（500 文字まで） |
| `created_at` / `updated_at` | timestamptz | |

RLS：
- 自分のスケジュールは自由に SELECT/INSERT/UPDATE/DELETE
- `proposals.expose_calendar = true` かつ自分が `sender_id` の打診相手 (`receiver_id`) は SELECT 可（取引完了 status=`agreed`/`rejected`/`expired` で閲覧停止）
- iter168.97: 打診時の待ち合わせ候補登録画面と取引チャットのスケジュール重ね見で、`place_name` を表示する

⚠️ 要確認：
- 招待受諾型のスケジュール（複数人参加）を将来サポートするか
- 繰返し予定（毎週月曜など）を持たせるか

---

## 5. 打診（Proposal）・ネゴ・メッセージ

### `proposals`（打診）

iter28（match_type）/ iter29（数量）/ iter30（7日期限）/ iter32（合意状態）/ iter33（meetup）反映。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `sender_id` | uuid | → users（打診送信者） |
| `receiver_id` | uuid | → users（受信者） |
| `match_type` | text | `perfect`（完全マッチ）/ `forward`（私が欲しい譲を持つ人）/ `backward`（私の譲が欲しい人）（iter28） |
| `sender_have_ids` | uuid[] | 送信者が出す `user_haves` IDs |
| `sender_have_qtys` | int[] | 各 IDの選択数（iter29、長さは sender_have_ids と一致） |
| `receiver_have_ids` | uuid[] | 受信者が出す `user_haves` IDs |
| `receiver_have_qtys` | int[] | 各 IDの選択数 |
| `message` | text | |
| `exchange_method` | text | `hand` / `mail` / `both`。提案単位の受け渡し方法 |
| `option_tags` | text[] default `{}` | iter170、打診条件タグ。例：即日発送 / 同日発送 / 終演後OK |
| `status` | text | `draft` / `sent` / `negotiating` / `agreement_one_side` / `agreed` / `rejected` / `expired`（09と一致） |
| `agreed_by_sender` | boolean default false | iter32、agreement_one_side 判定用 |
| `agreed_by_receiver` | boolean default false | iter32 |
| `last_action_at` | timestamptz | iter30、7日カウント起点 |
| `expires_at` | timestamptz | iter30、自動計算（last_action_at + 7days） |
| `extension_count` | int default 0 | iter30、+7日延長回数 |
| `rejected_template` | text nullable | 旧定型文選択 |
| `message_tone` | text | iter67、`standard`/`casual`/`polite`（メッセージのトーン選択を記録、デフォルト 'standard'） |
| ~~`meetup_type`~~ | — | **iter67.1 で廃止**。「いますぐ/日時指定」分岐を統一フォームに置換 |
| ~~`meetup_now_minutes`~~ | — | **iter67.1 で廃止** |
| ~~`meetup_scheduled_aw_id`~~ | — | **iter67 で廃止**。AW はマッチング演算専用に分離 |
| ~~`meetup_scheduled_custom`~~ | — | **iter67.1 で廃止**。下記 5 列に分解 |
| `meetup_start_at` | timestamptz nullable | iter67.1、待ち合わせ開始時刻（`exchange_method='hand'` / `both` で必須） |
| `meetup_end_at` | timestamptz nullable | iter67.1、待ち合わせ終了時刻（CHECK: end > start） |
| `meetup_place_name` | text(≤200) nullable | iter67.1、場所名（駅・施設名など） |
| `meetup_lat` | numeric(9,6) nullable | iter67.1、緯度（地図上の位置） |
| `meetup_lng` | numeric(9,6) nullable | iter67.1、経度 |
| `meetup_candidates` | jsonb default `[]` | iter154.34、交換できる候補（最大3件）。各要素は `{ startAt, endAt, placeName, lat, lng, mode }`。候補1を既存 `meetup_*` 5列へミラーして旧画面・取引チャットと互換 |
| `sender_mailing_address` | jsonb nullable | iter168.74、`exchange_method='mail'` / `both` で合意成立した時点の送信者住所スナップショット |
| `receiver_mailing_address` | jsonb nullable | iter168.74、`exchange_method='mail'` / `both` で合意成立した時点の受信者住所スナップショット |
| `expose_calendar` | bool default false | iter67 で再定義：送信者が自分の **個人スケジュール（schedules）** を相手に公開する ON/OFF。受信側は受信表示画面で送信者の予定を見られる（取引完了で自動的に RLS 不可）。AW は対象外 |
| `listing_id` | uuid nullable | iter64、個別募集 (`listings`) 経由の打診ならその id。直接打診なら null |
| `cash_offer` | bool default false | iter67.7、定価交換打診なら true（receiver_have_ids 空 + cash_amount 必須） |
| `cash_amount` | int nullable | iter67.7、定価交換金額（1〜9,999,999）。cash_offer=true のときのみ |
| `created_at` / `updated_at` | timestamptz | |

CHECK 制約 `proposals_meetup_required`（iter168.82 更新）：`exchange_method='hand'` または `exchange_method='both'` かつ `status!='draft'` の時だけ 5 列すべて NOT NULL かつ `meetup_end_at > meetup_start_at`。`mail` の時は待ち合わせ列を必須にしない。
CHECK 制約 `proposals_meetup_candidates_array`（iter154.34）：`meetup_candidates` は JSON 配列、最大3件。

iter168.97 追加運用：
- `exchange_method='both'` の打診に合意する時は、合意前に `hand` または `mail` のどちらか1つへ固定して保存する。
- 現地交換で `meetup_candidates` が複数ある場合は、合意前に1件を選択し、その候補を既存 `meetup_*` 列へミラーする。
- 条件変更の再打診は元 Proposal を直接更新せず、元の提示物/受け取り候補/交換手段/待ち合わせ候補をコピーした新規打診作成として扱う。

派生ルール：
- iter153: `status='agreed'` の proposal は、`sender_have_ids` / `receiver_have_ids` と各 qty を市場残数から差し引く。ただし `approved_by_sender` / `approved_by_receiver` が true の側は、取引完了承認処理で実在庫が既に減算されているため二重控除しない。
- iter153: `sent` / `negotiating` / `agreement_one_side` は在庫確保前の状態として扱い、市場残数からは差し引かない。`agreed` へ遷移する直前にキャパ超過を検証する。
- iter168.74/168.82: `exchange_method='mail'` または `exchange_method='both'` の時、送信者は打診送信前に `user_mailing_addresses` の登録が必須。受信者も合意前に住所登録が必要で、最終合意時に双方の住所スナップショットを `proposals.sender_mailing_address / receiver_mailing_address` へ固定し、当事者以外には返さない。

⚠️ 要確認：
- ネゴ中の提案修正で `last_action_at` リセットするか（09 未確定項目#1）
- `cancelled` 状態を追加するか（送信前に取消・送信後に sender が取消等）
- ~~`meetup_scheduled_custom` を JSONB か別テーブル `proposal_meetups` か~~ → ✅ **確定（iter39）：JSONB（MVP段階）**
- `agreement_one_side` 中の提案修正で双方の `agreed_by_*` を false にリセットするルール

### `proposal_revisions`（提案修正履歴）— 新規（iter30）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `proposal_id` | uuid | → proposals |
| `revised_by` | uuid | → users |
| `snapshot` | jsonb | 修正時点のスナップショット（sender_have_ids, receiver_have_ids, meetup_*, message） |
| `revised_at` | timestamptz | |

⚠️ 要確認：
- 履歴保存の粒度（毎修正 全部 vs 直近N件のみ）
- 表示用 vs 法的記録 vs ヒストリ機能のどれが目的か

### `messages`（取引チャット・ネゴチャット）

iter34 で `message_type` 拡張。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `proposal_id` | uuid | → proposals（合意後も同じ ID で継続） |
| `sender_id` | uuid | → users |
| `message_type` | text | `text` / `image` / `outfit_photo` / `location_share` / `system`（iter34） |
| `body` | text nullable | text/system 用 |
| `attachment_url` | text nullable | image / outfit_photo 用 |
| `metadata` | jsonb nullable | location_share: `{lat, lng, accuracy_m, captured_at}`／system: `{event_type, payload}` |
| `created_at` | timestamptz | |

⚠️ 要確認：
- `outfit_photo` を `messages` に格納するか専用テーブル `deal_outfit_photos` にするか
- system message の `event_type` の値リスト確定（'arrival', 'agreement_one_side', 'evidence_captured' 等）

### `proposal_read_states`（取引チャット読了状態 / iter162.83）

`messages` は追記型のまま維持し、参加者がその proposal のチャットをどこまで開いたかだけを別テーブルで管理する。送信者側のUIでは、相手ユーザーの `last_read_at` が自分のメッセージ `created_at` 以降の時だけ「既読」を表示する。

| カラム | 型 | 説明 |
|---|---|---|
| `proposal_id` | uuid | → proposals。PKの一部 |
| `user_id` | uuid | → users/auth.users。PKの一部 |
| `last_read_at` | timestamptz | その参加者が最後に開いたメッセージ時刻 |
| `updated_at` | timestamptz | 読了位置を更新した時刻 |

制約・RLS：
- primary key: `(proposal_id, user_id)`
- SELECT: proposal の sender / receiver のみ
- INSERT/UPDATE: proposal 参加者が自分の `user_id` 行のみ
- `messages` 本体は更新しない。既読は `proposal_read_states` の派生表示として扱う。

---

## 6. 取引（Deal）・到着・服装・位置共有

### `deals`（旧 `exchanges` をリネーム、用語集と一致）

iter34 で到着ステータス・サブステート追加。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `proposal_id` | uuid | → proposals（agreed 状態の Proposal から1:1で生成） |
| `participants` | uuid[] | 参加者（MVPは2名、user_id配列） |
| `status` | text | `agreed` / `on_the_way` / `arrived_one` / `arrived_both` / `evidence_captured` / `approved` / `rated` / `disputed` / `cancelled`（09 Deal Lifecycleと一致） |
| `evidence_image_url` | text nullable | 証跡撮影画像（C-3①、左=相手 / 右=自分 固定） |
| `sender_approved` | boolean default false | C-3②両者承認 |
| `receiver_approved` | boolean default false | |
| `actual_meet_lat` | double precision nullable | 実際の合流位置（提案時meetupと異なる場合あり） |
| `actual_meet_lng` | double precision nullable | |
| `cancelled_reason` | text nullable | キャンセル理由（'late_30min', 'mutual', 'system' 等） |
| `cancelled_by` | uuid nullable | → users（キャンセル発動者） |
| `completed_at` | timestamptz nullable | rated に到達した時刻 |
| `created_at` / `updated_at` | timestamptz | |

両者承認で `evidence_captured` → `approved`、両者評価で `approved` → `rated`、`completed_at` セット、関連 `user_haves.status` を `traded` に更新。

⚠️ 要確認：
- `cancelled_reason` の値リスト確定
- `disputed` 解決時に `rated` に戻るか、別の終了状態にするか

### `deal_arrivals`（到着ステータス追跡）— 新規（iter34、iter39 で MVP 範囲確定）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `deal_id` | uuid | → deals |
| `user_id` | uuid | → users |
| `arrived_at` | timestamptz | |
| `arrival_lat` / `arrival_lng` | double precision nullable | GPS 取得した到着位置（任意・将来用） |
| `detection_method` | text | **MVP は `manual` のみ**（ユーザー報告）。Post-MVP で `qr_scan`（本人確認時自動）/ `gps_auto`（位置自動検知）を検討 |
| `created_at` | timestamptz | |

> **🔒 設計確定（iter39）：MVP は手動報告のみ**
>
> - C-2 取引チャットに「会場到着」ボタンを置き、ユーザーがタップで到着扱い
> - `detection_method='manual'` 固定
> - **GPS 自動検知は Post-MVP**（プライバシー観点・電池消費・誤検知のため MVP 対象外）
> - **QR スキャン連動も Post-MVP**（実装軽いが、まずは手動で十分）
> - DBスキーマは将来対応も見越した設計（`arrival_lat/lng`, `detection_method` カラムは残す）

⚠️ 要確認：
- ~~到着検知の仕組み~~ → ✅ **確定（iter39）：MVPは手動のみ**
- 1 deal × 1 user で1レコード前提か、再到着（一度退場→戻る）も記録するか

### `deal_outfit_photos`（服装写真）— 新規（iter34、iter39 で2層構成確定）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `deal_id` | uuid | → deals |
| `user_id` | uuid | → users |
| `image_url` | text | |
| `shared_at` | timestamptz | |
| `created_at` | timestamptz | |

> **🔒 設計確定（iter39）：2層構成で運用**
>
> - **`deal_outfit_photos`（専用テーブル）**：「最新の服装写真」を deal_id × user_id で一意に保持。C-2 ヘッダーの「あなた:✓ / 相手:未シェア」ステータス取得用。1人が複数回更新する場合は INSERT ＋ ORDER BY DESC LIMIT 1 で最新を取得（履歴も保持）。
> - **`messages.message_type='system'`**：「@xxx が服装写真を共有しました」をシステムメッセージとしてチャットタイムラインに流す。`metadata.event_type='outfit_shared'` を設定。
>
> 両方使うことで「最新ステータスの高速取得」と「タイムラインの足跡」を両立。

---

## 7. 評価・通報・断った記録

### `user_evaluations`（評価）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `deal_id` | uuid | → deals（旧 `exchange_id`） |
| `evaluator_id` | uuid | → users |
| `evaluated_id` | uuid | → users |
| `rating` | int | 1-5 |
| `comment` | text nullable | |
| `punctuality_rating` | int nullable | 1-5（時間厳守度、⚠️要確認） |
| `item_condition_rating` | int nullable | 1-5（実物状態の一致度、⚠️要確認） |
| `communication_rating` | int nullable | 1-5（メッセージ対応、⚠️要確認） |
| `created_at` | timestamptz | |

集計はビューで：合計★平均、取引回数、無断キャンセル数。

⚠️ 要確認：
- 細分化評価（punctuality/item_condition/communication）を MVPで採用するか後フェーズか

### `rejected_partners`（断った記録）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users（自分） |
| `partner_id` | uuid | → users（相手） |
| `proposal_id` | uuid | → proposals |
| `created_at` | timestamptz | |

片方向記憶。重複打診の自動フィルタに使用。

### `reports`（通報）— 新規

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `reporter_id` | uuid | → users |
| `target_user_id` | uuid nullable | → users |
| `target_proposal_id` | uuid nullable | → proposals |
| `target_message_id` | uuid nullable | → messages |
| `category` | text | 'spam', 'harassment', 'fake_item', 'no_show', 'other' |
| `description` | text | |
| `evidence_urls` | text[] | スクショ等 |
| `status` | text | 'open', 'reviewing', 'resolved', 'dismissed' |
| `resolved_at` | timestamptz nullable | |
| `created_at` | timestamptz | |

---

## 8. Dispute（異議申し立て）

### `disputes`

iter12-18 の D-flow に対応するスキーマ（旧版未定義だったので新規追加）。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `deal_id` | uuid | → deals |
| `filed_by` | uuid | → users |
| `category` | text | `no_show` / `late` / `mismatch` / `damage` / `other`（iter12 の5種） |
| `description` | text | |
| `evidence_urls` | text[] | |
| `status` | text | `filed` / `submitted` / `reply_window` / `reply_received` / `arbitration` / `resolved` / `withdrawn`（09と一致） |
| `ticket_number` | text unique | iter16、受付番号（"D-2026-0001" 等） |
| `reply_deadline_at` | timestamptz | iter15、反論機会期限（24h） |
| `arbitration_deadline_at` | timestamptz | iter13、SLA（同日4h／それ以外24h、カテゴリ依存） |
| `resolution` | jsonb nullable | 仲裁結果（**iter39 で構造確定** → 下記） |
| `resolved_at` | timestamptz nullable | |
| `created_at` / `updated_at` | timestamptz | |

> **🔒 `resolution` JSONB の構造（iter39 確定）**
>
> ```json
> {
>   "decision": "sender_fault | receiver_fault | mutual_fault | no_fault | cant_determine",
>   "reason": "判定理由（テキスト、運営記入）",
>   "penalty_for_sender": "none | warning | temp_suspend | permanent_suspend",
>   "penalty_for_receiver": "none | warning | temp_suspend | permanent_suspend",
>   "next_steps": "推奨アクション（テキスト、当事者向けメッセージ）"
> }
> ```
>
> **`decision` の意味**：
> - `sender_fault` … 提案者側に非
> - `receiver_fault` … 受諾者側に非
> - `mutual_fault` … 双方に非
> - `no_fault` … 双方に非なし（コミュ不足等）
> - `cant_determine` … 判定不可（証拠不十分）
>
> **`penalty_for_*` の意味**：
> - `none` … ペナルティなし
> - `warning` … 警告（マイページに記録、累積で次段階へ）
> - `temp_suspend` … 一時停止（30日アカウント停止等、運営判断）
> - `permanent_suspend` … 永久停止
>
> 当事者へのペナルティ通知は別途 `reports`/`disputes` のステータス変化と連動。

⚠️ 要確認：
- 反論機会期限が 24h or 4h はカテゴリで変わるか（09 未確定項目#3）
- 仲裁SLA超過時のエスカレーションフロー
- ~~`resolution.decision` の値リスト~~ → ✅ **確定（iter39）：上記5値**

### `dispute_replies`（反論）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `dispute_id` | uuid | → disputes |
| `replied_by` | uuid | → users |
| `message` | text | |
| `evidence_urls` | text[] | |
| `created_at` | timestamptz | |

---

## 9. マネタイズ

iter45 で追加。`notes/16_monetization.md` の戦略に対応するテーブル群。

### `subscriptions`（Premium 会員 / めぐりPlus サブスクリプション）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `plan_type` | text | `premium_monthly` / `premium_yearly` / `meguri_plus_monthly` / `monthly` / `yearly` |
| `status` | text | `incomplete` / `incomplete_expired` / `trialing` / `active` / `past_due` / `cancelled` / `canceled` / `unpaid` / `expired` |
| `started_at` | timestamptz | 開始日時 |
| `current_period_end` | timestamptz | 現契約期間の終了 |
| `cancelled_at` | timestamptz nullable | 解約申請日時（期間終了まで有効） |
| `transaction_provider` | text | `stripe` / `apple` / `google` |
| `transaction_provider_subscription_id` | text | プロバイダー側のサブスクID |
| `created_at` / `updated_at` | timestamptz | |

⚠️ 要確認：
- 課金プロバイダー選定（Stripe / Apple In-App / Google Play）
- 払い戻しポリシー（年額中途解約）

> iter166: 実装上のPremium判定は `subscriptions` の生ステータスではなく、Stripe webhook/管理者操作で集約された `user_entitlements(feature_key='premium', active=true)` を参照する。
> `subscriptions` 本体はプロバイダーIDを含むためクライアントへ直接SELECTさせず、ユーザー向け表示は server route で必要列だけ返す。
> iter168.43: めぐりPlusは Premium とは別権限として `user_entitlements(feature_key='meguri_plus', active=true)` を参照する。`meguri_plus_monthly` の webhook は `meguri_plus` 権限を更新する。

### `boosts`（ブースト残数管理）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `granted_at` | timestamptz | 取得時刻 |
| `granted_via` | text | `purchase` / `premium_grant` |
| `consumed_at` | timestamptz nullable | 発動時刻（NULL なら未使用） |
| `expires_at` | timestamptz nullable | 発動から24h後（活動終了時刻） |
| `target_type` | text nullable | 発動時：`proposal` / `match_view` / `chat`（iter45 で対象3種、Phase β で要検証） |
| `target_id` | uuid nullable | 発動時：対象オブジェクトID |
| `transaction_id` | uuid nullable | → transactions（購入由来の場合） |
| `created_at` | timestamptz | |

検索インデックス：
- `(user_id, consumed_at)` で残数取得
- `(consumed_at, expires_at)` で active boost のクリーンアップ

⚠️ 要確認：
- 払い戻しポリシー（未使用ブースト）
- 1日2個発動上限の実装方針

### `transactions`（決済履歴）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `kind` | text | `boost_pack` / `subscription_initial` / `subscription_renewal` |
| `amount_jpy` | int | 金額（円） |
| `quantity` | int nullable | ブーストパック時の個数（1/5/10） |
| `provider` | text | `stripe` / `apple` / `google` |
| `provider_transaction_id` | text | プロバイダーID（refund 等で参照） |
| `status` | text | `pending` / `succeeded` / `failed` / `refunded` |
| `paid_at` | timestamptz nullable | 支払完了日時 |
| `refunded_at` | timestamptz nullable | 返金日時 |
| `created_at` | timestamptz | |

### `ad_overrides`（広告非表示の管理）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `override_until` | timestamptz | 広告非表示の終了時刻 |
| `override_reason` | text | `boost` / `premium` |
| `boost_id` | uuid nullable | → boosts（boost発動由来の場合） |
| `subscription_id` | uuid nullable | → subscriptions（Premium 由来の場合） |
| `created_at` | timestamptz | |

> **🔒 設計（iter45 確定）**
>
> - Premium 会員は `subscription.status='active'` の間 `ad_overrides` レコードを継続的に維持（バックグラウンドジョブで extend）
> - ブースト発動時は `consumed_at = NOW()`、`expires_at = NOW() + 24h` で `ad_overrides` レコードを INSERT
> - 広告表示判定：`SELECT 1 FROM ad_overrides WHERE user_id = X AND override_until > NOW() LIMIT 1`

### 関連 ビュー（推奨）

```sql
-- ユーザーごとのブースト残数
CREATE VIEW user_boost_remaining AS
SELECT user_id, COUNT(*) AS remaining
FROM boosts
WHERE consumed_at IS NULL
GROUP BY user_id;

-- アクティブな Premium 会員
CREATE VIEW active_premium_users AS
SELECT user_id, plan_type, current_period_end
FROM subscriptions
WHERE status = 'active' AND current_period_end > NOW();
```

### 広告配信関連（実装時詳細）

広告配信は外部サービス（AdMob / 自社）に委ねるため、Megrum 側DBには配信履歴のみ記録：

```
ad_impressions table（オプション、Post-MVP で詳細分析用）:
- id (uuid)
- user_id (uuid → users)
- screen_id (text)         -- 'HOM-main' / 'SCH-main' 等
- ad_type ('native' | 'banner')
- ad_provider ('admob' | 'direct')
- ad_id (string)           -- 外部広告ID
- shown_at (timestamptz)
- clicked_at (timestamptz nullable)
```

---

## 10. 管理者・権限管理

### `admin_roles`

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid PK | → users。管理者対象ユーザー |
| `role` | text | `owner` / `support` / `trust_safety` / `billing` / `viewer` |
| `permissions` | text[] | `users.read` 等。`*` は全権限 |
| `status` | text | `active` / `disabled` |
| `requires_mfa` | boolean | true の場合、AAL2 セッションのみ管理者ページへ入れる |
| `created_by` | uuid nullable | 付与した管理者 |
| `created_at` / `updated_at` | timestamptz | |

RLS:
- SELECT: 自分の管理者レコード、または `roles.read` 権限を持つ管理者のみ
- INSERT/UPDATE/DELETE: クライアントからは許可しない。管理者Server Actionが service role で更新し、必ず `admin_audit_logs` に記録する。

### `admin_audit_logs`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `actor_user_id` | uuid nullable | 実行者。system/webhook は NULL |
| `action` | text | `user.account_status.update` 等 |
| `target_type` | text | `user` / `admin_role` / `user_entitlement` / `subscription` 等 |
| `target_id` | text nullable | 対象ID |
| `reason` | text nullable | 管理者が入力した理由 |
| `before_state` / `after_state` | jsonb nullable | 変更前後のスナップショット |
| `request_ip` / `user_agent` | text nullable | 監査補助情報 |
| `metadata` | jsonb | 追加情報 |
| `created_at` | timestamptz | |

### `user_entitlements`

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid PK | → users |
| `feature_key` | text PK | `premium` / `meguri_plus` 等 |
| `active` | boolean | 現在有効か |
| `source` | text | `subscription` / `manual_override` / `system` / `purchase` |
| `subscription_id` | uuid nullable | → subscriptions |
| `override_id` | uuid nullable | → plan_overrides |
| `granted_at` | timestamptz | 付与日時 |
| `expires_at` | timestamptz nullable | 有効期限 |
| `metadata` | jsonb | 付与元補足 |
| `updated_at` | timestamptz | |

### `plan_overrides`

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `feature_key` | text | `premium` 等 |
| `active` | boolean | true=付与、false=停止 |
| `reason` | text | 管理者入力理由 |
| `starts_at` / `expires_at` | timestamptz | 有効期間 |
| `created_by` | uuid nullable | 管理者 |
| `revoked_at` / `revoked_by` | timestamptz / uuid nullable | 取消情報 |
| `created_at` | timestamptz | |

### `stripe_webhook_events`

| カラム | 型 | 説明 |
|---|---|---|
| `event_id` | text PK | Stripe event id。冪等性キー |
| `event_type` | text | `customer.subscription.updated` 等 |
| `status` | text | `processing` / `processed` / `failed` / `ignored` |
| `payload` | jsonb | 受信payload |
| `processed_at` | timestamptz nullable | 処理時刻 |
| `last_error` | text nullable | 失敗理由 |
| `created_at` | timestamptz | |

## 11. マッチング計算ロジック

### 既存ロジック（user_haves × user_wants）

- `genre_tag_id` 完全一致（必須）
- `character_id` 照合（want側 NULL or flexibility 高 ならスキップ）
- `goods_type_id` 照合（want側 NULL or flexibility 高 ならスキップ）

### 追加ロジック（iter後）

- **完全マッチ**：双方の haves と wants が両方向で一致 → `match_type='perfect'`
- **forward マッチ**：私の wants と相手の haves のみ一致（私の haves は不問）→ `match_type='forward'`
- **backward マッチ**：相手の wants と私の haves のみ一致（相手の haves は不問）→ `match_type='backward'`
- **AW交差**：`availability_windows` の時空交差（lat/lng/start_at/end_at）で重み加算
- **携帯グッズ**：`is_carrying=true` のみを完全マッチタブで対象（`carry_event_id` で絞り込み可）
- **「断った」フィルタ**：`rejected_partners` 既登録ペアを除外
- **flexibility**：want側の flexibility に応じて character_id / goods_type_id の照合をスキップ

### 計算タイミング

- **バッチ**：定期計算（夜間など、低頻度）
- **オンデマンド**：ユーザーがタブを開いたときに最新計算
- **リアルタイム**：完全マッチ発見時のみ即時通知（MVPではここのみ通知）

### `search_query_logs`（検索実績ログ / iter168.90）

ホーム右下の検索画面で、固定サンプルではなく実際の検索実績から「人気の検索」を表示するためのログ。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid nullable | → users。削除時はNULL |
| `term` | text | ユーザーが確定実行した検索語。1〜80文字 |
| `normalized_term` | text | NFKC + lowercase + 空白正規化済みの集計キー |
| `result_count` | integer | 検索実行時のヒット件数 |
| `created_at` | timestamptz | 検索実行日時 |

RPC:
- `record_search_query(p_query, p_result_count)`：検索確定時に実績を記録する。
- `get_popular_search_terms(p_limit)`：直近30日の検索実績から人気検索を返す。

検索結果分類:
- `matched`：検索ヒットした相手の譲が自分のwishに合い、相手も自分の譲候補を求めている。
- `possible`：自分のwishまたは相手のwishのどちらか一方に合う。
- `none`：検索にはヒットしたが、現時点の交換条件には合わない。

⚠️ 要確認：
- バッチ頻度（毎日 / 6h おき / 1h おき）
- リアルタイム通知のスロットル（同じユーザーから1日N回まで等）

---

## 12. ⚠️ 未確定項目

実装着手前にユーザーと擦り合わせる項目。`09_state_machines.md` の「未確定・要確認項目」表とも連携。

### ✅ iter39 で確定済（5件）

| # | カテゴリ | 項目 | 確定内容 |
|---|---|---|---|
| 3 | proposals | `meetup_scheduled_custom` を JSONB か別テーブルか | **JSONB（MVP段階）** |
| 5 | user_haves | `kind=keep` のアイテムは `status=in_negotiation` になり得るか | **完全分離・ならない** |
| 17 | messages | `outfit_photo` を専用テーブルか messages か | **両方（専用テーブル＋system message）** |
| 21 | deal_arrivals | 到着検知の仕組み | **手動のみ（MVP）。QR/GPSは Post-MVP** |
| 26 | disputes | `resolution.decision` 値リスト | **5値 + penalty 4段階 + reason/next_steps** |

### 未確定（残25件）

| # | カテゴリ | 項目 | 影響範囲 |
|---|---|---|---|
| 1 | proposals | ネゴ中の提案修正で `last_action_at` リセットするか | 7日期限のUX |
| 2 | proposals | `cancelled` 状態の追加可否（送信前取消等） | 状態数 |
| 4 | proposals | `agreement_one_side` 中の提案修正で `agreed_by_*` を reset するか | UX設計 |
| 6 | user_haves | `traded` のアイテムは `kind` を保持か reset するか | 履歴の見え方 |
| 7 | user_haves | 旧 `hand_prefecture` を `users.primary_area` に統合してOKか | スキーマ移行 |
| 8 | users | `gender` を必須にするか任意にするか | オンボUX |
| 9 | user_oshi | DD（複数推し）登録の上限・組み合わせルール | UI設計 |
| 10 | user_wants | `flexibility` の具体的意味の定義 | マッチング精度 |
| 11 | user_wants | `matched` 状態の継続性（一度マッチ通知したら戻らない？） | 通知頻度 |
| 12 | aw | `ended` から `archived` への自動遷移時間 | 09 未確定項目#2 と同じ |
| 13 | aw | `auto_from_proposal` AW は取引cancel時に削除？保持？ | データ整合 |
| 14 | events | ユーザー作成タグの即公開 vs 運営承認 | 運用負荷 |
| 15 | events | 重複検出・自動マージのルール | データ品質 |
| 16 | proposal_revisions | 履歴保存の粒度（毎修正全部 vs N件のみ） | ストレージ |
| 18 | messages | system message の `event_type` 値リスト確定 | 実装明確化 |
| 19 | deals | `cancelled_reason` の値リスト | UI構築 |
| 20 | deals | `disputed` 解決時に `rated` に戻るか別終了状態か | フロー設計 |
| 22 | deal_arrivals | 1 deal × 1 user で1レコードか、再到着も記録か | データ設計 |
| 23 | user_evaluations | 細分化評価（punctuality/item_condition/communication）を MVPで採用するか | UX複雑度 |
| 24 | disputes | 反論機会期限が 24h / 4h はカテゴリで変わるか | 09 未確定項目#3 と同じ |
| 25 | disputes | 仲裁SLA超過時のエスカレーション | 運用フロー |
| 27 | matching | バッチ計算頻度 | 性能設計 |
| 28 | matching | リアルタイム通知のスロットル | 通知頻度 |
| 29 | users | パスワード以外の auth method（passkey 等） | スコープ |
| 30 | groups_master | グループ非所属のジャンル（ソロアーティスト・声優）の `kind` 設計 | iter24 の派生 |
| 31 | mail | 合意後の郵送交換を `deals.status` の別分岐にするか、住所表示だけで既存状態を使うか | 状態遷移 / UI |
| 32 | mail | 住所スナップショットを `proposals` に置くか `deals` に置くか | 監査 / 実装容易性 |
| 33 | exchange tags | 「終演後交換OK」「グッズ販売中交換OK」を user profile / AW / proposal のどこへ持つか | UI / データ設計 |

---

## 付録：状態名の対応表（09との整合確認用）

| エンティティ | 09 の状態名 | このDoc の status カラム値 |
|---|---|---|
| Proposal | `draft` `sent` `negotiating` `agreement_one_side` `agreed` `rejected` `expired` | `proposals.status` |
| Deal | `agreed` `on_the_way` `arrived_one` `arrived_both` `evidence_captured` `approved` `rated` `disputed` `cancelled` | `deals.status` |
| Dispute | `filed` `submitted` `reply_window` `reply_received` `arbitration` `resolved` `withdrawn` | `disputes.status` |
| AW | `draft` `active` `paused` `ended` `archived` | `availability_windows.status` |
| Item | `available` `in_negotiation` `in_deal` `traded` | `user_haves.status` |
| Wish | `active` `matched` `in_negotiation` `achieved` | `user_wants.status` |
| Account | `registered` `verified` `onboarding` `active` `suspended` `deletion_requested` `deleted` | `users.account_status` |
| Groom | `draft` `published` `expired` `hidden` `archived` | `groom_posts.status` |
| AdminRole | `active` `disabled` | `admin_roles.status` |
| Subscription | `incomplete` `incomplete_expired` `trialing` `active` `past_due` `cancelled` `canceled` `unpaid` `expired` | `subscriptions.status` |
| UserEntitlement | `active` / `inactive`（boolean） | `user_entitlements.active` |
| StripeWebhookEvent | `processing` `processed` `failed` `ignored` | `stripe_webhook_events.status` |

> **注意**：実装で状態名を勝手に変えると 09 と不整合になる。命名変更が必要なら必ず両方を同時に更新する。
