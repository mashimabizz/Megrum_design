# 70. App Store商品ページ素材QAチェックリスト

最終更新: 2026-05-31

ステータス: Draft v0.1（撮影前・App Store Connect入力前）

## 目的

App Store商品ページに表示されるApp icon、スクリーンショット、App Preview、poster frame、ローカライズ別素材が、完成候補ビルド、App Store説明文、Review Notes、App Privacy、権利処理、初回提出スコープと矛盾しないかを最終確認する。

この文書は商品ページ素材のQA表であり、コード、Xcode asset catalog、App Store Connect設定、画像/動画ファイル自体は変更しない。

## 1. 公式前提の要点

Apple公式ヘルプ上、App iconはXcode project内のiconをbuildへ含め、buildをApp Store Connectへアップロードする流れになる。公開後にApp iconを変更するには、新しいversionを作成し、buildをアップロードしてreviewへ提出する必要がある。

スクリーンショットとApp Previewは、App Store Connectのapp version画面でアップロードする。スクリーンショットは1〜10枚、形式は `.jpeg` / `.jpg` / `.png`。App Previewは任意で、iOS等ではsupported device sizeと言語ごとに最大3本までアップロードできる。

App PreviewはiPhone、iPad、Mac、Apple TVではスクリーンショットより先に表示される。App Previewを使う場合はposter frameも商品ページ上の表示に関わる。アップロード後の処理には最大24時間かかる場合がある。

App Store商品ページでは、App Previewがない場合、スクリーンショットの向きに応じて先頭1〜3枚が検索結果に表示されることがあるため、先頭素材でアプリの本質が伝わる必要がある。

## 2. 初回提出の推奨

| 項目 | 推奨 | 理由 |
|---|---|---|
| App Preview | 初回はなし候補 | 動画の追加QA、poster frame、処理待ち、未完成機能露出リスクを避ける |
| スクリーンショット | 6〜8枚候補 | 主要価値を伝えつつ、重複と権利/実データ混入を減らす |
| 先頭3枚 | Home / Inventory / Proposal候補 | 検索結果でも価値が伝わる構成にする |
| ローカライズ | 初回はJapaneseのみでも可 | English (U.S.)を足す場合は説明文と素材を同時QAする |
| iPad素材 | iPad対応の有無を完成buildで確認 | iPad対応なら必要サイズのスクショを用意する |
| App icon | 完成build由来のみ | App Store Connect上だけで差し替えるものではないため |

## 3. 素材インベントリ

| Asset | 必須 | 初回方針 | QA |
|---|---|---|---|
| App icon | 必須 | 完成buildのiconを使う | 角丸、余白、ブランド、実在IP混入なし |
| iPhone screenshots | 必須 | 6〜8枚 | `notes/28` の台本と一致 |
| iPad screenshots | 条件付き | iPad対応なら用意 | iPad非対応ならApp Store Connect要件を確認 |
| App Preview | 任意 | 初回なし候補 | 出す場合は30秒以内、実機footage、poster frame QA |
| Poster frame | App Previewありなら実質必須 | App Previewなしなら不要 | 未完成機能や個人情報が写らない |
| Localized screenshots | 条件付き | Japaneseのみ候補 | English (U.S.)追加時は `notes/60` と一致 |

## 4. App icon QA

| Check | 確認 | 結果 |
|---|---|---|
| ICON-001 | 完成候補buildに含まれるApp iconである | TODO |
| ICON-002 | App Store Connect上の表示とホーム画面/TestFlight表示が一致 | TODO |
| ICON-003 | Megrumのブランドとして分かる | TODO |
| ICON-004 | 実在アーティスト、作品、キャラクター、公式ロゴ、第三者商標を含まない | TODO |
| ICON-005 | 小さなサイズでも読める/潰れない | TODO |
| ICON-006 | 背景透過や端切れなど審査・表示上の不安がない | TODO |
| ICON-007 | 公開後に変える場合は新versionが必要なことを理解している | TODO |

No-Go:
- 仮icon、debug用icon、別アプリ名のiconが入っている。
- 第三者権利物や公式提供と誤認される素材が入っている。
- App Store商品ページ、ホーム画面、TestFlightで見た目が食い違う。

## 5. スクリーンショットQA

| Check | 確認 | 結果 |
|---|---|---|
| SSQA-001 | App Store Connectで求められるデバイスサイズに必要枚数がある | TODO |
| SSQA-002 | 1〜10枚の範囲に収まっている | TODO |
| SSQA-003 | `.jpeg` / `.jpg` / `.png` のいずれか | TODO |
| SSQA-004 | 完成候補build由来で、古いUIではない | TODO |
| SSQA-005 | 先頭1〜3枚がMegrumの価値を伝えている | TODO |
| SSQA-006 | `notes/28` の撮影順/台本と一致 | TODO |
| SSQA-007 | `notes/40` の説明文と矛盾しない | TODO |
| SSQA-008 | `notes/60` の日本語/English説明と矛盾しない | TODO |
| SSQA-009 | 初回で隠す有料機能、外部AI、未完成3D、現地外の交換手段が写っていない | TODO |
| SSQA-010 | 実住所、電話番号、実メール、内部ID、debug表示、座席番号、外部連絡先がない | TODO |
| SSQA-011 | 実在アーティスト、作品、キャラクター、公式画像、第三者ロゴがない | TODO |
| SSQA-012 | 文字が小さすぎず、上下左右の切れがない | TODO |
| SSQA-013 | 通報/ブロック/削除/サポート導線をReview Notesで説明できる | TODO |

