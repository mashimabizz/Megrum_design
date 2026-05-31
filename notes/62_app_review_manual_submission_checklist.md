# 62. App Review手動提出チェックリスト

最終更新: 2026-05-31

ステータス: Draft v0.1（提出直前・手動操作用）

## 目的

App Store ConnectでMegrumの完成ビルドを審査提出する直前に、提出者が画面を見ながら最終確認できるチェックリスト。

この文書は提出操作の照合表であり、コード、App Store Connect設定、Apple Developer設定、DNS、公開URLは変更しない。

## 1. 使うタイミング

使うタイミング:
- 完成候補ビルドがApp Store Connectで処理完了している。
- TestFlight内部確認が終わっている。
- `notes/42_p0_smoke_test_script.md` のP0確認結果が記録されている。
- `notes/36_submission_evidence_checklist.md` に提出証跡を残す準備ができている。
- `notes/64_release_evidence_folder_index.md` に従って証跡保存先とmanifest方針が決まっている。
- `notes/70_app_store_product_page_asset_qa.md` でApp icon、スクショ、App Preview、poster frame、Product Page Previewを確認している。
- `notes/71_app_store_connect_final_input_reconciliation.md` でApp Store Connectの実入力値と提出docs/buildを照合している。
- 公開URL、App Privacy、Review Notes、デモアカウント、スクショが提出候補になっている。

使わないタイミング:
- ビルドが未アップロード。
- デモアカウントでログインできない。
- プライバシーポリシーURL又はサポートURLが未公開。
- 初回提出で出す/隠す機能が未確定。
- App Store Connectの提出権限が未確認。

## 2. 公式前提の要点

Apple公式ヘルプ上、App Store審査提出では、アプリバージョンに必要なメタデータを入力し、正しいビルドを選択したうえでAdd for Review、Draft Submission、Submit for Reviewの流れに進む。

提出に必要な権限は、Account Holder、Admin、又はApp Manager相当の確認が必要。App Privacyの入力・更新はApp Store Connect上で公開前に実装実態と一致させる。

この文書では、Apple公式の画面名を参照しつつ、Megrumで確認すべき項目へ分解する。

## 3. 提出者・環境

| 項目 | 値 |
|---|---|
| 提出予定日 | TODO |
| 提出者 | TODO |
| Apple Developer Team | TODO |
| App Store Connect権限 | Account Holder / Admin / App Manager / Other |
| 2FA確認 | Pass / Fail |
| 対象App Record | Megrum |
| 対象Bundle ID | TODO |
| Version | TODO |
| Build Number | TODO |
| 確認端末 | TODO |
| 証跡保存先 | TODO |

No-Go:
- 提出者が提出権限を持たない。
- 2FAを完了できない。
- 対象App Record又はBundle IDが不明。
- 完成候補ではないBuild Numberを選びそうな状態。

## 4. 提出前フリーズ確認

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| FR-001 | 開発セッションから、提出候補のVersion/Build Numberが共有されている | TODO | TODO |
| FR-002 | 提出候補ビルド以降にP0コード修正が入っていない | TODO | TODO |
| FR-003 | 初回提出スコープ露出監査がPass又は提出判断済み | TODO | `notes/59` |
| FR-004 | Go / No-Go判定がGo又はConditional Go | TODO | `notes/50` |
| FR-005 | 公開URLが200応答、ログイン不要、HTTPS | TODO | `notes/37` |
| FR-006 | サポートメール又は問い合わせ導線が受信確認済み | TODO | `notes/47` |
| FR-007 | 権限・運用アカウント台帳のP0が埋まっている | TODO | `notes/61` |
| FR-008 | App Store Connect最終入力差分QAがPass又は提出判断済み | TODO | `notes/71` |

No-Go:
- 提出候補ビルドとテスト済みビルドが違う。
- P0修正が入ったのに新ビルドで再確認していない。
- 公開URLが404又はログイン必須。

## 5. App Information確認

App Store Connect > Apps > Megrum > App Informationで確認する。

| Check | 項目 | 期待値 | 結果 |
|---|---|---|---|
| AI-001 | Name | Megrum | TODO |
| AI-002 | Bundle ID | 提出対象と一致 | TODO |
| AI-003 | SKU | 内部管理値として妥当 | TODO |
| AI-004 | Primary Language | Japanese想定 | TODO |
| AI-005 | Category | ライフスタイル又はソーシャルネットワーキングの最終判断と一致 | TODO |
| AI-006 | Privacy Policy URL | `https://megrum.jp/legal/privacy` 又は採用URL | TODO |
| AI-007 | Support URL | `https://megrum.jp/support` 又は採用URL | TODO |
| AI-008 | Content Rights | 第三者素材の扱いと一致 | TODO |
| AI-009 | Age Rating | `notes/46` と一致 | TODO |

