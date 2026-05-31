# 65. Release Candidateハンドオフチェックリスト

最終更新: 2026-05-31

ステータス: Draft v0.1（開発セッション連携用）

## 目的

開発セッションから法務・App Store提出準備セッションへ、完成候補ビルドの情報を受け渡す時に必要な情報、証跡、No-Go、差し戻し条件を整理する。

この文書はハンドオフ表であり、コード、ビルド、App Store Connect設定、公開URL、DB、外部サービス設定は変更しない。

## 1. 使うタイミング

使うタイミング:
- 開発側でP0実装の区切りがついた。
- 完成候補ビルドをTestFlight又はApp Store Connectへ上げる準備ができた。
- 法務・リリース準備側でApp Store Connect入力、公開URL確認、スモークテスト、Go / No-Go判定へ進みたい。

使わないタイミング:
- 開発側のP0変更がまだ大きく動いている。
- Version / Build Numberが未確定。
- 初回提出で出す/隠す機能が未確定。
- デモアカウント、公開URL、App Privacyの最終確認に進めない。

## 2. ハンドオフの原則

- 元ツリー `/Users/michitaka/Desktop/Megrum` の開発差分は、開発セッションが責任を持ってcommitする。
- 法務・リリース準備docsは `/Users/michitaka/Desktop/Megrum_release_prep` の `codex/legal-release-prep` を正本とする。
- 開発側で `git add -A` しない。法務docsを実装PRへ混ぜない。
- Release Candidateのハンドオフは、口頭ではなくこの表の項目で記録する。
- ハンドオフ後にP0コード修正が入った場合、同じBuildを提出候補にしない。新しいBuildで再確認する。

## 3. 開発側から受け取る情報

| 項目 | 必須 | 値 |
|---|---|---|
| 開発branch | Yes | TODO |
| 開発commit SHA | Yes | TODO |
| App Version | Yes | TODO |
| Build Number | Yes | TODO |
| Bundle ID | Yes | TODO |
| App ID / Team ID | Yes | TODO |
| Signing mode | Yes | Automatic / Manual |
| Capabilities / entitlements | Yes | TODO |
| Build作成方法 | Yes | Xcode / EAS / Other |
| Upload方法 | Yes | Xcode / Transporter / Other |
| App Store Connect処理状態 | Yes | Processing / Ready / Warning |
| TestFlight内部配布可否 | Yes | TODO |
| 対象端末/OS | Yes | TODO |
| Swift build/test結果 | Yes | TODO |
| xcodebuild結果 | 条件付き | TODO |
| 既知のP0不具合 | Yes | TODO |
| 既知のP1/P2不具合 | Yes | TODO |
| 未完了だが隠した機能 | Yes | TODO |
| 初回で出す機能 | Yes | TODO |
| 初回で隠す機能 | Yes | TODO |

No-Go:
- commit SHAが不明。
- TestFlightで確認したBuild Numberと提出予定Build Numberが違う。
- Bundle ID、App ID、Team ID、Capabilities、entitlementsが `notes/75` で照合できない。
- P0不具合が残っているのに提出候補として渡されている。
- 隠す機能が画面に残っている可能性がある。

## 4. 機能スコープ確認

| 領域 | 出す/隠す | 開発側確認 | 法務/提出側の参照 |
|---|---|---|---|
| Auth / Account | 出す | TODO | `notes/42`, `notes/45` |
| 在庫 / wish | 出す | TODO | `notes/42` |
| 打診 / ネゴ / 合意 | 出す | TODO | `notes/42` |
| 取引チャット | 出す | TODO | `notes/42`, `notes/26` |
| 通報 / ブロック | 出す | TODO | `notes/26`, `notes/42` |
| アカウント削除 | 出す | TODO | `notes/45` |
| 公開URL導線 | 出す | TODO | `notes/37`, `notes/63` |
| グルーム | 出す/隠す | TODO | `notes/26`, `notes/59` |
| スポット掲示板 | 出す/隠す | TODO | `notes/26`, `notes/59` |
| 有料機能 | 出す/隠す | TODO | `notes/33`, `notes/59` |
| 外部AI | 出す/隠す | TODO | `notes/27`, `notes/48`, `notes/59` |
| 未完成3D | 隠す推奨 | TODO | `notes/59` |
| 住所/電話番号入力 | 隠す推奨 | TODO | `notes/59` |
| debug / 管理画面 | 隠す | TODO | `notes/54`, `notes/63` |

No-Go:
- `notes/59_initial_release_scope_exposure_audit.md` で隠す扱いのものが、実ビルドで見えている。
- App Store説明文やReview Notesで説明する機能が、実ビルドで辿れない。
- App Privacyで回答しないデータを、実ビルドで入力又は送信している。

