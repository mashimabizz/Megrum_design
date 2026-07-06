# 77. 初回オンボーディング・ガイドツアー実装計画書

> **⚠️ v2改訂（iter1226.337, 2026-07-06）**：初版実装（iter1226.336）へのオーナーFBを受けて仕様を改訂済み。本文の「7ステップ」「吹き出しは対象を隠さない側に配置」等は以下の v2 仕様が正：
> - **10ステップ構成**：ホーム紹介を3分割（推し×シリーズ／推し／求められているグッズを1つずつdim＋切り抜きでハイライトし、自動スクロールで追従）
> - **見せ方3種**：centerCard（ようこそ/完了）／spotlight（対象切り抜き＋**隣接**吹き出し・実測サイズで重なり防止）／banner（めぐり＝dimなし下部バナーでマップ全面を見せる）
> - **切り抜き座標系**：`overlayPreferenceValue` の GeometryReader ごと `ignoresSafeArea()` してアンカー解決と描画を同一座標系に（内側だけ広げるとセーフエリア分ズレる）
> - **カウンタ「n/10」＋次へ/スキップ常設**、文言は「この画面が何か→なぜ→どこを押すか」の順
> - **通知許可ダイアログも抑制対象**（App の `requestNativePushAuthorizationIfReady` ガード＋終了時再要求）
> - **QA**：`MEGRUM_VISUAL_QA_TUTORIAL_STEP`（数字 or home-1/inventory 等）で任意ステップ直接起動
> 詳細は notes/08 iter1226.337。

> **目的**：新規登録→初期設定（AccountSetup 8ステップ）完了直後のユーザーに、Megrum の価値と使い方をアプリ内で体験的に伝える「初回ガイドツアー」＋「最初の3ステップ・ミッションカード」を実装する。
>
> **想定読者**：この計画を受けて実装する別 AI／エンジニア。この文書だけで着手できるよう、統合ポイント（ファイル・シンボル・シグネチャ・行番号）を具体的に書いてある。
>
> **作成時点の前提**：`ios-native/`（SwiftUI, iOS 17+）が現行ユーザー向けiOS実装。`mobile/`（旧Expo）は削除済み。この計画は `ios-native/` のみを対象とし、`web/` と EAS Update は対象外。
>
> **オーナー承認済みの設計判断（2026-07-06）**：
> - **A = サンプル表示方式**：ツアー中のホームには「サンプル」バッジ付きのデモ候補を本物のレイアウトで表示する（吹き出し内プレビュー画像ではない）。ツアー終了と同時にサンプルは消す。
> - **B = カスタムオーバーレイ承認**：iOS標準の TipKit では「暗転スポットライト＋順番に進む強制ツアー」は実現不能なため、CLAUDE.md「iOS標準コンポーネント優先」の例外条項に基づきカスタムオーバーレイを新設することをオーナーが承認済み。タブバーの UIKit 直叩き（isHidden/toolbar切替）は iOS 27 で復帰失敗の既知バグがあるため**禁止**、dim レイヤーで覆う方式にする。

---

## 0. 用語（この計画書内）

| 用語 | 意味 |
|---|---|
| **ガイドツアー / ツアー** | 全画面dim＋スポットライト＋吹き出しで、タップで進む7ステップの初回案内。StoryLane 風。 |
| **ミッションカード** | ツアー後にホーム最上部へ常駐する「最初の3ステップ」チェックリスト。マイグッズ登録／ほしいもの登録／個別募集作成の3タスク。3つ完了で消える。 |
| **サンプル表示** | ツアー中だけホームの3セクションに流し込むデモ候補（`NativePreviewData` 由来）。「サンプル」バッジを付ける。 |
| **isTutorialActive** | ツアー実行中を示すフラグ。割り込み（広告・共有プロンプト・位置許可・通知遷移）を抑制する。 |

用語は実装後に `notes/10_glossary.md` の「A. プラットフォーム概念」へ追加する（§12 参照）。

---

## 1. ゴールと非ゴール

### ゴール
1. 初期設定完了（`accountStatus` が `.active` へ遷移）した**初回のみ**、ガイドツアーが自動で立ち上がる。
2. ツアーは7ステップ。ホーム3セクション紹介 → マイグッズ → ほしいもの → 個別募集 → やりとり → めぐり → 完了。各ステップは**画面のどこをタップしても次へ**進む（スポットライト部分の実タップは要求しない）。
3. ツアーはいつでもスキップ可。スキップ／完了どちらでも既読フラグを立て、二度と自動表示しない。
4. ツアー中のホームは「サンプル」バッジ付きデモ候補で埋まって見える。ツアー終了で即座に実データ（新規ユーザーは通常空）へ戻る。
5. ツアー後、ホーム最上部に「最初の3ステップ」ミッションカードが常駐。各タスクの完了は実データ（`inventory` / `wishes` / `listings`）の変化で自動検知しチェックを付ける。3つ完了でカードは消え、以後表示しない。
6. ツアー中は広告・X共有プロンプト・位置情報ダイアログ・通知タブ遷移を抑制する。
7. ドロワー／再視聴導線からツアーを手動で再生できる（任意、Phase 3）。

### 非ゴール
- **登録操作そのもの（3ステップ登録ウィザードの中身）をツアーで説明しない。** シート内部（`.sheet`/`fullScreenCover`）にはオーバーレイが届かないため。ツアーは「どこに何があるか」を教え、実際の登録はミッションカードから本物のフローで行わせる。
- **タブアイテム個別の精密スポットライトはしない。** iOS標準タブバーは UIKit 管理で SwiftUI から frame を取れない。タブへは実際に切り替えて見せ、必要なら「タブバー帯」を近似的に指す。
- AccountSetup（初期設定8ステップ）自体には手を入れない。`onboarding` 状態にも触れない。

---

## 2. アーキテクチャ全体像

```
MegrumRootView (@State: selectedTab, isTutorialActive, tutorialCoordinator)
  └─ authenticatedRoot
       └─ MegrumRootAuthenticatedContent
            ├─ .onChange(of: appState.viewer?.accountStatus) → ツアー発火判定
            └─ authenticatedTabs()
                 └─ MegrumAuthenticatedTabsView (AppDrawerInteractiveHost)
                      └─ MegrumAuthenticatedTabContentView
                           ├─ ZStack {
                           │    TabView(5タブ) ... zIndex 0
                           │    スライドオーバーレイ群 ... zIndex 88〜112
                           │    ★ TutorialTourOverlay ... zIndex 5000  ← 新規差し込み
                           │  }
                           └─ .groomViewerImmersiveOverlay ... zIndex 9998/9999
```

