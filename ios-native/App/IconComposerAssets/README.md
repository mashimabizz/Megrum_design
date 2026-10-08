# Megrum Icon Composer assets

## 現行採用アイコン（M173 / 2026-10-08）

正式App Iconはリポジトリ直下の `MegrumMobius.icon/`。本人採用の非対称な交差メビウスと多色グラデーションを基準に、`Mobius/` のSVGを使用する。Xcode Debug / ReleaseともApp Icon名は `MegrumMobius`。

- `Mobius/01-rear-ribbon.svg`：小さい左ループから大きい右ループへ上昇する背面。
- `Mobius/02-right-return.svg`：右ループ内側で戻る帯。
- `Mobius/03-front-ribbon.svg`：中央交差の前面を通る下降する帯。
- `Mobius/megrum-mobius.svg`：同じ3面を統合したフラット前景。
- `Mobius/megrum-mobius-mono.svg`：同じ外形の白いtemplate前景。
- `Mobius/Previews/`：Apple `ictool` の6表示モード、1024 / 180 / 120 / 87 / 60 / 40 / 29px、iOS 26世代と27世代の比較。

再生成・検証の手順、旧資産の扱い、未確認事項は `notes/83_m173_mobius_app_icon.md` を参照。以下は旧ハート案の記録であり、現行の推奨素材ではない。

## 旧ハート案（履歴保持）

Apple Icon Composer向けの前景SVG素材です。背景グラデーション、単色背景、外側の角丸マスクは含めていません。

## Recommended files

- `megrum-icon-composer-exchange-heart.svg`
  - 1024 x 1024 px
  - iPhone / iPad / Mac向けの推奨統合素材
  - 横長の循環矢印の中央にハートだけを置いた前景
- `megrum-icon-composer-exchange-heart-watch.svg`
  - 1088 x 1088 px
  - Watch向け。1024px素材を中央に配置し、32px余白を追加
- `megrum-icon-composer-exchange-heart-mono.svg`
  - 1024 x 1024 px
  - Icon Composer側でLiquid Glass、単色、Mono / Clear / Dark系の見た目を調整しやすい白前景版

## Layer files

Icon Composerで個別にmaterialやdepthを調整したい場合は、下記を同じ1024 x 1024キャンバスのレイヤーとして読み込む。

- `megrum-icon-composer-exchange-heart-arrows.svg`
- `megrum-icon-composer-exchange-heart-heart.svg`

## Design intent

- 「交換」は2本の太い循環矢印で明確に伝える。
- 矢印は横長にし、上下とも同じ濃いlavenderに揃えて、アイコン全体の読みをシンプルにする。
- 中央要素はハートだけにして、推し活・wish・欲しい気持ちを小サイズでも読める形で残す。
- ぬいぐるみ、人物写真、カード、複数グッズの詰め込みは避ける。
- SVG内に背景rect、外側マスク、clipPath、filter、text/font要素は入れていない。

## Suggested Icon Composer use

1. 背景はIcon Composer側でMegrumのlavender / sky / pink寄りのグラデーションを設定する。
2. まず `megrum-icon-composer-exchange-heart.svg` を前景として読み込む。
3. 調整幅を広げたい場合は、arrows / heart の2レイヤーを読み込み、矢印を背面、ハートを前面に置く。
4. Liquid Glassはハートに強め、矢印にはやや控えめにかけると、交換アイコンとしての輪郭が残りやすい。
5. App Store提出前は、iPhoneホーム画面の小サイズ、Spotlight、Settings、通知、App Store ConnectのProduct Page Previewで判読性を確認する。
