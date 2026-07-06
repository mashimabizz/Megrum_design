# 63. 公開ページレダクションQA

最終更新: 2026-06-29

ステータス: Draft v1.1（近距離公開・作成位置情報 / 会員間支払い・金融規制境界 / 成立後支払い情報スナップショット / 現行Web短縮Terms/Privacy・アプリ内法務要約の同期No-Go / UGC・App Review 1.2 / App Store評価・公開レビュー返信 / 漏えい等初動・事故疑い / 広告宣伝メール・販促通知 / 公式連絡・フィッシング / StoreKit・IAP販売可否・復元失敗 / 公開Web外部アセット・next/font/google・MapTiler/Nominatim未検出整理 / ローカルenv・Vercel env・Supabase secrets・server-only key境界 / Keychain・session保存・最新法務ドラフト / 公開前・公開原稿QA）

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
| `/support/ai` | AI機能説明 | `notes/25` | AI機能又は顔候補付けを出す場合は必須 |
| `/support/faq` | よくある質問 | `notes/55` | 必須 |

公開前に、`notes/37_public_url_publication_checklist.md` のURL疎通確認と合わせて使う。

## 1.1 現行実装との差分QA（2026-06-29）

2026-06-29時点のコード読み取りでは、公開原稿の想定URLと現行Web実装/アプリ内リンクに差分がある。公開HTMLを生成又は実装へ反映する前に、次を必ず潰す。

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| IMPL-001 | App Store Connectへ入力するPrivacy Policy URLが、実際に公開されるPrivacy本文と同一 | TODO | 現行Web実装は `web/src/app/privacy/page.tsx` の `/privacy`、公開原稿は `/legal/privacy` |
| IMPL-002 | 利用規約URLが、登録同意画面、Settings、Support、App Store文面で同一 | TODO | 現行登録同意リンクは `ios-native/Sources/MegrumApp/AuthLegalConsentNotice.swift` から `/terms` |
| IMPL-003 | Web公開Terms/Privacyの最終更新日が、法務ドラフト最新版と一致 | TODO | `web/src/app/terms/page.tsx` / `web/src/app/privacy/page.tsx` は `2026年6月26日` |
| IMPL-004 | Web公開Terms/Privacyが短縮版ではなく、提出スコープのリスクを含む | TODO | `web/src/app/terms/page.tsx` / `web/src/app/privacy/page.tsx` は短縮ページ。Keychain/session保存、access token、refresh token、認証callback、通知linkPath、精密位置、作成位置、閲覧者位置、待ち合わせ候補、1km/3km非保証、写真メタデータ、共有シート、郵送交換、会員間支払い、銀行口座/口座名義、成立後支払い情報スナップショット、金融/決済サービス非関与、外部ID/送金リンク/QR非保証、外部AI/web_search、広告、顔候補付け、評価/通報/削除申出、UGC・App Review 1.2、App Store評価・公開レビュー返信、漏えい等初動・事故疑い、広告宣伝メール・販促通知、公式連絡・フィッシング、サポートSLA・専門助言非保証、現在地共有/服装写真の30日保持目標と非保証等 |
| IMPL-005 | Supportトップから、実際に存在する削除、個人情報請求、通報、AI、FAQページへ辿れる | TODO | 個別URL未実装なら、Supportトップ内の該当セクションへアンカー又は代替導線を用意 |
| IMPL-006 | アプリ内法務表示が要約である場合、正式本文への公開リンクが最新本文へ到達する | TODO | `ios-native/Sources/MegrumApp/LegalDocumentContent.swift` / `SettingsLegalViews.swift` は正式本文ではない旨を表示 |
| IMPL-007 | `PrivacyInfo.xcprivacy`、App Store Connect App Privacy、公開Privacy、SDK/通信監査の役割差が整理されている | TODO | Privacy Manifestに収集データ型が無いことだけでApp Privacy回答不要とは判断しない |
| IMPL-008 | 登録同意画面とSupport関連リンクが、同じ正式Terms/Privacy本文又は明示リダイレクトへ到達する | TODO | `ios-native/Sources/MegrumApp/AuthLegalConsentNotice.swift` と現行Supportは `/terms` / `/privacy` 系を指す。公開正URLを `/legal/*` にする場合はリンク更新又は公開リダイレクトが必要 |
| IMPL-009 | 2026-06-29版の最新法務論点が公開Terms/Privacy又は同一本文へのリダイレクトに反映済み | TODO | 少なくともUGC・App Review 1.2、公開レビュー返信、事故初動、販促通知、公式連絡・フィッシング、削除申出、SLA非保証、責任上限を確認 |
| IMPL-010 | Support/FAQ/問い合わせ導線が公式連絡・フィッシングと販促停止の注意を含む | TODO | Megrum公式が秘密情報を求めないこと、広告宣伝メール・販促通知の同意/停止が必要連絡と別であること |

