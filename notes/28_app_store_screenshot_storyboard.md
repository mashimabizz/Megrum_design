# 28. App Store スクリーンショット台本

最終更新: 2026-05-31

ステータス: Draft（撮影前の構成案）

## 目的

App Store Connectに提出するスクリーンショットの順番、画面、コピー、避けるべき表示を事前に決める。

この文書は撮影台本であり、アプリコードやデザインを変更しない。

## 1. 基本方針

- 初回提出では動画App Previewより、静止画スクリーンショットを優先する。
- Appleの仕様上、スクリーンショットは1〜10枚。初回は6〜8枚でコア体験を伝える。
- 検索結果では先頭1〜3枚が特に重要なので、ホーム、在庫/Wish、打診の流れを先に置く。
- 実機ビルドで撮影し、未完成機能、デバッグ表示、内部ID、個人情報、実在の住所、第三者権利物を写さない。
- K-POPやアニメの実在名称・実在画像は避け、架空のグループ名・グッズ名・画像で撮る。

## 2. デモデータ方針

スクショ用の架空データ候補:

| 種類 | 候補 |
|---|---|
| グループ | Starlume、Aster Nine、MiraPop |
| メンバー | Rina、Sora、Mio、Yui、Haru |
| グッズ | ランダムトレカ、アクスタ、缶バッジ、フォトカード |
| イベント | Starlume Arena Day 1、MiraPop Cafe |
| 場所 | サンプル会場、東口広場、カフェ前 |
| ユーザー名 | hana_trade、sora_goods、mio_collect |

審査用アカウントへ入れる具体的な在庫、wish、AW、取引チャットのデータは `notes/35_demo_account_review_data_plan.md` を使う。

避けるもの:
- 実在アーティスト名、実在アニメ名、実在キャラクター名
- 実在写真、公式ロゴ、CDジャケット、チケット画像
- 実住所、電話番号、メールアドレス
- 取引相手の本名、座席番号、外部連絡先

## 3. スクリーンショット順

| # | 画面 | 伝えること | 画面上コピー候補 | 注意 |
|---|---|---|---|---|
| 1 | ホーム / マッチ候補 | 条件が合う相手を見つけられる | 欲しいグッズに近い相手が見つかる | 空状態ではなく候補あり |
| 2 | 在庫登録 | 手元のグッズを整理できる | 譲れるグッズをかんたん登録 | 実写権利物を避ける |
| 3 | Wish登録 | 探しているグッズを明確化 | 欲しいグッズをWishで管理 | 検索や推し紐づけが見えるとよい |
| 4 | 打診作成 | 提示物と受け取る物を選ぶ | 条件を選んで打診 | 住所や個人情報は出さない |
| 5 | ネゴ / 合意 | 交換条件をすり合わせる | 反対提案から合意まで | 未完成機能を写さない |
| 6 | 取引チャット | 合意後のやり取り・証跡 | 当日の交換もチャットで安心 | 現在地はサンプル表示 |
| 7 | めぐり / 掲示板 | 現地の情報や温度感 | 近くの推し活情報を見つける | UGC通報導線があると審査説明に効く |
| 8 | 設定 / 安全 | 規約、通報、削除、問い合わせ | 安全機能とサポートも用意 | アカウント削除入口が見えるとよい |

## 4. 先頭3枚の狙い

### 1枚目: ホーム / マッチ候補

狙い:
- Megrumが「交換相手を探すアプリ」だと即座に伝える。
- ユーザーの在庫とWishがつながる体験を見せる。

避ける:
- 説明文だけの画面
- 候補0件
- 3Dや未完成演出

### 2枚目: 在庫登録

狙い:
- 手元のグッズを登録する入口を見せる。
- 写真、状態、数量、推しの整理ができることを見せる。

避ける:
- 実在グッズ画像
- AI機能が未完成の場合のAIボタン露出

### 3枚目: 打診作成

狙い:
- 交換アプリとしての一番大事な行動を見せる。
- 「譲る」「受け取る」「待ち合わせ」の条件整理を見せる。

避ける:
- 個人情報の露出
- 合意前に住所が見えている画面

## 5. 日本語コピー候補

スクリーンショット上に短い補足を載せる場合の候補。実UIの邪魔になる場合は使わない。

- 欲しいグッズに近い相手が見つかる
- 譲れるグッズをまとめて管理
- Wishで探しているものを整理
- 条件を選んで打診
- 反対提案から合意までアプリ内で
- 当日のやり取りも取引チャットで
- 近くの推し活情報をチェック
- 通報・ブロック・問い合わせもすぐに

## 6. 英語コピー候補

英語ローカライズを出す場合の候補。

- Find fans with matching items
- Organize what you can trade
- Keep your wishlist clear
- Send proposals with conditions
- Negotiate and agree in one flow
- Use trade chat on the day
- See local fan activity nearby
- Report, block, and get support

## 7. 撮影前チェック

- [ ] 最新の提出候補ビルドで撮影している
- [ ] TestFlight / Debug / Preview などの不要表示がない
- [ ] 実在ユーザーのメール、住所、電話番号、位置情報がない
- [ ] 実在アーティスト、作品、キャラクター、公式画像を使っていない
- [ ] App Store価格と違う有料表示がない
- [ ] 外部AI機能が未完成なら写っていない
- [ ] 3D機能が未完成なら写っていない
- [ ] 通報・ブロック・削除が未実装なら、安全画面に過度な表現をしない
- [ ] スクショとApp Review Notesの説明が一致している

## 8. 撮影後チェック

- [ ] 先頭3枚だけ見てもアプリ価値が伝わる
- [ ] 文字が小さすぎない
- [ ] 余白や切れがない
- [ ] 同じような画面が連続していない
- [ ] App Store Connectで必要なデバイスサイズに足りている
- [ ] ローカライズごとに文言が一致している
- [ ] メタデータの説明文と矛盾していない

## 9. App Review Notesとの対応

| レビュー経路 | 対応スクショ |
|---|---|
| Open inventory and Wish | #2, #3 |
| Create or inspect a proposal | #4 |
| Open trade chat | #6 |
| Terms / Privacy / Contact | #8 |
| Account deletion | #8又は別添証跡 |
| Report / Block | #7又は#8 |
| AI disclosure if enabled | #2又は別添証跡 |

## 10. 公式参照

- Apple Product Page: https://developer.apple.com/app-store/product-page/
- Apple Screenshot Specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Upload App Previews and Screenshots: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
