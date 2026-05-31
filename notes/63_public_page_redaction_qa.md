# 63. 公開ページレダクションQA

最終更新: 2026-05-31

ステータス: Draft v0.1（公開前・公開原稿QA）

## 目的

App Store審査前に公開するサポート、利用規約、プライバシーポリシー、特商法、FAQ、削除、通報、安全、AI説明ページから、内部情報、未確定機能、審査上まずい表現、秘密情報、実データが漏れないように確認する。

この文書は公開前QA表であり、コード、公開URL、App Store Connect設定、DNS、メール設定は変更しない。

## 1. 対象ページ

| URL候補 | 役割 | 原稿 | 公開前QA |
|---|---|---|---|
| `/support` | Support URL | `notes/25` | 必須 |
| `/legal/terms` | 利用規約 | `notes/legal/01_terms_of_service_draft.md` | 必須 |
| `/legal/privacy` | プライバシーポリシー | `notes/legal/02_privacy_policy_draft.md` | 必須 |
| `/legal/commerce` | 特商法表示 | `notes/25`, `notes/17` | 有料機能を出す場合は必須 |
| `/support/account-deletion` | アカウント削除ヘルプ | `notes/25` | 必須 |
| `/support/privacy-request` | 個人情報請求 | `notes/25` | 必須 |
| `/support/report` | 通報・ブロック・安全 | `notes/25` | UGCを出す場合は必須 |
| `/support/ai` | AI機能説明 | `notes/25` | AI機能を出す場合は必須 |
| `/support/faq` | よくある質問 | `notes/55` | 必須 |

公開前に、`notes/37_public_url_publication_checklist.md` のURL疎通確認と合わせて使う。

## 2. レダクション基本方針

公開してよいもの:
- 公開用メールアドレス
- 公開URL
- アプリ名、機能説明、問い合わせ手順
- 法務レビュー済み又はレビュー依頼対象として明示した文面
- App Store Connectへ入力する予定の公開文面
- 一般ユーザーに案内してよい操作手順

公開しないもの:
- 実パスワード、認証コード、2FA復旧コード
- API key、secret、private key、token、署名用証明書情報
- Supabase project ref、database URL、Storage bucketの内部名、RLS詳細の内部運用メモ
- App Store Connect、Apple Developer、DNS、メール管理、決済、外部サービスの管理画面URL
- 個人用メールアドレス、個人電話番号、個人住所
- 未公開の代表者情報、所在地、電話番号の実値
- デモアカウントの実パスワード
- 実ユーザー、実取引、実問い合わせ、実通報、実事故の情報
- 内部ID、debug表示、ログ、stack trace、IP address、端末固有ID
- 未確定価格、未確定商品ID、未確定キャンペーン
- 審査提出時に隠す機能の断定説明

## 3. 全ページ共通QA

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| CM-001 | ページに最終更新日がある | TODO | TODO |
| CM-002 | `support@megrum.jp` 又は採用済み問い合わせ先がある | TODO | TODO |
| CM-003 | 実パスワード、認証コード、secret実値がない | TODO | TODO |
| CM-004 | 個人住所、個人電話番号、個人メールアドレスがない | TODO | TODO |
| CM-005 | 実ユーザー名、実取引、実問い合わせ、実通報がない | TODO | TODO |
| CM-006 | 内部ID、debug表示、stack trace、IP addressがない | TODO | TODO |
| CM-007 | 未確定価格、未確定商品ID、未確定キャンペーンがない | TODO | TODO |
| CM-008 | 初回で隠す有料機能、外部AI、未完成3D、現地外の交換手段を断定的に説明していない | TODO | TODO |
| CM-009 | アプリ内導線と異なる操作手順を書いていない | TODO | TODO |
| CM-010 | App Store説明文、Review Notes、App Privacyと矛盾しない | TODO | TODO |
| CM-011 | 過剰保証、確実な安全、真贋保証、当日の合流保証に読める表現がない | TODO | TODO |
| CM-012 | 実在IPの公式提供、提携、承認済みと誤認される表現がない | TODO | TODO |

