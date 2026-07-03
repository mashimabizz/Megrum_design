# データモデル設計

> **目的**：Megrum の全エンティティのDBスキーマ設計と、状態・マッチング・取引のデータフロー定義。
> 実装の正解集。`09_state_machines.md` と完全に整合させ、`10_glossary.md` の用語を使う。

最終更新: 2026-07-01
ステータス: Draft v2.63（iter1226.258 めぐりプロフィール変更ロックを表示名に限定）

## 最新化履歴

| Rev | 日付 | 変更 |
|---|---|---|
| **v2.63** | **2026-07-01** | **iter1226.258 反映（`meguri_profiles.last_changed_at` と保存RPCの1ヶ月ロック対象を表示名変更に限定し、アイコン変更・`uses_public_profile` 切り替えは保存できるようにした）** |
| **v2.62** | **2026-06-30** | **iter1226.231 反映（`groom_posts` / `meguri_board_threads` に任意の `group_id` / `character_id` / `series_name` を追加し、めぐりホームで推し・シリーズによる表示フィルターに使えるようにした）** |
| **v2.61** | **2026-06-29** | **iter1226.187 反映（`listings.have_is_cash_offer` / `have_cash_amount` を追加し、譲る側を定価/金額指定にした個別募集でも `have_ids=[]` / `have_qtys=[]` を正規に保存できるようにした）** |
| **v2.60** | **2026-06-29** | **iter1226.183 反映（チャットルーム詳細を会話UIへ寄せ、`meguri_board_thread_reactions` / `meguri_board_reply_reactions` の表示用種別として `good` / `bad` を追加。旧 `useful` は `good` として互換集計）** |
| **v2.59** | **2026-06-29** | **iter1226.179 反映（`meguri_profiles.uses_public_profile` を追加し、めぐり内表示をグッズ交換側の公開プロフィールへ連携できるようにした。匿名名の一意制約は匿名モードだけに適用）** |
| **v2.58** | **2026-06-29** | **iter1226.177 反映（`meguri_messages` に `source_groom_post_id` / `source_groom_owner_id` / `source_groom_image_url` を追加し、グルームへの返信文脈をめぐりメッセージ本文の前に表示できるようにした）** |
| **v2.57** | **2026-06-29** | **iter1226.112 反映（`user_evaluations` / `reports` / `goods_reports` / `groom_reports` / `meguri_board_reports` / `disputes` / `groom_user_blocks` は安全対応・表示制御・監査用データであり、本人確認・安全確認・信用保証・緊急通報・削除保証を意味しない法務前提を追記）** |
| **v2.56** | **2026-06-29** | **iter1226.111 反映（`users.gender` / `users.primary_area` / 評価 / 支払い方法要約は公開プロフィール・候補表示の参考情報であり、本人確認・法的性別確認・安全確認・支払能力確認を意味しない法務前提を追記）** |
| **v2.55** | **2026-06-29** | **iter1226.110 反映（`users.birth_date` / `users.age` は自己申告年齢として扱い、公的年齢確認・身分証確認・保護者同意確認を意味しない法務前提を追記）** |
| **v2.54** | **2026-06-29** | **iter1226.102 反映（`list_meguri_messages_for_viewer()` とメディア閲覧権限で、旧 `meguri_plus` だけでなく現行 `megrum_plus` / 互換 `premium` でもロック解除できるように追加）** |
| **v2.53** | **2026-06-28** | **iter1226.93 反映（めぐり内の表示名・アイコンを保存する `meguri_profiles` と保存RPCを追加。表示名は全ユーザー一意、変更は1ヶ月に1回まで）** |
| **v2.52** | **2026-06-27** | **iter1226.14 反映（`notifications.kind='groom_liked'`、`notifications.groom_reaction_id`、グルーム/チャットルームカテゴリ別プッシュ設定、グルーム返信/めぐりメッセージ/チャットルーム通知のDBトリガー化を追加）** |
| **v2.51** | **2026-06-27** | **iter1225 / iter1226.101 反映（グルームいいねで `expires_at` を3時間延長するRPC、グルーム通報/ブロック操作、掲示板匿名プロフィール、掲示板7日失効・1000返信ロック・1日20件作成上限を追加）** |
| **v2.50** | **2026-06-27** | **iter1223 反映（メグルムプラス `megrum_plus_monthly` / `megrum_plus` を追加。個別募集無料3件上限、ホーム/検索優先表示、グルームアーカイブ無料10件上限、StoreKit購入同期RPCを定義）** |
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
| **v2.28** | **2026-05-30** | **iter278 反映（公開プロフィール列制限、削除済み/停止中ユーザー非公開、AW匿名読み取り停止、所有者更新系RLSの `WITH CHECK` 追加）** |
| **v2.29** | **2026-05-31** | **iter338 反映（Swift Native iOS版のAPNs device token保存用に `notification_devices.push_provider` / `native_device_token` を追加）** |
| **v2.30** | **2026-05-31** | **iter346 反映（相手プロフィールと評価一覧をSwift Nativeから読むため、公開プロフィール/評価一覧RPCを追加）** |
| **v2.31** | **2026-05-31** | **iter347 反映（Swift Native取引詳細から `chat-photos` / `proposal_evidence_photos` / `proposals.approved_by_*` / `user_evaluations` を使う最小完了フローを追加）** |
| **v2.32** | **2026-05-31** | **iter352 反映（Swift Native在庫/Wish長押しメニューから `goods_inventory.status='archived'` の非表示と本人所有行DELETEへ接続）** |
| **v2.33** | **2026-05-31** | **iter353 反映（他ユーザー所有グッズの長押し通報を `goods_reports` へ保存するSwift Native境界とRLSを追加）** |
| **v2.34** | **2026-06-14** | **iter601 反映（左ドロワーのプロフィール表示で都道府県横に年齢を出せるよう、`users.age` を任意列として追加）** |
| **v2.35** | **2026-06-14** | **iter613 反映（顔検出・メンバー候補付け用に `member_face_profiles` / `face_uploaded_images` / `detected_faces` / `face_match_candidates` / `face_match_corrections` を追加）** |
| **v2.36** | **2026-06-14** | **iter614 反映（画像種別、対象種別、認識方式、汎用品質、profile_type を追加し、実写/アニメ/イラスト/漫画の候補付けを同じ保存形式で扱う）** |
| **v2.37** | **2026-06-14** | **iter616 反映（グッズ登録時のメンバー候補付けを選択済み `groups_master` 文脈へ限定し、`kind='solo'` はL2指定不要として扱う）** |
| **v2.38** | **2026-06-23** | **iter731 反映（Swift Native版が `user_entitlements` から `premium` / `meguri_plus` を読み、広告非表示や有料権限をサーバー集約値で判定する境界を追加）** |
| **v2.39** | **2026-06-24** | **iter756 反映（`users.is_test_account` を追加し、ホーム候補から検証アカウントを除外。`goods_inventory.title` をdeprecated化し、候補表示はL1/L2/グッズ種別/シリーズのマスタを正とする）** |
| **v2.40** | **2026-06-24** | **iter763 反映（`proposals.cash_offer` を片側が金額指定・片側がグッズの両方向に対応。`sender_have_ids` または `receiver_have_ids` のどちらか一方が空の金額打診を許容）** |
| **v2.41** | **2026-06-24** | **iter765 反映（`proposals.cash_amount_side` を追加し、金額指定が `sender` / `receiver` のどちら側かを保存。金額指定側にもグッズを同時に含められるようCHECKを更新）** |
| **v2.42** | **2026-06-24** | **iter787 反映（個別募集に `at_least` ロジックを追加し、譲側 `have_min_count` / 求側 `listing_wish_options.min_count` で「何個以上」を保存。既存 qty は各アイテム数量として維持）** |
| **v2.43** | **2026-06-24** | **iter788 反映（`at_least` を2件以上選択時から利用可能にし、最低数は1〜選択件数として保存。選択画面のフィルタ後全選択ボタンを追加）** |
| **v2.44** | **2026-06-25** | **iter995 反映（プロフィール編集に `users.bio` と非公開の `users.birth_date` を追加。公開表示は自己紹介と年齢までに限定）** |
| **v2.45** | **2026-06-26** | **iter1004 反映（成立後の取引チャットで支払い情報を開示するため、`proposals.sender_payment_settings/receiver_payment_settings` スナップショットを追加）** |
| **v2.46** | **2026-06-26** | **iter1203 反映（証跡追加/取引完了/評価投稿のsystem message meta運用を追加。`evidence_added` / `trade_completed` / `evaluation_submitted` でチャット表示を再現する）** |
| **v2.47** | **2026-06-26** | **iter1205 反映（`proposal_evidence_photos.approved_by_sender/approved_by_receiver` を追加し、証跡画像ごとに承認状態を持つ。自分がアップロードした証跡は初期承認済み）** |
| **v2.48** | **2026-06-27** | **iter1219 反映（交換イベントから `notifications` 行を作成。`message_received` kind と `message_id` / `evidence_photo_id` / `evaluation_id` 参照列を追加し、APNs配送は既存 `push_enabled` 設定へ委譲）** |
| **v2.49** | **2026-06-27** | **iter1222 反映（管理者運用画面用に汎用 `reports` を実テーブル化し、`notifications.kind='admin_announcement'` と推し追加リクエスト承認/運営通知送信の管理権限を追加）** |
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