No-Go:
- 2026-06-29版の法務ドラフトと異なる2026-06-26短縮ページを、App Store提出時のPrivacy Policy URL又はTerms本文として扱う。
- 公開原稿では `/legal/privacy` / `/legal/terms` を正としているのに、アプリ内同意やサポートページが `/privacy` / `/terms` の旧ページへ誘導する。
- Keychain/session保存、access token、refresh token、認証callback、通知linkPath、写真メタデータ、精密位置、作成位置、閲覧者位置、1km/3km非保証、外部AI/web_search、AdMob/ATT等の最新追加論点がない短縮Privacyを、提出用Privacy Policy URLとして扱う。
- UGC・App Review 1.2、App Store評価・公開レビュー返信、漏えい等初動・事故疑い、広告宣伝メール・販促通知、公式連絡・フィッシング、削除申出・送信防止措置、サポートSLA・専門助言非保証、責任上限・存続条項がない短縮Terms/Privacyを正式本文として扱う。
- 現在地共有又は服装写真について、30日後の自動削除、完全削除、即時反映を未確認のまま公開Privacy又はFAQで保証している。
- 近く、1km圏内、3km圏内、同じスポット又は同じ都道府県を、匿名化、安全確認、本人確認、所在確認又は推測防止として公開ページやApp Store説明に書いている。
- 未実装の個別サポートURLを公開済みのように書く。
- アプリ内要約表示だけで、正式な利用規約又はプライバシーポリシーの公開要件を満たしたと扱う。
- Support、FAQ、サポート返信、Review Notes又は公開レビュー返信で、Megrum公式がパスワード、認証コード、認証リンク、金融機関ログイン情報、暗証番号、クレジットカード番号、送金用QRコード、送金リンク、外部決済サービスIDを求めるように読める。

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
- `.env.local`、`.vercel/.env.production.local`、`web/.env.local`、Supabase/Vercel/Apple/Stripe/Google/OpenAI等のsecret実値又はsecret表示画面
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
| CM-008 | 初回で隠す有料機能、外部AI、顔候補付け、未完成3D、現地外の交換手段を断定的に説明していない | TODO | TODO |
| CM-009 | アプリ内導線と異なる操作手順を書いていない | TODO | TODO |
| CM-010 | App Store説明文、Review Notes、App Privacyと矛盾しない | TODO | TODO |
| CM-011 | 過剰保証、確実な安全、真贋保証、当日の合流保証に読める表現がない | TODO | TODO |
| CM-012 | 実在IPの公式提供、提携、承認済みと誤認される表現がない | TODO | TODO |
| CM-013 | 公開URL、アプリ内リンク、App Store Connect入力値が同じ本文へ到達する | TODO | `notes/37` |
| CM-014 | Web公開ページの最終更新日と内容が、提出に使う法務ドラフトと一致する | TODO | 旧短縮ページを本番提出に使わない。2026-06-29版の最新法務論点を含む |
| CM-015 | 公開ページ、生成HTML、App Store転記文、サポート返信テンプレに `.env.local`、secret実値、Supabase/Vercel/Apple/Stripe/Google/OpenAIの管理画面情報がない | TODO | キー名を説明する場合も実値、project ref、private key、token断片は出さない |
| CM-016 | 公開WebのHTML/Networkに未説明の外部アセットがない | TODO | `next/font/google` はself-host前提。`fonts.googleapis.com` / `fonts.gstatic.com`、MapTiler、Nominatimが出る場合はPrivacy/台帳/証跡を更新 |

