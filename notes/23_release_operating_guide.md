# 23. リリース運用ガイド

最終更新: 2026-06-26
ステータス: Historical / 要更新（RN時代の短期リリース運用メモ。現在の実装主線は `ios-native/`）

## まず最初に

今回の3日間で狙うゴールは、**「理想の全部入り」ではなく「App Store 審査へ初回提出できる状態」**です。  
そのため、新機能を増やすよりも、既存のコアフローを止めないことを優先します。

## 今回のリリースで通す範囲

### Must

- 新規登録
- ログイン / ログアウト
- 在庫登録 / 編集 / 削除
- ウィッシュ登録 / 編集 / 削除
- 個別条件（listings）登録 / 編集 / 削除
- マッチ候補表示
- 打診送信 / 受信 / ネゴ / 合意 / 取引完了
- 郵送交換の最小導線（交換手段選択 / 住所登録確認 / 合意後住所表示）
- 既存グルーム（ストーリー投稿 / 閲覧）を壊さず残す
- 規約 / プライバシー / 問い合わせ導線
- TestFlight内部配布
- App Store Connect への審査提出

### Decision Today

- 郵送交換をどこまで初回提出に含めるか
- スポット掲示板のMVP仕様

補足:
郵送交換はユーザーニーズが強いので、**今回入れるなら送信前住所確認と合意後住所表示までを最小線** にします。  
掲示板は「やる / やらない」より、**今日中に対象ユーザーと最小仕様を1回で決め切れるか** が勝負です。  
いまの理解では、掲示板は交換のためではなく、**現地の情報や温度感を見たい人向けのスレッド型掲示板** として整理するのが自然です。  
仕様が今日固まるなら Day 2-3 で最小実装へ進めます。固まらないなら今回の提出スコープから外します。

### Cut For Now

- めぐり3Dアバター / 3D演出

補足:
3日で審査提出まで持っていく前提では、**新規ソーシャル機能は仕様が即決できるものだけに絞る**のが最も効率的です。  
既存のグルームは残しつつ、3D演出は切り、新規掲示板は仕様確定の速度で採否を決めます。

## P0 / P1 / P2 の線引き

- `P0`
  - これがあると提出しない、または出してはいけない
  - 例: クラッシュ、登録不能、打診不能、在庫破損、法的導線切れ
- `P1`
  - 出せるが体験を落とすので、P0の次に直す
  - 例: 文言違和感、軽い導線の詰まり、見た目の崩れ
- `P2`
  - 今回は切ってよい
  - 例: 演出改善、仕様未確定の拡張機能、細かい磨き込み

判定の問い:
**「初回ユーザーがこの不具合に当たったら、登録・交換・提出のどれかが止まるか？」**  
止まるなら、ほぼ `P0` です。

## 使う管理ファイル

- 表形式トラッカー: [22_release_triage_tracker.csv](/Users/michitaka/Desktop/Megrum/notes/22_release_triage_tracker.csv)
- 設計判断の履歴: [08_design_iterations.md](/Users/michitaka/Desktop/Megrum/notes/08_design_iterations.md)

トラッカーの使い方:

- 1行 = 1論点 で管理する
- `current_symptom` に実際の症状を書く
- `repro_steps` に再現手順を書く
- `status` は `未着手 / 進行中 / 確認待ち / 完了 / 保留` を使う
- 判断に迷う項目はまず `P0仮` で置き、後で下げる
- バグ以外の「新たに確定した仕様」も、P0/P1の実装論点として行を分けてよい

## このフォルダの役割

### コア

- `ios-native/`
  - Swift Native iOSアプリ本体です。現在のユーザー向けリリース対象はここが中心です。
- `web/`
  - Next.js の管理者・運用・サポート確認用Webです。
- `supabase/`
  - DBスキーマ、RLS、Edge Functions、ローカルSupabase設定です。
- `notes/`
  - 要件、状態遷移、設計判断、運用メモを置く場所です。
- `利用規約など/`
  - 法的文書の原典です。弁護士納品のベース資料です。

### 削除済み

