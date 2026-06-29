# 75. Apple Developer署名・Capabilities事前確認Runbook

最終更新: 2026-05-31

ステータス: Draft v0.1（完成ビルド到着前・Apple Developer確認前）

## 目的

App Store初回提出前に、Apple Developer側のBundle ID、App ID、Capabilities、entitlements、APNs、Sign in with Apple、provisioning profile、certificate、App Store Connectのapp recordを照合し、Build upload失敗、Invalid Binary、通知不達、ログイン不具合、審査時の説明不一致を防ぐ。

この文書はApple Developer / App Store Connect / Xcode署名設定の確認Runbookであり、コード、Xcode project、Apple Developer設定、App Store Connect設定、secret、証跡ファイル自体は変更しない。

## 1. 公式前提の要点

Apple公式ヘルプでは、App IDはアプリを識別し、explicit App IDは単一アプリ用のBundle IDに紐づく。App IDで有効化したCapabilitiesは、そのApp IDで使える機能のallow listになる。

CapabilitiesはXcode target側にも追加が必要で、Apple Developer側だけを有効化しても、targetのentitlementsやInfo.plistと一致しなければ提出ビルドの動作や署名が崩れる。

Apple Developer側でApp IDのCapabilitiesを変更すると、そのApp IDを含むprovisioning profileが無効になる場合があり、該当profileの再生成又はXcode automatic signingによる更新確認が必要になる。

App Storeへuploadするには、App Store Connect側のapp record、完成候補buildのBundle ID、Apple Developer側のexplicit App ID、署名に使うprofile/certificateが一致している必要がある。

## 2. 使うタイミング

使う:
- 完成候補ビルドをApp Store Connectへuploadする前。
- `Invalid Binary`、署名エラー、capability不足、APNs不達、Sign in with Apple不具合が出た時。
- Push Notifications、Sign in with Apple、Associated Domains、IAPなどのCapabilitiesを追加又は削除した時。
- Release CandidateハンドオフでBundle ID、Version、Build、entitlementsを受け取った時。

使わない:
- App Store Connectの説明文、スクショ、Review Notesだけの差分確認。これは `notes/71` を使う。
- Privacy Manifest / Required Reason API / SDK監査。これは `notes/44` を使う。
- RLS、Storage、secret、APNs payload、管理者権限のセキュリティ監査。これは `notes/54` を使う。

## 3. 確認する識別子

| 項目 | 確認先 | 一致させるもの |
|---|---|---|
| Bundle ID | Xcode / completed build / App Store Connect / Apple Developer | 4箇所で完全一致 |
| App ID | Apple Developer Identifiers | explicit App IDであること |
| Team ID | Apple Developer / signing certificate / APNs | Account Holder又は提出teamと一致 |
| Version / Build | Release Candidate / App Store Connect | 提出対象buildと一致 |
| SKU | App Store Connect | app record作成後は変更不可として記録 |
| Primary Language / Category | App Store Connect | `notes/31` / `notes/71` と一致 |

No-Go:
- Bundle IDがApp Store Connectのapp recordと違う。
- Preview用、development用、legacy Expo用のBundle IDを提出候補として扱っている。
- App IDがwildcardで、必要なCapabilitiesを正しく有効化できない。
- Team ID又はApple Developer teamが提出予定のteamと違う。

## 4. 初回Megrumで確認するCapabilities

| Capability / Service | 初回候補 | 確認 |
|---|---|---|
| Sign in with Apple | 出すなら必要 | Apple DeveloperのApp ID、Xcode target、Supabase Auth、削除時revoke方針が一致 |
| Push Notifications | 通知を出すなら必要 | App ID、Xcode target entitlement、APNs key、production/development環境が一致 |
| In-App Purchase | 有料機能を出すなら必要 | explicit App ID、Paid Apps契約、IAP商品、価格、復元、Availability、Server API/Notifications、アプリ内固定文言が一致 |
| Associated Domains | Universal Links等を出す場合のみ | domain、AASA、entitlement、公開URLが一致 |
| Maps / Location | capabilityではなく権限・App Privacy側で確認 | Info.plist、アプリ内説明、App Privacyが一致 |
| Camera / Photos | capabilityではなく権限・App Privacy側で確認 | Info.plist、写真/カメラ導線、App Privacyが一致 |
| Apple Pay / iCloud / App Groups | 初回なし候補 | 使わないなら有効化しない |
| HealthKit / HomeKit / Wallet等 | 初回なし | 使わないなら有効化しない |

No-Go:
- 使っていないCapabilitiesを「念のため」有効化する。
- Sign in with Appleが画面に見えるのにCapability又はSupabase設定が未確認。
- 通知許可画面や通知設定が見えるのにPush Notifications / APNs credentialが未確認。
- 有料機能が見えるのにIAP商品、契約、復元、Availability、価格固定文言、返金/取消/期限切れ/請求失敗同期が未確認。

## 5. Provisioning / certificate確認

| Check | 確認 | 結果 |
|---|---|---|
| SIGN-001 | Xcode automatic signingを使うか、manual signingを使うか決めた | TODO |
| SIGN-002 | App Store distribution用profileが対象Bundle ID / App IDと一致 | TODO |
| SIGN-003 | profileに必要Capabilitiesが含まれている | TODO |
| SIGN-004 | Capability変更後にprofile再生成又はXcode更新を確認した | TODO |
| SIGN-005 | distribution certificateが有効 | TODO |
| SIGN-006 | 証明書のprivate keyが必要なMac/CIにある | TODO |
| SIGN-007 | Debug / Release / Archiveで意図したteamとBundle IDになっている | TODO |
| SIGN-008 | Release/TestFlightはproduction APNs環境を使う | TODO |
| SIGN-009 | profile/certificateの実ファイルやprivate keyをリポジトリへ入れていない | TODO |

No-Go:
- Capability変更後、古いprofileのままArchiveする。
- development profile又はdevelopment APNs環境のままTestFlight / App Store提出する。
- certificate private key、`.p12`、`.mobileprovision`、APNs private keyを公開リポジトリへ置く。
- 誰のApple Developer accountで署名したか追えない。

## 6. APNs / Push通知確認

| Check | 確認 | 結果 |
|---|---|---|
| APNS-001 | App IDでPush Notificationsが有効 | TODO |
| APNS-002 | Xcode targetにPush Notifications entitlementがある | TODO |
| APNS-003 | APNs Key ID / Team ID / Bundle IDが一致 | TODO |
| APNS-004 | APNs private keyはsecret manager又はSupabase secretsだけに保存 | TODO |
| APNS-005 | production buildでproduction APNs endpointへ送る | TODO |
| APNS-006 | 通知payloadに正確な場所、個人情報、内部IDを含めない | TODO |
| APNS-007 | token失効時の無効化又は再登録を説明できる。ログアウト時revokeと退会申請/削除完了時のtoken無効化の差分を説明できる | TODO |

詳細なpayload、secret、Edge Function、ログ監査は `notes/54_prelaunch_security_audit_checklist.md` を使う。

## 7. Sign in with Apple確認

| Check | 確認 | 結果 |
|---|---|---|
| SIWA-001 | App IDでSign in with Appleが有効 | TODO |
| SIWA-002 | primary App ID又はgrouping方針が決まっている | TODO |
| SIWA-003 | Xcode targetにSign in with Apple capabilityがある | TODO |
| SIWA-004 | Supabase Authのredirect / client設定とBundle IDが一致 | TODO |
| SIWA-005 | アカウント削除時のtoken revoke要否を `notes/45` で確認 | TODO |
| SIWA-006 | server-to-server notification endpointを使うか判断 | TODO |
| SIWA-007 | Review NotesでApple login経路を説明できる | TODO |

No-Go:
- Sign in with Appleを提供するのにアカウント削除とtoken revokeの扱いが説明できない。
- Preview用Bundle IDのApple login設定を、本番提出Bundle IDの設定と混同する。
- server-to-server notification endpointが未構築なのに、構築済みのように説明する。

## 8. Associated Domains / Universal Links確認

初回提出でUniversal Linksを使わないなら、この節は「Not applicable」と記録する。

| Check | 確認 | 結果 |
|---|---|---|
| AD-001 | Associated Domains capabilityの要否を決めた | TODO |
| AD-002 | `applinks:` domainが本番domainだけを指す | TODO |
| AD-003 | AASAファイルがHTTPSで公開され、認証不要 | TODO |
| AD-004 | Preview / dev domainが本番提出に混ざっていない | TODO |
| AD-005 | 公開URLチェック `notes/37` と一致 | TODO |

## 9. App Store Connect / Xcode / Apple Developer照合表

| Check | 確認 | 証跡 |
|---|---|---|
| DEV-001 | App Store Connectのapp recordとBundle IDが一致 | TODO |
| DEV-002 | Apple Developer IdentifiersのApp IDがexplicit | TODO |
| DEV-003 | App IDのCapabilitiesが完成buildで見える機能だけ | TODO |
| DEV-004 | Xcode targetのSigning & CapabilitiesとApp IDが一致 | TODO |
| DEV-005 | Archiveしたbuildのentitlementsを確認した | TODO |
| DEV-006 | App Store Connectで選択したbuildがRelease Candidateハンドオフと一致 | TODO |
| DEV-007 | Capability変更後の再Archive / 再upload要否を判断した | TODO |
| DEV-008 | 証跡を `notes/64` の `15_signing_capabilities/` に保存 | TODO |

## 10. 記録フォーマット

```text
Signing preflight:
Checked at:
Checked by:
Apple Developer team:
Bundle ID:
App ID:
App Store Connect app record:
Xcode project / scheme:
Version:
Build:
Signing mode: Automatic / Manual
Distribution profile:
Capabilities enabled:
Capabilities visible in app:
APNs status:
Sign in with Apple status:
IAP status:
Associated Domains status:
No-Go remaining:
Evidence folder:
```

実値を記録してよいものと避けるもの:
- Bundle ID、Team ID、Profile名、Key IDは必要最小限で記録してよい。
- private key、certificate private key、`.p12` password、Apple ID password、2FA code、recovery code、実電話番号は記録しない。

## 11. 関連文書

- リリース権限・運用アカウント: `notes/61_release_access_owner_registry.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- TestFlight / Submit手順: `notes/32_testflight_review_submission_runbook.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
- Privacy Manifest / SDK監査: `notes/44_privacy_manifest_sdk_audit.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- IAP商品設定: `notes/33_iap_product_setup_worksheet.md`
- App Store配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定表: `notes/50_release_go_no_go_decision_matrix.md`

## 12. 公式参照

- Apple Register an App ID: https://developer.apple.com/help/account/identifiers/register-an-app-id/
- Apple Enable app capabilities: https://developer.apple.com/help/account/manage-identifiers/enable-app-capabilities
- Apple Capabilities overview: https://developer.apple.com/help/account/capabilities/capabilities-overview/
- Apple Create an App Store Connect provisioning profile: https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/
- Apple Provisioning profile updates: https://developer.apple.com/help/account/manage-provisioning-profiles/provisioning-profile-updates/
- Apple About Sign in with Apple: https://developer.apple.com/help/account/capabilities/about-sign-in-with-apple/
- Apple Enabling server-to-server notifications: https://developer.apple.com/help/account/capabilities/enabling-server-to-server-notifications