- **状態の持ち主**：ツアー進行状態は `TutorialTourCoordinator`（`ObservableObject`、`MegrumRootView` が `@StateObject` で保持）に集約。`isTutorialActive` は `coordinator.isActive` を参照。
- **タブ自動遷移**：`coordinator` が「次のステップの対象タブ」を持ち、`MegrumRootView.selectedTab` を書き換える（既存の `openWishSection` と同じ3値書き換えパターン）。
- **アンカー収集**：スポットライト対象（マイグッズ+ボタン等）に `TutorialAnchorPreferenceKey` を付与、ツアーオーバーレイ側で `overlayPreferenceValue` + `GeometryReader` で CGRect 解決（`HomeDiscoveryTabSwitcher.swift` のパターンを踏襲）。
- **純ロジック分離**：ステップ定義・遷移判定・既読フラグ・ミッション判定は View 非依存の caseless enum / struct に切り出し、`Tests/MegrumAppTests/` でユニットテストする（既存 `AccountSetupSessionPolicy` と同型）。

---

## 3. 新規ファイル一覧（`ios-native/Sources/MegrumApp/`）

| ファイル | 役割 | 種別 |
|---|---|---|
| `TutorialTourStep.swift` | ツアー7ステップの enum 定義（対象タブ・吹き出し文言・スポットライト対象アンカーID・カード種別） | 純ロジック |
| `TutorialTourCoordinator.swift` | `ObservableObject`。現在ステップ、`isActive`、`advance()`/`skip()`/`finish()`、対象タブ算出 | 状態管理 |
| `OnboardingTutorialProgressStore.swift` | 既読フラグの永続化（per-user UserDefaults）。`MeguriRoomIdentityStore` 型の caseless enum | 純ロジック |
| `TutorialAnchorPreferenceKey.swift` | スポットライト対象の frame 収集 PreferenceKey ＋ `.tutorialAnchor(_:)` View 拡張 | UI基盤 |
| `TutorialSpotlightOverlay.swift` | dim＋切り抜きスポットライト描画（`blendMode(.destinationOut)`+`compositingGroup`） | UI |
| `TutorialCalloutCard.swift` | 吹き出し（矢印付きカード）＋ステップ番号＋「次へ」「スキップ」 | UI |
| `TutorialTourOverlay.swift` | ツアーの最上位 View。dim＋spotlight＋callout＋welcome/completionカードを状態で出し分け、全面タップで advance | UI |
| `TutorialWelcomeCompletionCards.swift` | 冒頭ウェルカムカード・末尾完了カード（`BoardRoomEntryNoticeOverlay` のスタイル移植） | UI |
| `HomeStarterMissionCard.swift` | 「最初の3ステップ」ミッションカード View | UI |
| `HomeStarterMissionState.swift` | ミッション達成判定（`inventory`/`wishes`/`listings` から3タスクの done を算出）＋完了フラグ永続化 | 純ロジック |
| `TutorialSampleHomeData.swift` | ツアー中に流すサンプル候補（`NativePreviewData` を薄くラップし signals をペア生成） | 純ロジック |

**新規テストファイル（`ios-native/Tests/MegrumAppTests/`）**：
| ファイル | 対象 |
|---|---|
| `TutorialTourCoordinatorTests.swift` | ステップ前進・スキップ・完了・対象タブ |
| `OnboardingTutorialProgressStoreTests.swift` | per-user 永続化・既読判定 |
| `HomeStarterMissionStateTests.swift` | 3タスクの done 判定・全完了フラグ |

---

## 4. 詳細仕様

### 4.1 ツアーステップ定義（`TutorialTourStep.swift`）

```swift
import Foundation

/// 初回ガイドツアーの各ステップ。rawValue は VisualQA 起動やログに使えるよう小文字。
enum TutorialTourStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome        // 0: ウェルカムカード（中央、dimのみ、スポットライトなし）
    case homeSections   // 1: ホーム3セクション紹介（サンプル表示中）
    case inventory      // 2: マイグッズタブ + ボタン
    case wish           // 3: ほしいものタブ + ボタン
    case listing        // 4: 個別募集セクション「募集を追加」
    case trades         // 5: やりとりタブ・ステージバー
    case meguri         // 6: めぐりタブ（マップ全体）
    case completion     // 7: 完了カード（中央）

    var id: Int { rawValue }

    /// このステップで前面に出すべきタブ。welcome/completion/homeSections は .home。
    var targetTab: MegrumTab {
        switch self {
        case .welcome, .homeSections, .completion: return .home
        case .inventory: return .inventory
        case .wish, .listing: return .wish
        case .trades: return .trades
        case .meguri: return .meguri
        }
    }

    /// 中央カード表示か（スポットライトなし）。
    var isCardStep: Bool { self == .welcome || self == .completion }

    /// 吹き出しタイトル・本文（value 訴求は AccountSetupWelcomeStep が済ませているので操作ガイドに徹する）。
    var calloutTitle: String { ... }   // §4.2 の台本参照
    var calloutBody: String { ... }
}
```

> **注意**：`targetTab` の並びは実タブバー表示順（home → trades → meguri → inventory → wish）とは異なる enum 論理順。タブ自動遷移は `MegrumTab` を `selectedTab` に代入するだけなので順序は問題にならない。

### 4.2 ツアー台本（吹き出し文言）

CLAUDE.md の用語規約（「個別募集」「やりとり＝取引」「めぐり」）を厳守。value 訴求は AccountSetupWelcomeStep（既存3スライド：「推し活グッズを、ちゃんと交換。」等）で済んでいるので、ツアーは**操作の場所**に徹する。