No-Go:
- secret又はパスワードに見える文字列が公開原稿に残っている。
- 審査提出時に隠す機能を、利用可能な機能として公開ページで説明している。
- App Privacy回答と公開プライバシーポリシーが矛盾している。
- サポート窓口が個人情報を過剰に求めている。

## 4. Support URL QA

対象:
- `/support`
- `/support/faq`
- `/support/account-deletion`
- `/support/privacy-request`
- `/support/report`

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| SP-001 | Supportトップから規約、Privacy、削除、通報、FAQへ辿れる | TODO | TODO |
| SP-002 | 問い合わせ前に送ってほしい情報が最小限 | TODO | TODO |
| SP-003 | パスワード、認証コード、クレジットカード番号を送らない注意がある | TODO | TODO |
| SP-004 | 安全上の緊急時は会場スタッフ、施設管理者、警察等へ相談する案内がある | TODO | TODO |
| SP-005 | 通報後の対応結果を必ず開示すると書いていない | TODO | TODO |
| SP-006 | アカウント削除はアプリ内開始を基本として説明している | TODO | TODO |
| SP-007 | 有料サブスクリプションはApp Store側での解約が必要と説明している | TODO | TODO |
| SP-008 | 初回で出さない有料機能、外部AI、未完成3DをFAQで前面訴求していない | TODO | TODO |

No-Go:
- Support URLが問い合わせ先だけで、削除/通報/Privacyに辿れない。
- 退会はメールのみと読める。
- 通報者情報が相手に伝わるように読める。

## 5. 利用規約QA

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| TM-001 | Megrumの役割がユーザー間交換を補助する場として整理されている | TODO | TODO |
| TM-002 | 交換成立、相手の行動、グッズの真贋、状態、当日の合流を保証しない | TODO | TODO |
| TM-003 | 禁止事項に不正グッズ、権利侵害、危険行為、個人情報の不適切な公開が含まれる | TODO | TODO |
| TM-004 | 通報、ブロック、アカウント制限、コンテンツ制限の説明がある | TODO | TODO |
| TM-005 | 有料機能を出す場合、決済、解約、返金、復元がApp Store運用と矛盾しない | TODO | TODO |
| TM-006 | AI機能を出す場合、AI結果の非保証とユーザー確認が説明されている | TODO | TODO |
| TM-007 | 代表者情報非公表方針が弁護士原典と矛盾しない | TODO | TODO |
| TM-008 | 初回で存在しない機能を義務や権利として断定していない | TODO | TODO |

No-Go:
- Megrum運営者がユーザー間取引の当事者に見える。
- 未実装の削除、通報、課金、AI機能を実装済みのように書いている。
- 代表者情報の扱いが `notes/17_legal_alignment.md` とズレている。

## 6. プライバシーポリシーQA

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| PP-001 | 取得情報が実ビルド、App Privacy、外部サービス台帳と一致 | TODO | `notes/27`, `notes/43`, `notes/48` |
| PP-002 | 位置情報、写真、通知token、購入状態、問い合わせ、通報の扱いが説明されている | TODO | TODO |
| PP-003 | 外部AIを出す場合、送信情報、目的、保存、学習利用の有無が説明されている | TODO | TODO |
| PP-004 | 外部AIを隠す場合、公開ページで利用可能機能として読めない | TODO | TODO |
| PP-005 | 個人情報請求窓口と手続がある | TODO | TODO |
| PP-006 | アカウント削除時に残る可能性がある情報がデータ保持表と一致 | TODO | `notes/52` |
| PP-007 | 第三者提供/委託先の説明が外部サービス台帳と矛盾しない | TODO | `notes/48` |
| PP-008 | トラッキング有無がPrivacy Manifest/SDK監査と一致 | TODO | `notes/44` |

