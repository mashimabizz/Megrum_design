# 71. App Store Connect最終入力差分QA

最終更新: 2026-05-31

ステータス: Draft v0.1（App Store Connect入力後・Submit前）

## 目的

App Store Connectへ実際に入力した値を、完成候補build、`notes/31`、`notes/40`、公開URL、App Privacy回答、Review Notes、スクリーンショット、商品ページ素材QAと照合し、Submit for Review直前の取り違えを防ぐ。

この文書は最終照合台帳であり、コード、App Store Connect設定、Apple Developer設定、公開URL、証跡ファイル自体は変更しない。

## 1. 公式前提の要点

Apple公式ヘルプ上、App Store提出には必要なmetadataと対象versionのbuild選択が必要になる。提出操作は、対象app versionで正しいbuildを確認し、Add for ReviewでDraft Submissionへ入れ、最後にSubmit for Reviewを押す流れになる。

App informationには、Name、Subtitle、Bundle ID、SKU、Primary Language、Category、Content Rights、License Agreement等の共有propertyが含まれる。Nameは2〜30文字、Subtitleは30文字以内。Privacy Policy URLはiOS/macOS appで必須。Bundle IDはbuild upload後に変更できず、Xcode project側のBundle IDと一致する必要がある。SKUもapp record追加後は変更できない。

Platform version informationには、Screenshots、App Preview、Promotional Text、Description、Keywords、Support URL、Marketing URL、Version Number、Copyright等が含まれる。Screenshotsは必須でlocalize可能。App Previewは任意で、localization/device sizeごとに最大3本。Promotional Textは170文字以内。Descriptionは4000文字以内、plain textでHTML不可。Keywordsは100 bytes以内で、app name/company nameの重複や他app/company名の利用を避ける必要がある。Support URLは必須で、protocolを含む完全なURLが必要。

## 2. 使うタイミング

使う:
- App Store Connectへmetadata、screenshots/App Preview、App Privacy、Review Notes、build、IAP等を入力した後。
- Add for Reviewを押す前。
- Metadata Rejected後に、同じbuildでmetadataだけ修正した後。

使わない:
- 完成候補buildが未確定。
- App Store Connectへ未入力。
- デモアカウントや公開URLが未確定。
- 実パスワード、secret、tokenを記録しそうな状態。

## 3. 入力スナップショット

| 項目 | 値 |
|---|---|
| 照合日 | TODO |
| 照合者 | TODO |
| App Store Connect app record | Megrum |
| Version | TODO |
| Build Number | TODO |
| Bundle ID | TODO |
| Primary Language | TODO |
| Localizations | Japanese / English (U.S.) / Other |
| Draft Submission ID又は画面上の識別 | TODO |
| 同時提出item | None / IAP / In-App Event / Other |
| 証跡保存先 | TODO |

保存しない:
- Demo account password
- 2FA code
- secret、token、private key
- 実代表者情報、個人住所、個人電話番号
- App Store Connect担当者の個人情報が大きく写った管理画面

## 4. App Information差分QA

| Check | App Store Connect欄 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-FI-001 | Name | `Megrum`。`notes/31` / `notes/40` と一致 | TODO | TODO |
| ASC-FI-002 | Subtitle | 初回スコープと一致、30文字以内、過剰保証なし | TODO | TODO |
| ASC-FI-003 | Bundle ID | 完成候補build、開発側ハンドオフ、Xcode設定と一致 | TODO | `notes/65` |
| ASC-FI-004 | SKU | 内部管理値として妥当。変更不可であることを理解 | TODO | TODO |
| ASC-FI-005 | Primary Language | Japanese方針と一致 | TODO | `notes/31` |
| ASC-FI-006 | Primary/Secondary Category | `notes/31` / `notes/46` の判断と一致 | TODO | TODO |
| ASC-FI-007 | Privacy Policy URL | 公開済み、HTTPS、ログイン不要、`notes/37` と一致 | TODO | `notes/37` |
| ASC-FI-008 | Content Rights | 架空データ/UGC/権利侵害禁止の説明と一致 | TODO | `notes/46` |
| ASC-FI-009 | Age Rating | 質問票回答、UGC、チャット、IAP、AI露出と一致 | TODO | `notes/46` |
| ASC-FI-010 | License Agreement | Apple標準EULA/独自規約URL方針と一致 | TODO | `notes/31` |

No-Go:
- Bundle ID、Name、Primary Language、Categoryの取り違えがある。
- Privacy Policy URLが404、ログイン必須、又は別内容。
- Content Rightsがスクショ/初期データ/UGC実態と矛盾している。

## 5. Version Metadata差分QA

| Check | App Store Connect欄 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-VM-001 | Version Number | 開発側ハンドオフ、TestFlight確認buildと一致 | TODO | `notes/65` |
| ASC-VM-002 | Promotional Text | `notes/40` の最終候補と一致、170文字以内 | TODO | TODO |
| ASC-VM-003 | Description | 出す機能だけ説明、4000文字以内、HTMLなし | TODO | `notes/40` |
| ASC-VM-004 | Keywords | 100 bytes以内、app名/company名重複なし、他社名なし | TODO | TODO |
| ASC-VM-005 | Support URL | 公開済み、HTTPS、ログイン不要、連絡導線あり | TODO | `notes/37`, `notes/47` |
| ASC-VM-006 | Marketing URL | 入れる場合、公開済みで初回スコープと一致 | TODO | `notes/37` |
| ASC-VM-007 | Copyright | オーナー確認済み表記。Appleがsymbolを付ける前提で過不足なし | TODO | TODO |
| ASC-VM-008 | Screenshots/App Preview | `notes/70` の商品ページ素材QAと一致 | TODO | `notes/70` |
| ASC-VM-009 | Localization | `notes/60` と一致。English (U.S.)を出す場合は英語文面/素材も確認 | TODO | `notes/60` |