- `mobile/`: legacy Expo / React Native版
- `packages/`: legacy Web/mobile共有TS packages
- `Megrum/`: legacy JSX mockup
- `画面案/`: legacy design proposal PNG
- `Megrum めぐり/`: legacy 3D素材作業フォルダ

## GitHub と今のデスクトップフォルダの関係

このフォルダ `/Users/michitaka/Desktop/Megrum` は、**GitHubリポジトリのローカル作業コピー**です。

- デスクトップ上のファイル
  - あなたと私が実際に編集している生のファイル
- GitHub
  - `commit` と `push` をした時点のスナップショット置き場

重要:

- **未コミットの変更は GitHub にはまだ存在しません**
- **Codex desktop は、いまこのローカルフォルダを直接見て作業しています**
- **Xcode は、このローカルフォルダの中の `ios-native/MegrumNative.xcodeproj` と `ios-native/` を読んでいます**

つまり、今のアプリの正体は:
**`ios-native/` のローカルファイルが一次ソース、GitHubはその履歴共有先**です。

## アプリはどこの情報を読んでいるか

### iPhoneアプリ

- 画面 / 導線 / 共通UI / ロジック
  - `ios-native/Sources/MegrumApp/`
- Domain / data boundary
  - `ios-native/Sources/MegrumCore/`
  - `ios-native/Sources/MegrumData/`
- Xcode app host
  - `ios-native/MegrumNative.xcodeproj`
  - `ios-native/App/`

### Web

- 画面
  - `web/src/app/`
- Supabase連携
  - `web/src/lib/supabase/`

### バックエンド

- 実データの保存先
  - **Supabase のクラウドDB / Auth / Storage**
- ローカルでの定義
  - `supabase/config.toml`
- 変更履歴
  - `supabase/migrations/*.sql`

Swift Native app は `ios-native/Config/MegrumNative.xcconfig` と gitignore された local xcconfig / 環境変数から Supabase の公開設定を読みます。
`web/src/lib/supabase/server.ts` では、通常の公開キーに加えて、必要箇所で `SUPABASE_SECRET_KEY` も使います。

## サーバー / 配信 / Apple 側の住み分け

- `Supabase`
  - 認証、DB、Storage
- `Xcode`
  - Swift Native iOSアプリのビルド、署名、Archive作成
- `App Store Connect / TestFlight`
  - Apple側のビルド番号、配布状態、審査状態の管理
- `megrum.jp`
  - Webの公開ドメイン。認証コールバックにも使っています。

重要:
**App Store Connect のビルド番号や TestFlight の状態は、GitHubやこのフォルダの中には保存されません。**  
それは Apple 側の管理画面にある情報です。

## 3日間の進め方

### Day 1

- P0一覧を確定
- 認証 / 在庫 / 打診 / 合意 / 取引完了の実機確認
- めぐり3Dを今回スコープから外す方法を確定
- 郵送交換を入れる最小仕様（交換手段、住所入力、開示タイミング）を凍結
- スポット掲示板を今回入れるなら、MVP仕様をここで凍結

### Day 2

- P0を潰す
- TestFlightで友達と往復確認
- 郵送交換をやるなら最小導線を実装
- 掲示板をやるなら最小実装
- App Store Connect メタ情報の素材を揃える

### Day 3

- 審査向け最終確認
- スクリーンショット / 説明文 / URL入力
- Archive / Upload / 審査提出

## 私に渡してほしい情報の型

毎回この形で投げてもらえると最速です。

1. 症状
2. 再現手順
3. 理想の挙動
4. 重要度
5. どのBuild / どの端末で起きたか

例:

> 打診送信でエラーが出る。  
> TestFlight Build 8、相手プロフィールから打診で再現。  
> 理想は送信完了まで進むこと。  
> これはP0。

## 今のおすすめ判断

- 交換機能は最優先で守る
- 郵送交換は「住所登録確認」と「合意後開示」に絞って最短で入れる
- めぐりは3Dを切り、アイコン中心の形へ縮める
- 既存グルームは残し、新規掲示板は今日仕様を決められる時だけ進める
- リリースの勝ち条件は「一般公開」ではなく「審査提出完了」に置く