### 顔検出・メンバー候補付け（iter613 / iter614）

アップロード画像から顔またはキャラクター候補を検出し、`characters_master` のメンバー/キャラ候補に紐付けるための補助テーブル群。画像本体はStorageまたは既存画像URLに置き、DBには参照・画像種別・検出結果・補正履歴を保存する。実写はApple Vision + 差し替え可能な特徴量モデル、アニメ/イラスト/漫画は専用モデルまたはサーバー認識APIへ差し替える前提で、未設定時は `unknown` / `needs_review` 側に倒す。グッズ登録時は、先に選んだ `groups_master` が `kind in ('group','work')` の場合だけ、そのL1に紐づく `characters_master` と `member_face_profiles` を候補計算へ渡す。`kind='solo'` はL1そのものが推し対象なので、L2メンバー指定とメンバー推定を行わない。

#### `member_face_profiles`

運営管理の顔特徴量プロフィール。ユーザーが任意に書き込むものではなく、同意確認済みデータをservice role / 管理バックエンドから登録する。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `character_id` | uuid | → characters_master |
| `profile_type` | text | `real_face` / `anime_face` / `anime_character` / `illustration_embedding` |
| `embedding` | double precision[] | 顔特徴量ベクトル。モデル差し替えを考慮しpgvectorではなく配列で保持 |
| `embedding_model` | text | 特徴量を生成したモデル識別子 |
| `source_image_url` | text nullable | 学習元画像の参照URL |
| `consent_recorded_at` | timestamptz | 学習データ利用の同意を記録した日時 |
| `created_by` | uuid nullable | → users（登録した運営者/管理ユーザー。削除時NULL） |
| `created_at` / `updated_at` | timestamptz | |
| `deleted_at` | timestamptz nullable | 論理削除。削除済みは候補計算に使わない |

#### `face_uploaded_images`

顔解析対象として登録されたアップロード画像。ユーザー所有で、RLS上は本人だけ参照できる。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `inventory_id` | uuid nullable | → goods_inventory（グッズ登録画像に紐づく場合） |
| `storage_bucket` / `storage_path` | text nullable | Storage上の保存先 |
| `image_url` | text nullable | 既存画像URLを解析した場合の参照 |
| `image_hash` | text nullable | 重複検出用ハッシュ |
| `content_type` | text | `image/jpeg` 等 |
| `image_type` | text | `real_photo` / `anime` / `illustration` / `manga` / `unknown` |
| `analysis_status` | text nullable | 画像単位の解析ステータス。対象がない場合は `no_face` / `no_subject` をここに保持 |
| `created_at` | timestamptz | |
| `deleted_at` | timestamptz nullable | 論理削除 |

#### `detected_faces`

1枚の画像内で検出された顔またはキャラクター候補。既存互換のためテーブル名は `detected_faces` のまま維持する。`bounding_box` は画像上の正規化 top-left 座標で、`x/y/width/height` を持つ。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `uploaded_image_id` | uuid | → face_uploaded_images |
| `bounding_box` | jsonb | 正規化矩形 |
| `detection_confidence` | double precision | Vision等の検出信頼度 0〜1 |
| `quality_score` | double precision | サイズ・信頼度からの品質 0〜1 |
| `image_type` | text | 解析元画像種別 |
| `subject_type` | text | `real_face` / `anime_face` / `character` / `unknown` |
| `recognition_method` | text | `vision_face` / `coreml_real_face` / `real_face_embedding` / `anime_face_detector` / `anime_character_classifier` / `anime_embedding_similarity` / `manual` / `unknown` |
| `legacy_quality_status` | text | iter613互換の `usable` / `too_small` / `low_confidence` / `low_quality` |
| `quality_status` | text | 汎用品質。`ok` / `low_quality` / `too_small` / `occluded` / `side_face` / `stylized` / `unknown` |
| `model_version` | text nullable | 認識モデルまたは埋め込みモデルの識別子 |
| `profile_type` | text nullable | 照合対象プロフィール種別 |
| `match_status` | text | `auto_matched` / `needs_review` / `unknown` / `no_face` / `no_subject` / `low_quality` |
| `matched_character_id` | uuid nullable | 自動一致時の → characters_master |
| `matched_confidence` | double precision nullable | 自動一致時の信頼度 0〜1 |
| `created_at` / `updated_at` | timestamptz | |

#### `face_match_candidates`

検出顔ごとの上位候補。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `detected_face_id` | uuid | → detected_faces |
| `character_id` | uuid | → characters_master |
| `confidence` | double precision | cosine similarity を正規化した候補信頼度 0〜1 |
| `rank` | integer | 候補順位 |
| `profile_count` | integer | そのメンバーに使われた顔プロフィール数 |
| `created_at` | timestamptz | |

#### `face_match_corrections`

ユーザーが確認画面で補正した履歴。`should_add_training_data` は既定trueで保存し、学習データ利用の可否はプロダクト/法務方針と運営側処理で管理する。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `detected_face_id` | uuid | → detected_faces |
| `user_id` | uuid | → users |
| `original_match_status` | text | 補正前ステータス |
| `selected_character_id` | uuid nullable | 手動選択した → characters_master |
| `selected_member_name` | text nullable | 候補外入力・表示補助 |
| `image_type` | text | 補正対象の画像種別 |
| `subject_type` | text | 補正対象の対象種別 |
| `recognition_method` | text | 補正時は通常 `manual` |
| `selected_profile_type` | text nullable | 学習データ追加時の保存先プロフィール種別 |
| `should_add_training_data` | boolean | 学習データ追加対象として扱うか。既定true |
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
| `bio` | text nullable | 自己紹介。500文字以内。公開プロフィールのスケジュールボタン上に表示できる |
| `avatar_url` | text nullable | |
| `gender` | text nullable | 任意（オンボで聞く） |
| `primary_area` | text nullable | "東京都" 等の粗い検索用エリア |
| `birth_date` | date nullable | 本人編集用の生年月日。公開プロフィールには直接表示しない |
| `age` | integer nullable | プロフィール表示用の任意年齢。1〜120の範囲制約。未設定ならUIでは表示しない |
| `payment_methods` | text[] | 支払い条件の自己申告配列。`bank_transfer` / `paypay` / `cash_exchange` / `other` |
| `payment_note` | text nullable | 支払い条件のその他表示メモ。口座番号などの機微情報は入れない |
| `is_test_account` | boolean | 検証用アカウント印。通常ユーザー向けのホーム候補・検索候補から除外する |
| `account_status` | text | `registered` / `verified` / `onboarding` / `active` / `suspended` / `deletion_requested` / `deleted` (09と一致) |
| `email_verified_at` | timestamptz nullable | |
| `deletion_requested_at` | timestamptz nullable | 30日猶予の起点 |
| `last_login_at` | timestamptz nullable | |
| `created_at` / `updated_at` | timestamptz | |

⚠️ 要確認：
- パスワード以外の auth method（passkey, magic link）対応するか
- `gender` を必須にするか任意にするか（マッチング条件に使う？）

