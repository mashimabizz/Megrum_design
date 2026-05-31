# 51. App Store提出後・公開初日ランブック

最終更新: 2026-05-31

ステータス: Draft v0.1（初回提出前）

## 目的

App StoreへSubmit for Reviewした後、審査待ち、審査中、承認、手動公開、公開初日の監視を迷わず進める。

この文書は運用手順であり、コード、DB、ビルド設定、App Store Connect設定は変更しない。

## 1. 初回提出の推奨リリース方式

初回提出では、承認後すぐ自動公開ではなく、**手動公開**を推奨する。

理由:
- 承認後に公開URL、サポートメール、App Privacy、デモデータ、スクショ、問い合わせ導線を最終確認できる。
- `Pending Developer Release` 状態で止められるため、公開前のGo / No-Go判定を再実施できる。
- 公開直前に発覚した事故疑い、外部サービス不一致、メタデータ不一致を止めやすい。

Apple公式情報では、手動公開を選んだ場合、承認後にステータスが `Pending Developer Release` になり、App Store Connectで `Release This Version` を押して公開する。手動公開後、App Storeに表示されるまで最大24時間かかる場合がある。

将来のアップデートでは、7日間の段階的リリースを検討できる。ただし段階的リリース中でも、ユーザーはApp Storeから手動でダウンロードできる。

## 2. ステータス別対応

| App Store Connect状態 | 意味 | Megrum側の対応 |
|---|---|---|
| Ready for Review | Add for Review済み、Submit前 | 入力漏れを確認し、`notes/50` でGo判定 |
| Waiting for Review | Appleが受領、審査開始前 | URL、メール、サポート、デモアカウントを毎日確認 |
| In Review | Apple審査中 | App Review連絡を監視。機能やURLを勝手に変えない |
| Waiting for Export Compliance | 輸出コンプライアンス確認中 | `notes/46` の回答とInfo.plistを確認 |
| Pending Developer Release | 承認済み、手動公開待ち | 公開直前チェック後にRelease This Version |
| Processing for Distribution | 公開処理中 | 最大24時間の反映を見込み、証跡を残す |
| Ready for Distribution / Available | 公開状態 | 公開初日監視へ移る |
| Metadata Rejected | メタデータ不備 | `notes/41` で返信/修正。コード修正不要か切り分ける |
| Rejected | アプリ又は提出物が不承認 | 指摘文を保存し、`notes/41` で対応方針を分解 |
| Invalid Binary | バイナリ要件不一致 | 開発セッションへ新ビルド修正を依頼 |

## 3. Submit直後チェック

Submit for Review後、次を記録する。

| 項目 | 記録 |
|---|---|
| Submitted at | TODO |
| Submitted by | TODO |
| Version / Build | TODO |
| Release option | Manual / Automatic / Date |
| App Review status | TODO |
| Review Notes final | `notes/40` の最終文面 |
| Evidence folder | TODO |

Submit後にやること:
- [ ] App Store Connectのステータスをスクショ又は記録する
- [ ] `notes/36` に提出日時、Version、Buildを記録する
- [ ] Support URL、Privacy Policy URL、Terms URLが引き続き200応答か確認する
- [ ] `support@megrum.jp` へテストメールを送り、受信を確認する
- [ ] App Reviewからの連絡先メールを受信できる状態にする

## 4. 審査中の毎日確認

| 項目 | 頻度 | No-Go |
|---|---|---|
| App Store Connectのステータス | 1日2回 | Rejected / Metadata Rejectedを見落とす |
| Resolution Center / App Reviewメッセージ | 1日2回 | 返信期限や確認依頼を見落とす |
| `support@megrum.jp` | 1日1回以上 | 審査員又はユーザーからの連絡を見落とす |
| 公開URL | 1日1回 | Privacy / Support URLが404 |
| デモアカウント | 1日1回 | パスワード変更、メール確認切れ、ログイン不能 |
| 事故疑い | 随時 | `notes/49` の初動なし |

審査中に公開ページやApp Privacyの実質内容を変える場合は、変更理由と変更箇所を `notes/36` に記録する。

## 5. 指摘を受けた場合