| step | 対象 | タイトル | 本文 |
|---|---|---|---|
| welcome | 中央カード | Megrumへようこそ！🎉 | これから使い方をサッと案内するよ。1分でだいじょうぶ。［はじめる／スキップ］ |
| homeSections | ホーム3セクション | ここがホーム | 「推し×シリーズでマッチ」はあなたのほしいものに合う相手、「推しでマッチ」は同じ推しの相手のグッズ、「求められているグッズ」はあなたのグッズを欲しい人が並ぶよ。（※このステップだけサンプル表示中） |
| inventory | マイグッズ+ボタン | 持っているグッズを登録 | まずはここでマイグッズを登録。写真を撮るだけで、何枚でもまとめて登録できるよ。 |
| wish | ほしいもの+ボタン | 探しているグッズを登録 | ほしいものを登録すると、ホームに交換候補が出るようになるよ。 |
| listing | 募集を追加 | 個別募集で交換相手を探す | 「これを譲るからこれが欲しい」の条件が個別募集。作るとマッチ相手が見つかりやすくなるよ。 |
| trades | やりとりタブ | やりとりはここ | 交換の打診が届いたらこのタブ。チャットで条件を相談して、待ち合わせて交換！ |
| meguri | めぐりタブ | めぐりで“今”をシェア | 1km圏内の推し活マップ。近くの同担とグルームやチャットルームでつながれるよ。 |
| completion | 中央カード | 準備OK！🎊 | まずは「最初の3ステップ」からはじめよう。ホームでいつでも続きを確認できるよ。［はじめる］ |

> 文言は実装時に微調整可。ただし用語（個別募集／やりとり／めぐり／グルーム／チャットルーム）は変更禁止。

### 4.3 コーディネータ（`TutorialTourCoordinator.swift`）

```swift
import SwiftUI

@MainActor
final class TutorialTourCoordinator: ObservableObject {
    @Published private(set) var currentStep: TutorialTourStep?

    var isActive: Bool { currentStep != nil }

    func start() { currentStep = .welcome }

    /// 全面タップ or 「次へ」で前進。最後の completion で「はじめる」を押したら finish。
    func advance() {
        guard let step = currentStep else { return }
        if let next = TutorialTourStep(rawValue: step.rawValue + 1) {
            currentStep = next
        } else {
            finish()
        }
    }

    func skip() { currentStep = nil }   // 呼び出し側が既読フラグ保存
    func finish() { currentStep = nil }  // 同上
}
```

- **タブ自動遷移**：`MegrumRootView` が `.onChange(of: coordinator.currentStep)` を監視し、`selectedTab = step.targetTab` を代入（＋ `requestedTradesStage = nil` / `requestedWishSection = .listings`（listing ステップ時）をリセット）。**フラグ（isActive）は selectedTab を書き換える前に true になっている**必要がある（広告 onChange と同トランザクションで発火するため。start() で welcome にした時点で isActive=true）。
- **既読フラグ保存**：`skip()` / `finish()` の呼び出し側（`MegrumRootView`）で `OnboardingTutorialProgressStore.markTourCompleted(userID:)` を呼ぶ。

### 4.4 発火判定（`MegrumRootAuthenticatedContent.swift`）

`authenticatedTabs()` に落ちる分岐に、以下を付ける（`body` の `Group{...}` に `.onChange` を付与）：

```swift
.onChange(of: appState.viewer?.accountStatus) { oldValue, newValue in
    guard oldValue?.requiresSetup == true, newValue == .active else { return }
    guard let userID = appState.viewer?.id else { return }
    guard !OnboardingTutorialProgressStore.isTourCompleted(userID: userID) else { return }
    tutorialCoordinator.start()   // coordinator は MegrumRootView から渡す
}
```

**誤発火しない根拠（抽出で確認済み）**：
- 既存アクティブユーザーのログイン／セッション復帰は `nil → .active` 遷移で、`oldValue?.requiresSetup` が true にならない。
- stored セッションの `registered`/`verified` は `AccountSetupSessionPolicy.shouldReturnToLogin` でログインへ戻され、setup 完了経路に乗らない。
- stored の `.onboarding` から完了した場合は `onboarding(requiresSetup==true) → .active` で発火するが、これは初回完了なので**正しい**。
- 二重ガードとして UserDefaults 既読フラグ（下記）を必ず併用。

`AccountStatus`（`MegrumCore/UserProfileModels.swift`）：`registered`/`verified`/`onboarding` が `requiresSetup == true`、`active` が完了。

### 4.5 既読フラグ（`OnboardingTutorialProgressStore.swift`）

`MeguriRoomIdentityStore` / `MeguriHomePreferenceStore` と同じ caseless enum + `defaults` 注入 + userID 埋め込みキー：

```swift
enum OnboardingTutorialProgressStore {
    static func tourKey(userID: UUID) -> String {
        "onboarding.tour.completed.\(userID.uuidString.lowercased())"
    }
    static func missionKey(userID: UUID) -> String {
        "onboarding.mission.completed.\(userID.uuidString.lowercased())"
    }
    static func isTourCompleted(userID: UUID, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: tourKey(userID: userID))
    }
    static func markTourCompleted(userID: UUID, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: tourKey(userID: userID))
    }
    // mission も同型（isMissionCompleted / markMissionCompleted）
}
```

- **userID の取得**：`appState.viewer?.id`（`UserProfile.id: UUID`）。viewer は認証後の非同期ロードで確定するため、判定は viewer 確定後（`.onChange`/`.task(id: appState.viewer?.id)`）に行う。
- **VisualQA 強制表示**：VisualQA プレビューは常に同じ `NativePreviewData.viewerID` なので、一度見ると既読になり検証不能。**`visualQAInitialScreen == .tutorial` のときは既読フラグを無視して強制 start()** する分岐を入れる（§4.10）。

### 4.6 アンカー収集（`TutorialAnchorPreferenceKey.swift`）

`HomeDiscoveryTabSwitcher.swift` の `HomeDiscoveryTabFramePreferenceKey` をコピーし、キー型を `TutorialAnchorID`（`Hashable`）に変える。**private を外して** アプリ内から参照可能にする。

```swift
enum TutorialAnchorID: Hashable {
    case inventoryAddButton
    case wishAddButton
    case listingAddButton
    case homeSectionsArea
    case tradesStageBar
    // タブバー帯は近似なので不要（§4.7）
}

struct TutorialAnchorPreferenceKey: PreferenceKey {
    static let defaultValue: [TutorialAnchorID: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TutorialAnchorID: Anchor<CGRect>],
                       nextValue: () -> [TutorialAnchorID: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func tutorialAnchor(_ id: TutorialAnchorID) -> some View {
        anchorPreference(key: TutorialAnchorPreferenceKey.self, value: .bounds) { [id: $0] }
    }
}
```

