# M173 正式App Icon — 非対称交差メビウス

作成日：2026-10-08。Notion M173の本人依頼に基づくアイコン資産の本番化。

## 採用原典と作業境界

- タスク：[M173](https://www.notion.so/3f2bde3e1e3c81439aa3dd06d289aaf8)
- 採用原典：[Megrumブランドアイコン・カラー方針｜2026-10-07採用案](https://www.notion.so/3f2bde3e1e3c81dc9a5bead37be01d60)
- 添付PNG／JPEGを実際に閲覧。資料本文にはSVGの記載があるがSVGファイル自体は取得できなかったため、添付された採用画像から3面のBezierパスへ再構成した。元の作者のSVGやピクセル完全一致を称するものではない。
- 参照画像は `ios-native/App/IconComposerAssets/Mobius/Reference/owner-approved-2026-10-07.png` に保持。
- 基準コミット：`a2bcba0a74914dbd9d2cdda82139a79e77a86b9d`。固定調査用 `feat/candidate-sheet-redesign` は変更せず、`codex/megrum-m173-mobius-icon` で作業。
- アプリ全体カラー、Swiftの画面・配置・遷移・文言、DB/API、認証、通知処理には変更なし。色値はアイコン再現用で、M170の最終Design Tokenではない。

## 正式資産とレイヤー

正式App Iconは `MegrumMobius.icon/`。1024pxの透明SVG3面と `icon.json` を持つIcon Composer文書で、Appleのレンダラーで読み込み・書き出し可能。

小さい左ループ／大きい右ループ／中央を下降する前面の帯を保持。ハート、星、矢印、M等の追加記号は使用しない。シアン→ブルー→バイオレット→ピンク→コーラル→黄が同じ帯を巡る。

| 資産 | 役割 |
|---|---|
| `Mobius/01-rear-ribbon.svg` | 左ループから右上へ巡る背面 |
| `Mobius/02-right-return.svg` | 右ループの内側で戻る面 |
| `Mobius/03-front-ribbon.svg` | 中央交差を手前から通る下降する面 |
| `Mobius/megrum-mobius.svg` | 同じ形を統合したフラット前景 |
| `Mobius/megrum-mobius-mono.svg` | タブ用の白いtemplate前景 |

SVGには背景・外周角丸・影・blur・描き込んだspecularを入れない。背景／外周のマスク・OS材質はIcon Composer側に任せる。グループは不透明、specularなし、影はneutral 0.05に抑制。過度なガラス塊にならないよう元の強いシルエットを優先した。

`icon.json` は前面→右内側→背面の順に記録する。Apple `ictool` の実際の合成順で中央の前後関係を確認済み。CLIの一覧順と独自のflat previewの描画順を混同しない。

Mono系は前面白、右内側0.78431、背面0.65098のグレースケール指定を持つ。色がなくても中央交差と左右差を読み取れる。TintedはOSが指定色へ変換し、Clearは単色相当のOSレンダリングとして確認する。

## 実装参照と旧資産の扱い

| 資産・表示経路 | 現在の扱い |
|---|---|
| `MegrumMobius.icon` | Xcodeの唯一のApp Icon入力。Debug／ReleaseのApp Icon名を`MegrumMobius`へ更新 |
| `AppIcon.appiconset` | 同じ新メビウスのフラット1024px RGB、alphaなしへ更新。現行targetの主アイコン名ではない予備資産 |
| `MegrumBrandIcon.imageset` | 認証、共有画像、めぐり案内の旧星版を新メビウスへ更新。Light／Dark、1x／2x／3x |
| `LaunchIcon.imageset` | Info.plistのLaunch Screen／読み込み画面の旧星版を、透明な新メビウス前景へ更新。120／240／360px、既存表示サイズを維持 |
| `TabMeguriIcon.imageset` | めぐりタブの旧マークを同じ非対称外形の白templateへ更新。25／50／75px、template指定・既存tint・バッジを維持 |
| `MegrumIcon.icon` | 旧星版の履歴保持。AGENTS.mdの保持ルールに従って削除せず、Xcode参照を解除 |
| `MegrumIcon 起動.icon` | 旧起動案の履歴保持。現行Xcode target／Launch Screenから参照されない |
| `IconComposerAssets`の旧heart／orbit SVG | 履歴保持。READMEで旧案と明示。実行時からの参照なし。削除候補だが今回削除しない |
| Webのicon／favicon／site-assets | iOS App Iconタスクの範囲外として参照継続。今回の旧iOS表示競合とは区別し、変更しない |

Swiftの参照名とViewは維持し、同じ名前の画像だけを変更。画像選択やナビゲーションのコード修正は不要。

## 再生成と検証

```bash
python3 scripts/create-m173-mobius-sources.py
cp ios-native/App/IconComposerAssets/Mobius/0*.svg MegrumMobius.icon/Assets/
python3 scripts/export-m173-mobius-previews.py
```

書き出しスクリプトはmacOSの`sips`、Apple `ictool`、Python Pillowを使用する。既存Cloud Storageのplaceholderへ直接書き込まず、新規PNGをatomic replacementで反映する。

使用したコミュニティツール：`icon-composer-mcp@1.1.1` のCLI（[共有されたリポジトリ](https://github.com/ethbak/icon-composer-mcp)）。一時ディレクトリに導入し、作成・追加レイヤー・appearance指定・doctor・inspectに使用。CodexのMCP設定、Megrumのnpm依存、端末のグローバル設定は変更していない。

最終プレビューはCLIの疑似flat previewではなく、Xcode 27.0（27A266a）付属Icon Composer 27.0（129）の公式 `ictool` で出力。

- `Mobius/Previews/overview.png`：6モードの確認一覧。
- `Mobius/Previews/review-sheet.png`：小サイズ確認一覧。120px以下は1:1、180／1024px列は120pxへ縮小した掲示用表示。元PNGは各指定サイズを保持。
- iOS 27世代：Default／Dark／TintedLight／TintedDark／ClearLight／ClearDark × 1024／180／120／87／60／40／29px＝42枚。
- iOS 26世代：同じ6モード × 1024px＝6枚。
- 全48枚で出力寸法を読戻し確認。両世代で中央交差・左右差が残ること、小サイズで2つの穴と連続ループが潰れないことを目視確認。
- `xmllint --noout ios-native/App/IconComposerAssets/Mobius/*.svg MegrumMobius.icon/Assets/*.svg`：passed。
- `plutil -lint ios-native/MegrumNative.xcodeproj/project.pbxproj`：passed。
- `sips -g pixelWidth -g pixelHeight -g hasAlpha ios-native/App/Assets.xcassets/AppIcon.appiconset/App-Icon-1024x1024@1x.png`：1024×1024、alphaなし。
- Bundle内SVGと正本SVGのbytes一致、各imagesetのJSON参照先と寸法：passed。
- `git diff --check`：passed。

### Xcode確認

Google Drive上での`xcodebuild -list`／buildは`NSFileCoordinator`のファイル調整待ちで停止。固定HEADの`git archive HEAD ios-native`と今回のApp Icon／project／imageset差分だけを `/tmp/megrum-m173-validation/` へコピーし、同一ソースをローカルで検証する。gitignoredの環境固有xcconfigは検証用コピーへ含めない。

```bash
xcodebuild -list -project /tmp/megrum-m173-validation/ios-native/MegrumNative.xcodeproj
xcodebuild -project /tmp/megrum-m173-validation/ios-native/MegrumNative.xcodeproj -scheme MegrumNative -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/megrum-m173-xcodebuild CODE_SIGNING_ALLOWED=NO build
```

- Project：上記検証用コピーの `ios-native/MegrumNative.xcodeproj`、scheme：`MegrumNative`、destination：`generic/platform=iOS Simulator`。
- `xcodebuild -list`：passed。`MegrumNative` schemeを確認。
- `xcodebuild ... build`：**BUILD SUCCEEDED**。arm64／x86_64 Simulatorアプリを生成。
- `actool` の実入力に `MegrumMobius.icon`、`--app-icon MegrumMobius`、minimum deployment target 17.0を確認。
- ビルド済みInfo.plistの `CFBundleIconName = MegrumMobius` と生成された `MegrumMobius60x60@2x.png`／`MegrumMobius76x76@2x~ipad.png` を読戻し。生成PNGも目視で新メビウスを確認。
- `assetutil --info`でコンパイル済みAssets.carに `MegrumMobius`／`MegrumBrandIcon`／`LaunchIcon`／`TabMeguriIcon` が含まれ、旧 `MegrumIcon` が含まれないことを確認。
- 既存Swiftコードにactor isolation等のwarningあり。アイコン資産のエラーはなく、今回Swift修正は行っていない。
- 状態・用語・データモデルの追加／変更がないため、`notes/09_state_machines.md`、`notes/10_glossary.md`、`notes/05_data_model.md`は更新不要。

## 配布前に残る確認

- 実機ホーム／Spotlight／Settings／通知での表示、実際の壁紙を透過するClear、端末の動きに伴う反射は未実施。静止OS書き出しと区別して、配布前の端末確認へ残す。
- 署名付きRelease archive、TestFlight、App Store Connectへの提出・Product Page Previewは本依頼の資産作成から独立した配布作業で、今回未実施。
- Swiftのロジック変更がないためunit testは追加・再実行しない。全体の色Token化はM170へ引き渡す。