No-Go:
- App Store ConnectのApp Privacy回答で選ぶデータがPrivacyにない。
- 実装で使う外部サービスがPrivacyに反映されていない。
- 外部AIへの送信や学習利用について、アプリ内表示と公開説明が矛盾している。

## 7. 特商法表示QA

有料機能を初回提出で隠す場合、このページは公開準備だけでもよい。ただしアプリ、スクショ、説明文、FAQ、Review Notesに有料機能が見えていないことを `notes/59_initial_release_scope_exposure_audit.md` で確認する。

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| LC-001 | 有料機能を出す/隠す判断が明確 | TODO | TODO |
| LC-002 | 出す場合、商品名、価格、期間、提供時期がApp Store設定と一致 | TODO | TODO |
| LC-003 | 代表者、所在地、電話番号を非公表にする場合、請求対応フローがある | TODO | TODO |
| LC-004 | メールアドレスが公開サポート窓口と一致 | TODO | TODO |
| LC-005 | 返金・解約説明がApp Storeの購入/サブスクリプション運用と一致 | TODO | TODO |
| LC-006 | 未確定価格や予定価格を本番公開ページへ残さない | TODO | TODO |

No-Go:
- App Store Connect価格と公開価格が違う。
- 請求時開示の運用がない。
- 有料機能を隠すのに特商法ページだけが有料機能を強く訴求している。

## 8. 公開前検索パターン

公開前に原稿又は生成HTMLへ検索する。

```bash
rg -n "password|passwd|secret|token|private key|api[_-]?key|SUPABASE|service_role|anon key|debug|stack trace|localhost|127\\.0\\.0\\.1|TODO|TBD|未確定|予定価格|example@example|test@example" public-pages/
```

リポジトリ原稿で確認する場合:

```bash
rg -n "password|passwd|secret|token|private key|api[_-]?key|SUPABASE|service_role|anon key|debug|stack trace|localhost|127\\.0\\.0\\.1|TODO|TBD|未確定|予定価格|example@example|test@example" notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md notes/legal
```

注意:
- 原稿段階のTODOは許容される場合がある。
- 公開HTML、App Store Connect転記文、スクショ説明にTODOが残るのはNo-Go。
- 公開しない管理情報は `notes/61_release_access_owner_registry.md` で担当や保管場所だけを管理し、実値を書かない。

## 9. 公開ページQA記録

| 項目 | 値 |
|---|---|
| QA日 | TODO |
| QA担当 | TODO |
| 公開前原稿commit | TODO |
| 公開URL確認日時 | TODO |
| App Version / Build | TODO |
| Support URL | Pass / Conditional / Fail |
| Terms URL | Pass / Conditional / Fail |
| Privacy URL | Pass / Conditional / Fail |
| Commerce URL | Pass / Conditional / Fail / Not exposed |
| Account Deletion URL | Pass / Conditional / Fail |
| Privacy Request URL | Pass / Conditional / Fail |
| Report URL | Pass / Conditional / Fail |
| AI URL | Pass / Conditional / Fail / Not exposed |
| FAQ URL | Pass / Conditional / Fail |
| 修正が必要なページ | TODO |
| 公開停止が必要な理由 | TODO |

## 10. 関連文書

- 公開法務・サポートページ文面: `notes/25_public_legal_support_pages.md`
- 公開URL公開チェックリスト: `notes/37_public_url_publication_checklist.md`
- 公開ヘルプFAQ下書き: `notes/55_public_help_faq_draft.md`
- App Storeローカライズ・メタデータQA: `notes/60_app_store_localization_metadata_qa.md`
- 初回提出スコープ露出監査: `notes/59_initial_release_scope_exposure_audit.md`
- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- 外部サービス台帳: `notes/48_external_service_vendor_register.md`
- データ保持・削除: `notes/52_data_retention_deletion_matrix.md`
- リリース権限・運用アカウント: `notes/61_release_access_owner_registry.md`