| 指摘 | 初動 |
|---|---|
| メタデータだけ | `notes/41` のMetadataテンプレートで返信案を作る |
| URL不備 | `notes/37` / `notes/47` で公開状態を直し、証跡を追加 |
| App Privacy不一致 | `notes/27` / `notes/43` / `notes/44` / `notes/48` を再照合 |
| UGC安全 | `notes/26` と実画面の通報/ブロック証跡を添えて説明 |
| アカウント削除 | `notes/45` と実画面証跡を添えて説明 |
| IAP | `notes/33` で商品、価格、復元、特商法を確認 |
| 外部AI | AI導線を隠すか、説明/同意/Privacy回答を揃える |
| コード修正が必要 | 開発セッションへ切り出し、新ビルド後に再提出 |

指摘本文は全文保存し、返信前に「メタデータ修正で済むか」「新ビルドが必要か」を分ける。

## 6. 承認後の公開直前チェック

`Pending Developer Release` になったら、公開前に次を確認する。

- [ ] `notes/50` のG0〜G11がGo又はConditional Go
- [ ] Support URL、Privacy Policy URL、Terms URL、Commerce URLが開く
- [ ] `support@megrum.jp` が受信できる
- [ ] App Store ConnectのApp Privacy回答が最終ビルドと一致している
- [ ] スクショに実住所、実在IP、内部ID、デバッグ表示がない
- [ ] デモアカウントに実在ユーザーの個人情報が入っていない
- [ ] 外部AI、有料機能、未完成3Dが意図せず見えていない
- [ ] 事故疑い、公開URL障害、サポートメール障害がない

No-GoならRelease This Versionを押さず、原因を解消する。

## 7. 手動公開手順

実際のApp Store Connect画面で担当者が実施する。

1. AppsでMegrumを開く。
2. 該当するiOSバージョンを開く。
3. ステータスが `Pending Developer Release` であることを確認する。
4. `Release This Version` を選択する。
5. 確認ダイアログでConfirmする。
6. 公開処理中のステータスと時刻を `notes/36` に記録する。
7. App Storeで表示されるまで最大24時間を見込んで監視する。

## 8. 公開初日チェック

| 時点 | やること |
|---|---|
| T+0 | App Store Connectのステータス、公開処理時刻、公開国/地域を記録 |
| T+1h | App Store検索、直リンク、Privacy URL、Support URLを確認 |
| T+3h | 実端末でApp Storeから入手できるか確認 |
| T+6h | 新規登録、ログイン、在庫、wish、打診、取引チャットを軽く確認 |
| T+12h | サポートメール、App Store Connectメッセージ、TestFlightフィードバックを確認 |
| T+24h | 初日まとめ、未対応問い合わせ、次ビルド候補を記録 |

公開初日は、機能追加ではなく、ログイン不能、URL不通、削除導線、App Privacy不一致、重大通報の監視を優先する。

## 9. 公開後に止める判断

次が起きたら、機能停止、公開停止、新ビルド、サポート告知の要否を判断する。

- ログイン不能が複数発生する。
- 他人のデータが見える。
- 位置情報又は取引チャットが意図しない相手に見える。
- 支払い又はIAP権限が壊れている。
- アカウント削除が動かない。
- Privacy URL又はSupport URLが落ちている。
- 不正アクセス又は秘密情報流出の疑いがある。

個人情報又はセキュリティ事故疑いは `notes/49`、App Reviewや公開メタデータの問題は `notes/41`、次回提出判断は `notes/50` を使う。

## 10. 将来アップデート時の段階的リリース

初回公開後のアップデートでは、App Store Connectの段階的リリースを検討する。

Apple公式情報では、段階的リリースは7日間で自動アップデート対象へ広げる方式で、1日目1%、2日目2%、3日目5%、4日目10%、5日目20%、6日目50%、7日目100%の割合が示されている。

注意:
- 段階的リリース中でも、ユーザーはApp Storeから手動でダウンロードできる。
- 一時停止は合計30日まで可能。
- 初回公開より、既存ユーザーがいるアップデートで使う想定。

## 11. 公式参照

- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple App and submission statuses: https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses
- Apple Select an App Store version release option: https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option/
- Apple Release a version update in phases: https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases
