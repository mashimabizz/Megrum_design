# 44. Privacy Manifest / SDK監査台帳

> 目的：提出直前に、最終iOSビルドのPrivacy Manifest、Required Reason API、SDK、通信先を確認するための台帳。
> コード変更なし。実ビルド確認時に結果を埋める。
> 外部サービス/委託先の横断整理は `notes/48_external_service_vendor_register.md` を使う。
> RLS、Storage、secret、APNs、管理者権限の提出前監査は `notes/54_prelaunch_security_audit_checklist.md` を使う。

最終更新: 2026-05-31
ステータス: Draft v0.1（実ビルド未監査）

---

## 1. 現時点の静的確認

2026-05-31時点で読めたSwift Native側の状態。

| 対象 | 現状 |
|---|---|
| `ios-native/App/PrivacyInfo.xcprivacy` | `NSPrivacyTracking=false`、UserDefaults `CA92.1` |
| `ios-native/App/Info.plist` | カメラ、位置情報、`ITSAppUsesNonExemptEncryption=false` |
| `ios-native/Package.swift` | 外部Swift Package依存なし |
| Supabase設定 | Info.plist / 環境からURLとキーを読む |
| APNs | token更新通知とSupabase通知クライアントあり |
| PhotosUI / Camera | GoodsEditor / Tradesで利用 |
| CoreLocation / MapKit系 | 現地交換、検索、取引チャットの現在地共有で利用 |

---

## 2. Privacy Manifest確認

| 項目 | 現状 | 最終確認 |
|---|---|---|
| `NSPrivacyTracking` | false | TODO |
| Tracking Domains | 未記載 | TODO |
| Collected Data Types | 未記載 | TODO |
| Required Reason API: UserDefaults | `CA92.1` | TODO |
| Required Reason API: File Timestamp | 未記載 | TODO |
| Required Reason API: Disk Space | 未記載 | TODO |
| Required Reason API: System Boot Time | 未記載 | TODO |
| 追加SDKのPrivacy Manifest | 外部Swift Packageなし。ただしXcodeリンク内容を最終確認 | TODO |

判断メモ:
- アプリ本体のApp Privacy回答はApp Store Connect側で行う。
- Privacy ManifestはRequired Reason APIやSDK由来の宣言不足がないかを確認する。
- 追加SDK、Crash、Analytics、IAP、AI SDKが入った場合は再監査する。

---

## 3. SDK/Framework監査

| 領域 | 確認対象 | 現状 | App Privacy影響 | 最終確認 |
|---|---|---|---|---|
| Auth / DB | Supabase REST | あり | Contact Info, Identifiers, User Content | TODO |
| Storage | Supabase Storage相当 | 画像保存あり得る | Photos or Videos | TODO |
| Push | APNs token | あり | Device ID | TODO |
| Camera | AVFoundation / UIKit camera | あり | Photos or Videos | TODO |
| Photo Picker | PhotosUI | あり | Photos or Videos | TODO |
| Location | CoreLocation | あり | Precise / Coarse Location | TODO |
| Maps | MapKit又は地図表示 | あり得る | Location | TODO |
| IAP | StoreKit | 有料機能次第 | Purchases | TODO |
| Analytics | Analytics SDK | 未確認 | Usage Data | TODO |
| Crash | Crash SDK | 未確認 | Diagnostics | TODO |
| External AI | AI SDK/API | 初回非表示推奨 | User Content / Other Data | TODO |
| Advertising | Ad SDK / IDFA | 初回なし推奨 | Tracking / Advertising Data | TODO |

---

## 4. 通信先監査

提出前に、実機又はビルド設定から確認する。

| 通信先 | 用途 | App Privacy影響 | 確認 |
|---|---|---|---|
| Supabase Project URL | Auth / DB / Storage | 多数 | TODO |
| Apple APNs | 通知 | Device ID | TODO |
| Apple App Store / StoreKit | IAP | Purchases | 有料機能を出す場合 |
| MapKit / Apple Location関連 | 地図/場所 | Location | TODO |
| 外部AI API | AI機能 | User Content / Other Data | 初回非表示ならなし |
| Analytics / Crash endpoint | 分析/診断 | Usage Data / Diagnostics | 導入時 |
| 広告SDK endpoint | 広告 | Tracking可能性 | 初回なし推奨 |

---

## 5. 確認コマンド案

ローカルで静的確認する場合:

```bash
plutil -p ios-native/App/PrivacyInfo.xcprivacy
plutil -p ios-native/App/Info.plist
sed -n '1,160p' ios-native/Package.swift
rg -n "Firebase|Analytics|Crash|StoreKit|Supabase|URLSession|PhotosUI|CoreLocation|MapKit|APNs|PrivacyInfo|NSPrivacy" ios-native
```

実機で確認する場合:
- iOSのApp Privacy Reportをオンにして通信先を確認する。
- TestFlightビルドで権限ダイアログ、位置情報、写真、カメラ、通知を確認する。
- 送信/保存されるデータが `notes/43` の回答と一致するか確認する。

---

## 6. 監査結果記録欄

| 項目 | 結果 | 証跡 |
|---|---|---|
| PrivacyInfo.xcprivacy確認 | 未 |  |
| Info.plist権限文言確認 | 未 |  |
| 外部SDK有無確認 | 未 |  |
| 通信先確認 | 未 |  |
| App Privacy回答との一致 | 未 |  |
| Tracking Noの根拠確認 | 未 |  |
| IAP有無確認 | 未 |  |
| 外部AI有無確認 | 未 |  |

---

## 7. No-Go

次に該当する場合は提出しない。

- `NSPrivacyTracking=false` なのに広告/トラッキングSDKが入っている。
- Required Reason APIの利用があるのにPrivacy Manifestに理由がない。
- 外部SDKのPrivacy Manifestが不足している。
- App Privacy回答にないデータが実ビルドで送信/保存されている。
- Privacy PolicyとApp Privacy回答が矛盾している。
- 外部AI又はIAPのSDK/APIが入っているのに、対応文書と回答が未更新。

---

## 8. 参照

- App Privacy回答シート: `notes/43_app_privacy_connect_answer_sheet.md`
- App Privacyインベントリ: `notes/27_app_privacy_data_inventory.md`
- 提出前セキュリティ監査: `notes/54_prelaunch_security_audit_checklist.md`
- Apple Developer署名・Capabilities事前確認: `notes/75_apple_developer_signing_capabilities_preflight.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- Apple Privacy Manifest Files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Apple Adding a Privacy Manifest: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
