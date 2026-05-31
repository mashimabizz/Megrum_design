# 43. App Store Connect App Privacy回答シート

> 目的：App Store ConnectのApp Privacy質問に、Megrum初回提出ビルドとして回答しやすい形へ落とし込む。
> コード変更なし。実ビルドのSDK・通信・表示機能と照合してから最終回答する。

最終更新: 2026-05-31
ステータス: Draft v0.1（最終回答前）

---

## 1. 現時点の確認事実

| 項目 | 現状 |
|---|---|
| Swift Privacy Manifest | `NSPrivacyTracking=false`、UserDefaults Required Reason `CA92.1` |
| Swift Info.plist | カメラ、位置情報、暗号化免除フラグ、Social Networkingカテゴリあり |
| Swift Package | 外部Swift Package依存なし |
| ネットワーク | Supabase REST / Storage / Auth相当の通信あり |
| 写真 | グッズ、証跡、服装、プロフィール/投稿用途で画像選択・撮影あり |
| 位置情報 | 近くのグルーム/掲示板、現在地共有、現地交換モードで利用あり |
| 通知 | APNs tokenを扱う経路あり |
| IAP | 初回で有料機能を隠すなら未回答、出すならPurchases回答 |
| 外部AI | 初回で隠すなら未回答、出すならUser Content/Other Data等に反映 |

---

## 2. App Privacyトップ回答

| App Store Connect欄 | 推奨回答 | 条件 |
|---|---|---|
| Privacy Policy URL | `https://megrum.jp/legal/privacy` | 公開済みであること |
| User Privacy Choices URL | `https://megrum.jp/support/privacy-request` | 任意だが入力推奨 |
| Does this app collect data? | Yes | 認証、投稿、画像、取引チャット等がある |
| Tracking | No | IDFA/広告追跡/データブローカー共有なし前提 |

Appleの説明では、アプリが継続的又は主要機能として収集するデータは原則開示対象。問い合わせフォームのように任意・低頻度・主要機能外で、ユーザーが明示的に提供するものだけが任意開示になり得る。Megrumではアプリ機能の中核にあるデータが多いため、広めに開示する。

---

## 3. Data Types選択リスト

初回提出でコア交換、取引チャット、グルーム/掲示板、通知を出す場合の選択候補。

| Category | Data Type | 選択 | 条件 |
|---|---|---|---|
| Contact Info | Name | Yes | 表示名、問い合わせ時の氏名 |
| Contact Info | Email Address | Yes | 認証、問い合わせ |
| Contact Info | Phone Number | No | 初回MVPでは収集しない |
| Contact Info | Physical Address | No | 初回MVPでは収集しない |
| User Content | Photos or Videos | Yes | グッズ、証跡、服装、投稿、プロフィール画像 |
| User Content | Emails or Text Messages | Yes | 取引チャット、めぐりメッセージ等の非SMSメッセージ |
| User Content | Customer Support | Yes | 問い合わせ、通報、異議申し立て |
| User Content | Other User Content | Yes | プロフィール、在庫、wish、投稿、掲示板、自由記述 |
| Location | Precise Location | Conditional | 現在地座標を保存/送信する場合 |
| Location | Coarse Location | Yes | スポット、都道府県、活動エリア、近くの投稿 |
| Identifiers | User ID | Yes | Supabase user id、プロフィールID、ユーザー名 |
| Identifiers | Device ID | Conditional | APNs token等を保存する場合 |
| Purchases | Purchase History | Conditional | IAP/有料機能を出す場合 |
| Search History | Search History | Conditional | 検索語や保存検索をサーバー保存する場合 |
| Usage Data | Product Interaction | Conditional | 画面操作/行動分析を保存する場合 |
| Diagnostics | Crash Data | Conditional | クラッシュ収集を入れる場合 |
| Diagnostics | Performance Data | Conditional | パフォーマンス計測を入れる場合 |
| Other Data | Other Data Types | Conditional | 外部AI入力/出力ログなど、他カテゴリで表しにくい場合 |

初回で隠す/使わないなら選ばない候補:
- Purchases: 有料機能を完全に隠す場合
- Other Data Types: 外部AIを完全に隠す場合
- Phone Number / Physical Address: 初回MVPで扱わない場合
- Search History / Usage Data / Diagnostics: 実装・SDKで保存しない場合

---

## 4. Data Type別の回答

### 4.1 Contact Info / Name

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support |
| Examples | 表示名、問い合わせ時の氏名 |

### 4.2 Contact Info / Email Address

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Account Management, Customer Support |
| Examples | 登録メール、問い合わせメール |

### 4.3 Contact Info / Physical Address

初回MVPでは選択しない。

| 質問 | 回答 |
|---|---|
| Collected? | No |
| Linked to user? | No |
| Tracking? | No |
| Purposes | 該当なし |
| Examples | 該当なし |

提出前に、住所登録又は住所表示の導線が残っていないか確認する。

### 4.4 Contact Info / Phone Number

初回MVPでは選択しない。

| 質問 | 回答 |
|---|---|
| Collected? | No |
| Linked to user? | No |
| Tracking? | No |
| Purposes | 該当なし |
| Examples | 該当なし |

提出前に、電話番号入力の導線が残っていないか確認する。

### 4.5 User Content / Photos or Videos

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | グッズ写真、証跡写真、服装写真、プロフィール画像、投稿画像 |

### 4.6 User Content / Emails or Text Messages

Appleは、SMSではないアプリ内のユーザー間プライベートメッセージもこのデータタイプへ含める説明をしている。Megrumの取引チャット、めぐりメッセージ等が見える場合は選ぶ。

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety |
| Examples | 取引チャット、めぐりメッセージ、通報対象メッセージ |