No-Go:
- スクショに実ユーザー、実取引、実問い合わせ、実通報の情報がある。
- App Privacyで回答していないデータ取扱いが見える。
- 審査員が辿れない未完成画面を見せている。
- 権利許諾がない画像や名称を使っている。

## 6. App Previewを出す場合のQA

初回は出さない候補。ただし出す場合は次を満たす。

| Check | 確認 | 結果 |
|---|---|---|
| PV-001 | 実機で撮影した完成buildのfootageである | TODO |
| PV-002 | 30秒以内 | TODO |
| PV-003 | App Store Connectで受け付ける動画形式である | TODO |
| PV-004 | 最初の数秒で価値が伝わる | TODO |
| PV-005 | poster frameが未完成機能や個人情報を含まない | TODO |
| PV-006 | App Previewがスクショより先に出る前提で順序を確認した | TODO |
| PV-007 | アップロード後の処理待ち時間を提出計画に入れた | TODO |
| PV-008 | 音声がなくても意味が伝わる | TODO |
| PV-009 | 実在IP、実データ、debug表示がない | TODO |
| PV-010 | Review Notesと説明文にない機能を動画で訴求していない | TODO |

No-Go:
- 動画だけに未完成機能が写っている。
- poster frameにsecret、内部ID、実ユーザーデータがある。
- App Previewの処理完了を待たずに提出しようとしている。

## 7. ローカライズ別QA

| Check | 確認 | 結果 |
|---|---|---|
| L10N-AS-001 | Japanese metadataにJapanese素材が紐づく | TODO |
| L10N-AS-002 | English (U.S.)を追加する場合、英語説明とスクショ内容が一致 | TODO |
| L10N-AS-003 | App Previewをローカライズしない場合、代替言語表示を理解している | TODO |
| L10N-AS-004 | Localized screenshotに未翻訳の不自然な上書きコピーがない | TODO |
| L10N-AS-005 | 各localeで隠す機能/出す機能の説明が一致 | TODO |

## 8. App Store Connect入力時チェック

| Check | 確認 | 結果 |
|---|---|---|
| ASC-AS-001 | App iconがBuild sectionの選択build由来である | TODO |
| ASC-AS-002 | Screenshots/App Previewのアップロード対象localeが正しい | TODO |
| ASC-AS-003 | Media Managerで必要なdevice sizeが欠けていない | TODO |
| ASC-AS-004 | スクショ順が `notes/28` と一致 | TODO |
| ASC-AS-005 | App Previewを出す場合、poster frameを確認 | TODO |
| ASC-AS-006 | Product Page Previewで先頭表示を確認 | TODO |
| ASC-AS-007 | Submit前にスクショ/Previewの控えを `notes/64` の証跡先へ保存 | TODO |
| ASC-AS-008 | 承認後にスクショを変えるには新versionが必要なことを確認 | TODO |

## 9. 証跡

保存する:
- App Store Connect上のスクショ一覧
- Product Page Previewの確認結果
- App iconの表示確認
- スクショ台本との対応表
- 実データ/権利物/debug表示なし確認
- App Previewを出す場合、poster frame確認

保存しない:
- 実パスワード、secret、token
- 実ユーザー/実取引/実問い合わせのスクショ
- 権利未確認画像
- App Store Connect担当者の個人情報が大きく写った管理画面

証跡保存先は `notes/64_release_evidence_folder_index.md` の `06_screenshots/` と `07_review_notes_metadata/` を使う。

## 10. 最終判定

| 項目 | 判定 | 証跡 |
|---|---|---|
| App icon | Pass / Conditional / Fail | TODO |
| iPhone screenshots | Pass / Conditional / Fail | TODO |
| iPad screenshots | Pass / Conditional / Fail / Not applicable | TODO |
| App Preview | Pass / Conditional / Fail / Not exposed | TODO |
| Poster frame | Pass / Conditional / Fail / Not applicable | TODO |
| Localized assets | Pass / Conditional / Fail | TODO |
| Product Page Preview | Pass / Conditional / Fail | TODO |

No-Goなら、Submit for Reviewへ進まない。

## 11. 関連文書

- スクリーンショット台本: `notes/28_app_store_screenshot_storyboard.md`
- App Store Connect入力ワークシート: `notes/31_app_store_connect_metadata_worksheet.md`
- App Store Connect転記用シート: `notes/40_app_store_connect_copy_paste_sheet.md`
- ローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- 初回提出スコープ露出監査: `notes/59_initial_release_scope_exposure_audit.md`
- 公開ページレダクションQA: `notes/63_public_page_redaction_qa.md`
- 提出証跡チェックリスト: `notes/36_submission_evidence_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`

## 12. 公式参照

- Apple Add an app icon: https://developer.apple.com/help/app-store-connect/manage-app-information/add-an-app-icon
- Apple Creating your product page: https://developer.apple.com/app-store/product-page/
- Apple Upload app previews and screenshots: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- Apple Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