**対象ビューへの付与箇所**（既存ファイルに `.tutorialAnchor(...)` を1行ずつ足す）：
- マイグッズ+ボタン（`AddGoodsButton` を置く `GoodsCollectionScreen` の該当箇所）→ `.tutorialAnchor(.inventoryAddButton)`
- ほしいもの+ボタン → `.tutorialAnchor(.wishAddButton)`
- 個別募集「募集を追加」（`AddIndividualListingButton`）→ `.tutorialAnchor(.listingAddButton)`
- ホーム3セクションの VStack → `.tutorialAnchor(.homeSectionsArea)`
- やりとりステージバー（`TradeStageBar`）→ `.tutorialAnchor(.tradesStageBar)`

> **重要な制約**：`anchorPreference` は `overlayPreferenceValue` を付けたビューの**子孫からしか**収集できない。ツアーオーバーレイ（`overlayPreferenceValue` 側）は全タブを内包する `MegrumAuthenticatedTabContentView` の ZStack に置くこと（タブ切替でアンカーが消えないため）。ただしタブ切替直後はまだ対象タブがマウントされておらずアンカーが未収集になり得る → ステップ遷移時に短い遅延（0.25s）後にスポットライトを出す、またはアンカー未解決時は「タブ帯を指す」フォールバックにする（§13 リスク）。

### 4.7 スポットライト描画（`TutorialSpotlightOverlay.swift`）

コードベースに `blendMode(.destinationOut)` の切り抜き実例は無いので新規。dim 色は既存標準の `Color.black.opacity(0.42)`。

```swift
// rect: overlayPreferenceValue 内 GeometryReader の proxy 座標系で解決した対象CGRect
Rectangle()
    .fill(Color.black.opacity(0.42))
    .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .frame(width: rect.width + 12, height: rect.height + 12)
            .position(x: rect.midX, y: rect.midY)
            .blendMode(.destinationOut)   // 切り抜き
    }
    .compositingGroup()   // ★必須。付けないと背後アプリまで貫通し黒画面化
    .ignoresSafeArea()
```

- **dim とアンカー解決は同じ `GeometryReader` 内で描く**（座標系ずれ防止）。
- スポットライト移動アニメ：`.animation(.snappy(duration: 0.22), value: currentStep)`。`@Environment(\.accessibilityReduceMotion)` が true なら即時移動（アニメなし）。
- **タップ処理**：オーバーレイ全体で `onTapGesture { coordinator.advance() }`。切り抜き部の実タップは受けさせない（誤操作防止）。＝ StoryLane で言う「タップで進む」。

### 4.8 吹き出し・カード（`TutorialCalloutCard.swift` / `TutorialWelcomeCompletionCards.swift`）

`AnchoredDestructiveConfirmationPopover` の `CalloutArrow`（private）と `BoardRoomEntryNoticeOverlay` のカードスタイルを**コピーして**専用部品化（private のため直接再利用不可）。守る数値：

- **矢印**：`CalloutArrow` の Path（3点三角形）。上向き／下向き両対応（下向きは `.rotationEffect(.degrees(180))`）。`fill(Color.white.opacity(0.94))` + `overlay { stroke(MegrumTheme.lavender.opacity(0.42), lineWidth: 1.4) }` + `.frame(width: 32, height: 18)` + `.shadow(color: .black.opacity(0.08), radius: 2, y: -1)`。
- **吹き出しカード**：`.padding(14)` + `.background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))` + `.overlay { RoundedRectangle(...).strokeBorder(.white.opacity(0.65), lineWidth: 1) }` + `.shadow(color: .black.opacity(0.14), radius: 18, y: 10)`。
- **ウェルカム／完了カード**（中央、`BoardRoomEntryNoticeOverlay` 移植）：dim `Color.black.opacity(0.42).ignoresSafeArea()`、カード白背景 `RoundedRectangle(cornerRadius: 24)` + 内 `padding 22` + `.padding(.horizontal, 26)` + `.shadow(color: .black.opacity(0.2), radius: 24, y: 12)`、`.transition(.opacity)`。
- **フォント**：見出し `.system(size: 17, weight: .black, design: .rounded)` + `MegrumTheme.ink`、本文 `.system(size: 12.5, weight: .semibold, design: .rounded)` + `MegrumTheme.muted` + `.lineSpacing(2)`。
- **主ボタン**：`.system(size: 16, weight: .black, design: .rounded)` + `.white` + `.frame(maxWidth: .infinity).frame(height: 50)` + `.background(MegrumTheme.lavender, in: RoundedRectangle(cornerRadius: 14))`。3色グラデにするなら `LinearGradient(colors: [MegrumTheme.sky, MegrumTheme.lavender], startPoint: .leading, endPoint: .trailing)`。
- **スキップ**：吹き出し／ウェルカムカードに小さめのテキストボタン「スキップ」。`MegrumTheme.muted`。
- **ステップインジケータ**：`AccountSetupWelcomeStep` の Capsule ドット（選択中 width 22 / 非選択 7、`MegrumTheme.lavender` / `.opacity(0.22)`）を流用可。7ステップ表示。
- **ハプティクス**：ボタンは `MegrumHaptics.performButtonTap(action)`、全面タップ前進は `MegrumHaptics.buttonTap()`。
- **import**：`MegrumTheme` は `import MegrumDesign` が必要。`MegrumHaptics` は同モジュール（import 不要）。**色は必ず `MegrumTheme` トークン**（`Color(red:...)` 直書き禁止）。

### 4.9 ツアーオーバーレイ本体（`TutorialTourOverlay.swift`）と差し込み

`MegrumAuthenticatedTabContentView.swift` の ZStack、**L169 `.zIndex(112)` の直後（ZStack 閉じ括弧の直前）** に以下を追加：

```swift
if let step = tutorialCoordinator.currentStep {
    TutorialTourOverlay(step: step, coordinator: tutorialCoordinator)
        .zIndex(5000)
        .transition(.opacity)
}
```

- `TutorialTourOverlay` は `overlayPreferenceValue(TutorialAnchorPreferenceKey.self)` で対象 frame を解決し、`step.isCardStep` なら中央カード、そうでなければ dim＋spotlight＋callout を描く。
- `coordinator` は `MegrumRootView` → `MegrumAuthenticatedTabsView` → `MegrumAuthenticatedTabContentView` へ `visualQAInitialScreen` と同じ経路で `@ObservedObject` 渡し。
- zIndex 5000 で TabView（タブバー含む）と全スライドオーバーレイ（88〜112）より上、グルームビューア（9998/9999、modifier で外側 ZStack を包むため常に最上位）より下。ドロワー（zIndex 10、別スタッキングコンテキスト）はツアー中に開かせない（§4.11）。