RLS / 権限（iter278）：
- `anon` / `authenticated` に公開する `users` のSELECT列は、公開プロフィール表示に使う `id, handle, display_name, bio, avatar_url, gender, primary_area, age, account_status, created_at` に限定する。
- `birth_date` は本人編集用の非公開列であり、公開プロフィールやホーム候補には直接返さない。公開表示が必要な場合は `age` のみを使う。
- `birth_date` / `age` は自己申告年齢として扱う。これらの保存又は表示は、公的本人確認、年齢認証、身分証確認、保護者同意確認又は保護者管理機能が完了したことを意味しない。
- `gender` / `primary_area` / `age` / 評価サマリ / 完了取引数 / `payment_methods` / `payment_note` は、公開プロフィール、ホーム候補、交換条件又は打診前確認の参考情報であり、本人確認、法的性別確認、居住地確認、安全確認、信用保証、支払能力確認又は運営者による推薦を意味しない。
- `payment_methods` / `payment_note` は詳細口座情報ではなく支払い方法要約として扱う。ホーム候補・打診前確認など、authenticated の取引前表示経路だけで参照する。
- `email_verified_at` / `deletion_requested_at` / `last_login_at` / `updated_at` などの内部運用列は公開SELECT権限を付与しない。
- 公開プロフィール、ホーム候補、評価一覧等の読み取りは `account_status not in ('deleted', 'suspended', 'deletion_requested')` のユーザーだけを表示対象にする。個別のRLS/関数実装がこの方針と一致しているか提出前に確認する。
- 本人更新ポリシーは `using (auth.uid() = id)` に加えて `with check (auth.uid() = id)` を必須にし、直接API操作で `id` を別ユーザーへ移す更新を拒否する。

### `account_deletion_requests`（退会申請 / iter1221）

設定一覧の「退会する」から送信される、退会理由と任意メモを保持する監査用テーブル。退会申請は `request_account_deletion_for_viewer()` RPC 経由で行い、`users.account_status='deletion_requested'` と同じトランザクションで作成する。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users。申請した本人 |
| `reasons` | text[] | `not_using` / `hard_to_use` / `trade_concern` / `found_alternative` / `privacy_concern` / `other` から1〜8件 |
| `note` | text nullable | 任意メモ。500文字以内 |
| `requested_at` | timestamptz | 申請日時 |
| `deletion_scheduled_at` | timestamptz | 30日後の削除予定日時 |
| `status` | text | `requested` / `cancelled` / `completed` |
| `cancelled_at` / `completed_at` | timestamptz nullable | 申請取消・削除完了の運用記録 |
| `created_at` / `updated_at` | timestamptz | |

ビジネスルール：
- `proposals.status in ('sent', 'negotiating', 'agreement_one_side', 'agreed')` の進行中取引が1件でもある場合、退会申請は作成しない。
- 申請時に `users.account_status='deletion_requested'`、`users.deletion_requested_at=now()` を更新する。
- 本人は自分の申請行だけSELECTできる。作成はRPC経由に限定し、クライアントから直接INSERTしない。
- 2026-06-29時点のコード確認では、30日後に実削除又は匿名化を行うジョブ、`status='completed'` 更新処理、`status='cancelled'` 更新処理、ログインによる復旧処理は未確認。法務文面では削除予定日を処理予定の目安として扱う。

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

### `user_payment_settings`（支払い条件詳細 / iter587）

本人が設定一覧の「支払い条件設定」から編集する、支払い条件の詳細テーブル。ホーム候補や選んだグッズのヘッダーに表示する公開寄りの要約は `users.payment_methods` / `users.payment_note` を使い、銀行口座の詳細はこのテーブルに分離する。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | → users。PK 相当（1ユーザー1件） |
| `payment_methods` | text[] | 支払い方法設定画面のチェック状態。`bank_transfer` / `paypay` / `cash_exchange` / `other`。`users.payment_methods` と同期して保存する |
| `bank_name` | text nullable | 銀行名 |
| `bank_branch_name` | text nullable | 支店名 |
| `bank_account_type` | text nullable | 普通などの口座種別 |
| `bank_account_number` | text nullable | 口座番号。本人用保存値で、相手向けプレビューではマスク表示する |
| `bank_account_holder` | text nullable | 口座名義 |
| `other_note` | text nullable | その他支払い方法の補足。`users.payment_note` へも反映する公開寄りメモ |
| `created_at` / `updated_at` | timestamptz | |

運用ルール：
- RLS は本人だけが SELECT / INSERT / UPDATE / DELETE できる。
- `users.payment_methods` は対応可能な方法の要約、`user_payment_settings.payment_methods` は設定画面の再読込用の本人専用コピーとして扱う。保存時は両方を同期する。
- 口座詳細をホーム候補や公開プロフィールのSELECT経路へ混ぜない。
- `cash_offer=true` の打診が成立した時点で、`respond_to_proposal_for_viewer` が本人専用行を `proposals.sender_payment_settings` / `receiver_payment_settings` へスナップショット化する。

### `user_exchange_settings`（標準交換条件 / iter1226.32）

本人が設定一覧の「交換条件の設定」から編集する、ユーザー単位の標準交換条件テーブル。相手プロフィールの「交換条件」から読み取り専用で表示する公開寄りの条件として扱う。個別募集ごとの条件は既存どおり `individual_listings.note` 内の交換条件サマリを正とし、このテーブルは全体の標準条件を補足する。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | → users。PK 相当（1ユーザー1件） |
| `preference` | text | `local` / `mail` / `both`。現地・発送での交換可否 |
| `local_prefecture` | text nullable | 現地交換の主な都道府県 |
| `local_date_keys` | text[] | 現地交換できる日付キー配列（`YYYY-MM-DD`） |
| `local_date_details` | jsonb | 日付キーごとの都道府県・補足メモ |
| `mail_shipping_fee` | text | `owner` / `partner` / `negotiate`。送料負担方針 |
| `mail_shipping_days` | text | `oneDay` / `twoToFourDays` / `afterFiveDays`。発送目安 |
| `created_at` / `updated_at` | timestamptz | |

運用ルール：
- RLS は認証済みユーザーが SELECT でき、INSERT / UPDATE は本人だけができる。
- 相手プロフィールではこの行を読み取り専用で表示し、編集導線は出さない。
- 取引の打診・合意時点の条件スナップショットは既存の打診データ側を正とし、このテーブルの後続変更で履歴を上書きしない。

### `notifications`（通知一覧 / iter92, iter276）

アプリ内の通知一覧と未読バッジの基礎テーブル。打診、取引チャット、グルームいいね/返信、めぐりメッセージ、チャットルーム返信/メンション、運営通知などの通知を保存する。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | 通知を受け取るユーザー |
| `kind` | text | `proposal_received` / `message_received` / `groom_liked` / `groom_reply` / `meguri_message` / `meguri_board_reply` / `admin_announcement` など |
| `title` / `body` | text | 通知一覧と端末通知に表示する内容 |
| `link_path` | text nullable | タップ時の遷移先 |
| `proposal_id` / `message_id` / `evidence_photo_id` / `evaluation_id` / `dispute_id` / `groom_reply_id` / `groom_reaction_id` / `meguri_message_id` / `meguri_board_thread_id` / `meguri_board_reply_id` ほか | uuid nullable | 関連エンティティ |
| `read_at` | timestamptz nullable | nullなら未読 |
| `created_at` | timestamptz | |

iter276以降、`notifications` に行が追加されると、`notification_devices` の有効トークンへExpo Pushを送るDBトリガーが動く。iter338以降、Swift Native iOS版はAPNs tokenを保存する。iter344で `send-apns-notification` Edge Functionを追加し、iter345でDB triggerからも `app.settings.apns_dispatch_url` / `app.settings.apns_dispatch_secret` が設定済みの場合だけAPNs配送Functionへ `notification_id` を渡すようにした。iter1219以降、打診受信/再打診/見送り/成立、取引チャットメッセージ、キャンセル要請、証跡写真、取引完了、相互評価完了はDB triggerまたはRPC内で `notifications` 行を作成する。iter1222以降、管理者画面の `notifications.send` 権限を持つ管理者は `admin_announcement` を任意ユーザーまたは有効ユーザー全体へ作成できる。iter1226.14以降、グルームいいね、グルーム返信、通常めぐりメッセージ、チャットルーム投稿/返信、チャットルームメンションもDB triggerで通知行を作成する。`user_notification_settings.push_enabled=false` またはカテゴリ別プッシュ設定がOFFの場合もアプリ内通知行は残り、OSプッシュ配送だけを止める。

