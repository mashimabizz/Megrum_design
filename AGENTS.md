# AGENTS.md — Codex セッション Bootstrap

このファイルは、Codexがこのリポジトリに入った時に最初に読むファイルです。PC版Codexでもスマホ版Codex.aiでも、ここに書いたルールを優先してください。

## 作業前に必ず読むもの

1. このファイル全文
2. `notes/10_glossary.md` の目次
3. `notes/09_state_machines.md` の目次
4. `notes/08_design_iterations.md` の最新 iter 1〜2件
5. オーナーがタスク的な指示をした場合は `notes/USER_PLAYBOOK.md`
6. 法的文書、規約、プライバシー、特商法に関わる作業は `notes/17_legal_alignment.md`
7. iOS作業では `notes/22_swift_native_migration.md`

## 現在の実装方針

- ユーザー向けアプリは Swift Native iOS 一本に寄せる。
- 新機能、UI修正、ユーザーフローは原則 `ios-native/` を正とする。
- 旧 React Native / Expo 版の `mobile/`、旧 JSX mockup の `Megrum/`、旧画面案素材は iter1214 で削除済み。復活させない。
- `web/` は通常ユーザー向けWebではなく、管理者画面、運用画面、サポート確認、法務確認に必要な範囲だけ更新する。
- DB、Auth、Storage、Edge Functions は既存 Supabase を継続する。
- Xcode target が参照する `MegrumIcon.icon/` は削除しない。

## iOS開発ルール

### iOS標準優先

- できるだけ iOS 標準・ネイティブのコンポーネントと挙動を採用する。
- SwiftUI / UIKit / Apple framework で自然に作れるものを、独自Viewや独自アニメーションで作り直さない。
- 既存の標準コンポーネントを置き換える必要がある場合は、理由を先に明確にする。
- Liquid Glass は操作レイヤー、検索、シート、ツールバー、主要CTAなど効果がある場所へ限定的に使う。本文や可読性が重要なカードまで過剰にガラス化しない。

### 作業モード

- 高速モード: 小さな表示修正。`git diff --check` と必要な最小ビルドまででよい。iter記録は同一画面の修正が落ち着いた時点でまとめてもよい。
- 標準モード: 通常の機能修正、画面単位のUI修正、データ表示の意味が変わる修正。対象テストまたは小さな意味のあるビルドを実行し、必要な設計変更は `notes/08_design_iterations.md` に記録する。
- リリース前モード: TestFlight、App Store、本番DB、法務、セキュリティ、課金、通知、認証に関わる作業。検証を広めに取り、未確認項目を明示する。

明示指定がなければ、リスクに応じてCodexが選ぶ。保存処理、DB/API、認証、課金、通知、住所、通報、取引状態、打診/合意/完了に触る場合は標準モード以上に上げる。

### 検証コマンド

Swift package:

```bash
swift build --package-path ios-native
swift test --package-path ios-native --scratch-path /tmp/megrum-ios-native-build --enable-xctest --disable-swift-testing -j 1
```

Xcode app host:

```bash
xcodebuild -list -project ios-native/MegrumNative.xcodeproj
xcodebuild -project ios-native/MegrumNative.xcodeproj -scheme MegrumNative -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/megrum-native-xcodebuild CODE_SIGNING_ALLOWED=NO build
```

Swift NativeでXcode確認した場合は、project、scheme、destination、確認コマンドを完了報告に書く。

## 画面実装・リファクタリングのルール

- リファクタリングは、挙動、レイアウト、ナビゲーション、ビジネスロジックを維持する作業として扱う。仕様変更は別作業として分ける。
- 大きなSwiftUI画面は意味のある小さなViewへ分ける。巨大な `computed some View` の束へ置き換えない。
- 子コンポーネントへ親モデル全体を渡さず、必要最小限の値、状態、コールバックを渡す。
- 複雑なボタン処理、副作用、保存処理はView直下から出し、状態・Repository・小さな関数へ分ける。
- ルートの画面ツリーは安定させ、画面全体の `if/else` 入れ替えより局所的な条件表示を優先する。
- 変更しなかった重要項目もセルフレビューに明記する。例: 永続化、状態遷移、分析、通知、ナビゲーション、ユーザー表示文言。