No-Go:
- NameやSubtitleが完成ビルド、スクショ、公開URLと食い違う。
- Privacy Policy URLが未入力又は非公開。
- Categoryが`Info.plist`やメタデータ方針と説明不能にズレている。

## 6. Version Metadata確認

App Store Connect > 対象Versionで確認する。

| Check | 項目 | 期待値 | 結果 |
|---|---|---|---|
| VM-001 | Version string | 開発側が指定したVersion | TODO |
| VM-002 | Promotional Text | 初回提出スコープだけを説明 | TODO |
| VM-003 | Description | `notes/40` の最終候補と一致 | TODO |
| VM-004 | Keywords | 100 bytes以内、権利侵害に見えない | TODO |
| VM-005 | Subtitle | 30文字以内、過剰保証なし | TODO |
| VM-006 | Marketing URL | 空欄又は公開URL | TODO |
| VM-007 | Copyright | オーナー確認済み表記 | TODO |
| VM-008 | Contact URL等 | 必要欄が公開URLと一致 | TODO |

No-Go:
- 初回で隠す有料機能、外部AI、未完成3Dを訴求している。
- 住所登録や現地外の交換手段を初回スコープのように説明している。
- 実在IPの公式提供アプリに見える表現が残っている。

## 7. Screenshots / App Preview確認

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| SS-001 | 必須デバイスサイズのスクショが揃っている | TODO | TODO |
| SS-002 | 画像が完成候補ビルド由来である | TODO | TODO |
| SS-003 | 実住所、実在メール、内部ID、debug表示がない | TODO | TODO |
| SS-004 | 未完成機能が写っていない | TODO | TODO |
| SS-005 | スクショの文言がメタデータと矛盾しない | TODO | TODO |
| SS-006 | 通報/ブロック/削除/サポート導線を説明できる | TODO | TODO |
| SS-007 | App icon、App Preview、poster frame、Product Page Previewが `notes/70` と一致 | TODO | TODO |

No-Go:
- スクショが古いUI。
- 実ユーザーデータが写っている。
- 審査員が辿れない機能をスクショで見せている。

## 8. Build確認

Version画面のBuildセクションで確認する。

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| BD-001 | 正しいBuild Numberを選択している | TODO | TODO |
| BD-002 | Processing完了済み | TODO | TODO |
| BD-003 | Missing Compliance等の警告がない、又は回答済み | TODO | TODO |
| BD-004 | TestFlightで確認したBuildと一致 | TODO | TODO |
| BD-005 | Export Compliance回答が `notes/46` と一致 | TODO | TODO |
| BD-006 | Privacy Manifest / SDK監査メモと矛盾しない | TODO | `notes/44` |

No-Go:
- TestFlightで確認していないBuildを選択している。
- Compliance警告を理解しないまま進める。
- Privacy ManifestやSDKの確認が未完了。

## 9. App Privacy確認

App Store Connect > App Privacyで確認する。

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| AP-001 | Privacy Policy URLが公開URLと一致 | TODO | TODO |
| AP-002 | 収集データ回答が `notes/27` / `notes/43` と一致 | TODO | TODO |
| AP-003 | Supabase、Apple、Google、地図、決済、AI候補の扱いが反映済み | TODO | `notes/48` |
| AP-004 | 追跡の有無が実装と一致 | TODO | TODO |
| AP-005 | アカウント削除・個人情報請求の導線が説明可能 | TODO | `notes/45` |
| AP-006 | 外部AIを出す場合、送信データと説明がPrivacy回答に反映済み | TODO | TODO |

No-Go:
- 実装で収集しているデータが未申告。
- 外部SDKの収集データを確認していない。
- 外部AIが見えるのにPrivacy回答と規約/ポリシーに説明がない。

## 10. App Review Information確認

| Check | 項目 | 期待値 | 結果 |
|---|---|---|---|
| AR-001 | Contact first/last name | 対応可能な担当 | TODO |
| AR-002 | Contact phone | 審査対応可能な番号 | TODO |
| AR-003 | Contact email | 審査対応可能なメール | TODO |
| AR-004 | Demo account username | App Store Connectだけに実値入力 | TODO |
| AR-005 | Demo account password | リポジトリに書かずApp Store Connectだけに入力 | TODO |
| AR-006 | Notes | `notes/40` / `notes/60` の最終Review Notesと一致 | TODO |
| AR-007 | Attachment | 必要な補足がある場合だけ添付 | TODO |

Review Notesで必ず触れること:
- Megrumはユーザー同士の現地交換調整アプリである。
- アカウントが必要な理由。
- デモアカウントで確認できる主要経路。
- 通報、ブロック、問い合わせ、アカウント削除の場所。
- 初回で有料機能、外部AI、未完成3Dを隠す場合は、見えないこと。
- 公開URLがログイン不要であること。

