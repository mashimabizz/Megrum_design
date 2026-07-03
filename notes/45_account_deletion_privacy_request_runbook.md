# 45. アカウント削除・個人情報請求ランブック

最終更新: 2026-06-29

ステータス: Draft v0.4（退会申請RPCで通知deviceを失効するmigrationを追加・退会完了処理/取消処理/Auth削除/Storage削除/外部連携解除は未確認）

## 目的

App Store初回提出前に、アカウント削除、Apple / Googleログイン連携解除、サブスクリプション案内、個人情報の開示等請求を、審査・法務・サポート運用で説明できる状態へ整理する。
データごとの保持、削除、匿名化、例外保持は `notes/52_data_retention_deletion_matrix.md` で横断確認する。

この文書は運用ランブックであり、コード、DB、認証設定、公開ページは変更しない。

## 1. 公式要件メモ

| 論点 | 要件として見るもの | Megrumでの対応 |
|---|---|---|
| アプリ内削除開始 | アカウント作成があるアプリは、アプリ内で削除を開始できる必要がある | 設定内に削除入口を置く |
| 削除対象 | 一時停止だけでは足りず、アカウント全体と関連する個人データの削除を提示する | 削除対象/保持対象を確認画面に出す |
| サポート依存 | 原則、電話やメールだけを必須にしない | アプリ内で開始し、サポートは例外時の補助にする |
| 手動処理 | 即時自動でなくてもよいが、所要時間、処理状況、必要な場合の連絡導線を説明できる必要がある | 現行DBは削除予定日を保存する。完了通知、実削除ジョブ、取消処理は未確認 |
| IAP | 自動更新サブスクがある場合、Apple側の解約が別途必要と案内する | 削除確認画面とサポート文面へ入れる |
| Sign in with Apple | アカウント削除時にトークン失効対応を検討する | サーバー側でrevokeが必要か確認する。未確認の間は完了保証を書かない |
| 個人情報請求 | 開示、訂正、利用停止、消去、第三者提供停止、第三者提供記録の開示等を受け付ける | `support@megrum.jp` とアプリ内問い合わせで受付 |

## 2. 現行Swift Native実装確認

### 2.1 確認済みの入口と処理

2026-06-29時点でコードから確認できた現行導線:

1. 設定
2. 退会する
3. 削除前の確認
4. 退会理由選択
5. 任意メモ入力
6. 最終確認
7. `request_account_deletion_for_viewer()` RPCで退会申請
8. 成功時に `viewer.accountStatus = deletionRequested` とし、設定画面を閉じる

RPCで確認できた処理:
- `account_deletion_requests` に `reasons`、`note`、`requested_at`、`deletion_scheduled_at`、`status='requested'` を保存する。
- `users.account_status='deletion_requested'` と `users.deletion_requested_at=now()` を更新する。
- `deletion_scheduled_at` は申請時刻から30日後を設定する。
- `sent` / `negotiating` / `agreement_one_side` / `agreed` の進行中取引がある場合は `ONGOING_TRADE_EXISTS` で申請を拒否する。
- 理由は1件以上8件以内、任意メモは500文字以内に正規化される。
- 画面文言では、退会申請後に「削除申請中」となり通常利用が制限されること、安全確認に必要な記録は一定期間保持される場合があること、進行中取引がある場合は退会できないことを案内する。ただし、現行コード確認では、申請成功後に全画面を強制ログアウト又は全機能ブロックへ切り替える処理までは未確認。

APNs token / 端末通知まわりで確認できた処理:
- APNs device tokenは `notification_devices` に `push_provider='apns'`、`native_device_token` として保存される。
- ログアウト経路では、登録済みtokenがある場合に `notification_devices.revoked_at` をPATCHする `revokeRegisteredNativePushDeviceToken()` の呼び出しがある。
- `send-apns-notification` Edge Functionは、APNsが410、`BadDeviceToken` 又は `Unregistered` を返した場合に該当deviceの `revoked_at` を更新する。
- iter1226.267で、退会申請RPC成功時に `notification_devices.revoked_at` を未失効の全deviceへ設定するmigrationを追加した。削除完了時の横断削除、外部push provider側の完全削除、Expo tokenを含む本番データでの適用確認は未確認。