### `user_notification_settings`（通知設定 / iter93, iter276）

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | PK |
| `email_enabled` | boolean | 既存互換の通知チャネル設定 |
| `push_enabled` | boolean | iOS/Androidのモバイル通知を受け取るか |
| `groom_activity_push_enabled` | boolean | グルームいいね・グルーム返信・めぐりメッセージを端末プッシュするか |
| `chatroom_activity_push_enabled` | boolean | チャットルーム投稿/返信・メンションを端末プッシュするか |
| `created_at` / `updated_at` | timestamptz | |

アプリ内通知一覧は常時残る。`push_enabled=false` の場合は全端末通知だけを止める。`groom_activity_push_enabled=false` は `groom_liked` / `groom_reply` / `meguri_message` の端末通知だけを止め、`chatroom_activity_push_enabled=false` は `meguri_board_reply` / `meguri_board_mention` の端末通知だけを止める。

### `notification_devices`（モバイル通知端末 / iter276, iter338）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → auth.users |
| `platform` | text | `ios` / `android` / `web` |
| `push_provider` | text | `expo` / `apns`。Expo版はExpo Push、Swift Native iOS版はAPNs |
| `expo_push_token` | text nullable | Expo Push Token。Expo版の配送先 |
| `native_device_token` | text nullable | APNs device token。Swift Native iOS版の配送先 |
| `app_version` | text nullable | 登録時のアプリバージョン |
| `last_seen_at` | timestamptz | 最終登録/更新時刻 |
| `revoked_at` | timestamptz nullable | ログアウト等で無効化した時刻 |
| `created_at` / `updated_at` | timestamptz | |

`unique(user_id, expo_push_token)` と `unique(user_id, native_device_token) where native_device_token is not null` で同一ユーザー・同一端末の重複登録を防ぐ。`revoked_at is null` の端末だけが配送対象。既存DBトリガーは `push_provider='expo'` の行だけをExpo Pushへ送る。APNs配送は `send-apns-notification` Edge Functionが `push_provider='apns'` の有効端末を読み、Apple Push Notification serviceへ送る。Function接続用のdispatch URL/secretはDB設定値で管理し、migrationには秘密値を書かない。

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
| `group_id` | uuid nullable | iter1226.231 追加。任意の推しL1（→ groups_master）。めぐりホームの表示フィルターに使う |
| `character_id` | uuid nullable | iter1226.231 追加。任意の推しL2（→ characters_master）。めぐりホームの表示フィルターに使う |
| `series_name` | text nullable | iter1226.231 追加。任意のシリーズ名。めぐりホームの表示フィルターに使う |
| `image_transform` | jsonb | 編集画面での画像の `rotation` / `scale` / `x` / `y` |
| `text_overlays` | jsonb | テキストオーバーレイ配列 |
| `stickers` | jsonb | スタンプ等の拡張配列 |
| `doodles` | jsonb | 手描き線の配列 |
| `published_at` | timestamptz nullable | 投稿時刻 |
| `expires_at` | timestamptz nullable | 通常は `published_at + interval '24 hours'` |
| `created_at` / `updated_at` | timestamptz | |

iter1225 以降、いいね操作は `set_groom_like_for_viewer(p_post_id,p_is_liked)` RPC を使う。新規いいねが作成された時だけ `expires_at` を `greatest(expires_at, now()) + interval '3 hours'` へ延長し、重複いいねや取り消しでは期限を延長/短縮しない。`list_groom_feed_nearby()` は表示用 `like_count` を返す。

### `groom_reactions`（グルームいいね / iter164）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `groom_post_id` | uuid | → groom_posts |
| `user_id` | uuid | → users |
| `reaction_type` | text | 初期は `like` のみ |
| `created_at` | timestamptz | |

`unique (groom_post_id, user_id, reaction_type)` で同一ユーザーの重複いいねを防ぐ。アプリ側は現在ユーザーの liked 状態だけを取得する。iter1226.14以降、新規いいねが作成された時だけ `notifications.kind='groom_liked'` と `notifications.groom_reaction_id` を使って投稿者に通知を残す。

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

`notifications.kind='groom_reply'` と `notifications.groom_reply_id` を使い、受信者に通知を残す。iter1226.14以降、通知行はDB triggerで作成し、タイトルは「表示名さんからメッセージが届きました！」形式、bodyには返信本文プレビューを入れない。

### `groom_hidden_posts`（グルーム非表示 / iter165）

ユーザーごとの「このグルームを非表示」を保持する。`can_view_groom_post()` の判定に含め、非表示後はフィード・Storage署名URL発行から除外する。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | → users。PKの一部 |
| `groom_post_id` | uuid | → groom_posts。PKの一部 |
| `created_at` | timestamptz | |

### `groom_user_blocks`（めぐり文脈ユーザーブロック / iter165, iter178）

グルーム/めぐり文脈のユーザーブロック。`blocker_id` と `blocked_id` のどちらかに該当する関係では、相互にグルーム表示・めぐりメッセージ送信・スポット掲示板のスレッド/返信表示・掲示板通知を抑制する。

法務メモ（iter1226.112）：
- ブロック関係は表示、候補、メッセージ、返信、通知等を抑制するための安全操作ログであり、相手への法的通知、取引キャンセル、過去記録削除、過去評価削除、通報取消、異議申し立て終了を自動で意味しない。
- 安全対応、監査、法令対応、虚偽通報/嫌がらせ対策のため、ブロック後又は解除後もブロック関係や関連ログを保持する場合がある。

| カラム | 型 | 説明 |
|---|---|---|
| `blocker_id` | uuid | → users。PKの一部 |
| `blocked_id` | uuid | → users。PKの一部 |
| `created_at` | timestamptz | |

### `groom_reports`（グルーム通報 / iter165）

不適切なグルーム投稿の通報。ユーザーは自分の通報だけ参照できる。

法務メモ（iter1226.112）：
- `groom_reports` はUGCモデレーションの受付記録であり、投稿削除、返信停止、補償、相手への処分、通報者秘匿又は調査結果通知を保証しない。
- 緊急の危険、犯罪、医療上の問題は、アプリ内通報ではなく警察、消防、医療機関、会場スタッフ等へ連絡する前提で扱う。

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

### `meguri_profiles`（めぐりプロフィール / iter1226.93）

めぐり内で表示する名前・アイコンを通常プロフィールとは分けて保存する。グルーム投稿、グルームへのいいね・メッセージ、チャットルームの作成者/参加者表示で優先的に使う。

| カラム | 型 | 説明 |
|---|---|---|
| `user_id` | uuid | → users。PK |
| `display_name` | text | めぐり内表示名。1〜24文字 |
| `display_name_key` | text | 空白を除去して小文字化した匿名モード用の一意判定キー |
| `avatar_id` | text | `avatar_1`〜`avatar_6` |
| `avatar_url` | text nullable | めぐり専用のカスタムアイコンURL。未設定時は `avatar_id` を使う |
| `uses_public_profile` | boolean | true の時は、めぐり内の表示名・アイコンを `users` 側のグッズ交換プロフィールに連携して表示する |
| `last_changed_at` | timestamptz | 最後にめぐり内表示名を変更した時刻。アイコン変更や `uses_public_profile` 切り替えでは更新しない |
| `created_at` / `updated_at` | timestamptz | |

`display_name_key` は `uses_public_profile=false` の匿名モードだけで一意。保存は `set_meguri_profile_for_viewer(display_name, avatar_id, avatar_url, uses_public_profile)` RPC を使う。匿名名を変更する場合は `last_changed_at` から1ヶ月経過していないと拒否する。既定アイコン・カスタムアイコンURL・`uses_public_profile` の切り替えは表示名ロックの対象外として保存できる。

### `meguri_messages`（めぐりあいメッセージ / iter165）

グルーム返信後の通常会話を永続化する追記型メッセージ。静的プレビュー相手などUUIDでない相手はローカルフォールバックを使うが、実ユーザー間ではDB同期される。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `sender_id` | uuid | → users |
| `recipient_id` | uuid | → users |
| `source_groom_reply_id` | uuid nullable | → groom_replies。グルーム返信から始まった会話の起点 |
| `source_groom_post_id` | uuid nullable | → groom_posts。グルームへの返信文脈として引用する投稿 |
| `source_groom_owner_id` | uuid nullable | → users。引用元グルームの投稿者 |
| `source_groom_image_url` | text nullable | 返信文脈カードで表示するグルーム画像URL。投稿失効後も会話文脈を示すための表示用スナップショット |
| `message_type` | text | `text` / `image` |
| `body` | text nullable | 本文 |
| `image_url` | text nullable | 互換用。private Storage では path 相当 |
| `image_path` | text nullable | `meguri-message-media` private Storage path |
| `read_at` | timestamptz nullable | 受信者がスレッドを開いた時刻 |
| `created_at` | timestamptz | |