No-Go:
- デモアカウントでログインできない。
- 実パスワードをリポジトリや公開文書に書く。
- Review Notesに完成ビルドで辿れない画面を書く。

## 11. IAP / 同時提出アイテム確認

| Check | 確認 | 結果 | 証跡 |
|---|---|---|---|
| IA-001 | 初回で有料機能を出すか最終判断済み | TODO | `notes/33` |
| IA-002 | 出す場合、IAP商品がReady to Submit相当 | TODO | TODO |
| IA-003 | 出す場合、価格、表示名、説明、特商法表示が一致 | TODO | TODO |
| IA-004 | 隠す場合、アプリ、スクショ、説明文、Review Notesに露出なし | TODO | `notes/59` |
| IA-005 | 同時提出するIAP/イベント/追加アイテムがDraft Submissionに含まれている | TODO | TODO |

No-Go:
- 有料機能が見えるのにIAP未設定。
- IAPを同時提出する必要があるのにSubmissionへ入れていない。
- 特商法表示や価格説明と矛盾する。

## 12. Add for Review直前チェック

| Check | 確認 | 結果 |
|---|---|---|
| AF-001 | `notes/36` の証跡欄を開いている | TODO |
| AF-002 | `notes/50` の最終判定がGo/Conditional Go | TODO |
| AF-003 | Version/Build/Review Notes/App Privacyのスクショ又は控えを保存した | TODO |
| AF-004 | 開発セッションに「このBuildで提出へ進む」ことを共有した | TODO |
| AF-005 | これ以降のコード修正は次ビルド扱いになることを確認した | TODO |

操作:
1. 対象Version右上のAdd for Reviewを押す。
2. 新規Draft Submission又は既存Draft Submissionを選ぶ。
3. Draft Submissionに対象Versionが入っていることを確認する。
4. 同時提出するIAP等がある場合、同じSubmissionに含める。

No-Go:
- 違うVersion/BuildをAdd for Reviewしている。
- IAP等の同時提出アイテムを入れ忘れている。
- 証跡保存前に進めようとしている。

## 13. Submit for Review直前チェック

| Check | 確認 | 結果 |
|---|---|---|
| SR-001 | Draft SubmissionにMegrumの正しいVersionが入っている | TODO |
| SR-002 | 同時提出アイテムの有無が最終判断と一致 | TODO |
| SR-003 | Submit for Review後のステータス記録欄を用意した | TODO |
| SR-004 | リジェクト時の対応先が決まっている | TODO |
| SR-005 | 承認後の公開方法が手動/自動のどちらか決まっている | TODO |

操作:
1. Draft Submissionを開く。
2. 内容を最終確認する。
3. Submit for Reviewを押す。
4. ステータスがReady for Review、Waiting for Review、又はIn Reviewへ進んだことを記録する。

No-Go:
- 提出後の監視担当がいない。
- 承認後の公開方法が未決。
- リジェクト文の保存先が未決。

## 14. 提出直後に記録すること

| 項目 | 値 |
|---|---|
| Submit日時 | TODO |
| App Store Connect status | TODO |
| Version | TODO |
| Build Number | TODO |
| 提出者 | TODO |
| 同時提出アイテム | TODO |
| Review Notes最終版 | TODO |
| App Privacy回答控え | TODO |
| 公開URL確認結果 | TODO |
| 証跡保存先 | TODO |
| 次の監視担当 | TODO |

提出直後に行うこと:
1. `notes/36_submission_evidence_checklist.md` に証跡を追記する。
2. `notes/51_post_submission_release_day_runbook.md` の提出後監視へ移る。
3. リジェクトが来た場合は `notes/41_app_review_response_templates.md` へ指摘文を転記する。

## 15. 関連文書

- 全体司令塔: `notes/39_release_command_center.md`
- TestFlight / Submit手順: `notes/32_testflight_review_submission_runbook.md`
- App Store Connect入力: `notes/31_app_store_connect_metadata_worksheet.md`
- 転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- ローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- 商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 提出証跡: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
- 初回提出スコープ露出監査: `notes/59_initial_release_scope_exposure_audit.md`
- リリース権限・運用アカウント: `notes/61_release_access_owner_registry.md`
- 提出後・公開初日運用: `notes/51_post_submission_release_day_runbook.md`

## 16. 公式参照

- Apple Submit an App: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- Apple Overview of Submitting for Review: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/overview-of-submitting-for-review/
- Apple App information: https://developer.apple.com/help/app-store-connect/reference/app-information
- Apple Manage App Privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Apple App privacy details: https://developer.apple.com/app-store/app-privacy-details/