Auth session / Keychainまわりで確認できた処理:
- live authでは `KeychainAuthSessionStore` がAuthSessionを端末内Keychainへ保存し、access token、refresh token、expires、token type、user id、emailを保持し得る。
- 保存済みsessionは期限切れ又は期限間近の場合にrefresh tokenで更新され、更新後のsessionがKeychainへ保存し直される。
- ログアウト時は端末内sessionを先にclearし、その後Supabase logout APIを呼ぶ。リモートlogout失敗又はtimeoutでも端末内画面はログアウトへ戻る。
- ただし、退会申請成功時に全端末のAuth sessionを必ず失効させる処理、Supabase Authユーザー削除/無効化、Apple / Google連携解除、他端末session、ブラウザ、メール、OSバックアップ、Keychain復元又は外部認証事業者側sessionの即時完全削除は未確認。

### 2.2 未確認・未実装として扱う事項

現時点のコード確認では、次は未確認であり、公開文面やReview Notesで完了保証しない。

- 30日後に実際のAuth、DB、Storage、APNs tokenを削除又は匿名化するジョブ。
- `account_deletion_requests.status='completed'` へ更新する運用又は自動処理。
- 削除申請キャンセルAPI、ログインで自動復帰する処理、`status='cancelled'` 更新処理。
- 削除完了メール又はアプリ内完了通知。
- Sign in with Apple token revoke、Googleログイン連携解除、Supabase Authユーザー削除。
- 退会申請又は削除完了に連動したAPNs token / Expo push tokenの削除又は無効化の完了確認。
- Keychain保存sessionの `kSecAttrAccessible` 方針、ThisDeviceOnly要否、バックアップ/復元/アンインストール時の挙動、全端末session失効手順。

No-Go:
- サポートメールへの問い合わせだけで削除を完了させる。
- 削除入口がヘルプ記事の奥だけにある。
- 「退会」「ログアウト」「利用停止」だけで、アカウント削除がない。
- 削除を完了するために不要なアンケートや引き止めを必須にする。
- 実削除ジョブ、取消処理、token revokeが未確認のまま「30日で必ず削除完了」「ログインで復旧可能」「外部連携も削除済み」と公開する。
- ログアウト又は退会申請だけで、端末内Keychain、他端末、ブラウザ、メール、OSバックアップ、外部認証事業者側の全session/tokenが即時完全削除されると説明する。

### 2.3 確認画面に出す文面

```
アカウントを削除しますか？

削除すると、プロフィール、在庫、wish、打診、取引チャット、投稿、通知設定など、アカウントに紐づく情報の削除又は利用停止処理を行います。

安全対応、法令対応、不正利用防止、課金記録、問い合わせ対応、監査のため、一部の情報は必要な期間保存されることがあります。

有料サブスクリプションを利用している場合、アカウント削除とは別にApp Storeのサブスクリプション管理から解約してください。
```

### 2.4 申請受付後に出す文面

```
アカウント削除の申請を受け付けました。

アカウントは削除申請中になり、Megrumの通常利用が制限されます。削除予定日が表示される場合でも、実際の削除、匿名化、外部サービス上の連携解除、バックアップやログからの消去には時間がかかる場合があります。

誤って申請した場合や、進行中の問い合わせがある場合は、できるだけ早く support@megrum.jp までご連絡ください。取消や復旧を保証するものではありません。
```

## 3. 削除対象データ表