## 5. 開発側が添える検証結果

| Check | 必須 | 結果 | 証跡 |
|---|---|---|---|
| DEV-001 | Swift build | TODO | TODO |
| DEV-002 | Swift test | TODO | TODO |
| DEV-003 | xcodebuild Simulator build | App shell対象なら必須 | TODO |
| DEV-004 | 起動確認 | Yes | TODO |
| DEV-005 | Auth smoke | Yes | TODO |
| DEV-006 | 在庫/wish smoke | Yes | TODO |
| DEV-007 | 打診/取引 smoke | Yes | TODO |
| DEV-008 | 通報/ブロック/削除入口 | Yes | TODO |
| DEV-009 | App Store Connect upload | 提出候補なら必須 | TODO |
| DEV-010 | Crash / warning | Yes | TODO |

推奨コマンド例:

```bash
swift build --package-path ios-native
swift test --package-path ios-native --scratch-path /tmp/megrum-ios-native-build --enable-xctest --disable-swift-testing -j 1
xcodebuild -scheme MegrumNative -destination 'platform=iOS Simulator,name=iPhone 16' build
```

実際に使ったproject/workspace、scheme、destination、OS、Build Numberは、開発側の完了報告で明記する。

## 6. 法務・提出側が受領後に行うこと

| 順 | 作業 | 参照 |
|---|---|---|
| 1 | Version / Build Number / commit SHAを `notes/36` と `notes/64` に記録 | `notes/36`, `notes/64` |
| 2 | 初回提出スコープ露出監査を実ビルドで行う | `notes/59` |
| 3 | P0スモークテストを最低2アカウントで行う | `notes/42` |
| 4 | 公開URLがアプリ内導線から開くか確認 | `notes/37` |
| 5 | 公開ページのレダクションQAを行う | `notes/63` |
| 6 | App Privacy / Privacy Manifest / SDK監査を最終照合 | `notes/27`, `notes/43`, `notes/44`, `notes/48` |
| 7 | App Store Connect転記文面を最終化 | `notes/40`, `notes/60` |
| 8 | Apple Developer署名・Capabilities事前確認を行う | `notes/75` |
| 9 | Go / No-Goを判定 | `notes/50` |
| 10 | 手動提出チェックへ進む | `notes/62` |

## 7. 差し戻し条件

開発セッションへ差し戻す条件:
- デモアカウントでログインできない。
- コアフローが途中で止まる。
- 画面クラッシュ、空白画面、戻れない画面がある。
- 通報、ブロック、アカウント削除入口が説明できない。
- 初回で隠す機能が画面に見えている。
- 住所/電話番号入力が初回提出スコープに残っている。
- 実ユーザー情報、内部ID、debug表示が画面やスクショに出る。
- App Privacyと実ビルドの収集/送信データが矛盾する。
- Bundle ID、App ID、Capabilities、entitlements、provisioning profile、certificate、App Store Connect app recordが矛盾する。
- RLS、Storage、secret、APNs、管理者権限の監査でNo-Goが残る。

差し戻し時に渡す情報:

```text
Issue:
Severity: P0 / P1 / P2
Affected build:
Screen/flow:
Steps to reproduce:
Expected:
Actual:
Evidence:
Can hide instead of fix:
Relevant docs:
```

## 8. ハンドオフ完了テンプレート

```text
Release Candidate handoff

Development branch:
Commit SHA:
App Version:
Build Number:
Bundle ID:
App ID / Team ID:
Signing mode:
Capabilities / entitlements:
Uploaded to App Store Connect: Yes / No
TestFlight internal ready: Yes / No

Scope visible:
- Core exchange:
- UGC:
- Paid features:
- External AI:
- Unfinished 3D:
- Address/phone inputs:

Validation:
- swift build:
- swift test:
- xcodebuild:
- Smoke:

Known issues:
- P0:
- P1:
- P2:

Handoff decision:
- Accept for release QA / Return to development
```

## 9. 関連文書

- 法務branch統合手順: `notes/57_legal_release_branch_integration_plan.md`
- TestFlight / App Review提出ランブック: `notes/32_testflight_review_submission_runbook.md`
- Apple Developer署名・Capabilities事前確認: `notes/75_apple_developer_signing_capabilities_preflight.md`
- P0スモークテスト台本: `notes/42_p0_smoke_test_script.md`
- 初回提出スコープ露出監査: `notes/59_initial_release_scope_exposure_audit.md`
- App Review手動提出チェック: `notes/62_app_review_manual_submission_checklist.md`
- リリース証跡フォルダ索引: `notes/64_release_evidence_folder_index.md`
- Go / No-Go判定: `notes/50_release_go_no_go_decision_matrix.md`