### 4.10 VisualQA 起動（`VisualQAPreviewMode.swift` / `MegrumRootRouting.swift`）

- `VisualQAInitialScreen` に **`case tutorial`**（rawValue は小文字 `"tutorial"`。パースは lowercased 前提）を追加。
- `VisualQATabRouteResolver.initialTab` は default で `.home` に落ちるので**変更不要**。
- `MegrumRootView`：`visualQAInitialScreen == .tutorial` のとき、既読フラグを無視して `tutorialCoordinator.start()` を初期化時／viewer 確定時に呼ぶ（`_showsDrawer = State(initialValue: visualQAInitialScreen == .drawerOpen)` と同じ init 読み取りパターン）。
- 起動：`SIMCTL_CHILD_MEGRUM_VISUAL_QA_PREVIEW_AUTH=1 SIMCTL_CHILD_MEGRUM_VISUAL_QA_INITIAL_SCREEN=tutorial xcrun simctl launch <UDID> tokyo.megrum.native.preview`。

### 4.11 割り込み抑制（`isTutorialActive` ガード）

`isTutorialActive`（= `tutorialCoordinator.isActive`）を配り、以下4系統をガード：

| 割り込み | ガード位置 | 方法 |
|---|---|---|
| **インタースティシャル広告** | `MegrumRootView.requestInterstitial(_:)`（L358） | 冒頭 `guard !isTutorialActive else { return }`。※大元1本でガード（`requestInterstitialIfPrepared` だけだと Search 経路が漏れる） |
| **X共有プロンプト** | `GoodsCollectionShareActions.presentSharePrompt(_:)`（L5）／`IndividualListingsScreen.presentListingSharePrompt(_:)`／`HomeDiscoveryExperienceActions.handleCreatedListingShare(_:)` | 各関数冒頭で `guard !OnboardingTutorialProgressStore.tutorialActive読取 else { return }`。※深い階層なので `appState` の `@Published` フラグで読むのが配線少（§下記） |
| **めぐり位置情報** | `MeguriScreenBoardActions.requestInitialLocationIfNeeded()` | 既存 VisualQA guard の直後に `guard !isTutorialActive else { return }`。**ツアー終了時に再実行**（`.onChange(of: isTutorialActive)` が false になったら呼ぶ）を必ず併設 |
| **通知タブ遷移** | `MegrumRootView.handleNotificationRoute` ＋ `.onChange(of: notificationDestinationTab)` | 冒頭 `guard !isTutorialActive else { return }`。新規登録直後は通知が来ないので**破棄**で十分 |

**フラグの配り方**：
- 浅い階層（広告・位置・通知）は `MegrumRootView` の `@State` / coordinator を prop で渡す（`visualQAInitialScreen` と同経路）。
- 深い階層（共有プロンプト3ファイル）は `MegrumAppState` に `@Published public internal(set) var isTutorialActive: Bool = false` を1つ足し、coordinator の `isActive` を `MegrumRootView` の `.onChange` で `appState.isTutorialActive` に同期する（`internal(set)` なので AppState 内メソッド `setTutorialActive(_:)` を足す）。共有プロンプト側は `appState.isTutorialActive` を読む。
- **ドロワー**：ツアー中は左端スワイプでドロワーが開くと 5000 レイヤーの上（zIndex 10 は別コンテキストだが視覚上かぶる）に出る。`AppDrawerInteractiveHost` の `openDrawerPanGesture` はツアー中 `showsDrawer` 書き込みをガードするか、ツアーオーバーレイが全面 `contentShape(Rectangle())` でタップを捕捉する（ジェスチャは `simultaneousGesture` なので完全遮断は不可、`showsDrawer` ガード推奨）。

> **設計判断（共有プロンプト）**：ミッションカード経由の実登録は通常「ツアー終了後」なので、`isTutorialActive` が false → 共有プロンプトは正常に出る（初回登録の達成感を壊さない）。ガードが効くのは「万一ツアー中に登録が完走した」異常系のみ。これで良い。

### 4.12 サンプル表示（`TutorialSampleHomeData.swift` ＋ ホーム配線）

**目的**：ツアーの `homeSections` ステップで、新規ユーザーの空ホームを「候補が並んだ本物のレイアウト」で見せる。

- **注入ポイント**：`MegrumAppState.homeMatchedItems` 等は `public internal(set)` で View から書けない → **`HomeScreen`（または `MegrumAuthenticatedTabContentView.homeTab`）の props 差し替え**が最低侵襲。`isTutorialActive`（かつ現在ステップが `.homeSections` またはツアー中全般）の間だけ、`matchedItems`/`possibleItems`/`conditionSignalsByItemID` をサンプルに差し替えて `HomeDiscoveryExperience` に渡す。
- **サンプル生成**：`PreviewMegrumRepository.loadHomeCandidateSections()`（L33）の組み立てをそのまま踏襲：
  ```swift
  let matched = NativePreviewData.homeMatchedItems
  let possible = NativePreviewData.homePossibleItems
  let signals = HomeCandidateConditionSignalDefaults.previewSignals(matchedItems: matched, possibleItems: possible)
  ```
  画像は `Bundle.module/TestGoodsImages/`（13枚同梱）。持ち主は `NativePreviewData.partnerID` のまま（`partnerItems()` が viewer.id を除外するため、partnerID でないと候補行に出ない）。