| データ | 通常削除 | 保持する場合 | 保持理由 |
|---|---|---|---|
| 認証アカウント | はい | セキュリティログの一部 | 不正利用防止、監査 |
| メールアドレス | はい | 問い合わせ履歴との紐づきが必要な範囲 | サポート対応、法令対応 |
| プロフィール | はい | 通報・紛争対応中の証跡 | 安全対応 |
| 在庫 / wish | はい | 取引・通報に関わる記録 | 紛争対応 |
| 打診 / ネゴ / 取引 | 原則非表示又は削除 | 進行中、異議申し立て、監査対象 | 取引安全、法令対応 |
| 取引チャット | 原則非表示又は削除 | 通報・異議申し立て・法令対応 | 安全対応 |
| 証跡写真 | 原則削除 | 通報・異議申し立て・法令対応 | 安全対応 |
| グルーム / 掲示板投稿 | 原則削除又は匿名化 | 通報・法令対応 | UGC安全 |
| 通報 / 異議申し立て | 必要期間保持 | 原則保持 | 安全対応、監査 |
| IAP権限 / 購入状態 | 権限停止 | 会計・復元に必要な範囲 | 課金管理 |
| APNs token / Expo push token | 削除又は無効化 | 失効処理、障害調査又は監査に必要な最小記録 | 通知停止、不正利用防止、障害調査 |
| AI入力/出力ログ | AI機能を出す場合のみ削除又は匿名化 | 安全確認に必要な範囲 | 品質、安全対応 |
| 退会申請理由 / 任意メモ | 申請処理後に必要範囲で削除又は分離保存 | 監査、問い合わせ、不正利用防止 | 退会申請の処理履歴 |

## 4. 例外・保留条件

削除を一時保留又は一部保持する可能性がある条件:
- 進行中の取引がある。
- 異議申し立て又は通報対応中である。
- 未払い、返金、チャージバック、IAP権限確認が残っている。
- 不正利用、なりすまし、権利侵害、危険行為の調査中である。
- 法令、裁判所、行政機関、プラットフォーム規約上の保存が必要である。
- ユーザー本人確認が完了していない。

ユーザー向けには、保持する情報の種類、目的、期間の目安をできるだけ具体的に案内する。

## 5. サポート受付フロー

### 5.1 アカウント削除

1. アプリ内の設定から退会申請を開始できるか案内する。
2. アプリ内で進めない場合、登録メールアドレス又は本人確認に必要な最小情報で本人性を確認する。
3. 進行中の取引、通報、異議申し立て、IAP、法令対応の有無を確認する。
4. 削除予定日がある場合は処理予定の目安として案内し、30日完了や復旧可能性を保証しない。
5. 保持対象、サブスクリプション解約、Apple/Google連携解除、退会完了処理に連動した通知token無効化の未確認事項を案内する。
6. 実削除、匿名化、外部連携解除を手動で行った場合は、受付番号、処理者、処理日、根拠を記録する。

### 5.2 個人情報請求

受付対象:
- 利用目的の通知
- 開示
- 訂正、追加、削除
- 利用停止、消去
- 第三者提供停止
- 第三者提供記録の開示

対応フロー:
1. 請求内容を受け付ける。
2. 受付番号を発行する。
3. 本人確認を行う。
4. 対象データと保存先を特定する。
5. 法令上対応できる範囲、非開示又は一部対応の理由を確認する。
6. 手数料が必要な場合は事前に案内する。
7. 回答、訂正、削除、利用停止等を実施する。
8. 対応履歴、担当者、日時、根拠を記録する。

## 6. 受付テンプレート

### 6.1 削除申請受付

```
件名: 【Megrum】アカウント削除申請を受け付けました

Megrumサポートです。
アカウント削除申請を受け付けました。

受付番号:
削除予定日:
確認中の事項:

削除申請中は、Megrumの通常利用が制限されます。
削除予定日が表示される場合でも、実際の削除、匿名化、外部サービス上の連携解除、バックアップやログからの消去には時間がかかる場合があります。
安全対応、法令対応、不正利用防止、課金記録、問い合わせ対応、監査のため、一部情報は必要な範囲で保存される場合があります。

有料サブスクリプションをご利用中の場合、アカウント削除とは別にApp Storeのサブスクリプション管理から解約してください。
```

### 6.2 削除完了（実削除又は匿名化を確認した場合のみ）

```
件名: 【Megrum】アカウント削除が完了しました

Megrumサポートです。
以下の受付番号について、アカウント削除処理が完了しました。

受付番号:
完了日:

法令対応、不正利用防止、紛争対応、課金記録、問い合わせ対応、監査のために保存が必要な情報がある場合は、必要な期間に限って保存します。
```

### 6.3 個人情報請求受付

