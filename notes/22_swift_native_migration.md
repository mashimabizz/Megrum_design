# 22. Swift Native Migration

最終更新: 2026-05-31
ステータス: Active draft（iter306）

## 目的

MegrumはiOS一本で勝つ方針に切り替える。これ以降のユーザー向けiOS体験は、Swift / SwiftUI / UIKit / Apple標準フレームワークを正とし、Expo / React Native版は移行元・バックアップ・仕様参照として扱う。

## 参照した外部方針

- npaka「Codex のiOSアプリ開発のためのプロンプトまとめ」
- OpenAI Developers「Native development」
- Apple Developer「Adopting Liquid Glass」
- Apple Developer「Applying Liquid Glass to custom views」
- OpenAI Developers内の Native development collection に含まれる方針:
  - SwiftUI app shell はCLI-firstの小さな `xcodebuild` ループで作る
  - 大きなSwiftUI画面はMV firstで小さなViewへ分割する
  - Liquid Glassは監査してから高頻度フローへ限定導入し、古いOS向けfallbackを持つ
  - iOS Simulatorではアクセシビリティ階層・スクリーンショット・ログ・スタックを使って検証する

## バックアップ

Swift全面移行前の復元点を作成済み。

- Git backup branch: `backup/pre-swift-migration-20260531-030401`
- Backup base commit: `590c8834ea59de233ac3cf644f14d5f45cd433de`
- Local backup directory: `/Users/michitaka/Desktop/Megrum_backups/pre-swift-migration-20260531-030401`
- Local backup contents:
  - `HEAD.txt`
  - `current-branch.txt`
  - `git-status-short.txt`
  - `tracked-worktree.patch`
  - `staged.patch`
  - `untracked-files.tgz`
  - `untracked-files.zlist`

復元の基本手順:

```bash
git switch backup/pre-swift-migration-20260531-030401
git switch -c restore/pre-swift-migration
git apply /Users/michitaka/Desktop/Megrum_backups/pre-swift-migration-20260531-030401/tracked-worktree.patch
tar -xzf /Users/michitaka/Desktop/Megrum_backups/pre-swift-migration-20260531-030401/untracked-files.tgz
```

## 移行方針

### 1. 既存アプリを消さずに並走する

- `mobile/` は当面残す。
- `ios-native/` をSwift版の主作業場にする。
- Swift版が機能同等になるまでは、TestFlight配布の主線を急に切り替えない。
- 最終段階で、App Store Connectの本番Bundle IDへSwift版を接続する。

### 2. Swift版の技術方針

- Minimum target: iOS 17以上を基本線にする。
- iOS 26以上ではLiquid GlassのネイティブAPIを優先する。
- iOS 17/18/旧実行環境では `Material` / UIKit standard material / 独自最小fallbackで可読性を維持する。
- UIはSwiftUIを主軸にし、カメラ・写真・地図・通知・共有・購入・権限などは必要に応じてUIKit / Apple frameworkを直接使う。
- アーキテクチャはMV firstを基本にする。不要なMVVMや巨大ViewModelを増やさない。
- 共有状態は `@Observable` / `@State` / `@Environment` を優先し、非同期処理はSwift Concurrencyで整理する。
- 画面が直接fixtureを読む構造にしない。`MegrumAppState` と `MegrumRepository` を通し、Supabase接続へ差し替えられる境界を保つ。

### 3. MegrumでSwift化の恩恵が大きい領域

優先度高:

1. ホーム / 検索 / Liquid Glass操作レイヤー
2. グルーム閲覧・投稿・MapKit表示
3. 取引チャット、画像拡大、証跡撮影、通報導線
4. 在庫 / Wish / 個別募集の高密度グリッドと長押しメニュー
5. 左ドロワー、タブバー、階層ナビゲーション
6. 通知、設定、ブロック、評価一覧

### 4. Supabase / DBは当面維持する

- DBスキーマとRLSは既存Supabaseを継続する。
- Swift版はまず `MegrumData` の薄いPostgREST clientで同じデータを読む。必要性が明確になった段階でSupabase Swift SDK導入を判断する。
- DB変更はSwift移行そのものとは分ける。画面移行中にスキーマまで同時に壊さない。

## 実装フェーズ

### Phase 0: Native foundation

- `ios-native/` にSwift Packageを追加する。
- `MegrumCore` に状態名・主要モデル・ドメイン型を置く。
- `MegrumDesign` に色、タイポグラフィ、Liquid Glass primitiveを置く。
- `swift build` / `swift test` でCLI-first検証を作る。Codex Desktop上ではSwiftPMのbuild databaseが不安定になる場合があるため、testは `/tmp` のscratch pathを使う。

### Phase 1: App shell

- `ios-native/MegrumNative.xcodeproj` と `App/MegrumNativeApp.swift` でSwiftUI App hostを追加済み。
- Swift Package側では `MegrumApp` にRootView、TabView、主要タブ画面の骨格を置く。
- `MegrumAppState` と `MegrumRepository` で初期データロード境界を追加済み。
- `MegrumData` にSupabase設定とPostgRESTリクエスト境界を追加済み。環境/Info.plistに公開設定とviewer idがあればlive repository、なければpreview repositoryにfallbackする。
- Bundle IDは最初は比較用Previewを分け、最終的に本番IDへ寄せる。
- TabView / NavigationStack / deep link / auth restore / app lifecycleを組む。

### Phase 2: Auth and account

- 新規登録、ログイン、メールリンク復帰、プロフィール、推し設定、住所設定をSwift化する。
- キーボード回避、フォームvalidation、権限説明をiOS標準で作る。
- iter304で、Swift側に `AuthUser` / `AuthSession`、Supabase Auth client、`MegrumAuthState`、メール/パスワードのログイン・登録画面を追加した。
- iter305で、`AuthSessionStore`、`KeychainAuthSessionStore`、`InMemoryAuthSessionStore` を追加し、Swift版がログインsessionを保存・復元できる境界を持った。
- iter306で、保存済みまたはログイン直後の `AuthSession` を `MegrumAppStateFactory.repository(authSession:)` に渡し、session access tokenとuser idを `SupabaseMegrumRepository` へ反映できるようにした。
- 現時点のAuthはOAuth・メールリンク復帰・プロフィール自動作成までは未完了。次のPhase 2作業で認証リンク処理、Apple/Google、オンボーディング判定へ広げる。

### Phase 3: Exchange core

- ホーム、検索、在庫、Wish、個別募集、打診、取引チャットをSwift化する。
- 取引の状態名は `notes/09_state_machines.md` と完全一致させる。

### Phase 4: Meguri core

- グルーム、グルームマップ、スポット掲示板、掲示板マップ、めぐりメッセージをSwift化する。
- MapKit、PhotosUI、AVFoundation、UserNotificationsをネイティブに使う。

### Phase 5: Cutover

- Swift版PreviewをTestFlight配布する。
- 既存RN版との画面・機能差分をチェックリスト化する。
- App Store提出前に、Bundle ID、Associated Domains、通知、権限文言、Privacy Manifest、規約リンクを最終確認する。

## 完了条件

- 主要フローがSwift版で完走できる。
- 既存のP0バグがSwift版で再現しない。
- iOS Simulator / 実機 / TestFlightで確認済み。
- `notes/09_state_machines.md` と画面実装の状態名が一致している。
- rollback branchとローカルbackupから旧版へ戻せる。