No-Go:
- secret又はパスワードに見える文字列が公開原稿に残っている。
- 審査提出時に隠す機能を、利用可能な機能として公開ページで説明している。
- App Privacy回答と公開プライバシーポリシーが矛盾している。
- サポート窓口が個人情報を過剰に求めている。
- `.env.local`、`.vercel`、Supabase secrets、Vercel env、APNs private key、OAuth client secret、Stripe webhook secret、OpenAI API key、service role key等の実値又はスクショが公開ページや転記文に残っている。
- 公開ページが未説明の外部フォント、外部地図、外部ジオコーディング、外部解析又は広告タグを読み込んでいる。

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
| SP-009 | 顔候補付けを出す場合、本人確認/Face IDではないこと、第三者画像禁止、Sensitive Info候補が説明されている | TODO | TODO |
| SP-010 | 個別サポートURLを公開済みと書く場合、該当ページ又は同等のアンカーが存在する | TODO | `/support/account-deletion` 等 |
| SP-011 | 公式連絡・フィッシング注意と販促通知停止の説明がある | TODO | 公式が秘密情報を求めないこと、販促停止後も必要連絡が残り得ること |

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
| TM-009 | 顔候補付けを出す場合、本人確認/Face IDではないこと、第三者画像禁止、不正な顔特徴量利用禁止が説明されている | TODO | TODO |
| TM-007 | 代表者情報非公表方針が弁護士原典と矛盾しない | TODO | TODO |
| TM-008 | 初回で存在しない機能を義務や権利として断定していない | TODO | TODO |
| TM-010 | Web公開Termsが2026-06-29版ドラフトの主要リスクを含む | TODO | 郵送交換、支払い情報、成立後支払い情報スナップショット、金融/決済サービス非関与、通知、広告、AI、顔候補付け、評価/通報/削除申出 |
| TM-011 | Web公開Termsが最新の横断法務論点を含む | TODO | UGC・App Review 1.2、公開レビュー返信、事故初動、販促通知、公式連絡・フィッシング、SLA非保証、責任上限 |
| TM-012 | 会員間支払いの金融規制境界がある | TODO | 支払い方法、銀行口座、口座名義、成立後スナップショット、目的外利用禁止、送金/収納代行/回収/返金/チャージバック/エスクロー/本人確認/口座名義確認/支払能力確認/外部ID・送金リンク・QR確認の非関与 |

No-Go:
- Megrum運営者がユーザー間取引の当事者に見える。
- 未実装の削除、通報、課金、AI機能を実装済みのように書いている。
- 代表者情報の扱いが `notes/17_legal_alignment.md` とズレている。

## 6. プライバシーポリシーQA

| Check | 確認 | 結果 | メモ |
|---|---|---|---|
| PP-001 | 取得情報が実ビルド、App Privacy、外部サービス台帳と一致 | TODO | `notes/27`, `notes/43`, `notes/48` |
| PP-002 | 位置情報、写真、通知token、購入状態、問い合わせ、通報の扱いが説明されている | TODO | 位置情報は、現在地共有、待ち合わせ候補、グルーム/掲示板の作成座標、閲覧者座標、半径、距離、公開範囲、1km/3km非保証、保持/削除例外まで確認 |
| PP-003 | 外部AIを出す場合、送信情報、目的、保存、学習利用の有無が説明されている | TODO | TODO |
| PP-004 | 外部AIを隠す場合、公開ページで利用可能機能として読めない | TODO | TODO |
| PP-005 | 個人情報請求窓口と手続がある | TODO | TODO |
| PP-006 | アカウント削除時に残る可能性がある情報がデータ保持表と一致 | TODO | `notes/52` |
| PP-007 | 第三者提供/委託先の説明が外部サービス台帳と矛盾しない | TODO | `notes/48` |
| PP-008 | トラッキング有無がPrivacy Manifest/SDK監査と一致 | TODO | `notes/44` |
| PP-009 | 顔候補付けを出す場合、顔特徴量/画像特徴量、外部送信、保持/削除、Sensitive Info候補が説明されている | TODO | `notes/27`, `notes/43`, `notes/52` |
| PP-010 | Web公開Privacyが2026-06-29版ドラフトの取得情報・利用目的・提供範囲を含む | TODO | Keychain/session保存、access token、refresh token、認証callback、通知linkPath、AdMob、精密位置、作成位置、閲覧者位置、1km/3km非保証、写真メタデータ、外部AI/web_search、公開ページ、App Privacy、外部サービス台帳、現在地共有/服装写真の30日保持目標と非保証を照合 |
| PP-011 | Web公開Privacyが最新の横断取得・利用目的を含む | TODO | 公開レビュー返信、事故疑い、販促同意/停止履歴、不審連絡/フィッシング報告、通報/削除申出の記録 |
| PP-012 | 会員間支払い情報の取得・表示・保持が説明されている | TODO | 支払い方法、銀行口座番号、口座名義、金額、成立後支払い情報スナップショット、相手方表示、設定変更/削除後の例外保持、外部決済サービス非関与 |

