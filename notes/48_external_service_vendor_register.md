# 48. 外部サービス・委託先データ台帳

最終更新: 2026-05-31

ステータス: Draft v0.1（契約/公開前確認）

## 目的

Megrumの初回App Store提出前に、外部サービス、SDK、API、ホスティング、決済、通知、地図、AI候補を一覧化し、プライバシーポリシー、App Privacy、Privacy Manifest、法務レビュー、サポート運用と照合できる状態にする。

この文書は確認台帳であり、コード、DB、SDK、契約、外部サービス設定は変更しない。

## 1. 現行リポジトリから読めた事実

| 領域 | 読み取り結果 |
|---|---|
| Swift Native | `ios-native/Package.swift` 上は外部Swift Package依存なし |
| Swift Native | `Info.plist` にカメラ、位置情報、`ITSAppUsesNonExemptEncryption=false` |
| Swift Native | Supabase REST/Storage/Auth相当の独自クライアント、APNs端末登録、Google OAuth URL構築、Apple Sign-In処理が存在 |
| Swift Native | MapKit、CoreLocation、PhotosUI、カメラ利用箇所が存在 |
| Backend | Supabase migrations、Storage、Auth、Edge Function、APNs通知Functionが存在 |
| Web | Supabase、MapTiler、Leaflet、Nominatim proxy、Stripe webhook候補が存在 |
| Legacy Expo | Supabase、Expo Apple Authentication、Expo Camera、Expo Location、Expo Notifications、Expo IAP、React Native Maps、Three.js等が存在 |
| External AI | Supabase Studio設定にOpenAI API Keyコメントあり。アプリ機能としての外部AI送信は初回非表示推奨 |

## 2. 初回提出の回答方針

| 方針 | 内容 |
|---|---|
| 正とするバイナリ | Swift Native初回提出を正とする |
| Legacy Expo | 参照線。Expoで提出する場合のみ別監査 |
| Web | 管理/運用/公開ページとして別扱い。ただしプライバシーポリシーと委託先台帳には載せる |
| IAP | 初回で有料機能を隠すならApple IAP/StripeはNo-Go対象外。ただし見えるならP0 |
| 外部AI | 初回で外部AI送信を隠す又はオンデバイス限定推奨 |
| 地図/位置情報 | 現地交換・めぐりで使う場合、Locationと外部地図APIの扱いを回答 |
| 通知 | APNs token、通知本文、Edge Function、Apple endpointを回答対象に含める |

## 3. サービス別台帳

| サービス / SDK | 使う場面 | データ候補 | App Privacy影響 | 初回状態 | 要確認 |
|---|---|---|---|---|---|
| Supabase Auth | 認証、メール、OAuth | メール、ユーザーID、認証状態 | Contact Info, Identifiers | 使用候補 | DPA、リージョン、削除手順 |
| Supabase Database | プロフィール、在庫、wish、打診、取引、通報、設定 | User Content, Identifiers, Usage Data | User Content, Identifiers | 使用候補 | RLS、保持期間、削除対象 |
| Supabase Storage | グッズ写真、プロフィール画像、証跡、投稿画像 | Photos or Videos | User Content | 使用候補 | バケット公開範囲、署名URL、削除 |
| Supabase Edge Functions | APNs通知、将来API | 通知ID、user_id、APNs token参照 | Identifiers, User Contentの一部 | 使用候補 | secrets管理、ログ保持 |
| Apple Sign in | 認証 | Apple user id、メール、identity token | Contact Info, Identifiers | 使用候補 | token revoke、削除時処理 |
| Google OAuth | 認証 | Google user id、メール、プロフィール名候補 | Contact Info, Identifiers | 使用候補 | 初回Swiftで有効か、削除時連携解除 |
| Apple APNs | 端末通知 | APNs device token、通知本文 | Identifiers, User Contentの一部 | 使用候補 | token失効、通知本文の個人情報 |
| Apple StoreKit / IAP | 有料機能 | purchase state、transaction id | Purchases | 初回は隠す候補 | 見える場合はIAP設定とApp Privacy |
| Stripe | Web/将来課金、webhook | customer id、subscription id、event payload | Purchases, Identifiers | iOS初回では非表示候補 | iOS課金との棲み分け、特商法 |
| MapKit / CoreLocation | 現地交換、めぐり、地図表示 | 緯度経度、場所名、精度 | Location | 使用候補 | 正確/概略、保存有無、表示範囲 |
| MapTiler | Web地図 | 地図表示、座標、API key | Locationの可能性 | Webで使用候補 | 公開ページ/管理画面での使用範囲 |
| Nominatim / OpenStreetMap | Web geocode proxy | クエリ、緯度経度 | Locationの可能性 | Webで使用候補 | 利用ポリシー、キャッシュ、User-Agent |
| ZipCloud | 住所補完候補 | 郵便番号、住所候補 | Contact Infoの可能性 | 初回MVPでは非表示候補 | 初回で住所入力が見えないか |
| Expo Notifications | legacy通知 | Expo push token、通知本文 | Identifiers | Swift初回では対象外候補 | Expo提出時だけ回答 |
| Expo Updates / EAS | legacy配布 | update id、device/app metadata | Identifiers/Usageの可能性 | Swift初回では対象外候補 | Expo提出時だけ回答 |
| Expo Camera / Image Picker / Location / IAP | legacy権限 | 写真、位置、購入 | 複数 | Swift初回では対象外候補 | Expo提出時だけ回答 |
| Analytics / Crash SDK | 品質改善 | 操作ログ、クラッシュ | Usage Data, Diagnostics | 未導入候補 | SDK有無を最終確認 |
| External AI API | AI補助 | 画像、本文、グッズ情報、通報/問い合わせ | User Content, Other Data | 初回非表示推奨 | 送信情報、学習利用、同意 |
| OpenAI API Key in Supabase Studio | ローカル/管理補助 | 開発者入力 | 初回アプリ回答対象外候補 | アプリ機能では未確認 | アプリから送信しないこと |