No-Go:
- 未完成の有料機能、外部AI、未完成3D、現地外の交換手段を説明している。
- DescriptionやReview Notesだけに、完成buildで辿れない機能が残る。
- Keywordsに実在IP、他app名、他社名、過剰な検索語が入る。
- Support URLに問い合わせ、削除、通報、Privacy請求へ辿る導線がない。

## 6. App Review Information差分QA

| Check | App Store Connect欄 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-AR-001 | Contact name | 審査中に対応できる担当。公開docsに実名を転記しない | TODO | TODO |
| ASC-AR-002 | Contact phone | 審査対応可能。公開リポジトリに書かない | TODO | TODO |
| ASC-AR-003 | Contact email | 受信確認済み。`support@megrum.jp` 又は審査用連絡先 | TODO | `notes/47`, `notes/67` |
| ASC-AR-004 | Demo account username | `notes/35` の方針と一致。実値はApp Store Connectだけ | TODO | `notes/35` |
| ASC-AR-005 | Demo account password | リポジトリや証跡に保存しない | TODO | TODO |
| ASC-AR-006 | Review Notes | `notes/40` / `notes/60` の最終Review Notesと一致 | TODO | TODO |
| ASC-AR-007 | Attachment | 必要な場合のみ。secretや個人情報を含まない | TODO | TODO |

Review NotesのNo-Go:
- Demo account passwordを公開リポジトリや証跡へ残す。
- 審査員が辿れない機能、隠した機能、未完成機能を説明する。
- UGC、安全、削除、公開URLの説明が実buildと違う。

## 7. App Privacy / 質問票 / IAP差分QA

| Check | 領域 | 期待値/照合元 | 結果 | 証跡 |
|---|---|---|---|---|
| ASC-PI-001 | App Privacy | `notes/27` / `notes/43` / 実SDK/通信と一致 | TODO | TODO |
| ASC-PI-002 | Privacy Policy URL | App Privacy欄とApp Information欄で同じ公開URL | TODO | TODO |
| ASC-PI-003 | Export Compliance | `notes/46`、Info.plist、実buildと一致 | TODO | TODO |
| ASC-PI-004 | Age Rating | `notes/46` と一致 | TODO | TODO |
| ASC-PI-005 | Content Rights | `notes/46`、スクショ、初期データ、UGC方針と一致 | TODO | TODO |
| ASC-PI-006 | IAP | 出す/隠す判断、価格、Availability、特商法表示と一致 | TODO | `notes/33`, `notes/68` |
| ASC-PI-007 | DSA / Territory | 初回配信地域、DSA status、公開連絡先方針と一致 | TODO | `notes/68` |
| ASC-PI-008 | Draft Submission items | 同時提出itemの有無が `notes/62` と一致 | TODO | TODO |

No-Go:
- App Privacy回答と実buildのSDK/通信が違う。
- 有料機能が見えるのにIAPが未提出又は価格/Availabilityが未確認。
- DSAや配信地域の判断が未確定のままAll Countries等を選んでいる。

## 8. 差分対応判断

| 差分 | 対応 | 提出可否 |
|---|---|---|
| 誤字、軽微な表現ゆれ | `notes/40` 又はApp Store Connectの入力値を合わせる | 修正後に可 |
| 説明文に未露出機能が残る | 説明文、スクショ、Review Notesから削る | 削除後に可 |
| App Privacy回答漏れ | `notes/43` とApp Store Connect回答を修正し、実buildと再照合 | 修正後に可 |
| Build/Version取り違え | 正しいbuildへ差し替え、`notes/65` と証跡を再確認 | 修正後に可 |
| コード修正が必要な差分 | 開発側セッションへnew build依頼 | 現buildではNo-Go |
| 法務レビュー回答と矛盾 | `notes/58` / `notes/66` へ戻して公開文面も修正 | 修正後に再判定 |
| 実パスワードやsecretを証跡に保存した | 証跡を破棄し、安全な記録へ作り直す | 作り直しまでNo-Go |

## 9. 最終サインオフ

| 項目 | 判定 | 証跡 |
|---|---|---|
| App Information | Pass / Conditional / Fail | TODO |
| Version Metadata | Pass / Conditional / Fail | TODO |
| Screenshots / App Preview | Pass / Conditional / Fail | TODO |
| App Privacy | Pass / Conditional / Fail | TODO |
| Review Notes | Pass / Conditional / Fail | TODO |
| Review Contact / Demo Account | Pass / Conditional / Fail | TODO |
| IAP / 同時提出item | Pass / Conditional / Fail / Not exposed | TODO |
| DSA / Territory | Pass / Conditional / Fail | TODO |
| Draft Submission | Pass / Conditional / Fail | TODO |

最終判定:

```text
Decision: Go / Conditional Go / No-Go
Version:
Build:
Reviewed by:
Reviewed at:
Required fixes before Submit:
Evidence folder:
```

## 10. 関連文書

- App Store提出パック: `notes/24_app_store_submission_pack.md`
- App Store Connect入力ワークシート: `notes/31_app_store_connect_metadata_worksheet.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- App Storeローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- App Store商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- 配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`

## 11. 公式参照

- Apple Required, localizable, and editable properties: https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties
- Apple App information: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Apple Platform version information: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- Apple Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