No-Go:
- App Store ConnectのApp Privacy回答で選ぶデータがPrivacyにない。
- 実装で使う外部サービスがPrivacyに反映されていない。
- Keychain内AuthSession、access token、refresh token、session更新、logout request、端末復元/バックアップ/他端末sessionの説明が公開Privacyにない。
- 現在地共有又は服装写真について、実装未確認の30日自動削除を公開Privacyで保証している。
- 近距離投稿、待ち合わせ候補、グルーム、掲示板が見えるのに、作成位置、閲覧者位置、距離判定、保持例外、生活圏推測リスクをPrivacyで説明していない。
- 外部AIへの送信や学習利用について、アプリ内表示と公開説明が矛盾している。
- 顔候補付けが本人確認、年齢確認、Face ID認証、出入場管理、真贋鑑定、信用判断に見える。

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
| LC-007 | アプリ内要約表示とログイン不要の正式公開特商法ページを混同していない | TODO | `SettingsLegalViews.swift` の要約は正式本文ではない |
| LC-008 | 有料導線が見える場合、購入ボタン、復元ボタン、固定価格、StoreKit価格、特商法、FAQ、Review Notesが一致 | TODO | 現行フッター固定文言は「月額500円」 |
| LC-009 | 購入開始、承認待ち、未完了、キャンセル、復元失敗、サーバー同期失敗の記録がPrivacy/App Privacyと一致 | TODO | `notes/legal/02` 第2.9条・第10条 |

No-Go:
- App Store Connect価格と公開価格が違う。
- 請求時開示の運用がない。
- 有料機能を隠すのに特商法ページだけが有料機能を強く訴求している。
- アプリ内の要約表示又は設定内入口だけで、正式な公開特商法ページが公開済みだと扱う。
- メグルムプラスの購入ボタン、復元ボタン、価格、特典説明又は状態表示が見えるのに、App Store Connect商品、IAP Availability、特商法、Privacy/App Privacy、サーバー検証、返金/取消/期限切れ同期が未確認。

## 8. 公開前検索パターン

公開前に原稿又は生成HTMLへ検索する。

```bash
rg -n "password|passwd|secret|token|private key|api[_-]?key|SUPABASE|service_role|anon key|env\\.local|\\.vercel|debug|stack trace|localhost|127\\.0\\.0\\.1|TODO|TBD|未確定|予定価格|example@example|test@example" public-pages/
```

リポジトリ原稿で確認する場合:

```bash
rg -n "password|passwd|secret|token|private key|api[_-]?key|SUPABASE|service_role|anon key|env\\.local|\\.vercel|debug|stack trace|localhost|127\\.0\\.0\\.1|TODO|TBD|未確定|予定価格|example@example|test@example" notes/25_public_legal_support_pages.md notes/55_public_help_faq_draft.md notes/legal
```

注意:
- 原稿段階のTODOは許容される場合がある。
- 公開HTML、App Store Connect転記文、スクショ説明にTODOが残るのはNo-Go。
- 公開しない管理情報は `notes/61_release_access_owner_registry.md` で担当や保管場所だけを管理し、実値を書かない。
- 実値入り `.env.local`、`.vercel/.env.production.local`、`web/.env.local` は検索対象や証跡対象に含めない。必要な場合もキー名だけ別メモ化する。

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