`notifications.kind='meguri_message'` と `notifications.meguri_message_id` を使い、受信者に通知を残す。iter1226.14以降、通常めぐりメッセージの通知行はDB triggerで作成し、タイトルは「表示名さんからメッセージが届きました！」形式、bodyにはメッセージプレビューを入れない。`source_groom_reply_id` がある行は `groom_reply` 通知と重複させない。
iter168.43 以降、無料受信者に本文・画像パスを直接返さないため、通常表示は `list_meguri_messages_for_viewer()` RPC を使う。直接 `meguri_messages` をSELECTできるのは送信者本人、または `user_entitlements(feature_key in ('megrum_plus','meguri_plus','premium'), active=true)` を持つ受信者に限定する。iter1226.102 以降、Swift Nativeの導線は現行表記の「Megrum プレミアム」へつなぐため、現行 `megrum_plus` を優先し、旧 `meguri_plus` / `premium` は互換として残す。
iter1226.177 以降、グルームへの返信から始まる/反応一覧から送るめぐりメッセージは、本文の前に「あなたのグルームに返信しました」カードと対象グルーム画像を表示できるよう、`source_groom_*` の3列を返す。既存の `source_groom_reply_id` だけがある行は `groom_replies.groom_snapshot` から画像・投稿者を補完する。

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
| `anonymous_display_name` | text nullable | iter1225 追加。掲示板ごとの匿名表示名。未指定なら通常プロフィール名へフォールバック |
| `anonymous_avatar_id` | text nullable | iter1225 追加。`avatar_1`〜`avatar_6` の仮アバターID。後で画像差し替え可能 |
| `audience_scope` | text | `nearby_3km` / `same_prefecture`。`same_spot` / `global` は過去データ互換 |
| `spot_key` | text nullable | 互換用の粗いスポットキー。新規仕様では閲覧判定の主軸にしない |
| `spot_label` | text nullable | 画面表示用のスポット名 |
| `prefecture` | text nullable | 閲覧判定・表示用の都道府県。`nearby_3km` / `same_prefecture` の時は必須 |
| `origin_lat` / `origin_lng` | double precision nullable | iter168.89 追加。スレッド作成時の位置。`nearby_3km` では必須 |
| `group_id` | uuid nullable | iter1226.231 追加。任意の推しL1（→ groups_master）。めぐりホームの表示フィルターに使う |
| `character_id` | uuid nullable | iter1226.231 追加。任意の推しL2（→ characters_master）。めぐりホームの表示フィルターに使う |
| `series_name` | text nullable | iter1226.231 追加。任意のシリーズ名。めぐりホームの表示フィルターに使う |
| `reply_count` | integer | 返信数のサマリ |
| `reaction_count` | integer | 旧「参考になった」の互換集計。iter1226.183以降、画面表示はRPCが返す `good_reaction_count` / `bad_reaction_count` を優先 |
| `bookmark_count` | integer | 保存数の集計。iter171 追加 |
| `view_count` | integer | 詳細を開いた回数の集計。iter171 追加 |
| `latest_reply_preview` | text nullable | 最新返信の先頭160字 |
| `latest_activity_at` | timestamptz | スレッド作成または最新返信時刻 |
| `expires_at` | timestamptz | iter1225 追加。最後の書き込みから7日後。期限切れは `archived` 化して通常表示から外す |
| `created_at` / `updated_at` | timestamptz | |

> **公開範囲方針**：`nearby_3km` は現在地と `origin_lat/origin_lng` の距離でRPC判定する。`same_prefecture` はスレッド作成時の都道府県と閲覧者側の都道府県で判定する。正確な緯度経度は画面に表示しない。

> **画像添付方針（iter176）**：スレッド画像は `meguri-board-media` private Storage に保存し、DBには path のみを持つ。アプリは `list_meguri_board_threads_for_viewer()` で閲覧可能なスレッドを取得した後に署名URLを発行して表示する。

> **ブロック方針（iter178）**：`groom_user_blocks` に保存されたブロック関係はスポット掲示板にも適用する。ブロックした/された相手のスレッドは `can_view_meguri_board_thread*()` と一覧RPCで除外し、ローカル表示も即時に消す。

> **参加中判定（iter188）**：`list_meguri_board_threads_for_viewer()` は `viewer_participated` を返す。閲覧者がスレッド作成者、または `status='visible'` の返信を書いている場合に true とする。通知購読 `viewer_subscribed` とは別概念。

> **期限・上限（iter1225 / iter1226.101）**：スレッドは最後の書き込みから7日で `archived` 化する。返信追加時は `latest_activity_at` と `expires_at` を更新し、返信数が1000件に到達したら `locked` にする。スレッド作成はユーザー1人あたり1日20件までDBトリガーで制限する。作成は `create_meguri_board_thread_for_viewer()` RPCでログインユーザーを確定してから行う。

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
| `reaction_count` | integer | 返信への旧「参考になった」の互換集計。iter1226.183以降、画面表示はRPCが返す `good_reaction_count` / `bad_reaction_count` を優先 |
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
| `reaction_type` | text | `good` / `bad`。旧データ互換として `useful` も許容し、一覧RPCでは `good` に含めて返す |
| `created_at` | timestamptz | |

スレッド/返信へのグッド/バッド。iter1226.183以降、アプリは `set_meguri_board_thread_message_reaction()` / `set_meguri_board_reply_message_reaction()` でユーザーごとに1種だけ保存する。既存の `reaction_count` trigger は互換集計として残し、`list_meguri_board_threads_for_viewer()` / `list_meguri_board_replies_for_viewer()` は `good_reaction_count` / `bad_reaction_count` / `viewer_reaction_type` を返す。

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

スレッド作成者と返信者は自動で購読ONになる。ユーザーは一覧/詳細からON/OFFを切り替えられる。iter1226.14以降、スレッドに「参考になった」を付けたユーザーも購読ONになる。購読中スレッドに自分以外が返信した時は `notifications.kind='meguri_board_reply'` を作成し、`meguri_board_thread_id` / `meguri_board_reply_id` と `link_path='/meguri-board-thread?id=...'` を保存する。返信本文に `@handle` が含まれる場合は、本人以外かつスレッドを閲覧できる対象ユーザーに `notifications.kind='meguri_board_mention'` を作成し、通常の購読返信通知とは重複させない。チャットルーム通知のbodyには返信本文プレビューを入れない。iter178以降、返信者と通知先が `groom_user_blocks` で相互ブロック関係にある場合は返信通知・メンション通知を作成しない。

### `meguri_board_hidden_threads` / `meguri_board_reports`（非表示・通報 / iter171）

ユーザー単位の非表示は `meguri_board_hidden_threads`、通報は `meguri_board_reports` に保存する。通報はスレッドまたは返信のどちらか一方を対象にし、運営側で `open` / `reviewing` / `resolved` / `rejected` を管理する。iter179以降、アプリ側では `reason` を `spam` / `harassment` / `privacy` / `unsafe` / `off_topic` / `other` から選ばせる。