### 4.7 User Content / Customer Support

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | Customer Support, Safety, App Functionality |
| Examples | 問い合わせ、通報、異議申し立て、返信内容 |

### 4.8 User Content / Other User Content

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support, Safety, Product Personalization |
| Examples | プロフィール、在庫、wish、グルーム、掲示板、自由記述 |

Product Personalizationは、推し、位置、wish等を使って候補表示・おすすめ表示を行う場合だけ選ぶ。単なる保存/表示だけならApp Functionality中心にする。

### 4.9 Location / Precise Location

現在地座標を保存又は送信する場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Safety |
| Examples | 現在地共有、現地交換モードの座標、近くの投稿表示 |

端末内だけで処理し、サーバーへ送らない場合はApp Privacy上の「収集」には該当しない可能性がある。実ビルドでサーバー保存/送信するなら選ぶ。

### 4.10 Location / Coarse Location

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Product Personalization |
| Examples | 都道府県、スポット、活動エリア、丸めた位置 |

### 4.11 Identifiers / User ID

| 質問 | 回答 |
|---|---|
| Collected? | Yes |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Account Management, Customer Support, Safety |
| Examples | Supabase user id、プロフィールID、表示ID |

### 4.12 Identifiers / Device ID

APNs token等を保存する場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality |
| Examples | APNs device token |

IDFAを使う場合は別扱い。初回はIDFAなし前提。

### 4.13 Purchases / Purchase History

有料機能を出す場合のみ。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Customer Support |
| Examples | IAP購入状態、サブスクリプション状態、ブースト購入履歴 |

Appleが処理するカード番号などのPayment Infoは、開発者がアクセスしないならMegrum側の収集としては通常選ばない。Megrumが扱うのは購入状態・履歴。

### 4.14 Search History / Search History

検索語又は保存検索をサーバー保存する場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | Yes |
| Tracking? | No |
| Purposes | App Functionality, Product Personalization |
| Examples | グッズ検索語、保存検索条件 |

端末内だけで検索し保存しない場合は選ばない。

### 4.15 Usage Data / Product Interaction

分析ログを保存する場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | 原則Yes |
| Tracking? | No |
| Purposes | Analytics, App Functionality |
| Examples | 画面操作、機能利用、通知開封、投稿/検索利用状況 |

初回でAnalytics SDKや行動ログを入れないなら選ばない。

### 4.16 Diagnostics / Crash Data

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | SDK設定による |
| Tracking? | No |
| Purposes | App Functionality, Analytics |
| Examples | クラッシュログ |

Appleのクラッシュ情報のみで開発者が追加収集しない場合、App Store Connect回答上どう扱うかは実際の取得方法で判断する。

### 4.17 Diagnostics / Performance Data

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | SDK設定による |
| Tracking? | No |
| Purposes | App Functionality, Analytics |
| Examples | 起動時間、エラー、パフォーマンス |

### 4.18 Other Data / Other Data Types

外部AI入力/出力ログなど、他カテゴリで表しにくいデータを保存する場合。

| 質問 | 回答 |
|---|---|
| Collected? | Conditional |
| Linked to user? | 入力内容による。原則Yes寄せ |
| Tracking? | No |
| Purposes | App Functionality, Safety, Customer Support |
| Examples | AI入力、AI出力、AI安全確認ログ |

初回で外部AIを隠すなら選ばない。

---

## 5. 選ばない候補

初回提出の現行前提では、次は原則選ばない。

| Data Type | 理由 |
|---|---|
| Payment Info | Apple IAPのカード番号等をMegrumが取得しない |
| Credit Info | 取得しない |
| Health / Fitness | 取得しない |
| Contacts | 端末連絡先を取得しない |
| Browsing History | オープンWeb閲覧履歴を取得しない |
| Advertising Data | 初回広告なし前提 |
| Sensitive Info | 積極取得しない |
| Audio Data | 録音機能なし前提 |
| Environment Scanning / Hands / Head | 空間・身体トラッキングなし前提 |

---

## 6. App Store Connect入力順

1. App Privacyを開く。
2. Privacy Policy URLへ `https://megrum.jp/legal/privacy` を入れる。
3. User Privacy Choices URLへ `https://megrum.jp/support/privacy-request` を入れるか判断する。
4. Data CollectionでYesを選ぶ。
5. §3のData Typesを、実ビルドで見えている機能に合わせて選ぶ。
6. 各Data Typeで、Linked to user、Tracking、Purposesを§4に沿って回答する。
7. Product Page Previewを確認する。
8. `notes/36` に回答控えを保存する。

---

## 7. No-Go

次に該当する場合は、App Privacy回答を確定しない。

- 実ビルドに含まれるSDKが未確認。
- 外部AIが見えるのに送信情報と学習利用が未確定。
- 有料機能が見えるのにPurchasesを回答していない。
- 住所を扱う導線があるのにPhysical Addressを回答していない。
- 取引チャットがあるのにEmails or Text Messagesを回答していない。
- 位置情報をサーバー送信するのにLocationを回答していない。
- Analytics/Crash SDKがあるのにUsage Data/Diagnosticsの要否を確認していない。
- TrackingをNoにする根拠が崩れている。

---

## 8. 参照

- App Privacyインベントリ: `notes/27_app_privacy_data_inventory.md`
- Privacy Manifest/SDK監査台帳: `notes/44_privacy_manifest_sdk_audit.md`
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple App Privacy Reference: https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy
- Apple Manage App Privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Apple Privacy Manifest Files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