## 4. 委託/第三者提供の整理

| 分類 | 対象候補 | 文書上の扱い |
|---|---|---|
| 委託先候補 | Supabase、メール/サポートツール、ホスティング、外部AI、分析/クラッシュ、Map API | プライバシーポリシーの委託先/外部サービス欄で説明 |
| プラットフォーム提供者 | Apple、Google | 認証、IAP、通知、OS権限として説明 |
| 独立した第三者候補 | Stripe、外部AI、地図/ジオコーディングAPI | 利用態様に応じて第三者提供/委託/ユーザー送信の整理を法務確認 |
| ユーザー間表示 | 取引相手へのプロフィール、取引チャット、証跡等 | アプリ機能上の表示としてプライバシーポリシーに説明 |

## 5. 契約・設定チェック

| 項目 | 状態 |
|---|---|
| SupabaseのDPA/リージョン/サブプロセッサ確認 | 未 |
| Apple Developer契約とAPNs/IAP利用確認 | 未 |
| Google OAuthの設定、プライバシーURL、削除時連携解除確認 | 未 |
| Stripeを初回iOSで見せない又はIAPへ寄せる判断 | 未 |
| MapTiler/Nominatim/ZipCloudの初回露出有無確認 | 未 |
| 外部AIサービスを初回で隠す判断 | 未 |
| Analytics/Crash SDK導入有無確認 | 未 |
| サポートメール/問い合わせ管理ツールの委託先確認 | 未 |
| 公開ページホスティングの委託先確認 | 未 |

## 6. App Privacyへの反映

| データ | 関連サービス | App Privacy候補 |
|---|---|---|
| メール、OAuth ID | Supabase Auth、Apple、Google | Contact Info, Identifiers |
| プロフィール、在庫、wish、投稿、チャット | Supabase DB/Storage | User Content |
| 画像 | Supabase Storage、Camera/Photos | Photos or Videos |
| 位置情報 | CoreLocation、MapKit、MapTiler/Nominatim | Location |
| 通知token | Supabase、APNs、Expo legacy | Identifiers |
| 購入状態 | StoreKit、Stripe候補 | Purchases |
| 操作ログ/クラッシュ | Analytics/Crash SDK候補 | Usage Data, Diagnostics |
| 外部AI入力/出力 | External AI候補 | User Content, Other Data |

## 7. Privacy Manifest / SDK監査への反映

`notes/44_privacy_manifest_sdk_audit.md` で最終ビルドを確認する。
RLS、Storage、secret、APNs、管理者権限の提出前監査は `notes/54_prelaunch_security_audit_checklist.md` で確認する。

特に見るもの:
- Swift Nativeに外部SDKが追加されていないか。
- Required Reason APIが増えていないか。
- `NSPrivacyTracking=false` の根拠が崩れていないか。
- Analytics/Crash/Advertising SDKが入っていないか。
- Expo版で提出する場合、legacy manifestを再照合する。

## 8. No-Go

- 外部AIへ画像・本文・取引情報を送るのに、説明、同意、App Privacy、プライバシーポリシーが未整備。
- Analytics/Crash SDKが入っているのにUsage Data/Diagnosticsを確認していない。
- Stripeや有料導線が見えているのにIAP/特商法/App Privacyが未整備。
- MapTiler/Nominatim等へ位置クエリを送るのにLocation回答とプライバシーポリシーが未整備。
- APNs tokenを保存するのにIdentifiers回答や削除時無効化が未確認。
- 住所補完APIや住所入力が見えているのに、初回MVPのApp Privacyで住所を選ばない方針のまま提出する。
- Supabase service role key、APNs秘密鍵、Stripe webhook secret、Map API keyを公開ページや証跡に出す。

## 9. 提出前の最小確認コマンド

```bash
rg -n "Supabase|supabase|Stripe|stripe|Firebase|Analytics|Crash|Sentry|PostHog|Mixpanel|Amplitude|OpenAI|Anthropic|MapTiler|maptiler|Nominatim|ZipCloud|StoreKit|APNs|expo-notifications" ios-native web mobile supabase --glob '!**/node_modules/**' --glob '!web/.next/**'
plutil -p ios-native/App/PrivacyInfo.xcprivacy
plutil -p ios-native/App/Info.plist
sed -n '1,120p' ios-native/Package.swift
```

## 10. 関連文書

- App Privacy回答: `notes/43_app_privacy_connect_answer_sheet.md`
- Privacy Manifest/SDK監査: `notes/44_privacy_manifest_sdk_audit.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store質問票: `notes/46_app_store_questionnaire_answer_sheet.md`
- ドメイン・メール・公開URL: `notes/47_domain_email_publication_runbook.md`
- プライバシーポリシードラフト: `notes/legal/02_privacy_policy_draft.md`
- 個人情報・セキュリティ事故初動: `notes/49_privacy_security_incident_response_runbook.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