## ファイル構造

### `ios-native/`

Swift 6 + SwiftUI / UIKit / Apple framework の主作業場。

| パス | 内容 |
|---|---|
| `ios-native/Package.swift` | Swift package定義 |
| `ios-native/MegrumNative.xcodeproj` | iOS app host |
| `ios-native/App/` | app entry、entitlements、Info.plist、Privacy manifest |
| `ios-native/Sources/MegrumCore/` | 状態名・主要モデル・ドメイン型 |
| `ios-native/Sources/MegrumData/` | Supabase/PostgREST/Auth/Storage request layer |
| `ios-native/Sources/MegrumDesign/` | 色、タイポグラフィ、Liquid Glass primitive |
| `ios-native/Sources/MegrumApp/` | SwiftUI app shell と画面 |
| `ios-native/Tests/` | Core/Data/App tests |

### `web/`

Next.js + React + TypeScript + Tailwind CSS。管理者・運用・サポート確認用。

作業前に `web/AGENTS.md` を読む。Next.jsのバージョン依存がありそうな時は `web/node_modules/next/dist/docs/` も確認する。

```bash
npm run web:dev
npm run web:build
npm run web:lint
```

### `supabase/`

DB migration、RLS、Edge Functions、Supabase local config。DB変更はSwift画面変更と混ぜすぎない。

### `notes/`

| ファイル | 用途 |
|---|---|
| `notes/02_system_requirements.md` | 機能要件 |
| `notes/05_data_model.md` | データモデル |
| `notes/08_design_iterations.md` | 設計判断・実装変更の履歴 |
| `notes/09_state_machines.md` | 状態遷移 |
| `notes/10_glossary.md` | 用語集・廃止用語 |
| `notes/13_api_spec.md` | API仕様 |
| `notes/17_legal_alignment.md` | 法務原典との整合 |
| `notes/22_swift_native_migration.md` | Swift Native移行方針 |
| `notes/USER_PLAYBOOK.md` | オーナー向け作業手順 |

## ワークフロー

設計・実装変更時は次の順で進める。

1. 変更内容を実装
2. 最小限で意味のある検証を実行
3. `notes/08_design_iterations.md` に新しい iteration エントリを追加
4. 状態遷移に影響があれば `notes/09_state_machines.md` を更新
5. 新用語・廃止用語があれば `notes/10_glossary.md` を更新
6. データモデルに影響があれば `notes/05_data_model.md` を更新
7. commit message は `[iter◯◯] [タイトル30文字以内]`
8. push

高速モードの小さなUI修正では 3〜6 をその場では省略してよい。ただし省略した場合は完了報告に書き、同一画面の修正が落ち着いた時点またはcommit前にまとめて記録する。

### iteration エントリ形式

`notes/08_design_iterations.md` は最新が上。

```markdown
## イテレーション◯◯：[簡潔なタイトル]

### 背景・問題意識

### 変更内容

#### `path/to/file`
- 変更点

### 影響範囲

### 確認方法
- `command`
  - passed

### セルフレビュー結果
- ✅ ...
```

## 用語ルール

`notes/10_glossary.md` を正とする。新規ドキュメントに次の旧用語を使わない。

- ダイレクトメッセージ / DM
- 交換依頼
- 交換募集 / 募集情報 / 募集登録
- MyLog / MyLog投稿 / 投稿コンテンツ
- 郵送

必要がある場合は、後継用語と廃止理由を `notes/10_glossary.md` の廃止用語セクションで確認する。

## 法務ルール

- 規約原典は `利用規約など/` 配下のdocx。git管理外。
- 代表者情報は非公表。請求があれば回答する方針。
- 法的文書を変える時は `notes/17_legal_alignment.md` を確認し、弁護士納品原典との差分を明確にする。

## 完了報告

完了時は短く次を書く。

- 変更ファイルと変更した挙動
- 保持した挙動
- 実行した検証コマンド
- 未実行の検証と理由
- 関連のない未コミット変更がある場合は、触っていないこと