法務メモ（iter1226.112）：
- `meguri_board_reports.status` は運営処理状態であり、対象投稿の違反確定、無違反確定、法的責任、削除保証を意味しない。
- `hidden` やブロックで本人の表示から外れても、監査、モデレーション、法令対応、再発防止のため、スレッド、返信、通報、ブロック関係、既読/通知関連ログを保持する場合がある。

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
> Swift Native実装では `goods_inventory.locked_qty` に `agreed` かつ未完了の打診で確保済みの数量を保存し、`goods_inventory.market_available_qty = greatest(quantity - locked_qty, 0)` を生成列として持つ。`respond_to_proposal_for_viewer` は `agreed` 遷移直前に双方の譲在庫を行ロックし、市場残数不足なら成立させない。proposal trigger が `locked_qty` を再計算し、完了・取消・拒否・期限切れなど `agreed` から外れた行は市場ロックから外れる。
>
> **iter154.18 譲り済み履歴の不変性**：`status='traded'` の在庫は取引履歴の証跡として扱い、ユーザー操作による更新・削除を不可にする。画面上は詳細確認のみ、サーバーアクションでも update/delete を拒否する。
>
> **iter352 Swift Native操作**：在庫/Wishの「非表示」は `goods_inventory.status='archived'` に更新し、本人所有行だけを対象にする。「削除」は本人所有行を `id + user_id` で絞ってDELETEする。取引履歴に入った `traded` 行の削除禁止は別途サーバー側制約として維持する。
>
> **iter756 マスター表示の正規化**：`goods_inventory.title` は旧UIの自由入力表示名としてdeprecated扱いにする。ホーム候補、Wish、マイグッズ、個別募集の表示・判定は `groups_master` / `characters_master` / `goods_types_master` / `tags_master` を正とし、`title` の先頭語をL1/L2名として解析しない。`character_id` が入る場合は同じ行の `group_id` と所属関係が一致することをDB triggerで検証し、`group_id` 未指定なら `characters_master.group_id` で補完する。`goods_type_id` は既存FKで `goods_types_master(id)` 外の値を拒否する。

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
| `exchange_type` | text default `any` | iter62、`same_kind` / `cross_kind` / `any`。**自己申告シリーズ**、システム判定なし（カードに chip 表示のみ） |
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
| `have_logic` | text | `'and'`（全部セット）/ `'or'`（いずれか）/ `'at_least'`（何個以上）、default `'and'` |
| `have_min_count` | int | `have_logic='at_least'` の最低成立数。通常は 1。`at_least` は have_ids 2件以上かつ 1〜have_ids件数 |
| `have_is_cash_offer` | boolean | 譲る側を定価/金額指定で出す場合 true。true の時だけ `have_ids=[]` / `have_qtys=[]` を許可 |
| `have_cash_amount` | int nullable | 譲る側の金額指定。定価扱いは null、指定金額は 1〜9,999,999 |
| `have_group_id` | uuid | trigger で全 haves から自動算出（同一性検証） |
| `have_goods_type_id` | uuid | 同上 |
| `status` | text | `active` / `paused` / `matched` / `closed` |
| `note` | text nullable | |
| `created_at` / `updated_at` | timestamptz | |

> iter1226.187：譲る側を `定価で選ぶ` / `金額指定` にした個別募集では、`have_is_cash_offer=true` とし、`have_ids=[]` / `have_qtys=[]` を許可する。指定金額は `have_cash_amount`、定価扱いは null。UI表示・共有文面の互換のため、`note` 内の `譲る金額: 定価` または `譲る金額: ¥1500` メタ行も維持する。

制約：
- `have_is_cash_offer=false` の場合、have_ids 全件が **同 group + 同 goods_type**（trigger 検証）
- `have_is_cash_offer=false` の場合、have_qtys 各値 1〜99（trigger）
- `have_is_cash_offer=false` の場合、have_ids 全件が listing 所有者の `kind=for_trade` インベントリ
- `have_is_cash_offer=true` の場合、have_ids / have_qtys は空、have_group_id / have_goods_type_id は null
- have_logic='at_least' の時は have_ids 2件以上、have_min_count は 1〜have_ids件数。それ以外は have_min_count=1
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
| `logic` | text | `'and'`（全部セット）/ `'or'`（いずれか）/ `'at_least'`（何個以上）、default `'or'` |
| `min_count` | int | `logic='at_least'` の最低成立数。通常は 1。`at_least` は wish_ids 2件以上かつ 1〜wish_ids件数 |
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
- 通常選択肢：logic='at_least' の時は wish_ids 2件以上、min_count は 1〜wish_ids件数。それ以外は min_count=1
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

RLS / 権限（iter278）：
- `status='enabled'` のAW読み取りは `authenticated` のみに限定し、匿名ユーザーには公開しない。
- 更新ポリシーは `using (auth.uid() = user_id)` と `with check (auth.uid() = user_id)` の両方を持たせる。

### `events`（公演／物販イベントシリーズ）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | "TWICE 名古屋ドーム公演" 等 |
| `start_at` / `end_at` | timestamptz | |
| `lat` / `lng` | double precision | |
| `venue_name` | text | "ナゴヤドーム" |
| `genre_id` | uuid | → genres_master |
| `group_id` | uuid nullable | → groups_master |
| `created_by` | uuid | → users（ユーザー作成シリーズ） |
| `is_verified` | boolean | 運営承認済か（重複名寄せ後） |
| `created_at` | timestamptz | |

⚠️ 要確認：
- ユーザー作成シリーズの即公開 vs 運営承認後公開
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
| `option_tags` | text[] default `{}` | iter170、打診条件シリーズ。例：即日発送 / 同日発送 / 終演後OK |
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
| `sender_payment_settings` | jsonb nullable | iter1004、`cash_offer=true` の取引が合意成立した時点の送信者支払い情報スナップショット。銀行振込の振込先など、本人専用 `user_payment_settings` からコピーする |
| `receiver_payment_settings` | jsonb nullable | iter1004、`cash_offer=true` の取引が合意成立した時点の受信者支払い情報スナップショット。成立後の当事者向け取引チャットで表示する |
| `expose_calendar` | bool default false | iter67 で再定義：送信者が自分の **個人スケジュール（schedules）** を相手に公開する ON/OFF。受信側は受信表示画面で送信者の予定を見られる（取引完了で自動的に RLS 不可）。AW は対象外 |
| `listing_id` | uuid nullable | iter64、個別募集 (`listings`) 経由の打診ならその id。直接打診なら null |
| `cash_offer` | bool default false | iter765 更新、提案内に金額指定を含むなら true（`cash_amount` + `cash_amount_side` 必須） |
| `cash_amount` | int nullable | iter765 更新、金額指定の金額（1〜9,999,999）。cash_offer=true のときのみ |
| `cash_amount_side` | text nullable | iter765 追加、`sender` = 出す側に金額指定を含む / `receiver` = 受け取る側に金額指定を含む |
| `created_at` / `updated_at` | timestamptz | |

CHECK 制約 `proposals_meetup_required`（iter168.82 更新）：`exchange_method='hand'` または `exchange_method='both'` かつ `status!='draft'` の時だけ 5 列すべて NOT NULL かつ `meetup_end_at > meetup_start_at`。`mail` の時は待ち合わせ列を必須にしない。
CHECK 制約 `proposals_meetup_candidates_array`（iter154.34）：`meetup_candidates` は JSON 配列、最大3件。
CHECK 制約 `proposals_cash_amount_side_check`（iter765 追加）：`cash_amount_side` は null / `sender` / `receiver` のいずれか。
CHECK 制約 `proposals_cash_offer_consistency`（iter765 更新）：`cash_offer=true` の時は `cash_amount` と `cash_amount_side` 必須。`cash_amount_side='sender'` なら受け取る側に1件以上、`cash_amount_side='receiver'` なら出す側に1件以上のグッズが必要。金額指定側にもグッズを同時に含めてよい。`cash_offer=false` の時は両側にグッズがあり、`cash_amount` / `cash_amount_side` は null。

iter168.97 追加運用：
- `exchange_method='both'` の打診に合意する時は、合意前に `hand` または `mail` のどちらか1つへ固定して保存する。
- 現地交換で `meetup_candidates` が複数ある場合は、合意前に1件を選択し、その候補を既存 `meetup_*` 列へミラーする。
- 条件変更の再打診は元 Proposal を直接更新せず、元の提示物/受け取り候補/交換手段/待ち合わせ候補をコピーした新規打診作成として扱う。

派生ルール：
- iter153: `status='agreed'` の proposal は、`sender_have_ids` / `receiver_have_ids` と各 qty を市場残数から差し引く。ただし `approved_by_sender` / `approved_by_receiver` が true の側は、取引完了承認処理で実在庫が既に減算されているため二重控除しない。
- iter153: `sent` / `negotiating` / `agreement_one_side` は在庫確保前の状態として扱い、市場残数からは差し引かない。`agreed` へ遷移する直前にキャパ超過を検証する。
- iter168.74/168.82: `exchange_method='mail'` または `exchange_method='both'` の時、送信者は打診送信前に `user_mailing_addresses` の登録が必須。受信者も合意前に住所登録が必要で、最終合意時に双方の住所スナップショットを `proposals.sender_mailing_address / receiver_mailing_address` へ固定し、当事者以外には返さない。