- **フィルタ通過の必須条件**：`userTagCandidates`/`userCandidates` は `HomeDiscoveryMatchPolicy.isMemberTagMatchEligible`/`isMemberMatchEligible` を通すので、**signals を必ずペアで渡す**（`previewSignals` をそのまま使えば通る）。
- **「求められているグッズ」セクション**：これは自分の `inventoryItems` 由来。新規ユーザーは空なのでこのセクションはサンプルでは出さない（or サンプル在庫を `inventoryItems` にも渡す。MVPでは上2セクションのみで十分）。
- **「サンプル」バッジ**：`HomeDiscoverySection` に `var badgeText: String? = nil` を追加し、private `HomeDiscoverySectionHeader` の `Text(title)` 直後（Spacer 前）にカプセルバッジを描画。ツアー中のみ呼び出し側（`HomeDiscoveryExperience` の3セクション）で `badgeText: "サンプル"` を渡す。バッジ配線もツアー中フラグで出し分け。
- **タップ無効化**：サンプル行のタップは `HomeDiscoveryExperience` 側で `onSelect` / `onSearchCandidate` クロージャを差し替え（`.disabled`/`.allowsHitTesting(false)` は押下フィードバックを殺すので**禁止**）。ツアー中は全面ツアーオーバーレイがタップを吸うので、実質サンプル行は触れない（オーバーレイ zIndex 5000 が上）。念のためクロージャも no-op か「サンプルだよ」トーストに。
- **リフレッシュ競合**：ツアー中に pull-to-refresh（`appState.refresh` → `loadHomeCandidateSections`）が走るとサンプルが実データに入れ替わる。ツアー中はサンプル props を優先し続ける（props 差し替えが AppState より優先されるので、ツアー中は AppState 更新が来ても props がサンプルなら表示は保たれる）。
- **終了時クリア**：`isTutorialActive` が false になれば props が実データに戻り、サンプルは即消える（「更新すると候補が消える」混乱は起きない。ツアー明示終了が唯一のクリア契機）。

### 4.13 ミッションカード（`HomeStarterMissionCard.swift` / `HomeStarterMissionState.swift`）

- **配置**：`HomeDiscoveryExperience.swift` body の `VStack(alignment: .leading, spacing: 14)`（L60）の**先頭**（`userTagCandidates` の if の前）。`.padding(.horizontal, 20)` は VStack 側にあるのでカードに横パディング不要。
- **表示条件**：`OnboardingTutorialProgressStore.isMissionCompleted(userID:) == false` **かつ** 3タスクが未達成のうちどれかが残っている間。ツアー未実施でも（既存ユーザーで新規に入れた場合など）表示してよいが、MVPでは「ツアー完了 or スキップ後」に出す。
- **既存 CTA との重複回避**：全候補空のとき出る `HomeEmptyCandidateCTACard`（推し追加／ほしいもの登録ボタン）と導線が重複する。**ミッションカード表示中は `HomeEmptyCandidateCTACard` を抑止**（`HomeDiscoveryExperience` の空状態分岐に `&& !isMissionCardVisible` を足す）。
- **3タスクと完了判定**（`HomeStarterMissionState`、純ロジック）：
  ```swift
  struct HomeStarterMissionState: Equatable {
      var inventoryDone: Bool   // !inventory.isEmpty
      var wishDone: Bool        // !wishes.isEmpty
      var listingDone: Bool     // listings.contains { $0.status != .closed }
      var allDone: Bool { inventoryDone && wishDone && listingDone }
      static func evaluate(inventory: [GoodsItem], wishes: [WishItem], listings: [IndividualListing]) -> Self { ... }
  }
  ```
  - `inventory` / `wishes` / `listings` は `MegrumAppState` の `@Published`。追加は `GoodsLocalStateReducer.upserting` / `IndividualListingStateReducer.upserting` 経由で先頭 insert される。`ObservableObject` 購読でリアクティブに再評価される。
  - `wishes` の要素型は `WishItem`（`GoodsItem` ではない）。`listings` の closed 除外は既存 `viewerIndividualListingCount`（`$0.status != .closed`）に合わせる。
- **各タスクのタップ**：チェック未のタスクをタップ → 該当タブ＋登録シートへ誘導（`onOpenInventory` / `onOpenWish` / 個別募集セクション）。既存コールバック網（`onOpenWish` 等）を再利用。
- **全完了**：`allDone` になったら軽い祝福（`MegrumHaptics` ＋短いアニメ）→ `markMissionCompleted(userID:)` → カードは次回以降非表示。カード内に「×」で手動非表示も可（その場合もフラグ保存）。

---

## 5. 既存ファイルへの変更一覧（差分サマリ）

| ファイル | 変更 |
|---|---|
| `MegrumRootView.swift` | `@StateObject tutorialCoordinator` 追加。`.onChange(of: coordinator.currentStep)` でタブ遷移＋`appState.isTutorialActive` 同期。`requestInterstitial`/`handleNotificationRoute`/notification onChange にガード。`visualQAInitialScreen == .tutorial` の強制起動。tabs へ coordinator 伝播 |
| `MegrumRootAuthenticatedContent.swift` | `.onChange(of: appState.viewer?.accountStatus)` で発火判定。coordinator を prop 受け |
| `MegrumAuthenticatedTabsView.swift` | coordinator を prop 透過（`visualQAInitialScreen` と同経路） |
| `MegrumAuthenticatedTabContentView.swift` | ZStack L169 直後に `TutorialTourOverlay`（zIndex 5000）。homeTab の matchedItems/possibleItems/signals をツアー中サンプル差し替え。coordinator prop 受け |
| `MegrumAppState.swift` | `@Published public internal(set) var isTutorialActive` ＋ `setTutorialActive(_:)` |
| `HomeDiscoveryExperience.swift` | VStack 先頭に `HomeStarterMissionCard`。空状態 CTA をミッション表示中は抑止。3セクションへ `badgeText: "サンプル"`（ツアー中）とタップ差し替え |
| `HomeDiscoverySection.swift` | `var badgeText: String? = nil` ＋ header にカプセルバッジ描画 |
| `GoodsCollectionScreen`（`AddGoodsButton` 箇所） | `.tutorialAnchor(.inventoryAddButton)` / `.tutorialAnchor(.wishAddButton)` |
| `IndividualListingListChromeViews.swift`（`AddIndividualListingButton`） | `.tutorialAnchor(.listingAddButton)` |
| `TradesScreen`（`TradeStageBar`） | `.tutorialAnchor(.tradesStageBar)` |
| `GoodsCollectionShareActions.swift` / `IndividualListingsScreen.swift` / `HomeDiscoveryExperienceActions.swift` | 共有プロンプト set にガード |
| `MeguriScreenBoardActions.swift` | `requestInitialLocationIfNeeded` にガード＋終了時再実行 |
| `MeguriScreen.swift` | `isTutorialActive` prop 受け＋`.onChange` で位置再実行 |
| `VisualQAPreviewMode.swift` | `case tutorial` 追加 |

---

## 6. Phase 分割（実装順）

段階的に価値を出し、各 Phase 末で `swift build` / `swift test` を緑にする。