```
件名: 【Megrum】個人情報に関するご請求を受け付けました

Megrumサポートです。
個人情報に関するご請求を受け付けました。

受付番号:
請求内容:
追加確認:

本人確認と対象情報の特定を行ったうえで、法令に従って対応します。
回答に時間を要する場合や、法令上ご希望の全部又は一部に対応できない場合は、その理由を案内します。
```

## 7. 実装・運用チェックリスト

| 項目 | 状態 |
|---|---|
| アプリ内削除入口が設定画面から見つかる | 確認済（設定 > 退会する） |
| 削除前確認で主な削除対象と保持対象を説明している | 一部確認済（安全記録保持、通常利用制限、進行中取引ブロック）。全画面ブロックは未確認 |
| 明示的な最終確認がある | 確認済 |
| 削除申請理由と任意メモを保存する | 確認済（`account_deletion_requests`） |
| 削除申請後に削除予定日が残る | 確認済（30日後予定日） |
| 削除完了通知を送れる | 未 |
| APNs tokenを削除又は無効化できる | 一部確認済（ログアウト時のclient-side revoke、APNs失効応答時のEdge Function revoke、退会申請RPCでの全device revoke migration）。削除完了時の横断削除、本番適用、外部provider側の完全削除は未確認 |
| 端末内Keychain sessionを削除できる | 一部確認済（ログアウト時のlocal clear）。退会申請/削除完了、他端末session、外部認証事業者側sessionへの連動は未確認 |
| Sign in with Appleのtoken revoke要否を確認した | 未 |
| Googleログイン連携解除の要否を確認した | 未 |
| 削除申請キャンセル又はログイン復旧の処理がある | 未確認 |
| 実削除ジョブ又は手動削除手順がある | 未確認 |
| IAP利用者にApple側の解約導線を案内している | 文面上は反映、アプリ内表示は要確認 |
| サポートテンプレートが `notes/34` と矛盾しない | 未 |
| 公開ページ `support/account-deletion` と文面が一致する | 未 |
| 公開ページ `support/privacy-request` と文面が一致する | 未 |
| App Review Notesに削除入口を案内できる | 未 |

## 8. App Review Notes差し込み案

```
Account deletion can be initiated in the app from Settings > Delete Account.
The flow blocks deletion while an active trade is in progress, asks the user to select a reason, shows a final confirmation, and marks the account as deletion requested when the request is submitted.
The user-facing legal and support pages explain data that may be deleted, disabled, anonymized, or retained for legal, safety, fraud prevention, billing, support, audit, or technical reasons, and explain that App Store subscriptions must be managed separately.
If Sign in with Apple, Google login, or push notifications are enabled in the submitted build, the deletion operation, external-provider revocation/connection removal, and push-token invalidation status must be verified before submission.
```

## 9. No-Go

- アカウント作成があるのにアプリ内削除入口がない。
- 削除入口がサポートメールだけになっている。
- 一時停止やログアウトだけでアカウント削除を提供していない。
- 削除対象と保持対象を説明していない。
- IAP利用者にサブスクリプション解約が別途必要であることを説明していない。
- Sign in with Appleを使うのにtoken revoke要否を確認していない。
- 個人情報請求の受付窓口、本人確認、対応履歴がない。
- 実削除ジョブ、削除完了処理、申請取消処理が未確認なのに、公開ページで「30日後に必ず削除」「ログインで復旧可能」と説明する。
- Keychain保存session、refresh token、他端末session、外部認証事業者側sessionの確認なしに、退会で全session/tokenが即時完全削除されると説明する。
- 退会申請メモに第三者の個人情報や取引相手特定情報を書かせる、又は不要なアンケートを必須にする。

## 10. 公式参照

- Apple Account Deletion: https://developer.apple.com/support/offering-account-deletion-in-your-app/
- Apple TN3194 Sign in with Apple account deletion/token revocation: https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- 個人情報保護委員会 Q&A: https://www.ppc.go.jp/personalinfo/faq/APPI_QA/
- 個人情報保護委員会 通則ガイドライン: https://www.ppc.go.jp/personalinfo/legal/guidelines_tsusoku/