RLS / 権限（iter278）：
- 参加者更新ポリシーは `using (auth.uid() = sender_id or auth.uid() = receiver_id)` に加えて `with check (auth.uid() = sender_id or auth.uid() = receiver_id)` を必須にする。
- これにより、直接API操作で `sender_id` / `receiver_id` を第三者へ変更して打診の所有関係を移す更新を拒否する。

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

現行実装メモ（iter347）：
- 取引完了のSwift Native最小フローは、専用 `deals` 実テーブルではなく既存 `proposals` の `evidence_photo_url` / `evidence_taken_at` / `evidence_taken_by` / `approved_by_sender` / `approved_by_receiver` / `completed_at` / `status='completed'` と、複数枚対応の `proposal_evidence_photos`、評価の `user_evaluations` を使う。
- 証跡画像は Storage `chat-photos` に保存し、`proposal_evidence_photos.photo_url` と `proposals.evidence_photo_url`（最初の1枚の互換ミラー）に保持する。
- iter1205 以降、`proposal_evidence_photos` は `approved_by_sender` / `approved_by_receiver` を持ち、証跡画像ごとに承認状態を管理する。アップロードした本人側は作成時点で承認済み、相手側はその画像の「承認」でtrueにする。`proposals.approved_by_sender` / `approved_by_receiver` は全証跡画像の集約値として維持する。
- Swift Nativeの `SupabaseProposalClient` は、証跡追加、承認、評価投稿をこの境界に接続する。
- iter725 以降、証跡写真は `proposal_evidence_photos.id` / `proposal_id` / `taken_by` で絞って、アップロードした本人だけ削除できる。削除後は `proposals.evidence_photo_url` / `evidence_taken_at` / `evidence_taken_by` の互換ミラーを残りの先頭写真、または `NULL` に更新する。
- 証跡追加時は `messages` に `message_type='system'`、`meta.action='evidence_added'` の通知を追加する。本文は `表示名が取引証跡をアップロードしました` 形式で保存し、取引チャット上では「見る」導線から証跡写真一覧を開く。
- 両者の証跡承認で `proposals.status='completed'` になった時は、`messages` に `meta.action='trade_completed'` / `body='取引が完了しました'` のsystem通知を追加する。
- 評価投稿時は `user_evaluations` に従来通り保存しつつ、`messages` に `meta.action='evaluation_submitted'`、`meta.stars`、`meta.comment`、`meta.rater_display_name` / `meta.rater_handle` を持つsystem通知を追加する。取引チャットでは両者の評価通知がそろった時だけ、双方の評価文をチャット内カードとして公開する。

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
| `proposal_id` | uuid | → proposals |
| `rater_id` | uuid | 評価者 |
| `ratee_id` | uuid | 評価対象 |
| `stars` | int | 1-5 |
| `comment` | text nullable | |
| `punctuality_rating` | int nullable | 1-5（時間厳守度、⚠️要確認） |
| `item_condition_rating` | int nullable | 1-5（実物状態の一致度、⚠️要確認） |
| `communication_rating` | int nullable | 1-5（メッセージ対応、⚠️要確認） |
| `created_at` | timestamptz | |

集計はビューで：合計★平均、取引回数、無断キャンセル数。

実装メモ（iter277）：
- 相手プロフィールの評価一覧では、評価者アイコン、ユーザーネーム、評価日、★、コメントを表示する。
- `user_evaluations` は、削除・停止されていない ratee の評価に限り、ログイン済みユーザーがプロフィール評価一覧として閲覧できる。

実装メモ（iter346）：
- 直接の `user_evaluations` SELECT は取引参加者向けRLSを維持する。
- 相手プロフィールの表示には `get_public_user_profile_for_viewer(p_user_id)` と `list_user_evaluations_for_profile(p_user_id, p_limit)` を使い、公開してよいプロフィールサマリ・評価者公開情報・星・コメントだけを返す。
- `account_status in ('suspended', 'deletion_requested', 'deleted')` の評価対象/評価者はプロフィール評価一覧から除外する。

法務メモ（iter1226.112）：
- 評価コメントはユーザー入力UGCであり、公開プロフィール、評価一覧、取引チャット内カード、通知等で表示され得る。住所、連絡先、勤務先/学校、銀行口座、正確な待ち合わせ場所、顔写真、第三者情報、名誉毀損、権利侵害、虚偽又は報復目的の記載を入れない前提で扱う。
- `stars`、評価平均、評価件数、評価コメント、完了取引数は参考情報であり、本人確認、安全確認、信用保証、支払能力確認、商品品質保証、真実性確認又は運営推薦を意味しない。
- 評価は削除・非表示・アカウント制限・法令対応・監査の対象になり得るが、運営が全評価を事前審査し、真実性を保証し、特定の評価を削除/訂正/再投稿する義務を負うものではない。

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

### `reports`（汎用通報 / iter1222）

ユーザー、取引、取引チャットメッセージに対する通報。グッズ単位の表示通報は `goods_reports`、取引完了前後の異議申し立て/仲裁は `disputes` として分けるが、管理者画面ではこれらを横断して確認する。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `reporter_id` | uuid | → users |
| `target_user_id` | uuid nullable | → users |
| `target_proposal_id` | uuid nullable | → proposals |
| `target_message_id` | uuid nullable | → messages |
| `category` | text | `spam` / `harassment` / `fake_item` / `no_show` / `unsafe` / `privacy` / `other` |
| `description` | text nullable | 補足。4000文字以内 |
| `evidence_urls` | text[] | スクショ等 |
| `status` | text | `open` / `reviewing` / `resolved` / `dismissed` |
| `resolved_at` | timestamptz nullable | |
| `created_at` / `updated_at` | timestamptz | |

RLS:
- ログインユーザーは自分の `reporter_id` の行だけinsert/selectできる。
- `target_user_id` / `target_proposal_id` / `target_message_id` の少なくとも1つを必須にする。
- `target_user_id` がある場合は `reporter_id <> target_user_id` を必須にし、自分自身へのユーザー通報を禁止する。
- 管理者画面は service role + `reports.read` / `reports.moderate` で横断閲覧・状態更新する。

法務メモ（iter1226.112）：
- 通報は安全対応、問い合わせ対応、監査、法令対応、虚偽/報復通報対策のための記録であり、緊急通報、警察/消防/医療機関/法律相談、公的救済手続の代替ではない。
- 通報者IDは通常ユーザー向けに直接表示しない前提だが、対象行為の文脈、当事者間の状況、法令・裁判所・捜査機関・App Store審査・外部サービス対応により、通報者又は関連情報が推測又は開示される場合がある。
- `status` は運営処理状態であり、対象者の法的責任、信用、安全性、危険性、違反確定又は無違反確定を意味しない。虚偽、嫌がらせ、報復目的の通報はアカウント制限対象にする。

### `goods_reports`（グッズ通報 / iter353）

取引成立前でも、不適切なグッズ表示を運営確認へ回すためのグッズ単位の通報。取引異常時の `disputes` とは分ける。

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `reporter_id` | uuid | → users。通報者 |
| `goods_inventory_id` | uuid | → goods_inventory。対象グッズ |
| `reported_user_id` | uuid | → users。対象グッズの所有者 |
| `reason` | text | `spam` / `harassment` / `fake_item` / `privacy` / `unsafe` / `other` |
| `note` | text nullable | 補足。500文字以内 |
| `status` | text | `open` / `reviewing` / `resolved` / `dismissed` |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

RLS:
- ログインユーザーは自分の `reporter_id` の行だけinsert/selectできる。
- `reporter_id <> reported_user_id` を必須にし、自分のグッズ通報を禁止する。
- 対象 `goods_inventory` は `reported_user_id` 所有かつ `status in ('active','reserved')` の行に限定する。
- `unique (reporter_id, goods_inventory_id)` により同じグッズへの重複通報を防ぐ。

法務メモ（iter1226.112）：
- `goods_reports` は不適切表示、権利侵害、偽物疑い、個人情報、危険行為等を運営確認へ回すための記録であり、商品の真正性、権利処理、品質、交換可否を運営が保証するものではない。
- 通報済み又はレビュー中であっても、対象グッズの表示停止、取引停止、削除、補償、紛争解決を保証しない。必要に応じて非表示、削除、アカウント制限、外部機関対応の対象にする。

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

実装メモ（iter351）：
- Swift Native版は既存migration `20260503270000_add_disputes.sql` の `disputes` テーブルへ直接接続する。
- Native送信時は `proposal_id` / `reporter_id` / `respondent_id` / `category` / `fact_memo` / `evidence_photo_urls` / `ticket_no` をinsertし、DB既定の `status='submitted'` を使う。
- 申告作成後は取引チャットの `messages` にsystem messageを残す。