### Phase 1：基盤 ＋ ミッションカード（最小で価値が出る）
1. `OnboardingTutorialProgressStore` ＋ テスト
2. `HomeStarterMissionState` ＋ テスト
3. `HomeStarterMissionCard` を `HomeDiscoveryExperience` に配置（空状態 CTA 抑止込み）
4. 完了直後にウェルカムカード1枚だけ（`TutorialWelcomeCompletionCards` の welcome のみ）→ 「はじめる」でミッションカードへ誘導
5. `MegrumAppState.isTutorialActive`（この段階ではミッション表示のみ）

→ この時点で「真っ白ホーム」問題が解消し、初回導線ができる。

### Phase 2：ガイドツアー本体（StoryLane 体験）
6. `TutorialTourStep` / `TutorialTourCoordinator` ＋ テスト
7. `TutorialAnchorPreferenceKey` ＋ 対象ビューへ `.tutorialAnchor`
8. `TutorialSpotlightOverlay` / `TutorialCalloutCard` / `TutorialTourOverlay`
9. `MegrumAuthenticatedTabContentView` へ差し込み（zIndex 5000）＋ coordinator 伝播
10. `MegrumRootView` のタブ自動遷移・発火判定・完了フラグ保存
11. 割り込み抑制4系統
12. `TutorialSampleHomeData` ＋ サンプル注入 ＋「サンプル」バッジ
13. `VisualQAPreviewMode.tutorial` ＋ シミュレータ検証

### Phase 3（任意）：再視聴導線
14. ドロワー「ヘルプ」等から `tutorialCoordinator.start()` を手動起動

---

## 7. 検証（VisualQA・テスト）

### ユニットテスト（`Tests/MegrumAppTests/`、XCTest。`func test...`）
- `TutorialTourCoordinatorTests`：welcome→…→completion の前進、`advance()` が最後で `finish()`、`skip()`、各ステップ `targetTab`。
- `OnboardingTutorialProgressStoreTests`：`UserDefaults(suiteName:)` 注入＋`removePersistentDomain`、per-user 独立、tour/mission 別キー。
- `HomeStarterMissionStateTests`：inventory/wish/listing の done 判定、closed 除外、`allDone`。

実行：
```
swift build --package-path ios-native
swift test --package-path ios-native --scratch-path /tmp/megrum-ios-native-build --enable-xctest --disable-swift-testing -j 1
```
（現在テスト関数 約1494個・0失敗が基準。追加後も 0失敗を維持）

### シミュレータ目視（VisualQA）
```
# ビルド → install → tutorial 起動
xcodebuild -project ios-native/MegrumNative.xcodeproj -scheme MegrumNative \
  -destination 'platform=iOS Simulator,id=C70DDDBB-2602-49E0-8F95-1F043BCCED76' \
  -derivedDataPath /tmp/megrum-native-xcodebuild CODE_SIGNING_ALLOWED=NO build
xcrun simctl install C70DDDBB-2602-49E0-8F95-1F043BCCED76 <app path>
SIMCTL_CHILD_MEGRUM_VISUAL_QA_PREVIEW_AUTH=1 \
SIMCTL_CHILD_MEGRUM_VISUAL_QA_INITIAL_SCREEN=tutorial \
xcrun simctl launch --terminate-running-process C70DDDBB-2602-49E0-8F95-1F043BCCED76 tokyo.megrum.native.preview
xcrun simctl io C70DDDBB-2602-49E0-8F95-1F043BCCED76 screenshot /tmp/tutorial.png
```
- 各ステップでスクショを撮り、スポットライト位置・吹き出し・サンプル表示・タブ遷移を確認。
- 実データ検証（新規登録直後の実挙動）は `MEGRUM_DEBUG_AUTO_SIGNIN_EMAIL/PASSWORD`（DEBUG限定）で。

---

## 8. ドキュメント更新義務（実装AIが必ず実施）

CLAUDE.md「A. 設計・実装変更時のチェックリスト」に従う。

1. **`notes/08_design_iterations.md`**：着手時に**先頭のiter番号を再確認**して採番（この計画作成時点で最新コミットは `1226.334` → 次は **`1226.335`**。ただし着手時にさらに進んでいる可能性があるので必ず先頭を確認）。最新が上。テンプレ（背景／変更内容（ファイル別）／影響範囲／確認方法／**セルフレビュー結果**／関連ファイル）。確認方法に `swift test N件 0失敗` を記載。
2. **`notes/10_glossary.md`**：「A. プラットフォーム概念」に「**ガイドツアー**」「**ミッションカード（最初の3ステップ）**」「**サンプル表示**」を4列（用語／別名英／定義／関連iter）で追加。画面IDを作るなら「G. 画面識別子」にも。ヘッダー「最終更新」を当日、「ステータス: Draft v4.xx（iter1226.335 〜を反映）」にバンプ。
3. **`notes/11_screen_inventory.md`**：「A. 認証・オンボーディング」に新サブセクション「### 初回ガイドツアー（A-3）」を追加。画面ID `GUIDE-tour` 系、モックアップ無しは「iter1226.335 で実装（モックアップ未）」表記。ホームのミッションカードは「C-1. ホーム」表へ1行。末尾「更新ログ」に1行追記。
4. **`notes/09_state_machines.md`**：ツアー進行を UserDefaults に**永続化する**（tour_completed / mission_completed フラグ）ので、簡潔な状態機械セクションを追加してよい（`not_started → in_progress → completed|skipped`）。状態IDは snake_case で実装一致。関連画面・関連ファイル併記。※純ローカルの一時ステップ（welcome..completion）は 08 記録のみで可。
5. **コミット**：`[iter1226.335] タイトル（30字以内目安）` ＋ bullet 本文 ＋ `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`。iter番号は 08 エントリと一致。**push はオーナー指示があれば**。

> **注意**：CLAUDE.md チェックリスト8項（mobile/EAS Update）は旧Expo前提で**現在は不要**。対象は `ios-native/` のみ。確認方法は `swift test` の結果。

---

## 9. リスク・落とし穴（実装前に必読）