法務メモ（iter1226.112）：
- `disputes` は取引異常時の事実確認と運営対応のための記録であり、裁判、行政救済、警察/消防/医療機関、法律相談、損害賠償、返金、補償、エスクロー、強制執行の代替ではない。
- `fact_memo`、証跡URL、status、operator_comment、outcome等は、当事者説明、再発防止、アカウント制限、法令対応、監査のため保存する場合がある。
- `status`、`outcome`、`operator_comment` は運営上の対応記録であり、最終的な法的責任、真実性、商品価値、信用又は安全性を確定するものではない。

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

### `subscriptions`（メグルムプラス / 旧Premium / 旧めぐりPlus サブスクリプション）

| カラム | 型 | 説明 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | → users |
| `plan_type` | text | `megrum_plus_monthly` / `premium_monthly` / `premium_yearly` / `meguri_plus_monthly` / `monthly` / `yearly` |
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
> iter731: Swift Native版も同じ方針に合わせ、アプリ内の広告非表示・有料導線は `user_entitlements(feature_key in ('premium','meguri_plus'))` の有効行を読む。Apple StoreKit、Stripe、管理者手動付与のどれで発生しても、最終的には `user_entitlements` へ集約する。
> iter1223: 現行課金プランを **メグルムプラス** に統一し、`subscriptions.plan_type='megrum_plus_monthly'` / `user_entitlements.feature_key='megrum_plus'` を追加する。個別募集無料3件上限、ホーム/検索優先表示、グルームアーカイブ無料10件上限の判定はこの権限キーを見る。旧 `premium` / `meguri_plus` は互換用に残す。
> iter1226.102: めぐりメッセージの本文・画像パス解除も、現行 `megrum_plus` を正とし、旧 `premium` / `meguri_plus` を互換として許可する。
> iter1226.177: グルーム返信文脈付きのめぐりメッセージは `meguri_messages.source_groom_*` を使い、本文・画像ロックの有無とは別に引用元グルームの文脈カードを表示できる。

#### StoreKit product id 候補（iter1223）

| plan_type | product_id候補 | 付与する feature_key |
|---|---|---|
| `megrum_plus_monthly` | `megrum.plus.monthly` | `megrum_plus` |
| `premium_monthly` | `megrum.premium.monthly` | `premium` |
| `premium_yearly` | `megrum.premium.yearly` | `premium` |
| `meguri_plus_monthly` | `megrum.meguri_plus.monthly` | `meguri_plus` |

product_id は App Store Connect 登録時に最終決定する。DB上は `subscriptions.transaction_provider='apple'` と `transaction_provider_subscription_id` / `transactions.provider_transaction_id` にApple側IDを保存し、`user_entitlements` には利用権だけを保存する。iter1223時点のSwift実装はStoreKit検証済みtransactionを `sync_megrum_plus_purchase_for_viewer()` でDBへ同期するが、App Store Server APIによるサーバー側署名検証は本番前に追加する。

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
| `permissions` | text[] | `users.read` / `reports.read` / `oshi_requests.manage` / `notifications.send` 等。`*` は全権限 |
| `status` | text | `active` / `disabled` |
| `requires_mfa` | boolean | true の場合、AAL2 セッションのみ管理者ページへ入れる |
| `created_by` | uuid nullable | 付与した管理者 |
| `created_at` / `updated_at` | timestamptz | |

RLS:
- SELECT: 自分の管理者レコード、または `roles.read` 権限を持つ管理者のみ
- INSERT/UPDATE/DELETE: クライアントからは許可しない。管理者Server Actionが service role で更新し、必ず `admin_audit_logs` に記録する。
- iter1222以降、通報横断閲覧/対応は `reports.read` / `reports.moderate`、推し追加リクエスト確認/承認は `oshi_requests.read` / `oshi_requests.manage`、運営通知送信は `notifications.send` を使う。

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
| `feature_key` | text PK | `megrum_plus` / `premium` / `meguri_plus` 等 |
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
| `feature_key` | text | `megrum_plus` / `premium` 等 |
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

### 現行ホーム判定（iter582）

詳細は `notes/18_matching_v2_design.md` の「2026-06-13 現行ホーム判定仕様（最新）」を正とする。

ホームは「完全マッチ / forward / backward」などのユーザー向け棚では分けない。カードごとに `グッズ条件`、`交換条件`、`支払い条件` を判定し、そのうえで現行ホームの `ユーザー×シリーズでマッチ` / `ユーザーでマッチ` / `譲るものから見る` へ振り分ける。

#### グッズ条件

| 判定 | データ上の条件 |
|---|---|
| `◎` | 相手の個別募集（`listings` / `listing_wish_options`）に、自分の譲候補が一致している |
| `○` | 相手の Wish に、自分の譲候補が1つ以上一致している |
| `△` | 相手の Wish / 個別募集の中に、自分の譲候補が1つもない |

#### 交換条件

| 判定 | データ上の条件 |
|---|---|
| `◎` | `exchange_method` が発送OK（`mail`）同士、または現地交換OK同士かつ都道府県が一致 |
| `○` | 現地交換OK同士だが都道府県が一致しない |
| `△` | 共通する交換方法がない、または判定不能 |

日程は `交換条件` の◎/○/△判定には使わない。発送（`mail`）のみの場合、都道府県一致も条件に含めない。

#### 支払い条件

支払い条件は、ユーザーがあらかじめ設定する対応可能な支払い方法の自己申告配列として扱う。アプリ内決済ではなく、定価交換や差額相談などで、相手と対応可能な方法が重なるかを表示するための条件である。選んだグッズの詳細では、そのグッズ所有者の `payment_methods` / `payment_note` をデフォルト表示する。

| 値 | 表示 | 判定対象 |
|---|---|---|
| `bank_transfer` | 銀行振込 | yes |
| `paypay` | PayPay | yes |
| `cash_exchange` | 現金交換 | yes |
| `other` | その他 / 自由入力メモ | no |

| 判定 | データ上の条件 |
|---|---|
| `○` | 自分と相手の `payment_methods` のうち、判定対象の `bank_transfer` / `paypay` / `cash_exchange` が1つ以上一致 |
| `△` | 判定対象の一致がない、または片方が未設定 |

`account` / `口座` は独立した支払い方法として扱わない。銀行口座の詳細は `user_payment_settings` に本人専用データとして保存し、ホーム候補や公開プロフィールのSELECT経路には出さない。相手向けの取引前表示は `銀行振込 / PayPay / 現金交換 / メルペイ相談可` のような要約に留める。

#### シリーズ

- グッズシリーズはマッチング条件として使う。
- 1つ以上一致すれば `ユーザー×シリーズでマッチ` に出す。
- 複数一致した場合は同じ棚の中で表示順位を上げる。
- シリーズ一致は `グッズ条件◎/○/△` の判定には含めない。

#### Wish の L1 / L2

- L1 = グループ / 作品。
- L2 = メンバー / キャラクター。
- L2 マスターに値がある場合、Wish の L2 無指定は禁止。
- L2 マスターに値がない場合だけ、L1 そのものを Wish 対象として保存できる。
- Wish に優先度・妥協度は持たせない。

#### 市場残数

ホーム、検索、打診作成、個別募集作成では、実在庫 `quantity` ではなく `market_available_qty = quantity - locked_qty` を使う。`market_available_qty <= 0` の譲候補は候補から除外し、履歴保持のため物理削除ではなく論理削除・非表示・closed/archived 相当で扱う。`locked_qty` は `proposals.status='agreed'` の `sender_have_ids` / `receiver_have_ids` と数量配列から再計算し、`agreed` へ遷移する直前には `quantity - locked_qty >= proposal qty` を満たすことをRPCで検証する。

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
- 内部的に `matched` / `possible` / `none` を持つ場合でも、ユーザー向け棚は `ユーザー×シリーズでマッチ` / `ユーザーでマッチ` / `譲るものから見る` を正とする。
- 検索結果にも `グッズ条件`、`交換条件`、`支払い条件`、シリーズ一致理由を持たせ、なぜ候補に出たかを説明できるようにする。

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
| 14 | events | ユーザー作成シリーズの即公開 vs 運営承認 | 運用負荷 |
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