1. **`compositingGroup()` 必須**：スポットライトの `blendMode(.destinationOut)` は dim レイヤに `.compositingGroup()` を付けないと背後アプリまで貫通して黒画面／表示崩れになる。
2. **anchorPreference の収集範囲**：`overlayPreferenceValue` を付けたビューの子孫からしか frame が上がらない。ツアーオーバーレイは全タブ内包の `MegrumAuthenticatedTabContentView` に置く。タブ切替直後は対象タブ未マウントでアンカー未解決 → ステップ遷移後 0.25s 待つ or 未解決時はタブ帯フォールバック。
3. **タブバー精密切り抜き不可**：UIKit 管理で SwiftUI から frame 取得不可。UIKit isHidden/toolbar 切替は iOS 27 復帰失敗の既知バグ（`MegrumAuthenticatedTabsView` L38 コメント）。dim で覆う＋タブ帯近似のみ。
4. **広告ガードは大元1本**：`requestInterstitialIfPrepared` だけだと Search 経路が漏れる → `MegrumRootView.requestInterstitial(_:)` L358 でガード。180秒キャップは初回に効かない（`lastPresentedAt=nil`）。
5. **位置情報の再実行必須**：`requestInitialLocationIfNeeded` を `.task` でスキップしたら、ツアー終了時に呼び直さないと位置許可・地図センタリング・フィード読込が二度と走らない。`.onChange(of: isTutorialActive)` false で再実行。
6. **共有プロンプトは3ファイル分散**：`GoodsCollectionShareActions` / `IndividualListingsScreen` / `HomeDiscoveryExperienceActions`。深いので `appState.isTutorialActive` 参照が配線少。
7. **サンプルは props 差し替えで**：`homeMatchedItems` 等は `public internal(set)`。AppState を汚さず `HomeScreen`/`homeTab` の props をツアー中だけサンプルに。`resolvedWithFallbackInventory` の catch 経路（「更新で候補消える」防止）にサンプルを混ぜない。signals を必ずペアで渡す（フィルタ通過条件）。
8. **`HomeMutualMatchEmptyStateView` は使うな**：`HomeMutualMatchPage` ごと未接続レガシー（grep 使用箇所ゼロ）。ミッションカードは `HomeDiscoveryExperience` VStack 先頭が正。
9. **iter番号は着手時に再確認**：この計画時点で `1226.334` コミット済み。着手時に `notes/08` 先頭を見て採番。
10. **VisualQA 既読ループ**：プレビューは常に同一 viewerID。`.tutorial` 起動時は既読フラグ無視で強制 start。
11. **macOS ビルド対応**：`Package.swift` は `.macOS(.v14)` を含む。UIKit 直依存（`UIScreen` 等）は `#if canImport(UIKit)` で囲む。純ロジックは UIKit 非依存に。
12. **色トークン厳守**：`MegrumTheme.*`（`import MegrumDesign`）。`Color(red:...)` 直書き禁止。フォントは `.system(size:weight:design: .rounded)`。
13. **reduceMotion 対応**：スポットライト移動・カード登場に `@Environment(\.accessibilityReduceMotion)` 分岐（既存 `AppDrawerOverlay`/`ProposalCompletionCard`）。

---

## 10. 受け入れ基準（Definition of Done）

- [ ] 新規登録→初期設定完了で、初回のみツアーが自動起動する（既存ユーザーのログイン・復帰では起動しない）。
- [ ] 7ステップを画面タップで進める。各ステップで対象タブへ自動遷移し、スポットライト or 中央カードが正しく出る。
- [ ] スキップ／完了で既読フラグが立ち、再起動しても自動表示されない。
- [ ] ツアー中のホームに「サンプル」バッジ付き候補が並び、終了で即消える。
- [ ] ツアー中に広告・共有プロンプト・位置ダイアログ・通知遷移が出ない。ツアー終了後、めぐりで位置ダイアログが正常に出る。
- [ ] ツアー後、ホーム最上部にミッションカードが常駐。実登録でチェックが付き、3完了で消え、再表示されない。
- [ ] `swift build` 成功、`swift test`（追加テスト含む）0失敗。
- [ ] `SIMCTL_CHILD_..._INITIAL_SCREEN=tutorial` でシミュレータ検証済み（スクショ添付）。
- [ ] `notes/08`（iter1226.335）・`10`・`11`・`09` 更新済み。コミット形式準拠。

---

## 付録A：主要統合ポイント早見表（ファイル:行 / シンボル）

| 用途 | 場所 |
|---|---|
| ツアーオーバーレイ差し込み | `MegrumAuthenticatedTabContentView.swift` L169 `.zIndex(112)` 直後 |
| 発火判定 | `MegrumRootAuthenticatedContent.swift` `body` に `.onChange(of: appState.viewer?.accountStatus)` |
| タブ自動遷移 | `MegrumRootView.swift` `@State selectedTab`（既存 `openWishSection` 3値パターン） |
| 広告ガード | `MegrumRootView.swift` L358 `requestInterstitial(_:)` |
| 共有プロンプトガード | `GoodsCollectionShareActions.swift` L5 `presentSharePrompt(_:)` ほか2件 |
| 位置情報ガード | `MeguriScreenBoardActions.swift` `requestInitialLocationIfNeeded()` |
| 通知遷移ガード | `MegrumRootView.swift` `handleNotificationRoute` / `.onChange(of: notificationDestinationTab)` |
| サンプル注入 | `MegrumAuthenticatedTabContentView.swift` L236 `homeTab` の `matchedItems`/`possibleItems` |
| サンプル生成手本 | `PreviewMegrumRepository.swift` L33 / `NativePreviewGoodsData.swift` L219,223 |
| ミッションカード配置 | `HomeDiscoveryExperience.swift` L60 `VStack(spacing: 14)` 先頭 |
| セクションバッジ | `HomeDiscoverySection.swift` private `HomeDiscoverySectionHeader` |
| アンカー技法の手本 | `HomeDiscoveryTabSwitcher.swift` `HomeDiscoveryTabFramePreferenceKey` |
| 吹き出し矢印の手本 | `AnchoredDestructiveConfirmationPopover.swift` `CalloutArrow`（private・コピー） |
| 中央カードの手本 | `BoardRoomEntryViews.swift` `BoardRoomEntryNoticeOverlay` |
| 既読フラグ手本 | `MeguriRoomIdentityStore.swift` / `MeguriHomePreferenceStore.swift` |
| 色トークン | `MegrumDesign/MegrumTheme.swift`（lavender/sky/pink/ink/muted/ok/canvas） |
| ハプティクス | `MegrumInteractionFeedback.swift` `MegrumHaptics` |
| VisualQA enum | `VisualQAPreviewMode.swift` `VisualQAInitialScreen` |
| テスト手本 | `AccountSetupSessionPolicyTests.swift` / `GoodsGridLayoutTests.swift`（UserDefaults注入） |
