# Claude Design イテレーション記録（圧縮版）

（2026-04-27〜 ／ 2026-04-28 解決済イテレーションを圧縮）

---

## イテレーション200：掲示板返信表示順を追加

### 背景・問題意識

スポット掲示板のスレッドが長くなると、時系列で読むだけでなく、最新の状況を先に見たい時や参考になった返信を拾いたい時がある。一般的なスレッド閲覧体験として、返信の表示順を切り替えられるようにした。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- 返信一覧に `古い順` / `新着順` / `参考順` の表示順切り替えを追加した。
- 返信番号は元スレッド内の通し番号のまま維持し、表示順だけを切り替えるようにした。
- 検索結果ナビは現在の表示順に合わせて前後移動するようにした。
- 未読区切りは時系列の `古い順` 表示時だけ出すようにした。
- `最新へ` は現在の表示順に関係なく最新返信へ移動するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に返信表示順の表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板返信表示順を追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- スレッド内検索
- 未読区切りと最新返信ジャンプ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter200] add board reply sort modes" --non-interactive`
- Preview OTA: Update group `a291a04d-5762-47a2-83b7-aa9961d2f437` / iOS update `019e7566-28b3-74d8-9f53-763ed2410718`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 返信番号は表示順に依存させず、引用・検索・番号検索の文脈が崩れないようにした。
- ✅ 未読区切りは時系列表示に限定し、並び替え後に誤解を生まないようにした。
- ✅ 検索結果ナビは現在の表示順に合わせて移動するため、見えている順番と操作が一致する。

---

## イテレーション199：掲示板画像一覧を追加

### 背景・問題意識

スポット掲示板では、列状況・現地案内・落とし物などの画像が返信内に散らばりやすい。長いスレッドでも画像だけをまとめて確認できるよう、スレッド内の添付画像を集約する画像一覧を追加した。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド本文と削除されていない返信の添付画像を `mediaAttachments` として集約するようにした。
- スレッド詳細のアクション列に `画像 N` ボタンを追加した。
- 画像一覧モーダルを追加し、画像、投稿元、本文プレビュー、投稿時刻を確認できるようにした。
- 画像一覧から画像プレビューを開けるようにし、`本文へ` / `返信へ` で該当位置へ移動できるようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に画像一覧の表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板画像一覧を追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- スレッド内添付画像の閲覧体験

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter199] add board media gallery" --non-interactive`
- Preview OTA: Update group `700819f9-3b37-4527-88c4-235caaf27287` / iOS update `019e7562-0e67-74be-807b-f97bdfab408a`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の添付画像データから表示用リストを派生し、DB変更なしで実装した。
- ✅ 削除済み返信の画像は一覧に含めず、現在見えているスレッド内容と整合させた。
- ✅ 画像一覧から本文・返信位置へ戻れるようにして、単なる閲覧だけでなく文脈確認までつなげた。

---

## イテレーション198：掲示板検索結果ナビを追加

### 背景・問題意識

スレッド内検索で複数の返信がヒットした時、一覧を手で探すだけでは長いスレッドで使いにくい。一般的な検索体験として、検索結果の前後へ移動できるナビゲーションを追加した。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド内検索中、検索結果の現在位置と総件数を `1 / 3` のように表示するようにした。
- `前へ` / `次へ` ボタンで検索結果の返信位置へスクロールできるようにした。
- 検索語変更時は検索結果カーソルを先頭に戻し、結果件数が変わった時も範囲外カーソルにならないようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に検索結果ナビの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板検索結果ナビを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- スレッド内検索

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter198] add board search result navigation" --non-interactive`
- Preview OTA: Update group `c1f4a44a-cb0e-42ea-85aa-81f1e04a9cde` / iOS update `019e755b-6b8e-79e7-9467-36e240e9c553`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の返信位置記録を使い回し、検索結果の表示移動だけを追加した。
- ✅ 検索語・検索結果件数が変わってもカーソルが破綻しないようにした。
- ✅ スレッド/返信状態は変更せず、表示操作として実装した。

---

## イテレーション197：掲示板検索語ハイライトを追加

### 背景・問題意識

スレッド内検索で返信を絞り込めても、本文や引用内のどの語に反応したのかが分かりにくい。一般的なスレッド検索の体験として、検索語に一致した箇所をハイライト表示するようにした。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド内検索語を正規化した `replySearchQuery` として共有し、検索結果表示・未読区切り判定・ハイライトで使い回すようにした。
- 返信本文、引用本文、引用者名、返信者名に検索語ハイライトを表示する `HighlightedText` を追加した。
- 返信番号が検索語に一致した場合、返信番号の色を強調するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に検索語ハイライトの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板検索語ハイライトを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- スレッド内検索

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter197] highlight board search terms" --non-interactive`
- Preview OTA: Update group `81140fba-f2d9-487a-8fd9-cddc36a89cef` / iOS update `019e7558-19f9-7b89-8cf7-8ef61494002a`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 検索条件の表示補助だけを追加し、返信・スレッド状態は変更していない。
- ✅ 自分の返信バブル上でも読めるよう、濃色バブル用のハイライト色を分けた。
- ✅ 検索語がない時は通常の `Text` 表示へ戻し、不要な分割描画を避けた。

---

## イテレーション196：掲示板返信番号検索を追加

### 背景・問題意識

返信番号を表示しても、番号で直接探せなければ長いスレッドでは活用しにくい。スクショや会話で `#12` のように参照された時にすぐ該当返信へ近づけるよう、スレッド内検索に返信番号を含めた。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド内検索の対象に返信番号 `#1` / `#2` ... を追加した。
- 検索中の返信件数表示を `検索結果/全件` の形式にした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に返信番号検索の表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板返信番号検索を追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- スレッド内検索

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter196] search board replies by number" --non-interactive`
- Preview OTA: Update group `34a32228-3073-4696-8fc0-b27282862af7` / iOS update `019e7553-3475-7a1b-93cb-b1dd6ae67072`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 返信番号を既存検索インデックスに追加するだけに留め、DBや返信状態は変更していない。
- ✅ 検索中はヒット件数と全件数を同時に表示し、絞り込み状態が分かるようにした。

---

## イテレーション195：掲示板引用元ジャンプを追加

### 背景・問題意識

引用返信が増えると、引用元の文脈まで戻って確認したくなる。一般的なスレッド機能として、引用プレビューをタップした時に引用元の返信へ移動できるようにした。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- 返信ごとの画面内位置を保持し、引用プレビューから元返信へスクロールできるようにした。
- スレッド内検索中に引用元へ移動する場合は、検索条件を解除してから引用元へ移動するようにした。
- 引用元が見つからない場合は、理由が分かるアラートを表示するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に引用元ジャンプの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板引用元ジャンプを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 引用返信の読み返し体験

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter195] jump to quoted board reply" --non-interactive`
- Preview OTA: Update group `2c972e9f-9c45-4370-989b-8c112db8a85f` / iOS update `019e7550-406b-7cd9-a809-7570774df2c2`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 引用スナップショットはそのまま保持し、表示上の移動だけを追加した。
- ✅ 検索中でも引用元に戻れるよう、検索条件を解除してからスクロールする設計にした。
- ✅ 引用元が削除・取得外などで見つからない時は、無反応にならないよう案内を出す。

---

## イテレーション194：掲示板返信番号と作成者バッジを追加

### 背景・問題意識

掲示板スレッドでは、返信が増えた時に「何番の返信か」「スレッド作成者の発言か」を追えることが重要になる。一般的なスレッドUIとして、返信ごとの通し番号と作成者バッジを追加した。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- 返信一覧に、スレッド内の通し番号 `#1` / `#2` ... を表示するようにした。
- スレッド作成者による返信には `作成者` バッジを表示するようにした。
- 検索で絞り込んだ場合も、番号は元スレッド内の通し番号を維持するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に返信番号・作成者バッジの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板返信番号と掲示板作成者バッジを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 返信一覧の読み返しUI・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter194] show board reply numbers" --non-interactive`
- Preview OTA: Update group `a0df9987-8b4a-4dbb-8703-01660c53a1b7` / iOS update `019e754d-4fcb-7122-8876-e6e52a9e3317`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 返信状態は変更せず、既存の返信配列から表示番号を派生した。
- ✅ 検索結果でも元スレッドの番号を保ち、会話参照がずれないようにした。
- ✅ 作成者バッジは `thread.authorId` と返信者IDの比較だけで判定し、追加DBなしで実装した。

---

## イテレーション193：掲示板参加者別返信フィルタを追加

### 背景・問題意識

スポット掲示板のスレッドが伸びると、特定の参加者の発言だけを追いたい場面が出る。参加者一覧を確認するだけでなく、そこから返信検索へつなげることで、一般的なスレッドの読み返し体験に近づけた。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド内検索対象に返信者の handle を追加した。
- 参加者一覧の返信している参加者をタップすると、その参加者名または handle で返信を絞り込むようにした。
- 参加者一覧に `返信を見る` / `返信なし` の補助表示を追加した。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に参加者別返信フィルタの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板参加者別返信フィルタを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- スレッド内検索・参加者一覧

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter193] filter board replies by participant" --non-interactive`
- Preview OTA: Update group `72f0be16-821d-4b33-a8b6-75414cf32962` / iOS update `019e7548-fba7-71bb-8fce-869fe589c3c2`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存のスレッド内検索を使い回し、追加DBなしで参加者別の絞り込みを実現した。
- ✅ 返信がない作成者はタップ不可にし、空検索へ誘導しないようにした。
- ✅ 検索条件の変更だけなので、スレッド/返信状態は変更しない。

---

## イテレーション192：掲示板参加者一覧を追加

### 背景・問題意識

スポット掲示板の返信が増えると、誰がこのスレッドに参加しているのかを一目で確認できない。一般的なスレッド機能として、スレッド作成者と可視返信者をまとめた参加者一覧を追加した。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細のアクション列に `参加者` ボタンを追加した。
- スレッド作成者と削除されていない返信の投稿者を集約し、参加者一覧モーダルで表示するようにした。
- 参加者ごとに、作成者/自分のバッジ、返信数、handle、エリア、最終参加時刻を表示するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に参加者一覧の表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板参加者一覧を追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 掲示板の参加状況確認UI・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter192] add board participants list" --non-interactive`
- Preview OTA: Update group `3bc7cc61-14c6-4b8c-96bc-9cbaf9e14f8a` / iOS update `019e7545-c200-715c-add4-8bb7ff8c29b9`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ DB変更なしで、既存のスレッド/返信データから参加者を集約した。
- ✅ 削除済み返信は参加者集計から外し、現在見えている会話参加者だけを表示するようにした。
- ✅ スレッド状態は変えず、表示操作として参加者一覧を追加した。

---

## イテレーション191：掲示板固定スレッド表示を追加

### 背景・問題意識

スポット掲示板のデータモデルには固定表示用の `isPinned` があり、一覧の並び順にも反映されているが、画面上では固定スレッドであることが分からなかった。一般的なスレッド機能として、固定スレッドを明示するバッジを追加した。

### 変更内容

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧のスレッドカードで `thread.isPinned` が true の場合に `固定` バッジを表示するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細のヘッダー下バッジ列で `thread.isPinned` が true の場合に `固定` バッジを表示するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に固定スレッド表示のルールを追記した。

#### `notes/10_glossary.md`
- 掲示板固定スレッドを追加した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter191] show pinned board threads" --non-interactive`
- Preview OTA: Update group `8d906d11-e98a-410a-9136-58ac4b6a8665` / iOS update `019e753f-a8d5-7a48-b2e9-3dae8b756db9`

### 関連ファイル

- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の `isPinned` と状態バッジを使い回し、DB変更なしで表示だけを補完した。
- ✅ 一覧と詳細の両方で固定状態が分かるようにした。

---

## イテレーション190：掲示板詳細に未読区切りを追加

### 背景・問題意識

スポット掲示板の返信が増えると、前回読んだ位置からどこが新しい返信なのか分かりにくくなる。一般的なスレッド機能として、詳細画面に「ここから未読」の区切りを追加した。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細を開いた時、既読更新前の `readAt` を `previousReadAt` として保持するようにした。
- `previousReadAt` より新しい最初の返信の上に `ここから未読` 区切りを表示するようにした。
- スレッド内検索中は、検索結果の位置と混ざらないよう未読区切りを非表示にした。
- 自分が返信を送信した直後は、その返信を未読扱いにしないよう既読基準時刻を更新するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に未読区切りの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板未読区切りを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 掲示板の既読表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter190] add board unread separator" --non-interactive`
- Preview OTA: Update group `f3d51032-70d8-402d-abee-cae94520f3d1` / iOS update `019e753b-a508-7c74-add4-00582b14875f`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の `readAt` / 返信 `createdAt` 判定だけで実装し、DB変更なしで済ませた。
- ✅ 検索中と自分の送信直後に不自然な未読表示が出ないようにした。

---

## イテレーション189：掲示板詳細に最新返信ジャンプを追加

### 背景・問題意識

スポット掲示板の返信数が増えると、スレッド本文や古い返信から最新の会話位置へ戻る操作が必要になる。一般的なスレッド機能として、詳細画面で最新返信へすぐ移動できる導線を追加した。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細の `ScrollView` に ref を持たせ、`scrollToEnd()` で最新位置へ移動できるようにした。
- 返信ヘッダー右側に `最新へ` ボタンを追加した。
- 自分が返信を送信した直後、自動で最新返信位置へスクロールするようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に最新返信ジャンプの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板最新返信ジャンプを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter189] add board latest reply jump" --non-interactive`
- Preview OTA: Update group `f6c08039-75a2-438a-b6bb-1f7a1b163fb5` / iOS update `019e7536-acb8-7539-af77-8268ea3d1907`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 新しいネイティブ依存を追加せず、既存のScrollViewで実装した。
- ✅ 返信数が0件の時はボタンを表示しないようにした。

---

## イテレーション188：掲示板に参加中スレッド表示を追加

### 背景・問題意識

スポット掲示板では、返信したスレッドや自分が立てたスレッドに後から戻る必要がある。通知ONだけを参加扱いにすると、読むために通知を付けたスレッドと実際に会話へ参加したスレッドが混ざるため、一般的なスレッド機能として「参加中」表示を別概念で追加した。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardThreadSort` に `participated` を追加し、掲示板一覧で参加中スレッドだけを絞り込めるようにした。
- `MeguriBoardThread` に `participated` を追加した。
- スレッド作成時・返信時はローカル状態にも `participated=true` を保存するようにした。
- リモート取得時は `viewer_participated` を読み取り、作成者本人も参加中として扱うようにした。

#### `mobile/app/meguri-board.tsx`
- ソートレールに `参加中` を追加した。
- 参加中表示のセクションタイトルと空表示文言を追加した。

#### `supabase/migrations/20260530235900_add_meguri_board_thread_participation.sql`
- `list_meguri_board_threads_for_viewer()` の返却値に `viewer_participated` を追加した。
- 閲覧者がスレッド作成者、または可視返信を書いている場合に参加中として返すようにした。

#### `notes/05_data_model.md`
- 掲示板の参加中判定を追記した。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に参加中表示のルールを追記した。

#### `notes/10_glossary.md`
- 掲示板参加中表示を追加した。

#### `notes/13_api_spec.md`
- スポット掲示板一覧レスポンスに `viewer_participated` を追記した。

### 影響範囲

- iOS版 スポット掲示板一覧
- Supabase RPC `list_meguri_board_threads_for_viewer()`
- 掲示板の表示ルール・データモデル・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter188] add board participated filter" --non-interactive`
- Preview OTA: Update group `aa5b7816-08eb-4499-a4f1-581aa96d9f90` / iOS update `019e7532-7844-752f-bd1a-d1139ecadd3c`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `supabase/migrations/20260530235900_add_meguri_board_thread_participation.sql`
- `notes/05_data_model.md`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 通知購読とは別に参加中を定義し、表示の意味が混ざらないようにした。
- ✅ Migration適用前でも、端末内で作成・返信したスレッドはローカル状態から参加中へ出せるようにした。

---

## イテレーション187：掲示板未読一括既読を追加

### 背景・問題意識

スポット掲示板に未読表示を追加したことで、返信が多い現場では「今は全部確認済みにしたい」という操作が必要になる。一般的なスレッド機能として、未読表示に出ているスレッドをまとめて既読扱いにできる導線を追加した。

### 変更内容

#### `mobile/app/meguri-board.tsx`
- `未読` 表示中かつ未読スレッドがある時だけ、「表示中を既読にする」カードを表示するようにした。
- 表示中の未読スレッドIDを抽出し、既存の `markMeguriBoardThreadRead` をまとめて実行するようにした。
- 既読化は先にローカル表示へ反映し、処理中表示を出すようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に未読一括既読のルールを追記した。

#### `notes/10_glossary.md`
- 掲示板未読一括既読を追加した。

### 影響範囲

- iOS版 スポット掲示板一覧
- 掲示板の既読管理・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter187] add board bulk mark read" --non-interactive`
- Preview OTA: Update group `853f9ff5-885d-4ad7-b9da-eec8dbdfc134` / iOS update `019e752a-90f8-7867-996e-8174759038c8`

### 関連ファイル

- `mobile/app/meguri-board.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の既読状態管理を使い、DB変更なしで実装した。
- ✅ `未読` 表示中だけに導線を限定し、通常の掲示板閲覧を邪魔しないようにした。

---

## イテレーション186：掲示板に未読スレッド表示を追加

### 背景・問題意識

スポット掲示板では返信が増えるほど、まだ読んでいない更新だけを追いたくなる。未読ドット表示に加えて、一般的なスレッド機能として「未読」だけに絞り込める表示を追加した。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardThreadSort` に `unread` を追加した。
- `未読` 選択時、`readAt` がない、または `readAt < latestActivityAt` のスレッドだけを返すようにした。

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧のソートレールに `未読` を追加した。
- `未読` 選択時のセクションタイトルと空表示を専用文言にした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に未読表示のルールを追記した。

#### `notes/10_glossary.md`
- 掲示板未読表示を追加した。

### 影響範囲

- iOS版 スポット掲示板一覧
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter186] add board unread filter" --non-interactive`
- Preview OTA: Update group `d564c8ff-5edb-4572-b8fb-7865d576e0a1` / iOS update `019e7522-7626-7238-b525-c77de5cfdbce`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の `readAt` / `latestActivityAt` 判定を使い、DB変更なしで実装した。
- ✅ 検索・カテゴリ絞り込みと未読表示が同時に効くようにした。

---

## イテレーション185：掲示板返信共有を追加

### 背景・問題意識

掲示板の返信には列状況や現地メモなど、後から別アプリへ共有したい情報が含まれる。クリップボード機能は未導入ネイティブモジュールが必要になるため、OTAで反映できる範囲として、iOS共有シートから返信本文とスレッドURLを共有できるようにした。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- 返信アクションに「返信を共有」を追加した。
- 共有内容にスレッドタイトル、返信者名、返信本文、スレッドURLを含めるようにした。
- 削除済み返信は共有できないようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に返信共有の表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板返信共有を追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter185] add board reply share" --non-interactive`
- Preview OTA: Update group `08be98fc-b890-4db7-aed5-947869db8881` / iOS update `019e751e-a2f4-79f7-9b95-23c66b295e1c`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 新しいネイティブ依存を追加せず、既存の `Share` API で実装した。
- ✅ 削除済み返信は共有対象から外した。

---

## イテレーション184：掲示板にメンション返信導線を追加

### 背景・問題意識

スポット掲示板には `@handle` メンション通知の仕組みがあるが、ユーザーが手入力する前提だと使われにくい。一般的なスレッド機能として、返信アクションから相手のhandleを本文へ挿入できるようにした。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- 他ユーザーの返信アクションに「メンションして返信」を追加した。
- 選択すると返信入力欄の先頭へ `@handle` を挿入するようにした。
- handle がない場合は表示名から空白を除いた簡易メンションを挿入するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle にメンション返信導線のルールを追記した。

#### `notes/10_glossary.md`
- 掲示板メンション返信を追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter184] add board mention reply" --non-interactive`
- Preview OTA: Update group `e2d6542c-61f7-449e-84f0-4e1fbefb727c` / iOS update `019e751b-3612-7d99-a5c3-6eea381c63cb`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存のメンション通知仕様を活かし、DB/API追加なしで導線だけを足した。
- ✅ 自分の返信・削除済み返信・締め切りスレッドではメンション挿入しないようにした。

---

## イテレーション183：掲示板にプル更新を追加

### 背景・問題意識

スポット掲示板は現地情報や返信が短い間隔で更新されるため、画面を開き直さずに最新状態へ更新できる必要がある。一般的なスレッド機能として、一覧と詳細にiOS標準のプル更新を追加した。

### 変更内容

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧の `ScrollView` に `RefreshControl` を追加した。
- 引っ張って更新した時は全画面ローディングに戻さず、既存表示を維持したまま最新スレッドを再取得するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細の `ScrollView` に `RefreshControl` を追加した。
- 引っ張って更新した時は既存のスレッド本文・返信表示を維持したまま詳細を再取得するようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle にプル更新の表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板プル更新を追加した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter183] add board pull refresh" --non-interactive`
- Preview OTA: Update group `d58afa77-3079-4bf9-865a-d02ed6aef295` / iOS update `019e7518-33b6-7388-b277-5a60f8e123e2`

### 関連ファイル

- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ iOS標準の `RefreshControl` を使い、独自ジェスチャーを増やしていない。
- ✅ 通常読み込みとプル更新の状態を分け、更新時に表示が空白へ戻らないようにした。

---

## イテレーション182：掲示板添付画像プレビューを追加

### 背景・問題意識

スポット掲示板では画像付きのスレッドや返信が増えるため、サムネイルだけでは現地情報を確認しにくい。一般的なスレッド機能として、スレッド詳細内の添付画像をタップして大きく確認できるようにした。

### 変更内容

#### `mobile/app/meguri-board-thread.tsx`
- スレッド本文と返信本文の添付画像をタップ可能にした。
- 画像タップ時に全画面の暗背景プレビューを表示するようにした。
- 画面タップまたは右上の閉じるボタンでプレビューを閉じるようにした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に添付画像プレビューの表示ルールを追記した。

#### `notes/10_glossary.md`
- 掲示板添付画像プレビューを追加した。

### 影響範囲

- iOS版 スポット掲示板詳細
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter182] add board image preview" --non-interactive`
- Preview OTA: Update group `265f2050-cf15-4721-ba3f-976186210d4e` / iOS update `019e7514-d61f-7b02-b340-d2a73841bf0e`

### 関連ファイル

- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 添付画像の保存・取得ロジックには触れず、詳細画面の表示だけに限定した。
- ✅ モーダルは画面タップと閉じるボタンの両方で閉じられる。

---

## イテレーション181：掲示板に自分のスレッド表示を追加

### 背景・問題意識

スポット掲示板でスレッド数が増えると、自分が立てたスレッドへ戻る導線が必要になる。一般的なスレッド機能として、保存・通知中だけでなく「自分のスレッド」だけを一覧で確認できるようにした。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardThreadSort` に `mine` を追加した。
- 並び替え/絞り込み候補に `自分` を追加し、`mine` 選択時は `thread.mine` のスレッドだけを返すようにした。

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧のソートレールに `自分` を追加した。
- `自分` 選択時のセクションタイトルを「自分のスレッド」にした。
- 自分のスレッドがない時の空表示を専用文言にした。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に `自分` 表示のルールを追記した。

#### `notes/10_glossary.md`
- 自分のスレッドを追加した。

### 影響範囲

- iOS版 スポット掲示板一覧
- 掲示板の表示ルール・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter181] add my board threads" --non-interactive`
- Preview OTA: Update group `4e6448c3-f5dc-41dc-9055-31fd9ad7e6f6` / iOS update `019e7510-d164-7014-bee3-fe1beafb710b`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ DB変更なしで、既存の `thread.mine` 判定だけを使っている。
- ✅ 保存/通知/人気など既存の並び替え挙動を壊さず、`mine` 選択時だけ絞り込むようにした。

---

## イテレーション180：掲示板下書き自動保存を追加

### 背景・問題意識

スポット掲示板は現地で短時間に書き込む用途が多く、スレッド作成中や返信中に画面を閉じると入力内容が失われるのはストレスになる。一般的なスレッド機能として、作成途中のスレッドと返信を端末内に自動保存し、再度開いた時に復元できるようにした。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- スレッド作成下書き `MeguriBoardComposerDraft` と返信下書き `MeguriBoardReplyDraft` を追加した。
- `meguri.board.composerDrafts.v1` / `meguri.board.replyDrafts.v1` に端末内保存する load/save/clear 関数を追加した。
- 下書きは最新40件まで保持し、空になったら自動で削除するようにした。

#### `mobile/app/meguri-board.tsx`
- スレッド作成モーダルを開いた時、同じ掲示板文脈の下書きを復元するようにした。
- タイトル・本文・画像・カテゴリ・公開範囲を入力中に自動保存するようにした。
- 投稿成功後は該当下書きを削除するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド返信欄の本文と添付画像をスレッド単位で自動保存するようにした。
- スレッド詳細を開いた時、未送信の返信下書きを復元するようにした。
- 返信送信後は該当下書きを削除するようにした。

#### `notes/05_data_model.md`
- 掲示板下書きはDBに保存せず、端末内下書きとして扱う方針を追記した。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に下書き自動保存・投稿成功時削除のルールを追記した。

#### `notes/10_glossary.md`
- 掲示板下書きを追加した。

#### `notes/13_api_spec.md`
- 掲示板下書きはAPIを持たない端末内状態として明記した。

### 影響範囲

- iOS版 スポット掲示板一覧のスレッド作成モーダル
- iOS版 スポット掲示板詳細の返信欄
- 掲示板の端末内状態・仕様ドキュメント

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter180] add board drafts" --non-interactive`
- Preview OTA: Update group `638cb56c-36b7-4c6a-99f8-84e1b50f1e3b` / iOS update `019e750c-8069-7aed-a3ae-fa8c7c73d080`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `notes/05_data_model.md`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 新しいDB列やネイティブ依存を追加せず、OTA反映可能なJS実装に収めた。
- ✅ スレッド作成下書きと返信下書きを分け、投稿成功時に自動削除するようにした。
- ✅ 空の下書きは残さず、端末内保存件数も上限を設けた。

---

## イテレーション179：掲示板通報理由を追加

### 背景・問題意識

スポット掲示板の通報が即送信だと、運営側で何を確認すべきか分かりにくい。一般的なスレッド機能として、通報前に理由を選ばせ、スレッド/返信の通報に理由コードを保存できるようにした。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardReportReason` と `MEGURI_BOARD_REPORT_REASONS` を追加した。
- 通報理由の表示ラベル `meguriBoardReportReasonLabel()` を追加した。

#### `mobile/app/meguri-board.tsx`
- スレッド一覧から通報する時、iOS標準ActionSheetで理由を選択してから送信するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細と返信の通報で、同じ理由選択ActionSheetを表示するようにした。

#### `notes/05_data_model.md`
- `meguri_board_reports.reason` の運用理由コードを追記した。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に通報理由選択のビジネスルールを追記した。

#### `notes/10_glossary.md`
- 掲示板通報理由を追加した。

#### `notes/13_api_spec.md`
- 掲示板通報APIの `reason` を具体的な選択肢に更新した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- 掲示板のデータモデル・状態遷移・用語・API仕様

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter179] add board report reasons" --non-interactive`
- Preview OTA: Update group `b0546f3d-8e70-4e5d-b319-bb5dce63942d` / iOS update `019e7503-a4bf-7ff1-950f-aa68087ef1df`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `notes/05_data_model.md`
- `notes/08_design_iterations.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ iOS標準の `ActionSheetIOS` を使い、独自UIを増やしていない。
- ✅ スレッド通報と返信通報で同じ理由セットを使うようにした。
- ✅ DB列追加なしで既存の `meguri_board_reports.reason` を活用した。

---

## イテレーション178：掲示板ユーザーブロックを追加

### 背景・問題意識

一般的なスレッド型掲示板では、通報やスレッド非表示だけでは足りず、ユーザー単位で相手の投稿を見ない/通知を受けない制御が必要になる。スポット掲示板でも、合わない相手のスレッド・返信・通知をまとめて抑制できるようにした。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- 掲示板用の `blockMeguriBoardUser()` を追加し、既存の `groom_user_blocks` にブロック関係を保存するようにした。
- ローカル即時反映用に `meguri.board.userBlocks.v1` を追加し、ブロックした相手のスレッド/返信を端末上でも除外するようにした。
- スレッド一覧・詳細・返信読み込み時にローカルブロック状態を反映するようにした。

#### `mobile/app/meguri-board.tsx`
- スレッド一覧カードのアクションシートに「このユーザーをブロック」を追加した。
- ブロック後、対象ユーザーのスレッドを一覧から即時に消すようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細のアクションシートに、スレッド作成者をブロックする導線を追加した。
- 返信のアクションシートに、返信者をブロックする導線を追加した。
- ブロック後、対象ユーザーの返信を詳細画面から即時に消すようにした。

#### `supabase/migrations/20260530235000_add_meguri_board_user_blocks.sql`
- `can_view_meguri_board_thread()` / `can_view_meguri_board_thread_with_context()` にブロック判定を追加した。
- スレッド一覧RPC・返信一覧RPC・返信作成RPCで `groom_user_blocks` を参照するようにした。
- 掲示板返信通知・掲示板メンション通知で、返信者と通知先がブロック関係にある場合は通知を作成しないようにした。

#### `notes/05_data_model.md`
- `groom_user_blocks` をスポット掲示板にも適用する方針を追記した。

#### `notes/09_state_machines.md`
- Meguri Board Lifecycle に掲示板ユーザーブロックのビジネスルールを追記した。

#### `notes/10_glossary.md`
- 掲示板ユーザーブロックを追加した。

#### `notes/13_api_spec.md`
- ブロックAPIのスポット掲示板での副作用と、掲示板専用導線を追記した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- Supabase スポット掲示板表示判定/RPC/通知trigger
- 掲示板のデータモデル・状態遷移・用語・API仕様

### 確認方法

- `npm --prefix mobile run typecheck`
- `supabase db push --dry-run`
- `supabase db push`（`20260530235000_add_meguri_board_user_blocks.sql` を remote DB に適用）
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter178] add board user blocks" --non-interactive`
- Preview OTA: Update group `cb96e640-6354-4c0b-b215-fbdcda829f9e` / iOS update `019e74fe-12dd-7beb-9112-0ef84efeb345`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `supabase/migrations/20260530235000_add_meguri_board_user_blocks.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ iOS標準の `ActionSheetIOS` / `Alert` を使い、独自のモーダル操作を増やしていない。
- ✅ ブロックは一覧・詳細・返信・通知まで一貫して抑制する設計にした。
- ✅ 既存の `groom_user_blocks` を共用し、ユーザー単位ブロックのテーブルを重複させていない。

---

## イテレーション177：掲示板スレッド共有を追加

### 背景・問題意識

スポット掲示板で有用な現地情報が出た時、友達や同行者へスレッドを渡せる導線が必要。一般的なスレッド機能として、iOS標準の共有シートからスレッドタイトル・本文・アプリ内リンクを共有できるようにした。

### 変更内容

#### `mobile/app/meguri-board.tsx`
- スレッド一覧カードのアクションシートに「共有する」を追加した。
- 共有時は現在の `viewMode` と掲示板コンテキストを含めた `megrum://` / `megrum-preview://` deep link を生成するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細のアクションシートに「共有する」を追加した。
- iOS標準の `Share.share` で、スレッドタイトル・本文・deep link を共有するようにした。

#### `notes/10_glossary.md`
- スレッド共有を追加した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- 掲示板の用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter177] add board sharing" --non-interactive`
- Preview OTA: Update group `7aab9b26-db4c-480e-a549-49fc26a37219` / iOS update `019e74f3-e0f7-7d6c-97f2-054645f98499`

### 関連ファイル

- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `notes/08_design_iterations.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ iOS標準の共有シートを使い、独自共有UIを増やしていない。
- ✅ Preview/本番で scheme が切り替わるようにした。
- ✅ スレッドの閲覧範囲判定は既存詳細画面側に委ね、共有自体で状態を変えない。

---

## イテレーション176：掲示板画像添付を追加

### 背景・問題意識

一般的なスレッド型掲示板では、列状況・会場の案内・落とし物などをテキストだけで説明するより、写真を添える方が伝わりやすい。スポット掲示板の用途にも合うため、スレッド作成と返信の両方で画像を最大4枚添付できるようにした。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardThread` / `MeguriBoardReply` に `imageUris` を追加した。
- Supabase Storage `meguri-board-media` へ画像をアップロードし、DBには private Storage path を保存するようにした。
- スレッド/返信の取得時は、閲覧可能なデータに限って署名URLへ変換して表示するようにした。

#### `mobile/app/meguri-board.tsx`
- スレッド作成モーダルで写真ライブラリから最大4枚の画像を添付できるようにした。
- スレッド一覧カードに添付画像のサムネイルを表示するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド本文と返信に添付画像のサムネイルを表示するようにした。
- 返信入力欄に画像添付ボタンを追加し、画像だけの返信は「画像を共有しました」として送信できるようにした。

#### `supabase/migrations/20260530231500_add_meguri_board_image_attachments.sql`
- private Storage bucket `meguri-board-media` を追加した。
- `meguri_board_threads.image_paths` / `meguri_board_replies.image_paths` を追加した。
- スレッド一覧RPC、返信一覧RPC、返信作成RPCで `image_paths` を扱うように更新した。

#### `notes/05_data_model.md`
- スポット掲示板の画像添付と Storage 方針を追記した。

#### `notes/09_state_machines.md`
- 掲示板画像添付のビジネスルールを追記した。

#### `notes/10_glossary.md`
- 掲示板画像添付を追加した。

#### `notes/13_api_spec.md`
- 掲示板の作成/返信レスポンスと画像添付仕様を追記した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- Supabase スポット掲示板テーブル/RPC/Storage
- 掲示板のデータモデル・状態遷移・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `supabase db push --dry-run`
- `supabase db push`（`20260530231500_add_meguri_board_image_attachments.sql` を remote DB に適用）
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter176] add board image attachments" --non-interactive`
- Preview OTA: Update group `2e63b068-68de-4d12-b80d-34a0be157cfb` / iOS update `019e74ee-6b5e-75c1-b4ce-4a0116be2c8f`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `supabase/migrations/20260530231500_add_meguri_board_image_attachments.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ スレッド作成・返信の両方で最大4枚の画像を扱う実装にした。
- ✅ 画像は private Storage path として保存し、アプリ表示時に署名URL化する。
- ✅ Preview/local fallback でも添付画像表示が壊れないよう `imageUris` をローカル保持する。
- ✅ データモデル・状態遷移・用語・API仕様を更新。

---

## イテレーション175：掲示板メンション通知を追加

### 背景・問題意識

スポット掲示板で返信が増えると、特定のユーザーに確認してほしい情報や、現地で詳しそうな人への呼びかけが流れやすい。一般的なスレッド機能として、返信本文の `@handle` を検出し、対象ユーザーへ専用通知を届ける仕組みを追加した。

### 変更内容

#### `mobile/app/(tabs)/notifications.tsx`
- 通知種別 `meguri_board_mention` を追加した。
- Preview通知に掲示板メンション通知のサンプルを追加した。

#### `supabase/migrations/20260530223000_add_meguri_board_mentions.sql`
- `notifications.kind='meguri_board_mention'` を追加した。
- 返信本文から `@handle` を抽出する `meguri_board_mentioned_user_ids` を追加した。
- 返信作成時、本人以外かつ対象スレッドを閲覧できるメンション先へ通知を作成する trigger を追加した。
- メンション先には通常の購読返信通知を重複送信しないよう、購読通知 trigger を更新した。

#### `notes/05_data_model.md`
- 掲示板メンション通知のデータ方針を追記した。

#### `notes/09_state_machines.md`
- `@handle` メンションと通知重複回避のビジネスルールを追記した。

#### `notes/10_glossary.md`
- 掲示板メンションを追加した。

#### `notes/13_api_spec.md`
- 掲示板返信作成の副作用としてメンション通知を追記した。

### 影響範囲

- iOS版 通知一覧
- Supabase スポット掲示板返信 trigger
- Supabase 通知 kind
- 掲示板のデータモデル・状態遷移・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `supabase db push --dry-run`
- `supabase db push`（`20260530223000_add_meguri_board_mentions.sql` を remote DB に適用）
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter175] add board mentions" --non-interactive`
- Preview OTA: Update group `ab94b355-9dd5-46ba-8bfc-5c21cf79f5fb` / iOS update `019e74dd-ff35-7a42-8dec-b51ba7bc4d80`

### 関連ファイル

- `mobile/app/(tabs)/notifications.tsx`
- `supabase/migrations/20260530223000_add_meguri_board_mentions.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ `@handle` から対象ユーザーを抽出するDB関数を追加。
- ✅ メンション通知を購読返信通知と重複させないように調整。
- ✅ 通知一覧で `meguri_board_mention` を扱える。
- ✅ データモデル・状態遷移・用語・API仕様を更新。

---

## イテレーション174：掲示板スレッド購読と通知を追加

### 背景・問題意識

スポット掲示板を日常的に使うには、気になるスレッドを見逃さない仕組みが必要。一般的なスレッド機能として、作成・返信したスレッドの自動購読、手動の通知ON/OFF、返信通知からスレッドへ戻る導線を追加した。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardThread` に `subscribed` を追加した。
- スレッド作成者と返信者をローカル状態でも自動購読ONにした。
- `setMeguriBoardThreadSubscribed` を追加し、Supabase RPC とローカル状態の両方へ同期するようにした。
- 並び替えに「通知」を追加し、購読中スレッドを先に見られるようにした。

#### `mobile/app/meguri-board.tsx`
- スレッド一覧カードに通知ON/OFFのベル操作を追加した。
- アクションシートにも「通知を受け取る / 通知を止める」を追加した。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細のアクションピルとアクションシートに通知ON/OFFを追加した。
- 返信送信後はスレッドの購読状態をONとして表示するようにした。

#### `mobile/app/(tabs)/notifications.tsx`
- 通知種別 `meguri_board_reply` を追加した。
- 通知タップで `/meguri-board-thread` を開けるようにした。
- Preview通知にも掲示板返信通知のサンプルを追加した。

#### `supabase/migrations/20260530211500_add_meguri_board_thread_subscriptions.sql`
- `meguri_board_thread_subscriptions` を追加した。
- `notifications` に `meguri_board_thread_id` / `meguri_board_reply_id` と kind `meguri_board_reply` を追加した。
- スレッド作成者の自動購読 trigger、返信者の自動購読と購読者向け通知作成 trigger を追加した。
- スレッド一覧RPCに `viewer_subscribed` を追加した。

#### `notes/05_data_model.md`
- 掲示板スレッド購読テーブルと掲示板返信通知を追記した。

#### `notes/09_state_machines.md`
- スレッド購読ON/OFFと返信通知のビジネスルールを追記した。

#### `notes/10_glossary.md`
- スレッド購読、掲示板返信通知を追加した。

#### `notes/13_api_spec.md`
- 掲示板一覧レスポンス、返信作成の副作用、スレッド購読APIを追記した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- iOS版 通知一覧
- Supabase スポット掲示板/通知テーブル・RPC・trigger
- 掲示板のデータモデル・状態遷移・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `supabase db push --dry-run`
- `supabase db push`（`20260530211500_add_meguri_board_thread_subscriptions.sql` を remote DB に適用）
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter174] add board thread subscriptions" --non-interactive`
- Preview OTA: Update group `1701147b-6bd7-499a-a469-cca1217e115e` / iOS update `019e74d7-6d29-7f8b-a7b9-3b16e1276fe0`

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `mobile/app/(tabs)/notifications.tsx`
- `supabase/migrations/20260530211500_add_meguri_board_thread_subscriptions.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ スレッド一覧/詳細の両方で通知ON/OFFを操作できる。
- ✅ スレッド作成者・返信者は自動で購読ONになる。
- ✅ 購読者への返信通知と通知一覧からの復帰導線を追加。
- ✅ データモデル・状態遷移・用語・API仕様を更新。

---

## イテレーション173：引用返信とスレッド内検索を追加

### 背景・問題意識

スポット掲示板を現地の情報共有や雑談に使う場合、返信が増えるほど「どの発言への返事か」と「過去にその話が出ているか」が追いづらくなる。一般的なスレッド機能として、引用返信とスレッド内検索を追加した。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- `MeguriBoardReply` に `parentReplyId` / `quotedAuthorName` / `quotedBody` を追加した。
- 返信作成時に引用元のID・表示名・本文スナップショットを保存できるようにした。
- remote select / RPC / local fallback / preview data に引用返信フィールドを反映した。

#### `mobile/app/meguri-board-thread.tsx`
- 返信アクションに「引用して返信」を追加した。
- 返信入力欄の上に引用プレビューと解除ボタンを表示するようにした。
- 返信バブル内に引用元プレビューを表示するようにした。
- 返信本文・引用本文・返信者名を対象にしたスレッド内検索を追加した。

#### `supabase/migrations/20260530204000_add_meguri_board_reply_quotes.sql`
- `meguri_board_replies` に `parent_reply_id` / `quote_author_name` / `quote_body` を追加した。
- 返信一覧RPCと返信追加RPCを引用返信フィールド込みに更新した。

#### `notes/05_data_model.md`
- 掲示板返信の引用フィールドを追記した。

#### `notes/09_state_machines.md`
- 引用返信とスレッド内検索のルールを追記した。

#### `notes/10_glossary.md`
- 引用返信、スレッド内検索を追加した。

#### `notes/13_api_spec.md`
- 掲示板返信作成の引用フィールドを追記した。

### 影響範囲

- iOS版 スポット掲示板詳細
- Supabase スポット掲示板返信RPC
- 掲示板のデータモデル・状態遷移・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/src/lib/meguriBoard.ts mobile/app/meguri-board-thread.tsx supabase/migrations/20260530204000_add_meguri_board_reply_quotes.sql notes/05_data_model.md notes/09_state_machines.md notes/10_glossary.md notes/13_api_spec.md notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter173] add quoted replies and thread search" --non-interactive`
- Preview OTA: Update group `c1068115-0cd4-4cdd-91a9-3810e362fbec` / iOS update `019e74ca-5255-7f6c-88ab-99abee8e227b`
- `supabase db push`（`20260530204000_add_meguri_board_reply_quotes.sql` を remote DB に適用）

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board-thread.tsx`
- `supabase/migrations/20260530204000_add_meguri_board_reply_quotes.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 返信アクションに引用返信を追加。
- ✅ 返信入力欄と返信バブルに引用プレビューを追加。
- ✅ スレッド内検索を返信本文・引用本文・返信者名に対応。
- ✅ データモデル・状態遷移・用語・API仕様を更新。

---

## イテレーション172：掲示板の編集と締め切りを追加

### 背景・問題意識

掲示板を一般的なスレッド機能に近づけるには、投稿後の修正、返信停止、削除済み表示といった運用操作が必要。iter171 で保存・検索・通報などの基本操作を入れたため、次の段階として作成者による管理操作を追加した。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- スレッド/返信に `updatedAt`、返信に `status` / `deleted` を追加した。
- 自分のスレッド編集、締め切り/再開/削除、返信編集/削除の操作関数を追加した。
- `locked` スレッドは一覧・詳細で閲覧できるが、返信追加はできないようにした。

#### `mobile/app/meguri-board.tsx`
- 一覧カードに締め切りバッジを追加した。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド作成者向けに編集、締め切り/再開、削除をアクションメニューへ追加した。
- 自分の返信に編集・削除を追加した。
- 締め切り中のスレッドでは返信入力欄を締め切り表示に置き換えた。
- 編集済み表示と削除済み返信のプレースホルダ表示を追加した。

#### `supabase/migrations/20260530193000_add_meguri_board_edit_controls.sql`
- `meguri_board_replies` に `status` / `updated_at` / `deleted_at` を追加した。
- `locked` スレッドを閲覧可能・返信不可にするよう RPC を更新した。
- `update_meguri_board_thread` / `set_meguri_board_thread_status` / `update_meguri_board_reply` / `delete_meguri_board_reply` を追加した。

#### `notes/05_data_model.md`
- 掲示板返信の編集・削除済み表示、スレッド締め切り/削除のデータ方針を追記した。

#### `notes/09_state_machines.md`
- スレッド作成者による締め切り/再開/削除と返信編集/削除のルールを追記した。

#### `notes/10_glossary.md`
- スレッド締め切り、掲示板ソフト削除を追加した。

#### `notes/13_api_spec.md`
- 掲示板のスレッド編集、ステータス変更、返信編集、返信削除APIを追記した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- Supabase スポット掲示板関連テーブル/RPC
- 掲示板のデータモデル・状態遷移・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/src/lib/meguriBoard.ts mobile/app/meguri-board.tsx mobile/app/meguri-board-thread.tsx supabase/migrations/20260530193000_add_meguri_board_edit_controls.sql notes/05_data_model.md notes/09_state_machines.md notes/10_glossary.md notes/13_api_spec.md notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter172] add meguri board edit controls" --non-interactive`
- Preview OTA: Update group `f22890b6-763b-4705-868c-23537626f904` / iOS update `019e74c0-9e4b-73eb-a455-437eae549698`
- `supabase db push`（`20260530193000_add_meguri_board_edit_controls.sql` を remote DB に適用）

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `supabase/migrations/20260530193000_add_meguri_board_edit_controls.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 自分のスレッド編集・締め切り/再開・削除を追加。
- ✅ 自分の返信編集・削除済み表示を追加。
- ✅ `locked` スレッドは閲覧可能、返信不可に調整。
- ✅ 状態遷移・用語・データモデル・API仕様を更新。

---

## イテレーション171：スポット掲示板の基本スレッド機能を拡充

### 背景・問題意識

オーナーから、めぐり機能、とくに掲示板を継続的に拡充し、一般的なスレッドに備わっている機能を載せていきたいという依頼があった。既存のスポット掲示板は一覧・作成・返信の土台はあるが、カテゴリ、検索、並び替え、保存、リアクション、既読、非表示、通報といった日常利用に必要な操作が不足していた。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- スレッドカテゴリ（質問/情報/雑談/交換/落とし物）を追加した。
- スレッド検索、カテゴリ絞り込み、更新/新着/人気/保存の並び替え関数を追加した。
- スレッド保存、スレッド/返信の「参考になった」、既読、非表示、通報のローカル状態管理を追加した。
- Supabase RPC があれば各状態を同期し、migration 未適用時もローカル状態で操作できるようにした。

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧に検索欄、カテゴリチップ、並び替えボタンを追加した。
- スレッドカードにカテゴリ、未読ドット、保存、参考になった、アクションメニューを追加した。
- スレッド作成モーダルにカテゴリ選択を追加した。
- スレッドの非表示・通報をアクションシートから実行できるようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細にカテゴリ、保存、参考になった、アクションメニューを追加した。
- 詳細表示時に既読を記録するようにした。
- 返信ごとに参考になったと通報アクションを追加した。

#### `supabase/migrations/20260530174000_expand_meguri_board_threads.sql`
- `meguri_board_threads` に `category` / `status` / `is_pinned` / `view_count` / `reaction_count` / `bookmark_count` を追加した。
- `meguri_board_replies` に `reaction_count` を追加した。
- 保存、リアクション、既読、非表示、通報用テーブルと同期 trigger / RPC を追加した。
- 一覧・返信RPCを viewer 状態込みで返すように拡張した。

#### `notes/05_data_model.md`
- 掲示板の追加カラムと新テーブルを追記した。

#### `notes/09_state_machines.md`
- 掲示板の `locked` 状態と、カテゴリ/検索/保存/参考になった/既読/非表示/通報のルールを追記した。

#### `notes/10_glossary.md`
- スポット掲示板、スレッドカテゴリ、保存、参考になった、掲示板既読、ユーザー単位の非表示、掲示板通報を追加した。

#### `notes/13_api_spec.md`
- 掲示板一覧/作成/詳細/返信のレスポンスを拡張し、既読・保存・リアクション・非表示・通報エンドポイントを追記した。

### 影響範囲

- iOS版 スポット掲示板一覧
- iOS版 スポット掲示板詳細
- Supabase スポット掲示板関連テーブル/RPC
- 掲示板のデータモデル・状態遷移・API仕様・用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/src/lib/meguriBoard.ts mobile/app/meguri-board.tsx mobile/app/meguri-board-thread.tsx supabase/migrations/20260530174000_expand_meguri_board_threads.sql notes/05_data_model.md notes/09_state_machines.md notes/10_glossary.md notes/13_api_spec.md notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter171] expand meguri board thread basics" --non-interactive`
- Preview OTA: Update group `1abfdecf-ee5b-48b4-8c7a-2c9e221c1a58` / iOS update `019e74ad-88df-7fad-be96-cd638dedeb1b`
- `supabase db push`（`20260530152000_add_proposal_option_tags.sql` / `20260530174000_expand_meguri_board_threads.sql` を remote DB に適用）

### 関連ファイル

- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `supabase/migrations/20260530174000_expand_meguri_board_threads.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 掲示板一覧にカテゴリ/検索/並び替え/未読/保存/参考になった/アクションを追加。
- ✅ 掲示板詳細に保存/参考になった/既読/返信リアクション/通報を追加。
- ✅ migration 未適用でもローカル状態で落ちないフォールバックを実装。
- ✅ 状態遷移・用語・データモデル・API仕様を更新。

---

## イテレーション170.3：左ドロワーの奥行きと間隔調整

### 背景・問題意識

オーナーから、左ドロワーは下層にあるように見せたいので元画面側から影が落ちる表現にしたい、行間が広すぎる、文字が大きく「プロフィール編集」が入りきっていない、閉じる途中にドロワーをタップすると再表示される挙動が不自然、という指摘があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- 元画面を影を落とす外側レイヤーと、角丸で内容を切り抜く内側レイヤーに分け、ドロワー側へ落ちる影を強めた。
- ドロワーメニューの行間、アイコンサイズ、文字サイズ、区切り線余白を詰めた。
- メニュー文字を伸縮可能にし、「プロフィール編集」のような長い項目が入りやすいようにした。
- ドロワーを閉じるアニメーション中はドロワー側とエッジハンドルのタップを無効化し、閉じる途中のタップで再表示されないようにした。
- 閉じる方向のスワイプ判定を軽くし、少し左へ引いた時点で閉じる挙動に寄せた。

### 影響範囲

- iOS版 共通タブレイアウト
- 左ドロワー
- 左ドロワーの開閉ジェスチャー

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/(tabs)/_layout.tsx notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter170.3] drawer depth spacing polish" --non-interactive`
- Preview OTA: Update group `ba9c9644-259f-4580-9c31-73f315942d98` / iOS update `019e749d-4582-7702-bdaa-2e4294a748ad`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ 元画面側の影を強め、ドロワーが下層に見える構造へ変更。
- ✅ 行間・アイコン・文字サイズを縮小し、長い項目が収まりやすい表示へ変更。
- ✅ 閉じる途中のドロワータップによる再表示を防止。
- ✅ 状態遷移・用語・データモデルの変更はないため、`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要。

---

## イテレーション170.2：関係図ヘッダーと個別募集見出し調整

### 背景・問題意識

オーナーから、関係図画面のヘッダーに表示される「@michiとのマッチ詳細」のような説明書きは不要であり、ボディ側の「あなたの個別募集」は黒太字の見出しだけでよいという依頼があった。

### 変更内容

#### `mobile/app/match-detail.tsx`
- 関係図ヘッダーからマッチ詳細のサブタイトルを削除した。
- 「あなたの個別募集」セクションを黒太字の見出しのみで表示する `titleOnly` 表示に変更した。

### 影響範囲

- iOS版 関係図画面
- 関係図のスワイププレビュー / 切り替えカバー表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/match-detail.tsx notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter170.2] match detail copy cleanup" --non-interactive`
- Preview OTA: Update group `049f859b-f945-4e3b-a0a7-8436844b4e66` / iOS update `019e7495-3eb1-7157-b029-414977b0f05b`

### 関連ファイル

- `mobile/app/match-detail.tsx`

### セルフレビュー結果

- ✅ ヘッダーの説明書きは削除済み。
- ✅ 「あなたの個別募集」は黒太字の見出しのみで表示。
- ✅ 状態遷移・用語・データモデルの変更はないため、`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要。

---

## イテレーション170.1：提示物選択の待ち合わせUI整理

### 背景・問題意識

オーナーから、提示物選択画面の交換手段セレクタに残っている説明文と右上サマリー表示、待ち合わせタブ内の「相手と自分のスケジュール」見出しと説明文を削除したいという依頼があった。あわせて、待ち合わせタブ下部の余計な灰色領域をなくし、週/月カレンダー内に自分と相手の予定が見える状態にしたいという指摘があった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 交換手段カードから、選択中の交換手段サマリーと下部説明文を削除した。
- 待ち合わせタブから「相手と自分のスケジュール」見出しと説明文を削除した。
- カレンダー切り替えを「週 / 月」の小さな右上ボタンに変更した。
- 週表示を5日単位から7日単位に変更した。
- 待ち合わせカレンダー内の予定表示を、候補/予定のある時間帯へ初期スクロールするようにした。
- 月表示の予定にも予定名と場所を1行で出すようにした。
- 画面下部のPrimaryButtonを安全領域込みのフッターに移し、`Screen` の大きな下部余白を使わない構造にした。

### 影響範囲

- iOS版 提示物選択画面
- 交換手段選択
- 待ち合わせ候補選択カレンダー

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/proposal-select.tsx notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter170.1] proposal meetup calendar cleanup" --non-interactive`
- Preview OTA: Update group `d0f82e7a-66f6-4f29-8ddb-0616d70fcecd` / iOS update `019e7491-5b6c-7238-94c4-f847d854191e`

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 交換手段の説明文と右上サマリーを削除。
- ✅ 待ち合わせタブの見出し/説明文を削除。
- ✅ 週/月切り替えは右上の小型ボタン化。
- ✅ 週表示は7日単位へ変更。
- ✅ 予定名と場所は週/月どちらにも表示される構造。
- ✅ 状態遷移・用語・データモデルの変更はないため、`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要。

---

## イテレーション170：タグ右上統一と打診フィルター拡張

### 背景・問題意識

オーナーから、ホーム・マイ在庫・Wish・検索結果のカードタグを右上表示で統一し、マイ在庫の未使用ヘッダーアイコンやフッター上の余計な灰色領域を削除したいという依頼があった。あわせて、やりとり画面の下部タブを提示物選択の交換手段セレクタに寄せ、提示物選択の在庫表示速度、打診時のオプションタグ、検索フィルターを改善する必要があった。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- `topRowMode="tag"` のタグ表示をカード右上に寄せ、検索結果・在庫・Wishで共通化した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム候補カードのタグを右上表示に変更した。

#### `mobile/app/(tabs)/inventory.tsx`
- 右上の未使用フィルター/検索アイコンを削除した。
- グッズカードに右上タグを表示し、下部タグ帯は非表示にした。
- 外側の大きな下余白を削り、フッター上の余計な背景領域が出にくい構造にした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wishカードに右上タグを表示し、下部タグ帯は非表示にした。
- 外側の大きな下余白を削った。

#### `mobile/app/(tabs)/transactions.tsx`
- やりとり画面下部の「打診中 / 進行中」切り替えを iOS の `SegmentedControl` に変更し、提示物選択の交換手段セレクタと揃えた。
- 外側の大きな下余白を削った。

#### `mobile/app/proposal-select.tsx`
- 提示物選択の初期在庫読み込みを「私が出す」「受け取る」それぞれ独立して表示できるようにし、先に返った10件から表示するようにした。

#### `mobile/app/proposal-confirm.tsx`
- 打診確認画面にオプションタグ選択を追加した。
- 郵送を含む交換では「即日発送」「同日発送」を候補に含めるようにした。
- 選択したタグを `proposals.option_tags` に保存するようにした。

#### `mobile/app/search.tsx`
- 検索結果画面にフィルター導線を追加した。
- グループ、メンバー、グッズ種別、現地交換日付、現地交換場所、オプションタグ、タグ、交換手段で絞り込めるUIを追加した。

#### `supabase/migrations/20260530152000_add_proposal_option_tags.sql`
- `proposals.option_tags text[]` を追加した。

#### `notes/05_data_model.md`
- `proposals.option_tags` を追記した。

#### `notes/10_glossary.md`
- 「オプションタグ」を交換シーンタグの打診単位UI名として追加した。

### 影響範囲

- iOS版 ホーム
- iOS版 マイ在庫
- iOS版 Wish
- iOS版 やりとり
- iOS版 提示物選択 / 送信確認
- iOS版 検索
- Supabase `proposals` スキーマ

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/src/components/GoodsGrid.tsx mobile/app/(tabs)/index.tsx mobile/app/(tabs)/inventory.tsx mobile/app/(tabs)/wishes.tsx mobile/app/(tabs)/transactions.tsx mobile/app/proposal-select.tsx mobile/app/proposal-confirm.tsx mobile/app/search.tsx notes/05_data_model.md notes/10_glossary.md notes/08_design_iterations.md supabase/migrations/20260530152000_add_proposal_option_tags.sql`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter170] tag placement filters option tags" --non-interactive`
- Preview OTA: Update group `b427d4cb-b30d-41df-bb21-209e0b3f153c` / iOS update `019e7489-38b0-7a7e-92c8-89b63774e1ea`

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/app/search.tsx`
- `supabase/migrations/20260530152000_add_proposal_option_tags.sql`
- `notes/05_data_model.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ カードタグ表示は右上に統一。
- ✅ マイ在庫の未使用ヘッダーアイコンを削除。
- ✅ やりとり下部タブは iOS 標準の `SegmentedControl` に変更。
- ✅ 提示物選択は片側ずつ初期表示できるようにした。
- ✅ `proposals.option_tags` の migration / データモデル / 用語を更新。
- ✅ 状態遷移の追加・変更はないため、`notes/09_state_machines.md` の更新は不要。

---

## イテレーション169：ホーム候補を検索結果カードへ統一

### 背景・問題意識

オーナーから、ホーム画面の「交換できるかも？」はタップ時に相手プロフィールへ遷移し、各パネル右上には登録タグを表示したいという依頼があった。あわせて、ホームの交換候補パネルは検索結果画面のデザインを踏襲し、文字サイズと画像サイズを揃える必要があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホームの交換候補表示を、行ごとの横スクロール棚から検索結果と同じ3列グリッド型のカード表示へ変更した。
- カード画像の比率を検索結果の `GoodsGrid` と同じ `width * 1.34` に揃え、タグ表示の文字サイズ・角丸・配置を検索結果のトップタグ表示に寄せた。
- 各候補カード右上に `tagLabels` / `tag` 由来の登録タグを表示するようにした。
- 「交換できるかも？」セクションの候補タップ時は、`partnerId` を使って `/user-profile` へ遷移するようにした。
- ホームの「交換できるかも」見出しを検索結果と同じ「交換できるかも？」表記へ揃えた。

### 影響範囲

- iOS版 ホーム画面
- ホームの「マッチしてるよ！」候補カード
- ホームの「交換できるかも？」候補カード
- 候補カードからのプロフィール/詳細遷移

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/(tabs)/index.tsx notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter169] home candidate grid profile links" --non-interactive`
  - Update group ID: `75545053-d78c-4c11-9ef5-81e53439a1ba`
  - iOS update ID: `019e747a-6872-7eb8-af06-0b9ee912fd95`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 検索結果と同じ3列・同じ画像比率へ寄せた。
- ✅ 登録タグはカード右上に表示される。
- ✅ 「交換できるかも？」は相手プロフィールへ遷移し、「マッチしてるよ！」は既存の詳細遷移を維持。
- ✅ 状態遷移・用語・データモデル変更はないため、`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要。

---

## イテレーション168.99：左ドロワーを背面レイヤー化

### 背景・問題意識

オーナーから、左ドロワーを添付画像のように「ドロワーが下層にあり、元の画面が右へ動いて境界の端が丸くなる」デザインへ変更したいという依頼があった。あわせて、右スワイプ量に応じて元画面が白くホワイトアウトする動きと、ドロワー内テキストサイズを画像に近づける必要があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- 既存の前面オーバーレイドロワーをやめ、`ProfileDrawerShell` で `NativeTabs` 自体を前景レイヤーとして包む構造に変更した。
- ドロワーを背面レイヤーとして常駐させ、左端スワイプで前景のタブ画面を右へスライドさせるようにした。
- 前景画面の左上/左下角を開閉量に応じて大きく丸め、境界に奥行きが出るシャドウを付けた。
- 開閉量に応じて前景画面の上に白いフェードを重ね、右へスワイプするほど元画面が白く薄れるようにした。
- ドロワー内のメイン項目/コンパクト項目のアイコン・文字サイズ・行間を拡大し、添付画像の密度に近づけた。

### 影響範囲

- iOS版 全タブ画面
- 左端スワイプで開くプロフィールドロワー
- ドロワー内のプロフィール/設定/更新導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/(tabs)/_layout.tsx notes/08_design_iterations.md`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.99] drawer layered swipe design" --non-interactive`
  - Update group ID: `36b63d99-b298-47ff-b7b4-8d551a84ce68`
  - iOS update ID: `019e7471-9254-7657-94fe-c1fdd346d951`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ ドロワーを背面、タブ画面を前景として動かす構造に変更。
- ✅ 前景画面の左境界に丸みとシャドウを付け、下層ドロワーらしい見え方へ調整。
- ✅ スワイプ量に応じた白フェードを追加。
- ✅ 状態遷移・用語・データモデル変更はないため、`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要。

---

## イテレーション168.98：読み込み骨格を実UI形状へ調整

### 背景・問題意識

オーナーから、ローディング中のスケルトンは「読み込みがかかるところだけ」に出し、表示後のコンポーネントの部品の形と位置に合わせるよう依頼があった。従来は一部の画面で汎用的な箱やローディング文言に寄っており、実際のカード/グリッド構造とズレて見える箇所があった。

### 変更内容

#### `mobile/src/components/SkeletonScreen.tsx`
- 在庫/Wishのグッズグリッドと同じ列数・タイル比率で表示する `GoodsGridSkeleton` に作り直した。
- 在庫/Wishのフィルタ行に合わせた `FilterRowsSkeleton` を追加した。
- 個別募集の募集デッキ、取引カード、ホームの交換候補棚、掲示板スレッドカード、提示物選択カードの形状に合わせて各スケルトンを再設計した。
- グルームの横並びスケルトンを、実際の丸アイコンサイズとラベル位置に合わせた。

#### `mobile/app/(tabs)/index.tsx`
- ホームのグルーム欄は読み込み対象ではないため、ホームの交換候補ロード中も実データを表示したままにした。
- 交換候補棚だけを、行見出しとカード列に合わせたスケルトン表示に変更した。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫のロード中は、フィルタ行とグッズグリッドだけを実UI位置でスケルトン表示するようにした。
- activeタブでは実表示と同じく追加タイル分も骨格表示するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wishタブはフィルタ行とグッズグリッド、個別募集タブは募集デッキだけをスケルトン表示するようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- 掲示板ロード中のActivityIndicator文言カードを廃止し、実際のスレッドカード形状のスケルトンに置き換えた。

### 影響範囲

- iOS版 ホーム
- iOS版 マイ在庫
- iOS版 ウィッシュ / 個別募集
- iOS版 めぐりホームのグルーム/掲示板
- iOS版 やりとり一覧
- iOS版 提示物選択

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/src/components/SkeletonScreen.tsx mobile/app/(tabs)/index.tsx mobile/app/(tabs)/inventory.tsx mobile/app/(tabs)/wishes.tsx mobile/app/(tabs)/encounters.tsx`
- `npm --prefix mobile run export:ios:preview`
- `EAS_UPDATE_PROJECT_SLUG=ihub EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.98] loading skeletons match components" --non-interactive`
  - Update group ID: `35b340cb-5934-4ea0-b6dc-de89deb618dd`
  - iOS update ID: `019e746c-300b-76f4-9b80-f6caa4d8c1dc`

### 関連ファイル

- `mobile/src/components/SkeletonScreen.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ スケルトンは画面全体ではなく、読み込み対象のカード/グリッド/フィルタ/掲示板部分に限定。
- ✅ 在庫/Wishのタイル比率、個別募集デッキ、取引カード、掲示板カードの主要な形と位置を実UIに合わせた。
- ✅ 状態遷移・用語・データモデル変更はないため、`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要。

---

## イテレーション168.97：応答時の条件選択と予定重ね見

### 背景・問題意識

オーナーから、取引チャット内の交換内容詳細に現地交換の候補日時が混ざっているため、交換手段の詳細へ移したいという依頼があった。あわせて、相手からの打診に応じる時は、現地/郵送どちらもOKや複数候補のまま曖昧に合意せず、交換手段または候補を1つ選ぶ必要がある。条件を少し変えたい場合は、元打診をコピーして再打診できる導線も必要になった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 交換内容詳細から待ち合わせ候補を外し、交換手段詳細へ移した。
- 交換手段詳細の地図をタップすると、端末の地図アプリで候補地点を開くようにした。
- `both` の打診、または複数候補の現地交換に応じる場合、交換手段/候補を1つ選ぶモーダルを追加した。
- モーダルと「条件を変えて再打診」から、元打診の内容をコピーして `proposal-select` に進めるようにした。
- チャット入力欄上の「カレンダー」を「スケジュール」に変更し、取引相手との予定重ね見画面へ遷移させるようにした。

#### `mobile/app/transaction-schedule.tsx`
- 取引チャット専用のスケジュール重ね見画面を追加した。
- 自分と相手の予定を日別に並べ、ヘッダー右端の「更新」から自分のスケジュール管理へ進めるようにした。

#### `mobile/app/schedules.tsx` / `mobile/app/schedule-editor.tsx`
- スケジュールにテキスト入力の「場所」を追加した。
- `place_name` 未適用のDBでも画面が落ちないように読み書きのフォールバックを追加した。

#### `mobile/app/proposal-select.tsx`
- 現地交換の待ち合わせ候補登録画面に、自分と相手のスケジュールを読み取り専用の背景として表示した。
- 既存の5日表示に加え、月表示へ切り替えられるようにし、1日につき最大3件の予定を表示した。

#### `supabase/migrations/20260530123000_add_schedule_place_name.sql`
- `schedules.place_name` を追加する migration を作成した。

### 影響範囲

- iOS版 取引チャット
- iOS版 打診への応答/再打診
- iOS版 提示物選択の待ち合わせ候補登録
- iOS版 スケジュール管理
- Supabase `schedules` テーブル

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/transaction-detail.tsx mobile/app/transaction-schedule.tsx mobile/app/proposal-select.tsx mobile/app/schedules.tsx mobile/app/schedule-editor.tsx supabase/migrations/20260530123000_add_schedule_place_name.sql notes/08_design_iterations.md notes/09_state_machines.md notes/10_glossary.md notes/05_data_model.md`
- `npx supabase db push`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.97] 応答時の条件選択と予定重ね見" --non-interactive`
- Preview channel OTA配信済み：Update group `8267f92d-f276-4def-ae02-a7900add18ef` / iOS update ID `019e7462-9a59-75b8-873a-5c8654ca7d91`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/8267f92d-f276-4def-ae02-a7900add18ef`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/transaction-schedule.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/schedules.tsx`
- `mobile/app/schedule-editor.tsx`
- `supabase/migrations/20260530123000_add_schedule_place_name.sql`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 交換内容詳細はグッズ内容に絞り、現地交換の候補は交換手段詳細へ移動
- ✅ `both` / 複数候補のまま合意せず、応答前に1つ選択する導線を追加
- ✅ 元打診をコピーして条件変更できる再打診導線を維持
- ✅ スケジュール場所はテキスト入力のみで追加
- ✅ 5日表示と月表示を切り替え可能にし、予定は編集不可の背景/一覧として表示
- ✅ Supabase remote DBへ `schedules.place_name` migration 適用済み
- ✅ 09更新診断：合意前の交換手段・候補選択ルールとカレンダー公開の対象を更新
- ✅ 10更新診断：スケジュール/再打診/カレンダー重ね見の定義を更新
- ✅ 05更新診断：`schedules.place_name` と合意時の候補固定ルールを追記
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み

---

## イテレーション168.96：掲示板の都道府県選択を保存

### 背景・問題意識

オーナーから、スポット掲示板の都道府県は掲示板画面内で選べるようにし、初期値はプロフィールの都道府県、以降はユーザーが最後に選んだ都道府県をデフォルトにしたいという依頼があった。現地3km圏内と都道府県単位の閲覧を分けつつ、都道府県側は現在地ではなくユーザーが掲示板で選んだ値を使う必要がある。

### 変更内容

#### `mobile/src/lib/meguriBoardPreferences.ts`
- 掲示板専用の都道府県デフォルト保存 helper を追加した。
- 初回はプロフィール由来の都道府県を正規化し、変更後は AsyncStorage の保存値を返すようにした。
- 47都道府県の選択肢と、表示名変換 helper をまとめた。

#### `mobile/app/meguri-board.tsx`
- スポット掲示板画面に、iOS標準のアクションシートで都道府県を選べるセレクタを追加した。
- `same_prefecture` の一覧取得、投稿作成、詳細遷移で、選択済み都道府県を使うようにした。
- 現在地から取れる都道府県が、ユーザーの選択値を上書きしないようにした。

#### `mobile/app/meguri-board-map.tsx`
- 掲示板マップでも、掲示板画面で保存した都道府県デフォルトを使って都道府県単位のスレッドを取得するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細で、一覧やマップから渡された都道府県を現在地の都道府県より優先するようにした。

#### `mobile/src/lib/meguriBoard.ts`
- 都道府県の一致判定で `東京都` と `東京` のような表記ゆれを同一視するようにした。

### 影響範囲

- iOS版 スポット掲示板
- iOS版 掲示板マップ
- iOS版 掲示板スレッド詳細
- 掲示板の都道府県単位表示・投稿作成

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/meguri-board.tsx mobile/app/meguri-board-map.tsx mobile/app/meguri-board-thread.tsx mobile/src/lib/meguriBoard.ts mobile/src/lib/meguriBoardPreferences.ts notes/09_state_machines.md notes/10_glossary.md`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.96] 掲示板の都道府県選択" --non-interactive`
- Preview channel OTA配信済み：Update group `db76fc17-5ee0-4db0-8354-3afdf32bcb78` / iOS update ID `019e744e-0e19-7faa-9663-c450eb089278`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/db76fc17-5ee0-4db0-8354-3afdf32bcb78`

### 関連ファイル

- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-map.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `mobile/src/lib/meguriBoard.ts`
- `mobile/src/lib/meguriBoardPreferences.ts`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 初回デフォルトはプロフィールの都道府県から取得
- ✅ 画面内で変更した都道府県を端末に保存し、次回以降の既定値にする
- ✅ `same_prefecture` の閲覧・投稿で、現在地ではなく掲示板の選択値を優先
- ✅ iOS標準のアクションシートで都道府県を選択
- ✅ 09更新診断：掲示板の都道府県既定値ルールを追記
- ✅ 10更新診断：スポット掲示板と掲示板の都道府県設定を更新
- ✅ 05更新診断：端末保存値のみのためDBスキーマ変更なし
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み

---

## イテレーション168.95：めぐり地図と掲示板ホームを追加

### 背景・問題意識

オーナーから、グルームを地図上に吹き出し付き丸アイコンとして表示し、1km圏内だけ内容を開けるようにしたいという依頼があった。あわせて、めぐりホームのメッセージ/マップ/実績導線は廃止し、掲示板一覧と掲示板マップ、スレッド作成導線を主軸にしたい。マイ在庫とWishでは、ヘッダーの囲いを外し、列数変更を現在の列数が分かるアイコンにしたい。

### 変更内容

#### `mobile/src/lib/groom.ts`
- グルーム取得結果に `origin_lat/origin_lng` を含めるようにした。
- 地図用に、位置情報付きのグルーム投稿を取得し、閲覧者からの距離を計算する `fetchGroomMapPosts` を追加した。

#### `mobile/app/groom-map.tsx`
- グルーム投稿を地図上の吹き出し付き丸アイコンとして表示する全画面マップを追加した。
- 1km圏内の投稿だけ内容モーダルを開けるようにし、圏外タップ時は「1km圏外のグルームは見れません」を表示するようにした。

#### `mobile/src/lib/meguriBoard.ts`
- 掲示板マップ用に、3km圏内と都道府県単位のスレッドをまとめて取得し、距離で並べる `loadMeguriBoardMapThreads` を追加した。

#### `mobile/app/meguri-board-map.tsx`
- 掲示板スレッドを地図上に表示する全画面マップを追加した。
- 3km圏内または都道府県単位で閲覧可能なスレッドだけ詳細へ遷移するようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム見出し右に「地図で見る」を追加し、グルームマップへ遷移するようにした。
- メッセージ/マップ/実績のショートカットをホームから外した。
- 掲示板見出し、3km圏内スレッド一覧、掲示板マップ導線を追加した。
- 右下固定の「スレッドを立てる」ボタンを追加し、掲示板作成モーダルを開けるようにした。

#### `mobile/app/meguri-board.tsx`
- `compose=1` パラメータでスレッド作成モーダルを自動表示できるようにした。

#### `mobile/src/components/GoodsGrid.tsx`
- 列数変更UIを、3/4/5の数字ボタンから、現在の列数分だけ四角が並ぶ単一アイコンボタンに変更した。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫ヘッダーの枠・背景を外し、フラットな行にした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wishヘッダーの枠・背景を外し、フラットな行にした。

### 影響範囲

- iOS版 めぐりタブ
- iOS版 グルームマップ
- iOS版 掲示板マップ
- iOS版 掲示板作成導線
- iOS版 マイ在庫 / Wish のヘッダーと列数変更UI

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/groom-map.tsx mobile/app/meguri-board-map.tsx mobile/src/lib/groom.ts mobile/src/lib/meguriBoard.ts mobile/app/'(tabs)'/encounters.tsx mobile/src/components/GoodsGrid.tsx mobile/app/'(tabs)'/inventory.tsx mobile/app/'(tabs)'/wishes.tsx mobile/app/meguri-board.tsx notes/09_state_machines.md notes/10_glossary.md`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.95] めぐり地図と掲示板ホーム" --non-interactive`
- Preview channel OTA配信済み：Update group `1fdd9c59-2086-4408-a487-6e70e75ef8e6` / iOS update ID `019e7444-3bd0-778f-9bb2-2d6dcb84da0d`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/1fdd9c59-2086-4408-a487-6e70e75ef8e6`

### 関連ファイル

- `mobile/app/groom-map.tsx`
- `mobile/app/meguri-board-map.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-board.tsx`
- `mobile/src/lib/groom.ts`
- `mobile/src/lib/meguriBoard.ts`
- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ グルームマップは1km圏外もアイコン表示し、内容閲覧だけを1km圏内に制限
- ✅ めぐりホームからメッセージ/マップ/実績ショートカットを撤去し、掲示板一覧と作成導線へ置換
- ✅ 掲示板マップは3km圏内/都道府県単位の閲覧条件を維持
- ✅ マイ在庫/Wishのヘッダー枠を撤去
- ✅ 列数変更アイコンは現在の3/4/5列に応じて四角数が変わる
- ✅ 09更新診断：グルーム/掲示板の地図閲覧ルールを追記
- ✅ 10更新診断：グルームマップ/掲示板マップを用語として追記
- ✅ 05更新診断：既存の `origin_lat/origin_lng` を利用するためDBスキーマ変更なし
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み

---

## イテレーション168.94：証跡撮影と提示物選択を整理

### 背景・問題意識

オーナーから、証跡撮影中のカメラ画面をグルーム撮影時のカメラデザインに揃えたいという依頼があった。あわせて、提示物選択では個別募集で指定された一部候補だけではなく、自分のグッズと相手のグッズを選べるようにし、読み込みが重くならないよう10件ずつ追加読み込みしたい。やりとり一覧では「打診中」「進行中」の切り替えをフッター上部に置き、横フリックでも同時に切り替えたい。

### 変更内容

#### `mobile/app/transaction-capture.tsx`
- 証跡撮影カメラの上部バー、背景スクリム、シャッター、アルバム導線をグルーム撮影カメラの見た目に寄せた。
- 上部タイトルは `証跡の撮影` に変更した。
- 撮影済み写真のサムネイルは下部操作エリアの上にまとめ、削除操作は維持した。
- 撮影サイズ選択をグルーム撮影と同じくアップロード向きの長辺上限付きにした。

#### `mobile/app/proposal-select.tsx`
- 相手プロフィール/個別募集起点の提示物選択で、「私が出す」は自分の譲る在庫、「受け取る」は相手の譲る在庫を候補にするようにした。
- 初回は各10件だけ読み込み、下へスクロールすると10件ずつ追加取得する方式にした。
- 既にrouteで渡された候補は先頭側に含めつつ、候補全体をその一部だけに制限しないようにした。
- 追加読み込み中はカードリスト末尾に読み込み表示を出すようにした。

#### `mobile/app/(tabs)/transactions.tsx`
- 「打診中」「進行中」の切り替えを画面下部、ネイティブタブバーの上に固定表示した。
- 一覧本体を横ページングにし、横フリックの指の動きに合わせて下部タブの選択位置も動くようにした。
- 読み込み中のスケルトン表示と既存の空表示をページごとに維持した。

### 影響範囲

- iOS版 `/transaction-capture`
- iOS版 `/proposal-select`
- iOS版 やりとりタブ

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/proposal-select.tsx mobile/app/transaction-capture.tsx mobile/app/'(tabs)'/transactions.tsx`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.94] 証跡カメラと提示物ページング" --non-interactive`
- Preview channel OTA配信済み：Update group `7159488b-c834-40f5-92df-e1859a17a700` / iOS update ID `019e7434-203e-7384-9835-ff7b38f13f0f`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/7159488b-c834-40f5-92df-e1859a17a700`

### 関連ファイル

- `mobile/app/transaction-capture.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ 証跡撮影中のカメラUIをグルーム撮影の構造に統一
- ✅ 提示物選択は自分/相手それぞれの譲る在庫を10件ずつページング取得
- ✅ やりとり一覧の「打診中」「進行中」を下部固定タブ化
- ✅ 横フリック中も下部タブの選択位置が追従
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み
- ✅ 09更新診断：状態遷移の追加・削除はないため更新不要
- ✅ 10更新診断：既存の「証跡撮影」「打診」「取引」「譲」の範囲内のため更新不要
- ✅ 05更新診断：DBスキーマ変更なし

---

## イテレーション168.93：iOS Google OAuth導線を接続

### 背景・問題意識

オーナーから、新規アカウント登録でGoogleアカウントを使えるようにしたいという相談があった。iOS版にはApple ID認証はあるが、GoogleはWelcome画面で無効ボタンのまま残っていた。リリース前の確認速度を落とさないため、ネイティブ依存を追加せず、既存のWeb callbackとmobile deep linkを再利用してGoogle OAuthを接続する方針にした。

### 変更内容

#### `mobile/src/auth/redirects.ts`
- OAuth用のmobile callback URL生成 helper を追加した。
- `next=mobile` / `scheme` / `provider=google` を `https://megrum.jp/auth/callback` に渡せるようにした。

#### `mobile/src/auth/AuthProvider.tsx`
- `supabase.auth.signInWithOAuth({ provider: "google" })` を使う `signInWithGoogleOAuth` を追加した。
- `skipBrowserRedirect: true` でOAuth URLだけ取得し、React Nativeの `Linking.openURL` でGoogle認証画面を開くようにした。

#### `mobile/src/components/GoogleAuthButton.tsx`
- Google新規登録 / ログイン共通ボタンを追加した。
- Supabase未設定時は表示せず、Provider未設定やredirect設定不備は日本語エラーへ寄せるようにした。

#### `mobile/app/(auth)/welcome.tsx`
- 無効化されていた「Googleで新規登録」ボタンを実際のOAuth導線へ差し替えた。
- 利用規約 / プライバシーポリシー同意前はGoogle登録も進めないようにした。

#### `mobile/app/(auth)/login.tsx`
- ログイン画面のApple IDログイン下にGoogleログイン導線を追加した。

#### `web/src/app/auth/callback/route.ts`
- mobile callbackへ `provider=google` を引き継ぐようにした。

#### `mobile/app/auth/email-confirmed.tsx`
- Google OAuthから戻った場合は「Googleアカウントで認証できました」と表示するようにした。

### 影響範囲

- iOS新規登録入口
- iOSログイン画面
- Supabase Google OAuth callback
- Web auth callback の mobile bridge 分岐

### 確認方法

- `git diff --check -- mobile/src/auth/AuthProvider.tsx mobile/src/auth/redirects.ts mobile/src/components/GoogleAuthButton.tsx 'mobile/app/(auth)/welcome.tsx' 'mobile/app/(auth)/login.tsx' mobile/app/auth/email-confirmed.tsx web/src/app/auth/callback/route.ts`
- `npm run mobile:typecheck` は実行したが、今回触っていない `mobile/app/proposal-select.tsx` の既存型エラーで停止
- Supabase DashboardでGoogle Providerを有効化し、Google Cloud OAuth Client ID / Secret とredirect設定を入れた後、Previewアプリで「Googleで新規登録」→ Google認証 → Megrumへ戻ることを確認

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/src/auth/redirects.ts`
- `mobile/src/components/GoogleAuthButton.tsx`
- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/login.tsx`
- `mobile/app/auth/email-confirmed.tsx`
- `web/src/app/auth/callback/route.ts`

### セルフレビュー結果

- ✅ 新しいネイティブ依存を追加していないため、コード差分自体はEAS Update反映対象
- ✅ 既存のmobile email callbackと `exchangeCodeForSession` を再利用した
- ✅ Google登録も規約同意前には開始できない
- ⚠️ Supabase Dashboard / Google Cloud Console のGoogle Provider設定が別途必要
- ⚠️ `npm run mobile:typecheck` は既存の `proposal-select.tsx` 型エラーで完走せず
- ✅ 状態遷移・DBスキーマ・新用語の変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.92：読み込み中をスケルトン表示へ統一

### 背景・問題意識

オーナーから、ホーム画面、在庫、Wish、個別募集、やりとり、グルーム、打診時の提示物選択で、読み込み中のテキスト表示ではなくスケルトンスクリーンにしたいという依頼があった。あわせて、提示物選択では在庫候補の読み込みが遅いため、体感速度を改善したい。

### 変更内容

#### `mobile/src/components/SkeletonScreen.tsx`
- 共通のスケルトン表示コンポーネントを追加した。
- ホームフィード、グッズグリッド、個別募集デッキ、取引一覧、グルーム横並び、提示物選択カードに使えるプレースホルダを用意した。

#### `mobile/app/(tabs)/index.tsx`
- ホームのマッチ候補読み込み中は、グルーム列と候補棚を含むホーム用スケルトンを表示するようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫の読み込み中は、フィルタチップとグッズグリッドのスケルトンを表示するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wishタブの読み込み中は、フィルタチップとグッズグリッドのスケルトンを表示するようにした。
- 個別募集タブの読み込み中は、募集デッキ型のスケルトンを表示するようにした。

#### `mobile/app/(tabs)/transactions.tsx`
- やりとり一覧と完了取引一覧の読み込み中は、取引カード型のスケルトンを表示するようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- グルームの読み込み中は、丸アイコン列のスケルトンを表示するようにした。

#### `mobile/app/proposal-select.tsx`
- 提示物選択の在庫読み込み中は、提示物カード型のスケルトンを表示するようにした。
- 相手プロフィール起点の在庫候補取得を、自分・相手の在庫を並列取得する方式へ変更した。
- 同じ自分/相手ペアの在庫候補を45秒キャッシュし、戻る/再打診時の再読み込みを軽くした。
- `supabase.auth.getUser()` の追加呼び出しを避け、既存のAuthProviderのユーザー情報を使うようにした。

### 影響範囲

- iOS版ホーム
- iOS版マイ在庫
- iOS版Wish / 個別募集
- iOS版やりとり
- iOS版めぐり内グルーム
- iOS版提示物選択

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/'(tabs)'/index.tsx mobile/app/'(tabs)'/inventory.tsx mobile/app/'(tabs)'/wishes.tsx mobile/app/'(tabs)'/transactions.tsx mobile/app/'(tabs)'/encounters.tsx mobile/app/proposal-select.tsx mobile/src/components/SkeletonScreen.tsx`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.92] 読み込みスケルトンと提示物高速化" --non-interactive`
- Preview channel OTA配信済み：Update group `eae3bb2b-be7a-4f4a-9cfc-ada3fa8d9553` / iOS update ID `019e7426-79d4-78d3-a0ff-79f5add4e4fb`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/eae3bb2b-be7a-4f4a-9cfc-ada3fa8d9553`

### 関連ファイル

- `mobile/src/components/SkeletonScreen.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 読み込み中のテキスト表示を主要画面でスケルトン表示へ置き換え
- ✅ Wish と個別募集はタブごとに形の違うスケルトンを表示
- ✅ 提示物選択はカード型スケルトンへ変更
- ✅ 提示物選択の在庫候補取得を並列化し、短時間キャッシュを追加
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み
- ✅ 09更新診断：状態遷移の追加・削除はないため更新不要
- ✅ 10更新診断：ドメイン用語の追加ではなくUI表示パターンのため更新不要
- ✅ 05更新診断：DBスキーマ変更なし

---

## イテレーション168.91：取引チャットの交換手段表示を圧縮

### 背景・問題意識

オーナーから、郵送を選択した取引チャットで「郵送交換」「現地・郵送どちらもOK」と住所情報がヘッダー直下に大きく表示され、チャット上部の領域を取りすぎているという指摘があった。交換内容と同じ粒度で、初期表示はサマリーだけにし、詳細を押した時だけ住所情報を確認できるようにしたい。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引チャットのピン留め領域に常時表示していた郵送住所ブロックを廃止した。
- 交換内容カードと同じ形で、`交換手段` の1行サマリーカードを追加した。
- サマリー文言を `郵送のみ` / `郵送・現地交換どちらもOK` / `現地交換のみ` に整理した。
- `詳細` を押した時だけ交換手段の説明と住所情報をモーダル表示するようにした。
- 郵送対応の取引では、合意前は自分の住所と住所設定導線、合意後は自分と相手の住所を詳細内に表示するようにした。
- 現地交換のみの取引では、詳細内に待ち合わせ候補は交換内容詳細で確認できる旨を表示するようにした。

### 影響範囲

- iOS版 `/transaction-detail`
- 取引チャット上部のピン留め領域
- 郵送交換 / 現地・郵送どちらも対応可 / 現地交換のみの表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/transaction-detail.tsx`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.91] 取引チャット交換手段サマリー" --non-interactive`
- Preview channel OTA配信済み：Update group `1007782d-67c7-4e51-86f7-b4a0b9fd0281` / iOS update ID `019e741a-928c-72b2-baf8-cb290126a91e`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/1007782d-67c7-4e51-86f7-b4a0b9fd0281`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ 住所情報の常時表示をやめ、初期表示を1行サマリーへ圧縮
- ✅ `詳細` から合意前/合意後の住所表示を確認できる
- ✅ 交換内容カードと同じ操作粒度に統一
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み
- ✅ 09更新診断：状態遷移の追加・削除はないため更新不要
- ✅ 10更新診断：既存の「交換手段」「郵送交換」「住所」の範囲内のため更新不要
- ✅ 05更新診断：DBスキーマ変更なし

---

## イテレーション168.90：検索結果を実績とマッチ分類へ整理

### 背景・問題意識

オーナーから、ホーム右下の検索アイコンから開く検索画面について、左上の `(tabs)` 表示を消し、人気の検索は固定サンプルではなく実際の検索実績から出したいという依頼があった。あわせて、検索結果はユーザー名の縦カードではなくマイ在庫のようなグッズパネルで表示し、ホームと同じく「マッチしてるよ！」「交換できるかも？」「マッチなし」に分類したい。

### 変更内容

#### `mobile/app/search.tsx`
- Native Stack の戻る表示を `minimal` にして、左上に `(tabs)` が出ないようにした。
- 検索バーの入力変更だけでは検索実績を記録せず、検索確定時だけ検索するようにした。
- 人気の検索を `get_popular_search_terms` RPC から取得し、固定サンプルの人気ワードを廃止した。
- 検索実行後に `record_search_query` RPC で検索語とヒット件数を記録するようにした。
- 検索結果をグッズパネル表示へ変更し、ユーザー名・ハンドル・評価表示を削除した。
- 検索結果を `matched` / `possible` / `none` に分類し、「マッチしてるよ！」「交換できるかも？」「マッチなし」の3セクションで表示するようにした。
- タイトル・推し・タグ検索に対応し、タグはパネル左上に表示するようにした。

#### `mobile/src/components/GoodsGrid.tsx`
- 既存のマイ在庫グリッドを検索結果でも使えるよう、上部表示をタイトルではなくタグにできる `topRowMode="tag"` を追加した。
- 検索結果では下部タグ帯を消せるよう `showBottomStrip` を追加した。

#### `supabase/migrations/20260529193000_add_search_query_logs.sql`
- `search_query_logs` を追加し、検索語・正規化検索語・ヒット件数・検索日時を保存するようにした。
- `record_search_query` / `get_popular_search_terms` RPC を追加した。

### 影響範囲

- iOS版 `/search`
- iOS版ホーム右下検索導線
- Supabase `search_query_logs` / 検索実績RPC
- notes 05 / 10 / 13

### 確認方法

- `npm --prefix mobile run typecheck`
- `npx supabase db push`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.90] 検索結果と人気検索" --non-interactive`
- Preview channel OTA配信済み：Update group `a53553a0-2d90-4ce0-bb5f-fe36ac040181` / iOS update ID `019e7415-4307-7b37-97c4-596fd2bb9b40`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/a53553a0-2d90-4ce0-bb5f-fe36ac040181`
- `git diff --check -- mobile/app/search.tsx mobile/src/components/GoodsGrid.tsx supabase/migrations/20260529193000_add_search_query_logs.sql notes/05_data_model.md notes/08_design_iterations.md notes/10_glossary.md notes/13_api_spec.md`

### 関連ファイル

- `mobile/app/search.tsx`
- `mobile/src/components/GoodsGrid.tsx`
- `supabase/migrations/20260529193000_add_search_query_logs.sql`
- `notes/05_data_model.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ `(tabs)` 戻るタイトルを非表示化
- ✅ 人気の検索から固定サンプルを削除
- ✅ 検索実績ログ/RPCをremote DBへmigration適用済み
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み
- ✅ 検索結果をグッズパネル形式へ変更
- ✅ ユーザー名・ハンドル・評価は検索結果カードから削除
- ✅ タグはパネル左上に表示
- ✅ 検索結果を「マッチしてるよ！」「交換できるかも？」「マッチなし」に分類
- ✅ 09更新診断：状態遷移の追加・削除はないため更新不要
- ✅ 10更新診断：検索実績 / マッチなしを追加
- ✅ 05更新診断：`search_query_logs` とRPC追加を反映

---

## イテレーション168.89：グルームと掲示板の位置スコープ整理

### 背景・問題意識

オーナーから、グルームは周囲1km圏内にいる人のものが一覧に出るようにし、掲示板は都道府県単位または3km圏内のスレッドを見られるようにしたいという依頼があった。掲示板の3km判定は、スレッドを立てた時の位置情報を基準にする。

### 変更内容

#### `mobile/src/lib/locationContext.ts`
- 現在地・都道府県・表示用ラベルを取得する共通ヘルパーを追加した。
- 掲示板詳細への遷移時に渡す緯度経度パラメータを安全に数値化する補助関数を追加した。

#### `mobile/src/lib/groom.ts`
- `fetchGroomFeed()` に閲覧者の現在地を渡せるようにし、Supabase RPC `list_groom_feed_nearby` が使える場合は1km圏内の投稿だけを取得するようにした。
- `createGroomPost()` に投稿時位置を保存する `origin` を追加した。
- migration未適用時は従来カラムのみでリトライし、アプリが即時クラッシュしないようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム一覧取得時に現在地を取得し、1km圏内フィードへ渡すようにした。
- グルーム投稿時は位置情報を必須にし、投稿時位置をDBへ渡すようにした。

#### `mobile/src/lib/meguriBoard.ts`
- 掲示板の公開範囲を `nearby_3km` / `same_prefecture` に更新し、`same_spot` / `global` はlegacy互換扱いにした。
- スレッドに `originLat/originLng/distanceMeters` を持たせ、3km圏内判定と距離表示に使うようにした。
- 一覧・返信・返信追加は位置コンテキスト付きRPCを優先し、ローカル/preview fallbackも同じ公開範囲で絞るようにした。

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧を `3km圏内` / `都道府県` のセグメント切り替えに変更した。
- スレッド作成時の公開範囲も `3km圏内` / `都道府県` に変更した。
- `3km圏内` スレッド作成時は位置情報を必須にし、作成時位置を保存するようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細と返信送信にも閲覧者の位置・都道府県・表示モードを渡し、公開範囲内のスレッドだけ開けるようにした。

#### `supabase/migrations/20260529191000_add_location_scoped_groom_board.sql`
- `groom_posts` / `meguri_board_threads` に `origin_lat/origin_lng` を追加した。
- Haversine距離計算関数を追加した。
- グルーム1kmフィード用RPC、掲示板3km/都道府県一覧・返信用RPCを追加した。

#### `notes/23_meguri_board_thread_spec.md`
- 掲示板を欲しがるユーザー、参考にするスレッド型体験、MVP仕様、後回し項目を整理した。

### 影響範囲

- iOS版 めぐりホームのグルーム一覧/投稿
- iOS版 `/meguri-board`
- iOS版 `/meguri-board-thread`
- Supabase `groom_posts` / `meguri_board_threads` / 掲示板RPC
- notes 05 / 09 / 10 / 13 / 23

### 確認方法

- `npm --prefix mobile run typecheck`
- `npx supabase db push`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.89] グルーム掲示板位置スコープ" --non-interactive`
- Preview channel OTA配信済み：Update group `222049ff-154c-4e15-ac2b-35bbedd445ac` / iOS update ID `019e7409-5342-7603-b461-6a576fec6a2a`
- EAS Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/222049ff-154c-4e15-ac2b-35bbedd445ac`
- `git diff --check -- mobile/src/lib/locationContext.ts mobile/src/lib/groom.ts mobile/src/lib/meguriBoard.ts mobile/app/(tabs)/encounters.tsx mobile/app/meguri-board.tsx mobile/app/meguri-board-thread.tsx supabase/migrations/20260529191000_add_location_scoped_groom_board.sql notes/05_data_model.md notes/09_state_machines.md notes/10_glossary.md notes/13_api_spec.md notes/23_meguri_board_thread_spec.md`

### 関連ファイル

- `mobile/src/lib/locationContext.ts`
- `mobile/src/lib/groom.ts`
- `mobile/src/lib/meguriBoard.ts`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `supabase/migrations/20260529191000_add_location_scoped_groom_board.sql`
- `notes/23_meguri_board_thread_spec.md`

### セルフレビュー結果

- ✅ グルーム一覧は現在地1km圏内をRPC優先で取得
- ✅ グルーム投稿時に作成時位置を保存
- ✅ 掲示板一覧は `3km圏内` / `都道府県` の2択へ変更
- ✅ 3km圏内スレッドの基準地点は作成時位置
- ✅ Supabase remote DBへmigration適用済み
- ✅ Preview channel / iOS runtime `0.1.0` へOTA配信済み
- ✅ 正確な緯度経度を画面表示しない
- ✅ 09更新診断：GroomのビジネスルールとBoard Lifecycleを更新
- ✅ 10更新診断：グルーム/掲示板/スレッド/掲示板公開範囲を更新
- ✅ 05更新診断：`origin_lat/origin_lng` とRPC追加を反映

---

## イテレーション168.88：Preview OTA配信設定の復旧

### 背景・問題意識

オーナーから、TestFlightへ毎回Uploadするのではなく、直近のJS/TS変更をOTA配信で反映したいという依頼があった。EAS Update実行時に、既存TestFlightビルドへ埋め込まれている `extra.eas.projectId` はそのまま必要だが、Expo側の既存プロジェクトslugが旧名のため、現在の `slug: megrum` と不一致になり配信が止まっていた。

### 変更内容

#### `mobile/app.config.js`
- 通常のアプリ設定では `slug: megrum` を維持したまま、EAS Update実行時だけ `EAS_UPDATE_PROJECT_SLUG` でslugを上書きできるようにした。
- 既存TestFlightビルドに届くよう、今回は `EAS_UPDATE_PROJECT_SLUG=ihub` を指定して `preview` チャンネルへiOS OTA配信した。

#### EAS Update
- `preview` ブランチ / iOS / runtime `0.1.0` へOTA配信した。
- Update group ID: `68a9389f-05f0-4d37-8619-b4fee1d9109b`
- iOS update ID: `019e73f4-83dc-7101-97cf-635be78a59ec`
- Dashboard: `https://expo.dev/accounts/mashima.bizz/projects/ihub/updates/68a9389f-05f0-4d37-8619-b4fee1d9109b`

### 影響範囲

- iOS版 Preview OTA配信
- TestFlight配布済みの `tokyo.megrum.app.preview`
- `preview` channel / runtime `0.1.0`

### 確認方法

- `npm --prefix mobile run typecheck`
- `EXPO_NO_GIT_STATUS=1 EAS_UPDATE_PROJECT_SLUG=ihub npm --prefix mobile run update:ios:preview -- --message "[iter168.85-168.87] Preview OTA" --non-interactive`
- `git diff --check -- mobile/app.config.js notes/08_design_iterations.md notes/10_glossary.md`

### 関連ファイル

- `mobile/app.config.js`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 通常ビルド時のMegrum slugは維持
- ✅ OTA配信時だけ既存EAS project slugへ合わせられる
- ✅ iOS Preview / runtime `0.1.0` へOTA publish成功
- ✅ 09更新診断：アプリ状態遷移は変えないため更新不要
- ✅ 10更新診断：OTA配信の用語を追加
- ✅ 05更新診断：DBスキーマ更新なし

---

## イテレーション168.87：取引証跡撮影と通報導線の整理

### 背景・問題意識

オーナーから、取引チャットで証跡を撮る時に、撮影前の案内画面を挟まず、追加撮影と同じように「交換したグッズを撮影してください」の確認ポップアップを出してからカメラを起動したいという指定があった。あわせて、通常撮影・追加撮影のどちらでも撮影中に左側から自分のアルバムへ入り、複数枚を選んでアップロードできるようにしたい。取引チャットのヘッダー右側には通報導線を常設したい。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 証跡撮影の初回CTAと追加撮影CTAを、同じ確認ポップアップから `/transaction-capture` へ遷移する流れに統一した。
- 以前の追加撮影だけが取引チャット内で直接カメラを開いてアップロードする処理を削除し、撮影画面へ集約した。
- 取引チャットのネイティブヘッダー右側に `通報` ボタンを追加し、`/dispute-new` へ遷移するようにした。

#### `mobile/app/transaction-capture.tsx`
- `expo-camera` の `CameraView` を使い、画面自体を実カメラとして起動するようにした。
- 撮影中の左側にアルバムボタンを表示し、最新写真のサムネイルまたはフォールバック表示を出すようにした。
- アルバムボタンから写真ライブラリを開き、複数枚を選んで順番に証跡アップロードできるようにした。
- カメラの反転、撮影済み証跡の削除、完了通知は既存フローを維持した。

#### `notes/10_glossary.md`
- `dispute` の別名に `通報` を追加し、ヘッダーの `通報` ボタンが既存の申告フローに接続することを明確化した。

### 影響範囲

- iOS版 `/transaction-detail`
- iOS版 `/transaction-capture`
- 取引チャットの証跡撮影導線
- 取引チャットの通報導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/transaction-detail.tsx mobile/app/transaction-capture.tsx notes/08_design_iterations.md notes/10_glossary.md`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/transaction-capture.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 初回撮影と追加撮影の入口を同一ポップアップに統一
- ✅ 証跡撮影画面は実カメラを直接表示
- ✅ 撮影中の左側にアルバム入口を表示
- ✅ アルバムから複数枚選択して証跡アップロード可能
- ✅ 取引チャットヘッダー右側に `通報` ボタンを追加
- ✅ 09更新診断：Deal / Dispute の状態遷移は変えないため更新不要
- ✅ 10更新診断：`dispute` の別名に `通報` を追加
- ✅ 05更新診断：既存 `proposal_evidence_photos` / `disputes` を使うためスキーマ更新不要

---

## イテレーション168.86：個別募集作成UIの条件操作整理

### 背景・問題意識

オーナーから、個別募集作成時の定価選択は「譲るもの」「求めるもの」のどちらも、独立した大きなボタンではなく「グループ」見出し行の右端に置きたいという指定があった。あわせて、複数グッズ選択時の条件表記をユーザーに伝わりやすくし、各グッズパネルではメンバー名・種別ではなく紐づくタグを見せ、個数操作はパネル外へ出したい。

### 変更内容

#### `mobile/app/listing-editor.tsx`
- 「譲るグッズ」の `グループ` 行右端に、iOS標準 `Switch` ベースの `定価` トグルを配置した。
- 「求めるもの」の各選択肢でも、`グループ` 行右端に同じ `定価` トグルを配置し、定価ON時はグループ候補を畳んで金額入力を出すようにした。
- 複数選択ロジックの表示を `全部` / `1pick` から `すべてほしい` / `どれか1つだけ` に変更した。
- グッズパネルのメンバー名・グッズ種別表示を外し、`goods_inventory_tags` / `tags_master` から取得したタグを右上に最大2件表示するようにした。
- 選択済みグッズの個数操作をパネル外の下部へ移し、個数1からマイナスを押した場合は選択解除するようにした。

#### `notes/10_glossary.md`
- 個別募集の AND / OR 条件について、画面表示名 `すべてほしい` / `どれか1つだけ` を追記した。
- 定価交換のUI表現として、個別募集作成では `グループ` 行右端の `定価` トグルで扱うことを追記した。

### 影響範囲

- iOS版 `/listing-editor`
- 個別募集作成・編集
- 個別募集の譲るもの / 求めるもの選択
- 個別募集内の定価交換オプション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/listing-editor.tsx notes/08_design_iterations.md notes/10_glossary.md`

### 関連ファイル

- `mobile/app/listing-editor.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 定価トグルは譲るもの・求めるものともに `グループ` 見出し行の右端へ移動
- ✅ トグルはReact NativeのiOS標準 `Switch` を使用
- ✅ 条件表記は `すべてほしい` / `どれか1つだけ` に変更
- ✅ パネル内のメンバー名・グッズ種別の独立表示を削除し、タグを右上表示
- ✅ 個数操作をパネル外へ移動し、1からマイナスで選択解除
- ✅ 09更新診断：個別募集の状態遷移は変えないため更新不要
- ✅ 10更新診断：個別募集条件・定価交換の表示名を更新
- ✅ 05更新診断：既存 `goods_inventory_tags` / `listing_wish_options` を使うためスキーマ更新不要

---

## イテレーション168.85：現地打診初期候補とタグ候補改善

### 背景・問題意識

オーナーから、現地交換モード ON 中にグッズ交換を依頼する際は、待ち合わせ場所に現在時刻から30分の枠と現在地を自動候補登録したいという要望があった。あわせて、グッズ登録・編集とウィッシュ追加・編集では、選択中グループに紐づく既存タグを登録件数順に候補表示し、タグ検索入力より上に丸いボタンで出したい。また、マイ在庫とウィッシュのメモ入力項目は不要になった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 現地交換モード設定を読み、`hand` / `both` の新規打診で待ち合わせ候補が未設定の場合だけ、自動候補を1件追加するようにした。
- 自動候補は現在時刻の15分スロットから30分相当を取り、GPS取得に成功した場合は現在地と逆ジオコード名、失敗時は Local Mode の前回地点または AW 地点へフォールバックする。

#### `mobile/app/goods-editor.tsx`
- 選択中グループの `goods_inventory` から既存タグを集計し、登録件数が多い順に最大10件の候補を表示するようにした。
- タグ候補をタグ検索入力欄の上に丸いボタンとして表示し、グッズ登録・編集とウィッシュ追加・編集の両方で使う `TagEditor` に統合した。
- マイ在庫 / ウィッシュのメモ入力セクションを削除し、新規作成時に hidden な note パラメータから説明文へ流れ込まないようにした。

#### `notes/09_state_machines.md`
- Local Mode のビジネスルールに、現地交換モード ON 中の打診作成時は現在時刻30分枠・現在地を待ち合わせ初期候補へ追加するルールを追記した。

### 影響範囲

- iOS版 `/proposal-select`
- iOS版 `/goods-editor`
- グッズ登録 / 編集
- ウィッシュ追加 / 編集
- Local Mode の打診作成時初期値

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/proposal-select.tsx mobile/app/goods-editor.tsx notes/08_design_iterations.md notes/09_state_machines.md`

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `mobile/app/goods-editor.tsx`
- `notes/09_state_machines.md`

### セルフレビュー結果

- ✅ 現地交換モード ON かつ現地交換を含む新規打診のみ自動候補を追加
- ✅ 手動で待ち合わせ候補がある場合や打診修正時は自動上書きしない
- ✅ タグ候補はグループ単位で登録件数順、最大10件に制限
- ✅ タグ検索入力欄の上に丸いボタンで表示
- ✅ マイ在庫 / ウィッシュのメモ入力欄を削除
- ✅ 09更新診断：Local Mode の打診初期値ルールを追記
- ✅ 10更新診断：既存用語 `タグ` / `現地交換モード` の範囲内のため更新不要
- ✅ 05更新診断：既存 `goods_inventory_tags` / `user_local_mode_settings` を使うためスキーマ更新不要

---

## イテレーション168.84：めぐりとやりとりの導線整理

### 背景・問題意識

オーナーから、フッターでは「やりとり」を右から2番目、「めぐり」を一番右にしたいという指定があった。また、`やりとり` に混在していた `めぐりあい` メッセージ一覧はめぐりホームの「メッセージ」ボタンへ移し、`やりとり` は取引一覧だけに絞る。あわせて、めぐりホーム上部のユーザーアイコン・一言・今日のレポート・今日のひとことを外し、グルーム直下に掲示板導線を強く出す。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- NativeTabs の並びを `ホーム / 在庫 / Wish / やりとり / めぐり` に変更した。

#### `mobile/app/(tabs)/transactions.tsx`
- `めぐりあい` タブとメッセージ一覧を削除し、`打診中` / `進行中` の取引一覧だけを表示する構成にした。
- めぐりメッセージ読み込み・既読処理・会話行UIは `めぐり` 側の `/meguri-letters` に集約した。

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム直下に `現地掲示板` の大きめバナーを追加し、`/meguri-board` へ遷移するようにした。
- 画面上部のめぐりユーザー表示、一言吹き出し、統計行、今日のレポート、今日のひとこと導線を削除した。
- ショートカットは `メッセージ` / `マップ` / `実績` に整理し、`メッセージ` は `/meguri-letters` を開くように維持した。

#### `mobile/app/meguri-hitokoto.tsx`, `mobile/app/meguri-report.tsx`
- 今日のひとこと画面と今日のレポート画面を削除した。

#### `mobile/app/meguri-profile-edit.tsx`, `mobile/app/meguri-profile.tsx`, `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`, `mobile/app/meguri-letters.tsx`
- 画面上に残っていた「今日のひとこと」表示・編集導線・サンプル文言を削除または公開メモ文脈へ置き換えた。

### 影響範囲

- iOS版フッタータブ順
- iOS版 `/transactions`
- iOS版 `/encounters`
- iOS版 `/meguri-letters`
- iOS版 `/meguri-board` への導線
- めぐりプロフィール表示・編集

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/(tabs)/_layout.tsx mobile/app/(tabs)/transactions.tsx mobile/app/(tabs)/encounters.tsx mobile/app/meguri-letters.tsx mobile/app/meguri-profile-edit.tsx mobile/app/meguri-profile.tsx mobile/src/components/meguri/GroomProfileSlidePanel.tsx notes/08_design_iterations.md`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/meguri-profile-edit.tsx`
- `mobile/app/meguri-profile.tsx`
- `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`
- `mobile/app/meguri-hitokoto.tsx`
- `mobile/app/meguri-report.tsx`

### セルフレビュー結果

- ✅ フッターで `やりとり` が右から2番目、`めぐり` が一番右になる順序に変更
- ✅ `やりとり` は取引一覧のみ表示
- ✅ めぐりホームの `メッセージ` から `/meguri-letters` へ遷移
- ✅ グルーム直下に掲示板バナーを追加
- ✅ 今日のレポート / 今日のひとことの画面導線と画面本体を削除
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：既存用語 `めぐりメッセージ` / `スポット掲示板` の範囲内のため更新不要

---

## イテレーション168.83：Wishタブの追従ページャー化

### 背景・問題意識

オーナーから、Wish一覧と個別募集のタブ切り替えについて、横フリック自体はできるが、フリック中の指の動きに合わせて画面も動くようにしてほしいという指摘があった。マイ在庫のタブ切り替えと同じ体験に揃え、タブを切り替える瞬間だけでなく、ドラッグ中からページとタブのつまみが追従するようにする。

### 変更内容

#### `mobile/app/(tabs)/wishes.tsx`
- 独自のタッチ終端判定によるタブ切り替えをやめ、マイ在庫と同じ `horizontal` / `pagingEnabled` の `ScrollView` ページャーに変更した。
- `SectionTabs` に `pagerPosition` を渡し、横スクロール量に合わせてタブのつまみが追従するようにした。
- タブ押下時は該当ページへアニメーションスクロールし、横フリック完了時は現在ページに合わせて選択タブを更新するようにした。

### 影響範囲

- iOS版 `/wishes`
- Wish一覧 / 個別募集のタブ切り替え
- Wish一覧 / 個別募集の横フリック操作

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/(tabs)/wishes.tsx notes/08_design_iterations.md`

### 関連ファイル

- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ マイ在庫と同じ ScrollView ページャー構造に変更
- ✅ フリック中の画面移動とタブつまみの追従に対応
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：既存用語 `Wish` / `個別募集` の範囲内のため更新不要

---

## イテレーション168.82：住所再読込と交換手段both対応

### 背景・問題意識

オーナーから、打診前の送信確認画面で住所未登録リンクから住所設定へ移動して保存しても、戻った後の「あなたの住所登録」に登録済み住所が表示されないという指摘があった。また、受け渡し方法は現地交換と郵送交換を二者択一にせず、どちらも対応可能な打診を作れるようにしたいという要望があった。

### 変更内容

#### `mobile/app/proposal-confirm.tsx`
- 送信確認画面が再フォーカスされた時に住所を再取得するようにし、住所設定から戻った直後に「あなたの住所登録」へ反映されるようにした。
- `both` の打診では、待ち合わせ候補と住所登録の両方を確認し、住所未登録時は送信前に止めるようにした。

#### `mobile/app/proposal-select.tsx`
- 交換手段を `現地交換` / `郵送交換` / `どちらもOK` の3択に変更した。
- `どちらもOK` の場合は待ち合わせタブを表示し、確認画面へ `exchangeMethod=both` を渡すようにした。

#### `mobile/src/lib/mailingAddress.ts`
- `ExchangeMethod` に `both` を追加し、現地対応・郵送対応の判定ヘルパーを追加した。

#### `mobile/app/transaction-detail.tsx`, `mobile/app/transaction-approve.tsx`
- `both` の取引で、住所表示と現地交換用の取引アクションを両方扱えるようにした。

#### `supabase/migrations/20260529184000_allow_both_exchange_method.sql`
- `proposals.exchange_method` のCHECK制約に `both` を追加した。
- `both` では待ち合わせ情報を必須にするよう、`proposals_meetup_required` を更新した。

#### `notes/05_data_model.md`, `notes/09_state_machines.md`, `notes/10_glossary.md`
- `exchange_method='both'` と、現地・郵送どちらも対応可のビジネスルールを反映した。

### 影響範囲

- iOS版 `/proposal-select`
- iOS版 `/proposal-confirm`
- iOS版 `/address-settings` から送信確認画面へ戻る導線
- iOS版 `/transaction-detail`, `/transaction-approve`
- Supabase `proposals.exchange_method` CHECK制約

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `supabase db push --yes`
- `git diff --check -- mobile/src/lib/mailingAddress.ts mobile/app/proposal-select.tsx mobile/app/proposal-confirm.tsx mobile/app/transaction-detail.tsx mobile/app/transaction-approve.tsx notes/05_data_model.md notes/09_state_machines.md notes/10_glossary.md supabase/migrations/20260529184000_allow_both_exchange_method.sql`

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/src/lib/mailingAddress.ts`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/transaction-approve.tsx`
- `supabase/migrations/20260529184000_allow_both_exchange_method.sql`

### セルフレビュー結果

- ✅ 住所設定から戻った時に送信確認画面で住所を再取得
- ✅ 現地交換・郵送交換・どちらもOKの3択に対応
- ✅ `both` は現地候補と住所登録の両方を送信前チェック対象にした
- ✅ 09更新診断：交換手段ルールに `both` を追加したため更新済み
- ✅ 10更新診断：既存用語 `交換手段` に `both` を追加したため更新済み
- ✅ 05更新診断：DB制約・カラム説明の変更があるため更新済み

---

## イテレーション168.81：マッチ詳細の初期チラつきを抑止

### 背景・問題意識

オーナーから、ホームの「マッチしてるよ！」パネルをタップすると一瞬別データが表示され、その後に正しいデータへ差し替わるため体験が悪いという指摘があった。打診導線の入口で別候補が見えると信頼感を損なうため、詳細画面では実在庫・個別募集の解決が終わるまで候補データを描画しない方針にする。

### 変更内容

#### `mobile/app/match-detail.tsx`
- URLパラメータで渡された `gives` / `receives` / `listings` のIDを解決するまで、関係図の仮組み表示を出さないようにした。
- 在庫サムネイルのカタログ解決、個別募集詳細の取得それぞれに解決キーを持たせ、前回データやプレースホルダーが一瞬描画される状態を防いだ。
- 解決中は中立のローディング表示だけを出し、フッターの打診ボタンも正しいデータ確定後に表示するようにした。

### 影響範囲

- iOS版 `/match-detail`
- ホーム「マッチしてるよ！」からのマッチ詳細表示
- マッチ詳細から打診選択へ進む導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/match-detail.tsx`

### 関連ファイル

- `mobile/app/match-detail.tsx`

### セルフレビュー結果

- ✅ 初回描画時に別候補の関係図を表示せず、ID解決後に正しいデータだけを描画
- ✅ 打診ボタンは正しい在庫・個別募集が確定するまで非表示
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：既存用語 `マッチ` / `打診` / `個別募集` の範囲内のため更新不要

---

## イテレーション168.80：相手プロフィールの公開一覧をタブ化

### 背景・問題意識

オーナーから、相手プロフィールにある譲る候補をマイ在庫と同じようにフィルタリングできるようにし、さらに相手の個別募集一覧も見られるようにしたいという指示があった。譲る候補と個別募集は、プロフィール内で横フリック切り替えでき、デザインはマイ在庫のタブ切り替えを踏襲する方針にする。

### 変更内容

#### `mobile/app/user-profile.tsx`
- 相手プロフィールの公開セクションを `譲る候補` / `個別募集` の `SectionTabs` 構成へ変更した。
- 横フリックのページャーを追加し、タップとスワイプの両方で公開一覧を切り替えられるようにした。
- 譲る候補に、マイ在庫と同じ `推し` / `種別` フィルタチップを追加した。
- 個別募集も同じフィルタに連動し、譲側の代表推し・種別で絞り込めるようにした。
- 公開中の個別募集をカード表示し、タップすると相手・対象募集を引き継いで打診選択へ進むようにした。
- 譲る候補のカードも、タップすると受け取り候補として打診選択へ進むようにした。
- Supabaseから相手の `listings` / `listing_wish_options` / 関連 `goods_inventory` を取得し、公開中の個別募集をプロフィールで表示できるようにした。

### 影響範囲

- iOS版 `/user-profile`
- 相手プロフィールからの打診導線
- 公開中の譲る候補・個別募集の表示、絞り込み、横フリック切り替え

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/user-profile.tsx notes/08_design_iterations.md`

### 関連ファイル

- `mobile/app/user-profile.tsx`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `npm --prefix mobile run export:ios:preview` 通過
- ✅ マイ在庫と同じ `SectionTabs` とフィルタチップを使用
- ✅ 個別募集と譲る候補を横フリックで切り替え可能
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：既存用語 `譲る候補` / `個別募集` の範囲内のため更新不要

---

## イテレーション168.79：Preview更新クラッシュを回避

### 背景・問題意識

Preview OTA update group `2a9a2fa0-8d06-44c5-8edf-4ba69dd6e42a` をアプリ内の `最新の更新を反映` から適用したところクラッシュした、という報告があった。直近で共通 `Screen` の非スクロール画面まで `KeyboardAvoidingView` 化しており、タブ・ホーム・チャットなど広範囲の画面構造へ影響する変更だったため、リリース前の安定性を優先して影響範囲を絞る。

### 変更内容

#### `mobile/src/components/Screen.tsx`
- `scroll={false}` の画面は従来どおり通常の `View` へ戻した。
- 住所設定などスクロール画面のキーボード追従は維持した。
- `automaticallyAdjustKeyboardInsets` は iOS のときだけ有効にし、他プラットフォームへの影響を避けた。

### 影響範囲

- iOS版の全画面共通 `Screen`
- 住所設定などのスクロール入力画面
- タブホーム・めぐりホーム・一覧・チャットなど `scroll={false}` を使う画面
- Preview OTA更新後の初回起動安定性

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/src/components/Screen.tsx`
- Preview channel OTA配信済み：Update group `2d776847-ac6d-46b8-a1f4-1094bb0012b8` / iOS update ID `019e72e3-4146-7da3-aa93-4429df08ff94`

### 関連ファイル

- `mobile/src/components/Screen.tsx`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `npm --prefix mobile run export:ios:preview` 通過
- ✅ 住所設定のスクロール画面キーボード対応は維持
- ✅ 非スクロール画面のラッパー変更を戻し、クラッシュ疑いの影響範囲を縮小
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：新規用語・廃止用語はないため更新不要

---

## イテレーション168.78：めぐりホームをプロフィールアイコン表示へ統一

### 背景・問題意識

オーナーから、めぐりホーム上部の「X人とめぐりあいました！」型のカウント訴求をなくし、専用2Dアバターではなくグッズ交換側のプロフィールアイコンを表示したいという指示があった。リリース前はめぐり専用の見せ方を増やさず、既存プロフィール情報と同じ見え方へ寄せる方針にする。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホームのステージ上部から、人数カウントと「とめぐりあいました！」文言を削除した。
- ホームの人物表示を、専用2Dアバターではなくプロフィールアイコン表示へ置き換えた。
- `avatarUrl` がある場合は画像、ない場合は交換側プロフィールと同じ頭文字アイコンを表示するようにした。
- グルーム投稿者の `avatarUrl` をめぐり側ユーザーデータへ引き継ぎ、実データではプロフィール画像を使えるようにした。
- 設定モーダルの `アイコン編集` 導線を、めぐり専用編集ではなく `/profile-edit` へ変更した。
- 既存の `WalkingCard` 利用箇所は、新しいプロフィールアイコン表示へ委譲する互換関数にした。

#### `notes/10_glossary.md`
- `めぐり住人` の定義を更新し、めぐりホームではグッズ交換側と同じプロフィールアイコンを表示する方針を追記した。

### 影響範囲

- iOS版 `/encounters` めぐりホーム
- `WalkingCard` を使うめぐり広場・レポート・シェア・ひとことプレビュー
- めぐり設定モーダルのプロフィールアイコン導線
- めぐり関連用語

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- 'mobile/app/(tabs)/encounters.tsx' notes/10_glossary.md`
- `mobile/app/(tabs)/encounters.tsx` に `出会いました` / `とめぐりあいました` / `bigCount` / `countRow` / `stageTitle` が残っていないことを確認
- Preview channel OTA配信済み：Update group `904754b1-c41e-448a-a469-f80a444ff2be` / iOS update ID `019e72dd-d74b-7c63-996f-70740c51f75e`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `npm --prefix mobile run export:ios:preview` 通過
- ✅ めぐりホーム上部の人数カウント訴求を削除
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：`めぐり住人` の定義を更新済み

## イテレーション168.77：住所設定導線と入力体験を改善

### 背景・問題意識

オーナーから、左ドロワーの設定一覧に住所設定を追加したいこと、住所設定画面で入力中の項目がキーボードに隠れないようにしたいこと、郵便番号入力から住所を自動入力したいことが指示された。郵送交換をリリース対象に戻したため、住所登録は打診送信前だけでなく、設定からいつでも管理できる必要がある。

### 変更内容

#### `mobile/app/settings-privacy.tsx`
- 設定一覧の主要項目に `住所設定` を追加した。
- 左ドロワーの `設定とプライバシー` から、住所設定へ進める導線を作った。

#### `mobile/app/address-settings.tsx`
- 住所設定画面をスクロール可能な `Screen` 構成へ戻し、キーボード表示中でも下部の項目と保存ボタンへ到達しやすくした。
- 郵便番号が7桁になったら住所検索を行い、都道府県・市区町村・町域を自動入力するようにした。
- 自動入力中 / 成功 / 未検出 / 失敗の状態文言を追加した。
- 町域まで自動入力されるため、番地入力欄のラベルを `町域・番地・建物名` に変更した。

#### `mobile/src/components/Screen.tsx`
- 共通 `Screen` のスクロール画面に `automaticallyAdjustKeyboardInsets` / `keyboardShouldPersistTaps` / `keyboardDismissMode` を設定した。
- `scroll={false}` の画面も `KeyboardAvoidingView` で包み、チャットや一覧内入力でもキーボードに隠れにくくした。
- Android は既存の `useKeyboardInset` を使って下部余白を増やすようにした。

#### `mobile/src/lib/japanPostalCode.ts`
- zipcloud 郵便番号検索APIを使う住所補完ヘルパーを追加した。
- APIの `address1 / address2 / address3` を、都道府県・市区町村・町域へ正規化して返すようにした。

### 影響範囲

- iOS版の左ドロワー `設定とプライバシー`
- iOS版 `/address-settings`
- 共通 `Screen` を使う入力画面全般
- 郵送交換前の住所登録体験

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `git diff --check -- mobile/app/address-settings.tsx mobile/src/components/Screen.tsx mobile/app/settings-privacy.tsx mobile/src/lib/japanPostalCode.ts`
- `https://zipcloud.ibsnet.co.jp/api/search?zipcode=1000001` が `東京都 / 千代田区 / 千代田` を返すことを確認
- Preview channel OTA配信済み：Update group `2a9a2fa0-8d06-44c5-8edf-4ba69dd6e42a` / iOS update ID `019e72d4-d941-756d-8e46-90921bab988c`

### 関連ファイル

- `mobile/app/settings-privacy.tsx`
- `mobile/app/address-settings.tsx`
- `mobile/src/components/Screen.tsx`
- `mobile/src/lib/japanPostalCode.ts`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `npm --prefix mobile run export:ios:preview` 通過
- ✅ zipcloud公式API仕様の `address1 / address2 / address3` と実装マッピングが一致
- ✅ 09更新診断：状態遷移の追加・削除・名称変更はないため更新不要
- ✅ 10更新診断：既存用語 `住所` / `郵送交換` の範囲内のため更新不要

## イテレーション168.76：めぐり導入演出を廃止

### 背景・問題意識

オーナーから「めぐり演出はなくしてください」と明確な指示があった。iter168.73 で3D依存は外していたが、`meguri-intro` には2Dの導入・会話・エリア解放演出が残っていたため、リリース前の不要な体験として完全に外す必要があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 導入・会話・エリア解放演出の実装を削除した。
- 既存のディープリンクや古い導線で `/meguri-intro` が開かれても、即座に `/meguri-map` へ遷移する軽量ルートへ置き換えた。

#### `notes/10_glossary.md`
- `めぐり` の定義を、演出中心ではなくマップ・掲示板・グルームを確認する入口として更新した。
- `めぐり3D演出 / めぐり演出 / めぐりイントロ` を廃止用語へ統合し、後継を `めぐり` / `めぐりマップ` / `スポット掲示板` とした。

### 影響範囲

- iOS版 `/meguri-intro` ルート
- めぐり関連の用語定義

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- Preview channel OTA配信済み：Update group `3a5c52c5-95bd-4a20-a0dc-f87125aca617` / iOS update ID `019e72c6-9c72-7e26-8bcd-d94dfd17ce40`
- iOS Previewで `/meguri-intro` を開いても演出画面が表示されず、`めぐりマップ` へ進むことを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `npm --prefix mobile run export:ios:preview` 通過
- ✅ Preview channel OTA配信済み
- ✅ 09更新診断：状態遷移の変更はないため更新不要
- ✅ 10更新診断：廃止用語を更新済み

## イテレーション168.75：Preview iOSの更新チャンネルを固定

### 背景・問題意識

オーナーから、iter168.74 の郵送交換・スポット掲示板・3D演出削除を **Megrum Preview iOS** で見られるようにしてほしいという指示があった。EAS Update 自体は `preview` ブランチに配信済みだったが、Xcode Archive で作ったPreviewバイナリ側に `preview` チャンネルを要求するヘッダーが入っていなかったため、OTA更新を拾えない可能性があった。

### 変更内容

#### `mobile/app.config.js`
- `updates.requestHeaders["expo-channel-name"]` を追加し、Preview variant では `preview`、通常variantでは `production` を見るようにした。

#### `mobile/app.json`
- iOS `buildNumber` を `9` に上げ、次回TestFlightアップロードでネイティブ設定変更を配布できるようにした。

#### `mobile/ios/MegrumPreview/Supporting/Expo.plist`（ローカル生成物）
- `EXUpdatesRequestHeaders` に `expo-channel-name = preview` を追加した。
- `mobile/ios` はgitignore対象なので、Xcode Archive用のローカル設定として反映した。

#### `mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`（ローカル生成物）
- Xcode側の `CURRENT_PROJECT_VERSION` を `9` に更新した。
- `mobile/ios` はgitignore対象なので、Xcode Archive用のローカル設定として反映した。

### 影響範囲

- Megrum Preview iOS のOTA更新取得設定
- TestFlightへ次に上げるBuild 9

### 確認方法

- `plutil -lint mobile/ios/MegrumPreview/Supporting/Expo.plist`
- `cd mobile && APP_VARIANT=preview npx expo config --json`
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- Build 9をArchiveしてTestFlightへアップロード後、Megrum Preview iOSを完全終了して再起動し、`めぐり > 掲示板` / `プロフィール > 住所設定` / `打診 > 郵送交換` を確認する

### 関連ファイル

- `mobile/app.config.js`
- `mobile/app.json`
- `mobile/ios/MegrumPreview/Supporting/Expo.plist`
- `mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`

### セルフレビュー結果

- ✅ `Expo.plist` のplist構文チェック通過
- ✅ Preview variant のExpo configで `updates.requestHeaders.expo-channel-name = preview` と `ios.buildNumber = 9` を確認
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `npm --prefix mobile run export:ios:preview` 通過
- ℹ️ 09/10更新診断：状態・用語の追加変更はないため更新不要

## イテレーション168.74：郵送交換とスポット掲示板をiOSへ実装

### 背景・問題意識

オーナーから、交換手段として **現地交換に加えて郵送交換を使えるようにしたい**、また、めぐり配下に **現地の情報共有・雑談用のスポット掲示板** を実装したいという指示があった。加えて、めぐりトップからは3D演出を外し、軽い2D導線で新機能へ入れるように整理する必要があった。リリース直前のため、既存の交換フローを大きく壊さずに、`hand / mail` の分岐と掲示板MVPを差し込む実装が求められた。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 打診作成の先頭に `現地交換 / 郵送交換` の segmented control を追加した。
- `exchange_method` を revision 読み込み・次画面遷移へ乗せ、`mail` の時は待ち合わせ候補を必須にしない分岐へ変えた。
- 郵送時の説明文を追加し、住所登録確認が次画面で行われる導線にした。

#### `mobile/app/proposal-confirm.tsx`
- `exchange_method` ごとに送信確認内容を出し分け、`mail` の時は待ち合わせカードとスケジュール共有トグルを隠すようにした。
- 送信前に `user_mailing_addresses` を読み、未登録なら送信を止めて `address-settings` 導線を出すようにした。
- `proposals.exchange_method` を insert / update へ含める互換処理を追加した。

#### `mobile/app/address-settings.tsx`
- 郵送交換用の住所設定画面を新規追加した。
- 宛名、郵便番号、都道府県、市区町村、番地、補足住所、電話番号を保存できるようにした。
- Preview / 未ログイン時はログイン導線へ分岐する。

#### `mobile/app/transaction-detail.tsx`
- proposal 読み込みに `exchange_method` と住所スナップショット列を含めた。
- 郵送交換では `MailingAddressBanner` を上部に表示し、合意前は自分の登録状況だけ、合意後は当事者同士の住所を見せるようにした。
- 郵送交換で合意する時は、双方の住所登録がそろっているか確認し、最終合意時に `sender_mailing_address / receiver_mailing_address` を proposal へ固定するようにした。
- 郵送交換の合意後は、現地交換向けの現在地・到着・服装写真クイックアクションを出さないようにした。

#### `mobile/app/transaction-approve.tsx`
- 郵送交換の取引完了確認で「場所未設定」ではなく `郵送交換` と表示するようにした。

#### `mobile/app/(tabs)/profile.tsx`
- プロフィール配下に `郵送交換 > 住所設定` の入口を追加した。

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりトップの3Dホームステージをやめ、`HomeResidentsFallback` ベースの2D表示に統一した。
- ショートカット群へ `掲示板` を追加し、`/meguri-board` へ遷移できるようにした。
- 設定メニューの `アバター編集` 表記を `アイコン編集` に変更した。

#### `mobile/app/meguri-board.tsx`
- めぐり配下のスポット掲示板一覧を追加した。
- `same_spot / same_prefecture / global` の3つの公開範囲でセクション分けし、スレ立てモーダルから投稿できるようにした。
- Preview / ローカル fallback でもスレッドが見えるようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細とチャット形式の返信UIを追加した。
- 返信送信は Supabase 優先、失敗時はローカル fallback へ保存する。

#### `mobile/src/lib/mailingAddress.ts`
- 郵送交換の共通型・住所取得・保存・整形ヘルパーを追加した。

#### `mobile/src/lib/meguriBoard.ts`
- 掲示板スレッド/返信の型、公開範囲判定、preview dataset、AsyncStorage fallback、Supabase read/write を実装した。

#### `supabase/migrations/20260529163000_add_meguri_board.sql`
- スレッド / 返信テーブル、reply count 更新 trigger、公開範囲ベースの最小 RLS を定義した。

#### `supabase/migrations/20260529170000_add_mail_exchange_support.sql`
- `user_mailing_addresses` テーブル、proposal の `exchange_method` と住所スナップショット列、郵送時の meetup 制約緩和を追加した。

#### `notes/05_data_model.md`
- `user_mailing_addresses` の実装前提を「案」から実装済み仕様へ寄せ、proposal 住所スナップショット列を追記した。

### 影響範囲

- iOS版の打診作成〜送信確認〜取引チャット〜取引完了確認
- iOS版プロフィールの設定導線
- iOS版めぐりトップ / 掲示板一覧 / 掲示板スレッド
- Supabase の proposal / postal / meguri board 関連テーブル

### 確認方法
- `npm --prefix mobile run typecheck`
- `git diff --check`
- `npm --prefix mobile run export:ios:preview`
- Preview channel OTA配信済み：Update group `e691bbdc-5ea0-4133-afb2-b0c5fb01ee4b` / iOS update ID `019e72a2-2632-70ac-a46d-2798b3ce608a`
- iOS Preview で `めぐり > 掲示板`、`プロフィール > 住所設定`、`打診 > 郵送交換` を確認

### 関連ファイル
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/app/address-settings.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/transaction-approve.tsx`
- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/lib/mailingAddress.ts`
- `mobile/src/lib/meguriBoard.ts`
- `supabase/migrations/20260529163000_add_meguri_board.sql`
- `supabase/migrations/20260529170000_add_mail_exchange_support.sql`

### セルフレビュー結果
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ Preview channel OTA配信済み。既存Previewバイナリが旧EAS project slugに紐づいているため、配信時のみclean worktree側でslug互換を合わせた
- ⏳ DB migration の適用前は、郵送交換の住所固定と掲示板の Supabase 永続化は有効にならない
- ✅ めぐりトップの3D依存は親画面側でも外し、2D導線へ整理した

## イテレーション168.73：めぐりの3D依存を2D表示へ置換

### 背景・問題意識

オーナーから、めぐり体験は残しつつ **3Dアバター / 3D演出をなくしたい** という実装指示があった。並行作業中のため、`mobile/app/(tabs)/encounters.tsx` には触れず、担当範囲の画面だけで3D依存を切り離し、既存の軽量なアバター表現へ寄せる必要があった。加えて、ユーザー向けに使わない表現の補足指示も入り、担当画面の表示テキストを自然な言い回しへ調整した。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- `MeguriThreeScene` / `MeguriThreeBoundary` 依存を外し、既存の `WalkingCard` ベースの2D導入ステージへ統一した。
- 完了導線を `/meguri-map` に合わせて「めぐりマップ」表現へ寄せた。
- fallback 文言の禁止表現を「同じ推しの人に会えて」へ置き換えた。

#### `mobile/app/meguri-plaza.tsx`
- 広場の表示を `PlazaFallback` ベースの2D一覧へ切り替え、3Dステージと読み込み境界を削除した。
- 各ユーザーのタップ対象アクセシビリティ文言を「キャラクター」ではなく「プロフィール」へ調整した。

#### `mobile/app/meguri-profile.tsx`
- 3Dアバター表示をやめ、`MeguriAvatarFace` を使った静的な公開アイコン表示へ変更した。
- プロフィールヒーロー内の見せ方を、色付きのハロー + 公開アイコン表示に整理した。

#### `mobile/app/meguri-avatar-edit.tsx`
- 3Dプレビューを廃止し、選択中のどうぶつ / 毛色が分かる2Dプレビューへ差し替えた。
- 既存の保存フローと色・どうぶつ選択UIは維持した。

#### `mobile/app/meguri-letters.tsx`
- 会話一覧の先頭アバターから `MeguriThreeScene` 依存を外し、`MeguriAvatarFace` へ統一した。
- 3D用のクリップ / ズーム用スタイルを削除した。

#### `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`
- スライドプロフィールのヒーローを `MeguriAvatarFace` ベースの2D表示へ変更した。
- 3D失敗時の fallback 分岐をなくし、公開アイコン + スタイル表示の静的UIへ整理した。

#### `notes/10_glossary.md`
- めぐり関連の用語定義から3D前提の説明を外し、現行の2D UI前提の説明へ更新した。
- 旧称として `めぐり3D演出` を廃止用語へ追加した。

### 影響範囲

- めぐり導入画面
- めぐり広場
- めぐりプロフィール
- めぐりアバター編集
- めぐりメッセージ一覧
- グルームから開くめぐりプロフィール

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Preview / Expo で `meguri-intro` / `meguri-plaza` / `meguri-profile` / `meguri-avatar-edit` / `meguri-letters` を開き、3D読み込み待ちや fallback が出ず、2Dアイコンで表示されることを確認
- 会話一覧・導入文言に禁止表現が残っていないことを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/app/meguri-profile.tsx`
- `mobile/app/meguri-avatar-edit.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 担当範囲の画面から `MeguriThreeScene` / `MeguriThreeBoundary` 依存を外した
- ✅ `MeguriAvatarFace` / `WalkingCard` を使って、めぐり体験は残したまま2D表示へ置き換えた
- ✅ ユーザー向けの禁止表現を担当範囲から除去した
- ✅ 状態追加・削除はないため `notes/09_state_machines.md` の更新は不要

---

## イテレーション168.73：めぐり掲示板MVPのiOS画面と土台を追加

### 背景・問題意識

オーナーから、めぐり配下に「現地の情報共有・雑談」向けのスポット掲示板MVPを入れたいという実装依頼があり、担当範囲として `mobile/app/meguri-board.tsx` / `meguri-board-thread.tsx` / `mobile/src/lib/meguriBoard.ts` と必要に応じた migration / notes 更新が指定された。親の `encounters.tsx` は別担当のため触らず、新規画面として差し込める形で完結させる必要があった。

### 変更内容

#### `mobile/src/lib/meguriBoard.ts`
- スポット掲示板のスレッド・返信型を追加した。
- `previewMode` / Supabase未設定 / 未ログインでも動くよう、`AsyncStorage` ベースのローカルfallbackと preview データを実装した。
- Supabase が使える時は `meguri_board_threads` / `meguri_board_replies` を読む実装を追加した。
- 公開範囲は MVP として `same_spot` / `same_prefecture` / `global` の3択にした。

#### `mobile/app/meguri-board.tsx`
- 掲示板一覧画面を追加した。
- スレッド一覧、公開範囲ごとのセクション表示、スレ立てモーダルを実装した。
- iOS標準寄せとして `SegmentedControl` で公開範囲を選べるようにした。

#### `mobile/app/meguri-board-thread.tsx`
- スレッド詳細画面を追加した。
- 元投稿をカード表示し、その下にチャット形式の返信一覧と返信 composer を実装した。

#### `supabase/migrations/20260529163000_add_meguri_board.sql`
- `meguri_board_threads` / `meguri_board_replies` と最小RLSを追加した。
- `reply_count` / `latest_reply_preview` / `latest_activity_at` を返信insertで更新する trigger を追加した。
- `same_spot` は MVP では exact spot をRLSで持たず、author / global / same prefecture をサーバー側の最小防壁にした。

#### `notes/05_data_model.md`
- 掲示板スレッドと返信テーブルを追加し、MVPの簡略化方針も明記した。

#### `notes/10_glossary.md`
- 既存の「掲示板の公開範囲」定義に、MVPの enum (`same_spot` / `same_prefecture` / `global`) を追記した。

#### `notes/13_api_spec.md`
- 掲示板一覧 / スレッド作成 / スレッド詳細 / 返信作成の draft API を追加した。
- 未確定項目を「ユーザー像」から「current spot の永続化」へ更新した。

### 影響範囲

- めぐり配下の新規掲示板体験
- preview fallback と Supabase両対応の掲示板データ層
- 掲示板MVPのデータモデル / API draft

### 確認方法

- [mobile/app/meguri-board.tsx](/Users/michitaka/Desktop/Megrum/mobile/app/meguri-board.tsx) を開き、一覧とスレ立てUIが存在することを確認
- [mobile/app/meguri-board-thread.tsx](/Users/michitaka/Desktop/Megrum/mobile/app/meguri-board-thread.tsx) を開き、チャット形式の返信UIがあることを確認
- `npm --prefix mobile run typecheck`
  - 掲示板追加分の型エラーは解消済み
  - ただし現時点では別担当差分由来で `transaction-detail.tsx` / `src/lib/mailingAddress.ts` の既存エラーが残る

### 関連ファイル

- `mobile/app/meguri-board.tsx`
- `mobile/app/meguri-board-thread.tsx`
- `mobile/src/lib/meguriBoard.ts`
- `supabase/migrations/20260529163000_add_meguri_board.sql`
- `notes/05_data_model.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 交換成立用ではなく、現地の情報共有・雑談向けの掲示板として分離できた
- ✅ preview fallback でもスレ立て・返信の最低限が動く形にした
- ✅ 新規データモデル追加があるため `notes/05_data_model.md` を更新した
- ✅ 用語の具体化があるため `notes/10_glossary.md` を更新した
- ✅ 新規状態 machine は増やしていないため `notes/09_state_machines.md` は今回更新不要
- ⚠️ `same_spot` の exact 判定は current spot 永続化が未整備のため、MVPではクライアント `spot_key` 比較 + RLSは same prefecture 近似に留めた

## イテレーション168.72：掲示板を現地スレッドとして定義

### 背景・問題意識

オーナーから、スポット掲示板は交換成立のための補助機能ではなく、**現地の情報や温度感を見たい人向け** の機能だと明確な補足があった。さらに、仕組みとしては誰でもスレッドを立てられ、参加者がチャット形式で返信できるイメージであり、スレッドごとに「この範囲の人だけ見られる」公開範囲を設定したいという要件が共有された。前段の docs では掲示板の対象ユーザー像が曖昧だったため、ここを言語化しておく必要があった。

### 変更内容

#### `notes/02_system_requirements.md`
- F5.5 として、スポット掲示板を「現地の情報共有・雑談のためのスレッド型掲示板」と定義した。
- めぐり機能の中に置くこと、誰でもスレッドを立てられること、チャット形式で返信できること、公開範囲を指定できることを追記した。

#### `notes/10_glossary.md`
- **スポット掲示板**、**スレッド**、**掲示板の公開範囲** を正式用語として追加した。

#### `notes/22_release_triage_tracker.csv`
- RL-025 を `進行中` に更新し、対象ユーザー像が「現地の情報や温度感を見たい人」で固まったことをメモした。
- RL-026 に、スレ立て + チャット形式返信 + 公開範囲指定を最小要件候補として追記した。

#### `notes/23_release_operating_guide.md`
- Decision Today の補足に、掲示板の位置づけが「交換のためではなく、現地の情報共有」だと分かる一文を追加した。

### 影響範囲

- スポット掲示板のユーザー像
- 掲示板MVPの切り方
- めぐり機能の役割整理

### 確認方法

- [notes/02_system_requirements.md](/Users/michitaka/Desktop/Megrum/notes/02_system_requirements.md) の F5.5 を確認
- [notes/22_release_triage_tracker.csv](/Users/michitaka/Desktop/Megrum/notes/22_release_triage_tracker.csv) の RL-025 / RL-026 を確認
- [notes/10_glossary.md](/Users/michitaka/Desktop/Megrum/notes/10_glossary.md) に新用語が追加されていることを確認

### 関連ファイル

- `notes/02_system_requirements.md`
- `notes/10_glossary.md`
- `notes/22_release_triage_tracker.csv`
- `notes/23_release_operating_guide.md`

### セルフレビュー結果

- ✅ 掲示板を「交換掲示板」ではなく「現地スレッド」として整理できた
- ✅ 用語追加があったため `notes/10_glossary.md` を更新した
- ✅ 状態名やDB列の追加ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` は今回この論点では追加更新不要

---

## イテレーション168.70：グルーム継続と掲示板MVP判断を反映

### 背景・問題意識

オーナーから、今回の提出スコープでは「めぐり3Dは切るが、既に実装しているグルーム（Instagramストーリー的な体験）は残す」方針と、「スポット掲示板は今回入れたいが、まだ仕様が決まっていない」という補足があった。前イテレーションの運用トラッカーでは、新規投稿体験を一律 `cut_for_now` に寄せていたため、現状の優先度とズレていた。3日で審査提出まで進めるには、既存グルームを守ることと、掲示板は仕様決定を先に置くことを明文化する必要があった。

### 変更内容

#### `notes/22_release_triage_tracker.csv`
- 既存グルーム（ストーリー投稿 / 閲覧）を「残すべき既存機能」として `must / P1` で追加した。
- スポット掲示板は、いきなり実装ではなく「MVP仕様を今日決める」を `must / P0` として追加した。
- 掲示板実装本体は `decision_pending / P1` とし、Day 1で仕様が凍結できた場合のみ着手する整理に変更した。
- リリース定義の行番号を1つ後ろへずらし、整合を保った。

#### `notes/23_release_operating_guide.md`
- Must に「既存グルームを壊さず残す」を追記した。
- `Decision Today` セクションを追加し、スポット掲示板は仕様確定の速度で採否を決める方針を明記した。
- `Cut For Now` から Instagram的な既存体験の扱いを外し、めぐり3Dのみ明確に切る整理へ変更した。
- 3日計画の Day 1 / Day 2 と、最後のおすすめ判断を最新方針に合わせて更新した。

### 影響範囲

- リリーススコープの優先順位づけ
- 既存グルーム機能の扱い
- スポット掲示板の着手条件

### 確認方法

- [22_release_triage_tracker.csv](/Users/michitaka/Desktop/Megrum/notes/22_release_triage_tracker.csv) を開き、RL-018 以降の優先度とステータスが最新方針に合うことを確認
- [23_release_operating_guide.md](/Users/michitaka/Desktop/Megrum/notes/23_release_operating_guide.md) の `Must / Decision Today / Cut For Now` が現状の意思決定に沿っていることを確認
- `git diff --check -- notes/22_release_triage_tracker.csv notes/23_release_operating_guide.md notes/08_design_iterations.md`

### 関連ファイル

- `notes/22_release_triage_tracker.csv`
- `notes/23_release_operating_guide.md`

### セルフレビュー結果

- ✅ 「既存グルームを残す」と「新規掲示板は仕様確定が先」の差をトラッカーへ落とした
- ✅ 3日間の進め方が、現実的な実行順になるよう更新した
- ✅ 状態遷移・DBスキーマ・新用語の追加ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.71：郵送交換を要件へ戻し、掲示板前段のニーズ整理を追加

### 背景・問題意識

オーナーから、現場での手渡し交換だけではなく、**郵送交換を強いユーザーニーズとして初回提出スコープへ戻したい** という判断が共有された。また、wish登録中に推し未登録へ気づいた時の戻り導線、交換しやすい場面を示すタグ、グッズ検索結果UIの整理、スポット掲示板の前段として「どんなユーザーが欲しがっているか」を先に明確化したいという要望もあった。既存ドキュメントは現地交換専用前提だったため、要件・用語・状態・データ・法務メモをまとめて更新する必要があった。

### 変更内容

#### `notes/02_system_requirements.md`
- MVP範囲を「現地交換のみ」から「現地交換を主軸にしつつ、郵送交換も選べる」へ更新した。
- F3に、wish登録中にその場から推し追加画面へ遷移できる導線を追加した。
- F4に、終演後交換OK / グッズ販売中交換OK などの交換シーンタグ要件を追加した。
- F5/F7に、郵送交換の最小ルール（待ち合わせ不要、送信前の住所確認、合意後だけ住所開示、初回は本人確認なし）を追記した。
- 設計論点に、スポット掲示板のユーザー像整理とグッズ検索結果UI整理を追加した。

#### `notes/10_glossary.md`
- 正式用語として **郵送交換**、**交換手段**、**住所**、**交換シーンタグ** を追加した。
- 「現地交換のみ」前提を廃止語側へ移し、最新方針との差分が見えるようにした。

#### `notes/05_data_model.md`
- `user_mailing_addresses` テーブル案を追加した。
- `proposals.exchange_method` と、`mail` の時は待ち合わせ必須を外す前提を追記した。
- 郵送交換の住所スナップショットや、Deal側で専用状態を切るかどうかを未確定項目へ追加した。

#### `notes/09_state_machines.md`
- Proposal Lifecycle のビジネスルールに、`hand` / `mail` の分岐と住所開示タイミングを追記した。
- Deal Lifecycle が現地交換主軸で、郵送交換の詳細状態は未確定であることを明記した。
- 未確定項目に、郵送交換専用状態と受信者住所登録の必須タイミングを追加した。

#### `notes/12_screens/C-0_propose_select.md`
- C-0 を「譲・受け取る・交換手段」の画面として再定義し、郵送選択時は待ち合わせタブを出さず住所登録確認を行う仕様へ更新した。

#### `notes/17_legal_alignment.md`
- 郵送交換を初回提出候補へ戻すと、現行の法務整理はそのままでは整合しないことを追記した。

#### `notes/13_api_spec.md`
- proposal / deal / 掲示板まわりの未確定API論点に、郵送交換と掲示板前段整理の項目を追加した。

#### `notes/22_release_triage_tracker.csv`
- 郵送交換のP0論点（交換手段、住所登録確認、合意後住所表示）を追加した。
- wishから推し追加へ戻れる導線、交換シーンタグ、グッズ検索結果UI整理を追記した。
- スポット掲示板は、いきなり仕様ではなく「欲しがるユーザー像を今日決める」を先に置く形へ更新した。

#### `notes/23_release_operating_guide.md`
- Must に郵送交換の最小導線を追加した。
- Day 1 / Day 2 の進め方に、郵送交換の仕様凍結と最小実装を追加した。

### 影響範囲

- リリーススコープ
- 打診フロー（C-0）
- 郵送交換のデータモデル
- 法務整合の前提
- 掲示板の要件定義順序

### 確認方法

- [notes/22_release_triage_tracker.csv](/Users/michitaka/Desktop/Megrum/notes/22_release_triage_tracker.csv) を開き、RL-019 以降に郵送交換・wish導線・掲示板ニーズ整理が追加されていることを確認
- [notes/02_system_requirements.md](/Users/michitaka/Desktop/Megrum/notes/02_system_requirements.md) の MVP 範囲と F3 / F4 / F5 / F7 が最新方針に沿っていることを確認
- [notes/12_screens/C-0_propose_select.md](/Users/michitaka/Desktop/Megrum/notes/12_screens/C-0_propose_select.md) の交換手段分岐を確認
- [notes/13_api_spec.md](/Users/michitaka/Desktop/Megrum/notes/13_api_spec.md) の未確定項目に郵送交換論点が増えていることを確認
- `git diff --check -- notes/02_system_requirements.md notes/05_data_model.md notes/09_state_machines.md notes/10_glossary.md notes/12_screens/C-0_propose_select.md notes/13_api_spec.md notes/17_legal_alignment.md notes/22_release_triage_tracker.csv notes/23_release_operating_guide.md notes/08_design_iterations.md`

### 関連ファイル

- `notes/02_system_requirements.md`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/12_screens/C-0_propose_select.md`
- `notes/13_api_spec.md`
- `notes/17_legal_alignment.md`
- `notes/22_release_triage_tracker.csv`
- `notes/23_release_operating_guide.md`

### セルフレビュー結果

- ✅ ユーザー要望を「実装項目」と「仕様を先に決める項目」に分けて残した
- ✅ 郵送交換を、用語・要件・データ・状態・法務メモの5箇所で同期した
- ✅ 類義語の追加があったため `notes/10_glossary.md` を更新した
- ✅ 状態ルールの追加があったため `notes/09_state_machines.md` を更新した
- ✅ データモデル変更案があったため `notes/05_data_model.md` を更新した

---

## イテレーション168.69：リリース運用トラッカーとリポジトリ地図を追加

### 背景・問題意識

オーナーから、3日でApp Store審査提出まで持っていくために、P0/P1/P2の線引きを後から見返せる表形式ファイルが欲しい、また現在のMegrumフォルダ内で「どこが何を担っているか」「GitHub / デスクトップ / サーバー / DB がどう繋がっているか」を把握したいという要望があった。リリース直前の判断速度を上げるには、バグ表と構成ガイドを先に置くのが最も効率的だと判断した。

### 変更内容

#### `notes/22_release_triage_tracker.csv`
- Excel / Numbers でそのまま開けるCSVのリリーストラッカーを追加した。
- Auth、在庫、ウィッシュ、個別条件、打診、ネゴ、取引、法的導線、TestFlight運用などの必須項目を初期行として整理した。
- めぐり3Dは今回スコープから外し、Instagram的投稿機能とスポット掲示板は `cut_for_now` / `P2` として明記した。

#### `notes/23_release_operating_guide.md`
- 今回のリリース目標を「App Store審査へ初回提出すること」と明文化した。
- `mobile/`, `web/`, `supabase/`, `Megrum/`, `notes/` など各フォルダの役割を整理した。
- GitHub とローカル作業フォルダの関係、iPhoneアプリ / Web / Supabase / EAS / App Store Connect の住み分けを説明した。
- 3日間の進め方と、オーナーがCodexへ渡すと最速で動ける情報の型をまとめた。

### 影響範囲

- リリース前の優先順位づけ
- バグトリアージ運用
- オーナーのリポジトリ把握
- Codexへの依頼フォーマット

### 確認方法

- [22_release_triage_tracker.csv](/Users/michitaka/Desktop/Megrum/notes/22_release_triage_tracker.csv) をExcelまたはNumbersで開く
- [23_release_operating_guide.md](/Users/michitaka/Desktop/Megrum/notes/23_release_operating_guide.md) を読み、フォルダ役割・インフラ説明が現在の理解と一致することを確認
- `git diff --check -- notes/22_release_triage_tracker.csv notes/23_release_operating_guide.md notes/08_design_iterations.md`

### 関連ファイル

- `notes/22_release_triage_tracker.csv`
- `notes/23_release_operating_guide.md`

### セルフレビュー結果

- ✅ リリース優先度をそのまま運用に使える表形式で置いた
- ✅ ローカル / GitHub / Supabase / Apple 側の住み分けを一箇所で確認できるようにした
- ✅ 状態遷移・DBスキーマ・新用語の追加ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.68：Preview ArchiveのBuild番号追従を修正

### 背景・問題意識

TestFlight向けに `MegrumPreview` のBuild番号を `3` へ上げたにもかかわらず、Xcode OrganizerのArchive一覧では `0.1.0 (2)` が作成され続けた。Xcode project側の `CURRENT_PROJECT_VERSION` は `3` だったが、`Info.plist` の `CFBundleVersion` が `2` で直書きされており、Archive表示・アップロード時のBuild番号が古いまま固定されていた。

### 変更内容

#### `mobile/ios/MegrumPreview/Info.plist`
- `CFBundleVersion` を `2` 直書きから `$(CURRENT_PROJECT_VERSION)` 参照へ変更した。
- `CFBundleShortVersionString` も `0.1.0` 直書きから `$(MARKETING_VERSION)` 参照へ変更し、XcodeのVersion/Build設定に追従するようにした。

#### `mobile/app.json`
- Expo設定の `ios.buildNumber` を `3` として明示し、iOSプロジェクト再生成時にもBuild番号が古い値へ戻らないようにした。

### 影響範囲

- iOS Preview Archive / TestFlight Upload のVersion/Build番号
- Xcode Organizer上のArchive表示
- Expo prebuild / iOS native project再生成時のBuild番号

### 確認方法

- `plutil -lint mobile/ios/MegrumPreview/Info.plist`
- `rg -n "CFBundleVersion|CFBundleShortVersionString|CURRENT_PROJECT_VERSION|MARKETING_VERSION" mobile/ios/MegrumPreview/Info.plist mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`
- `rg -n "\"buildNumber\"" mobile/app.json`
- Xcodeで再Archiveし、OrganizerのVersion欄が `0.1.0 (3)` になることを確認

### 関連ファイル

- `mobile/app.json`
- `mobile/ios/MegrumPreview/Info.plist`

### セルフレビュー結果

- ✅ `Info.plist` がXcode側のVersion/Build設定に追従する
- ✅ TestFlight再アップロード時に同じBuild番号 `2` を繰り返さない
- ✅ 状態遷移・DBスキーマ・新用語の変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.67：打診送信のプレビューID混入を防止

### 背景・問題意識

友達が打診送信した時に、確認画面で `invalid input syntax for type uuid: "give-1"` が表示された。`give-1` はモック/プレビュー用のIDであり、`proposals.sender_have_ids` / `receiver_have_ids` に保存できる実在庫UUIDではない。ホーム・マッチ起点で片側の実IDが空になった場合、プレビュー候補が選択状態になり、DB送信まで混ざる経路を塞ぐ必要がある。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- `partnerId` がある実送信フローでは、`give-1` などUUIDではない候補や空の片側候補をプレビュー候補で補わないようにした。
- 片側の候補が空、またはUUIDではない場合は、現在ログインユーザーと相手の `goods_inventory` から active な `for_trade` 在庫を読み直して候補化するようにした。
- 相手ID自体がUUIDではない場合はDB問い合わせに進まず、「相手情報を読み直してください」を表示するようにした。

#### `mobile/app/proposal-confirm.tsx`
- 実送信の確認画面では、候補サムネイルにプレビューIDのフォールバックを表示しないようにした。
- 送信前の在庫所有者チェックでUUID以外のIDを先に検出し、DBへ投げる前に「提示するグッズを最新の在庫から選び直してください。」を返すようにした。
- `listing_id` もUUIDの時だけ送信し、古い/プレビュー由来の値がDBエラーにならないようにした。

#### `mobile/src/data/proposalItems.ts`
- `buildProposalThumbs` に `includeFallback` オプションを追加した。
- 実在庫UUID判定用の `isUuid` helper を追加し、打診選択・確認で共通利用するようにした。

### 影響範囲

- iOSホーム/マッチ詳細/プロフィール起点の打診作成
- iOS打診送信確認画面
- TestFlight / Preview での実在庫UUIDバリデーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/proposal-select.tsx mobile/app/proposal-confirm.tsx mobile/src/data/proposalItems.ts`
- TestFlight / Preview でホームまたは相手プロフィールから打診へ進み、`give-1` などのプレビューIDが送信エラーとして露出しないことを確認
- Preview channel OTA配信済み：Update group `1690f63d-47be-4b75-9cab-cf50fb064a9f` / iOS update ID `019e7143-444d-744c-af80-e82bc0290b41`

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/src/data/proposalItems.ts`

### セルフレビュー結果

- ✅ 実送信フローでプレビューIDを候補補完に使わない
- ✅ DBへ送る前にUUID形式を確認し、Raw DBエラーをユーザーに見せない
- ✅ 状態遷移・DBスキーマ・新用語の変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.66：オンボ完了後のホーム遷移を修正

### 背景・問題意識

新規登録オンボーディング完了画面の「ホームへ」を押した時、アプリ内ホームではなく外側のホームへ戻る挙動が報告された。オンボーディング完了後は Megrum アプリ内のタブホームへ確実に遷移させる必要がある。

### 変更内容

#### `mobile/app/onboarding/done.tsx`
- 「ホームへ」ボタンの遷移先を `/` から `/(tabs)` へ変更した。
- Expo Router のタブグループを明示し、アプリ内ホームタブへ戻る意図をコード上で明確化した。

### 影響範囲

- iOS新規登録オンボーディング完了画面
- iOSアプリ内ホームへの復帰導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/onboarding/done.tsx`
- TestFlight / Preview でオンボーディング完了画面 → 「ホームへ」→ アプリ内ホームタブへ戻ることを確認
- Preview channel OTA配信済み：Update group `774c4e4d-1782-4240-8d1b-54c545cf9d17` / iOS update ID `019e7129-6d83-78c5-873e-1bdae54c716b`

### 関連ファイル

- `mobile/app/onboarding/done.tsx`

### セルフレビュー結果

- ✅ iOSアプリ内のタブホームを明示する遷移へ変更
- ✅ 状態遷移・DBスキーマ・新用語の変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.65：プロフィール打診候補を実在庫化

### 背景・問題意識

ユーザープロフィールから「この人に打診する」を押した時、`partnerId` だけで打診選択画面へ遷移していたため、私が出すもの・相手から受け取るものが固定のプレビュー候補になっていた。プロフィール起点でも、私が出すものは自分の在庫、受け取るものは相手の在庫から選ばせる必要がある。

### 変更内容

#### `mobile/app/user-profile.tsx`
- プロフィールから打診選択へ遷移する時に `partnerHandle` も渡すようにした。

#### `mobile/app/proposal-select.tsx`
- `partnerId` のみで開かれたプロフィール起点の打診では、ログインユーザーと相手ユーザーの `goods_inventory` を読み込むようにした。
- 「私が出す」は自分の `kind='for_trade'` / `status='active'` の在庫だけを候補化した。
- 「受け取る」は相手の `kind='for_trade'` / `status='active'` の在庫だけを候補化した。
- 実在庫がある時は固定プレビュー候補を混ぜず、空の場合は選択不可メッセージを出すようにした。

#### `mobile/app/proposal-confirm.tsx`
- 送信直前に、`sender_have_ids` が自分の active な譲る在庫、`receiver_have_ids` が相手の active な譲る在庫であることを検証するようにした。
- URLパラメータや古い候補が混ざった場合でも、不正な所有者のグッズを proposals に保存しないようにした。

#### `mobile/src/data/proposalItems.ts`
- 実IDが渡っている時は固定プレビュー候補を追加しないようにした。
- プロフィール起点では明示的に fallback を無効化できるようにした。

### 影響範囲

- iOSプロフィール画面からの打診作成
- iOSマッチ詳細・ホームから打診作成へ渡る実ID候補
- iOS打診送信直前の在庫所有者バリデーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check -- mobile/app/proposal-select.tsx mobile/app/proposal-confirm.tsx mobile/src/data/proposalItems.ts mobile/app/user-profile.tsx`
- 実機 / TestFlight で相手プロフィール → 「この人に打診する」→ 「私が出す」に自分の在庫、「受け取る」に相手の在庫だけが出ることを確認
- Preview channel OTA配信済み：Update group `8deafdb7-8ea6-40c5-99e1-22a902ed3bee` / iOS update ID `019e7125-8427-7c2d-80d5-d7664be76d68`

### 関連ファイル

- `mobile/app/user-profile.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/src/data/proposalItems.ts`

### セルフレビュー結果

- ✅ プロフィール起点の打診候補が実在庫由来になる
- ✅ 送信直前にも在庫所有者を検証する
- ✅ 状態遷移・DBスキーマ・新用語の変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.64：メール認証リンクをiOSアプリへ戻す

### 背景・問題意識

TestFlight版の新規登録で、メールアドレス登録後に届く確認メールをタップするとWeb側に遷移してしまうことが分かった。ユーザー向け体験はiOSアプリを正本にする方針なので、メール確認後もそのままアプリ側の認証完了画面へ戻す必要がある。

### 変更内容

#### `mobile/src/auth/redirects.ts`
- mobile認証メール用のredirect URLを生成する helper を追加した。
- Supabaseから直接custom schemeへ戻すのではなく、`https://megrum.jp/auth/callback?next=mobile&scheme=...` を経由する形にした。

#### `mobile/src/auth/AuthProvider.tsx`
- 新規登録時の `emailRedirectTo` を mobile用callback helper に変更した。

#### `mobile/app/(auth)/verify-email.tsx`
- 確認メール再送時も同じ mobile用callback に戻るよう `emailRedirectTo` を追加した。

#### `web/src/app/auth/callback/route.ts`
- `next=mobile` の場合はWeb側で認証コードを消費せず、`megrum:///auth/email-confirmed?...` へリダイレクトするようにした。
- 通常Web callbackは従来通りWeb sessionへ交換する。

### 影響範囲

- iOS新規登録メール確認
- iOS確認メール再送
- Web auth callback の mobile bridge 分岐

### 確認方法

- `npm run typecheck`
- `git diff --check`
- 確認メールリンクが `https://megrum.jp/auth/callback?next=mobile...` 経由でiOSアプリの `/auth/email-confirmed` に戻ることをTestFlightで確認

### 関連ファイル

- `mobile/src/auth/redirects.ts`
- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(auth)/verify-email.tsx`
- `web/src/app/auth/callback/route.ts`

### セルフレビュー結果

- ✅ 新規登録と再送の両方で同じiOS復帰導線を使う
- ✅ Web callback が mobile 用の認証コードを先に消費しない
- ✅ 状態遷移・DBスキーマ・用語の変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション168.63：iOSアプリ集中方針を明文化

### 背景・問題意識

オーナーから「もうiOSアプリに一点特化したい。Web版は管理者画面の実装くらいにしか使わない」という方針が改めて共有された。iter168.51 で `mobile/` 主対象の方針は入っていたが、AGENTS / Playbook / iOSロードマップ側にまだWeb版もユーザー向けに並走するよう読める記述が残っていたため、次セッションが迷わないよう正本方針として明文化した。

### 変更内容

#### `AGENTS.md`
- 「実装対象の優先方針」を追加し、ユーザー向けアプリは `mobile/` のiOSアプリに一点特化することを明記した。
- `web/` の位置付けを管理者・運用画面へ変更した。
- WebとiOSの見た目・導線の完全同期は要求せず、共通化は `packages/core/` / `packages/supabase/` を中心にする方針を追記した。

#### `CLAUDE.md`
- `web/` の説明を管理者・運用画面用途へ揃えた。

#### `notes/10_glossary.md`
- `Webアプリ版` の定義を `Web管理画面` へ更新し、通常ユーザー向けWeb版ではないことを明記した。
- `iOSアプリ版` をユーザー向け体験の主対象として再定義した。

#### `notes/20_ios_app_roadmap.md`
- ドキュメント名と目的を「iOSアプリ集中ロードマップ」に更新した。
- ユーザー向けMegrumはiOSアプリへ一本化し、Webは管理者・運用・サポート確認用途に限定する方針へ更新した。

#### `notes/14_implementation_phases.md`
- フロントエンドの正本方針として、ユーザー向け画面・導線・体験は `mobile/` のiOSアプリを正本にすることを追加した。
- 更新ログを v1.3 / iter168.63 に更新した。

#### `notes/USER_PLAYBOOK.md`
- 現在の実装方針として、ユーザー向けMegrumはiOSアプリに一点特化することを冒頭へ追加した。
- Phase 3 のフロントエンド実装を「iOSアプリ実装（主対象）」と「Web管理者・運用画面実装（必要最小限）」に分けた。

### 影響範囲

- Codex / Claude の作業判断
- オーナー向け指示テンプレ・作業ガイド
- 実装フェーズの優先順位
- 用語上のWeb版の扱い

### 確認方法

- `rg -n "iOSアプリに一点特化|Web管理画面|管理者・運用" AGENTS.md CLAUDE.md notes/10_glossary.md notes/14_implementation_phases.md notes/20_ios_app_roadmap.md notes/USER_PLAYBOOK.md`
- `git diff --check`
- `npm run typecheck`

### 関連ファイル

- `AGENTS.md`
- `CLAUDE.md`
- `notes/10_glossary.md`
- `notes/14_implementation_phases.md`
- `notes/20_ios_app_roadmap.md`
- `notes/USER_PLAYBOOK.md`

### セルフレビュー結果

- ✅ ユーザー向け実装の正本は `mobile/` / iOSアプリであることを複数の入口ドキュメントへ明記
- ✅ `web/` は管理者・運用・サポート確認用途に限定する扱いへ更新
- ✅ 状態遷移・DBスキーマの変更ではないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション168.62：旧名残存箇所の最終整理

### 背景・問題意識

オーナーから、前サービス名と旧ドメインが GitHub やサーバー設定を含めて残っていないか調べ、正式名 `Megrum` / 正式ドメイン `megrum.jp` へ完全に寄せたいという依頼があった。iter168.60〜168.61 で現行コードの多くは整理済みだったが、外部 GitHub metadata と配布用 standalone HTML に残存があったため、現行運用面まで含めて追い込み確認した。

### 変更内容

#### GitHub repository metadata
- GitHub リポジトリ名を旧リポジトリ名から `mashimabizz/Megrum_design` へ変更した。
- GitHub repository homepage を旧 Vercel URL から `https://megrum.jp` へ更新した。
- ローカル `origin` を `https://github.com/mashimabizz/Megrum_design.git` へ更新した。
- GitHub Pages は `https://mashimabizz.github.io/Megrum_design/` として再build中であることを確認した。

#### Vercel project metadata
- PR の Vercel check は成功しているが、Vercel 側 project path は旧プロジェクト名のまま残っていることを確認した。
- ローカルには有効な Vercel CLI token / `VERCEL_TOKEN` が無く、API での project rename は実行不能だった。
- Vercel dashboard 認証後に project name を `megrum` へ変更する必要がある。

#### `Megrum/Megrum Dispute Flow (standalone).html`
#### `Megrum Dispute Flow _standalone_.html`
- 展開済みバンドル内に残っていた旧サポート表記を `Megrumサポート` へ置換した。
- base64 化されたフォント/ライブラリデータ内の偶然一致が検索に出ないよう、base64 文字列を安全な改行で分割した。

#### `.claude/worktrees/`
- 旧名を大量に含む未追跡の stale 作業ワークツリーをリポジトリ作業領域から除去した。

### 影響範囲

- GitHub の公開リポジトリ名・URL
- GitHub Pages の公開URL
- ローカル git remote
- Vercel project metadata（確認のみ、rename は dashboard 認証待ち）
- 配布用 standalone HTML の表示文言
- 旧名残存検索の対象範囲

### 確認方法

- 旧名・旧ドメイン・旧GitHub名の本文検索がヒットなし
- 旧名を含むファイル名検索がヒットなし
- `git remote -v` が `https://github.com/mashimabizz/Megrum_design.git` を指すことを確認
- `gh api repos/mashimabizz/Megrum_design --jq '{full_name, html_url, homepage, has_pages}'`
- `gh api repos/mashimabizz/Megrum_design/pages --jq '{html_url, status, source}'`

### 関連ファイル

- `Megrum/Megrum Dispute Flow (standalone).html`
- `Megrum Dispute Flow _standalone_.html`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 現行リポジトリ本文・ファイル名・ローカル env 例・Supabase/Web/Mobile/Packages の旧名・旧ドメイン・旧GitHub名の残存検索はヒットなし
- ✅ GitHub リポジトリ名と homepage は `Megrum_design` / `https://megrum.jp` に更新済み
- ✅ `npm run typecheck` と `git diff --cached --check` は成功
- ⚠️ `npm --prefix web run lint` は既存の React purity / Link / image 系 lint error で失敗（今回の名称変更に起因する残存表記ではない）
- ⚠️ Vercel project path の rename は有効な Vercel 認証が無く未実施。PR check の deploy 自体は成功
- ✅ 状態遷移・業務用語・DB スキーマの変更ではないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の追加更新は不要

---

## イテレーション168.61：旧識別子を `megrum` へ統一

### 背景・問題意識

オーナーから、履歴系ファイルはそのまま残しつつ、現行コード・現行運用ドキュメント・アプリ識別子に残っている旧識別子を正式ドメイン `megrum.jp` に合わせて整理したいという依頼があった。途中で `megurum` ではなく `megrum` が正式表記だと判明したため、現行で有効な識別子だけを `megrum` へ寄せ直した。

### 変更内容

#### `mobile/app.json`
- Expo の `slug` / `scheme` を `megrum` に更新した。
- 本番 iOS の bundle identifier を `tokyo.megrum.app` に更新した。

#### `mobile/app.config.js`
- Preview 版の bundle identifier を `tokyo.megrum.app.preview` に更新した。

#### `mobile/ios/MegrumPreview/Info.plist`
- Preview の URL scheme に残っていた旧 Preview bundle ID を `tokyo.megrum.app.preview` に更新した。
- Expo の deep link scheme を `exp+megrum` に更新した。

#### `mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`
- Preview native project の `PRODUCT_BUNDLE_IDENTIFIER` を `tokyo.megrum.app.preview` に更新した。

#### `packages/design/src/index.ts`
- 旧 spacing / shadow exports を `megrumSpacing` / `megrumShadows` に改名した。

#### `web/src/components/home/HomeView.tsx`
- 旧 match detail state キーを `megrumMatchDetail` に改名した。

#### `mobile/app/(auth)/signup.tsx`
- ハンドル名プレースホルダを `megrum_xx` に更新した。

#### `mobile/app/(tabs)/profile.tsx`
#### `mobile/app/profile-edit.tsx`
- ローカル fallback ハンドル名を `megrum_user` に更新した。

#### `mobile/app/(tabs)/transactions.tsx`
- 旧サンプルパートナー名を `megrum_lily` に更新した。

#### `notes/15_non_functional.md`
- 「旧サービス名特有のリスクと前提」を `Megrum` 表記へ更新した。

#### `notes/20_ios_app_roadmap.md`
- 暫定 bundle ID の説明を `tokyo.megrum.app` に更新した。

### 影響範囲

- Expo / iOS Preview のアプリ識別子
- 現行モバイル/WEBコード内の内部キー
- 現行運用ドキュメントのブランド名・bundle ID 記載

### 確認方法

- `npm run typecheck`
- 旧ブランド名・旧識別子の残存検索（依存物・生成物・履歴スナップショットを除外）
- `npm --prefix web run lint` は既存の別件 lint error 群で失敗するが、今回追加した rename 起因の新規エラーは確認されていない

### 関連ファイル

- `mobile/app.json`
- `mobile/app.config.js`
- `mobile/ios/MegrumPreview/Info.plist`
- `mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`
- `packages/design/src/index.ts`
- `web/src/components/home/HomeView.tsx`
- `mobile/app/(auth)/signup.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/profile-edit.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `notes/15_non_functional.md`
- `notes/20_ios_app_roadmap.md`

### セルフレビュー結果

- ✅ 履歴扱いの旧モック、古い iterations、過去 migration は変更対象から外した
- ✅ 現行コード・現行ドキュメント・実運用 bundle ID / scheme は `megrum` に揃えた
- ✅ `notes/09_state_machines.md` と `notes/10_glossary.md` は状態・業務用語の変更ではないため更新不要

---

## イテレーション168.60：表示名を Megrum へ整理開始

### 背景・問題意識

オーナーから、履歴や内部IDは急がずそのままでよいが、GitHubや現行運用で目に入る旧表示名は順に `Megrum` へ寄せたいという要望があった。まずは危険な識別子変更を避けつつ、表示名や運用ガイドなど、今すぐ直しても挙動に影響しない箇所から整理することにした。

### 変更内容

#### `AGENTS.md`
- 現行サービス名として説明している箇所を旧表示名から `Megrum` に更新した。
- 用語マッピング表の見出しと、トップページ説明の `Hello Megrum` を `Hello Megrum` に更新した。

#### `CLAUDE.md`
- 現行サービス名として説明している箇所を旧表示名から `Megrum` に更新した。
- 用語マッピング表の見出しと、トップページ説明の `Hello Megrum` を `Hello Megrum` に更新した。

#### `notes/21_ios_review_guide.md`
- Development Build / 実機レビュー手順内のアプリ名表記を旧表示名から `Megrum` に更新した。
- レビュー観点の旧サービス名の用語を `Megrum` の用語に更新した。

#### `web/src/app/signup/SignUpForm.tsx`
- ハンドル名入力欄の旧プレースホルダを `megrum_xx` に更新した。

### 影響範囲

- オーナー向け運用ドキュメント
- Codex の作業ガイド
- Web サインアップ画面の表示文言

### 確認方法

- `npm --prefix web run lint -- src/app/signup/SignUpForm.tsx`
- `AGENTS.md` / `CLAUDE.md` / `notes/21_ios_review_guide.md` を開き、現行サービス名としての表記が `Megrum` へ寄っていることを確認
- Web のサインアップ画面でハンドル名プレースホルダが `megrum_xx` になっていることを確認

### 関連ファイル

- `AGENTS.md`
- `CLAUDE.md`
- `notes/21_ios_review_guide.md`
- `web/src/app/signup/SignUpForm.tsx`

### セルフレビュー結果

- ✅ 表示名だけを先に `Megrum` 化し、`slug` / `scheme` / `bundleIdentifier` など危険な内部IDには触れていない
- ✅ 実在する旧モックフォルダ名や GitHub リポジトリ名は、まだ変更していないためドキュメント上もそのまま維持した
- ✅ 状態遷移・用語定義・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.59：Previewビルド番号を 2 に更新

### 背景・問題意識

オーナーが TestFlight へ再Uploadしても、見た目が変わっていないという報告があった。調査すると、Preview用 iOS プロジェクトの `CFBundleVersion` / `CURRENT_PROJECT_VERSION` がまだ `1` 固定で、既存 build と区別できない状態だった。これでは App Store Connect / TestFlight 上で新しい build として認識しづらく、変更確認の導線が詰まりやすい。

### 変更内容

#### `mobile/ios/MegrumPreview/Info.plist`
- `CFBundleVersion` を `1` から `2` に更新した。

#### `mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`
- `CURRENT_PROJECT_VERSION` を `2` に更新した。
- `MARKETING_VERSION` を native project 側でも `0.1.0` に揃えた。

### 影響範囲

- Preview版の TestFlight 再配布
- Xcode Archive / Upload フロー

### 確認方法

- Xcode の Organizer / TestFlight 上で新しい build が `0.1.0 (2)` として見えることを確認
- その build をインストール後、トレカ一括登録の最新UIが反映されることを確認

### 関連ファイル

- `mobile/ios/MegrumPreview/Info.plist`
- `mobile/ios/MegrumPreview.xcodeproj/project.pbxproj`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ Preview版を既存 build と識別できる番号に更新した
- ✅ JS の EAS Update では解決できない TestFlight 配布問題に対して、native 側の番号を直接是正した
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.58：手動切り取りモードを分離

### 背景・問題意識

トレカAI一括登録の枠編集画面で、通常の枠選択と手動ドラッグ追加が同じレイヤーに混在していたため、意図せず選択が切り替わったり、スクロールやドラッグが競合しやすかった。オーナーから、`切り出す` を押した時だけ手動切り取りモードへ入り、そこで追加した枠が切り取りプレビューへ反映されること、通常画面では手動追加できないこと、上端の見切れも直してほしいという要望があった。

### 変更内容

#### `mobile/src/components/TradingCardBulkCropper.tsx`
- 調整フローを `adjust` と `manual` に分離し、通常画面では枠選択と角ハンドル調整だけ、`切り出す` を押した後だけ手動ドラッグ追加ができるようにした。
- 手動モードでは画像を縦いっぱいに近いサイズで表示し、ドラッグ追加専用オーバーレイに切り替えて、選択切替との競合をなくした。
- 手動モードの下部アクションを `選択枠を解除` / `角度調整に進む` に変更し、追加した枠を確認したあと結果画面へ進める流れに整理した。
- 通常調整画面の `切り取りプレビュー` 空文言を、手動追加は `切り出す` から進む前提に合わせて修正した。
- 選択中の枠削除は下部単独ボタンをやめ、`切り取りプレビュー` ヘッダー内の小さい削除アクションへ移した。
- ヘッダー上端は safe area を明示的に加味するようにして、ステータスバーと `閉じる` / タイトルが重なる状態を解消した。

### 影響範囲

- 譲るグッズ登録の「トレカ > AIで一括登録」フロー
- 手動枠追加の操作導線
- iPhone実機でのモーダル上端レイアウト

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- AI一括登録で画像選択後、通常画面では連続タップ選択と角調整だけができ、ドラッグ追加は起きないことを確認
- `切り出す` を押した後の手動モードで、画像上ドラッグにより新規枠が追加され、下部の切り取りプレビューへ反映されることを確認
- 手動モードの `角度調整に進む` から結果画面へ遷移し、回転や削除ができることを確認
- iPhone実機でモーダル上端の `閉じる` / タイトルが見切れないことを確認
- EAS Update
  - Update group: `b616cafa-1bf7-4ff1-9bb5-df5ee6011f4f`
  - iOS update ID: `019e5f5c-53b4-7ed2-a2ed-17bf6a3ab411`

### 関連ファイル

- `mobile/src/components/TradingCardBulkCropper.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 手動追加を専用モードへ分離して、通常の枠選択と競合しない構造にした
- ✅ 上端 safe area を手動で見直し、実機で見切れやすいヘッダーを補正した
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.57：Preview版に手動更新ボタンを追加

### 背景・問題意識

オーナーの iPhone で EAS Update を配信しても、アプリを閉じて開くだけでは更新が見えないケースがあった。TestFlight の自動アップデートはバイナリ更新向けであり、Expo Updates の JS 差し替えとは別経路なので、Preview版の内部確認ではアプリ側から明示的に最新更新を取りにいける手段が必要だった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- Preview variant / preview channel の時だけ、プロフィールドロワー内に `最新の更新を反映` ボタンを表示するようにした。
- ボタン押下時は `expo-updates` で `checkForUpdateAsync` → `fetchUpdateAsync` を実行し、更新があればその場で `reloadAsync` して即反映するようにした。
- 更新確認中はボタンを再押下できないようにし、右側にインジケータを表示して二重実行を防いだ。
- 更新が無い場合と通信失敗時は、原因が分かる文言を Alert で返すようにした。

#### `mobile/src/components/IconSymbol.tsx`
- ドロワー項目用に `arrow-clockwise` アイコンを追加した。

### 影響範囲

- iPhone / TestFlight での Preview確認フロー
- mobile の JS / UI 修正の受け取り手順
- プレビュー版のプロフィールドロワー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- Preview版でドロワーを開き、`最新の更新を反映` ボタンが表示されることを確認
- EAS Update 配信後にこのボタンを押し、更新がある場合にアプリが再読み込みされることを確認
- EAS Update
  - Update group: `3bc08e2f-8fa0-4774-b732-9dfdba59365f`
  - iOS update ID: `019e5f3f-e539-773f-a2b0-746abb349744`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/src/components/IconSymbol.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ Preview版にだけ露出するため、本番向けUIを汚さずに手動更新導線を追加できた
- ✅ Expo Updates の確認・取得・再読み込みをアプリ側で完結させた
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.56：mobile変更のPreview反映を運用ルールへ固定

### 背景・問題意識

オーナーは iPhone の TestFlight / Preview 版で日常的に確認しているが、こちらが mobile のJS修正を入れたあと EAS Update を流さずに完了扱いとしてしまうと、オーナー側では「直ったはずなのに見えない」状態が発生しやすい。実際、トレカ切り出しUIの改善でも、コード修正後に Preview 反映までを毎回セットで進めてほしいという要望があった。

### 変更内容

#### `AGENTS.md`
- 設計・実装変更時のチェックリストに、mobile のユーザー向け変更は Preview channel への反映まで必須とする手順を追加した。
- JS/TS変更では `export:ios:preview` → `update:ios:preview`、ネイティブ変更では EAS build が必要、という分岐も明文化した。

#### `CLAUDE.md`
- 既存の Preview更新手順に加えて、オーナーが iPhone / TestFlight を見ている時は **EAS Update 完了までを1セット** とみなす方針を追記した。

#### `notes/08_design_iterations.md`
- iter168.55 の変更を Preview channel へ EAS Update で配信した実績を確認方法へ追記した。

### 影響範囲

- 今後の mobile UI/JS修正全般
- iPhone確認フロー
- Codex / Claude の運用ルール

### 確認方法

- `AGENTS.md` と `CLAUDE.md` のチェックリストに Preview反映手順が載っていることを確認
- `npm --prefix mobile run update:ios:preview -- --message "iter168.55 トレカ切り出しドラッグ修正"` 実行済み
- EAS Update
  - Update group: `a2ce288a-486a-479e-99c9-2aa426dd7cb9`
  - iOS update ID: `019e5f34-2ec4-710b-b469-7e60f7b8e2ee`

### 関連ファイル

- `AGENTS.md`
- `CLAUDE.md`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ オーナーの実運用に合わせて、mobile変更後の Preview反映を明文化した
- ✅ ネイティブ変更と JS変更の反映手段を分けて記載した
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.55：トレカ枠編集の操作性を改善

### 背景・問題意識

トレカAI一括登録の枠編集UIで、入れ子や重なりがある検出結果を狙った方の枠に切り替えにくかった。また、編集画面では「いまの枠が実際に何を切り取るのか」が分かりづらく、縦に要素が増えたことで下部の操作ボタンまで届きにくくなっていた。切り出し後の結果画面でも不要な画像を削除できず、枠追加も四隅を後から動かす前提で手数が多かった。オーナーから、重なった枠を複数回タップして切り替えられること、枠色を黄色系に寄せること、編集中も下部に切り取り結果一覧を出すこと、結果画面でも削除できること、さらに画像上のドラッグだけで新しい枠を作れることが必要だと指摘を受けた。

### 変更内容

#### `mobile/src/components/TradingCardBulkCropper.tsx`
- 枠編集画面のタップ判定を1枚のオーバーレイに集約し、同じ場所を連続タップした時は重なっている候補枠を順番に切り替えるようにした。
- 重なり選択時は小さい枠を優先しつつ、連続タップで大きい枠にも切り替えられるよう、四角形面積で候補順を制御した。
- 枠線とハンドルの強調色を黄色系に変更し、編集中に選択中の枠が視覚的に分かりやすいようにした。
- 枠編集画面全体をスクロール可能に変更し、プレビュー追加後でも下部の削除・撮り直し・切り出し操作まで確実に到達できるようにした。
- 枠追加は専用ボタンではなく、画像の上で指を置いて引いて離すドラッグ操作で四角形を新規作成する方式へ変更した。
- ドラッグ中は黄色の点線プレビュー矩形を表示し、どの範囲が新しい枠になるか即座に分かるようにした。
- ドラッグ確定時は state の描画タイミングに依存せず ref で最終矩形を保持し、黄色い下書き枠が出たのに指を離すと消えるケースを防いだ。
- スクロール可能な調整画面でも画像上のドラッグが優先されるよう、枠作成中は親 ScrollView のスクロールを一時停止した。
- `撮り直す` / `切り出す` は写真直下へ戻し、プレビュー一覧より先に主要操作へ触れられるようにした。
- 枠編集画面の下部に、現在の枠から切り取られるプレビュー一覧を追加した。1行あたり約5枚見える密度で表示し、サムネイルを押すと該当枠を選択できる。
- 枠変更後は少し待ってからプレビューを再切り出しするようにし、角ドラッグ中の無駄な再生成を抑えた。
- 切り出し結果画面に各カードの削除ボタンを追加し、不要な画像だけ落として確定できるようにした。

### 影響範囲

- 譲るグッズ登録の「トレカ > AIで一括登録」フロー
- 枠編集の操作性
- 切り出し結果確認の精度

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS版で「譲るグッズ登録 > 種別: トレカ > AIで一括登録」を開く
- 重なった枠の中央付近を連続タップして、選択枠が切り替わることを確認
- 編集画面を縦にスクロールして、下部の操作ボタンまで到達できることを確認
- 画像上でドラッグして新しい矩形を作成できることを確認
- 編集画面下部のサムネ一覧が、現在の枠内容に応じて更新されることを確認
- 切り出し結果画面で不要なカードを削除し、そのまま確定できることを確認
- EAS Update
  - Update group: `a24ed645-2172-441c-ac00-12799d1e3164`（重なり選択 / 結果削除 / サムネ追加）
  - Update group: `a2ce288a-486a-479e-99c9-2aa426dd7cb9`（ドラッグ枠追加 / スクロール競合解消 / ボタン位置調整）

### 関連ファイル

- `mobile/src/components/TradingCardBulkCropper.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 重なり枠のタップ切り替えを、個別透明ボタンではなくポリゴン判定ベースに変更して再発しにくくした
- ✅ 枠追加をドラッグ操作へ寄せ、四隅手動調整は補助操作に後退させた
- ✅ 編集画面をスクロール構造へ変え、プレビュー追加後でも操作が埋もれないようにした
- ✅ 結果画面の削除と編集中プレビューを同じコンポーネント内で完結させ、既存ネイティブモジュール構成は維持した
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.54：workspace依存をroot lockfileで固定

### 背景・問題意識

オーナーの最新 iOS Preview build ログでも、失敗箇所は引き続き `Bundle React Native code and images` で、`main.jsbundle` 内の `OTEL_PKG` 動的 import により Hermes が `Invalid expression encountered` で停止していた。ログ中の `resolveHeadersConstructor` / `Deno` / `Headers` 周辺のコード断片を追跡したところ、これは `@supabase/supabase-js` の `2.106.x` 系が追加した tracing / OpenTelemetry 対応コードと一致した。一方、repo の `mobile/package-lock.json` は `2.105.4` を固定しており、手元の export もその版で成功している。原因は、npm workspace の root lockfile が存在しないため、EAS の monorepo install で `mobile/package-lock.json` ではなく `mobile/package.json` の semver range (`^2.105.4`) から最新 `2.106.1` が解決され、remote build だけ dependency tree が変わっていたことだった。

### 変更内容

#### `mobile/package.json`
- `@supabase/supabase-js` を `^2.105.4` から `2.105.4` に固定した。
- tracing / OpenTelemetry を含む `2.106.x` 系への意図しない自動更新を防いだ。

#### `mobile/package-lock.json`
- workspace 内の manifest と整合するよう、top-level dependency spec を `2.105.4` に揃えた。

#### `package-lock.json`
- npm workspace 用の root lockfile を新規追加した。
- EAS monorepo install でも root lockfile 経由で `mobile` / `packages/*` の dependency tree を固定し、手元と remote build の解決結果を一致させた。

### 影響範囲

- EAS iOS Preview / development / production build の npm workspace install
- mobile の Supabase SDK 版
- monorepo の再現性

### 確認方法

- 一時 workspace で root lockfile なしの `npm install --package-lock-only` を再現し、`@supabase/supabase-js` が `2.106.1` に解決されることを確認
- root lockfile 生成後に `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`

### 関連ファイル

- `mobile/package.json`
- `mobile/package-lock.json`
- `package-lock.json`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 新ログでも failure point が Swift ではなく JS bundle 生成であることを再確認
- ✅ npm workspace は root lockfile を使う前提であることと、EAS が immutable lockfile install を使うことを公式ドキュメントで確認
- ✅ `OTEL_PKG` を含む `@supabase/supabase-js 2.106.x` への drift を止める方針に絞った
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.53：EAS混入サーバー依存をnative shimへ隔離

### 背景・問題意識

iter168.52 後も、オーナーの iOS Preview build で `main.jsbundle` に `import(/* webpackIgnore: true */ /* turbopackIgnore: true */ /* @vite-ignore */OTEL_PKG)` が入り、Hermes の `Invalid expression encountered` で archive が失敗した。添付ログでは `megrum-trading-card-cropper` のSwiftビルドは通っており、失敗箇所は引き続き React Native の bundle 生成だった。EAS の install/cache 環境でのみ Next / OpenTelemetry / Vercel 系サーバー依存が解決されるケースを、Metro のパス除外だけでなく resolver レベルでも遮断する必要がある。

### 変更内容

#### `mobile/metro.config.js`
- `next` / `@next` / `@opentelemetry/*` / `@vercel/*` / `import-in-the-middle` / `require-in-the-middle` / `server-only` を、Metro の `resolveRequest` で native 用の空 shim に向けるようにした。
- `blockList` に入る前のモジュール名解決で止めることで、EAS 環境だけ root `node_modules` にサーバー依存が存在する場合でも bundle へ実体コードが入らないようにした。
- `@megrum/*` workspace alias と `mobile/node_modules` 優先解決は維持した。

#### `mobile/src/shims/serverOnlyModule.js`
- OpenTelemetry / Vercel系の代表的な named export を no-op で返す shim を追加した。
- サーバー専用コードが誤って読み込まれても、Hermes 非対応の dynamic import 構文を含む実体ファイルへ進まないようにした。

### 影響範囲

- EAS iOS Preview / development / production build のMetroバンドル生成
- EAS cache や root `node_modules` に依存したサーバー専用パッケージの混入防止

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 生成された `main.jsbundle` と `mobile/dist` に `OTEL_PKG` / `webpackIgnore` / `turbopackIgnore` / `@opentelemetry` が混入していないことを `rg` で確認

### 関連ファイル

- `mobile/metro.config.js`
- `mobile/src/shims/serverOnlyModule.js`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 添付XcodeログでSwift local moduleではなくJS bundle生成が失敗していることを再確認
- ✅ サーバー専用依存を mobile bundle に入れない対策を resolver レベルへ強化
- ✅ ユーザー向け mobile 主対象・web 管理画面方針と整合
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.52：EAS mobile buildからweb依存を分離

### 背景・問題意識

iter168.50 で Metro の監視対象から `web/` と Next 系パッケージを除外したが、オーナーの iOS Preview build では引き続き `main.jsbundle` に Next / OpenTelemetry 由来の `OTEL_PKG` 動的 import が混入して archive が失敗した。EAS の build 環境では root workspace install により `web` workspace の Next 依存が入るため、Metro側の除外だけでなく install対象からも `web` を分離する必要がある。

### 変更内容

#### `package.json`
- root `workspaces` から `web` を外し、EAS の mobile build install で Next / React DOM / web 管理画面依存を入れないようにした。
- `web` は管理者画面用途として残し、従来通り `npm --prefix web ...` または `cd web` で個別に扱う方針にした。
- `mobile` と `packages/*` は root workspace に残し、mobile build と共通ロジック利用は維持した。

### 影響範囲

- EAS iOS Preview / development / production build の依存インストール
- root workspace install の対象
- web 管理画面の運用方法（root workspace経由ではなく `web/` 個別）

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 生成された `main.jsbundle` と `mobile/dist` に `OTEL_PKG` / `next/dist` / `opentelemetry` が混入していないことを `rg` で確認

### 関連ファイル

- `package.json`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ ユーザー向け主対象が `mobile/` になった方針と整合
- ✅ `web` を削除せず、管理者画面として個別運用できる状態を維持
- ✅ mobile build に必要な `mobile` / `packages/*` workspace は維持
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.51：mobile主対象・web管理画面方針へ更新

### 背景・問題意識

オーナーから、今後はWebアプリをほとんど使わない予定であり、ユーザー向け更新対象から外してよいこと、ただしWebは管理者画面として使う想定があることが共有された。これにより、今後の実装・Preview反映・セルフレビューの主対象を iOS / mobile に寄せ、Webへの横展開を前提にしない運用へ整理する必要がある。

### 変更内容

#### `CLAUDE.md`
- ユーザー向けアプリの主対象を `mobile/`（React Native + Expo / iOS）と明記した。
- `web/` は通常のユーザー向け更新対象から外し、管理者画面・運用画面・法務/サポート確認画面として必要な場合だけ更新する方針を追加した。
- mobile のユーザー向け変更では Preview channel / EAS build 反映要否を確認し、web 管理画面だけの変更では iOS Preview 更新不要とした。

#### `notes/14_implementation_phases.md`
- フロントエンド担当範囲を iOS mobile 主体、Web Next.js は管理者画面用途へ更新した。
- Web/iOS の完全同期を未確定項目から外し、共通ロジックは `packages/*` に寄せつつ見た目・導線の完全同期は要求しない方針を追記した。

### 影響範囲

- 今後のユーザー向けUI実装・修正の対象判断
- Preview channel / EAS build 反映判断
- Web版の位置づけ（ユーザー向け同等画面ではなく管理者・運用画面）

### 確認方法

- ドキュメント差分確認

### 関連ファイル

- `CLAUDE.md`
- `notes/14_implementation_phases.md`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ mobile をユーザー向け主対象にする方針を明記
- ✅ web を管理者画面・運用画面用途として残す方針を明記
- ✅ Preview反映ルールと矛盾しないよう、web管理画面のみの変更は iOS Preview 更新不要と整理
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.50：PreviewビルドのMetro混入を防止

### 背景・問題意識

オーナーがトレカAI一括登録を試すために iOS Preview build を実行したところ、Swift local module 自体はコンパイルされたものの、React Native のJSバンドル生成で `Invalid expression encountered` が発生した。ログ上では `main.jsbundle` に Next / OpenTelemetry 由来の `import(/* webpackIgnore: true */ /* turbopackIgnore: true */ OTEL_PKG)` 形式のコードが混入しており、Hermes がその動的 import を解釈できず archive が失敗していた。

### 変更内容

#### `mobile/metro.config.js`
- Expo/Metro の自動 workspace 検出で `web/` が `watchFolders` に含まれていたため、mobile のMetro対象から明示的に除外した。
- EAS の workspace install で root `node_modules` に web 側の Next 系依存が同居しても拾わないよう、`next` / `@next` / `@opentelemetry` / `@vercel` を blockList に追加した。
- mobile から使う workspace package は従来通り `@megrum/core` / `@megrum/design` / `@megrum/supabase` の alias で解決する構成を維持した。

### 影響範囲

- iOS Preview / development / production build のMetroバンドル生成
- mobile のworkspace package解決
- トレカAI一括登録を含む次回EAS native build

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 生成された `main.jsbundle` と `mobile/dist` に `OTEL_PKG` / `next/dist` / `opentelemetry` が混入していないことを `rg` で確認

### 関連ファイル

- `mobile/metro.config.js`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ EASログ上の失敗箇所がSwift local moduleではなくJSバンドル生成であることを確認
- ✅ `web/` をMetroの監視対象から外し、Nextサーバー用コードがmobileバンドルへ混入しないようにした
- ✅ mobile側のExpo Router依存解決を壊さないよう、nested dependency解決は維持
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ 状態遷移・用語・データモデルの変更はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要

---

## イテレーション168.49：トレカAI一括登録を追加

### 背景・問題意識

オーナーから、譲るグッズ登録で種別「トレカ」を選んだ場合、写真選択画面に `トレカ専用 AIで一括登録` ボタンを設け、複数トレカを1枚の写真から端末内で検出・切り出しできるようにしたいという指示があった。サーバー通信やOpenCV等の外部ライブラリは使わず、iOS純正の Vision / Core Image で完結させる必要がある。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 譲るグッズ新規登録フローで、選択したグッズ種別が `トレカ` の場合だけ写真ステップに `トレカ専用 AIで一括登録` ボタンを表示するようにした。
- AI一括登録で生成された切り出し画像を、既存の複数写真登録と同じ `goods_inventory.photo_urls` 登録フローへ流し込むようにした。

#### `mobile/src/components/TradingCardBulkCropper.tsx`
- 撮影/ライブラリ選択、撮影ガイド、検出中ローディング、検出枠プレビュー、四隅ドラッグ調整、不要枠削除、手動枠追加、切り出し後サムネイル確認、90度回転補正、確定導線を追加した。
- ネイティブモジュール未組み込みの既存ビルドでは、その旨を画面内で案内するフォールバック文言を出すようにした。

#### `mobile/src/lib/tradingCardCropper.ts`
- React Native側から `detectCardsAsync` / `cropCardsAsync` / `rotateImagesAsync` を呼べる薄いラッパーを追加した。
- 将来のReact Native Bridge公開に備えて、入力画像パス→切り出し済み画像パス配列の単位で扱えるAPIにした。

#### `mobile/modules/trading-card-cropper/`
- Expo local module として `TradingCardCropperModule` を追加した。
- iOS Vision `VNDetectRectanglesRequest` の設定値を定数化した。
  - `maximumObservations = 30`
  - `minimumAspectRatio = 0.6`
  - `maximumAspectRatio = 0.85`
  - `minimumSize = 0.05`
  - `minimumConfidence = 0.6`
  - `quadratureTolerance = 20`
- Visionの左下原点・正規化座標を、RNプレビューで扱う左上原点・正規化座標へ変換して返すようにした。
- 確定枠を `CIPerspectiveCorrection` で透視補正し、JPEGとして端末キャッシュへ保存する処理を追加した。
- 切り出し後の90度単位回転保存を追加した。

#### `notes/02_system_requirements.md`
- F1在庫登録の写真撮影UXに、トレカAI一括登録の要件を追記した。

#### `notes/10_glossary.md`
- `トレカAI一括登録` をグッズ関連用語として追加した。

### 影響範囲

- iOS版 譲るグッズ新規登録フロー
- グッズ種別 `トレカ` の写真登録体験
- iOSネイティブビルド（Expo local module追加のため、EAS Updateだけではネイティブ処理は反映されない）

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npx --prefix mobile expo-modules-autolinking search --platform apple --project-root mobile`
- `EXPO_NO_GIT_STATUS=1 npm --prefix /tmp/megrum-preview-update-16849/mobile run update:ios:preview -- --message "[iter168.49] トレカAI一括登録を追加" --non-interactive`
- EAS Update: `019e5e2e-3458-7831-a2e3-896afff80ef1`
- EAS Update group: `6bf781bd-24cf-4b3a-b8f5-9bb5b2a1b29f`
- iOSネイティブビルドは未実行（このリポジトリには生成済み `ios/` がないため、実機検証には次回EAS development/preview buildが必要）

### 関連ファイル

- `mobile/app/goods-editor.tsx`
- `mobile/src/components/TradingCardBulkCropper.tsx`
- `mobile/src/lib/tradingCardCropper.ts`
- `mobile/modules/trading-card-cropper/`
- `notes/02_system_requirements.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ `トレカ` 種別選択時のみ専用AI一括登録ボタンを表示
- ✅ 検出枠の四隅ドラッグ、削除、手動追加、切り出し後90度回転を実装
- ✅ Vision/Core Image処理をSwift local moduleへ分離し、RN側UIと処理を分離
- ✅ 検出0件時に手動枠追加へ誘導する文言を追加
- ✅ サーバー通信なしで端末内処理する設計
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Expo autolinkingでlocal module検出を確認
- ✅ Preview channel へ EAS Update 済み（UI導線の確認用。Swift処理は次回ネイティブビルドが必要）
- ⚠️ ネイティブSwiftの実機ビルド/実カード写真検証は次回EAS buildで確認が必要
- ✅ 状態遷移名の追加はないため `notes/09_state_machines.md` 更新不要

---

## イテレーション168.48：めぐりメッセージUIを精緻化

### 背景・問題意識

オーナーから、めぐりPlusのボトムシート表示時に黒い半透明背景まで下から上がってくるのが不自然、無料会員向けロックメッセージは「何かしら書かれている」ことが分かるモザイクにしたい、CTAの折り返しをなくしたい、期限切れグルーム画像の空白を詰めたい、会話一覧アイコンを3Dアバターそのものに近づけたい、という指摘があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりPlusモーダルを `animationType="fade"` に変更し、黒い半透明背景は全画面でフェード表示するようにした。
- ボトムシート本体だけを `Animated.View` で下からスライドさせ、背景とシートの動きを分離した。

#### `mobile/app/meguri-letters.tsx`
- ロック済み相手メッセージの泡に、本文があることを示す淡いテキスト行風モザイクを追加した。
- `メッセージを開封する` CTA は `numberOfLines={1}` / `adjustsFontSizeToFit` で折り返しを防ぎ、横長のボタン幅にした。
- グルーム返信添付の文言を `この人のグルームに返信しました` に変更した。
- グルーム画像URLがない、または読み込みに失敗した場合は添付ブロック自体を畳み、送信メッセージとの余白が残らないようにした。
- めぐりあいメッセージ一覧のアイコンを、2D簡易フェイスから小さな3Dアバターサムネに変更した。3Dが使えない場合のみ2Dフェイスへフォールバックする。

### 影響範囲

- めぐりPlusボトムシート
- 無料会員向けロック済み相手メッセージ表示
- グルーム返信添付表示
- めぐりあいメッセージ一覧アイコン

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.48] めぐりメッセージUIを精緻化" --non-interactive`
- EAS Update: `019e5dea-d68f-7f8b-b9b8-e675f72dc524`
- EAS Update group: `45e837a6-3007-49e0-8b56-2d5675019c39`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 背景フェードとボトムシートスライドを分離
- ✅ ロック泡に本文の存在が分かるテキスト行風モザイクを追加
- ✅ CTAの折り返し防止を追加
- ✅ 期限切れ/読み込み失敗グルーム画像の空白を畳むように変更
- ✅ グルーム返信文言を修正
- ✅ 会話一覧アイコンを3Dサムネへ変更（3D不可時は2Dフォールバック）
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Preview channel へ EAS Update 済み

---

## イテレーション168.47：めぐりロック泡を再レビュー調整

### 背景・問題意識

オーナーから「貼った画像のデザインと今のものとを自分で見比べて、レビューして、直して」と指示があった。iter168.46 の実装は方向性は合っていたが、参考画像と比べるとロック泡が大きく、CTAが太く、時刻が下端より少し上に浮いていた。また、相手アイコンも参考画像より大きく見え、泡との比率が崩れていた。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- ロック泡を参考画像の比率に近い 216pt 幅 / 96pt 高へ縮小した。
- CTA を約 172pt 幅 / 38pt 高になるよう内側余白を調整した。
- CTA フォントを少し下げ、影も控えめにして参考画像の軽さへ寄せた。
- 受信時刻の下余白を詰め、泡の右外・下端近くに表示されるようにした。
- 相手アイコンを 36pt から 30pt に縮小し、ロック泡との比率を参考画像寄りにした。

### 影響範囲

- iOS版 めぐりメッセージ会話スレッド
- 無料会員時のロック済み相手メッセージ表示
- 受信メッセージの時刻・相手アイコン表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.47] めぐりロック泡を再レビュー調整" --non-interactive`
- EAS Update: `019e5dcc-7b49-70ba-9d5e-0e8f7ddf23a3`
- EAS Update group: `efc2f725-1383-4122-9362-6235f438dca7`

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 参考画像に対して泡サイズ・CTAサイズ・時刻位置を再比較して調整
- ✅ 受信アイコンを縮小し、参考画像に近いバランスへ変更
- ✅ 状態名・用語追加はないため `09` / `10` 更新不要
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Preview channel へ EAS Update 済み

---

## イテレーション168.46：めぐりロック泡を参考UIへ調整

### 背景・問題意識

オーナーから参考画像付きで、無料会員の相手メッセージのモザイク/ロック表示を、薄い水色の角丸泡と中央CTAの見た目に寄せたいと指示があった。あわせて、送信日時をメッセージ泡の右外・下揃えに表示したいという要望があった。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- 無料会員向けのロック済み相手メッセージを、薄い水色の大きな角丸泡に変更した。
- ロック泡中央にターコイズの `メッセージを開封する` CTA を配置し、CTAタップで従来どおりめぐりPlus導線を開くようにした。
- 受信メッセージの時刻表示を、泡の右外側・下揃えに出る横並びレイアウトへ変更した。

### 影響範囲

- iOS版 めぐりメッセージ会話スレッド
- 無料会員時のロック済み相手メッセージ表示
- 受信メッセージの時刻表示位置

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.46] めぐりロック泡を参考UIへ調整" --non-interactive`
- EAS Update: `019e5dc1-519c-7d47-b9e2-ec896b663d9e`
- EAS Update group: `845431b9-d92c-4b85-a860-6a0364510653`

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 参考画像に合わせて、ロック済み相手メッセージを薄い水色泡 + ターコイズCTAへ変更
- ✅ CTA文言を `メッセージを開封する` に変更
- ✅ 受信メッセージの時刻を泡の右外・下揃えに変更
- ✅ 状態名・用語追加はないため `09` / `10` 更新不要
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Preview channel へ EAS Update 済み

---

## イテレーション168.45：めぐりPlusレビュー切替を常時表示

### 背景・問題意識

オーナーから「一度Plus会員に切り替えた後、無料会員に切り替えるボタンがない」と指摘があった。iter168.43 では `michilion` アカウント限定の切替ボタンをPlusモーダル内に置いていたが、Plus会員状態では本文ロックが解除されるため、通常操作ではPlusモーダルへ戻る入口が消えてしまっていた。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- `michilion` アカウントでは、めぐりメッセージ一覧ヘッダー右側にレビュー用の切替ピルを常時表示するようにした。
- めぐりメッセージの会話スレッドヘッダー右側にも同じ切替ピルを表示するようにした。
- Plus会員状態では `無料へ`、無料状態では `Plusへ` と表示し、どちらの状態からでも1タップで切り替えられるようにした。

### 影響範囲

- iOS版 めぐりメッセージ一覧
- iOS版 めぐりメッセージ会話スレッド
- `michilion` 限定の開発レビュー導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.45] めぐりPlusレビュー切替を常時表示" --non-interactive`
- EAS Update: `019e5dac-ec16-778b-aeae-564786347117`
- EAS Update group: `5967a5c3-7280-4a97-a1f2-23c3f581f21a`

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ Plus会員状態でも無料会員へ戻す入口を常時表示
- ✅ 表示対象は `michilion` のレビュー用アカウントに限定
- ✅ 状態名・用語追加はないため `09` / `10` 更新不要
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Preview channel へ EAS Update 済み

---

## イテレーション168.44：めぐりPlus送信枠を20通化

### 背景・問題意識

オーナーから「めぐりPlusは月20通まで新規のユーザーに送れるように」「無料会員の際のメッセージが届いている時、相手からのメッセージにモザイクをかけるように」と指示があった。iter168.43 ではめぐりPlus送信枠を月8通としていたが、レビュー時の期待値は月20通だった。また、無料会員のロック済みスレッドでは本文を伏せていたものの、会話泡としては「メッセージが届いています！」という通常テキストに見えており、開封前の秘匿感が弱かった。

### 変更内容

#### `mobile/src/lib/meguriPlus.ts`
- めぐりPlusの月間送信枠を 8 通から 20 通へ変更した。
- 月ごとの送信使用数を `AsyncStorage` に保存し、無料/Plusのどちらでも同じ月次カウンタで残数を計算するようにした。

#### `mobile/app/meguri-letters.tsx`
- めぐりPlus会員でも月20通を超えた場合は送信欄をロックし、残数表示を月20通基準にした。
- 無料会員で相手から届いたロック済みメッセージは、本文テキストではなく細かいモザイクブロック付きの泡として表示するようにした。
- モザイク泡内の「めぐりPlusで開封」から従来のめぐりPlusモーダルへ遷移できるようにした。

#### `mobile/app/meguri-plus.tsx` / `mobile/app/(tabs)/encounters.tsx`
- めぐりPlusの訴求文言を「新規メッセージ月20通」に更新した。

#### `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/16_monetization.md`
- めぐりPlusの送信枠を月20通として仕様文言を更新した。

### 影響範囲

- iOS版 めぐりPlus画面
- iOS版 めぐりメッセージ一覧・スレッド
- めぐりPlusの送信枠表示・送信ロック
- めぐりメッセージの無料会員向けロック表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.44] めぐりPlus送信枠を20通化" --non-interactive`
- EAS Update: `019e5da0-329b-7a3f-aaec-69c209f2ed9c`
- EAS Update group: `8aa06de6-43a2-42cd-b89c-9f78307eb548`

### 関連ファイル

- `mobile/src/lib/meguriPlus.ts`
- `mobile/src/lib/meguriSettings.ts`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/meguri-plus.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/16_monetization.md`

### セルフレビュー結果

- ✅ めぐりPlus送信枠を月20通へ変更
- ✅ 無料会員の相手メッセージを通常テキストではなくモザイク泡で表示
- ✅ 状態遷移・用語集・マネタイズ文書の送信枠記述を更新
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Preview channel へ EAS Update 済み

---

## イテレーション168.43：めぐりPlus権限を実装

### 背景・問題意識

オーナーから「めぐりに関する有料プランについて機能実装」「Megrum Plusではなく、めぐりPlusという名前に変更」「開発中は、michilionのアカウントでのみ、Plus会員か無料会員かをボタン１つで切り替え」と指示があった。既存実装はローカル `AsyncStorage` の擬似Plus切替で、無料送信枠も仕様上の月2通ではなく月3通になっていた。また、めぐりメッセージ本文がDBから直接取得できる構造のままだったため、本番課金前に `premium` とは分離した `meguri_plus` 権限へ整理する必要があった。

### 変更内容

#### `mobile/src/lib/meguriPlus.ts`
- めぐりPlus判定を `user_entitlements(feature_key='meguri_plus')` へ分離した。
- `michilion` アカウントだけが使えるレビュー用ローカル上書きを追加した。
- 無料送信枠を月2通、めぐりPlus送信枠を月8通として定数化した。

#### `mobile/app/meguri-plus.tsx` / `mobile/app/meguri-letters.tsx` / `mobile/app/(tabs)/encounters.tsx`
- ユーザー向け名称を `めぐりPlus` に統一した。
- Plus判定をローカル擬似設定から `meguri_plus` 権限 + `michilion` 限定レビュー上書きへ差し替えた。
- `michilion` では1ボタンで「めぐりPlus会員 / 無料会員」を切り替えられるようにした。
- 無料送信枠を月2通に戻し、3通目以降はめぐりPlus導線へ出すようにした。

#### `mobile/src/lib/meguriMessages.ts` / `supabase/migrations/20260525052000_add_meguri_plus_entitlement.sql`
- `list_meguri_messages_for_viewer()` RPC を追加し、無料受信者には本文・画像パスを返さずロック済みメタ情報だけ返すようにした。
- `meguri_messages` の直接SELECTは、送信者本人または `meguri_plus` 有効な受信者に限定した。
- `meguri-message-media` の画像閲覧も同じ権限判定へ寄せた。
- `subscriptions.plan_type` に `meguri_plus_monthly` を追加した。

#### `web/src/app/api/stripe/webhook/route.ts`
- Stripe webhookで `plan_type='meguri_plus_monthly'` の場合は `user_entitlements(feature_key='meguri_plus')` を更新するようにした。
- 既存Premium系は引き続き `feature_key='premium'` を更新する。

#### 法務・仕様ドキュメント
- 特商法表示に `めぐりPlus：月額¥1,000` を追加した。
- `notes/05_data_model.md` / `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/13_api_spec.md` / `notes/16_monetization.md` / `notes/17_legal_alignment.md` / `notes/21_oshi_encounter_strategy.md` を更新した。

### 影響範囲

- iOS版 めぐりPlus画面
- iOS版 めぐりメッセージ一覧・スレッド
- めぐりメッセージ本文/画像のRLS・RPC
- Stripe webhookの有料権限反映
- 特商法表示、マネタイズ、API、データモデル、状態遷移、用語集

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.43] めぐりPlus権限を実装" --non-interactive`
- EAS Update: `019e5d7e-da8f-7c0a-8cfc-c55143877c13`
- EAS Update group: `633f3914-485a-42fb-a1e9-3a50b6f0165e`
- `npm --prefix web run lint -- src/app/api/stripe/webhook/route.ts src/app/legal/notice/page.tsx`
- `supabase db push --dry-run`
- `supabase db push --yes`

### 関連ファイル

- `mobile/src/lib/meguriPlus.ts`
- `mobile/src/lib/meguriPlusPurchase.ts`
- `mobile/app/meguri-plus.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/lib/meguriMessages.ts`
- `supabase/migrations/20260525052000_add_meguri_plus_entitlement.sql`
- `web/src/app/api/stripe/webhook/route.ts`
- `mobile/app/legal/notice.tsx`
- `web/src/app/legal/notice/page.tsx`
- `Megrum/legal-pages.jsx`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`
- `notes/16_monetization.md`
- `notes/17_legal_alignment.md`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ ユーザー向け名称を `めぐりPlus` に統一
- ✅ `premium` と `meguri_plus` を分離
- ✅ 無料送信枠を月2通へ修正
- ✅ `michilion` 限定の1ボタン切替を実装
- ✅ 無料受信者へ `meguri_messages` 本文/画像パスを直接返さないRPC/RLSへ変更
- ✅ 特商法表示にめぐりPlus月額¥1,000を追加
- ✅ モバイル型チェック成功
- ✅ iOS Preview export 成功
- ✅ Preview channel へ EAS Update 済み
- ✅ Web対象ファイルlint成功
- ✅ Supabase migration dry-run / remote push 成功

---

## イテレーション168.42：推し分類切替を即時化

### 背景・問題意識

オーナーから、推し追加モーダル下部の分類ボタン（K-POP男性など）を押した時に「少しラグがあってその分類の画面に切り替わる」と指摘があった。また、L1候補カードのメタ表示で `TXT / K-POP男性 / グループ / 5メンバー` のように大分類名が出ているが、分類タブで文脈は分かるため不要との指示があった。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 分類チップタップ時のページ移動をアニメーション付き横スクロールから即時ジャンプに変更した。
- L1候補カードのメタ表示から大分類名を外し、`グループ / 5メンバー` のように表示するようにした。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- Web/PWA側の同等モーダルでも、L1候補カードのメタ表示から大分類名を外した。

### 影響範囲

- iOS版 推し設定の「推しを追加」モーダル
- Web/PWA版 推し設定の「推し追加」モーダル
- L1候補カードのメタ表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix web run lint -- src/app/profile/oshi/OshiEditView.tsx`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.42] 推し分類切替を即時化" --non-interactive`
- EAS Update: `019e5d31-f8c7-7e68-aa23-e00938fb8c17`
- EAS Update group: `02d4d4de-f175-434b-940e-d8cbb353b138`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 分類チップタップ時の横スクロールアニメーションを停止し、即時切替に変更
- ✅ L1候補カードから大分類名表示を削除
- ✅ モバイル型チェック成功
- ✅ Web/PWA対象ファイルlint成功
- ✅ Preview channel へ EAS Update 済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.41：推し追加検索欄のキーボード被りを解消

### 背景・問題意識

オーナーから、推し追加モーダルで検索入力欄をタップした時に「微妙に入力欄がキーボードに隠れてしまっている」と指摘があった。分類チップはキーボード上に見えていたが、検索入力欄の下端がキーボード上端に食われており、入力中の視認性が落ちていた。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し追加モーダルでキーボード表示状態を監視するようにした。
- キーボード表示中だけ検索ドックの下余白を追加し、検索入力欄がキーボード上端から離れて表示されるようにした。
- 複数選択時の固定「登録」ボタンも、追加した下余白に追従するようにした。

### 影響範囲

- iOS版 推し設定の「推しを追加」モーダル
- 推し追加モーダルの検索入力フォーカス時レイアウト
- 複数選択時の固定登録ボタン位置

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.41] 推し追加検索欄のキーボード被りを解消" --non-interactive`
- EAS Update: `019e5d2b-ad02-7ae0-9752-8ffbf327b1c9`
- EAS Update group: `32e5bad7-760e-41bf-af3e-1f447a5ddc6b`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ キーボード表示中のみ検索ドックの下余白を増やす
- ✅ 非表示時の通常レイアウトは維持
- ✅ 登録ボタン位置も追加余白へ追従
- ✅ モバイル型チェック成功
- ✅ Preview channel へ EAS Update 済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.40：推しL2取得をページング化

### 背景・問題意識

K-POP男性L2を追加したにもかかわらず、画面上で増えているように見えないと指摘があった。実DBでは `SHINee` に `ジョンヒョン` を含む5件が登録されていたが、`characters_master` が2825件まで増えたことで、推し設定画面のL2全件取得がSupabase/PostgRESTのデフォルト上限1000件に引っかかり、画面側の候補数が途中で欠ける状態になっていた。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- `characters_master` の取得を単発selectから1000件単位の `.range()` ページング取得へ変更した。
- 推し追加モーダルと推しメンバー追加で、増えたL2マスタを全件使えるようにした。

#### `web/src/app/profile/oshi/page.tsx`
- Web/PWA側の推し設定でも同じページング取得に変更した。
- 既存のL1/L2集約ロジックは維持し、取得漏れだけを解消した。

### 影響範囲

- iOS版 推し設定/推し追加画面
- Web/PWA版 推し設定/推し追加画面
- L2名検索とメンバー数表示

### 確認方法

- `supabase db query --linked -o table "select count(*) as characters_master_count from public.characters_master;"`
- `supabase db query --linked -o table "select gm.name as l1, cm.name as l2 from public.characters_master cm join public.groups_master gm on gm.id = cm.group_id join public.genres_master ge on ge.id = cm.genre_id where ge.name = 'K-POP男性' and gm.name ilike '%SHINee%' order by cm.display_order, cm.name;"`
- `npm --prefix mobile run typecheck`
- `npm --prefix web run lint -- src/app/profile/oshi/page.tsx`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.40] 推しL2取得をページング化" --non-interactive`
- EAS Update: `019e5d26-8cd5-77a4-b0b8-04443d20f3e5`
- EAS Update group: `48c220ec-6f25-4427-adaa-2414640d0f32`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/page.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ `characters_master` 2825件に対して1000件上限を回避
- ✅ `SHINee` のL2は `オンユ`、`キー`、`ミンホ`、`テミン`、`ジョンヒョン` の5件をDBで確認
- ✅ モバイル型チェック成功
- ✅ Web/PWA対象ファイルlint成功
- ✅ Preview channel へ EAS Update 済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.39：K-POP男性L2を旧メンバーまで補完

### 背景・問題意識

オーナーから、K-POP男性のL1に紐づくL2について「それぞれ3、4人くらいしかメンバーがいないの嘘すぎる」と指摘があった。前回補完では現役メンバー中心に判定していたため、旧譜・旧トレカ・過去ツアーグッズで検索される旧メンバーや、NCT内の複数ユニット所属文脈が足りていなかった。

### 変更内容

#### `supabase/migrations/20260525044500_expand_kpop_male_l2_depth.sql`
- K-POP男性L1に対して、旧メンバー/旧活動文脈も含むL2を24件追加した。
- `Stray Kids`、`RIIZE`、`TREASURE`、`THE BOYZ`、`NCT 127`、`EXO`、`SHINee`、`MONSTA X`、`BTOB`、`SUPER JUNIOR`、`WayV`、`ONEUS`、`BIGBANG` を補完した。
- `SUPER JUNIOR` は本体の旧メンバーに加え、グッズ検索で拾われやすい `Super Junior-M` 文脈の `ヘンリー` / `チョウミ` も追加した。
- `NCT 127` / `NCT DREAM` / `WayV` で同一人物になる `マーク`、`ヘチャン`、`ウィンウィン` の `entity_id` を明示的に束ねた。
- 英字表記・旧芸名・本名を `aliases` に入れ、検索の取りこぼしを減らした。

### 影響範囲

- 推し追加/推し設定のK-POP男性候補
- グッズ登録、Wish登録、譲グッズ登録時のK-POP男性メンバー候補
- NCT系メンバーの同一人物集計

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- 追加後レビュー: 追加候補24件について `missing_count = 0`
- 追加後レビュー: 追加候補24件について `entity_null_count = 0`
- 追加後レビュー: K-POP男性内の `(group_id, name)` 重複0件
- 追加後レビュー: `マーク`、`ヘチャン`、`ウィンウィン` のNCT系 `entity_id` 同期を確認

### 関連ファイル

- `supabase/migrations/20260525044500_expand_kpop_male_l2_depth.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ K-POP男性だけに絞って再レビュー
- ✅ 現役だけでなく旧グッズ検索に必要な旧メンバー文脈を追加
- ✅ 追加候補24件の登録漏れなし
- ✅ 追加候補24件の `entity_id` 同期漏れなし
- ✅ K-POP男性内の重複L2なし
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存マスタへのデータ追加のみでDBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.38：対象L1の所属L2を大幅補完

### 背景・問題意識

オーナーから「KPOP男性、女性、国内男性・女性、キャラクターIP、スポーツで今登録しているL1マスタについて、一つずつ所属のメンバーやキャラクターを確認し、もれなく登録」「1つのL1マスタにつき2回はレビュー」と指示があった。既存マスタはL1自体は増えていたが、坂道/48系/ハロプロ/大人数K-POP/スポーツ/キャラクターIPのL2が一部代表メンバーだけに留まっていた。

### 変更内容

#### `supabase/migrations/20260525043000_expand_target_l1_l2_batch1.sql`
- 対象6分類の既存L1を全件集計し、L2不足が確認できた71件のL1に対して591件のメンバー/キャラクター/選手/マスコットを追加した。
- K-POPは `tripleS` を24名まで補完し、`CRAVITY`、`Dreamcatcher`、`WJSN`、`EVNNE` などの不足メンバーを補った。
- 国内女性は坂道、AKB48/SKE48/NMB48/HKT48/STU48、ハロプロ、KAWAII LAB.系、私立恵比寿中学などを現役/主要メンバー中心に補完した。
- 国内男性は `MAZZEL`、`BALLISTIK BOYZ`、`PSYCHIC FEVER`、`BUDDiiS` などの不足メンバーを補完した。
- キャラクターIPはサンリオ、ポケモン、カービィ、たまごっち、シルバニア、リカちゃん等のグッズ検索で使われやすい主要キャラクターを追加した。
- スポーツは代表チーム/クラブに、代表的な選手と公式マスコット系キャラクターを追加した。
- 追加L2に対して `oshi_entities_master` を再同期し、人物/キャラクターentityを検索・集計に使える状態にした。

### 影響範囲

- 推し追加/推し設定のL1-L2候補
- グッズ登録、Wish登録、譲グッズ登録時のメンバー/キャラクター候補
- L2名検索からL1を返す検索体験

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- 追加前レビュー: 対象6分類172件のL1を集計し、L2不足のあるL1と追加候補を抽出
- 追加後レビュー: 追加候補591件について `missing_count = 0`
- 追加後レビュー: 追加候補591件について `entity_null_count = 0`
- 追加後レビュー: 71件すべてのL1で `expected_added_names = registered_added_names`

### 関連ファイル

- `supabase/migrations/20260525043000_expand_target_l1_l2_batch1.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 対象6分類のL1件数を全件レビュー
- ✅ 追加対象71 L1は追加前差分レビューと追加後DBレビューの2回を実施
- ✅ 追加候補591件の登録漏れなし
- ✅ 追加候補591件の `entity_id` 同期漏れなし
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存マスタへのデータ追加のみでDBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.37：推し追加の分類選択とキーボード追従を改善

### 背景・問題意識

オーナーから、推し追加画面の下部分類ボタンで「押す前と押したボタンが交互に選択するような表示になる」、検索欄フォーカス時に「キーボードの上まで入力欄が押し上がってほしい」と指摘があった。分類チップの選択表示にスクロール中のページ位置を使っていたため、タップ後のアニメーション中に旧分類と新分類が揺れて見えていた。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 分類チップのアクティブ判定を、スクロール中のページ位置ではなく選択中の `genreId` に固定した。
- ページスワイプで分類が確定したタイミングでは、従来通り `genreId` を更新する。
- 推し追加モーダル内を `KeyboardAvoidingView` で包み、検索欄フォーカス時に下部ドックがキーボード上へ逃げるようにした。
- 検索入力に `returnKeyType="search"` を追加した。

### 影響範囲

- iOS版 推し設定の「推しを追加」モーダル
- 推し追加モーダルの分類チップ選択表示
- 推し追加モーダルの検索入力時レイアウト

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.37] 推し追加の分類と検索入力を改善" --non-interactive`
- EAS Update: `019e5afe-53f9-7912-b89a-6472fd10047f`
- EAS Update group: `bf2edac7-439f-4711-bf1f-2847220c7dfe`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 分類チップはタップした分類を即座に安定表示
- ✅ スワイプ完了時の分類同期は維持
- ✅ 検索欄フォーカス時に下部入力ドックがキーボードを避ける
- ✅ Preview channel へ EAS Update 済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.36：推し追加検索にL2名を含める

### 背景・問題意識

オーナーから、推し追加画面の検索で「メンバーの方も検索に含める」「検索結果として出てくるのはL1のマスタ」と指示があった。たとえば「笠原桃奈」で検索した場合、該当メンバーを含む `ME:I` と `アンジュルム` のようなL1候補を返す必要がある。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し追加モーダルの検索対象に `option.characters[].name` を追加した。
- L2名がヒットしても、表示結果は従来通りL1の `MasterOption` カードにした。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- Web/PWA側の同等モーダルも、L2名を検索対象に追加した。

#### `supabase/migrations/20260525041000_add_momona_kasahara_angerme_l2.sql`
- 代表例として、`アンジュルム` のL2に `笠原桃奈` を追加した。
- 既存の `ME:I / 笠原桃奈` と同じ `entity_id` を引き継ぎ、同一人物として扱えるようにした。

### 影響範囲

- 推し設定の「推しを追加」モーダル
- プロフィール推し編集のマスタ選択候補
- 推しマスタのL2候補

### 確認方法

- `npm --prefix web run lint -- src/app/profile/oshi/OshiEditView.tsx`
- `npm --prefix mobile run typecheck`
- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select gm.name as l1, cm.name as l2 from public.characters_master cm join public.groups_master gm on gm.id = cm.group_id where cm.name = '笠原桃奈' order by gm.name;"`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.37] 推し追加の分類と検索入力を改善" --non-interactive`（iter168.37と同梱）
- EAS Update: `019e5afe-53f9-7912-b89a-6472fd10047f`
- EAS Update group: `bf2edac7-439f-4711-bf1f-2847220c7dfe`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `supabase/migrations/20260525041000_add_momona_kasahara_angerme_l2.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ L2メンバー名を検索対象に追加
- ✅ 検索結果表示はL1カードのまま維持
- ✅ `笠原桃奈` は `ME:I` と `アンジュルム` の両方に紐付く
- ✅ Preview channel へ EAS Update 済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存L2補完のみでDBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.35：ソロ候補の0メンバー表示を省略

### 背景・問題意識

オーナーから、推し追加画面でソロ候補に「0メンバー」と出るのは不要と指摘があった。ソロはメンバーを持たない前提なので、0件表示は情報量がなく、候補の読みやすさを下げる。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し追加モーダルの候補メタ情報で、`kind === "solo"` の場合はメンバー数を表示しないようにした。
- グループ / 作品は従来通りメンバー数を表示する。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- Web/PWA側も、ソロ候補ではメンバー数を出さない条件を明示した。

### 影響範囲

- 推し設定の「推しを追加」モーダル
- プロフィール推し編集のマスタ選択候補

### 確認方法

- `npm --prefix web run lint -- src/app/profile/oshi/OshiEditView.tsx`
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter168.35] 推し追加モーダルの登録CTA反映" --non-interactive`
- EAS Update: `019e5af7-748a-7f81-84f9-d048865fc1cc`
- EAS Update group: `d052287c-45e2-4d8c-93e7-7ee06df85973`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ ソロ候補で「0メンバー」を表示しない
- ✅ グループ / 作品候補のメンバー数表示は維持
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.34：推し追加を複数登録CTAへ変更

### 背景・問題意識

オーナーから、推し追加画面で「複数選択できるように」「選択したら画面の右下端に固定で登録ボタンを表示」「各パネルの『追加』表示はなくす」と指示があった。1件ずつ追加する表示だと複数登録の意図が伝わりにくいため、カード自体を選択対象にし、確定操作を固定CTAに集約する。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し追加モーダルの確定CTAを、選択時だけ表示される右下固定の「登録」ボタンに変更した。
- 固定CTA表示中に候補リストや検索欄が隠れないよう余白を確保した。
- 各マスタカードはカード全体タップで複数選択できる状態を維持し、カード右端の「追加」表示を置かない構成にした。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- Web/PWA側の同等モーダルも、下部全面ボタンから右下固定の「登録」ボタンへ揃えた。
- 固定ボタン表示中もリスト末尾が隠れないよう、スクロール領域の下余白を増やした。

### 影響範囲

- 推し設定の「推しを追加」モーダル
- プロフィール推し編集のマスタ選択UX

### 確認方法

- `npm --prefix web run lint -- src/app/profile/oshi/OshiEditView.tsx`
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 複数選択は既存のdraft選択配列を利用し、複数件をまとめて登録できる
- ✅ 各マスタカード右端に「追加」を表示しない
- ✅ 選択後だけ右下固定の「登録」CTAを表示
- ✅ 先頭一文字アイコンは対象モーダルに表示していない
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.33：恋愛・BL寄り作品を追加

### 背景・問題意識

アニメ/マンガ系の推しマスタ拡充で、少年漫画・大型アクション作品に偏りすぎると、実際のグッズ交換で強い女性向け・恋愛・BL寄り作品の需要を取りこぼす。公式/専門店でグッズ展開が確認できる作品を中心に、交換対象になりやすいキャラクターをL2として追加した。

### 変更内容

#### `supabase/migrations/20260525035000_expand_romance_bl_manga_merch_titles.sql`
- ゆびさきと恋々 / 山田くんとLv999の恋をする / 佐々木と宮野 / ギヴンを追加し、主要キャラをL2登録した。
- ホリミヤ / ブルーピリオド / 彼女、お借りしますを追加し、主要キャラをL2登録した。
- 追加した全 `work` にL2を同梱し、追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('ゆびさきと恋々','山田くんとLv999の恋をする','佐々木と宮野','ギヴン','ホリミヤ','ブルーピリオド','彼女、お借りします') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 416
- L2合計: 2209
- `oshi_entities_master`: 2333件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 代表例: ホリミヤ 10件 / ギヴン 8件 / 佐々木と宮野 8件 / 山田くんとLv999の恋をする 8件

### 関連ファイル

- `supabase/migrations/20260525035000_expand_romance_bl_manga_merch_titles.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 女性向け・恋愛・BL寄りのグッズ交換需要を補完
- ✅ 追加した `work` はすべてL2を同梱
- ✅ 実在する作品・キャラクターのみを登録
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.32：最近人気作のL2を深掘り

### 背景・問題意識

オーナーから、アニメ/マンガ系は「最近人気なものやグッズ展開があるもの」を中心に充実させるよう指示があった。iter168.31で新規作品を追加したが、既存の最近人気作にもL2が薄いものが残っていたため、新規追加と既存作品の主要キャラ補完を同時に行った。

### 変更内容

#### `supabase/migrations/20260525033000_expand_recent_anime_manga_merch_depth.sql`
- 薫る花は凛と咲く / カグラバチ / ふつうの軽音部を新規追加し、主要キャラをL2登録した。
- ダンダダン / WIND BREAKER / SAKAMOTO DAYS / 【推しの子】 / 葬送のフリーレン / ブルーロック / 薬屋のひとりごと / 怪獣8号の主要キャラを追加補完した。
- 追加した全 `work` にL2を同梱し、追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('薫る花は凛と咲く','カグラバチ','ふつうの軽音部','ダンダダン','WIND BREAKER','SAKAMOTO DAYS','【推しの子】','葬送のフリーレン','ブルーロック','薬屋のひとりごと','怪獣8号') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 409
- L2合計: 2154
- `oshi_entities_master`: 2278件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 代表例: ブルーロック 19件 / SAKAMOTO DAYS 17件 / WIND BREAKER 16件 / 葬送のフリーレン 16件 / 薬屋のひとりごと 14件

### 関連ファイル

- `supabase/migrations/20260525033000_expand_recent_anime_manga_merch_depth.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 最近人気・グッズ展開のあるアニメ/マンガ作品に軸を寄せて追加
- ✅ 新規追加した `work` はすべてL2を同梱
- ✅ 既存人気作品の主要キャラ不足を追加補完
- ✅ 実在する作品・キャラクターのみを登録
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.31：最近人気アニメ・マンガを追加

### 背景・問題意識

オーナーから「ビッグタイトルもいいんだけど、アニメや漫画系は、最近人気なものやグッズ展開があるものを中心にマスタを充実させて欲しい」と指示があった。そこで定番・長寿作品だけでなく、2024〜2026年に話題化し、公式サイト・公式ショップ・アニメイト等でグッズ展開が確認できるアニメ/マンガ作品を優先して追加した。

### リサーチ観点

- 2025年冬アニメ初速ランキングで上位に出ている作品（例: メダリスト、SAKAMOTO DAYS、薬屋のひとりごと）
- 公式サイトにグッズ情報・公式ショップ・オンリーショップ・新規描き下ろしグッズ情報がある作品
- 2025年前後に放送・続編・新規展開があり、ランダムグッズやアクリルスタンド等の交換需要が見込める作品

### 変更内容

#### `supabase/migrations/20260525031000_expand_recent_anime_manga_merch_titles.sql`
- メダリスト / アオのハコ / 忘却バッテリー / 桃源暗鬼 / ガチアクタ / 光が死んだ夏 / 逃げ上手の若君を追加し、それぞれ主要キャラをL2登録した。
- MASHLE / ダンジョン飯 / らんま1/2 / その着せ替え人形は恋をする / シャングリラ・フロンティア / 地獄楽を追加し、それぞれ主要キャラをL2登録した。
- 追加した全 `work` にL2を同梱し、追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。
- 初回適用時に `oshi_entities_master.entity_type` の制約に合わない `work` 値を入れようとして失敗したため、既存設計に合わせてL1作品のentity同期は行わず、L2キャラクターのみ同期するよう修正した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('メダリスト','アオのハコ','忘却バッテリー','桃源暗鬼','ガチアクタ','光が死んだ夏','逃げ上手の若君','MASHLE','ダンジョン飯','らんま1/2','その着せ替え人形は恋をする','シャングリラ・フロンティア','地獄楽') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 406
- L2合計: 2077
- `oshi_entities_master`: 2201件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 追加例: ガチアクタ 14件 / アオのハコ 12件 / らんま1/2 11件 / 桃源暗鬼 10件 / ダンジョン飯 10件

### 関連ファイル

- `supabase/migrations/20260525031000_expand_recent_anime_manga_merch_titles.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 最近人気・グッズ展開のあるアニメ/マンガ作品に軸を寄せて追加
- ✅ 追加した `work` はすべてL2を同梱
- ✅ 実在する作品・キャラクターのみを登録
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ `oshi_entities_master.entity_type` の既存制約（person / character / other）を尊重
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.30：定番アニメゲーム舞台のL2を補完

### 背景・問題意識

オーナーから、大きい作品やグループではL2に主要キャラ・主要メンバーを十分に登録するよう指摘が続いている。前回までの補完後も、定番アニメ・ゲーム・2.5次元作品で主要キャラ数が少ないL1が残っていたため、既存L1のL2を追加補完した。

### 変更内容

#### `supabase/migrations/20260525024500_expand_classic_anime_game_stage_l2.sql`
- ワンパンマン / るろうに剣心 / 地縛少年花子くん / 怪獣8号 / 薬屋のひとりごと / 鋼の錬金術師の主要キャラを追加した。
- ファイナルファンタジーVII / ペルソナ5 / スプラトゥーン / キングダム ハーツ / 刀剣乱舞ONLINEの主要キャラを追加した。
- ミュージカル「刀剣乱舞」/ 舞台「刀剣乱舞」/ ミュージカル「テニスの王子様」のキャラクター候補を補完した。
- 追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('ワンパンマン','るろうに剣心','地縛少年花子くん','怪獣8号','薬屋のひとりごと','鋼の錬金術師','ファイナルファンタジーVII','ペルソナ5','スプラトゥーン','キングダム ハーツ','刀剣乱舞ONLINE','ミュージカル「刀剣乱舞」','舞台「刀剣乱舞」','ミュージカル「テニスの王子様」') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 393
- L2合計: 1953
- `oshi_entities_master`: 2077件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 代表例: 刀剣乱舞ONLINE 14件 / ペルソナ5 10件 / ミュージカル「刀剣乱舞」10件 / スプラトゥーン 9件

### 関連ファイル

- `supabase/migrations/20260525024500_expand_classic_anime_game_stage_l2.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実在する作品・キャラクターのみを追加
- ✅ 定番アニメ・ゲーム・2.5次元作品のL2密度を改善
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.29：キャラIPと定番作品のL2を補完

### 背景・問題意識

オーナーから、大きい作品やグループではL2に主要キャラ・主要メンバーを十分に入れるべきという追加指摘があった。前回までで大型ゲーム・大型作品を補完したが、キャラクターIPや長寿アニメ作品にまだ主要キャラが少ないものが残っていたため、グッズ交換で選ばれやすい定番IPを中心に厚増しした。

### 変更内容

#### `supabase/migrations/20260525022500_expand_character_ip_and_classic_works.sql`
- クレヨンしんちゃん / ドラえもん / ムーミン / PEANUTS / 星のカービィ / すみっコぐらし / ちいかわ / サンリオ個別IPの主要キャラを追加した。
- NARUTO / BLEACH / HUNTER×HUNTER / ワールドトリガー / Dr.STONE / ぼっち・ざ・ろっく！ の主要キャラを追加した。
- ゼルダの伝説 / どうぶつの森 / モンスターハンターの代表キャラ・モンスターを追加した。
- 追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('クレヨンしんちゃん','ドラえもん','ムーミン','PEANUTS','星のカービィ','すみっコぐらし','ちいかわ','ハローキティ','マイメロディ','クロミ','シナモロール','ポムポムプリン','NARUTO -ナルト-','BLEACH','HUNTER×HUNTER','ワールドトリガー','Dr.STONE','ぼっち・ざ・ろっく！','ゼルダの伝説','どうぶつの森','モンスターハンター') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 393
- L2合計: 1892
- `oshi_entities_master`: 2016件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 代表例: ちいかわ 11件 / すみっコぐらし 11件 / クレヨンしんちゃん 9件 / BLEACH 9件 / ドラえもん 8件

### 関連ファイル

- `supabase/migrations/20260525022500_expand_character_ip_and_classic_works.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実在するキャラクターIP・作品・キャラクターのみを追加
- ✅ グッズ交換で選ばれやすい定番IPと長寿作品のL2密度を改善
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.28：ビッグ作品ゲームのL2を再補完

### 背景・問題意識

オーナーから「まだL2に主要キャラやグループ全員が登録されていないものがあります」「ビッグな作品やグループならちゃんと十分に登録してください」と追加指摘があった。前回の厚増し後も、グッズ交換・推し活の対象として大きい作品やゲームで主要キャラ数がまだ少ないL1が残っていたため、既存L1のL2密度をさらに補完した。

### 変更内容

#### `supabase/migrations/20260525020500_expand_major_l2_depth_2.sql`
- 黒執事 / Free! / 夏目友人帳 / SAKAMOTO DAYS / WITCH WATCH / カードキャプターさくら / 弱虫ペダル / ゴールデンカムイ / 家庭教師ヒットマンREBORN! の主要キャラを追加した。
- 原神 / 崩壊:スターレイル / ゼンレスゾーンゼロ / アークナイツ / ウマ娘 プリティーダービー / ブルーアーカイブ / 学園アイドルマスター / Identity V 第五人格 / 魔法使いの約束の主要キャラを追加した。
- 追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('黒執事','Free!','夏目友人帳','SAKAMOTO DAYS','WITCH WATCH','カードキャプターさくら','弱虫ペダル','ゴールデンカムイ','家庭教師ヒットマンREBORN!','原神','崩壊:スターレイル','ゼンレスゾーンゼロ','アークナイツ','ウマ娘 プリティーダービー','ブルーアーカイブ','学園アイドルマスター','Identity V 第五人格','魔法使いの約束') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 393
- L2合計: 1818
- `oshi_entities_master`: 1942件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 代表例: 原神 13件 / 魔法使いの約束 11件 / 弱虫ペダル 10件 / SAKAMOTO DAYS 9件 / ゴールデンカムイ 9件

### 関連ファイル

- `supabase/migrations/20260525020500_expand_major_l2_depth_2.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 大型作品・ゲームでL2が薄かった既存L1を追加補完
- ✅ 新規L1追加なし、既存ビッグL1の主要キャラ補完に集中
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.27：ビッグ作品の主要L2を厚増し

### 背景・問題意識

オーナーから「まだL2に主要キャラやグループ全員が登録されていないものがあります」「ビッグな作品やグループならちゃんと十分に登録してください」と指摘があった。iter168.24〜168.26 ではL2必須と新規L1拡充を優先したため、一部の大型作品・大型グループでL2が主要数件に留まっていた。今回は既存のビッグL1に対して、代表的な主要キャラ・メンバーを厚く補完した。

### 変更内容

#### `supabase/migrations/20260525014500_expand_major_l2_depth.sql`
- ONE PIECE / 名探偵コナン / SPY×FAMILY / 進撃の巨人 / 銀魂 / 文豪ストレイドッグス / 黒子のバスケ / テニスの王子様の主要キャラを追加した。
- Fate/Grand Order / アイドルマスター シンデレラガールズ / アイドルマスター SideM の主要キャラを追加した。
- ポケットモンスター / サンリオキャラクターズの代表キャラクターを追加した。
- hololive / にじさんじの代表メンバーを追加した。
- 追加L2に対して `oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, gm.name, count(cm.id) as l2 from public.groups_master gm join public.genres_master ge on ge.id=gm.genre_id left join public.characters_master cm on cm.group_id=gm.id where gm.name in ('ONE PIECE','名探偵コナン','SPY×FAMILY','進撃の巨人','銀魂','文豪ストレイドッグス','黒子のバスケ','テニスの王子様','Fate/Grand Order','アイドルマスター シンデレラガールズ','アイドルマスター SideM','ポケットモンスター','サンリオキャラクターズ','hololive','にじさんじ') group by ge.name, gm.name order by ge.name, gm.name;"`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`

### 適用後件数

- L1合計: 393
- L2合計: 1727
- `oshi_entities_master`: 1851件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 代表例: ONE PIECE 18件 / 名探偵コナン 20件 / Fate Grand Order 15件 / hololive 19件 / にじさんじ 19件

### 関連ファイル

- `supabase/migrations/20260525014500_expand_major_l2_depth.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 既存の大型L1に対して、主要キャラ・代表メンバーを厚く補完
- ✅ 新規L1追加なし、既存ビッグL1のL2密度改善に集中
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.26：作品IPと配信者マスタを追加

### 背景・問題意識

オーナーから「私が止めるまで続けて」と再指示があったため、推しマスタ拡充を継続した。前バッチまででアイドル・音楽はかなり厚くなったため、今回はグッズ交換や推し活対象になりやすいアニメ・マンガ、ゲーム、キャラクターIP、VTuber・配信者、お笑いを中心に追加した。

### 変更内容

#### `supabase/migrations/20260525013000_expand_oshi_master_batch4.sql`
- アニメ・マンガに NARUTO / HUNTER×HUNTER / Dr.STONE / ワールドトリガー / 鋼の錬金術師 / BLEACH / 怪獣8号 などを追加し、主要キャラをL2登録した。
- ゲームに FFVII / ペルソナ5 / ゼルダの伝説 / スプラトゥーン / どうぶつの森 / モンスターハンター / キングダム ハーツを追加した。
- キャラクターIPに ハローキティ / マイメロディ / クロミ / ポムポムプリン / シナモロール / PUI PUI モルカー / カナヘイの小動物などを追加した。
- VTuber・配信者に hololive English / hololive DEV_IS / NIJISANJI EN / QuizKnock / ドズル社を追加した。
- お笑いに 千鳥 / チョコレートプラネット / ミキ / ダウ90000 / ヨネダ2000を追加した。
- 追加した全 `group` / `work` にL2を同梱し、`oshi_entities_master` と `entity_id` を再同期した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`
- `supabase db query --linked -o table "select 'solo_l1_without_entity' as check_name, count(*) from public.groups_master where kind='solo' and entity_id is null union all select 'l2_without_entity', count(*) from public.characters_master where entity_id is null union all select 'l1_total', count(*) from public.groups_master union all select 'l2_total', count(*) from public.characters_master union all select 'entities_total', count(*) from public.oshi_entities_master;"`

### 適用後件数

- L1合計: 393
- L2合計: 1594
- `oshi_entities_master`: 1718件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件

### 関連ファイル

- `supabase/migrations/20260525013000_expand_oshi_master_batch4.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実在する作品・IP・グループ・人物・キャラクターのみを追加
- ✅ 追加した `group` / `work` はすべて同一migration内でL2を同梱
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.25：定番KPOPと声優ユニットを追加

### 背景・問題意識

iter168.24 で `group` / `work` のL2空状態は解消できたが、オーナーから「私が止めるまで、推しのマスタを拡充してください」と継続指示がある。次のバッチとして、グッズ交換・推し活の定番になりやすいレガシーK-POP、国内グループ、声優ユニットを追加し、引き続き全L1にL2を同梱した。

### 変更内容

#### `supabase/migrations/20260525005500_expand_oshi_master_batch3.sql`
- K-POP男性に GOT7 / BIGBANG / 2PM を追加し、各メンバーをL2登録した。
- K-POP女性に Girls' Generation / KARA / 2NE1 を追加し、各メンバーをL2登録した。
- 国内男性に Hey! Say! JUMP / Kis-My-Ft2、国内女性に BEYOOOOONDS / つばきファクトリー / OCHA NORMA を追加した。
- 声優に 虹ヶ咲学園スクールアイドル同好会 / Liella! / TrySail / DIALOGUE+ / 22/7 / Afterglow / Morfonica / RAISE A SUILEN を追加した。
- 追加L2に対して `oshi_entities_master` を再同期し、`entity_id` 未紐付けが出ないようにした。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`
- `supabase db query --linked -o table "select 'solo_l1_without_entity' as check_name, count(*) from public.groups_master where kind='solo' and entity_id is null union all select 'l2_without_entity', count(*) from public.characters_master where entity_id is null union all select 'l1_total', count(*) from public.groups_master union all select 'l2_total', count(*) from public.characters_master union all select 'entities_total', count(*) from public.oshi_entities_master;"`

### 適用後件数

- L1合計: 357
- L2合計: 1471
- `oshi_entities_master`: 1595件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件

### 関連ファイル

- `supabase/migrations/20260525005500_expand_oshi_master_batch3.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実在するグループ・人物のみを追加
- ✅ 追加した `group` はすべて同一migration内でL2を同梱
- ✅ `group` / `work` でL2が0件のL1は引き続き0件
- ✅ `entity_id` 未紐付け0件を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ 既存のL2必須運用ルール内のseed追加であり、追加のデータモデル更新なし

---

## イテレーション168.24：推しL2必須でマスタを拡充

### 背景・問題意識

オーナーから「私が止めるまで、推しのマスタを拡充してください」「グループや作品のマスタについては、必ずその中にメンバーが１人以上追加されるようにしてください」と指示があった。推し登録・グッズ登録・Wish登録ではL1だけが増えても、メンバー/キャラが空だとユーザーが具体的な推しを選びづらくなる。そこで既存の `group` / `work` のL2空状態を解消し、追加する新規L1も同一migration内でL2を必ず持つようにした。

### 変更内容

#### `supabase/migrations/20260525002000_fill_oshi_master_required_l2.sql`
- 既存の `groups_master.kind in ('group','work')` で `characters_master` が0件だったL1を補完した。
- K-POP男性/女性、国内男性/女性、歌い手、2.5次元・舞台、ゲーム、キャラクターIP、スポーツなどを中心にL2を追加した。
- スポーツチームはグッズ化されやすい公式マスコットをL2として追加し、`oshi_entities_master.entity_type='character'` に明示リンクした。
- NCT 127 / NCT DREAM のマーク・ヘチャン、After the Rain / ソロのまふまふ・そらる、刀剣乱舞系の同一キャラクターを同じ `oshi_entities_master` に明示リンクした。

#### `supabase/migrations/20260525003500_expand_oshi_master_batch2.sql`
- 新規L1として K-POP、国内アイドル/音楽、アニメ・マンガ、ゲーム、キャラクターIP、VTuber・配信者、お笑いを追加した。
- P1Harmony / MAMAMOO / Da-iCE / IS:SUE / 薬屋のひとりごと / ブルーアーカイブ / たまごっち / ホロスターズ / 見取り図など、追加した全 `group` / `work` にL2を同梱した。
- 刀剣乱舞ONLINE と既存の2.5次元文脈に出る同一キャラクターを `oshi_entities_master` で束ねた。

#### `notes/05_data_model.md`
- `groups_master.kind in ('group','work')` は少なくとも1件以上の `characters_master` を持つ、という運用不変条件を追記した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し追加
- グッズ登録 / Wish登録 / 個別募集の推し選択候補
- 推しすれ違いの同担・近傍界隈判定に使うマスタ候補

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "with missing as (select gm.id from public.groups_master gm left join public.characters_master cm on cm.group_id=gm.id where gm.kind in ('group','work') group by gm.id having count(cm.id)=0) select count(*) as group_or_work_without_l2 from missing;"`
- `supabase db query --linked -o table "select 'solo_l1_without_entity' as check_name, count(*) from public.groups_master where kind='solo' and entity_id is null union all select 'l2_without_entity', count(*) from public.characters_master where entity_id is null union all select 'l1_total', count(*) from public.groups_master union all select 'l2_total', count(*) from public.characters_master union all select 'entities_total', count(*) from public.oshi_entities_master;"`

### 適用後件数

- L1合計: 338
- L2合計: 1370
- `oshi_entities_master`: 1494件
- `group` / `work` でL2が0件のL1: 0件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件

### 関連ファイル

- `supabase/migrations/20260525002000_fill_oshi_master_required_l2.sql`
- `supabase/migrations/20260525003500_expand_oshi_master_batch2.sql`
- `notes/05_data_model.md`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実在するグループ・作品・人物・キャラクター・公式マスコットのみを追加
- ✅ 既存/新規の `group` / `work` は、少なくとも1件以上のL2を持つ状態にした
- ✅ 新規L1追加時も同一migration内でL2を同梱
- ✅ `oshi_entities_master` と `entity_id` を再同期し、未紐付け0件を確認
- ✅ 同一人物・同一キャラとして明確な文脈は手動entityで束ねた
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ データモデル運用ルールは `notes/05_data_model.md` に反映

---

## イテレーション168.23：推し追加を複数選択CTAへ変更

### 背景・問題意識

オーナーから「『推し設定』や『推しを追加』の画面で、各パネルの先頭にあるアイコンの表示はなくしてください」「『推しを追加』の画面の各パネルの右端にある『追加』は無くしてください」「パネルを一つでも選択したら、下部に『推しを設定する』というボタンが現れるようにしてください」と指摘があった。推し候補パネルは名前・ジャンル・種別が主情報で、先頭アイコンや右端の追加ラベルは情報量に対して視線ノイズが大きかった。また、1件ずつ即追加するより、複数の推しを選んでまとめて設定する方が登録操作に合っている。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し追加モーダルの候補パネル右端に出ていた「追加 / 追加済み」ラベルを削除した。
- 候補パネルのタップを即追加ではなく選択/解除に変更した。
- 1件以上選択すると、下部に「推しを設定する」ボタンを表示するようにした。
- 複数候補を選択してボタンを押すと、まとめて `user_oshi` に追加し、ローカルUIにも即時反映するようにした。
- 設定済み候補はパネル内メタ情報で「設定済み」と分かるようにし、再選択できない状態を維持した。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- Web版プロフィール推し設定の追加モーダルも、同じく候補パネル選択 + 下部「推しを設定する」CTAへ揃えた。
- 右端の「追加 / 追加済み」ラベルを削除した。

#### `Megrum/account-extras.jsx`
- 推し設定モックアップの推しカード先頭にあった頭文字アイコンを削除した。

### 影響範囲

- iOS版 推し設定
- iOS版 推し追加モーダル
- Web版 プロフィール推し設定
- 推し設定モックアップ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix web run lint -- src/app/profile/oshi/OshiEditView.tsx`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `Megrum/account-extras.jsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 推し設定カードの先頭アイコンは表示しない方針を維持
- ✅ 推し追加候補パネル右端の「追加 / 追加済み」を削除
- ✅ 複数候補選択後に下部CTAでまとめて追加できる導線に変更
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.22：推しの同一人物entityを追加

### 背景・問題意識

オーナーから「ソロで登録していても、どこか別のグループのメンバーとしても活躍している場合がある」「同じ人としてみなされるような設計にしたい」「選ぶ側はグループのメンバーとしても選べるし、ソロとしても選べるようになりたい」と相談があり、その設計で進めることになった。既存の `groups_master` / `characters_master` はユーザーが推しを選ぶ文脈として必要なので維持しつつ、内部で同じ人物・キャラクターを束ねる正規entityを追加した。

### 変更内容

#### `supabase/migrations/20260524235000_add_oshi_entities_identity_model.sql`
- `oshi_entities_master` を追加し、`identity_key` / `canonical_name` / `entity_type` / `aliases` を保持するようにした。
- `groups_master.entity_id` と `characters_master.entity_id` を追加した。
- 同名別人の誤統合を避けるため、既定では選択文脈ごとにentityを作り、明示した兼任・移籍・ソロ活動だけ同じentityへ寄せる設計にした。
- 既存の `kind='solo'` L1 と全L2に `entity_id` をバックフィルした。

#### `supabase/migrations/20260524235500_expand_cross_context_oshi_master.sql`
- K-POP男性に ASTRO、K-POP女性に IZ*ONE を追加した。
- 国内男性に DISH// を追加し、既存の FANTASTICS / M!LK / IMP. のメンバーを補完した。
- 声優に μ's / Aqours / Roselia と主要ソロ声優を追加した。
- 俳優・タレントに 平野紫耀 / 神宮寺勇太 / 岸優太 / 佐野勇斗 を追加した。
- サクラ / キム・チェウォン / ユジン / ウォニョン / チャ・ウヌ / Number_i 3名 / 八木勇征 / 北村匠海 / 佐野勇斗 を、別文脈から同じ `oshi_entities_master` に明示紐付けした。

#### `notes/05_data_model.md`
- `oshi_entities_master` と `entity_id` の設計を追記した。
- `groups_master` / `characters_master` は「選択文脈」、`oshi_entities_master` は「内部的な同一推し」を表すと明記した。

#### `notes/10_glossary.md`
- 「推し正規entity」「選択文脈」を追加した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し編集
- グッズ登録 / Wish登録 / 個別募集の対象選択
- 将来の推し別集計、同担判定、検索サジェスト、マッチング補助

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select entity_type, count(*) as entities from public.oshi_entities_master group by entity_type order by entity_type;"`
- `supabase db query --linked -o table "select ge.display_order, ge.name as genre, count(distinct g.id) as groups, count(c.id) as characters from public.genres_master ge left join public.groups_master g on g.genre_id = ge.id left join public.characters_master c on c.group_id = g.id group by ge.id, ge.display_order, ge.name order by ge.display_order, ge.name;"`

### 適用後件数

- L1合計: 274
- L2合計: 797
- `oshi_entities_master`: person 551件 / character 323件
- `entity_id` 未紐付け: solo L1 0件 / L2 0件
- 同一entity確認: サクラ（IZ*ONE / LE SSERAFIM）、キム・チェウォン（IZ*ONE / LE SSERAFIM）、ユジン（IVE / IZ*ONE）、ウォニョン（IVE / IZ*ONE）、チャ・ウヌ（ASTRO / 海外エンタメsolo）、平野紫耀・神宮寺勇太・岸優太（Number_i / 俳優・タレントsolo）、八木勇征（FANTASTICS / 俳優・タレントsolo）、北村匠海（DISH// / 俳優・タレントsolo）、佐野勇斗（M!LK / 俳優・タレントsolo）

### 関連ファイル

- `supabase/migrations/20260524235000_add_oshi_entities_identity_model.sql`
- `supabase/migrations/20260524235500_expand_cross_context_oshi_master.sql`
- `notes/05_data_model.md`
- `notes/10_glossary.md`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ ユーザーが選ぶL1/L2文脈は維持し、内部の同一人物判定だけ `entity_id` に分離
- ✅ 同名別人の誤統合を避けるため、全件名前一致統合ではなく文脈別entity + 明示リンク方式にした
- ✅ 実在するグループ・ユニット・人物のみを追加
- ✅ `supabase db push --dry-run` 成功
- ✅ `supabase db push --yes` でリモートDBへ適用済み
- ✅ リモートDBでジャンル別件数、entity件数、代表的な同一人物リンクを確認済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新用語は `notes/10_glossary.md` に追加
- ✅ DBスキーマ変更は `notes/05_data_model.md` に反映

---

## イテレーション168.21：推し設定の頭文字アイコンを削除

### 背景・問題意識

オーナーから「推し設定関連の画面で、アイコンを推しの先頭一文字にしていますが、そのアイコンは不要です。何の情報もないので。表示させないでください」と指摘があった。推し名の先頭1文字を丸/角丸アイコンとして表示しても識別性が低く、一覧内の情報密度と視線移動だけを増やしていたため、推し設定関連画面から削除した。

### 変更内容

#### `mobile/app/onboarding/oshi.tsx`
- 推し選択カード左側の先頭1文字アイコンを削除した。

#### `mobile/app/onboarding/members.tsx`
- 推しメン・推しキャラ選択セクションのグループ頭文字アイコンを削除した。

#### `mobile/app/oshi-settings.tsx`
- 推し設定一覧のグループ頭文字アイコンを削除した。
- 登録済み推し追加モーダルの候補行から頭文字アイコンを削除した。

#### `web/src/app/onboarding/oshi/OshiForm.tsx`
- Web版オンボーディング推し選択の通常候補/審査中候補から頭文字アイコンを削除した。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- Web版プロフィール推し編集の推しカードヘッダーと追加候補行から頭文字アイコンを削除した。

### 影響範囲

- iOS版 オンボーディング推し選択
- iOS版 オンボーディング推しメン・推しキャラ選択
- iOS版 推し設定
- Web版 オンボーディング推し選択
- Web版 プロフィール推し編集

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix web run lint -- src/app/onboarding/oshi/OshiForm.tsx src/app/profile/oshi/OshiEditView.tsx`

### 関連ファイル

- `mobile/app/onboarding/oshi.tsx`
- `mobile/app/onboarding/members.tsx`
- `mobile/app/oshi-settings.tsx`
- `web/src/app/onboarding/oshi/OshiForm.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 推し名の先頭1文字を表示するアイコンを削除
- ✅ 名前・ジャンル・選択状態など、意味のある情報は維持
- ✅ iOS側 typecheck 成功
- ✅ Web対象ファイルの eslint 成功
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.20：再整理後分類の推しマスタ拡充

### 背景・問題意識

オーナーから「その分類に従って、マスタを充実させていってください。かならず現実にあるグループや作品、キャラや人名を登録するようにしてください」と指示があった。iter168.19で確定した分類を前提に、アイドル・音楽だけでなく、キャラクターIP、VTuber・配信者、お笑い、スポーツ、俳優・タレント、海外エンタメまで、実在するL1/L2候補を増やした。

### 変更内容

#### `supabase/migrations/20260524234000_expand_oshi_master_by_refined_taxonomy.sql`
- K-POP男性/女性、国内男性/女性、歌い手、声優、2.5次元・舞台、アニメ・マンガ、ゲームを追加拡充した。
- キャラクターIPに サンリオキャラクターズ / ちいかわ / すみっコぐらし / リラックマ / ポケットモンスター / 星のカービィ / ディズニー ミッキー&フレンズ / ミッフィー / PEANUTS / おぱんちゅうさぎ / mofusand / パペットスンスン を追加した。
- VTuber・配信者に にじさんじ / hololive / ぶいすぽっ！ / Neo-Porte / TOP4 / 東海オンエア / Fischer's / HIKAKIN / はじめしゃちょー を追加した。
- お笑いに 令和ロマン / 真空ジェシカ / マユリカ / ぱーてぃーちゃん / バッテリィズ / ヤーレンズ / エバース / ジョックロック / ママタルト / トム・ブラウン / ダイタク / ハナコ / かまいたち / 霜降り明星 / ニューヨーク / 男性ブランコ を追加した。
- スポーツに日本代表、NPB/Jリーグ/B.LEAGUEチームを追加し、代表グループには主要選手をL2登録した。
- 俳優・タレント、海外エンタメは人物を `kind='solo'` として追加した。

#### `supabase/migrations/20260524234500_fill_oshi_master_l2_gaps.sql`
- L2が明確な ミッフィー / おぱんちゅうさぎ / パペットスンスン / Fischer's / お笑いコンビ・トリオ を補完した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し編集
- グッズ登録 / Wish登録 / 個別募集のグループ・作品・人物選択
- `groups_master` / `characters_master` のseedデータ

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.display_order, ge.name as genre, count(distinct g.id) as groups, count(c.id) as characters from public.genres_master ge left join public.groups_master g on g.genre_id = ge.id left join public.characters_master c on c.group_id = g.id group by ge.id, ge.display_order, ge.name order by ge.display_order, ge.name;"`

### 適用後件数

- L1合計: 259
- L2合計: 732
- K-POP男性: 21グループ / 120メンバー
- K-POP女性: 18グループ / 79メンバー
- 国内男性: 18グループ / 76メンバー
- 国内女性: 19グループ / 47メンバー
- キャラクターIP: 12作品/IP / 51キャラ
- VTuber・配信者: 9組・人物 / 38名
- お笑い: 16組 / 34名
- スポーツ: 19チーム・代表 / 15選手
- 俳優・タレント: 16名
- 海外エンタメ: 20名

### 関連ファイル

- `supabase/migrations/20260524234000_expand_oshi_master_by_refined_taxonomy.sql`
- `supabase/migrations/20260524234500_fill_oshi_master_l2_gaps.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実在するグループ・作品・IP・人物・キャラ・選手のみを登録
- ✅ L1は `groups_master`、L2は `characters_master`、人物単体は `kind='solo'` で登録
- ✅ `groups_master.kind = group / work / solo` とジャンル分類を混同しない構成を維持
- ✅ `supabase db push --dry-run` 成功
- ✅ `supabase db push --yes` でリモートDBへ適用済み
- ✅ リモートDBでジャンル別件数を確認済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要、seed追加のみ）

---

## イテレーション168.19：推しジャンル分類を再整理

### 背景・問題意識

オーナーと推し分類の粒度を整理し、「アイドル・音楽だけ、KPOP男性、KPOP女性、国内男性、国内女性、歌い手、声優、という感じに分けましょう。それ以外は大分類のままで大丈夫です」と方針が確定した。`groups_master.kind = group / work / solo` は登録対象の形を示す別軸なので、ジャンル分類とは混ぜず、`genres_master` をユーザーが推しを探す入口として再整理する。

### 変更内容

#### `supabase/migrations/20260524233000_refine_oshi_genre_taxonomy.sql`
- 既存の `K-POP` を `K-POP男性`、`邦アイ` を `国内男性` にリネームし、既存IDを維持した。
- `K-POP女性` / `国内女性` / `歌い手` / `声優` を追加した。
- `2.5次元` を `2.5次元・舞台`、`アニメ` を `アニメ・マンガ` にリネームした。
- `キャラクターIP` / `VTuber・配信者` / `お笑い` / `スポーツ` / `俳優・タレント` / `海外エンタメ` を大分類として追加した。
- K-POP女性グループと国内女性グループを新ジャンルへ移動し、`characters_master.genre_id` を所属グループに同期した。
- 旧 `K-POP` に紐づいていた pending の追加リクエスト（BABYMONSTER / asepa / ME:I）を適切な女性カテゴリへ移した。
- `歌い手` と `声優` に初期候補を追加した。

#### `notes/05_data_model.md`
- `genres_master` の説明を、新しい推し分類方針に合わせて更新した。
- `groups_master.kind` はジャンルではなく対象形態（group / work / solo）の別軸であることを明記した。

#### `notes/10_glossary.md`
- 「ジャンル」の定義を iter168.19 の分類方針に合わせて更新した。

### 影響範囲

- オンボーディングの推し選択
- プロフィールの推し編集
- グッズ登録 / Wish登録 / 個別募集のグループ・作品選択
- 推し追加リクエストのジャンル選択
- `genres_master` / `groups_master` / `characters_master`

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.display_order, ge.name as genre, ge.kind, count(distinct g.id) as groups, count(c.id) as characters from public.genres_master ge left join public.groups_master g on g.genre_id = ge.id left join public.characters_master c on c.group_id = g.id group by ge.id, ge.display_order, ge.name, ge.kind order by ge.display_order, ge.name;"`

### 適用後件数

- K-POP男性: 13グループ / 99メンバー
- K-POP女性: 9グループ / 52メンバー
- 国内男性: 8グループ / 56メンバー
- 国内女性: 7グループ / 40メンバー
- 歌い手: 10組 / 0メンバー
- 声優: 10名 / 0メンバー
- 2.5次元・舞台: 7作品 / 32キャラ
- アニメ・マンガ: 11作品 / 97キャラ
- ゲーム: 3作品 / 69キャラ

### 関連ファイル

- `supabase/migrations/20260524233000_refine_oshi_genre_taxonomy.sql`
- `notes/05_data_model.md`
- `notes/10_glossary.md`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ `groups_master.kind = group / work / solo` は維持し、ジャンル分類と混同しない構造にした
- ✅ 既存 `K-POP` / `邦アイ` のIDをリネームで再利用し、既存参照を壊さないようにした
- ✅ 女性グループ移動後、`characters_master.genre_id` を所属グループに同期済み
- ✅ `supabase db push --dry-run` 成功
- ✅ `supabase db push --yes` でリモートDBへ適用済み
- ✅ リモートDBでジャンル別件数を確認済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語として「ジャンル」定義を `notes/10_glossary.md` で更新
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` は分類方針の説明更新のみ）

---

## イテレーション168.18：推し登録マスタを大幅拡充

### 背景・問題意識

オーナーから「推しに登録できるマスタをとにかく充実させて欲しい」「グッズ交換や活動が活発なグループや作品が何かをまずリサーチし、その上でマスタ登録をどんどん進めてください」と指示があった。既存DBではK-POPの一部グループにメンバー未登録があり、アニメ/ゲーム/邦アイ/2.5次元の推し登録候補が薄かったため、ランダム封入トレカ・缶バッジ・アクスタ・生写真など交換文化が強い領域を優先してマスタseedを追加した。

### 変更内容

#### `supabase/migrations/20260524230000_expand_oshi_master_active_goods.sql`
- K-POPの既存未登録グループ（Stray Kids / ENHYPEN / TXT / LE SSERAFIM）にメンバーを追加した。
- K-POPに ATEEZ / ZEROBASEONE / RIIZE / NCT WISH / BOYNEXTDOOR / TREASURE / NMIXX / BABYMONSTER / ITZY / (G)I-DLE / &TEAM / PLAVE を追加した。
- アニメに ブルーロック / 呪術廻戦 / 鬼滅の刃 / ハイキュー!! / 僕のヒーローアカデミア / チェンソーマン / ダンダダン / 葬送のフリーレン / WIND BREAKER / 東京リベンジャーズ / 【推しの子】 を追加し、主要キャラを登録した。
- ゲーム/メディアミックスに プロジェクトセカイ / あんさんぶるスターズ!! / ディズニー ツイステッドワンダーランド を追加し、主要キャラを登録した。

#### `supabase/migrations/20260524231000_expand_jpop_25d_oshi_master.sql`
- 邦アイに Snow Man / SixTONES / なにわ男子 / King & Prince / Number_i / JO1 / INI / ME:I / BE:FIRST / FRUITS ZIPPER / =LOVE / ≠ME / 乃木坂46 / 櫻坂46 / 日向坂46 を追加した。
- 2.5次元に 刀剣乱舞 / ヒプノシスマイク / アイドリッシュセブン / A3! / うたの☆プリンスさまっ♪ / 魔法使いの約束 / Paradox Live を追加した。
- Snow Man / SixTONES / なにわ男子 / Number_i / BE:FIRST / FRUITS ZIPPER と、刀剣乱舞 / ヒプノシスマイク / アイドリッシュセブンの主要キャラを登録した。

#### `supabase/migrations/20260524232000_expand_jpop_lapone_equal_master.sql`
- King & Prince / JO1 / INI / ME:I / =LOVE / ≠ME のメンバーを補完した。

### 影響範囲

- オンボーディングの推しグループ/作品選択
- プロフィールの推し編集
- グッズ登録/Wish登録/個別募集のグループ・メンバー選択
- `groups_master` / `characters_master` のseedデータ

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase db query --linked -o table "select ge.name as genre, count(distinct g.id) as groups, count(c.id) as characters from public.genres_master ge left join public.groups_master g on g.genre_id = ge.id left join public.characters_master c on c.group_id = g.id group by ge.name, ge.display_order order by ge.display_order;"`

### 適用後件数

- K-POP: 22グループ / 151メンバー
- 邦アイ: 15グループ / 96メンバー
- 2.5次元: 7作品 / 32キャラ
- アニメ: 11作品 / 97キャラ
- ゲーム: 3作品 / 69キャラ

### 関連ファイル

- `supabase/migrations/20260524230000_expand_oshi_master_active_goods.sql`
- `supabase/migrations/20260524231000_expand_jpop_25d_oshi_master.sql`
- `supabase/migrations/20260524232000_expand_jpop_lapone_equal_master.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ リサーチを踏まえ、トレカ/ランダムグッズ/缶バッジ/アクスタ交換が起きやすい領域を優先
- ✅ 既存K-POPグループの未登録メンバーを補完
- ✅ 空だった邦アイ/2.5次元にもグループ・作品候補を追加
- ✅ `supabase db push --dry-run` 成功
- ✅ `supabase db push --yes` でリモートDBへ適用済み
- ✅ リモートDBでジャンル別件数を確認済み
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要、seed追加のみ）

---

## イテレーション168.17：めぐりあい一覧を実データ読込後に表示

### 背景・問題意識

オーナーから「めぐりあいのメッセージ一覧が、まだ開いた瞬間にプレビュー？かわからないですが、それぞれのメッセージがパッと切り替わります」「一発で自分の下のデータを読み込んで欲しくて、読み込み中はそもそもメッセージ一覧全体で読み込み中、、みたいな感じでだしてほしい」と指摘があった。取引タブのめぐりあい一覧が、通常ログイン時でも固定サンプルの `LETTERS + USERS` から会話行を先に作り、あとから `groom_replies` を混ぜ直していたため、一覧が開いた瞬間に別データから実データへ切り替わって見えていた。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 通常ログイン時は、めぐりあい一覧のロード中に固定サンプル行を表示しないようにした。
- `meguriLoading` を追加し、`loadMeguriMessageReadState()` / `loadMeguriGroomReplies()` / `loadMeguriThreadMessages()` が完了するまで一覧全体を「メッセージを読み込み中…」表示にした。
- preview mode のみ従来の固定サンプル会話を表示する構成にした。
- 実データ表示では `groom_replies` と `meguri_messages` から会話相手・最新本文・未読数を組み立てるようにした。

### 影響範囲

- iOS版 取引タブの「めぐりあい」メッセージ一覧
- めぐりあいメッセージ一覧の初回ロード表示
- グルーム返信とめぐりあいメッセージの会話プレビュー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.17] めぐりあい一覧を実データ読込後に表示" --non-interactive`
- EAS Update: `019e5995-5d33-7d82-968f-a04970c6d59d`
- EAS Update group: `97efaa0b-e0f3-495c-8bbf-9bc8b3cbe13f`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 通常ログイン時の固定サンプル先出しを停止
- ✅ ロード中は会話行を描画せず、一覧全体の読み込み表示へ変更
- ✅ `groom_replies` と `meguri_messages` の実データから会話一覧を作成
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマの追加変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.16：グルーム右タップを直近表示へ修正

### 背景・問題意識

オーナーから「進捗ステータスの分割は、右にタップすればするほど直近のグルームが見えるようにしてね。今だと逆です」「タップした瞬間にグルームが切り替わるようにしてください」と指摘があった。リモート取得は `published_at desc` のため、同一アカウント内の進捗が左=最新、右=古い並びになり、右タップで古い投稿へ戻っていた。また同一アカウントの投稿が尽きて次アカウントへ進むタップでも、スワイプ用のアニメーション完了後に投稿IDを切り替えていた。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- `GroomPost` に `publishedAt` を保持し、グルームビューア内の同一アカウント投稿を古い順から新しい順へ並べ替えるようにした。
- グルームレールのサムネイルは直近投稿を維持しつつ、開いたときは古い投稿から表示して右タップで直近へ進めるようにした。
- 右/左タップ時は `selectedGroomId` を即時更新し、次アカウントへ移る場合もタップではスワイプ演出完了を待たないようにした。
- スワイプ時のキューブ演出は維持し、次アカウントは古い投稿から、前アカウントは直近投稿からプレビューするようにした。

### 影響範囲

- iOS版 めぐりホームのグルームビューア
- グルーム進捗バーの分割順
- グルーム左右タップの切替挙動
- アカウント間遷移時のタップ応答

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.16] グルーム右タップを直近表示へ修正" --non-interactive`
- EAS Update: `019e5991-ad27-7403-9f30-178297e6ffc5`
- EAS Update group: `9c615b7e-124d-4985-a77d-576783b514ce`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 同一アカウントの進捗を古い→新しい順に変更
- ✅ 右タップで直近投稿へ進む挙動に変更
- ✅ タップ時はアニメーション完了待ちなしで投稿IDを即時切替
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマの追加変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.15：グルーム投稿RLS保存失敗を修正

### 背景・問題意識

オーナーから「まだグルームを保存できません。一度そちらで試してみて、ログとかで何が起きてるかちゃんとみてくれませんか」と再指摘があった。実際にSupabase認証ユーザーで画像アップロードからグルーム投稿保存まで再現したところ、Storageアップロードは成功しており、`groom_posts.insert(...).select()` が `42501 new row violates row-level security policy` で失敗していた。

### 変更内容

#### `supabase/migrations/20260524220000_fix_groom_posts_owner_select_policy.sql`
- `groom_posts` の `SELECT` RLSポリシーに `auth.uid() = user_id` を追加し、投稿者本人が自分の投稿を直接読めるようにした。
- 既存の `public.can_view_groom_post(id, auth.uid())` は維持し、公開範囲・モデレーション条件による閲覧制御はそのまま残した。
- `insert().select()` / `INSERT ... RETURNING` の瞬間だけ、helper関数経由では新規行を見られず失敗するケースを解消した。

### 影響範囲

- iOS版 めぐりホームのグルーム投稿保存
- Supabase `groom_posts` の本人閲覧RLS
- グルーム投稿作成直後の署名URL生成前データ取得

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase migration list --linked`
- `supabase db query --linked -o table "select policyname, cmd, qual, with_check from pg_policies where schemaname = 'public' and tablename = 'groom_posts' order by policyname;"`
- 認証済みテストユーザーで `groom-posts` Storage upload → `groom_posts.insert(...).select(...).single()` → `storage.createSignedUrls()` が成功することを確認

### 関連ファイル

- `supabase/migrations/20260524220000_fix_groom_posts_owner_select_policy.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ 実ユーザー相当のSupabase authセッションで保存失敗を再現
- ✅ 失敗箇所が画像アップロードではなく `groom_posts.insert().select()` のRLSであることを確認
- ✅ リモートDBへRLSポリシー修正migrationを適用済み
- ✅ 適用後に同じ保存経路で投稿作成・署名URL生成が成功
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ テーブル/カラムの追加変更なし（`notes/05_data_model.md` 更新不要、RLSポリシー変更はmigrationで管理）

---

## イテレーション168.14：グルーム投稿画像読込を安定化

### 背景・問題意識

オーナーから「まだグルームを保存できないので、保存できるようにしてください。エラーがでます」と再指摘があった。iter168.11 で画像サイズ超過と署名URL失敗の扱いは修正したが、iOS/Expo 実機では `fetch(file://...)` によるローカル画像読み込みが失敗し、Storageアップロード前に「グルームを保存できませんでした」へ落ちる可能性が残っていた。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- カメラ撮影とアルバム選択で、投稿用の `uri` に加えてBase64画像データとMIME typeを保持するようにした。
- グルーム下書きのBase64/MIME typeを投稿成功・閉じる・撮り直し時に確実にクリアし、投稿失敗時は再投稿できるよう復元する構成にした。
- 投稿失敗メッセージを拡張し、画像読み込み失敗・ログイン情報不整合・Storage権限系の原因をユーザーに具体表示できるようにした。

#### `mobile/src/lib/groom.ts`
- 投稿前にSupabaseの認証ユーザーを再確認し、画面側の `currentUserId` と不一致なら明示エラーにした。
- Base64が渡された場合は `fetch(file://...)` を使わず、Base64から直接 `ArrayBuffer` を生成して `groom-posts` Storageへアップロードするようにした。
- Base64が無い場合だけ従来の `fetch(uri)` fallback を使い、失敗時は撮り直し/選び直しを促す具体エラーにした。

### 影響範囲

- iOS版 めぐりホームのグルーム投稿
- カメラ撮影からのグルーム投稿
- アルバム選択からのグルーム投稿
- グルーム投稿失敗時のエラー表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.14] グルーム投稿保存をBase64アップロードへ修正" --non-interactive`
- EAS Update: `019e5877-0561-7d43-8128-0457da777894`
- EAS Update group: `871211a4-ca3d-4dd6-974d-d8f2b370e049`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/lib/groom.ts`

### セルフレビュー結果

- ✅ `fetch(file://...)` 依存を避け、Base64から直接アップロードできる経路を追加
- ✅ Supabase認証ユーザーと投稿者IDの不一致を明示エラー化
- ✅ 投稿失敗時に下書き画像・キャプションを復元
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし（`notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` 更新不要）

---

## イテレーション168.13：SEVENTEENメンバーをマスタ追加

### 背景・問題意識

オーナーから「推し活グループとして、KPOPグループにSEVENTEENというグループを追加して、メンバーをマスタ登録して欲しい」と指示があった。既存の初期seedでは `groups_master` に `SEVENTEEN` は登録済みだが、`characters_master` 側の13名が未登録だったため、オンボーディング/推し設定/在庫登録でメンバーを選べるようにする。

### 変更内容

#### `supabase/migrations/20260524210000_seed_seventeen_members.sql`
- `groups_master` の `SEVENTEEN` を upsert し、aliases に `SVT` を追加した。
- SEVENTEEN Japan official site の PROFILE 掲載順に合わせて、13名を `characters_master` に追加した。
- 既存環境で重複登録しないよう、同一 `group_id` + `name` が存在する場合はメンバーinsertをスキップする構成にした。
- 表示名は既存seedに合わせて日本語カナを主にし、aliases に英字公式表記・ハングル・主要な表記揺れを入れた。

### 影響範囲

- Supabase `groups_master` / `characters_master`
- オンボーディングの推しグループ/メンバー選択
- プロフィール推し設定
- 在庫/ウィッシュの推し・メンバー選択

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `supabase migration list --linked`
- `supabase db query --linked -o table "select g.name as group_name, count(c.id) as member_count from public.groups_master g left join public.characters_master c on c.group_id = g.id where g.name = 'SEVENTEEN' group by g.name;"`
- `rg -n "SEVENTEEN|エスクプス|ディノ" supabase/migrations/20260524210000_seed_seventeen_members.sql notes/08_design_iterations.md`

### 関連ファイル

- `supabase/migrations/20260524210000_seed_seventeen_members.sql`
- `notes/08_design_iterations.md`

### セルフレビュー結果

- ✅ `groups_master` は既存seedと整合する `genre_id + name` upsert
- ✅ `characters_master` へSEVENTEEN 13名を登録
- ✅ `supabase db push --yes` でリモートDBへ適用済み
- ✅ リモートDBで `SEVENTEEN` の `member_count = 13` を確認
- ✅ 状態IDの追加・変更なし（`notes/09_state_machines.md` 更新不要）
- ✅ 新しいアプリ用語・廃止用語なし（`notes/10_glossary.md` 更新不要）
- ✅ DBスキーマ変更なし（`notes/05_data_model.md` 更新不要）

---

## イテレーション168.12：3Dアバターを歩きGLB常時再生状態へ戻す

### 背景・問題意識

オーナーから「3Dのアバターですが、おかしくなったので、一つ前の状態に戻してください」と指示があった。iter168.10 で表示モデルを立ちGLBベースにし、停止中idle / 移動中walkの2アクション切替にしたが、実機上の見え方が崩れたため、直前の安定状態である iter168.9 へ戻す。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 立ちGLBベースの表示モデルとidle/walk切替ロジックを削除した。
- `cat.glb` / `fox.glb` / `rabbit.glb` に含まれる `Armature|walking_man|baselayer` を `AnimationMixer` で常時ループ再生する構成へ戻した。
- 有効な歩行clipがない場合だけ、自前ボーンモーションへフォールバックする iter168.9 の構成へ戻した。

#### `mobile/assets/meguri-avatars/`
- `cat-idle.glb` / `fox-idle.glb` / `rabbit-idle.glb` をアプリbundle対象から削除した。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.12] 3Dアバターを前状態へ戻す" --non-interactive`
- EAS Update: `019e585e-a9c5-7442-a431-9744a13ce1fc`
- EAS Update group: `cc0a941f-25d7-4804-a958-4082304470e9`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/assets/meguri-avatars/cat-idle.glb`
- `mobile/assets/meguri-avatars/fox-idle.glb`
- `mobile/assets/meguri-avatars/rabbit-idle.glb`

### セルフレビュー結果

- ✅ iter168.10 の立ちGLBベース/idling切替を解除
- ✅ iter168.9 の歩きGLB常時ループ再生構成へ復帰
- ✅ 未使用になったidle GLBをbundle対象から削除
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.11：グルーム投稿保存エラーを修正

### 背景・問題意識

オーナーから「グルームを投稿しようとするとグルームを保存できませんでしたというエラーが出るので、なぜエラーが出るか突き止めて直してください」と指摘があった。保存経路を確認したところ、グルーム画像は `groom-posts` Storage の10MB制限に対して、カメラ/アルバム取得時に最大画質・最大サイズのままアップロードされていた。また、DB保存後の署名URL発行失敗まで「保存失敗」として扱うため、実際には保存済みでもエラー表示になり得た。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム撮影時のJPEG qualityを `1` から `0.88` に変更し、アップロード制限を超えにくくした。
- カメラのpictureSize選択を最大サイズ優先から、長辺2400px以下の最大サイズ優先へ変更した。
- アルバム選択時は iOS の compatible representation を指定し、HEIC/高容量画像がそのままアップロードされにくいようにした。
- 投稿失敗時に `console.warn` へ元エラーを出し、サイズ超過など原因が分かる場合はAlertにも具体文言を出すようにした。

#### `mobile/src/lib/groom.ts`
- `groom_posts` のselect句を共通化した。
- アップロード前に画像byte長を確認し、9.5MB超過ならStorageへ送る前に明示エラーを返すようにした。
- Storageアップロード後にDB insertが失敗した場合、アップロード済み画像を削除して孤児ファイルを残さないようにした。
- DB保存後の署名URL発行に失敗しても投稿保存自体は成功扱いにし、投稿直後はローカル画像URIをfallback表示できるようにした。
- `content-type` は `image/jpeg` / `image/png` / `image/webp` のみStorage許可MIMEとして渡し、それ以外はJPEG扱いに寄せた。

### 影響範囲

- iOS版 グルーム投稿（カメラ撮影・アルバム選択・投稿保存）
- iOS版 グルーム投稿直後の楽観表示/署名URL fallback

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.11] グルーム投稿保存エラーを修正" --non-interactive`
- EAS Update: `019e5859-b59a-7ab7-89eb-fbb6586059d1`
- EAS Update group: `8bd4dc07-8290-4a36-8933-141dca821833`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/lib/groom.ts`

### セルフレビュー結果

- ✅ Storage 10MB制限に対して、撮影/選択時の画像サイズを抑制
- ✅ DB保存後の署名URL発行失敗を保存失敗として扱わないように修正
- ✅ DB insert失敗時にStorageへ残った画像を削除
- ✅ 投稿失敗時に原因ログと具体エラーを出せるように修正
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.10：v2立ち歩きアニメーションを切替

### 背景・問題意識

オーナーから「同じフォルダに、立ち姿のglbファイルも入れました。立っている時はこのアニメーションで、それ以外の歩いているときは歩いている時のアニメーションにしてほしいです」と指示があった。iter168.9では歩行clipを常時再生していたため、停止中も歩いて見える問題が残っていた。

### 変更内容

#### `mobile/assets/meguri-avatars/`
- `Megrum めぐり/v2/ねこ  v2 立ち.glb` を `cat-idle.glb` として取り込んだ。
- `Megrum めぐり/v2/きつね v2 立ち.glb` を `fox-idle.glb` として取り込んだ。
- `Megrum めぐり/v2/うさぎ  v2 立ち.glb` を `rabbit-idle.glb` として取り込んだ。
- 3ファイルとも `Armature|Idle_13|baselayer` の約11.43秒・343キーidle clipを含むことを確認した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 表示モデルのベースを立ちGLBに変更し、初期表示と停止中の姿勢を立ち姿側へ揃えた。
- 歩きGLBはwalk clip供給用として読み込み、同じボーン名の表示モデルへ `AnimationMixer` で適用するようにした。
- 既存の移動判定に合わせ、移動中はwalk action、停止中はidle actionへ切り替えるようにした。
- idle/walk clipが欠けた場合だけ、前回の自前ボーンモーションへフォールバックする保険を残した。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- v2立ちGLB/歩きGLBのanimation key数確認
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.10] v2立ち歩きアニメーションを切替" --non-interactive`
- EAS Update: `019e5850-aa43-791f-8fa2-8d03bdb1b8c3`
- EAS Update group: `bcb0c285-caac-4b05-8f0a-750b4c085a09`

### 関連ファイル

- `mobile/assets/meguri-avatars/cat-idle.glb`
- `mobile/assets/meguri-avatars/fox-idle.glb`
- `mobile/assets/meguri-avatars/rabbit-idle.glb`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 追加されたv2立ちGLBをアプリbundle対象のassetsへ反映
- ✅ `Armature|Idle_13|baselayer` が343キーのidle clipであることを確認
- ✅ 表示モデルは立ちGLB、移動中clipは歩きGLBという分担に変更
- ✅ 移動判定に応じてidle/walk actionを切り替える実装に変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.9：v2歩きGLBのアニメーションを適用

### 背景・問題意識

オーナーから「v2のフォルダに歩きのglbファイルも追加しました。そちらを使って欲しいです」と指示があった。iter168.8 の自前ボーンモーションでTポーズは解消したが、腕の見え方が不自然だったため、制作者が用意した歩行clipを優先して再生する必要がある。

### 変更内容

#### `mobile/assets/meguri-avatars/`
- `Megrum めぐり/v2/ねこ v2 歩き.glb` を `cat.glb` として取り込んだ。
- `Megrum めぐり/v2/きつね v2 歩き.glb` を `fox.glb` として取り込んだ。
- `Megrum めぐり/v2/うさぎ v2 歩き.glb` を `rabbit.glb` として取り込んだ。
- 3ファイルとも `Armature|walking_man|baselayer` の約1.06秒・32キー歩行clipを含むことを確認した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLB内に有効な歩行clipがある場合は `AnimationMixer` でそのclipを常時ループ再生するようにした。
- clip名は `walk` / `walking` / `歩き` を優先し、複数キーかつ0.1秒超のclipだけを有効な歩行clipとして扱うようにした。
- 有効な歩行clipがないGLBでは、iter168.8 の自前ボーンモーションへフォールバックする構成を残した。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- v2歩きGLBのanimation key数確認
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.9] v2歩きGLBのアニメーションを適用" --non-interactive`
- EAS Update: `019e5840-9ec1-7ae9-bf54-d2918c303fd6`
- EAS Update group: `8c6ad459-155c-4ba9-a05d-34770c4e76d5`

### 関連ファイル

- `mobile/assets/meguri-avatars/cat.glb`
- `mobile/assets/meguri-avatars/fox.glb`
- `mobile/assets/meguri-avatars/rabbit.glb`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 追加されたv2歩きGLBをアプリbundle対象のassetsへ反映
- ✅ `Armature|walking_man|baselayer` が32キーの歩行clipであることを確認
- ✅ 有効な歩行clipがあれば自前モーションより優先して `AnimationMixer` で再生
- ✅ 有効clipがない場合の自前モーションフォールバックは維持
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.8：v2ボーンへ自前歩行モーションを適用

### 背景・問題意識

オーナーから「めぐり演出中、Tポーズのままです。歩くようにして欲しいです。元々のアニメーションを使ってもらった方がいいのかな？初期の自前のやつ」と指摘があった。v2 GLB内の `Armature|clip0|baselayer` は実質1キーの静止clipで、常時再生しても歩行にならないため、初期実装の自前モーション方針へ戻す必要がある。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLB内蔵clip依存をやめ、v2モデルの `Hips` / `Spine` / `Head` / 手足ボーンへサイン波ベースの歩行モーションを毎フレーム適用するようにした。
- アバターのボーンrigを内側のアバターグループから外側の住人グループ経由で参照できるようにし、めぐり演出中の更新処理が確実にv2ボーンへ届くようにした。
- 腰の上下動は小さく抑え、腕・脚・足先・首の揺れで「常に歩いている」見え方を作るようにした。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.8] v2めぐりアバターに自前歩行を適用" --non-interactive`
- EAS Update: `019e5834-812b-76e7-83a2-abbf20230e21`
- EAS Update group: `a6cf2181-6e1e-4411-856b-3dcecf4187d6`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ GLB内蔵clipが静止1キーでも、v2ボーンへ自前歩行が適用される構成に変更
- ✅ アバターrig参照先のズレを修正し、外側の住人更新ループから内側のGLBボーンを更新
- ✅ 腰の上下動を抑え、手足と首の常時歩行表現を追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.7：v2アバターの歩行clipを常時再生

### 背景・問題意識

オーナーから「常に歩くモーションにしてもらっていい」と指示があった。iter168.6では移動時のみclip再生にしていたが、めぐり演出では静止時も歩くモーションを見せたい。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- v2 GLB内蔵clipを、移動中判定に関係なく常時 `AnimationMixer` で進めるようにした。
- 停止時に `stopAllAction()` / `skeleton.pose()` で待機ポーズへ戻す処理を削除した。
- 初回表示時にactionを開始し、その後は毎フレーム `mixer.update(delta)` するようにした。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.7] v2めぐりアバターを常時歩行モーション化" --non-interactive`
- EAS Update: `019e582c-22bd-7f45-864e-923d5b81237c`
- EAS Update group: `d59adb87-e1f7-40a6-a552-3e7f14cc4295`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ v2 GLB内蔵clipを常時再生するように変更
- ✅ 停止時に待機ポーズへ戻す処理を削除
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.6：v2アバターをさらに半分にして移動時だけ歩行clipを適用

### 背景・問題意識

オーナーから「さらに1/2くらいにしてほしい。その後、アニメーション追加。これは歩く時のアニメーションなので、移動する時のアニメーションにして」と指示があった。iter168.5で極端に縮小したうえで、内蔵clipは常時再生ではなく移動時だけ使う必要がある。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLB cloneの正規化目標高さを `AVATAR_MODEL_TARGET_HEIGHT = 0.0216` に変更し、iter168.5からさらに半分にした。
- v2 GLB内のanimation clipを `AnimationMixer` に登録し、キャラクターが移動している時だけ再生するようにした。
- 移動が止まったら `stopAllAction()` と `skeleton.pose()` で待機ポーズへ戻すようにした。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.6] v2めぐりアバターを縮小し移動時アニメーション化" --non-interactive`
- EAS Update: `019e5825-2ebf-75fe-bf08-7734e38e7373`
- EAS Update group: `0157e174-8b44-4b4e-85b3-e515efba3200`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ iter168.5からさらに1/2の正規化高さへ変更
- ✅ v2 GLB内蔵clipを移動時だけ再生
- ✅ 停止時はclipを止めてスケルトンポーズへ戻す
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.5：v2めぐりアバターを1/50相当に縮小

### 背景・問題意識

iter168.4 の縮小後も、オーナーから「1/50くらいにして」と追加指示があった。v2 GLBのボーン/スキン込みサイズが実機表示で大きく出ている可能性があるため、まず極端に縮小して表示有無と暴れ方を切り分ける。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLB cloneの正規化目標高さを `AVATAR_MODEL_TARGET_HEIGHT = 0.0432` に変更した。
- 元の正規化高さ `2.16` の約1/50相当まで、モデル本体だけを縮小した。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.5] v2めぐりアバターを1/50に縮小" --non-interactive`
- EAS Update: `019e5821-56f5-78cc-a99d-0c8f5e30221e`
- EAS Update group: `8c74a6a7-c42c-4a93-8b16-603e564da257`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 指示通り、元の正規化高さの約1/50相当まで縮小
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.4：v2めぐりアバターの表示サイズを縮小

### 背景・問題意識

オーナーから「サイズがでかすぎるのかもしれない。少し小さくしてほしい」と相談があった。v2 GLBは旧モデルより頂点数・テクスチャサイズ・リグが大きく、既存の正規化高さ `2.16` ではカメラや各シーン配置に対して大きくなりすぎる可能性がある。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLB cloneの正規化目標高さを `AVATAR_MODEL_TARGET_HEIGHT = 1.42` に変更した。
- 各シーンの配置・カメラ・キャラ間隔は維持し、モデル本体だけを約34%小さくした。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.4] v2めぐりアバターを縮小" --non-interactive`
- EAS Update: `019e581d-ac51-7703-8ce4-52b353585e3b`
- EAS Update group: `acf34c1a-ccff-4ea8-a76d-910e6dafb0b9`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ v2 GLB本体の正規化サイズだけを縮小し、シーン配置の副作用を抑えた
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.3：v2アバターを静止表示優先に切り戻し

### 背景・問題意識

iter168.2 後も、オーナーから「まだ何も表示されない」「めぐり演出を見ると挙動がはちゃめちゃになる」と報告があった。v2 GLBには `Armature|clip0|baselayer` が含まれているが、実アプリ上では配置・歩行演出と同時に再生するとリグポーズが大きく崩れる可能性がある。まずはv2モデルを安定して画面内に出すことを優先し、内蔵clip再生を止める必要がある。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- v2 GLBの内蔵animation clip再生を一旦停止した。
- `AnimationMixer` / action生成を外し、アプリ側のグループ移動・ゆらぎだけで配置するようにした。
- v2テクスチャ読み込みをGLB読み込みから分離し、テクスチャ読み込みに失敗しても白いモデルとして表示できるフォールバック材質を追加した。
- `SkeletonUtils.clone()` が実行環境で使えない場合は `template.clone(true)` に落ちるようにした。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィールの3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.3] v2めぐりアバター表示を安定化" --non-interactive`
- EAS Update: `019e5819-32a3-7295-9c7d-f8ee5579d3f3`
- EAS Update group: `6e9355a2-7368-44dc-8677-e13688129177`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ v2 GLB内蔵clipの自動再生を止め、表示安定を優先
- ✅ テクスチャ失敗時もモデル自体は表示される材質フォールバックを追加
- ✅ スキン付きcloneの実行環境差分に備えたfallbackを追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.2：旧めぐりアバターのフォールバック表示を抑止

### 背景・問題意識

iter168.1 後も、オーナーから「前作ったアバターが表示される」「何も表示されなくなっている」と報告があった。3Dシーン内部には、v2 GLBが読み込まれるまで旧プロシージャルアバターを一時表示する `fallbackGroup` が残っていた。また、3Dエラー時の画面フォールバックにも `WalkingCard` / 旧2D表現が残っており、v2が失敗した時に前のアバターへ戻って見える状態だった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 旧プロシージャルアバターの `fallbackGroup` を初期状態から非表示にし、v2 GLB読み込み中や失敗時にも前の3Dアバターを表示しないようにした。

#### `mobile/app/(tabs)/encounters.tsx` / `mobile/app/meguri-intro.tsx` / `mobile/app/meguri-plaza.tsx` / `mobile/app/meguri-profile.tsx`
- 3D失敗時のフォールバックを旧アバター表示からローダー表示へ変更した。
- v2表示が失敗した場合に、古いアバターへ戻って見える経路を閉じた。

### 影響範囲

- iOS版 めぐりホーム/めぐりイントロ/めぐり広場/めぐりプロフィールの3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.2] 旧めぐりアバター表示を抑止" --non-interactive`
- EAS Update: `019e5812-0317-7fc6-86ac-ebe1859c1ef0`
- EAS Update group: `c2eee321-eddf-44bc-86ce-5b51ce4d575c`

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-intro.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/app/meguri-profile.tsx`

### セルフレビュー結果

- ✅ v2 GLB読み込み前に旧プロシージャル3Dアバターを表示しない
- ✅ 3Dエラー時に旧 `WalkingCard` / 旧2Dアバターへ戻らない
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168.1：めぐりアバターv2の実機表示を修正

### 背景・問題意識

iter168 のEAS Update後、オーナーから「アプリを起動したがアバターが表示されない」と報告があった。v2 GLBはボーン/アニメーション入りだが、GLB内の埋め込み画像テクスチャ参照をそのまま `GLTFLoader` に処理させると、Expo実機側で読み込みが崩れる可能性がある。以前は外部テクスチャを `expo-asset` 経由で明示読み込みしており、この経路の方が実機で安定していた。

### 変更内容

#### `mobile/assets/meguri-avatars/*.glb`
- v2 GLBからアプリ実行時に不要な埋め込み画像参照を外し、形状・スキン・ボーン・animation clip を保持したGLBとして再出力した。

#### `mobile/assets/meguri-avatars/textures/*-v2.png`
- v2 GLB内の画像を外部PNGとして抽出し、Expo asset として明示読み込みできるようにした。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- v2 PNGを `expo-asset` 経由で読み、GLB読み込み後に `MeshStandardMaterial` へ貼り直す方式に変更した。
- `SkeletonUtils.clone()` と `AnimationMixer` は維持し、表示安定性とボーンアニメーション再生を両立した。

#### `mobile/app/(tabs)/encounters.tsx` / `mobile/app/meguri-avatar-edit.tsx` / `mobile/app/meguri-plaza.tsx` / `mobile/app/meguri-intro.tsx`
- アバター/プロフィール設定の読み込みに失敗してもローダーのまま止まらないよう、デフォルト設定へフォールバックする保険を追加した。

### 影響範囲

- iOS版 めぐり3D演出
- iOS版 めぐりホーム/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168.1] めぐりアバターv2表示を修正" --non-interactive`
- EAS Update: `019e580a-f5e0-73a5-b5d8-5c69668fcbcf`
- EAS Update group: `6e602946-c881-4c56-b815-9d7bd4c2aa53`

### 関連ファイル

- `mobile/assets/meguri-avatars/cat.glb`
- `mobile/assets/meguri-avatars/fox.glb`
- `mobile/assets/meguri-avatars/rabbit.glb`
- `mobile/assets/meguri-avatars/textures/cat-v2.png`
- `mobile/assets/meguri-avatars/textures/fox-v2.png`
- `mobile/assets/meguri-avatars/textures/rabbit-v2.png`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-avatar-edit.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/app/meguri-intro.tsx`

### セルフレビュー結果

- ✅ ボーンアニメーションはv2 GLB内の `Armature|clip0|baselayer` を利用している
- ✅ 実機で不安定になりやすいGLB埋め込み画像参照を外し、外部PNG読み込みに変更
- ✅ GLB側のスキン・ボーン・animation clip は保持
- ✅ 設定読み込み失敗時も3Dシーンがローダーのまま止まらない
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション168：めぐりアバターv2 GLBとボーンアニメーション適用

### 背景・問題意識

オーナーが `Megrum めぐり/v2/` に、ボーン入りの新しい `ねこv2.glb` / `きつねv2.glb` / `うさぎv2.glb` を追加した。既存実装はGLBを外部jpgテクスチャで上書きし、動きは手足の旧プロシージャルモデル側に付けていたため、v2に入っているスキン/アニメーションを活かせない構造だった。

### 変更内容

#### `mobile/assets/meguri-avatars/*.glb`
- `cat.glb` / `fox.glb` / `rabbit.glb` を v2 GLB に差し替えた。
- v2 GLB はそれぞれ `skins: 1` / `animations: 1` / 埋め込み画像ありで、アプリ側ではGLB内テクスチャを使用する。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLB内の埋め込みテクスチャを使うようにし、旧 `textures/*.jpg` の手動上書きをやめた。
- `SkeletonUtils.clone()` でスキン付きGLBを複製し、複数体表示でもボーンが共有破綻しないようにした。
- GLBに含まれる animation clip を `THREE.AnimationMixer` で再生し、移動中/待機中/会話中で再生速度を切り替えるようにした。

### 影響範囲

- iOS版 めぐり3D演出
- iOS版 めぐりホーム/めぐり広場/めぐりプロフィール/アバター編集の3D表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter168] めぐりアバターv2 GLBを適用" --non-interactive`
- EAS Update: `019e57fe-c704-77c8-afe6-0959864f0dbf`
- EAS Update group: `407ed231-1bb2-45b7-a735-ec576911c447`

### 関連ファイル

- `mobile/assets/meguri-avatars/cat.glb`
- `mobile/assets/meguri-avatars/fox.glb`
- `mobile/assets/meguri-avatars/rabbit.glb`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ v2 GLBにスキン・アニメーション・埋め込み画像が含まれていることを確認
- ✅ GLB内テクスチャを尊重し、旧jpgテクスチャ上書きを削除
- ✅ スキン付きモデルを安全に複製するため `SkeletonUtils.clone()` を使用
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション167：初回表示のプレビューデータちらつきを除去

### 背景・問題意識

オーナーから「グルームも、めぐりのアバターも、めぐりのメッセージ一覧も、最初にひらいたときにプレビュー用の別データが一瞬表示されるのが目障り」と指摘があった。実データやローカル設定を非同期読み込みする前に、モック配列やデフォルトアバターを初期stateへ入れていたため、本来のデータへ差し替わるまで別の内容が見えていた。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム投稿の初期stateを本番モードでは空配列にし、読み込み中はレール内ローダーを表示するようにした。
- プレビューモードの時だけ `GROOM_POSTS` を使うように分離した。
- めぐりホームの自分アバターは、保存済みアバター/プロフィール設定を読み込むまで3Dシーンへ渡さず、ローダーを表示するようにした。

#### `mobile/app/meguri-letters.tsx`
- めぐりメッセージ一覧で、プレビューモード以外は `LETTERS` / `USERS` 由来の静的会話を初期表示しないようにした。
- Plus設定・既読状態・グルーム返信・めぐり会話を一括で読み込んでから一覧を表示し、読み込み中はローダー、実データなしは空状態を表示するようにした。
- プレビュー用の返信文はプレビューモード時だけ追加するようにした。

#### `mobile/app/meguri-avatar-edit.tsx` / `mobile/app/meguri-plaza.tsx` / `mobile/app/meguri-intro.tsx`
- 自分のめぐりアバターを、保存済み設定の読み込み完了前にデフォルトのうさぎとして描画しないようにした。
- 読み込み中は3Dプレビュー/プラザ/イントロでローダーを表示し、別アバターが一瞬出る挙動を避けた。

#### `mobile/app/meguri-profile.tsx`
- 存在しないプロフィールIDで開いた時に `USERS[0]` へフォールバックせず、別ユーザーのプロフィールを見せない空状態へ変更した。

### 影響範囲

- iOS版 めぐりホームのグルームレールと自分アバター
- iOS版 グルーム閲覧入口
- iOS版 めぐりメッセージ一覧・スレッド
- iOS版 めぐりアバター編集・プラザ・イントロ・プロフィール

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter167] 初回表示のプレビューデータちらつきを除去" --non-interactive`
- EAS Update: `019e57f5-169c-796e-9de5-58a33cef739e`
- EAS Update group: `ec7e842e-40b2-4a1e-ad82-82d73a716523`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/meguri-avatar-edit.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/app/meguri-intro.tsx`
- `mobile/app/meguri-profile.tsx`

### セルフレビュー結果

- ✅ 本番モードではグルーム一覧に静的 `GROOM_POSTS` を初期表示しない
- ✅ 本番モードではめぐりメッセージ一覧に静的 `LETTERS` / `USERS` 由来の会話を初期表示しない
- ✅ 自分アバター設定読み込み前にデフォルトアバターを描画しない
- ✅ プロフィールID不一致時に別ユーザーへフォールバックしない
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID・用語・DBスキーマの追加変更なし

---

## イテレーション166：管理者機能と有料権限の基盤追加

### 背景・問題意識

オーナーから「完全な管理者機能を作れるように」と再レビュー依頼があった。ユーザー管理・権限管理・有料プラン管理を安全に扱うには、画面だけでなく「管理者をどう認可するか」「誰が何を変更したか」「Premium等の権限をどこで判定するか」をDB/RLS/Server Actionで分離する必要がある。

### 変更内容

#### `supabase/migrations/20260524200000_add_admin_security_and_billing.sql`
- `admin_roles` / `admin_audit_logs` を追加し、管理者ロール・細分化permission・MFA必須フラグ・監査ログをDB管理にした。
- `subscriptions` / `user_entitlements` / `plan_overrides` / `stripe_webhook_events` を追加し、Premium判定を `user_entitlements` に集約した。
- `is_admin()` / `admin_has_permission()` を追加し、RLSで管理者の読み取り範囲を制限した。

#### `web/src/lib/admin/permissions.ts`
- ログインユーザーの管理者ロール確認、permission確認、MFA(AAL2)確認、監査ログ保存の共通処理を実装した。

#### `web/src/app/admin/**`
- `/admin` 概要、`/admin/users` ユーザー管理、`/admin/roles` 権限管理、`/admin/billing` 有料プラン管理、`/admin/audit` 監査ログを追加した。
- ユーザー状態変更、管理者ロールupsert、手動有料権限上書きをServer Actionsで実装し、理由必須・監査ログ保存を通した。

#### `web/src/app/api/stripe/webhook/route.ts`
- Stripe webhookの署名検証、event_id冪等化、subscription upsert、Premium entitlement反映を実装した。

#### docs
- `notes/05_data_model.md` / `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/13_api_spec.md` に管理者・有料権限・webhookの状態と用語を追記した。

### 影響範囲

- Web版 管理者ページ `/admin`
- Supabase 管理者ロール、監査ログ、有料権限、Stripe webhook
- 設定画面の管理者リンク（管理者のみ表示）

### 確認方法

- `npm --prefix web install`
- `npm --prefix web run build`
- `supabase db push --dry-run`
- `supabase db push --yes`
- `npm --prefix web run lint`（既存のReact 19 purity系lintが複数あり失敗。今回追加ファイルはlintエラー対象に出ていない）

### 関連ファイル

- `supabase/migrations/20260524200000_add_admin_security_and_billing.sql`
- `web/src/lib/admin/permissions.ts`
- `web/src/app/admin/**`
- `web/src/app/api/stripe/webhook/route.ts`
- `web/src/app/settings/page.tsx`
- `web/.env.local.example`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 管理者変更はServer Action + service roleに閉じ、クライアントへ特権キーを渡さない
- ✅ 管理者ロール・ユーザー状態・有料権限変更は理由必須で `admin_audit_logs` に保存
- ✅ `requires_mfa=true` の管理者は AAL2 セッション必須
- ✅ 最後の `owner` 管理者を無効化・降格できないガードを追加
- ✅ Stripe webhookは署名検証・5分許容・event_id冪等化を実装
- ✅ Premium判定を `subscriptions` 生状態ではなく `user_entitlements` に集約
- ✅ `npm --prefix web run build` 成功
- ✅ `supabase db push --dry-run` 成功
- ✅ `supabase db push --yes` 成功
- ⚠️ `npm --prefix web run lint` は既存ファイルのReact purity lintで失敗（今回追加の管理者ファイルは指摘なし）
- ⚠️ 初回ownerはSupabase SQLで `admin_roles` に手動bootstrapが必要

---

## イテレーション165.1：グルーム返信画像の期限後表示を補強

### 背景・問題意識

iter165 実装後の再レビューで、グルーム投稿のStorage権限を `can_view_groom_post()` のみに寄せると、投稿が `expired` / `archived` になった後に、めぐりメッセージ内の「この人のストーリーズに返信しました」画像まで署名URLを再発行できなくなることが分かった。また、通報と非表示を同時実行すると、非表示が先に入った場合に通報RLSの可視性判定が落ちる可能性があった。

### 変更内容

#### `supabase/migrations/20260524152000_allow_groom_reply_snapshot_images.sql`
- `can_view_groom_object()` を更新し、`groom_replies.groom_snapshot.image_path` に残っている画像は、投稿期限後でも返信スレッド参加者だけ署名URLを発行できるようにした。

#### `mobile/src/lib/groom.ts`
- `reportGroomPost()` を `upsert` から `insert` に変更し、重複通報だけ無視するようにした。

#### `mobile/app/(tabs)/encounters.tsx` / `mobile/app/(tabs)/index.tsx`
- 通報後に非表示を実行する順序へ変更し、RLS上の可視性判定が通報前に失われないようにした。

#### `mobile/src/lib/meguriMessages.ts`
- 画像メッセージのDB保存に失敗した場合、先にアップロードしたStorage objectを削除して孤児ファイルを残しにくくした。

### 影響範囲

- iOS版 めぐりメッセージのグルーム返信画像表示
- iOS版 グルーム通報/非表示
- Supabase Storage RLS

### 確認方法

- `npm --prefix mobile run typecheck`
- `supabase db push --dry-run`
- `supabase db push --yes`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter165.1] グルーム返信画像の期限後表示を補強" --non-interactive`
- EAS Update: `019e57b5-3072-7854-b839-a496154f8e98`
- EAS Update group: `b120dbbe-4969-499c-90a2-52dc53dbd8d5`

### 関連ファイル

- `supabase/migrations/20260524152000_allow_groom_reply_snapshot_images.sql`
- `mobile/src/lib/groom.ts`
- `mobile/src/lib/meguriMessages.ts`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`

### セルフレビュー結果

- ✅ 期限切れ後も返信スレッド参加者だけグルーム返信画像を再表示できる
- ✅ 通報RLSが非表示処理に先に潰されない
- ✅ 画像メッセージ保存失敗時のStorage孤児化を軽減
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 新しい状態ID追加なし
- ✅ 既存用語の意味更新のみで新規用語追加なし

---

## イテレーション165：グルーム公開範囲とめぐり会話を永続化

### 背景・問題意識

グルーム機能の棚卸しで、公開範囲が実質的に絞れていないこと、投稿保存失敗時にローカルだけ投稿済みに見えること、グルーム返信後の通常会話が永続化されないこと、自分の投稿削除・相手投稿の非表示/通報/ブロック導線が未整備なことが分かった。オーナーから「全て上から順に実装」と指示があったため、DB/RLS/Storage/アプリUIまで一続きで修正した。

### 変更内容

#### `supabase/migrations/20260524143000_harden_groom_privacy_and_messages.sql`
- `groom-posts` Storage を private bucket に切り替え、`can_view_groom_post()` を満たす投稿だけ署名URLを発行できるようにした。
- `groom_audience_for_user()` を追加し、投稿時に同じ粗いエリアの active ユーザーを `audience_user_ids` へ入れるようにした。
- `groom_hidden_posts` / `groom_user_blocks` / `groom_reports` を追加し、非表示・ブロック・通報をDB管理にした。
- `meguri_messages` と `meguri-message-media` private Storage を追加し、グルーム返信後の通常会話と画像送信を永続化した。
- `notifications.kind='meguri_message'` と `notifications.meguri_message_id` を追加した。
- pg_cron が利用できる環境では `expire_groom_posts()` を15分ごとに実行するようにした。

#### `mobile/src/lib/groom.ts`
- グルーム画像を private Storage path として保存し、フィード取得時に署名URLへ差し替えるようにした。
- 投稿時に `audience_user_ids` / `area_key` を設定し、空配列公開をやめた。
- 自分の投稿アーカイブ、投稿非表示、投稿通報、ユーザーブロックのAPIラッパーを追加した。

#### `mobile/app/(tabs)/encounters.tsx`
- 投稿失敗時は optimistic 投稿を消し、編集画面に戻して再投稿できるようにした。
- グルームビューアのメニューから、自分の投稿削除、他人の投稿非表示、通報、ブロックを実行できるようにした。
- アプリ復帰時にもグルームフィードを再取得するようにした。
- グルーム返信に `groomImagePath` を渡し、期限切れ後も署名URLを再生成できるようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部のグルームにも、非表示・通報・ブロック・削除メニューとアプリ復帰時再取得を追加した。
- ホーム側のグルーム返信にも private Storage path を渡すようにした。

#### `mobile/src/lib/meguriMessages.ts` / `mobile/app/meguri-letters.tsx`
- `meguri_messages` の読み書き・既読更新・ローカルフォールバックを追加した。
- めぐりメッセージ画面で通常テキスト/画像送信をDBに保存し、再起動後や別端末でも復元できるようにした。
- グルーム返信画像と通常送信画像を private Storage の署名URLで表示するようにした。

#### `mobile/app/(tabs)/notifications.tsx`
- `meguri_message` 通知種別に対応した。

#### `notes/05_data_model.md` / `notes/09_state_machines.md` / `notes/10_glossary.md`
- グルーム公開範囲、private Storage、非表示/ブロック/通報、めぐり会話永続化を追記した。

### 影響範囲

- iOS版 めぐりホームのグルーム投稿・閲覧・返信・管理メニュー
- iOS版 ホーム画面上部のグルーム閲覧・返信・管理メニュー
- iOS版 めぐりメッセージの通常会話・画像送信・既読
- Supabase DB / Storage / RLS / notifications

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter165] グルーム公開範囲とめぐり会話を永続化" --non-interactive`
- EAS Update: `019e57af-4479-7d0c-b534-d236ed08e815`
- EAS Update group: `28b3994d-0e9c-4329-81e8-fc3f3931d44d`

### 関連ファイル

- `supabase/migrations/20260524143000_harden_groom_privacy_and_messages.sql`
- `mobile/src/lib/groom.ts`
- `mobile/src/lib/meguriMessages.ts`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/(tabs)/notifications.tsx`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ `audience_user_ids` 空配列を公開扱いにしないRLSへ変更
- ✅ `groom-posts` / `meguri-message-media` は private Storage + 署名URL表示
- ✅ 投稿失敗時はローカルだけ投稿済みになる状態を解消
- ✅ グルーム削除・非表示・通報・ブロック導線を追加
- ✅ めぐり返信後の通常会話を `meguri_messages` に永続化
- ✅ 期限切れはアプリ起動/復帰時に加え、利用可能な環境では pg_cron でも進行
- ✅ `supabase db push --dry-run` / `supabase db push --yes` 成功
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ データモデル・状態遷移・用語集を更新済み

---

## イテレーション164.1：グルーム写真の通常表示をクリア化

### 背景・問題意識

オーナーから、撮影した写真・アルバムから選んだ写真がまだモザイクになっているという指摘があった。過去仕様では、写真本体は常にクリアに表示し、ピンチアウトなどで画像を小さくした時だけ背面背景が単色グレーとして見える方針だった。実装をレビューしたところ、編集画面と閲覧画面で `imageTransform` がデフォルト値のままでも変形用レイヤーに入っており、初期表示でも通常の全画面 `Image cover` 経路を通らない状態になっていた。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- `isDefaultGroomImageTransform` を追加し、`rotation=0 / scale=1 / x=0 / y=0` の時は変形レイヤーを使わず、写真本体を通常の全画面 `Image resizeMode="cover"` で表示するようにした。
- 画像をピンチ・回転・移動した時だけ、単色グレー背景 + 変形画像レイヤーを表示するようにした。
- カメラ起動時に `getAvailablePictureSizesAsync()` から最大画質の `pictureSize` を選び、iOSでは `Photo`、なければ最大解像度/`High` を使うようにした。
- 撮影時に `maxDownsampling: 1` を指定し、撮影画像が不要に縮小されないようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム側グルームビューアにも同じデフォルト変形判定を追加し、DBからデフォルト `image_transform` が来ても写真本体はクリアな通常表示経路を通るようにした。

### 影響範囲

- iOS版 グルーム撮影後編集画面
- iOS版 めぐりホームのグルーム閲覧画面
- iOS版 ホーム画面上部のグルーム閲覧画面

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter164.1] グルーム写真をクリア表示に修正" --non-interactive`
- EAS Update: `019e55f4-e6e9-72f8-b137-f6bf29c273ff`
- EAS Update group: `b9d63a01-c630-4cd0-a1cd-60373626ffbf`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 仕様どおり、通常状態では写真本体にモザイク/ぼかし/背面レイヤーを重ねない
- ✅ ピンチアウトなどで画像を変形した時だけ背面の単色グレーが露出する
- ✅ 撮影時は利用可能な最大 `pictureSize` を選ぶようにした
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション164：グルームをDB連携へ移行

### 背景・問題意識

グルーム機能全体を棚卸しした結果、投稿・24時間ライフサイクル・ホーム側グルーム・返信・いいね/閲覧済みがローカルモック中心に残っていた。オーナーから「1から5まで実装」と指示があったため、グルームの主要データを Supabase 管理へ移し、プレビュー更新まで完了させた。

### 変更内容

#### `supabase/migrations/20260524100000_add_groom_backend.sql`
- `groom-posts` Storage bucket を作成し、ユーザー別フォルダアップロードと公開表示のRLSを追加。
- `groom_posts` を追加し、投稿写真・キャプション・編集変形・テキスト/手描き/スタンプ・24時間期限を保存するようにした。
- `expire_groom_posts()` を追加し、`published` の期限切れを `expired`、7日経過後を `archived` へ進めるようにした。
- `groom_reactions` / `groom_views` / `groom_replies` を追加し、いいね・閲覧済み・グルーム返信をDB管理へ移行。
- `notifications.kind='groom_reply'` と `notifications.groom_reply_id` を追加し、グルーム返信通知を作れるようにした。

#### `mobile/src/lib/groom.ts`
- グルームフィード取得、Storageアップロード、投稿作成、いいね更新、閲覧済み更新の Supabase API ラッパーを追加。
- フィード取得前に `expire_groom_posts()` を呼び、期限切れ投稿を通常表示から落とすようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホームのグルーム一覧を Supabase フィードから読み込むようにした。
- 新規グルーム投稿時は、ローカル即時表示後に Storage + `groom_posts` へ保存し、成功後にDB IDへ差し替えるようにした。
- いいねと閲覧済みを `groom_reactions` / `groom_views` に反映するようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム画面上部のグルームも同じ Supabase フィードを読むようにした。
- ホーム側ビューアの再オープンをセッションkeyで安定化し、縦dismissの native driver 混在を解消。
- ホーム側でも投稿編集後の画像変形・テキスト・手描き・スタンプを表示できるようにした。

#### `mobile/src/lib/meguriMessages.ts` / `mobile/app/meguri-letters.tsx`
- グルーム返信を `groom_replies` に保存し、ローカルAsyncStorageはフォールバック兼即時履歴として扱うようにした。
- 受信したグルーム返信をめぐりメッセージ一覧/スレッドへ表示し、開いたら `read_at` を更新するようにした。

#### `mobile/app/(tabs)/notifications.tsx`
- `groom_reply` 通知種別と `/meguri-letters?open=1&userId=...` 遷移に対応した。

#### `notes/05_data_model.md` / `notes/09_state_machines.md`
- グルーム関連テーブルとライフサイクル運用をDB実装に合わせて更新した。

### 影響範囲

- iOS版 めぐりホームのグルーム一覧・投稿・閲覧
- iOS版 ホーム画面上部のグルーム一覧・閲覧
- iOS版 グルーム返信からめぐりメッセージ/通知への導線
- Supabase DB / Storage / RLS

### 確認方法

- `supabase db push --dry-run`
- `supabase db push --yes`
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter164] グルームをDB連携" --non-interactive`
- EAS Update: `019e55ef-ebdd-7a17-b07d-9a08070a0e6e`
- EAS Update group: `338ec1fe-eb48-4555-95b1-5989ae066747`

### 関連ファイル

- `supabase/migrations/20260524100000_add_groom_backend.sql`
- `mobile/src/lib/groom.ts`
- `mobile/src/lib/meguriMessages.ts`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/(tabs)/notifications.tsx`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`

### セルフレビュー結果

- ✅ グルーム投稿が Storage + DB に保存される経路を追加
- ✅ `expires_at` による24時間表示制御と `expired` / `archived` 遷移関数を追加
- ✅ ホーム側グルームも同じフィードを参照し、再オープン安定化を反映
- ✅ グルーム返信をDB保存・通知・めぐりメッセージ既読へ接続
- ✅ いいね/閲覧済みをDB管理へ移行
- ✅ `supabase db push --yes` 成功
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 新規DB構造を `notes/05_data_model.md` に反映
- ✅ 状態運用の補足を `notes/09_state_machines.md` に反映
- ✅ 新規一般用語追加なしのため `notes/10_glossary.md` の更新は不要

---

## イテレーション163.4：グルーム再オープンクラッシュを修正

### 背景・問題意識

オーナーから、グルーム一覧をタップした時の開き方は改善されたが、2回目以降にグルームを開くとクラッシュするという指摘があった。開閉後に残るアニメーション状態や、native driver と JS driver の混在が再オープン時に影響している可能性があったため、ビューアのライフサイクルと dismiss アニメーションを安定化する必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルームビューアを `selectedGroomPost` がある時だけマウントする構成に変更し、閉じたらビューア内部の Animated.Value / responder / 入力状態が破棄されるようにした。
- グルーム一覧から開くたびに `groomViewerSession` を更新し、ビューアを新しい `key` で再生成するようにした。
- 縦方向 dismiss の `dismissY` アニメーションを `useNativeDriver: false` に統一し、PanResponder の JS 更新と native driver が混在しないようにした。

### 影響範囲

- iOS版 めぐりホームのグルーム一覧
- iOS版 グルームビューアの再オープン挙動
- iOS版 グルームビューアの縦スワイプ dismiss

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter163.4] グルーム再オープンクラッシュを修正" --non-interactive`
- EAS Update: `019e55d3-a539-7f79-8cc3-89a929340856`
- EAS Update group: `6c349b31-8643-481e-98d8-43284d6f60f8`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ グルームビューアを閉じたら完全にアンマウントする構成へ変更
- ✅ 再オープンごとにビューア内部状態を作り直すようにした
- ✅ `dismissY` の native/JS driver 混在を解消
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション163.3：グルーム写真をクリア表示へ修正

### 背景・問題意識

オーナーから、グルームをアルバム経由・写真撮影経由のどちらで作成しても、撮った写真そのものに強いモザイクがかかったように見えるという指摘があった。モザイク/ぼかしが必要なのは写真の後ろの背景レイヤーだけであり、その背景も単色グレーでよいという方針が示された。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム画像レイヤーの背面から、写真を `blurRadius` 付きで敷く背景処理を削除した。
- 背景レイヤーを単色グレーの `GroomStoryBackdrop` に変更した。
- 前面の写真画像に専用スタイルを追加し、写真本体は常にクリア表示されるようにした。
- グルーム編集画面のルート背景も同じ単色グレーに変更した。
- グルーム編集画面の全体シェードを削除し、ピンチアウト時に見える背面背景がそのまま単色グレーで表示されるようにした。
- カメラ撮影とアルバム選択の画像取得品質を `quality: 1` に引き上げた。

### 影響範囲

- iOS版 グルーム投稿編集画面
- iOS版 グルーム投稿閲覧画面
- iOS版 グルームカメラ/アルバム選択後の画像表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter163.5] グルーム編集背景を単色化" --non-interactive`
- EAS Update: `019e55d5-f09b-701d-842e-6f8cd2f5ae0f`
- EAS Update group: `1d654457-5656-46b4-a501-09bd5a1cee45`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ 写真本体に使われていた可能性のある背面ぼかし画像を削除
- ✅ 背景レイヤーを単色グレー化
- ✅ ピンチアウト時の背面背景に残っていた全体シェードを削除
- ✅ 前面写真はクリアな通常画像として表示
- ✅ カメラ/アルバムの取得品質を `quality: 1` へ変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション163.2：グルーム一覧タップ遷移を安定化

### 背景・問題意識

オーナーから、グルーム一覧をタップしてグルーム表示画面を開く時に、出現アニメーションが「ぼよん」と跳ねるのが嫌で、もっとスタイリッシュにぱっと表示されるだけでよいという指摘があった。あわせて、2回目以降にタップした時にクラッシュすることがあるため、再オープン時の安定性も改善する必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム一覧からビューアを開くアニメーションを `Animated.spring` から短い `Animated.timing` に変更した。
- 開く時のスケール補間から `1.035` のオーバーシュートを削除し、跳ねずに等倍へ収束するようにした。
- 開始元のリング計測値を `normalizeGroomOpenOrigin` で検証し、不正な座標・サイズの場合は通常表示へフォールバックするようにした。
- グルーム一覧アイテムの連続タップ中に複数の `measureInWindow`/open 処理が重ならないよう、短時間のオープンロックを追加した。

### 影響範囲

- iOS版 めぐりホームのグルーム一覧
- iOS版 グルームビューアのオープン遷移

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter163.2] グルーム一覧タップ遷移を安定化" --non-interactive`
- EAS Update: `019e55cd-48d6-7bcd-ac49-3e83351cd863`
- EAS Update group: `261fc98c-7e84-42de-b21c-fef73accfe7a`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ グルーム一覧タップ時のオーバーシュートを削除
- ✅ spring 由来の跳ね感を短い timing 遷移へ変更
- ✅ タップ元計測値の不正値をガード
- ✅ 連続タップ/再オープン時の open 処理重複を抑制
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション163.1：個別募集一覧を縦型カードへ変更

### 背景・問題意識

オーナーから、個別募集の一覧が横並びパネルになっていて見づらいため、縦に並べてスクロールで見られるようにしたいという要望があった。あわせて、各パネル右上の操作は編集を鉛筆、削除を×ボタンにし、削除時には「本当に個別募集を削除しますか？」の確認ポップアップを挟むこと、パネル内のグッズ/Wishは4件以上でも省略せずすべて表示することが求められた。

### 変更内容

#### `mobile/app/(tabs)/wishes.tsx`
- 個別募集一覧を横スクロールの募集デッキから、縦に積むカードリストへ変更した。
- 個別募集カード右上の操作を、編集の鉛筆アイコンと削除の×ボタンに整理した。
- カード右上の削除ボタン、および詳細シートの削除アクションから、個別募集削除確認モーダルを開くようにした。
- 削除確認モーダルの文言を「本当に個別募集を削除しますか？」にした。
- 個別募集カード内の「譲る」「求める」表示を、積み重ね/＋省略表示から折り返しグリッドへ変更し、登録されているグッズ/Wish/定価選択肢をすべて表示するようにした。

### 影響範囲

- iOS版 ウィッシュタブ内の個別募集一覧
- iOS版 個別募集カード操作
- iOS版 個別募集削除フロー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter163.1] 個別募集一覧を縦型カードへ変更" --non-interactive`
- EAS Update: `019e55c8-8f0b-707c-a7fb-3ba202605124`
- EAS Update group: `71fe69a3-e50f-4b33-9fcb-313de8ad0b58`

### 関連ファイル

- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ 個別募集一覧を縦並びに変更し、既存の画面スクロールで見られる構成にした
- ✅ カード右上の操作を編集=鉛筆、削除=×へ変更
- ✅ 削除前に確認ポップアップを挟むようにした
- ✅ 4件以上でも＋省略せず、登録済みの譲るグッズ/求めるWish/定価選択肢をすべてカード内へ表示
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション163：グルーム編集の画像/テキスト操作を拡張

### 背景・問題意識

オーナーから、アルバムからグルームを作成した時に画像へ強いモザイクがかかって見えるため、通常表示ではモザイクが出ないようにしたいという指摘があった。あわせて、グルーム編集のテキストは2本指ピンチで拡大縮小できるだけでなく、回転・位置調整もできるようにし、1本指で移動中に2本目を追加した場合もそのまま拡大縮小・回転へ移れるようにしたいという要望があった。さらに、何もない場所をタップしてテキスト入力開始、キャプション入力欄の文言変更、キーボード表示時の入力欄押し上げも求められた。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム画像の編集表示を contain 基準から cover 基準に変更し、初期状態では画像が画面全面を覆うようにした。
- 画像をピンチで縮小した時だけ、背面のぼかし/グラデーション背景が見えるようにした。
- テキストオーバーレイに `rotation` を追加し、投稿後の表示と編集画面の両方で回転を反映するようにした。
- テキストの2本指ジェスチャーで、拡大縮小に加えて回転と位置調整も同時にできるようにした。
- 1本指でテキストを移動している途中に2本目を追加した場合、その時点の位置・サイズ・角度を基準にピンチ/回転へ移行するようにした。
- グルーム編集画面の何もない場所をタップすると、その位置を初期配置先としてテキスト入力を開始できるようにした。
- 下部キャプション入力欄の placeholder を「キャプションを追加」に変更した。
- キャプション入力中にキーボードが出た時、下部入力欄がキーボード上へ押し上がるようにした。

### 影響範囲

- iOS版 グルーム投稿編集画面
- iOS版 グルーム投稿閲覧画面
- グルーム投稿の画像・テキストオーバーレイ表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter163] グルーム編集の画像テキスト操作を拡張" --non-interactive`
- EAS Update: `019e55c3-24c9-7566-b458-3b1dad2f9ea6`
- EAS Update group: `37b6dc0a-634f-4908-8370-2e6d97627370`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ アルバム画像の初期表示ではモザイク背景が露出しない cover 基準へ変更
- ✅ 画像縮小時のみ背面のぼかし/グラデーション背景が見える構成を維持
- ✅ テキストのピンチ拡大縮小・回転・位置調整に対応
- ✅ 1本指移動中の2本目追加からピンチ/回転へ移行可能
- ✅ 空白タップからテキスト入力開始可能
- ✅ キャプション placeholder を「キャプションを追加」に変更
- ✅ キャプション入力欄がキーボード上へ移動
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.99：在庫/Wish/ホームカード下部をタグ表示へ変更

### 背景・問題意識

オーナーから、マイ在庫・ウィッシュ・ホーム画面の各パネル下部に、グループ名やグッズ種別ではなく、登録されているタグを `# タグ名` の形で表示したいという要望があった。あわせて、個別募集を設定する際に、譲るものとして定価も設定できるようにしたいという要望があった。

### 変更内容

#### `mobile/src/lib/inventoryTags.ts`
- `goods_inventory_tags` から在庫/Wishのタグラベルをまとめて取得する helper を追加した。
- 表示用に `# タグ名` 形式へ整形する `formatHashTags` を追加した。

#### `mobile/src/components/GoodsGrid.tsx`
- 共通グッズパネルの下部表示を `subtitle` ではなく `tagLabels` 優先に変更した。
- タグがない場合は、グループ名/種別ではなく「タグ未設定」を表示するようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫一覧の取得時に登録タグを読み込み、各パネル下部へ反映した。
- プレビュー在庫にもタグ表示用のサンプルタグを追加した。
- 選択時のポップオーバーにもタグ表示を優先するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish一覧の取得時に登録タグを読み込み、各パネル下部へ反映した。
- プレビューWishにもタグ表示用のサンプルタグを追加した。
- 選択時のポップオーバーにもタグ表示を優先するようにした。

#### `mobile/src/data/homeMatches.ts`
- ホームプレビュー候補に `tagLabels` を追加した。

#### `mobile/src/data/homeSupabase.ts`
- Supabase から取得済みのタグラベルをホーム候補の `tagLabels` として渡すようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム候補パネル下部からグッズ種別キャプションを削除し、登録タグを `# タグ名` 形式で表示するようにした。

#### `mobile/app/listing-editor.tsx`
- 個別募集の「譲るグッズ」セクションに「定価でも譲る」トグルを追加した。
- トグルON時は既存の `listing_wish_options.is_cash_offer / cash_amount` を使い、定価交換選択肢として保存するようにした。
- Wishが未登録でも、譲る候補があれば定価交換の個別募集を作れるようにした。

### 影響範囲

- iOS版 マイ在庫一覧
- iOS版 ウィッシュ一覧
- iOS版 ホーム候補パネル
- iOS版 個別募集作成/編集
- `goods_inventory_tags` の読み取り表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.99] 在庫Wishホームをタグ表示へ変更" --non-interactive`
- EAS Update: `019e55bc-5e47-7893-a102-f585b07f0ba3`
- EAS Update group: `1981e3ce-a7a8-4221-beb0-d03013c4c4b1`

### 関連ファイル

- `mobile/src/lib/inventoryTags.ts`
- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/src/data/homeMatches.ts`
- `mobile/src/data/homeSupabase.ts`
- `mobile/app/listing-editor.tsx`

### セルフレビュー結果

- ✅ マイ在庫パネル下部はタグ表示に変更
- ✅ Wishパネル下部はタグ表示に変更
- ✅ ホーム候補パネル下部はタグ表示に変更
- ✅ グループ名/グッズ種別をパネル下部に出さない構成に変更
- ✅ 個別募集の譲る側から定価交換選択肢を作成可能
- ✅ Wish未登録でも譲る候補 + 定価で個別募集を作れる構成に変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 既存DBカラム `listing_wish_options.is_cash_offer/cash_amount` を使うため新規 migration は不要
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.98：グルーム画像のピンチ回転編集を追加

### 背景・問題意識

オーナーから、グルーム編集でテキストがない場所を2本指でピンチして画像サイズを調整し、向きも変えられるようにしたいという要望があった。さらに、画像を縮小した時の余白は単色ではなく、添付画像のようにグラデーションのかかったモザイク調背景にしたいという指定があった。テキストについても、入力後の文字を2本指で拡大縮小できるようにしたいという要望があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム投稿データに `imageTransform` を追加し、画像の拡大率・回転角・位置を投稿後も保持できるようにした。
- グルーム編集画面で、テキストや描画ツールを触っていない状態の2本指ジェスチャーを画像操作として扱い、ピンチで拡大縮小、2本指の角度変化で回転、中心点移動で位置調整できるようにした。
- 編集画面と投稿閲覧画面の画像表示を共通化し、変形済み画像の背面にぼかし画像＋紫/水色/ピンクのグラデーション＋淡いモザイク面を表示するようにした。
- 既存のテキストオーバーレイ操作は、2本指ピンチ時の文字サイズ変更範囲を広げ、小さくする/大きくする操作をしやすくした。
- `imageTransform` がない既存グルームは従来通り全画面 cover 表示を維持し、既存投稿の見え方を不用意に変えないようにした。

### 影響範囲

- iOS版 グルーム投稿編集画面
- iOS版 グルーム投稿閲覧画面
- グルーム投稿のテキストオーバーレイ操作

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.98] グルーム画像のピンチ回転編集を追加" --non-interactive`
- EAS Update: `019e55b4-3c4f-71a7-abf4-a62d385d5f02`
- EAS Update group: `5ed11112-60fa-4807-85cd-77a91104d38b`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ 画像のピンチ縮小/拡大、2本指回転、位置調整を追加
- ✅ 画像縮小時にぼかし＋グラデーション＋モザイク調の背景が出る構成に変更
- ✅ 投稿後も `imageTransform` を保存して閲覧画面に反映
- ✅ 既存グルームは `imageTransform` 未設定なら従来の cover 表示を維持
- ✅ テキストオーバーレイのピンチ拡大縮小範囲を拡張
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.97：タグサジェストを登録件数順に変更

### 背景・問題意識

オーナーから、タグは入力中にサジェストが出るようにし、登録件数を表示し、登録件数が多い順にサジェストしてほしいという要望があった。既存実装では `search_tags` RPC の候補をそのまま横チップで表示しており、登録件数が見えず、入力ありの場合は前方一致・類似度が登録件数より優先されていた。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- タグ検索結果を多めに取得し、モバイル側で `userCount` の多い順へ並べ替えるようにした。
- サジェスト表示に `登録◯件` を追加した。
- サジェストを横並びチップから、タグ名と登録件数を読みやすい1行リストへ変更した。
- 既に選択済みのタグはサジェスト候補から除外するようにした。
- 通常のグッズ/ウィッシュ編集と、複数写真からのまとめ登録フローの両方に同じサジェスト挙動を反映した。

### 影響範囲

- iOS版 グッズ登録/編集のタグ入力
- iOS版 ウィッシュ登録/編集のタグ入力
- iOS版 複数写真まとめ登録の共通タグ入力

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.97] タグサジェストを登録件数順に変更" --non-interactive`
- EAS Update: `019e55ac-aef1-78ed-a955-5b988cd921a1`
- EAS Update group: `f185f537-7858-4bf7-a16c-2edbc21db13d`

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ 入力中のタグサジェストに登録件数を表示
- ✅ サジェストは登録件数の多い順に並べ替え
- ✅ 選択済みタグは候補から除外
- ✅ 通常編集とまとめ登録の両方に反映
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.96：グルーム編集のタグ削除とテキスト操作改善

### 背景・問題意識

オーナーから、グルーム編集機能のタグ登録は不要であり、入力したテキストをタップしても自由に動かせないため、指のスワイプに追従して移動できるようにしたいという指摘があった。あわせて、テキスト入力中は添付画像のように背景が薄暗くなり、画面上で直接文字を入力している見え方にしたいが、左バー、字体変更、メンション、位置情報などは不要という要望があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム編集画面のタグ/スタンプ追加ボタンとプリセット選択トレイを削除した。
- 新規投稿時にタグ/スタンプ情報を追加しないようにした。
- テキスト入力中は画面全体に暗い編集レイヤーを出し、右上の「完了」と大きめの直接入力欄を表示する構成に変更した。
- テキスト入力中は背景写真を薄暗くし、通常のキャプション入力や投稿ボタンを一時的に隠すようにした。
- テキストの色・表示トーンだけを下部に残し、字体変更、メンション、位置情報に相当する操作は追加しない構成にした。
- 既存テキストのドラッグ移動を `gesture.dx/dy` だけに頼らず、タッチの絶対座標とキャンバス位置から再計算する方式へ変更し、指のスワイプに追従しやすくした。

### 影響範囲

- iOS版 グルーム投稿編集画面
- グルーム投稿のテキストオーバーレイ操作
- グルーム投稿のタグ/スタンプ追加導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.96] グルーム編集テキスト入力を修正" --non-interactive`
- EAS Update: `019e55a7-04c0-70ce-a336-f07f7602ef8f`
- EAS Update group: `cb5bf269-d5a0-46a5-86c5-ba6facc34a2a`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ タグ/スタンプ登録UIは編集画面から削除
- ✅ テキスト入力中は背景が薄暗くなり、直接入力風のUIを表示
- ✅ 左バー、字体変更、メンション、位置情報の機能は追加なし
- ✅ 既存テキストの移動はタッチ位置ベースで更新
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.95：グルームカメラをシンプル化し最新写真入口を追加

### 背景・問題意識

オーナーから、グルームのカメラ画面左側にある `Aa` などの編集アイコンと、画面下部の「投稿／ストーリーズ／リール／ライブ」は不要であり、右下に置いていたアルバム起動アイコンは左端へ移して、自分のアルバムの最新写真がサムネイル表示される形にしたいという要望があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- カメラ画面左側のツールレールを表示しないようにした。
- カメラ画面下部の投稿種別ラベルを表示しないようにした。
- アルバム起動ボタンを右下から左下へ移動した。
- `expo-media-library` で写真ライブラリの最新写真を取得し、アルバム起動ボタン内にサムネイル表示するようにした。
- 写真権限がない場合や最新写真が取れない場合は、カメラアイコンのフォールバックを表示するようにした。

#### `mobile/package.json`
- `expo-media-library` を追加した。

#### `mobile/app.config.js`
- Expo config plugin に `expo-media-library` を追加した。

### 影響範囲

- iOS版 グルーム投稿カメラ
- iOS版 グルーム投稿のアルバム選択導線
- `expo-media-library` 追加により、反映には OTA ではなく preview/native rebuild が必要

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run config:ios:preview`
- `npm --prefix mobile run export:ios:preview`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/package.json`
- `mobile/package-lock.json`
- `mobile/app.config.js`

### セルフレビュー結果

- ✅ 左側の `Aa` などのツールアイコンは非表示化
- ✅ 下部の投稿種別ラベルは非表示化
- ✅ アルバム入口は左下配置へ変更
- ✅ アルバム入口に最新写真サムネイルを表示する処理を追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run config:ios:preview` で `expo-media-library` plugin 追加を確認
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ⚠️ `expo-media-library` はネイティブ依存のため、直前に作成済みの preview build には含まれていない。反映には再度 EAS preview build が必要
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.94：グルーム一覧から閲覧へ拡大遷移

### 背景・問題意識

オーナーから、グルーム一覧でグルームをタップした時に、単に閲覧画面へ切り替わるのではなく、一覧上のグルームから画面がブワッと拡大されてグルームを見る感じにしたいという要望があった。既存実装は `selectedGroomId` をセットして `Modal` を表示するだけだったため、タップした一覧アイコンと閲覧画面のつながりが弱かった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム一覧アイコンの `measureInWindow` で、タップされた丸アイコンの画面上の位置・サイズを取得するようにした。
- `GroomOpenOrigin` を追加し、一覧から閲覧モーダルへ起動元の矩形情報を渡すようにした。
- `GroomViewerModal` に入場用の `openProgress` を追加し、起動元アイコンの中心から全画面へスケールアップするスプリングアニメーションを追加した。
- 入場時はモーダルの標準 fade ではなく、アプリ側で背景暗転と閲覧画面の拡大を制御するようにした。
- 横スワイプ中・下スワイプで閉じる既存挙動はそのまま維持し、入場アニメーションは一覧から新規に開いた時だけ走るようにした。

### 影響範囲

- iOS版 めぐりホームのグルーム一覧
- iOS版 グルーム閲覧モーダルの入場演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ 一覧アイコンの実測位置からグルーム閲覧画面が拡大表示される
- ✅ 閲覧中の左右スワイプ切り替えでは入場拡大を再発火しない
- ✅ 既存の下スワイプ終了、返信入力、プロフィールスライド導線を維持
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.93：グルーム投稿カメラとテキスト編集を拡張

### 背景・問題意識

オーナーから、グルームで起動するカメラをシステムカメラではなくストーリーズ投稿に近い全画面カメラ構成にしたい、右下からアルバムを開いてアップロードできるようにしたい、さらに投稿編集画面で入力したテキストを1本指で移動、2本指で拡大縮小、タップで再編集できるようにしたいという要望があった。既存実装は `expo-image-picker` の `launchCameraAsync` に寄っていたため、撮影UIをアプリ側で制御できず、テキストも追加後の直接編集・ジェスチャ操作ができなかった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- `expo-camera` の `CameraView` を使う `GroomCameraModal` を追加し、グルーム投稿の撮影画面を全画面プレビュー構成にした。
- カメラ画面の右下にアルバム起動ボタンを置き、写真ライブラリから選択した画像も同じ編集画面へ流すようにした。
- カメラ画面にクローズ、前後カメラ切替、左側ツールレール、下部モードタブを配置し、添付参考に近いストーリーズ投稿カメラの骨格にした。
- 既存の `openGroomCamera` をシステムカメラ起動からアプリ内カメラモーダル起動へ変更した。
- 編集画面のテキストオーバーレイに `scale` を追加し、1本指ドラッグで移動、2本指ジェスチャで拡大縮小できるようにした。
- テキストオーバーレイをタップすると、入力トレイに既存の文字・色・トーンを戻して再編集できるようにした。
- 描画レイヤーと編集可能テキストレイヤーを分離し、描画ツール使用時だけ doodle の PanResponder が有効になるようにした。

#### `mobile/package.json`
- `expo-camera` を追加した。

#### `mobile/app.config.js`
- Expo config plugin に `expo-camera` を追加し、iOSビルドへネイティブカメラモジュールを組み込めるようにした。

### 影響範囲

- iOS版 グルーム投稿カメラ
- iOS版 グルーム投稿編集画面
- グルーム投稿の画像アップロード導線
- グルーム投稿内テキストオーバーレイの編集操作
- `expo-camera` 追加により、反映には OTA ではなく preview/native rebuild が必要

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run config:ios:preview` で `expo-camera` plugin が含まれることを確認
- `npm --prefix mobile run build:ios:preview -- --non-interactive`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/package.json`
- `mobile/package-lock.json`
- `mobile/app.config.js`

### セルフレビュー結果

- ✅ グルーム投稿カメラはアプリ内 `CameraView` の全画面プレビュー構成へ変更
- ✅ 右下アルバムボタンから画像選択して編集画面へ進める導線を追加
- ✅ テキストオーバーレイは1本指移動、2本指拡大縮小、タップ再編集に対応
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ `expo-camera` は Expo config plugin に追加済み
- ⚠️ `expo-camera` はネイティブ依存のため、端末反映には EAS preview build の再作成が必要
- ⚠️ 初回の EAS preview build は Xcode の `Invalid expression encountered` で失敗。オーナー側ターミナルで再実行し、同じ場合は Xcode log を追加確認する
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.92：関係図選択と打診match_typeを修正

### 背景・問題意識

オーナーから、ホーム画面から関係図を経由して提示物の選択画面へ進んだ時に、関係図で選んだ「私が出すもの」「受け取るもの」が選択状態になっていないこと、さらに打診送信時に `new role for relation "proposals" violates check constraint "proprosals_match_type_check"` が出るという報告があった。調査の結果、関係図画面では選択後もホームカード由来の route `gives/receives` が優先される場合があり、送信確認ではモバイル側の `complete/they_want_you/you_want_them` をDB制約が許可する `perfect/forward/backward` に変換していなかった。

### 変更内容

#### `mobile/app/match-detail.tsx`
- 関係図で選択がある場合は、route params の初期 `gives/receives/listings` よりも関係図の集約結果を優先して `proposal-select` に渡すようにした。
- 相手側の個別募集で、ハイライトされている相手の譲が listing have 側にある場合も、対応する候補を初期選択するようにした。
- AND条件では各wishの先頭候補を、OR条件では先頭の候補を初期選択する補助関数を追加した。

#### `mobile/app/proposal-confirm.tsx`
- 送信前に `matchType` をDB正規値へ変換するようにした。
  - `complete` → `perfect`
  - `you_want_them` → `forward`
  - `they_want_you` → `backward`
- 既に正規値の `perfect/forward/backward` が来た場合はそのまま扱うようにした。

### 影響範囲

- iOS版 ホーム → 関係図 → 提示物選択
- iOS版 提示物選択 → 送信確認 → 打診送信
- `proposals.match_type` 保存値

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.92] 関係図選択と打診match_typeを修正" --non-interactive`
- EAS Update: `019e5580-36c5-7350-9b69-249190424d0b`
- EAS Update group: `139b77d8-cba0-42fe-a32d-1569a37a87b7`

### 関連ファイル

- `mobile/app/match-detail.tsx`
- `mobile/app/proposal-confirm.tsx`

### セルフレビュー結果

- ✅ 関係図で選択した提示物を `proposal-select` の初期選択へ優先反映
- ✅ 相手側 listing have がハイライトされたケースでも初期候補を選択
- ✅ `proposals.match_type` は `perfect/forward/backward` のDB正規値で送信
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.91：グルームUIをキューブ面へ追従

### 背景・問題意識

オーナーから、グルーム横スワイプ中は進捗ステータスが止まること、さらにグルーム画像上のユーザーネーム・進捗バー・画面下部のメッセージ入力欄も画像と同じ3Dキューブ面に貼り付いて動くことを求められた。前iterまでは画像面だけがキューブ化され、UIクロームは画面上に固定されていたため、キューブの外側に1枚のストーリー画面が貼られている感覚が弱かった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- 横スワイプ開始時に `horizontalSwiping` を立て、進捗アニメーションを停止して現在値を保持するようにした。
- 横スワイプ終了・キャンセル時に `horizontalSwiping` を解除し、保持した進捗値から再開するようにした。
- `GroomStoryAttachedChrome` を追加し、進捗バー・ユーザー名・時刻・キャプション・入力欄風UI・いいね/送信アイコンをキューブ面の子要素として描画するようにした。
- 通常時の操作可能なヘッダー/入力欄は残しつつ、スワイプ中は透明化し、面に貼った非操作UIが動いて見える構成にした。
- next / previous 面の進捗バーも、そのユーザー側のストーリー本数に合わせた静止バーとして表示するようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部グルーム閲覧にも同じ `horizontalSwiping` 停止制御を反映した。
- `HomeGroomStoryAttachedChrome` を追加し、ホーム側の進捗・ユーザー名・キャプション・入力欄風UIもキューブ面に追従させた。
- next / previous 面では、遷移先/遷移元の進捗位置に合わせた静止バーを表示するようにした。

### 影響範囲

- iOS版 グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルームの横スワイプ切り替え演出
- グルーム閲覧中のストーリー進捗制御

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.91] グルームUIをキューブ面へ追従" --non-interactive`
- EAS Update: `019e557a-5b08-7426-9ecf-f615858200c6`
- EAS Update group: `f6175664-6692-45c3-9247-e3047afc795d`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 横スワイプ中は進捗アニメーションを停止し、終了後に保持値から再開
- ✅ ユーザー名・進捗バー・キャプション・入力欄風UIをキューブ面へ追従
- ✅ 通常時の入力欄は操作可能なまま維持
- ✅ グルームタブとホーム側グルームの両方へ反映
- ✅ ネイティブ依存追加なし
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.90：グルームキューブ面の隙間を解消

### 背景・問題意識

オーナーから、グルーム横スワイプ時の動き自体は良くなったが、前のグルームと次のグルームの間に隙間ができるという指摘があった。前iterでは current / next / previous の動きはキューブらしくなったが、面の `left` 補間がキューブの回転エッジ位置と一致しておらず、スワイプ途中で壁面同士の辺が離れて見える瞬間があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- current / next / previous の `left` 補間を半幅基準に揃え、回転中の辺同士が同じX位置で接続するようにした。
- 実機描画のアンチエイリアスで細い穴が出ないよう、面同士に `1px` の重なりを追加した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム側グルーム閲覧にも同じ半幅基準と `1px` 重なりを反映した。

### 影響範囲

- iOS版 グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルームの横スワイプ切り替え演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.90] グルームキューブ面の隙間を解消" --non-interactive`
- EAS Update: `019e5570-bb18-739f-b2a7-95c7e76966f7`
- EAS Update group: `f6bd5d85-5bfb-4d77-8bad-d342ebc5d81f`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ キューブ面の辺位置を半幅基準に揃えた
- ✅ 実機の細い隙間対策として1pxの面重なりを追加
- ✅ グルームタブとホーム側グルームの両方へ反映
- ✅ ネイティブ依存追加なし
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.89：グルーム現面のキューブ回転を調整

### 背景・問題意識

オーナーから、グルーム横スワイプ時の次のグルーム画像は良くなった一方、スワイプ前の現在画像がその場でY軸回転しているように見えるという指摘があった。前iterの仮想キューブ化では、incoming 面は `left + rotateY` で壁面から正面へ動いていたが、current 面は `left` が固定のまま回っていたため、同じキューブの壁面としてつながって見えなかった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- current 面を、次面の逆アニメーションとして `left + rotateY` を連動させる形に変更した。
- 左スワイプ時は current 面が右端支点で左壁へ逃げ、右スワイプ時は左端支点で右壁へ逃げるようにした。
- current / previous / next それぞれの側面シェードを、正面では薄く、壁面では濃くなるように整理した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム側グルーム閲覧にも同じ current 面の逆アニメーションを反映した。
- ホーム側の側面シェードもグルームタブ側と同じ挙動にした。

### 影響範囲

- iOS版 グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルームの横スワイプ切り替え演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.89] グルーム現面のキューブ回転を調整" --non-interactive`
- EAS Update: `019e556c-d8d1-7b4b-956a-e1a56eaedff0`
- EAS Update group: `c3a91470-eda0-442c-b954-89e674b0d427`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ current面がその場回転に見える原因だった `left: 0` 固定を解消
- ✅ 次面の逆アニメーションとして current面にも `left + rotateY` を適用
- ✅ 左右スワイプ両方で端支点が自然になるよう current面を2系統で描画
- ✅ ネイティブ依存追加なし
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.88：グルーム横スワイプを仮想キューブ化

### 背景・問題意識

オーナーから、グルームを横スワイプした時に画像が裂けたように見え、3Dキューブの外側にそれぞれのグルーム画像が貼られてぐるっと回る体験になっていないという指摘があった。前iterまでの実装は current 面を左右方向用に2枚描画し、next/previous を別面として重ねていたため、スワイプ途中に中央の縦割れや不自然な帯が出やすかった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧の横スワイプを `GroomStoryCube` 構造に変更した。
- current を1枚の前面として中心軸で回転させ、previous / next を左右の壁面として表示する構成にした。
- previous / next 面はスワイプ量に応じて `left` と `rotateY` を同時に変化させ、仮想キューブ外側の面に画像が貼られているようにした。
- 側面に薄いシェードを入れ、壁面として奥行きが出るようにした。
- `left` をアニメーションするため、横スワイプの `swipeX` アニメーションは JS driver に変更した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム側のグルーム閲覧にも同じ `HomeGroomStoryCube` 構造を反映した。
- current 分割描画をやめ、ホーム側でも前面＋左右壁面の仮想キューブとして回るようにした。

### 影響範囲

- iOS版 グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルームの横スワイプ切り替え演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.88] グルーム横スワイプを仮想キューブ化" --non-interactive`
- EAS Update: `019e5567-2b6f-73ee-b50c-233f8092bffb`
- EAS Update group: `02e6b0f6-e070-496a-bbd7-7a05b1387f51`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ current面の二重描画を撤去し、中央の縦割れ原因を除去
- ✅ previous / next を左右の壁面として扱う仮想キューブ構造へ変更
- ✅ グルーム画面とホーム側グルームの両方へ同じ方針を反映
- ✅ ネイティブ依存追加なし
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.87：メールログイン導線を明確化

### 背景・問題意識

オーナーから、メールアドレスとパスワードでログインできるようにしたいという指示があった。既存実装には Supabase Auth の `signInWithPassword` とログイン画面自体は存在していたが、Welcome画面ではメール新規登録が主導線で、ログインは小さなテキストリンクに留まっていた。実利用時にメール/パスワードログインが見つけづらいため、ログイン導線を明示し、ログイン成功後の遷移も確実にした。

### 変更内容

#### `mobile/app/(auth)/welcome.tsx`
- Welcome画面の最上位アクションとして「メールアドレスでログイン」ボタンを追加した。
- 新規登録系の導線は「はじめての方」で区切り、利用規約同意後に進む構成へ整理した。
- 既存の小さなログインテキストリンクを廃止し、ログイン導線を押しやすいボタンにした。

#### `mobile/app/(auth)/login.tsx`
- ログインボタンの文言を「メールアドレスでログイン」に変更した。
- メール/パスワード入力に `autoComplete` / `autoCorrect={false}` を付け、iOSで入力しやすくした。
- ログイン成功時に `router.replace("/")` で明示的にホームへ進むようにした。

#### `mobile/src/auth/AuthProvider.tsx`
- メール/パスワードログイン成功時に `users.last_login_at` を更新するようにした。
- 何らかの理由で `auth.users` は存在するが `public.users` が無いユーザーでも、ログイン時に最低限のプロフィール行を補完するフォールバックを追加した。
- Appleログイン側も同じプロフィール補完を通すようにした。

### 影響範囲

- iOS版 Welcome画面
- iOS版 ログイン画面
- iOS版 Supabase Auth セッション確立後のプロフィール同期

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.87] メールアドレスログイン導線を明確化" --non-interactive`
- EAS Update: `019e5560-7e85-7eb5-814f-a3bad68cdae3`
- EAS Update group: `6092e63b-e49e-445a-9787-88297ffc71a5`

### 関連ファイル

- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/login.tsx`
- `mobile/src/auth/AuthProvider.tsx`

### セルフレビュー結果

- ✅ メール/パスワードログインがWelcome画面から明確に選べる
- ✅ Supabase Auth の `signInWithPassword` 経路を維持
- ✅ ログイン成功後のホーム遷移を明示
- ✅ 既存DBカラム `last_login_at` の利用のみで、新規DB変更なし
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB構造変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.86：チャット送信グラデーションを再調整

### 背景・問題意識

オーナーから、前iterで直した取引チャット・めぐりあいチャットのメッセージグラデーションがまだおかしいという指摘があった。前回は滑らかな描画にはなったが、各吹き出し単体に斜め方向で強く色変化するため、Instagram風のチャットバブルとしては主張が強く、紫〜水色の自然な面に見えづらかった。

### 変更内容

#### `mobile/src/components/ChatGradientBubble.tsx`
- 送信側グラデーションの中間色を、強い青からブランド紫〜水色の段階補間へ変更した。
- グラデーション方向を斜めの強い変化から、ほぼ横方向に穏やかにつながる流れへ変更した。
- `megrumColors.lavender` / `megrumColors.sky` を起点にし、ブランド色との整合を取り直した。
- 相手側メッセージは引き続き単色背景のまま維持した。

### 影響範囲

- iOS版 取引チャット
- iOS版 めぐりあいチャット
- 共通チャット吹き出しコンポーネント

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.86] チャット吹き出しグラデーションを再調整" --non-interactive`
- EAS Update: `019e5553-e782-7d47-9cc4-76e7bb1b9ba6`
- EAS Update group: `4748e8b9-03b4-4272-843d-a1d832a2fa38`
- EAS iOS preview build: `https://expo.dev/accounts/mashima.bizz/projects/megrum/builds/1c89da23-9a08-4d9b-a19c-dccd8ef14942`

### 関連ファイル

- `mobile/src/components/ChatGradientBubble.tsx`

### セルフレビュー結果

- ✅ 送信側だけグラデーション、受信側は単色背景の仕様を維持
- ✅ 紫〜水色以外の強い色味を抑制
- ✅ ブランドカラー起点の自然な補間へ変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.85：チャット送信吹き出しを滑らかに調整

### 背景・問題意識

オーナーから、取引チャット・めぐりあいチャットのメッセージ吹き出しグラデーションがInstagramのチャットと全然違うという指摘があった。Instagram DMの送信側バブルは紫〜青系の滑らかなグラデーション、受信側はグレー/無地に見える整理のため、前iterで入れた色帯を重ねる疑似グラデーションではなく、送信側だけネイティブのリニアグラデーションで描画する必要があった。

### 変更内容

#### `mobile/src/components/ChatGradientBubble.tsx`
- `expo-linear-gradient` を使い、自分から送ったメッセージだけを紫〜水色の滑らかなリニアグラデーションで描画するようにした。
- 相手からのメッセージはグラデーションをやめ、単色背景の通常バブルに戻した。
- 前iterの疑似グラデーション用に重ねていた複数の色面を削除した。

#### `mobile/app/transaction-detail.tsx`
- 取引チャットの自分側メッセージ背景がグラデーションを邪魔しないよう、送信側バブルの単色背景を透明にした。

#### `mobile/app/meguri-letters.tsx`
- めぐりあいチャットの自分側メッセージ背景がグラデーションを邪魔しないよう、送信側バブルの単色背景を透明にした。

#### `mobile/package.json`
- `expo-linear-gradient` を追加した。

### 影響範囲

- iOS版 取引チャット
- iOS版 めぐりあいチャット
- 共通チャット吹き出しコンポーネント

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.85] チャット吹き出しグラデーションを調整" --non-interactive`
- EAS Update: `019e554b-8167-71da-817d-1e885bc1782b`
- EAS Update group: `c8c03996-aaf0-44f1-a840-71e6d4faf378`

### 関連ファイル

- `mobile/src/components/ChatGradientBubble.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/package.json`
- `mobile/package-lock.json`

### セルフレビュー結果

- ✅ Instagram DMの送信側だけが紫〜青系に見える整理へ寄せた
- ✅ 受信側バブルのグラデーションを撤去し、単色背景にした
- ✅ 疑似的な色帯ではなく `expo-linear-gradient` による滑らかな描画へ変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.84：グルームキューブ遷移をInstagram式に調整

### 背景・問題意識

オーナーから、前iterで入れたグルームの3Dキューブ遷移がInstagram Storiesのイメージと違うという指摘があった。また、スワイプで切り替えた直後に一瞬前のグルームが表示され、ユーザー体験が悪いという問題もあった。調査したところ、Instagram Stories系のキューブ遷移は「横スライド中の各面を個別に回す」よりも、正面・左右の3面を作り、パン量に応じて共有エッジを軸に90度回転させる構造に近い。React Nativeでも `rotateY` には `perspective` が必要で、現行RNでは `transformOrigin` を使って回転軸を左右端へ寄せられるため、その方式へ寄せた。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- `useLayoutEffect` を使い、選択中のグルームが切り替わった同一描画サイクルで `swipeX` を0へ戻すようにした。
- スワイプ確定時に `swipeX` を先に0へ戻す処理をやめ、次の投稿選択を先に確定させるようにした。
- `GroomStoryFace` を、正面・左面・右面の3面構成へ変更した。
- current面は左右スワイプ方向ごとに回転軸を `left center` / `right center` に分け、隣の面は画面外の左/右端から90度回転して入るようにした。
- `perspective` を広めに取り、前回より強すぎる魚眼感を抑えた。
- 自動送り/タップ/スワイプの別ユーザー切り替えで、旧グルームが一瞬再表示される原因だった「reset → select」の順序を「select → layout reset」に変更した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム側グルーム閲覧も同じInstagram Stories風の3面キューブ構造へ変更した。
- スワイプ確定時の旧グルームちらつき対策をホーム側にも反映した。

### 影響範囲

- iOS版 グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルームのタップ送り・スワイプ送り・自動送り

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.84] グルームキューブ遷移をInstagram式に調整" --non-interactive`
- EAS Update: `019e5546-eda0-7972-8d84-9060694cc2eb`
- EAS Update group: `278cb051-2a6c-4a42-aaae-fb87b9cb6cf7`

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ Instagram Stories系のキューブ構造を調査して、3面構成・共有エッジ回転へ寄せた
- ✅ React Nativeの `perspective` / `rotateY` / `transformOrigin` を使って実装
- ✅ スワイプ確定時の旧グルームちらつき原因だった `swipeX` リセット順序を修正
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.83：グルーム遷移とチャット既読表示を調整

### 背景・問題意識

オーナーから、グルームのユーザー切り替え時に3Dキューブが回るような遷移にしたい、グルーム一覧アイコンを少し大きくしたい、取引チャット・めぐりあいチャットの吹き出しをInstagram風のグラデーションへ寄せたい、めぐりあい側のアイコンをアバター顔にしたいという指示があった。また、めぐりあいチャットの既読が送信直後に付いているように見える問題について、見せかけの遅延ではなく、実データに基づく仕様へ直す必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧で、同一ユーザー内の投稿移動は従来通り、別ユーザーへ切り替わる時だけY軸回転を伴うキューブ風遷移にした。
- グルーム一覧の丸アイコンを 62px から 74px 相当へ拡大し、横幅と戻り先のアイコン座標を調整した。
- グルームの戻る縮小アニメーション先が拡大後のアイコン中心へ合うようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム側グルーム閲覧でも、投稿切り替え時にY軸回転を伴うキューブ風遷移を追加した。
- ホーム側グルーム一覧の丸アイコンも 74px 相当へ拡大した。

#### `mobile/src/components/ChatGradientBubble.tsx`
- 取引チャット・めぐりあいチャットで共通利用する、Instagram風のグラデーション吹き出し部品を追加した。
- 自分のメッセージは紫・青・ピンクが重なる濃いグラデーション、相手側は白地に淡い色のにじみが入る表現にした。

#### `mobile/app/transaction-detail.tsx`
- 取引チャットのテキスト/写真吹き出しを `ChatGradientBubble` へ差し替えた。
- 自分のメッセージに常時 `既読` を出していた処理をやめ、相手の `proposal_read_states.last_read_at` が自分のメッセージ時刻以降の時だけ表示するようにした。
- 画面を開いたユーザー側の読了位置を、最新メッセージ時刻で `proposal_read_states` に upsert するようにした。
- `proposal_read_states` 未作成環境では既読表示を出さず、チャット本体は落とさないフォールバックにした。

#### `supabase/migrations/20260506110000_add_proposal_read_states.sql`
- `proposal_read_states` テーブルを追加した。
- `proposal_id + user_id` を主キーにし、参加者ごとの `last_read_at` / `updated_at` を保存するようにした。
- proposal参加者のみ読み取り可能、本人行のみ insert/update 可能なRLSを追加した。

#### `mobile/app/meguri-letters.tsx`
- めぐりあいチャットの吹き出しを `ChatGradientBubble` へ差し替えた。
- めぐりあいチャットでは、相手がこちらの返信を読んだイベントがまだ存在しないため、送信直後に出ていた `既読` 表示を撤去し、送信時刻のみ表示するようにした。
- めぐりメッセージ一覧、スレッド上部、相手メッセージ横の小アイコンを、文字丸ではなく `MeguriAvatarFace` に差し替えた。

#### `mobile/app/(tabs)/transactions.tsx`
- やりとりタブ内のめぐりあい一覧アイコンを、文字丸から `MeguriAvatarFace` に差し替えた。

#### `mobile/src/components/meguri/MeguriAvatarFace.tsx`
- めぐり一覧・チャット内で使う2Dアバター顔コンポーネントを追加した。
- ねこ・きつね・うさぎ、毛色、アクセント色を既存めぐり住人データから反映できるようにした。

#### `notes/05_data_model.md`
- `proposal_read_states` をデータモデルへ追記し、取引チャット既読表示の派生ルールを明記した。

### 影響範囲

- iOS版 グルーム一覧・グルーム閲覧
- iOS版 取引チャット
- iOS版 めぐりあいチャット
- iOS版 やりとり > めぐりあい一覧
- Supabase DB migration

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.83] グルームとチャット既読表示を調整" --non-interactive`
- `supabase db push`
- EAS Update: `019e5538-37d9-7cdb-8f67-e88a44b1bacd`
- EAS Update group: `7eec5d9b-d8dd-48ae-bc27-c80249feba72`
- Expo exportで新規JSバンドルが生成され、既存めぐりGLB/テクスチャアセットが引き続きiOSアセットに含まれることを確認
- Supabase remote database に `20260506100000_add_proposal_meetup_candidates.sql` と `20260506110000_add_proposal_read_states.sql` が適用されたことを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/src/components/ChatGradientBubble.tsx`
- `mobile/src/components/meguri/MeguriAvatarFace.tsx`
- `supabase/migrations/20260506110000_add_proposal_read_states.sql`
- `notes/05_data_model.md`

### セルフレビュー結果

- ✅ グルームの別ユーザー切り替えをキューブ風Y軸回転へ変更
- ✅ グルーム一覧アイコンを拡大し、戻り先座標も調整
- ✅ 取引チャット/めぐりあいチャットの通常吹き出しをグラデーション化
- ✅ 取引チャットの既読表示を `proposal_read_states` ベースに変更
- ✅ めぐりあいチャットの根拠がない即時 `既読` 表示を撤去
- ✅ めぐり一覧・チャット内のユーザーアイコンをアバター顔へ差し替え
- ✅ `notes/05_data_model.md` を更新
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ Supabase remote database への migration 適用成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要

---

## イテレーション162.82：めぐりGLBテクスチャ表示を改善

### 背景・問題意識

オーナーから、追加したGLBアバターの表示について、特にねこときつねのテクスチャが粗く崩れて見えるという指摘があった。前iterではReact Native実行時の画像読み込みを避けるため、GLB内の2048pxテクスチャを頂点カラーへ焼き込んでいたが、目や顔のような細かい情報は頂点密度では再現できず、低ポリゴン状の色むらとして見えてしまっていた。うさぎの頂点数・フェイス数が他モデルより多いことは見え方の差に少し影響するが、根本原因ではなかった。

### 変更内容

#### `mobile/assets/meguri-avatars/`
- アプリ同梱版GLBを、頂点カラー版からジオメトリのみの軽量GLBへ作り直した。
- 元GLBの2048pxベースカラーテクスチャを `textures/cat.jpg` / `textures/fox.jpg` / `textures/rabbit.jpg` として別アセット化した。
- ねこ・きつね・うさぎのGLBサイズをそれぞれ約600KB前後まで軽量化し、テクスチャは元のJPEG品質を保持した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- GLBモデル読み込みと同時に、対応する2048pxテクスチャを `expo-asset` で読み込むようにした。
- Expo GL の `texImage2D` が扱える `localUri` 付き画像オブジェクトを `THREE.Texture` に渡し、元UVのままテクスチャ表示するようにした。
- glTF由来のUVに合わせて `texture.flipY = false` を指定した。
- 頂点カラー前提ではなく、`MeshStandardMaterial` の `map` にテクスチャを割り当てる方式へ変更した。

### 影響範囲

- iOS版 めぐり3D演出
- iOS版 めぐり広場
- iOS版 めぐりプロフィール
- iOS版 アバター編集プレビュー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.82] めぐりGLBテクスチャ表示を改善" --non-interactive`
- EAS Update: `019e5416-6ba7-7a98-b107-2390be32a949`
- EAS Update group: `75ef22b2-7f02-49ea-accb-038334416289`
- Expo exportで、軽量化した `cat.glb` / `fox.glb` / `rabbit.glb` と、`textures/*.jpg` 3枚がiOSアセットに含まれることを確認

### 関連ファイル

- `mobile/assets/meguri-avatars/cat.glb`
- `mobile/assets/meguri-avatars/fox.glb`
- `mobile/assets/meguri-avatars/rabbit.glb`
- `mobile/assets/meguri-avatars/textures/cat.jpg`
- `mobile/assets/meguri-avatars/textures/fox.jpg`
- `mobile/assets/meguri-avatars/textures/rabbit.jpg`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ テクスチャ崩れの主因を頂点カラー化と判断
- ✅ 2048px元テクスチャを別アセット化
- ✅ GLBはジオメトリのみへ軽量化
- ✅ Three.js 側で元UVにテクスチャを割り当てる方式へ変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.81：めぐりアバターをGLBモデルへ差し替え

### 背景・問題意識

オーナーから、`Megrum めぐり` フォルダに追加した、ねこ・きつね・うさぎのアバターを、現在のめぐりアバターへ反映してほしいという指示があった。既存のめぐり3D演出はコード生成のぬいぐるみ風モデルだったため、追加済みGLBをiOSアプリのアセットとして同梱し、現在のめぐり住人の種類をGLBモデルへ差し替える必要があった。

### 変更内容

#### `mobile/assets/meguri-avatars/`
- `Megrum めぐり/ねこ.glb` を `cat.glb` として追加した。
- `Megrum めぐり/きつね.glb` を `fox.glb` として追加した。
- `Megrum めぐり/うさぎ.glb` を `rabbit.glb` として追加した。
- React Native の画像ローダーに依存しないよう、アプリ同梱版はテクスチャ色を頂点カラーへ焼き込んだGLBとして整えた。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `expo-asset` と `GLTFLoader` でGLBアバターを読み込む処理を追加した。
- 読み込み完了後、既存のコード生成アバターを非表示にし、GLBモデルを正規化して表示するようにした。
- ねこ・きつね・うさぎの3種類を `animalType` に応じて読み分けるようにした。
- アバター設定変更時に、同じIDの3D表示でも見た目が更新されるようにした。
- GLBが読み込めない場合は、既存のコード生成アバターをフォールバックとして残すようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- めぐり住人の種類を `cat | fox | rabbit` に変更した。
- 既存データの `bear` を `fox` へ置き換えた。

#### `mobile/app/meguri-avatar-edit.tsx`
- アバター編集の選択肢を「ねこ / きつね / うさぎ」に変更した。

#### `mobile/src/lib/meguriSettings.ts`
- 保存されるアバター種別を `cat | fox | rabbit` に変更した。
- 旧バージョンで保存済みの `bear` は、読み込み時に `fox` へ寄せる互換処理を追加した。

#### `mobile/metro.config.js`
- Metroのアセット拡張子に `glb` を追加した。

#### `notes/10_glossary.md`
- 「めぐり住人」の定義を、GLBアセットのねこ・きつね・うさぎに更新した。

### 影響範囲

- iOS版 めぐり3D演出
- iOS版 めぐり広場
- iOS版 めぐりプロフィール
- iOS版 グルーム内プロフィールスライド
- iOS版 アバター編集

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.81] めぐりアバターをGLBモデルへ差し替え" --non-interactive`
- EAS Update: `019e5410-4c6f-77a1-a64c-6730ab74ae46`
- EAS Update group: `f6ea3ffc-7747-4fbb-abfa-9e69566392c3`
- Expo exportで `assets/meguri-avatars/cat.glb` / `fox.glb` / `rabbit.glb` がiOSアセットに含まれることを確認

### 関連ファイル

- `mobile/assets/meguri-avatars/cat.glb`
- `mobile/assets/meguri-avatars/fox.glb`
- `mobile/assets/meguri-avatars/rabbit.glb`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-avatar-edit.tsx`
- `mobile/src/lib/meguriSettings.ts`
- `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`
- `mobile/metro.config.js`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ GLBアセット3種をiOSアプリ側へ追加
- ✅ GLB内テクスチャ色を頂点カラー化し、React Native実行時の画像デコード依存を回避
- ✅ Three.js 側で頂点カラーを使う指定を追加
- ✅ Metroで `glb` をバンドル対象に追加
- ✅ めぐり住人の種類をねこ・きつね・うさぎに統一
- ✅ 既存の `bear` データを `fox` へ置換
- ✅ 旧保存値 `bear` の読み込み互換を追加
- ✅ GLB読み込み失敗時のフォールバック表示を保持
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 用語定義変更のため `notes/10_glossary.md` を更新
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.80：やりとり側めぐり一覧の未返信表示を修正

### 背景・問題意識

オーナーから、めぐりあいのメッセージ一覧が以前の修正指示どおりになっておらず、「メッセージがきています！」と場所・時刻ヒントが表示されたままになっているという指摘があった。実際の表示は `meguri-letters.tsx` ではなく、下部タブ「やりとり」内の `mobile/app/(tabs)/transactions.tsx` 側のめぐりあい一覧だったため、同じ表示ルールをそちらにも反映する必要があった。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- めぐりあい一覧から `letter.placeHint / letter.timeHint` の表示を削除した。
- 未返信行の文言を「未返信　メッセージが届いています！」に変更した。
- 「未返信」は赤文字、「メッセージが届いています！」は太字で表示するようにした。
- 未返信行に赤系の枠と影を追加し、通常行より目立つようにした。
- 保存済みのグルーム返信を読み込み、こちらから送ったメッセージがある相手は、本文を一覧プレビューとして通常ウェイトで表示するようにした。
- やりとりタブにフォーカスした時、めぐり既読状態とグルーム返信履歴を再読み込みするようにした。

### 影響範囲

- iOS版 やりとりタブ
- やりとりタブ内のめぐりあいメッセージ一覧
- グルーム返信済み相手の一覧プレビュー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.80] やりとり側めぐり一覧の未返信表示を修正" --non-interactive`
- EAS Update: `11ddcf03-04f0-427a-9201-4e4642fbdcbf`
- やりとりタブのめぐりあい一覧で、場所・時刻ヒントが表示されないことを確認
- 未返信行が「未返信　メッセージが届いています！」になり、「未返信」が赤文字で表示されることを確認
- 未返信行の枠が目立つことを確認
- グルーム返信済み相手では、送信本文が一覧プレビューに通常ウェイトで表示されることを確認

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ やりとりタブ側の旧文言「メッセージがきています！」を削除
- ✅ 場所・時刻ヒントを一覧から削除
- ✅ 未返信文言と赤文字表示を追加
- ✅ 未返信パネルの枠と影を強調
- ✅ 送信済みグルーム返信の本文プレビュー表示を追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.79：Wish操作をLiquid Glassへ統一

### 背景・問題意識

オーナーから、Wish のパネルを押した時も、マイ在庫と同様に iOS Liquid Glass 仕様の操作UIにしてほしいという指示があった。直前の iter162.77 で、マイ在庫側は `expo-glass-effect` の `GlassContainer` / `GlassView` を使い、非対応環境では模造UIを出さず iOS 標準 ActionSheet に戻す方針に修正済みだったため、Wish 側も同じ共通UIへ揃える必要があった。

### 変更内容

#### `mobile/app/(tabs)/wishes.tsx`
- Wish パネル押下時に、タップ位置を `GoodsGrid` から受け取り、操作UIのアンカーとして保持するようにした。
- 選択中 Wish の写真・色・文字を `BottomOptionSheet` のプレビューとして渡すようにした。
- Wish 操作用の `BottomOptionSheet` に `presentation="glass"` を指定し、マイ在庫と同じ Liquid Glass 浮遊操作レイヤーを使うようにした。
- フィルタ変更、タブ切り替え、横スワイプ時に Wish の選択状態とアンカー位置を同時に閉じるようにした。

### 影響範囲

- iOS版 Wish 一覧
- iOS版 Wish パネルタップ時の操作UI

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.79] Wish操作をLiquid Glassへ統一" --non-interactive`
- EAS Update: `bb77b4b9-0324-49e8-a3a7-6d42fd85cab5`
- Wish 一覧で Wish パネルをタップし、iOS Liquid Glass API 対応環境ではタップ位置近くに小さな操作レイヤーが浮くことを確認
- Liquid Glass API 非対応 iOS では、iter162.77 と同じく標準 ActionSheet に戻ることを確認

### 関連ファイル

- `mobile/app/(tabs)/wishes.tsx`
- `mobile/src/components/GoodsGrid.tsx`

### セルフレビュー結果

- ✅ Wish パネルもマイ在庫と同じ `presentation="glass"` を使用
- ✅ タップ位置アンカーとグッズプレビューを渡すように変更
- ✅ 非対応 iOS は共通 `GoodsGrid` 側の標準 ActionSheet フォールバックを利用
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.78：グルーム内プロフィール遷移をスライド化

### 背景・問題意識

オーナーから、グルーム閲覧中に左上のアイコンや名前を押した時、一旦めぐりホームが映ってしまうのではなく、グルーム画面のまま右横からその人のプロフィール画面がスライドして見えるようにしたいという指示があった。また、プロフィール側から左端を右へスワイプすると元のストーリーへ戻る設計にする必要があった。

### 変更内容

#### `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`
- グルーム閲覧モーダル内で使うプロフィール用スライドパネルを新規追加した。
- パネルは右端から全画面でスライドインし、ストーリーを閉じずにプロフィールを表示する。
- 左端から右方向へのスワイプでパネルをスライドアウトし、元のグルームストーリーへ戻るようにした。
- 既存のめぐりプロフィールと同じ公開情報、めぐり回数、推し、最近の公開メモを表示する構成にした。
- パネル内の「グルームに戻って返信」ボタンで、プロフィールを閉じて返信入力欄へ戻れるようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧中のプロフィール遷移を、`router.push("/meguri-profile")` からモーダル内スライドパネル表示へ変更した。
- プロフィールパネル表示中はグルーム進捗バーを停止し、戻った後に再開するようにした。
- iOSの戻る要求では、プロフィールパネルが開いている場合はまずパネルだけ閉じるようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部グルームでも同じスライドプロフィール表示に変更した。
- ホーム用グルーム投稿から既存のめぐりユーザー情報を解決し、プロフィールパネルに渡すようにした。

### 影響範囲

- iOS版 めぐりタブ内グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルームからめぐりプロフィールへ移動する体験

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.78] グルーム内プロフィール遷移をスライド化" --non-interactive`
- EAS Update: `b2384477-312d-4959-9f45-d9c116be0ee6`
- グルーム閲覧中に左上のユーザー情報をタップして、めぐりホームを挟まずプロフィールが右からスライドインすることを確認
- プロフィール画面の左端を右へスワイプし、元のグルームストーリーへ戻ることを確認
- プロフィール表示中は進捗バーが進まず、戻った後に再開することを確認

### 関連ファイル

- `mobile/src/components/meguri/GroomProfileSlidePanel.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ グルームから route 遷移せず、モーダル内プロフィール表示へ変更
- ✅ 右からスライドインするプロフィールパネルを追加
- ✅ 左端右スワイプでストーリーへ戻る操作を追加
- ✅ プロフィール表示中の進捗停止と復帰を追加
- ✅ ホーム上部グルームにも同じ挙動を適用
- ⚠️ `npm --prefix mobile run typecheck` は実装直後に成功。その後の最終再実行では、今回の変更外である `mobile/app/(tabs)/wishes.tsx` の `closeSelectedWish` / `normalizePressContext` 未定義により失敗
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

## イテレーション162.77：マイ在庫操作をLiquid Glassへ再実装

### 背景・問題意識

オーナーから、マイ在庫パネルタップ時のUIについて、単なる半透明カードや「似せた」表現ではなく、iOS の Liquid Glass 仕様を使った挙動へ再実装するよう指示があった。Apple HIG 上の Liquid Glass はコンテンツそのものではなく、コンテンツ上に浮くコントロール／ナビゲーションの機能レイヤーとして扱うべきであり、在庫パネルの操作UIも大きなボトムシートではなく、選択パネルから浮く小さな操作レイヤーにする必要があった。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- `expo-glass-effect` の `GlassContainer` / `GlassView` を使った、iOS ネイティブ Liquid Glass 操作ポップオーバーを追加した。
- `isGlassEffectAPIAvailable()` と `isLiquidGlassAvailable()` を確認し、iOS Liquid Glass API が利用できる場合のみ Liquid Glass ポップオーバーを表示するようにした。
- Liquid Glass API が利用できない iOS では、模造ガラスUIを出さず、iOS 標準の `ActionSheetIOS` にフォールバックするようにした。
- 既存の大きな glass bottom sheet ではなく、タップ位置を起点に小さな操作群が浮く配置へ変更した。
- `GlassContainer` 内に、選択グッズのプレビューと、編集・移動・削除・閉じるの各操作を個別の `GlassView` として表示するようにした。
- Expo GlassEffect の既知制約に合わせ、Liquid Glass 表示時は `GlassView` / 親要素の opacity アニメーションを使わず、位置と scale のみで表示するようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- グッズパネル押下時のタップ位置を `GoodsGrid` から受け取り、Liquid Glass 操作ポップオーバーの表示位置として渡すようにした。
- 選択中グッズの写真・色・文字をプレビューとして操作レイヤーに渡すようにした。
- フィルタ変更、ステータス切り替え、ページスワイプ時に選択状態とアンカー位置を同時に閉じるようにした。

### 影響範囲

- iOS版 マイ在庫一覧
- iOS版 マイ在庫パネルタップ時の操作UI
- 共通 `GoodsGrid` の `presentation="glass"` 表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.77] マイ在庫操作をLiquid Glassへ再実装" --non-interactive`
- EAS Update: `b7da2a38-d921-49ec-a60c-3dfa09629179`
- マイ在庫でグッズパネルをタップし、iOS Liquid Glass API 対応環境ではタップ位置近くに小さな操作レイヤーが浮くことを確認
- Liquid Glass API 非対応 iOS では、模造UIではなく iOS 標準 ActionSheet に戻ることを確認

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`

### セルフレビュー結果

- ✅ `expo-glass-effect` の `GlassContainer` / `GlassView` を使用
- ✅ `isGlassEffectAPIAvailable()` / `isLiquidGlassAvailable()` で可用性チェック
- ✅ 非対応 iOS ではガラス風 View / BlurView で似せず、標準 ActionSheet にフォールバック
- ✅ マイ在庫の大きなボトムシート表示を廃止し、タップ位置起点の浮遊操作レイヤーへ変更
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.76：グルーム返信入力の復帰挙動を整理

### 背景・問題意識

オーナーから、グルームでメッセージ入力を始めたあと、画面上部などをタップしたらキーボードが閉じて入力欄が下へ戻り、通常のグルーム閲覧に復帰してほしいという指示があった。また、入力中は入力欄とキーボード以外を薄く暗くし、進捗ステータスは入力中だけ停止、それ以外では動くようにする必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧モーダルの返信 `TextInput` に ref を追加し、背景タップで `blur()` と `Keyboard.dismiss()` を実行するようにした。
- 返信入力中だけ、入力欄より上の閲覧領域に薄い暗幕レイヤーを表示し、タップすると入力を閉じるようにした。
- 返信送信時も入力を閉じ、送信後に進捗が再開できるようにした。
- グルーム進捗アニメーションの停止時に現在値を保存し、入力終了後は保存値から再開するようにした。
- キーボードが閉じた時に `replyFocused` を確実に false へ戻す listener を追加した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部のグルーム閲覧でも同じ返信入力の暗幕、背景タップ復帰、送信時 dismiss、進捗再開処理を追加した。

### 影響範囲

- iOS版 めぐりタブ内グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- グルーム返信入力中の進捗ステータス制御

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.76] グルーム返信入力の復帰挙動を整理" --non-interactive`
- EAS Update: `548c0070-5d2c-4065-b080-ea533baa1d14`
- グルーム閲覧で返信入力欄をタップし、入力中に閲覧領域が薄く暗くなることを確認
- 入力中に画面上部をタップし、キーボードが閉じて入力欄が下へ戻ることを確認
- 入力中は進捗バーが停止し、入力を閉じた後は途中から進むことを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 入力中の暗幕レイヤーを追加
- ✅ 背景タップで `TextInput` blur とキーボード dismiss を実行
- ✅ 返信送信後も入力状態を解除
- ✅ 進捗ステータスは入力中だけ停止し、入力終了後は保存位置から再開
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.75：グルーム撮影後編集をストーリー型へ変更

### 背景・問題意識

オーナーから、グルームを撮った後の画面を、Instagram ストーリーの撮影後編集のように、文字入れなどができる構成にしたいという指示があった。撮影後の単純な投稿シートではなく、写真を全画面で確認しながら編集する体験に寄せる必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム投稿前の画面を、下部シートから全画面のストーリー編集画面へ変更した。
- 上部ツールとして、閉じる、文字追加、スタンプ追加、描画、ひとつ戻すを配置した。
- 文字追加では、文字色、表示スタイル（文字 / 帯 / 塗り）を選んで写真上に重ねられるようにした。
- スタンプ追加では、グルーム向けの「現場到着」「交換OK」「推し色」などのスタンプを写真上に配置できるようにした。
- 描画では、色を選んで写真上をなぞる簡易ペン入力を追加した。
- 下部には、ひとこと入力、撮り直す、投稿するを配置し、ストーリー投稿画面に近い操作構成へ変更した。
- 投稿したグルームの閲覧画面でも、追加した文字・スタンプ・描画を写真上に表示するようにした。

### 影響範囲

- iOS版 グルーム撮影後編集
- iOS版 グルーム投稿
- iOS版 グルーム閲覧

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.75] グルーム撮影後編集をストーリー型へ変更" --non-interactive`
- EAS Update: `32e78c48-e600-40ed-8916-96b55c69fcda`
- めぐりタブでグルーム撮影後、全画面編集画面が表示されることを確認
- 文字・スタンプ・描画を追加して投稿できることを確認
- 投稿後のグルーム閲覧で、追加した文字・スタンプ・描画が表示されることを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ グルーム撮影後画面を全画面編集へ変更
- ✅ 文字入れ機能を追加
- ✅ グルーム向けスタンプ追加機能を追加
- ✅ 簡易描画機能を追加
- ✅ 投稿後の閲覧画面にも編集内容を反映
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.74：めぐりメッセージ一覧の未返信表示整理

### 背景・問題意識

オーナーから、めぐりあいのメッセージ一覧では、いつどこでめぐりあったかの説明は不要で、未返信状態をより分かりやすく表示したいという指示があった。また、こちらから送ったメッセージは一覧にも本文プレビューとして表示し、未返信のパネルは枠を目立たせる必要があった。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- メッセージ一覧の未返信行で、「未返信　メッセージが届いています！」を表示するようにした。
- 「未返信」は赤文字、「メッセージが届いています！」は太字で表示するようにした。
- こちらから送信済みのスレッドでは、最新の送信本文を一覧プレビューに表示するようにした。
- 送信済み本文の一覧プレビューは太字にせず、通常寄りの文字ウェイトにした。
- 未返信の行に赤系の枠と軽い影を追加し、通常行より目立つようにした。
- 旧文言「メッセージがきています！」を「メッセージが届いています！」へ整理した。

### 影響範囲

- iOS版 めぐりメッセージ一覧
- iOS版 めぐりメッセージ未開封表示
- iOS版 グルーム返信・通常返信の一覧プレビュー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.74] めぐりメッセージ一覧の未返信表示整理" --non-interactive`
- EAS Update: `34ddf355-66ed-4cdb-bcf7-97423c957cb4`
- めぐりメッセージ一覧で、未返信行に赤い「未返信」と太字の「メッセージが届いています！」が表示されることを確認
- 未返信行の枠が通常行より目立つことを確認
- こちらから送ったメッセージがある行では、送信本文が一覧に1行プレビューされることを確認

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 未返信文言を指定どおりに変更
- ✅ 「未返信」だけ赤文字に変更
- ✅ 到着メッセージ文言を太字に変更
- ✅ 送信済み本文を一覧プレビューに表示
- ✅ 未返信行の枠を強調
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.73：グルーム閲覧からめぐりプロフィールへ遷移

### 背景・問題意識

オーナーから、グルーム画面で左上のアイコンや名前を押したら、その人のめぐりプロフィールに遷移できるようにしたいという指示があった。グルーム閲覧中に気になった相手の詳細を自然に見に行ける導線が必要だった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりタブ内のグルーム閲覧ヘッダーで、相手のアイコン・名前・時刻のまとまりをタップ可能にした。
- タップ時にグルーム閲覧モーダルを閉じ、`/meguri-profile?id=...` へ遷移するようにした。
- 自分の投稿など `author` がないグルームではプロフィール遷移を無効にした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部のグルーム閲覧でも、左上のアイコン・名前タップでめぐりプロフィールへ遷移するようにした。
- ホーム用グルームの表示名を、既存のめぐりユーザーIDマップでプロフィールIDへ解決するようにした。

### 影響範囲

- iOS版 めぐりタブ内グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- iOS版 めぐりプロフィール導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.73] グルームからプロフィールへ遷移" --non-interactive`
- EAS Update: `1eea3f12-41fc-4bb4-9e7e-42b2cb69c77b`
- グルーム閲覧中、左上のアイコンまたは名前をタップすると対象ユーザーのめぐりプロフィールへ遷移することを確認
- 自分の投稿グルームではプロフィール遷移が発火しないことを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ めぐりタブ内グルームからプロフィール遷移を追加
- ✅ ホーム上部グルームからプロフィール遷移を追加
- ✅ 自分投稿など相手ユーザーがないグルームは無効化
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.72：マイ在庫登録の入力項目整理

### 背景・問題意識

オーナーから、マイ在庫からグッズを登録する時にシリーズ・弾名やコンディションを入力させるのではなく、タグ入力へ寄せたいという指示があった。また、「ラベル設定」という案内、詳細登録画面の持参中一括設定、説明／メモ欄、ヘッダー右上の `NEW` が分かりにくいため整理する必要があった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 新規在庫登録の共通ステップから「シリーズ・弾名」と「コンディション」を削除した。
- 代わりに共通ステップへ「タグ」入力を配置し、登録時に各グッズへ同じタグを付与する流れにした。
- 写真選択後の案内を「ラベル設定」から「詳細設定へ」に変更した。
- 詳細設定画面の見出しを「各グッズの詳細設定」に変更した。
- 詳細設定画面から「全部今日から持参中にする」と「説明 / メモ」を削除した。
- 新規在庫登録画面のヘッダー右上に出ていた `NEW` 表示を削除した。
- 入力しなくなった `series` / `description` は新規在庫登録では `null`、`condition` は既定値 `good`、`carrying` は `false` として保存するようにした。

### 影響範囲

- iOS版 マイ在庫の新規グッズ登録
- 複数写真からのまとめ登録
- 在庫タグ付与

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.72] マイ在庫登録の入力項目整理" --non-interactive`
- EAS Update: `53c7dfba-ef3c-46c1-b0d3-81cb7c53a1ef`
- マイ在庫 → 追加 → 新規グッズ登録で、共通ステップにタグ入力が表示され、シリーズ・弾名／コンディションが表示されないことを確認
- 写真選択後のボタンが「次へ：詳細設定へ」になっていることを確認
- 詳細設定画面に「全部今日から持参中にする」と「説明 / メモ」が表示されないことを確認
- 新規在庫登録画面のヘッダー右上に `NEW` が表示されないことを確認

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ 新規在庫登録の不要項目を削除
- ✅ タグ入力をシリーズ・弾名の代替として共通ステップへ移動
- ✅ 「ラベル設定」文言を「詳細設定」へ変更
- ✅ 詳細設定画面の持参中一括設定と説明／メモ欄を削除
- ✅ 新規在庫登録ヘッダーの `NEW` 表示を削除
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.71：グルーム返信をめぐりメッセージへ反映

### 背景・問題意識

オーナーから、グルームでメッセージを送信した時に、画面中央へ「メッセージが送信されました」というトーストを表示したいという指示があった。また、送信したグルーム画像とその時のメッセージを、めぐりメッセージ側にもストーリーズ返信のように表示する必要があった。

### 変更内容

#### `mobile/src/lib/meguriMessages.ts`
- グルーム返信をローカル保存する `MeguriGroomReply` 型を追加した。
- `loadMeguriGroomReplies` / `appendMeguriGroomReply` を追加し、返信したグルーム画像・本文・送信先ユーザーを保存できるようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧中の返信送信時に、中央トースト「メッセージが送信されました」を表示するようにした。
- 返信本文と対象グルーム画像をめぐりメッセージ用に保存するようにした。
- 従来のキャプション位置に出ていた送信フィードバックを中央トーストへ移動した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部グルームの返信でも、同じ中央トーストとめぐりメッセージ保存を行うようにした。
- ホーム用グルームの表示名から、対応するめぐりユーザーIDへ紐づけるマップを追加した。

#### `mobile/app/meguri-letters.tsx`
- 保存済みのグルーム返信を読み込み、対象ユーザーのめぐりメッセージスレッドに自分の送信メッセージとして表示するようにした。
- 「この人のストーリーズに返信しました」というラベル、返信対象のグルーム画像、送信したメッセージ本文を添付画像のように縦並びで表示するようにした。
- メッセージ一覧のプレビューでも、グルーム返信は「ストーリーズに返信しました」と分かるようにした。

### 影響範囲

- iOS版 グルーム閲覧
- iOS版 ホーム上部グルーム閲覧
- iOS版 めぐりメッセージ
- ローカル保存のめぐりメッセージ補助データ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.71] グルーム返信をめぐりメッセージへ反映" --non-interactive`
- EAS Update: `a091fded-55d8-456e-8196-eed75050183b`
- グルームでメッセージ送信後、画面中央に「メッセージが送信されました」トーストが出ることを確認
- めぐりメッセージ側で、返信したグルーム画像と送信本文が対象ユーザーのスレッドに表示されることを確認

### 関連ファイル

- `mobile/src/lib/meguriMessages.ts`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ グルーム返信後の中央トーストを追加
- ✅ グルーム返信をめぐりメッセージ用に保存
- ✅ めぐりメッセージでグルーム画像＋返信本文を表示
- ✅ ホーム上部グルームとめぐり画面内グルームの両方に対応
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.70：取引チャット詳細モーダルを確認画面寄せ

### 背景・問題意識

オーナーから、打診中チャットではヘッダー右端に合意ステータスが既に表示されているため、合意ステータスカード内の見出しは不要という指示があった。また、交換条件の詳細を開いた時の「交換できる候補」は、打診送信内容の確認画面と同じようにマップも表示し、打診時メッセージはチャット最初のメッセージとして出るため詳細画面には表示しない必要があった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 打診中の合意カードから「✓ 合意ステータス」見出しと双方ドット表示を削除し、ヘッダー右端のステータス表示と重複しないようにした。
- 交換条件詳細モーダルの「交換できる候補」を、地図パネルと番号付き候補リストのカード表示へ差し替えた。
- 候補に緯度経度がある場合は `NativeMapPreview` で送信確認画面と同じ番号付きピンを表示し、座標がない候補はリストだけ表示するようにした。
- 交換条件詳細モーダルから打診メッセージ欄を削除した。打診時メッセージは従来通りチャット最初のメッセージとして表示する。

### 影響範囲

- iOS版 取引チャット
- 取引内容詳細モーダル
- 打診中の合意アクションカード

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.70] 取引チャット詳細モーダルを確認画面寄せ" --non-interactive`
- EAS Update: `a7b05357-ba2a-487a-b2bc-b97a1406ff55`
- 打診中チャットで合意カード内の「合意ステータス」見出しが表示されないことを確認
- 取引内容の詳細モーダルで、交換できる候補に地図と番号付きリストが表示されることを確認
- 取引内容の詳細モーダルに打診時メッセージが表示されないことを確認

### 関連ファイル

- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ 合意ステータス見出しの重複を解消
- ✅ 交換できる候補にマップ表示を追加
- ✅ 詳細モーダルから打診時メッセージ表示を削除
- ✅ 打診時メッセージはチャット先頭表示のまま維持
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.69：チャット送信後スクロールとメタ表示調整

### 背景・問題意識

オーナーから、取引チャットとめぐりあいチャットの両方で、メッセージ送信後に送信したメッセージの最下部へ移動してほしいという指示があった。また、送信時間と既読表示は吹き出し内ではなく、吹き出し外の左下に表示する必要があった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引チャットのメッセージScrollViewに参照とメッセージ末尾アンカーを追加し、最新メッセージIDが変わった時にメッセージ一覧の末尾へスクロールするようにした。
- 完了パネルや証跡パネルがメッセージ下に続く場合でも、送信後はScrollView全体の末尾ではなくメッセージ末尾に寄せるようにした。
- テキスト/写真メッセージと現在地メッセージの時刻を吹き出し内から外へ移動し、自分のメッセージは吹き出し左下に「既読」と送信時刻を表示するようにした。

#### `mobile/app/meguri-letters.tsx`
- めぐりあいチャットのスレッドScrollViewに参照を追加し、メッセージ送信・画像送信後にスレッド末尾へスクロールするようにした。
- めぐりあいチャットでも自分のメッセージの「既読」と送信時刻を吹き出し外の左下に表示し、相手メッセージの時刻も吹き出し外へ出した。

### 影響範囲

- iOS版 取引チャット
- iOS版 めぐりあいチャット

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.69] チャット送信後スクロールとメタ表示調整" --non-interactive`
- EAS Update: `1fdc2c17-49b4-414a-ad20-57a32dc7706e`
- 取引チャットでメッセージ送信後、送信したメッセージの末尾へスクロールすることを確認
- めぐりあいチャットでメッセージ/画像送信後、スレッド末尾へスクロールすることを確認
- 両チャットで送信時刻と既読表示が吹き出し外の左下に表示されることを確認

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 取引チャット送信後のメッセージ末尾スクロールを追加
- ✅ めぐりあいチャット送信後のスレッド末尾スクロールを追加
- ✅ 送信時刻/既読表示を吹き出し外へ移動
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.68：Wish未紐付け表示を警告枠へ変更

### 背景・問題意識

オーナーから、ウィッシュ一覧のパネル上部にあるタグは表示せず、個別募集にまだ紐づけていないものだけ「⚠️ 未紐付け」と左上に表示し、そのパネル自体を黄色く囲ってほしいという指示があった。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- `GoodsGrid` に `showUnlinkedWarning` オプションを追加した。
- `showUnlinkedWarning` が有効で `badge === "未紐付け"` のパネルだけ、左上に「⚠️ 未紐付け」チップを表示するようにした。
- 未紐付けパネルだけ黄色の枠と軽い黄色影で囲うようにした。
- 既存の `showTopRow` は維持し、ウィッシュ一覧以外の在庫グリッド表示には影響しないようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- ウィッシュ一覧の `GoodsGrid` で `showTopRow={false}` を指定し、パネル上部の既存タグ行を非表示にした。
- 同じ一覧で `showUnlinkedWarning` を有効化し、未紐付けのWishだけ警告表示と黄色枠を出すようにした。

### 影響範囲

- iOS版 ウィッシュ一覧
- 共通 `GoodsGrid` の任意オプション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.68] Wish未紐付け表示を警告枠へ変更" --non-interactive`
- EAS Update: `a9012abd-1454-4998-8e20-eff251ff3beb`
- ウィッシュ一覧で通常パネルの上部タグが表示されないことを確認
- 個別募集に紐づいていないWishだけ左上に「⚠️ 未紐付け」が表示され、黄色枠で囲われることを確認

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ ウィッシュ一覧の上部タグ行を非表示化
- ✅ 未紐付けWishだけ左上警告と黄色枠を表示
- ✅ 共通 `GoodsGrid` の既存利用箇所はデフォルト挙動を維持
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.67：マイ在庫タップ時のリキッドグラスメニュー

### 背景・問題意識

オーナーから、マイ在庫の各グッズパネルをタップした時に、iOSのリキッドグラス風UIで操作ボタンを表示したいという要望があった。既存実装では iOS では `ActionSheetIOS` が表示されるだけで、アプリ内の視覚表現としてはホーム画面のグラス表現と揃っていなかった。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- `BottomOptionSheet` に `presentation="glass"` を追加し、既存のネイティブActionSheetとは別にグラス風の浮遊メニューを表示できるようにした。
- iOSでは `expo-glass-effect` の `GlassView` を動的に使用し、利用できない環境では `expo-blur` の `BlurView` にフォールバックする構成にした。
- グラスメニュー内に対象グッズ名/補足と、アイコン付きのアクションボタンを2列で表示するようにした。
- 既存の `presentation` 未指定箇所は従来通り `ActionSheetIOS` / ボトムシートを使うようにし、Wish側の既存挙動には影響させないようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫のグッズパネルタップ時の `BottomOptionSheet` を `presentation="glass"` に切り替えた。
- 過去に譲ったグッズもタップ時にグラスメニューを出し、「詳細を見る」「閉じる」のみ表示するようにした。

### 影響範囲

- iOS版 マイ在庫
- 共通 `GoodsGrid` のオプションシート表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.67] マイ在庫タップ時のリキッドグラスメニュー" --non-interactive`
- EAS Update: `768b4054-bee7-4a9c-9bd1-ce838a776682`
- マイ在庫のグッズパネルをタップし、グラス風の浮遊メニューが表示されることを確認
- 編集/移動/削除/閉じるの各アクションが従来通り動くことを確認
- 過去に譲ったグッズでは「詳細を見る」「閉じる」のみ表示されることを確認

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`

### セルフレビュー結果

- ✅ マイ在庫のパネルタップ時にグラス風アクションメニューを表示
- ✅ `GlassView` が使えない環境では `BlurView` へフォールバック
- ✅ Wish側など既存の `BottomOptionSheet` 利用箇所は従来表示を維持
- ✅ 過去に譲ったグッズは読み取り専用のアクションだけ表示
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.66：ホーム上部グルームをその場で閲覧

### 背景・問題意識

オーナーから、Megrimホーム画面上部のグルームを押した時に、めぐり画面へ遷移してしまうのではなく、その場でグルームを見られるようにしたいという指示があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部グルームの丸アイコン押下を `/encounters` 遷移から、ホーム内の閲覧モーダル起動へ変更した。
- ホーム画面用のグルーム閲覧モーダルを追加し、フルスクリーンでグルーム写真・投稿者・時間・ひとことを表示できるようにした。
- ホーム内閲覧でも左右タップ/横スワイプで前後のグルームへ切り替えられるようにした。
- ホーム内閲覧でもいいね、メッセージ入力、送信フィードバックを表示できるようにした。
- 閲覧したグルームはホーム上部の丸アイコン枠を既読色へ更新するようにした。

### 影響範囲

- iOS版 Megrimホーム画面
- ホーム画面上部のグルームレール
- ホーム内グルーム閲覧モーダル

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.66] ホーム上部グルームをその場で閲覧" --non-interactive`
- EAS Update: `e11c7846-d141-4551-9f9d-f7a4ae678a2e`
- ホーム上部のグルーム丸アイコンを押しても、めぐり画面へ遷移せず、その場で閲覧モーダルが開くことを確認
- ホーム内閲覧で左右タップ/横スワイプにより前後のグルームへ切り替わることを確認
- ホーム内閲覧でいいね、メッセージ入力、送信フィードバックが動くことを確認

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ ホーム上部グルーム押下を画面遷移ではなくモーダル閲覧へ変更
- ✅ ホーム内でグルーム写真、投稿者、時間、ひとことを表示
- ✅ ホーム内閲覧で前後切り替え、いいね、返信入力を実装
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.65：グルーム閲覧のスワイプと入力中進行を調整

### 背景・問題意識

オーナーから、グルーム閲覧中に下スワイプすると画面が黒く暗くなってしまうため、スワイプに従って元のめぐりホーム画面へうっすら戻る見え方にしたいという指示があった。また、横スワイプ時に画像が縦に割れたように表示される不具合があり、メッセージ入力時には背景のグルームがキーボードに合わせて上へスライドせず、入力中は進捗ステータスが進まない必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧モーダルを透明モーダルに変更し、下スワイプ時は黒背景ではなく背後のめぐりホームが透けて戻るようにした。
- 下スワイプ中の暗幕はスワイプ量に応じて薄くなるようにし、画面本体は丸アイコン方向へ縮小しながら収束する動きを維持した。
- 横スワイプ時の大きな `rotateY` 重なりをやめ、安定した横ページ移動に軽い奥行きだけを加える表現へ変更した。
- メッセージ入力時に `KeyboardAvoidingView` でモーダル全体を押し上げる挙動を廃止し、入力欄フッターだけをキーボード上へ逃がすようにした。
- メッセージ入力欄のフォーカス中はグルーム進捗アニメーションを一時停止し、フォーカス解除後に続きから再開するようにした。

### 影響範囲

- iOS版 めぐりホーム > グルーム閲覧モーダル
- グルーム閲覧中の下スワイプ dismiss
- グルーム閲覧中の横スワイプ切り替え
- グルーム閲覧中のメッセージ入力

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.65] グルーム閲覧のスワイプと入力中進行を調整" --non-interactive`
- EAS Update: `357e79c2-35a0-4f6e-b25c-dcec92c9b280`
- 下スワイプ時に黒く暗くならず、背後のめぐりホームが透けて見えることを確認
- 横スワイプ時に画像が縦割れ状に崩れないことを確認
- メッセージ入力時に背景のグルームがキーボードと一緒に上へ動かないことを確認
- メッセージ入力中に進捗ステータスが進まないことを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ 下スワイプ時にホームへ透けて戻る透明モーダル構成へ変更
- ✅ 横スワイプの表示崩れを避ける安定したページ移動表現へ変更
- ✅ 入力時に背景グルームが上へスライドしない構成へ変更
- ✅ 入力中は進捗アニメーションを停止
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.64：推し追加モーダルを下固定検索とスワイプ切替へ変更

### 背景・問題意識

オーナーから、「登録済みの推しを追加」のポップアップタイトルを「推しを追加」に変え、検索バーは画面下部に固定し、その上に推しの区分ボタンを置きたいという指示があった。また、一覧部分を横スワイプした時に、マイ在庫一覧と同じように指の動きへ追従しながら区分が切り替わる必要があった。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し追加モーダルのタイトルを「推しを追加」に変更した。
- 推し追加モーダル内の検索バーを、一覧の下部に固定されるドックへ移動した。
- 検索バーの上に「すべて」＋ジャンル区分ボタンを横並びで表示するようにした。
- 推し一覧をジャンル区分ごとの横ページャーへ変更し、横スワイプで区分を切り替えられるようにした。
- スワイプ中は一覧ページが指の動きに追従し、スワイプ完了後に区分ボタンの選択状態も同期するようにした。
- 区分ボタンをタップした場合も、対応する一覧ページへ横スクロールするようにした。

### 影響範囲

- iOS版 推し設定
- 推し設定 > 推し追加モーダル

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.64] 推し追加モーダルを下固定検索とスワイプ切替へ変更" --non-interactive`
- EAS Update: `0066c064-a2d2-4c18-b55f-3a96fdb45f24`
- 推し追加モーダルのタイトルが「推しを追加」になっていることを確認
- 検索バーが下部固定で表示され、その上に区分ボタンが表示されることを確認
- 一覧部分を横スワイプすると、指の動きに追従して区分ページが切り替わることを確認
- 区分ボタンをタップすると、対応する一覧ページへ切り替わることを確認

### 関連ファイル

- `mobile/app/oshi-settings.tsx`

### セルフレビュー結果

- ✅ モーダルタイトルを「推しを追加」へ変更
- ✅ 検索バーを下部固定ドックへ移動
- ✅ 区分ボタンを検索バーの上に配置
- ✅ 一覧を横スワイプ追従のページャー化
- ✅ 区分ボタンとスワイプ後の表示状態を同期
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.63：取引チャット取引内容を1行折りたたみ化

### 背景・問題意識

オーナーから、取引チャットの交換内容はデフォルトでは1行に折りたたみ、タップした時だけ詳細をポップアップ表示したいという指示があった。詳細画面では送信確認画面で使っている交換内容のカード表現を流用し、交換できる候補も同じ文脈で確認できる必要がある。また、合意ステータスは取引チャットのヘッダー右端へ簡潔に載せる必要があった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引チャット上部の取引内容カードを、デフォルト1行の折りたたみ行へ変更した。
- 1行の交換内容をタップすると、取引内容の詳細モーダルを表示するようにした。
- 詳細モーダル内の交換内容を、送信確認画面の交換カードに近い左右パネル＋矢印のデザインへ変更した。
- 詳細モーダル内に交換できる候補をリスト表示し、簡易地図は出さない構成にした。
- 合意ステータスを、相手ユーザー名が表示されているヘッダー行の右端へ短いバッジとして表示した。
- 詳細モーダルの内容が多い場合にスクロールできるようにした。

### 影響範囲

- iOS版 取引チャット
- iOS版 取引チャット > 取引内容詳細モーダル

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.63] 取引チャット取引内容を1行折りたたみ化" --non-interactive`
- EAS Update: `a4d2f501-b358-4589-921c-59e234b23555`
- 取引チャット上部の交換内容が1行で表示されることを確認
- 交換内容タップで詳細モーダルが開くことを確認
- 詳細モーダルで交換内容が送信確認画面風の左右カードで表示されることを確認
- 詳細モーダルで交換できる候補が簡易地図なしで表示されることを確認
- ヘッダー右端に合意ステータスの短いバッジが表示されることを確認

### 関連ファイル

- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ 交換内容のデフォルト表示を1行折りたたみへ変更
- ✅ タップ時の詳細ポップアップを実装
- ✅ 送信確認画面に近い交換内容カード表現を詳細モーダルへ反映
- ✅ 交換できる候補は簡易地図なしで表示
- ✅ 合意ステータスをヘッダー右端の短いバッジへ移動
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.62：グルーム閲覧をアカウント内投稿単位へ再整理

### 背景・問題意識

オーナーから、グルームはアカウント単位で3Dキューブの面を切り替えつつ、同じアカウントが複数グルームを投稿している場合は、そのアカウント内で進捗ステータスバーを投稿数分に分割し、左右タップで投稿を切り替えたいという指示があった。また、下スワイプで閉じる際は、画面がスワイプに追従しながら一覧のグルームアイコンへ収束していく感じにする必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム一覧を投稿単位ではなくアカウント単位の丸アイコンへ整理した。
- グルーム閲覧では、アカウントごとに投稿配列を持つ `groomAccountGroups` を追加した。
- 進捗ステータスバーは現在表示中アカウントの投稿数で分割するようにした。
- 左右タップは同一アカウント内の前後グルームへ移動し、端まで進んだ場合のみ前後アカウントへ移動するようにした。
- 横スワイプはアカウント間の切り替え専用にし、隣アカウントのグルームへ3Dキューブ風に回転して移るようにした。
- 下スワイプ dismiss では、画面が縮小しながら選択中アカウントの丸アイコン位置へ寄るように、横/縦方向の収束アニメーションを追加した。
- プレビュー確認用に、同一アカウントが複数グルームを持つデータを追加した。

### 影響範囲

- iOS版 めぐりホーム > グルーム一覧
- iOS版 グルーム閲覧モーダル

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.62] グルーム閲覧をアカウント内投稿単位へ再整理" --non-interactive`
- EAS Update: `e57a8f19-7b70-4129-9593-b1ab85651b13`
- 同一アカウントのグルームを開いたとき、進捗バーがそのアカウントの投稿数分に分割されることを確認
- 右側タップで同一アカウント内の次グルームへ切り替わることを確認
- 横スワイプで別アカウントのグルームへ3Dキューブ風に切り替わることを確認
- グルーム閲覧中に下スワイプし、画面が縮小しながら一覧の丸アイコンへ寄ることを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ 進捗バーをアカウント内投稿数で分割
- ✅ 左右タップを同一アカウント内投稿切り替えへ変更
- ✅ 横スワイプはアカウント間の3Dキューブ切り替えに限定
- ✅ 下スワイプ dismiss を丸アイコン方向へ収束する動きに調整
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.61：在庫/Wish/ホーム導線を整理

### 背景・問題意識

オーナーから、マイ在庫の各グッズパネル上部に出ているキャラ名や「譲る候補」などのタグは不要という指示があった。また、マイ在庫のステータス切り替えはパネルがない余白でも左右スワイプでき、指の動きに追従して画面が動く必要があった。あわせて、Wishにもマイ在庫と同じ推し/種別フィルタを追加し、個別募集は募集デッキだけ残して下の一覧を消し、グルームをホーム画面上部にも表示したいという要望があった。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- `GoodsGrid` に `showTopRow` オプションを追加し、カード上部のタイトル/バッジ行を画面ごとに非表示へできるようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫の `GoodsGrid` では `showTopRow={false}` を指定し、各グッズパネル上部のキャラ名/状態タグを表示しないようにした。
- ステータス切り替えを手動タッチ判定から横スクロールページャーへ変更し、パネルがない余白でも左右スワイプできるようにした。
- スワイプ中はページが指に追従し、スワイプ完了後に `譲る候補` / `自分用キープ` / `過去に譲った` のタブ状態が同期するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish に `group` / `type` を持たせ、マイ在庫と同じ「推し」「種別」フィルタを追加した。
- Wishタブの件数とグリッド表示をフィルタ後の件数/内容へ同期した。
- 個別募集タブでは募集デッキのみを表示し、その下の縦一覧を削除した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム画面の上部にグルームの横レールを追加した。
- グルームの追加/閲覧タップは既存のめぐり画面へ接続し、既存のグルーム投稿/閲覧導線を使えるようにした。

### 影響範囲

- iOS版 マイ在庫
- iOS版 Wish
- iOS版 個別募集タブ
- iOS版 ホーム画面
- 共通グッズグリッド表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- `npm --prefix mobile run update:ios:preview -- --message "[iter162.61] 在庫Wishホーム導線を整理" --non-interactive`
- マイ在庫のグッズパネル上部にキャラ名/状態タグが出ないことを確認
- マイ在庫の余白を左右スワイプして、画面が指に追従しながらステータスタブが切り替わることを確認
- Wishで推し/種別フィルタが使えることを確認
- 個別募集タブで募集デッキだけが残り、下の一覧が出ないことを確認
- ホーム上部にグルームレールが表示されることを確認
- EAS Update: `40d23cd1-519d-460e-8baa-98a30811ad22`

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ マイ在庫のカード上部タグを非表示化
- ✅ マイ在庫のステータス切り替えを指追従の横ページャーへ変更
- ✅ Wishに推し/種別フィルタを追加
- ✅ 個別募集タブは募集デッキのみ表示
- ✅ ホーム上部にグルームレールを追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ Expo preview channel への EAS Update 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.60：めぐりメッセージ未読バッジを実件数化

### 背景・問題意識

オーナーから、めぐりあいのメッセージ一覧に出ているバッジは、相手のメッセージのうちこちらが未読の件数を表示するべきという指示があった。また、既読/未読が実際には機能しておらず、バッジ有無によって送信日時の表示位置もずれているため、バッジがある行でも送信日時を右端に揃える必要があった。

### 変更内容

#### `mobile/src/lib/meguriMessages.ts`
- めぐりメッセージの相手側メッセージIDを定義し、未読件数を算出する共通ヘルパーを追加した。
- 会話を開いたら相手側メッセージを既読として `AsyncStorage` に保存する処理を追加した。

#### `mobile/app/(tabs)/transactions.tsx`
- めぐりあいメッセージ一覧の未読バッジを、仮の `index` 判定ではなく相手側メッセージの未読件数から表示するようにした。
- 会話を開いた時点で既読状態を保存し、画面へ戻ったときにもフォーカス時に既読状態を読み直すようにした。
- 送信日時を本文側の行内から右側のメタ列へ移し、バッジ有無に関係なく同じ右端位置へ揃えた。

#### `mobile/app/meguri-letters.tsx`
- めぐりメッセージ一覧側も同じ既読状態を読み込み、未読バッジを相手側メッセージの未読件数で表示するようにした。
- 会話画面を開いたらその相手からのメッセージを既読化し、一覧へ戻るとバッジが消えるようにした。
- ユーザー名横の仮件数表記を削除し、件数表示をバッジへ一本化した。

### 影響範囲

- iOS版 やりとり > めぐりあいメッセージ一覧
- iOS版 めぐりメッセージ一覧
- iOS版 めぐりメッセージ会話画面の既読化

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 未読バッジがあるめぐりメッセージを開き、一覧へ戻るとバッジが消えることを確認
- バッジあり/なしの行で、送信日時が同じ右端位置に表示されることを確認
- バッジの数が相手側メッセージの未読件数になることを確認

### 関連ファイル

- `mobile/src/lib/meguriMessages.ts`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 未読バッジを仮の index 値から相手側メッセージの未読件数へ変更
- ✅ 会話を開いた時点で既読状態を保存
- ✅ めぐりあい一覧へ戻った時も既読状態を再読み込み
- ✅ バッジ有無に関係なく送信日時を右端列へ固定
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.59：スケジュール画面をカレンダー入力へ変更

### 背景・問題意識

オーナーから、左ドロワーのスケジュールから開く設定画面について、タイトル下の「自分の予定（AWとは別）」表記を消し、スケジュール設定のメリットを画面上部に示したうえで、待ち合わせ候補の登録で使っているカレンダー機能を画面内に載せたいという指示があった。また、時間帯選択後は待ち合わせ候補登録と同じようなポップアップを出し、この画面固有の項目として「予定名」を入力できるようにする必要があった。

### 変更内容

#### `mobile/app/schedules.tsx`
- `RouteHeader` の subtitle を外し、「自分の予定（AWとは別）」が表示されないようにした。
- 画面上部に、スケジュール設定によって相手が交換候補を提示しやすくなるメリット文言を追加した。
- 既存の一覧中心UIを、待ち合わせ候補登録と同じ5日表示・時間グリッド・長押し/タップで時間帯を作るカレンダーUIへ変更した。
- 時間帯を選択すると、iOSでは `pageSheet` のポップアップを開き、「予定名」を入力して保存できるようにした。
- 既存予定はカレンダー上のブロックとして表示し、タップで予定名編集、長押しドラッグで移動、下端ドラッグで終了時刻変更ができるようにした。

### 影響範囲

- iOS版 左ドロワー > スケジュール
- iOS版 スケジュール登録・編集
- `schedules` テーブルへの登録・更新・削除

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 左ドロワーからスケジュールを開き、「自分の予定（AWとは別）」が出ないことを確認
- 画面上部にスケジュール設定のメリット文言が出ることを確認
- カレンダー上で時間帯を選択すると、予定名入力のポップアップが出ることを確認
- 予定名を保存するとカレンダー上に予定ブロックが表示されることを確認

### 関連ファイル

- `mobile/app/schedules.tsx`

### セルフレビュー結果

- ✅ 「自分の予定（AWとは別）」表記を削除
- ✅ メリット文言を画面上部に追加
- ✅ 待ち合わせ候補登録と同系統の時間グリッド操作をスケジュール画面へ追加
- ✅ 時間帯選択後のポップアップに「予定名」入力を追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ 既存 `schedules` テーブル利用のみのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.58：左ドロワーに自分のプロフィールアイコンを反映

### 背景・問題意識

オーナーから、左ドロワーに表示されるアイコンへ、自分のプロフィールで設定したアイコン画像を表示したいという指示があった。プロフィール編集画面では `users.avatar_url` を保存している一方、左ドロワーは認証メタデータ側の `avatar_url` / `picture` を見ていたため、アプリ内プロフィールで設定した画像が反映されなかった。

### 変更内容

#### `mobile/src/auth/AuthProvider.tsx`
- 認証コンテキストの `AuthProfile` に `avatarUrl` / `displayName` / `handle` を追加した。
- `refreshProfile()` で `users.avatar_url` / `display_name` / `handle` を取得するようにした。

#### `mobile/app/(tabs)/_layout.tsx`
- 左ドロワーの表示名・ハンドル・アイコン画像を、`profile` の値を優先して表示するようにした。
- アイコン画像は `profile.avatarUrl` を最優先し、なければ従来どおり認証メタデータへフォールバックするようにした。

#### `mobile/app/profile-edit.tsx`
- プロフィール保存成功後に `refreshProfile()` を呼び、保存したアイコン画像が左ドロワーへ即時反映されるようにした。

### 影響範囲

- iOS版 左ドロワー
- iOS版 プロフィール編集
- iOS版 認証プロフィールコンテキスト

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- プロフィール編集でアイコン画像を設定・保存し、左ドロワーを開いて同じ画像が表示されることを確認

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/profile-edit.tsx`

### セルフレビュー結果

- ✅ 左ドロワーは `users.avatar_url` 由来のプロフィール画像を優先表示
- ✅ 保存後に `refreshProfile()` を実行し、画面再起動なしで反映されるようにした
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.57：グルーム閲覧をユーザー単位キューブへ調整

### 背景・問題意識

オーナーから、グルーム閲覧の進捗ステータスバーは投稿単位ではなく一人のアカウント単位で分割したいこと、グルームはユーザーごとに3Dキューブの各面になっているイメージにしたいこと、上部の黒い透明覆いと右上の `×` / `...` を外したいこと、未入力の一言は非表示にし、表示する場合も背景なし・左寄せ・小さめ・細めにしたいこと、下スワイプで元の画面へ戻りながらグルームアイコンへ収まるような退出動作にしたいこと、閲覧済みグルームのアイコン枠をグレーにしたいという指示があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- グルーム閲覧用に投稿配列からアカウント単位の `faces` を作り、進捗バー・左右移動・3Dキューブ面をユーザー単位で扱うようにした。
- グルームビューア上部/下部の黒い scrim 表示を外し、右上の `...` と `×` ボタンも表示しない構成にした。
- グルームの一言は未入力なら非表示にし、投稿時も空入力なら空のまま保持するようにした。
- 一言表示は背景なし・左寄せ・小さめ・細めのスタイルへ変更した。
- 下スワイプ時にビューア全体が下へ移動しながら縮小・フェードして閉じる dismiss アニメーションを追加した。
- 開いたグルームのアカウントキーをローカル state で記録し、閲覧済みの丸アイコン枠をグレー表示にした。

### 影響範囲

- iOS版 めぐりホーム
- iOS版 グルーム閲覧モーダル

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- グルーム閲覧で進捗バーがアカウント単位の本数になることを確認
- 横スワイプでユーザーごとの3Dキューブ面として切り替わることを確認
- 上部の黒い覆い、右上の `...` / `×` が出ないことを確認
- 一言未入力のグルームで一言欄が出ないことを確認
- 一言ありのグルームで、左寄せ・小さめ・細めの文字になることを確認
- 下スワイプでビューアが縮小しながら閉じ、閲覧済みアイコン枠がグレーになることを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ 進捗バー・左右移動・3D面をユーザー単位へ変更
- ✅ 上下の黒い覆いと右上操作ボタンを表示から削除
- ✅ 未入力の一言は非表示
- ✅ 一言表示は背景なし・左寄せ・小さめ・細めに変更
- ✅ 下スワイプ dismiss と閲覧済みグレー枠を追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.56：取引チャットの取引内容と証跡確認を整理

### 背景・問題意識

オーナーから、取引チャット上の待ち合わせ場所には簡易地図を表示しなくてよいこと、取引内容はタップで詳細ポップアップ表示にしたいこと、メッセージ入力欄上の「写真添付」クイックボタンを外したいこと、証跡到着後は遅刻・キャンセル相談導線を出さないこと、追加撮影時は撮影画面へ直接遷移せず事前に「交換したグッズを撮影してください」と案内したいこと、取引完了確認画面では証跡サムネイルを選択して上部表示へ反映し、選択枠と撮影者表示を出したいという指示があった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引内容カードから待ち合わせ場所の簡易地図サムネイルを削除し、時間・場所テキストのみの表示に変更した。
- 取引内容カード全体をタップ可能にし、受け取るもの・出すもの・待ち合わせを確認できる詳細モーダルを追加した。
- メッセージ入力欄上のクイックアクションから「写真添付」を削除した。
- 取引証跡が届いているカードから `TradeSupportActions` を外し、「遅刻を連絡」「キャンセル相談」が出ないようにした。
- 証跡到着後の「追加撮影」は撮影画面へ遷移せず、確認ポップアップを出してからカメラを起動し、撮影した画像を証跡として追加するようにした。

#### `mobile/app/transaction-approve.tsx`
- 証跡一覧のサムネイルをタップ可能にし、選択した証跡を上部の大きい画像へ反映するようにした。
- 選択中の証跡サムネイルに枠線と背景を付け、どの証跡を見ているか分かるようにした。
- 証跡の上部メタ情報とサムネイルラベルに、誰が撮影したものかを表示するようにした。

### 影響範囲

- iOS版 取引チャット
- iOS版 取引証跡追加
- iOS版 取引完了の確認画面

### 確認方法

- `npm --prefix mobile run typecheck`
- 取引チャットで、取引内容カードに簡易地図が出ず、カードタップで詳細ポップアップが開くことを確認
- 取引チャットの入力欄上のクイックアクションに「写真添付」が出ないことを確認
- 証跡到着後のカードに「遅刻を連絡」「キャンセル相談」が出ないことを確認
- 「追加撮影」押下時に事前ポップアップが出て、その後カメラが開くことを確認
- 取引完了の確認画面で証跡サムネイルをタップし、上部画像・選択枠・撮影者表示が切り替わることを確認

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/transaction-approve.tsx`

### セルフレビュー結果

- ✅ 取引内容カード内の待ち合わせ簡易地図を削除
- ✅ 取引内容詳細はモーダルで確認可能
- ✅ 入力欄上の「写真添付」クイックボタンを削除
- ✅ 証跡到着後カードから遅刻・キャンセル相談導線を削除
- ✅ 追加撮影は事前ポップアップ後にカメラ起動
- ✅ 証跡確認画面で選択中画像・選択枠・撮影者表示を追加
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.55：チャット入力バーのキーボード追従を安定化

### 背景・問題意識

オーナーから、取引チャットで入力欄をタップしても入力バーがキーボード上へ調整されないという指摘があった。また、取引チャット・めぐりチャットの複数行入力時に、同じ行の `+` アイコンと送信アイコンを入力欄の最下行側へ固定したいという要望があった。

### 変更内容

#### `mobile/src/lib/useKeyboardInset.ts`
- iOS/Android のキーボード表示イベントから、画面下部に対するキーボード重なり量を返す共通フックを追加した。

#### `mobile/app/transaction-detail.tsx`
- 取引チャットの下部入力バーを `KeyboardAvoidingView` 依存から、キーボード重なり量に応じて `marginBottom` を付ける構成へ変更した。
- キーボード表示中は safe-area 分の下余白を抑え、入力バーがキーボード直上に密着しやすいよう調整した。
- 複数行入力時も `+` ボタンと送信ボタンが入力欄の下端に揃うよう、各ボタンを下揃えに固定した。

#### `mobile/app/meguri-letters.tsx`
- めぐりチャットの下部入力バーにも同じキーボード重なり量による追従を適用した。
- 複数行入力時に `+` アイコンと送信アイコンが入力欄の下端へ残るよう、入力バー全体と各ボタンを下揃えにした。

### 影響範囲

- iOS版 取引チャット
- iOS版 めぐりチャット

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで取引チャットを開き、入力欄タップ時に入力バーがキーボード直上へ移動することを確認
- iOS Previewでめぐりチャットを開き、入力欄タップ時に入力バーがキーボード直上へ移動することを確認
- 複数行入力時に `+` アイコンと送信アイコンが入力欄の最下行側に揃うことを確認

### 関連ファイル

- `mobile/src/lib/useKeyboardInset.ts`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ iOS標準のキーボードイベントを使い、入力バー自体がキーボード重なり量へ追従するようにした
- ✅ 複数行入力時の `+` / 送信アイコンは下揃えに固定
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.54：グルーム閲覧をストーリーUIへ寄せる

### 背景・問題意識

オーナーから、めぐりホームのグルーム一覧は白いパネルに閉じ込めず、Instagramのストーリーのように「グルーム」見出し下へ丸アイコンを横並びにしたいという指示があった。また、グルーム閲覧画面もInstagram Stories仕様に寄せ、20秒進捗バー、左右タップでの切り替え、横スワイプ中の3Dキューブ風遷移、キーボード直上の返信入力欄を実装したいという要望があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホームのグルーム一覧から白いカード枠と補足文を削除し、「グルーム」見出し直下に丸アイコンが横並びになる構成へ変更した。
- グルーム追加ボタンを一覧の一番左に移動した。
- 旧MESSAGEパネルを削除し、めぐりメッセージ導線はフッターの `やりとり` に集約した。
- グルーム閲覧モーダルに、1枚20秒で進む分割進捗バーを追加した。
- 閲覧中の左上表示を、投稿画像ではなくめぐりアバター風の顔アイコンと名前に変更した。
- 画面右タップで次のグルームへ進む操作を追加した。
- 横スワイプで前後のグルームへ移動する際、スワイプ量に追従して3Dキューブ風に切り替わる表現を追加した。
- グルーム返信入力欄を `KeyboardAvoidingView` でキーボード直上へ出し、複数行入力は最大4行相当に制限した。

#### `mobile/src/components/IconSymbol.tsx`
- グルーム閲覧画面のアクション用に `heart` / `heart-outline` を追加した。

### 影響範囲

- iOS版 めぐりホーム
- iOS版 グルーム閲覧モーダル
- iOS版 共通簡易アイコン

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewでめぐりホームを開き、グルーム追加が左端、丸アイコン列が見出し下に出ることを確認
- グルームを開き、20秒進捗バー、右タップで次へ、横スワイプ時の3D風遷移、キーボード直上の入力欄を確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/components/IconSymbol.tsx`

### セルフレビュー結果

- ✅ グルーム一覧からMESSAGEパネルを削除し、やりとり導線との重複を解消
- ✅ 返信入力欄はiOS標準のキーボード回避挙動を使うため `KeyboardAvoidingView` を利用
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 既存用語「グルーム」の範囲内のため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.53：チャット入力欄をキーボード直上へ調整

### 背景・問題意識

オーナーから、取引チャットとめぐりチャットで文字入力時に、iOSのメッセージアプリのように入力欄がキーボードのすぐ上に出るようにしたいという指示があった。また、複数行入力時は入力欄を最大7行まで表示したいという要望があった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引チャットの入力フッターを通常フローへ戻し、`KeyboardAvoidingView` でキーボード上へ押し上げる構成にした。
- 入力中はクイックアクション列を隠し、入力欄・添付・送信だけがキーボード直上に残るようにした。
- メッセージ入力欄を複数行対応にし、最大7行相当まで表示するようにした。

#### `mobile/app/meguri-letters.tsx`
- めぐりチャット画面にも `KeyboardAvoidingView` を追加し、入力欄がキーボード上へ移動するようにした。
- めぐりチャットの入力欄も複数行対応にし、最大7行相当まで表示するようにした。

### 影響範囲

- iOS版 取引チャット
- iOS版 めぐりチャット

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで取引チャットを開き、入力欄タップ時にキーボード直上へ入力欄が移動することを確認
- iOS Previewでめぐりチャットを開き、入力欄タップ時にキーボード直上へ入力欄が移動することを確認
- 7行を超える長文入力時に入力欄が肥大化しすぎないことを確認

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ iOS標準のキーボード回避挙動を使うため `KeyboardAvoidingView` を利用
- ✅ 入力欄は7行相当で高さ上限を設定
- ✅ 取引チャットでは入力中に補助アクションを畳み、キーボード上を入力に集中できる状態へ調整
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.52：やりとり画面のタブ構成を整理

### 背景・問題意識

オーナーから、フッターの `取引` は実態として取引チャットだけでなく、めぐりメッセージも含むため `やりとり` にしたいという指示があった。また、`めぐりあい` / `取引` はタップだけでなく横スワイプで切り替え、打診中の `要対応` / `相手待ち` はタブではなく各パネル内で分かるようにしたいという要望があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- フッターの `取引` ラベルを `やりとり` に変更した。

#### `mobile/app/(tabs)/transactions.tsx`
- 通常の `やりとり` 画面から左上ヘッダー表示を削除した。
- 上位タブ `めぐりあい` / `取引` を横スワイプ可能なページャーにした。
- `打診中` / `進行中` は取引側の小さめセグメントに整理した。
- 打診中内の `要対応` / `相手待ち` タブを廃止し、取引パネル内のバッジとして表示する構成にした。

#### `mobile/app/meguri-letters.tsx`
- めぐりメッセージ画面上部の相手プロフィール帯を押すと、めぐり専用プロフィールへ遷移するようにした。

### 影響範囲

- iOS版 フッター
- iOS版 やりとり画面
- iOS版 めぐりメッセージ画面

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで、フッターが `やりとり` 表記になっていることを確認
- iOS Previewで、やりとり画面の左上に `Transactions / 取引` が出ないことを確認
- iOS Previewで、`めぐりあい` / `取引` が横スワイプで切り替わることを確認
- iOS Previewで、打診中パネルに `要対応` / `相手待ち` がバッジ表示されることを確認
- iOS Previewで、めぐりメッセージ画面の相手プロフィール帯からめぐりプロフィールへ遷移することを確認

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ iOSフッターは `NativeTabs` を維持し、ラベルのみ変更
- ✅ 取引画面内の上位切り替えは横スワイプに対応
- ✅ 打診中の `要対応` / `相手待ち` はタブではなくカード内状態として表現
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ UIラベル変更のみのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.51：プレビュー起動クラッシュを回避

### 背景・問題意識

オーナーから、Preview版で新規登録画面までは開けるが、`画面だけプレビューする` を押すとアプリが強制終了するという報告があった。プレビュー突入時はタブ配下のホーム・めぐり・取引関連モジュールが一気に読み込まれるため、起動導線では実験的なネイティブ演出や3D native module の即時ロードを避ける必要があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホームの `expo-glass-effect` / `expo-symbols` 利用を起動時は無効化し、React Native標準表示へフォールバックするようにした。
- `BlurView` も同じ feature flag 下に置き、Preview起動直後にネイティブ演出をロードしないようにした。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `expo-gl` の `GLView` をトップレベル import せず、利用時にだけ guarded `require` する形へ変更した。
- `GLView` が利用できない環境ではクラッシュさせず、既存の2Dフォールバック表示へ切り替えるようにした。

### 影響範囲

- iOS版 Preview の `画面だけプレビューする` 導線
- iOS版 ホーム画面の現地交換アクション表示
- iOS版 めぐり3D演出のフォールバック

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、新規登録/ログイン画面の `画面だけプレビューする` からホームへ遷移してクラッシュしないことを確認

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ Preview起動直後に experimental native effects をロードしないようにした
- ✅ `expo-gl` のトップレベル import を避けた
- ✅ `npm --prefix mobile run typecheck` 成功
- ✅ `npm --prefix mobile run export:ios:preview` 成功
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.50：取引タブをめぐりあい二層構成へ変更

### 背景・問題意識

オーナーから、自分のプロフィール画面では左ドロワーから設定できる列を出さず、見るためのプロフィールに絞りたいという指示があった。また、フッターの `取引` では、通常の取引だけでなく、めぐり機能のメッセージ一覧も同じ入口から見たいという要望があった。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- 自分のプロフィール画面から `アイデンティティ` 以下の設定・サポート・アカウント列を削除した。
- プロフィール本体、推し、譲る候補に表示内容を絞った。

#### `mobile/app/(tabs)/_layout.tsx`
- 左ドロワーからフッターと重複する `通知` 導線を外した。
- 左ドロワーに `完了した取引` を追加し、完了ステータスの取引を専用入口から見られるようにした。

#### `mobile/app/(tabs)/transactions.tsx`
- フッターの `取引` 画面に、上位タブ `めぐりあい` / `取引` を追加した。
- `取引` 側のタブを `打診中` / `進行中` のみに整理し、`完了` は左ドロワーの `完了した取引` から開く構成にした。
- `めぐりあい` 側に、めぐりメッセージの一覧を表示し、押下で対象ユーザーのめぐりメッセージ画面を直接開く導線を追加した。

#### `mobile/app/meguri-letters.tsx`
- `open=1&userId=...` で特定のめぐりメッセージを直接開けるようにした。
- めぐりメッセージのやり取り画面を、取引チャットの構成に寄せたヘッダー・相手情報帯・下部入力フッターへ再構成した。
- 取引詳細ヘッダーは表示せず、めぐり用のアバターと名前だけを表示する構成にした。

### 影響範囲

- iOS版 自分のプロフィール画面
- iOS版 左ドロワー
- iOS版 取引タブ
- iOS版 めぐりメッセージ一覧・メッセージ画面

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで、自分のプロフィール画面から `アイデンティティ` 以下の列が消えていることを確認
- iOS Previewで、左ドロワーに `完了した取引` が表示されることを確認
- iOS Previewで、フッターの `取引` に `めぐりあい` / `取引` の上位タブが表示されることを確認
- iOS Previewで、`取引` 側に `打診中` / `進行中` のみが表示されることを確認
- iOS Previewで、めぐりメッセージ一覧から会話画面に遷移し、取引チャット由来の入力フッターが表示されることを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ 自分のプロフィール画面を設定導線なしの表示に整理した
- ✅ 完了取引を左ドロワーの専用項目へ移した
- ✅ 取引タブを `めぐりあい` / `取引` の二層構成にした
- ✅ 取引側の上部タブを `打診中` / `進行中` のみにした
- ✅ めぐりメッセージの会話画面を取引チャット構成に寄せ、取引詳細ヘッダーは省いた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.49：グルーム導線をめぐりホームへ追加

### 背景・問題意識

オーナーから、めぐり機能にインスタグラムのストーリーのような一過性投稿を追加し、名前を「グルーム」にしたいという要望があった。推し活現場で撮ったグッズ・服装・現場の雰囲気を、めぐりあった人の間で見られるようにし、気になった相手へメッセージやいいねを送れる導線にする。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホーム上部に、グルームの丸い写真アイコンが横並びで表示されるレールを追加した。
- レール右端に、自分のグルームを追加するプラス付き丸アイコンを追加した。
- 追加アイコンからカメラを起動し、正方形トリミング後にひとことを編集して投稿できるローカル投稿フローを追加した。
- 他人/自分のグルームをタップすると、写真が画面いっぱいに表示される全画面ビューアを追加した。
- 全画面ビューア下部に、メッセージ入力欄・いいねボタン・送信ボタンを配置した。

#### `notes/10_glossary.md`
- 新用語 `グルーム` を追加した。

#### `notes/09_state_machines.md`
- `Groom Lifecycle` を追加し、`draft` / `published` / `expired` / `hidden` / `archived` を定義した。

#### `notes/05_data_model.md`
- 永続化時の draft として `groom_posts` / `groom_reactions` のテーブル候補を追加した。

### 影響範囲

- iOS版 めぐりホーム
- めぐりからめぐりメッセージへ向かうソーシャル導線
- 推しすれ違い系の用語・状態・データモデル draft

### 確認方法

- `npm --prefix mobile run typecheck`
  - 現時点では既存/並行作業中の `mobile/app/(tabs)/transactions.tsx` の型エラーで失敗（今回変更した `encounters.tsx` 由来のエラーは出ていない）
- iOS Previewで、めぐりホーム上部にグルームの丸アイコン列が表示されることを確認
- iOS Previewで、右端の追加アイコンからカメラ起動・編集・投稿ができることを確認
- iOS Previewで、グルームをタップすると全画面表示になり、下部にメッセージ入力といいねが表示されることを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `notes/10_glossary.md`
- `notes/09_state_machines.md`
- `notes/05_data_model.md`

### セルフレビュー結果

- ✅ めぐりホーム上部にグルーム導線を追加した
- ✅ 自分の投稿追加アイコンを右端に配置した
- ✅ カメラ撮影 → 編集 → 投稿の流れを追加した
- ✅ 他人のグルーム閲覧時に全画面表示・メッセージ入力・いいねを表示した
- ✅ 新用語 `グルーム` を `notes/10_glossary.md` に追加した
- ✅ 新状態を `notes/09_state_machines.md` に追加した
- ✅ 永続化時のテーブル候補を `notes/05_data_model.md` に draft 追記した
- ⚠️ 型チェックは既存/並行作業中の `transactions.tsx` エラーで失敗しているため、別途修正が必要

---

## イテレーション162.48：推し追加導線を固定フッター化

### 背景・問題意識

オーナーから、推し設定画面の上部にある `登録済みの推しを追加` ボタンを固定フッターへ移し、`マスタに無い推しを追加リクエスト` は推し設定画面上には出さないようにしたいという指示があった。また、登録済みの推し追加モーダル内の `すべて` / `K-POP` などのジャンルタブが選択時に潰れて見える問題と、追加完了メッセージをトースト形式にしたいという要望があった。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し設定画面上部の追加ボタン群を削除し、画面左下に固定表示される `+ 推しを追加` のピル型フッター導線へ変更した。
- 推し設定画面上の `マスタに無い推しを追加リクエスト` ボタンを非表示にした。
- 登録済みの推し追加時の成功文言を `推しを追加しました` に変更し、画面内テキストではなく下部トーストで表示するようにした。
- ジャンルタブのチップに最小高さ・縮小禁止・1行表示を指定し、選択時に潰れて見えないようにした。

### 影響範囲

- iOS版 推し設定画面
- 登録済みの推し追加モーダル
- 推し追加成功時の通知表示

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで、推し設定画面上部に追加ボタンが出ず、左下固定フッターに `推しを追加` が出ることを確認
- iOS Previewで、登録済みの推し追加モーダルの `すべて` / `K-POP` などのタブが選択時も潰れないことを確認
- iOS Previewで、推し追加後に `推しを追加しました` がトースト表示されることを確認

### 関連ファイル

- `mobile/app/oshi-settings.tsx`

### セルフレビュー結果

- ✅ 推し設定画面上の追加リクエストボタンを削除した
- ✅ 追加導線を左下固定フッターに移した
- ✅ ジャンルチップの縮小を防いだ
- ✅ 成功メッセージをトースト化した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.47：めぐりメッセージ一覧をMegrim文法へ戻す

### 背景・問題意識

オーナーから、めぐりメッセージはLINE風の一覧/トーク構造に寄せつつ、画面上部の行・フッター・文字サイズはMegrim本体の文法に合わせたいという指摘があった。また、メッセージルームから戻る時は必ずメッセージ一覧へ戻る必要があった。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- メッセージ一覧の上部ヘッダーを、左戻るボタン + 中央 `メッセージ` のみに整理した。
- LINE風の独自フッターを削除し、Megrimの通常タブに合わせた下部ナビ表示へ差し替えた。
- 一覧のユーザー名、本文プレビュー、時刻、未読バッジのフォントサイズ/色をMegrimの既存画面に近い密度へ調整した。
- メッセージルーム表示中に戻る操作をした場合、まず一覧へ戻るように `BackHandler` とヘッダー戻るを整理した。
- めぐりプロフィールからのメッセージ導線は、対象相手を一覧先頭に出す形へ変更し、ルームは一覧から開く構造にした。

### 影響範囲

- iOS版めぐりメッセージ一覧
- iOS版めぐりメッセージルーム
- めぐりプロフィールからのメッセージ導線

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで、めぐりメッセージ一覧のヘッダーが `メッセージ` のみになっていることを確認
- iOS Previewで、一覧下部がLINE風フッターではなくMegrim本体の下部ナビに見えることを確認
- iOS Previewで、メッセージルームから戻ると一覧へ戻ることを確認

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ LINE風の上部ピル/右アクションを削除した
- ✅ LINE風フッターをMegrim側の下部ナビ表現へ戻した
- ✅ 文字サイズと色をMegrimの既存トーンへ寄せた
- ✅ ルームからの戻り先を一覧へ寄せた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.46：めぐりメッセージ画像送信と専用プロフィールを追加

### 背景・問題意識

オーナーから、めぐりメッセージをちゃんと機能するようにし、画像も送れるようにしたいという指示があった。また、めぐり広場でキャラを押した後のプロフィールは、グッズ交換側の相手プロフィールではなく、めぐり専用プロフィールとして3Dアバター、拠点、公開情報、自分とのめぐり回数、メッセージ導線を表示したいという要望があった。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- `expo-image-picker` を使い、めぐりメッセージのトークルームから画像を選択して送信できるようにした。
- 画像送信時は自分側の吹き出し内に画像プレビューを表示するようにした。
- 画像送信も無料送信枠を消費し、Plus未加入で無料枠を超える場合はPlus導線へ遷移するようにした。
- `/meguri-letters?userId=...` で指定ユーザーをメッセージ一覧の先頭に表示できるようにした。
- 一覧プレビューも、送信済み画像がある場合は `画像を送信しました` を表示するようにした。

#### `mobile/app/meguri-profile.tsx`
- めぐり専用プロフィール画面を新規追加した。
- 3Dアバター、拠点、ユーザー名、公開している推し情報、今日のひとこと、最近の公開メモ、めぐり回数を表示するようにした。
- `メッセージを送る` ボタンから、対象ユーザーが先頭に出るめぐりメッセージ一覧へ遷移するようにした。
- 3Dが利用できない場合は既存の2D `WalkingCard` 表示にフォールバックするようにした。

#### `mobile/app/meguri-plaza.tsx`
- 広場の `詳細を見る` 導線を、グッズ交換側の `/user-profile` ではなく `/meguri-profile` へ変更した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `presentation="profile"` を追加し、めぐりプロフィール用に1体の3Dアバターを中央表示できるようにした。

#### `notes/10_glossary.md`
- `めぐりプロフィール` を新規用語として追加した。

### 影響範囲

- iOS版めぐりメッセージ
- iOS版めぐり広場
- iOS版めぐりプロフィール
- Megrum Plus の本文開封/送信枠導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐりメッセージから画像を選択して自分側の吹き出しに表示できることを確認
- iOS Previewで、無料枠超過時に画像/テキスト送信がPlus導線になることを確認
- iOS Previewで、めぐり広場の `詳細を見る` からめぐり専用プロフィールへ遷移することを確認
- iOS Previewで、めぐりプロフィールのメッセージ導線から対象ユーザーが先頭に出るメッセージ一覧へ遷移することを確認

### 関連ファイル

- `mobile/app/meguri-letters.tsx`
- `mobile/app/meguri-profile.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 画像送信をめぐりメッセージに追加した
- ✅ 画像送信もPlus/無料枠制限の対象にした
- ✅ めぐり広場のプロフィール導線をグッズ交換側から分離した
- ✅ 3Dアバター付きのめぐり専用プロフィールを追加した
- ✅ `めぐりプロフィール` を用語集に追加した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.45：めぐりメッセージをLINE風UIへ再構成

### 背景・問題意識

オーナーから、めぐりメッセージ一覧とメッセージ詳細について、LINEのUIを完全に再現するくらいの精度で寄せたいという指示があった。また、Plusプランでないと本文開封や月3通目以降の送信ができない仕様も、見た目だけでなく挙動として入れる必要があった。LINE公式ガイド/ヘルプで、トーク一覧からトークルームへ入り、トークルーム内で左右の吹き出し・上部メニュー・入力欄を扱う構成を確認した。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- `RouteHeader` とカード型レイアウトをやめ、白背景のLINE風トーク一覧へ再構成した。
- 上部は黒い `メッセージ⌄` ピル、太い見出し、右側アクションアイコンの構成にした。
- トーク一覧は、丸いアバター、太い相手名、薄いプレビュー、右側の時刻と緑の未読バッジに寄せた。
- めぐりユーザーから追加のモック会話を生成し、LINEのように会話が縦に並ぶ密度へ調整した。
- 下部にLINE風のタブバーを追加し、`メッセージ` をアクティブ表示にした。
- 個別画面は、白い上部バー、青系トーク背景、日付チップ、左=相手/右=自分の吹き出し、下部入力バーへ変更した。
- Plus未加入かつ未開封の会話では、本文の代わりに `メッセージがきています！` と `Plusで開封` を表示するようにした。
- Plus未加入時は無料送信枠を月2通までに制限し、3通目以降は入力欄と送信ボタンからPlus導線へ遷移するようにした。
- 送信できたメッセージは、自分側の緑の吹き出しとして会話内に追加されるようにした。

### 影響範囲

- iOS版めぐりメッセージ一覧
- iOS版めぐりメッセージ詳細
- Megrum Plus のメッセージ本文開封/送信枠導線

### 確認方法

- LINE公式ガイド/ヘルプのトーク一覧・トークルーム構成を確認
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、一覧がLINE風のトーク一覧になっていることを確認
- iOS Previewで、詳細がLINE風のトークルームになっていることを確認
- iOS Previewで、未加入時の本文開封ロックと3通目以降送信ロックを確認

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ トーク一覧/トークルームの視覚構造をLINE寄せに再構成した
- ✅ 会話件数を増やし、一覧画面の密度をLINEのトーク一覧に近づけた
- ✅ 受信/送信のタブ分割はなく、相手ごとのトーク一覧にした
- ✅ Plus未加入時は本文を伏せ、開封導線を明示した
- ✅ 無料は月2通まで、3通目以降はPlus誘導になるよう送信処理を制御した
- ✅ 送信成功時に自分側の吹き出しとして追加されることを実装した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の追加更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の追加更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.44：めぐり広場の説明削除と引き構図調整

### 背景・問題意識

オーナーから、めぐり広場の一番上の説明書きと一番下の説明書きは不要であり、キャラクター同士の距離が近すぎるため少し間隔を取りたいという指示があった。また、カメラがキャラクターに寄りすぎているため、もっと引きの見下ろし構図にしたいという要望があった。

### 変更内容

#### `mobile/app/meguri-plaza.tsx`
- 上部タイトル横の説明文を削除し、`めぐり広場` のタイトルだけを残した。
- 下部の説明パネルを削除し、画面下まで3D広場が見えるようにした。
- キャラ選択用の透明タップ領域を、広がった3D配置に合わせて再配置した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `presentation="plaza"` のカメラ位置をさらに上・奥へ移動し、広場全体が見える引き構図にした。
- 広場住人の配置座標を広げ、キャラ同士の距離を確保した。
- 広場住人の表示スケールを少し下げ、密集感を抑えた。

### 影響範囲

- iOS版めぐり広場
- めぐり広場の3D住人表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、上/下の説明文が消え、引きの見下ろし構図になっていることを確認

### 関連ファイル

- `mobile/app/meguri-plaza.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 上部説明文を削除した
- ✅ 下部説明パネルを削除した
- ✅ カメラを引いて、キャラ同士の距離を広げた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.43：めぐりメッセージのPlus制限を明確化

### 背景・問題意識

オーナーから、`すれ違いレター` から `メッセージ` への文言変更とLINE風UIの依頼について、Plusプランでないと本文開封や月3通目以降の送信ができない仕様まできちんと実装できているか確認があった。前回実装ではLINE風の一覧/スレッド自体は入っていたが、無料送信枠の見え方と、送信した文が会話に積まれる挙動が弱かったため補強した。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- LINE公式ガイドのトーク一覧/トークルーム構成を参考に、相手ごとの一覧から個別トークへ入る構成を維持した。
- Plus未加入かつ本文未表示の会話では、本文を出さず `メッセージがきています！` と `Plusで開封` を表示するようにした。
- トーク詳細にPlus制限カードを追加し、本文開封にはPlusが必要であることを明示した。
- 無料送信枠を月2通までとし、3通目以降はPlus誘導になるよう送信ボタンと入力欄を制御した。
- 送信できた場合は、自分側の吹き出しとして会話に追加されるようにした。
- Plus加入プレビュー時は本文開封と送信制限解除が確認できるようにした。

### 影響範囲

- iOS版めぐりメッセージ一覧
- iOS版めぐりメッセージ詳細
- Megrum Plus のメッセージ開封/送信枠導線

### 確認方法

- LINE公式ガイドのトーク一覧/トークルーム系ページを確認
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、Plus未加入時に本文が伏せられ、`メッセージがきています！` と表示されることを確認
- iOS Previewで、無料送信枠を超えた状態では送信欄がPlus誘導になることを確認

### 関連ファイル

- `mobile/app/meguri-letters.tsx`

### セルフレビュー結果

- ✅ LINE風の相手別一覧/個別トーク構成を維持した
- ✅ Plus未加入時の本文開封ロックを明示した
- ✅ 無料は月2通まで、3通目以降はPlusという制限をUIと送信処理に入れた
- ✅ 送信済みメッセージが自分側の吹き出しとして追加されるようにした
- ✅ 既存の `notes/09_state_machines.md` に月2通/Plus制限が記録済みのため追加更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の追加更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.42：めぐり広場を見下ろし3D広場へ刷新

### 背景・問題意識

オーナーから、めぐり広場を添付画像のように上から見下ろす形で、複数ユーザーのキャラクターを画面いっぱいに見られるよう改善したいという指示があった。あわせて、各キャラをタップするとこちらを見るようにし、`詳細を見る` の吹き出しからそのユーザー詳細画面へ遷移したいという要望があった。

### 変更内容

#### `mobile/app/meguri-plaza.tsx`
- 旧カード内表示のめぐり広場を、全画面の3D広場表示へ変更した。
- 10人のめぐり住人を上から見下ろす配置にし、透明なタップ領域を重ねてキャラごとに選択できるようにした。
- 選択したキャラの近くに `詳細を見る` 吹き出しを表示し、タップで `/user-profile?id=...` へ遷移するようにした。
- 3Dが利用できない場合の2Dフォールバックも、上から見下ろす広場配置に寄せた。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `focusedId` を追加し、めぐり広場で選択された住人だけがカメラ側を向いて少し大きく見えるようにした。
- `presentation="plaza"` のカメラを上から見下ろす位置へ変更した。
- 広場用の住人配置を、複数人が画面全体に散らばって見える並びへ調整した。

#### `notes/10_glossary.md`
- `めぐり広場` の定義を、上から見下ろす3D広場とタップ詳細導線を含む内容へ更新した。

### 影響範囲

- iOS版めぐり広場
- iOS版めぐり住人3D表示
- 相手プロフィールへの導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐり広場が画面いっぱいの見下ろし3D表示になることを確認
- iOS Previewで、キャラタップ後に吹き出しが出て、詳細画面へ遷移することを確認

### 関連ファイル

- `mobile/app/meguri-plaza.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ カード内表示ではなく、全画面の3D広場表示に変更した
- ✅ キャラごとのタップ領域、選択表示、詳細導線を追加した
- ✅ 3D利用不可時の2Dフォールバックを残した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の追加更新は不要
- ✅ `めぐり広場` の定義変更を `notes/10_glossary.md` に反映した
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.41：めぐりメッセージをLINE風スレッドへ刷新

### 背景・問題意識

オーナーから、`すれ違いレター` という文字を `メッセージ` に修正し、受け取った/送ったの2分割ではなく、LINEのように相手ごとの一覧と双方向のやり取り画面にしたいという指示があった。また、Plus未加入の場合は本文を見せず、`メッセージがきています！` と到着だけが分かる見せ方にしたいという要望があった。着手前にLINE公式ガイドのトーク一覧の考え方を確認した。

### 変更内容

#### `mobile/app/meguri-letters.tsx`
- 画面タイトルとUI表記を `めぐりメッセージ` / `メッセージ` に変更した。
- `受け取った` / `送った` のセグメントを削除し、相手ごとのLINE風メッセージ一覧へ変更した。
- 未読バッジ、時刻、相手名、プレビューを持つトーク一覧の形にした。
- Plus未加入かつ本文未表示の会話は、一覧と本文側の両方で `メッセージがきています！` と表示するようにした。
- 各会話をタップすると、左右の吹き出しでやり取りする双方向スレッド画面へ遷移するようにした。

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホーム、実績、Plusモーダル、旧レター系モーダルの表示文言をメッセージ表記へ統一した。

#### `mobile/app/meguri-plus.tsx`
- Plus訴求を、レター開封ではなくメッセージ本文表示・返信へ変更した。

#### `mobile/app/meguri-achievements.tsx`
#### `mobile/app/meguri-report.tsx`
#### `mobile/app/meguri-plaza.tsx`
- めぐり関連の表示文言を `レター` から `メッセージ` に変更した。

#### `mobile/src/components/IconSymbol.tsx`
- メッセージ一覧/スレッドで使う `search-outline`、`send-outline`、`ellipsis-horizontal`、`chevron-back`、`add-circle-outline` を追加した。

#### `notes/09_state_machines.md`
- 推しすれ違いレター状態管理を、めぐりメッセージの状態管理へ名称変更した。
- 本文開封表記を本文表示表記へ更新した。

#### `notes/10_glossary.md`
- `すれ違いレター` を廃止用語に移し、後継を `めぐりメッセージ` とした。
- 推しすれ違い Plus の説明も、メッセージ本文表示・返信・送信枠追加へ更新した。

### 影響範囲

- iOS版めぐりメッセージ一覧
- iOS版めぐりメッセージ詳細
- iOS版めぐりホーム/Plus/実績/レポート/広場の表示文言
- めぐりメッセージの用語定義と状態遷移ドキュメント

### 確認方法

- LINE公式ガイドのトーク整理ページを確認
- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐりメッセージが相手ごとの一覧と双方向スレッドになっていることを確認
- Plus未加入時に本文の代わりに `メッセージがきています！` と表示されることを確認

### 関連ファイル

- `mobile/app/meguri-letters.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-plus.tsx`
- `mobile/app/meguri-achievements.tsx`
- `mobile/app/meguri-report.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/src/components/IconSymbol.tsx`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ `すれ違いレター` の表示を `メッセージ` へ置換した
- ✅ 受信/送信の分割をやめ、相手ごとの一覧と双方向スレッドにした
- ✅ Plus未加入時は本文を伏せ、到着だけを示す表示にした
- ✅ 状態遷移ドキュメントを `めぐりメッセージ` 表記へ更新した
- ✅ 用語集で `すれ違いレター` を廃止語、`めぐりメッセージ` を後継語として整理した
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.40：めぐり広場を3D住人表示へ差し替え

### 背景・問題意識

オーナーから、めぐり広場のキャラクターを現在の3Dキャラクターへ変更したいという指示があった。また、めぐり広場とめぐりホームのキャラクターについて、立っている時に完全停止ではなく、少し横に揺れながら自然に待機している動きにしたいという要望があった。

### 変更内容

#### `mobile/app/meguri-plaza.tsx`
- めぐり広場のメイン表示を、旧 `WalkingCard` の2Dカード表現から `MeguriThreeScene` の3D住人表示へ差し替えた。
- 広場用に8人の住人が広場内に並ぶ表示へ変更した。
- 3Dが利用できない場合だけ旧2D表示へ戻すフォールバックを残した。
- 3Dシーン下に、出会った住人のIDと回数が分かるコンパクトなチップを追加した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 3Dシーンに広場用の `presentation="plaza"` を追加した。
- 広場用のカメラ位置と住人配置を追加し、複数人が広場に立っている見え方にした。
- ホーム・広場・待機列などの停止中キャラクターにも、横揺れを含む自然なアイドルモーションを付けた。
- 立っている時も、体・頭・しっぽの微細な揺れに加えて、グループ全体が少し横に揺れるようにした。

### 影響範囲

- iOS版めぐり広場
- iOS版めぐりホームの3D住人表示
- めぐり演出3D住人の待機モーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐり広場の住人が3Dキャラクターで表示されることを確認
- iOS Previewで、めぐりホーム/広場の住人が立っている時に自然に横揺れすることを確認

### 関連ファイル

- `mobile/app/meguri-plaza.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ めぐり広場を現在の3D住人表示へ差し替えた
- ✅ GL利用不可時の2Dフォールバックを残した
- ✅ ホーム/広場の待機キャラに横揺れを追加した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.39：認証画面のアプリアイコン化と登録前同意を追加

### 背景・問題意識

オーナーから、アプリ内で古いロゴ/アイコンが使われている箇所を現在のアプリアイコンへ差し替えたいという指示があった。また、新規登録入口の画面で「ログイン」導線を見るために下スクロールが必要になっており、初期表示内に登録ボタン・Apple/Google登録・ログイン導線が収まるようにしたいという要望があった。さらに、Apple/Googleで登録する前に利用規約・プライバシーポリシー同意チェックを必須にしたいという指示があった。

### 変更内容

#### `mobile/src/components/MegrumLogo.tsx`
- 旧テキストロゴ `Mg` を、現在のアプリアイコン画像 `mobile/assets/icon.png` 表示へ差し替えた。
- Welcome/Loginなど、`MegrumLogo` を使う画面がまとめて現在のアプリアイコン表示になるようにした。

#### `mobile/app/(auth)/welcome.tsx`
- 画面上部余白、ロゴサイズ、ボタン間隔、下部余白を詰め、初期表示で登録ボタン群とログイン導線が見えるようにした。
- 登録ボタン群の上に、利用規約・プライバシーポリシー同意チェックを追加した。
- 同意前はメール登録・Apple登録を進められないようにした。
- 同意文内の「利用規約」「プライバシーポリシー」から既存の法的画面へ遷移できるようにした。

#### `mobile/app/(auth)/signup.tsx`
- Welcomeで同意済みの状態からメール登録へ進んだ場合、同意チェックを引き継いで表示するようにした。
- 直接メール登録画面に入った場合は、従来通り登録前に同意チェックが必要な状態を維持した。

### 影響範囲

- iOS版Welcome画面
- iOS版ログイン画面のロゴ表示
- iOS版メール新規登録画面
- Apple登録前の同意チェック

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、Welcome画面のロゴが現在のアプリアイコンになっていることを確認
- iOS Previewで、Welcome初期表示内に登録ボタン群とログイン導線が収まることを確認
- iOS Previewで、同意チェック前にApple/メール登録へ進めないことを確認

### 関連ファイル

- `mobile/src/components/MegrumLogo.tsx`
- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/signup.tsx`

### セルフレビュー結果

- ✅ 古いテキストロゴを現在のアプリアイコンへ差し替えた
- ✅ Welcome画面の余白を詰め、ログイン導線が初期表示に入りやすい構成にした
- ✅ 登録前の利用規約・プライバシーポリシー同意チェックを追加した
- ✅ 法的文書本文の変更はないため `notes/17_legal_alignment.md` の更新は不要
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.38：めぐり演出の解放マップを本体マップへ統一

### 背景・問題意識

オーナーから、めぐり演出中の新しいエリア解放表示で、`▼` が出る前後に白いパネルの縦幅が変わらないようにしたいという指示があった。また、この画面に出る都道府県マップを、めぐりマップ本体の新しいブロック地図に合わせたいという要望があった。

### 変更内容

#### `mobile/src/data/japanPrefectures.ts`
- めぐりマップ本体で使っていた47都道府県ブロック地図の座標・サイズ・地域カラーを共通データとして移動した。
- `MEGURI_MAP_TILES`、`MEGURI_MAP_REGION_COLORS`、マップサイズ、タイルサイズをエクスポートし、演出画面とマップ画面で同じ配置を参照できるようにした。

#### `mobile/app/meguri-map.tsx`
- ローカルに持っていたマップ座標定義を削除し、共通データを参照する構成へ変更した。
- 表示内容と現在の見た目は維持したまま、演出側とデータを共有できるようにした。

#### `mobile/app/meguri-intro.tsx`
- エリア解放演出内の都道府県マップを、旧略字グリッドから、めぐりマップ本体と同じ47都道府県ブロック地図へ変更した。
- 解放済み県は地域色、未解放県はグレー、今回解放された県は点滅グローと拡大で目立つようにした。
- `▼` は表示前も透明状態でスペースを確保し、表示前後で白いパネルの高さが変わらないようにした。

### 影響範囲

- iOS版めぐり演出
- 新しいエリア解放演出
- iOS版めぐりマップ
- 都道府県ブロック地図の共通データ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 座標レビューで47都道府県が表示され、タイル同士の重なりがないことを確認
- iOS Previewで、解放演出の `▼` 表示前後に白いパネルの高さが変わらないことを確認
- iOS Previewで、解放演出内の地図がめぐりマップ本体と同じブロック配置になっていることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/app/meguri-map.tsx`
- `mobile/src/data/japanPrefectures.ts`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 解放演出の `▼` 用スペースを常時確保した
- ✅ 演出内マップとめぐりマップ本体で同じ座標データを参照するようにした
- ✅ 47都道府県のタイル数と重なりなしを確認した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.37：左ドロワー通知遷移を即時実行へ修正

### 背景・問題意識

オーナーから、スクショで示された左ドロワー内の「通知」ボタンを押しても通知一覧に遷移しないと再指摘があった。前回は `/notifications` の入口不足として扱ったが、実際には左ドロワーの項目押下時に「ドロワーを閉じ終わってから遷移する」共通処理があり、実機上で閉じアニメーション完了コールバックに依存すると遷移が走らない可能性があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- 左ドロワーの共通遷移処理を、先に `router.push` で遷移を確定し、その後ドロワーを閉じる順序へ変更した。
- 左ドロワーの「通知」は、隠しタブ側の通知一覧を明示的に開くため `/(tabs)/notifications` へ遷移するようにした。
- プロフィール、プロフィール編集、推し設定、スケジュール等の他ドロワー項目も、閉じアニメーション完了待ちに依存しない挙動へ揃えた。

### 影響範囲

- iOS版左ドロワー
- 左ドロワー内の各メニュー遷移
- 通知一覧画面への遷移

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、左ドロワー内の「通知」を押すと通知一覧へ遷移することを確認

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ スクショで示された左ドロワーの通知項目を対象に修正した
- ✅ ドロワーを閉じるアニメーション完了に遷移を依存させないようにした
- ✅ 通知一覧は `/(tabs)/notifications` を明示して開くようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.36：めぐりマップの北陸・近畿配置を再調整

### 背景・問題意識

オーナーから、めぐりマップの都道府県ブロックについて、北陸・東北・近畿の位置関係をより分かりやすくしたいという指示があった。特に、石川・福井を下げること、岐阜を1マス化すること、大阪・京都・和歌山・奈良・兵庫の関係を整えることが求められた。

### 変更内容

#### `mobile/app/meguri-map.tsx`
- 石川と福井をそれぞれ2マス分下へ移動した。
- 岐阜を縦長ブロックから通常の1マスブロックに変更した。
- 新潟を1マス分下げ、長野・山梨・静岡の縦列も重なりが出ないように整理した。
- 北海道・東北ブロックは、福島を含めて全体を1マス分下へ移動した。
- 大阪を2マス上へ移動し、その上に京都を配置した。
- 和歌山を横長ブロックから1マスブロックに変更し、奈良の横に配置した。
- 兵庫を鳥取・岡山の右側の近畿入口として見える位置へ移動した。

### 影響範囲

- iOS版めぐりマップ
- 都道府県ブロック地図の見え方

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- 座標レビューで47都道府県が表示され、タイル同士の重なりがないことを確認
- iOS Previewで、北陸・東北・近畿の配置が指定に近づいていることを確認

### 関連ファイル

- `mobile/app/meguri-map.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 47都道府県のタイル数を維持した
- ✅ タイル同士の重なりがないことを座標レビューで確認した
- ✅ 和歌山と岐阜を1マス化した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.35：通知ドロワー導線を専用ルート化

### 背景・問題意識

オーナーから、左ドロワーの「通知」ボタンを押しても通知一覧へ遷移しないという指摘があった。通知一覧画面自体は隠しタブ配下に存在していたが、ドロワーは `/notifications` へ遷移しており、プロフィール導線と同様に公開ルート側で明示的に受ける必要があった。

### 変更内容

#### `mobile/app/notifications.tsx`
- ルート直下に通知一覧用の `/notifications` ルートを追加した。
- 実装は既存の `mobile/app/(tabs)/notifications.tsx` を再利用し、画面ロジックや表示内容は重複させない構成にした。
- 左ドロワーの既存遷移先 `/notifications` がそのまま通知一覧へ解決されるようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 左ドロワーの通知導線は、隠しタブ直行ではなく `/notifications` 専用ルートで受ける方針を追記した。

### 影響範囲

- iOS版左ドロワー
- 通知一覧画面への遷移

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、左ドロワーの「通知」を押すと通知一覧へ遷移することを確認

### 関連ファイル

- `mobile/app/notifications.tsx`
- `mobile/app/(tabs)/notifications.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 通知一覧の既存実装を再利用し、重複画面を作らない構成にした
- ✅ 左ドロワーの既存 `/notifications` 遷移先を明示的に解決できるようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.34：めぐりマップ解放状態とレター導線を調整

### 背景・問題意識

オーナーから、めぐりマップは良くなっているが、まだ解放していないエリアはグレーアウトしたいという要望があった。また、めぐりマップ画面上部の説明書きは不要であり、めぐりホーム最上部にはレター導線を置き、レターが届いている時は目立たせ、届いていない時でも送りたくなる導線にしたいという指示があった。

### 変更内容

#### `mobile/app/meguri-map.tsx`
- 未解放の都道府県ブロックを地域色ではなくグレー表示に変更した。
- 未解放県の県名も薄いインク色にし、解放済み県との視覚差を強めた。
- めぐりマップ上部の説明文と `RouteHeader` の補足文を削除した。
- 解放済み県の色分け、回数バッジ、47都道府県の縦長配置は維持した。

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホーム最上部にレター導線カードを追加した。
- 未開封レターがある場合は、ピンク系の目立つカードで `レターが届いています` と未開封数を表示するようにした。
- 未開封レターがない場合も、`めぐりあった人へ、ひとことを` としてレターを書きたくなる導線を表示するようにした。
- レター導線は `/meguri-letters` へ遷移する。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりマップの未解放県はグレーアウトする方針と、めぐりホーム最上部にレター導線を置く方針を追記した。

### 影響範囲

- iOS版めぐりマップ
- iOS版めぐりホーム
- すれ違いレター画面への導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、未解放県がグレー表示になることを確認
- iOS Previewで、めぐりマップ上部の説明文が消えていることを確認
- iOS Previewで、めぐりホーム最上部にレター導線が表示されることを確認

### 関連ファイル

- `mobile/app/meguri-map.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 未解放県をグレーアウトし、解放済み県だけ地域色にした
- ✅ めぐりマップ上部の説明文を削除した
- ✅ めぐりホーム最上部にレター導線を追加した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.33：めぐりホーム吹き出し位置を修正

### 背景・問題意識

オーナーから、めぐりホームの吹き出しが3Dキャラクターのいる枠の外に出ていて位置関係が不自然であること、吹き出し内のユーザーネームは不要であること、また「X人とめぐりあいました！」の紫パネルが下にあり上部に空白ができていることを指摘された。今日のめぐりパネルは、数字・3D住人・セリフがひとつの演出としてまとまって見える必要がある。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- 吹き出しを3Dキャラクター表示枠の外から、3D枠内のオーバーレイへ移動した。
- 吹き出し内の `@ユーザーID さん` 表示を削除し、セリフ本文だけを表示するようにした。
- 吹き出しのしっぽを上向きにし、3Dキャラクター側を指す見え方へ変更した。
- めぐりホームの本文スクロールで自動インセットを使わないようにし、固定ヘッダー用の余白が重なってカード上部に大きな空白が出ないようにした。
- 今日のめぐりパネルの高さを詰め、3D枠の外に余分な吹き出し領域を持たない構成にした。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりホームの吹き出しは3D住人枠内に収め、ユーザーネームではなくひとこと本文を見せる方針を追記した。

### 影響範囲

- iOS版めぐりホーム
- 今日のめぐりパネル内の3D住人表示と吹き出し
- 固定ヘッダー下の初期余白

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、吹き出しが3Dキャラクター枠内に収まることを確認
- iOS Previewで、吹き出しにユーザーネームが表示されないことを確認
- iOS Previewで、今日のめぐりパネル上部に大きな空白が出ないことを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 吹き出しを3D住人枠の中へ移動した
- ✅ 吹き出し内のユーザーネーム表示を削除した
- ✅ 自動インセット由来の上部余白を抑えた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.32：めぐりマップを横スクロールなしへ

### 背景・問題意識

オーナーから、めぐりマップが横にスクロールしないと全体を見られないのはダメで、日本地図が少し縦長になってもよいので1画面幅に収めたいという指示があった。前回の横長ブロック地図は添付画像には近かったが、スマホ操作では全体像を一目で把握できず、めぐりマップとしての達成感が弱かった。

### 変更内容

#### `mobile/app/meguri-map.tsx`
- めぐりマップから横スクロール用 `ScrollView` を削除した。
- 都道府県ブロックの列数を減らし、全体を縦長の日本地図レイアウトへ再配置した。
- 47都道府県のフル表記と地域色分けは維持した。
- 端末幅が狭い場合も横にはみ出さないよう、地図全体を画面幅に合わせて自動縮小するようにした。
- 回数バッジ、薄いガイド線、解放済み県の強調表示は維持した。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりマップは横スクロールなしで1画面幅に収め、必要なら縦長配置にする方針を追記した。

### 影響範囲

- iOS版めぐりマップ画面
- めぐりマップの47都道府県ブロック配置

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐりマップが横スクロールなしで画面幅内に収まることを確認
- iOS Previewで、47都道府県がすべて表示されることを確認

### 関連ファイル

- `mobile/app/meguri-map.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 横スクロール表示を削除した
- ✅ 47都道府県を縦長ブロック地図として画面幅内に収めた
- ✅ 狭い端末幅でも地図全体が自動縮小される
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.31：自分プロフィール導線を専用ルート化

### 背景・問題意識

オーナーから、左ドロワーの「プロフィール」を押してもプロフィール画面に遷移しないという指摘が再度あった。自分プロフィール画面自体は `mobile/app/(tabs)/profile.tsx` に存在していたが、隠しタブとして置いた画面へドロワーから遷移する構造が不安定だった。ユーザー視点では「プロフィール画面がない」ように見えるため、ドロワーから確実に開ける専用ルートが必要だった。

### 変更内容

#### `mobile/app/me.tsx`
- 自分プロフィール画面を開くための明示ルート `/me` を追加した。
- 既存の自分プロフィール画面 `mobile/app/(tabs)/profile.tsx` を再利用し、画面実装を重複させない構成にした。

#### `mobile/app/(tabs)/_layout.tsx`
- 左ドロワーの `プロフィール` 押下先を `/(tabs)/profile` から `/me` へ変更した。
- ドロワー内メニューの遷移処理を、ドロワーを閉じ切ってから遷移する方式へ変更した。
- 背景タップやスワイプ終了時のドロワー閉じ処理は既存挙動を維持した。

#### `notes/21_oshi_encounter_strategy.md`
- 自分プロフィールは隠しタブ直行ではなく、ドロワーから `/me` を開く方針を追記した。

### 影響範囲

- iOS版の左ドロワー
- 自分プロフィール画面への導線
- ドロワー内メニュー全般の遷移タイミング

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、左ドロワーの `プロフィール` から自分プロフィール画面へ遷移することを確認
- iOS Previewで、`プロフィール編集` など他のドロワーメニューも閉じた後に遷移することを確認

### 関連ファイル

- `mobile/app/me.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 自分プロフィール画面は既存実装を再利用し、`/me` から確実に開けるようにした
- ✅ 隠しタブへの直接遷移に依存しない導線へ変更した
- ✅ ドロワーを閉じ切ってから遷移するため、押下後の見え方が安定する
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.30：めぐりホームに固定設定と3D住人列

### 背景・問題意識

オーナーから、めぐりホーム右上の設定アイコンは固定ヘッダーにし、「今日のめぐり X人と出会いました！」のパネルには巡り会った人たちの3Dキャラクターが並ぶようにしたいという指示があった。めぐりホームはスクロールしても設定へすぐ戻れることと、今日の出会いが数字だけではなく住人の存在として見えることを優先する。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりホームを固定ヘッダー + スクロール本文の構造へ変更した。
- 右上の設定アイコンをスクロール領域から外し、画面右上に固定表示されるようにした。
- 今日のめぐりパネル内に、巡り会った人たちが横並びする3Dシーンを追加した。
- 3D初期化に失敗した場合は、既存の軽量キャラクター列へフォールバックするようにした。
- 表示中の相手プレビューは、3D列に合わせてゆっくり切り替わるようにした。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 既存のめぐり演出3Dシーンに `presentation="home"` を追加した。
- ホーム表示では自分キャラを非表示にし、巡り会った人たちだけを横一列に自然な待機モーションで並べるようにした。
- ホーム表示では `3D MEGURI` ラベルを出さず、パネル内の一部として馴染ませた。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりホームの今日パネルは、数字だけでなく3D住人列で今日の出会いを見せる方針を追記した。

### 影響範囲

- iOS版めぐりホーム
- めぐり設定モーダルへの導線
- 既存めぐり3Dシーンのホーム利用

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐりホームをスクロールしても右上設定アイコンが残ることを確認
- iOS Previewで、今日のめぐりパネル内に巡り会った人の3Dキャラクター列が表示されることを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 設定アイコンをスクロール本文から分離し、固定ヘッダーにした
- ✅ 今日のめぐりパネルに本物の3D住人列を表示する経路を追加した
- ✅ 3D不可環境向けのフォールバックを維持した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.29：めぐりマップをブロック地図へ変更

### 背景・問題意識

オーナーから、めぐりマップは添付画像のような都道府県ブロック地図を再現したいという指示があった。これまでの省略記号ベースの小さなグリッドでは、日本地図としての視認性と「47都道府県を集めていく」楽しさが弱かったため、地域ごとの色分けとフル県名表示を優先したレイアウトへ変更する。

### 変更内容

#### `mobile/app/meguri-map.tsx`
- めぐりマップ本体を、省略名グリッドから47都道府県のフル表記ブロック地図へ置き換えた。
- 添付画像に寄せて、北海道を大きな青紫ブロック、東北を水色、関東を緑、中部をシアン、関西を黄緑、中国を黄色、四国をオレンジ、九州・沖縄をピンクで配置した。
- 沖縄と本州側の距離感を出すため、白背景上に薄いガイド線を追加した。
- 既にめぐりあった都道府県には回数バッジを出し、未解放県も含めて47件すべてを一覧できるようにした。
- モバイル画面で文字が潰れないよう、地図は横スクロールできる大きめのキャンバスにした。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりマップの基準表現を、添付画像に近い都道府県ブロック地図へ変更する方針を追記した。

### 影響範囲

- iOS版めぐりマップ画面
- めぐり演出中のエリア開放演出で参照するマップ表現方針

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐりマップに47都道府県のブロック地図が表示されることを確認

### 関連ファイル

- `mobile/app/meguri-map.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 47都道府県をすべてフル表記で表示する構成にした
- ✅ 添付画像に近い地域色とブロック配置へ寄せた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.28：ドロワーのプロフィール導線を修正

### 背景・問題意識

オーナーから、左ドロワーの「プロフィール」を押しても自分のプロフィール画面へ遷移せず、ホーム画面に戻ってしまうという指摘があった。プロフィール画面はタブグループ内の非表示タブとして存在しているため、通常の `/profile` ではなくタブグループを明示したルートへ遷移させる必要があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- 左ドロワーの `プロフィール` 押下時の遷移先を `/profile` から `/(tabs)/profile` に変更した。
- 既存のドロワー開閉挙動と、他のメニュー項目の遷移先は維持した。

### 影響範囲

- iOS版の左端スワイプドロワー
- 自分のプロフィール画面への導線

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS Previewで、左ドロワーの `プロフィール` から自分のプロフィール画面へ遷移することを確認

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ ドロワーのプロフィール遷移先をタブグループ内プロフィールへ明示した
- ✅ 他のドロワーメニューには影響を与えていない
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.27：めぐりホームを今日のパネル中心へ整理

### 背景・問題意識

オーナーから、めぐりホーム上部の `MEGRUM` 表記、メール/Plusアイコン、大きい「めぐり」見出しを削除し、今日のめぐりパネル周辺の導線を整理したいという要望があった。あわせて、パネル下のバー・広場/レター/演出ボタン、下部の「今日のめぐりを見る」CTA、最下部の説明文を削除し、設定は右上アイコンから開けるようにしたいという指示があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- 画面上部の `MEGRUM`、メールアイコン、Plusアイコン、大きい「めぐり」タイトルを削除した。
- 右上に設定アイコンだけを置くヘッダーへ変更した。
- 今日のめぐりパネル下部のドットバー、`広場` / `レター` / `演出へ` ボタンを削除した。
- 今日のめぐりパネル右上に `演出をもう一度見る` ボタンを追加し、`/meguri-intro` へ遷移するようにした。
- パネル下の `今日のめぐりを見る` CTAを削除した。
- 最下部の `広場・マップ・実績・レポートは、それぞれの入口から見に行けます。` 説明文を削除した。
- 右上設定アイコンから開く `めぐり設定` モーダルを追加した。
- 設定モーダルに `アバター編集`、`プロフィール編集（名前、めぐりで別れ際のメッセージ）`、`めぐり機能 ON/OFF` を並べた。
- `めぐり機能 ON/OFF` はプレビュー上でトグルできるローカル状態にした。

#### `mobile/src/components/IconSymbol.tsx`
- 設定アイコン用に `settings-outline` を追加した。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりホームは、今日のめぐりパネル中心で、右上設定からめぐり固有設定を開く方針を追記した。

### 影響範囲

- iOS版のめぐりタブホーム
- めぐり設定モーダル
- アイコン表示ヘルパー

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、上部の `MEGRUM` / メール / Plus / 大きい「めぐり」見出しが出ないことを確認
- iOS Previewで、今日のめぐりパネル右上の `演出をもう一度見る` から演出へ進めることを確認
- iOS Previewで、右上設定アイコンから設定一覧が開き、ON/OFFトグルが動くことを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/src/components/IconSymbol.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 指定された上部表記とアイコンを削除した
- ✅ パネル下部バーと演出CTAを削除し、パネル右上へ再配置した
- ✅ 指定の設定一覧を右上アイコンから開けるようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.26：めぐり3D演出を3つ前へ戻す

### 背景・問題意識

オーナーから、直近の入場順・影・服まわりの修正で見え方がおかしくなっているため、3つ前のバージョンへ戻したいという指示があった。対象は `iter162.23` から `iter162.25` で入れた服上下分割、会話前歩行の減速、隊列追い抜き対策、影分離などの調整であり、安定していた `iter162.22` 相当へ戻す。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- `approaching` から会話へ入る待ち時間を `iter162.22` 相当の短い値へ戻した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `active` / `farewell` の停止位置・スケール・速度を `iter162.22` 相当へ戻した。
- 冒頭入場の後続ディレイ、アクティブ中の隊列インデックス固定、`approaching` 中の `intro_queue` 扱いを撤回した。
- 影をキャラクターグループから分離する変更を撤回し、元のキャラクター内シャドウに戻した。
- 服の上下分割と単色服調整を撤回し、元の1枚服パネル構成に戻した。
- 別れ際の手振り角度を `iter162.22` 相当へ戻した。

#### `notes/21_oshi_encounter_strategy.md`
- `iter162.23` から `iter162.25` の演出調整を撤回し、`iter162.22` 相当へ戻したことを追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の入場、会話前歩行、影、服、別れ際手振り

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、直近3回の調整前の見え方に戻っていることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 直近3回の3D演出調整を撤回した
- ✅ `iter162.22` 相当の入場・影・服・手振り構成に戻した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.25：めぐり入場隊列と影を根本修正

### 背景・問題意識

オーナーから、前回修正後も冒頭入場で一人目より後続が前に出て見える問題が残っていると指摘があった。原因は、`approaching` に入った瞬間に一人目だけが `active` としてゆっくり前へ出る一方、二人目以降は通常 `queue` として高速に前の隊列スロットへ詰めていたことだった。また、影はキャラクターグループ内の子要素として補正していたため、移動中の見え方がまだ安定しきっていなかった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `approaching` 中の後続キャラは通常 `queue` ではなく `intro_queue` のまま扱い、高速に前へ詰めないようにした。
- アクティブな一人目がいる間は、後続キャラの表示インデックスを1つ後ろに固定し、二人目が一人目のスロットへ移動しないようにした。
- 先頭キャラの入場速度をさらに上げ、後続キャラの追従ディレイを強めた。
- 影をキャラクターグループの子要素から分離し、広場ワールド上の地面オブジェクトとして独立更新するようにした。
- 移動中の影は地面の固定位置に置き、上下バウンドや体の左右揺れに連動して変形しないようにした。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- 冒頭入場から一人目の会話前歩行までの隊列制御
- めぐり住人の影表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、`10人にめぐりあいました！` 後に一人目が先行し、二人目以降が一人目を追い抜かないことを確認
- iOS Previewで、会話前歩行中の影が不自然に浮いたり傾いたりしないことを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ `approaching` 中の後続高速詰めを止めた
- ✅ アクティブ中は後続を一つ後ろの隊列位置に固定した
- ✅ 影をキャラクター本体から分離して地面基準で更新するようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.24：めぐり入場順・影・服表示を再調整

### 背景・問題意識

オーナーから、冒頭で一人目と後続が登場する時に、一人目だけ到着が遅く見え、二人目以降が一瞬追い抜いているように見えるという指摘があった。また、自分の番になったキャラクターがユーザー前へ来る時に影が不自然に見えること、服の柄テクスチャがうまく見えていないためテクスチャを外したいという要望があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `intro_queue` のスポーン位置と速度を調整し、一人目が先に前へ出て後続が追う順番にした。
- 後続キャラには短い追従ディレイを入れ、冒頭入場で先頭を追い抜いて見えないようにした。
- キャラクターの影をパーツとして保持し、歩行バウンド中も地面に貼り付くように補正した。
- 服のプロシージャル柄テクスチャを削除し、上半身/下半身の分割は残したまま単色パーツへ戻した。

#### `notes/21_oshi_encounter_strategy.md`
- 服は当面テクスチャなし、冒頭入場は先頭優先、影は地面に固定する方針を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の冒頭入場、会話前歩行、影、服表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、一人目が先に前へ出て、後続が後ろから追うことを確認
- iOS Previewで、会話前歩行中に影が浮いたり歪んだりして見えないことを確認
- iOS Previewで、服の柄テクスチャが消え、上下分割の単色服になっていることを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 冒頭入場の先頭優先と後続追従を調整した
- ✅ 影がキャラの上下揺れに付いて浮かないよう補正した
- ✅ 服テクスチャを削除し、単色上下パーツへ戻した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.23：めぐり服上下分割と歩行間合い調整

### 背景・問題意識

オーナーから、3Dキャラクターの服が1枚の服装テクスチャを上から貼ったように見えるため、上半身と下半身を分けて別デザインのテクスチャにしたいという要望があった。また、別れ際の手振りが下向きに見えること、自分の番になった相手が一瞬で前に来てしまい、ユーザーより手前で大きく見えることも指摘された。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- キャラクターの服を、上半身エリアと下半身エリアの2パートに分割した。
- 上半身は斜めチェック、下半身はストライプ/裾ラインのプロシージャルテクスチャを貼る構成にした。
- 別れ際の `farewell` ロールで、右腕を横上へ上げて振る角度に調整した。
- 会話前に前へ出てくる相手キャラの停止位置を自分キャラと同じ奥行きに揃え、スケールを抑えて手前に出すぎないようにした。
- `active` ロールの移動速度と歩行テンポを落とし、とことこ歩いてくる時間が見えるようにした。

#### `mobile/app/meguri-intro.tsx`
- `approaching` フェーズから会話へ入るまでの待ち時間を伸ばし、相手がユーザー前へ歩いてくる尺を確保した。

#### `notes/21_oshi_encounter_strategy.md`
- 服の上下分割、横上のバイバイ、会話前歩行の間合いと停止位置の方針を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の服テクスチャ表現
- 相手キャラクターの会話前入場と別れ際モーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、服が上半身/下半身の2エリアに分かれて見えることを確認
- iOS Previewで、別れ際の手振りが横上のバイバイに見えることを確認
- iOS Previewで、相手キャラがゆっくり歩いてきて、自分キャラと同じ奥行きで止まることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 服を上半身/下半身の2エリアに分けた
- ✅ 上半身/下半身で異なるプロシージャルテクスチャを使った
- ✅ バイバイ時の腕を横上に上げる方向へ調整した
- ✅ 会話前の歩行時間を伸ばし、相手の停止位置と大きさをユーザーと揃えた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.22：めぐり表情・実績解除・別れ際を強化

### 背景・問題意識

オーナーから、冒頭サマリー文言を「X人にめぐりあいました！」に戻したいこと、立っているキャラクターが完全停止して見える不自然さ、エリア開放演出の文言と見せ方、別れ際の手振りとセリフ、会話中のニコニコ目について要望があった。めぐり演出は説明よりもキャラクターの反応と達成感で見せる必要がある。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 冒頭サマリーを `X人がきました！` から `X人にめぐりあいました！` に戻した。
- 会話の最後に、相手キャラクターが話す別れ際のひとことを追加した。
- 別れ際の文言を複数パターンから選ぶようにした。
- エリア開放演出を `AREA OPEN` ではなく `実績解除` に変更し、タイトルを `{都道府県}の人に初遭遇！` にした。
- エリア開放演出の補足説明文を削除した。
- エリア開放演出の表示直後1秒間は `▼` を表示せず、タップしても次へ進まないようにした。
- エリア開放マップで新しく解放された都道府県を濃い色・拡大・グローで強調した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 会話中の話者は、顔テクスチャ上の目をニコニコ目に切り替えるようにした。
- 別れ際の相手キャラクターは、ニコニコ目のまま手を振る `farewell` ロールにした。
- 待機中のキャラクターにも呼吸・小さな体/頭/腕/しっぽの揺れを入れ、完全停止して見えないようにした。
- 顔テクスチャの目をベースから分離し、通常目・ニコニコ目・口パクを同じテクスチャ内で描き替えるようにした。

#### `mobile/src/data/japanPrefectures.ts`
- 正規化済み都道府県名から `東京都` / `大阪府` / `北海道` / `神奈川県` のような表示名を返す `displayPrefectureName` を追加した。

#### `notes/21_oshi_encounter_strategy.md`
- 冒頭サマリー、実績解除演出、別れ際の手振り、話者のニコニコ目、待機時の自然な揺れを追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の顔テクスチャ・表情・待機モーション
- 新エリア開放演出
- 会話完了から門へ向かう前の別れ際演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、冒頭サマリーが `10人にめぐりあいました！` と表示されることを確認
- iOS Previewで、話者の目がニコニコになり、別れ際に相手が手を振ってから門へ向かうことを確認
- iOS Previewで、エリア開放演出が `実績解除` / `{都道府県}の人に初遭遇！` になり、1秒後まで `▼` が出ないことを確認
- iOS Previewで、待機中のキャラクターが自然に小さく揺れることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/src/data/japanPrefectures.ts`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 冒頭サマリー文言を戻した
- ✅ エリア開放演出を実績解除の見せ方に変更し、即スキップを防いだ
- ✅ 新規解放都道府県をマップ上でより強く目立たせた
- ✅ 会話中の話者をニコニコ目にし、別れ際は手振りを追加した
- ✅ 待機中のキャラクターに自然な揺れを追加した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.21：めぐり説明ヘッダーと開始ボタンを削除

### 背景・問題意識

オーナーから、演出中の「こちらに向かって歩いてきています」「TODAY 10人が広場に到着しました」「TODAY 広場の門へ向かっています」といった表記は不要であり、「一人ずつ話す」ボタンも不要という指摘があった。人数サマリーを押すと、一人目が自然に歩いてきて会話が始まるほうが、演出として途切れにくい。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 演出中の `TODAY` ヘッダー表示を出さないようにした。
- `summary` 中の下部プライマリボタンを表示対象から外し、「一人ずつ話す」ボタンを削除した。
- 冒頭カメラ後は、人数サマリー表示自体をタップできる状態にし、タップすると一人目の `approaching` へ進むようにした。
- 人数サマリー文言を `X人とめぐりあいました！` から `X人がきました！` に変更した。

#### `notes/21_oshi_encounter_strategy.md`
- 説明ヘッダーを出さず、人数サマリーを開始入口にする方針を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- 冒頭サマリーから一人目の会話へ入る操作導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、演出中に `TODAY` ヘッダーや「一人ずつ話す」ボタンが出ないことを確認
- iOS Previewで、`10人がきました！` をタップすると一人目が歩いてきて会話が始まることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 説明ヘッダーを表示しないようにした
- ✅ 「一人ずつ話す」ボタンを削除した
- ✅ 人数サマリーをタップ開始の入口にした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.20：めぐり冒頭を縦下降カメラと同時入場へ調整

### 背景・問題意識

オーナーから、演出冒頭のカメラは斜めに寄るのではなく、上から下へ降りてくる感じにしたいという指摘があった。また、カメラがゆっくり降りている間に、右奥からめぐりあった人たちがとことこ歩いてくるイメージにしたいという要望があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 冒頭の `camera` フェーズを長めにし、上空から降りる動きが見える時間を確保した。
- 2Dフォールバックでも `camera` フェーズ中は来訪者を隠さず、導入中から列が見える方向に寄せた。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 冒頭カメラの開始位置と目標位置の横移動を抑え、Y方向中心にゆっくり下降する軌道へ変更した。
- `camera` フェーズ中のカメラ追従速度を落とし、降りてくる動きが急に終わらないようにした。
- 導入中の来訪者を非表示にせず、右奥のスポーン位置から待機列へゆっくり歩く `intro_queue` ロールを追加した。
- `splash` / `walking` 中も来訪者が背景で歩き続け、人数サマリー後に列が整う流れへ寄せた。

#### `notes/21_oshi_encounter_strategy.md`
- 冒頭カメラは縦方向に降り、同時に右奥から来訪者が歩いてくる方針を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり演出冒頭のカメラワークと来訪者入場テンポ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、演出冒頭のカメラが上空から縦方向にゆっくり降りることを確認
- iOS Previewで、カメラ下降中から右奥の来訪者がゆっくり歩き始めることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 冒頭カメラの横方向移動を抑え、上から下へ降りる見え方に寄せた
- ✅ カメラ下降中から来訪者が右奥から歩き始める
- ✅ 導入用のゆっくりした歩行ロールを追加し、通常待機列への移動と分けた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.19：めぐりマップを47都道府県表示へ統一

### 背景・問題意識

オーナーから、めぐりマップが47都道府県を表示できておらず、解放したところだけ色がつく見え方にしたいという指摘があった。会話中の新エリア開放演出でも同じ地図表現にし、マップ本体と演出の認知をそろえる必要があった。

### 変更内容

#### `mobile/src/data/japanPrefectures.ts`
- 47都道府県すべてのタイル表示用データを追加した。
- 都道府県名の表記を正規化する `normalizePrefectureName` を追加し、「東京都」「大阪府」などのプロフィール値でもめぐりマップ側の表記に合わせられるようにした。

#### `mobile/app/meguri-map.tsx`
- 22件だけだったマップタイルを、共通データに基づく47都道府県表示へ変更した。
- 未解放の都道府県は薄いグレー、めぐり済みの都道府県は色付きタイルと回数バッジで表示するようにした。
- サマリー文言を `解放済み / 47 都道府県` の見え方に変更した。

#### `mobile/app/meguri-intro.tsx`
- 会話中の新エリア開放演出でも、抽象的な島とピンではなく47都道府県タイルを表示するようにした。
- すでに解放済みの都道府県は色付き、新しく解放された都道府県は点滅・拡大して灯るようにした。
- `kind: "area"` の判定時に都道府県名を正規化し、プロフィール値の表記揺れに強くした。

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりトップのマップショートカット文言を `47 都道府県` に変更した。

#### `notes/21_oshi_encounter_strategy.md`
- めぐりマップ本体とエリア開放演出はどちらも47都道府県を先に表示し、解放済みだけ色をつける方針を追記した。

### 影響範囲

- iOS版の `meguri-map`
- iOS版の `meguri-intro` 新エリア開放演出
- めぐりトップのマップショートカット文言

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐりマップに47都道府県のタイルが表示され、解放済みだけ色付きになることを確認
- iOS Previewで、会話中の新エリア開放演出でも47都道府県が表示され、新しく解放された都道府県が点滅することを確認

### 関連ファイル

- `mobile/src/data/japanPrefectures.ts`
- `mobile/app/meguri-map.tsx`
- `mobile/app/meguri-intro.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 47都道府県すべてを共通データとして定義した
- ✅ めぐりマップ本体は未解放グレー、解放済み色付きで表示する
- ✅ 会話中の新エリア開放演出も同じ47都道府県タイル表現へ統一した
- ✅ プロフィール値が `東京都` などでも `東京` として扱えるよう正規化した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.18：めぐり都道府県セリフを短く調整

### 背景・問題意識

オーナーから、会話中の都道府県セリフを「〇〇の方で推し活をしています」ではなく、「〇〇からきました！」にしたいという要望があった。3D住人の自己紹介としては、説明調の文章よりも短くポップな挨拶のほうがテンポに合う。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 相手の都道府県セリフを `${partner.area}のほうで推し活しています。` から `${partner.area}からきました！` に変更した。
- `kind: "area"` は維持し、新エリア開放マップ演出の発火位置は変えないようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 会話例と文言方針を「〇〇からきました！」へ更新した。
- 「からきました！」は公開プロフィール上の所属都道府県を使う演出上の挨拶であり、現在地や正確な移動元を示すものではないと明記した。

### 影響範囲

- iOS版の `meguri-intro` 会話演出
- 新エリア開放演出直前の都道府県セリフ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、相手の都道府県セリフが「千葉からきました！」のように表示され、その後の新エリア開放演出が引き続き動くことを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 都道府県セリフを短く親しみやすい文言へ変更した
- ✅ `kind: "area"` を維持し、新エリア開放演出の判定は変えていない
- ✅ 安全設計として、現在地や正確な移動元を示す文言ではないことを仕様メモに残した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.17：めぐり冒頭カメラ導入と顔拡大

### 背景・問題意識

オーナーから、演出画面に入った直後にすぐ「X人とめぐりあいました！」を出すのではなく、まず3D世界へカメラが上から降りて、自分キャラが広場の門前に立っているところを見せたいという要望があった。また、顔テクスチャが頭の面積に対して小さく見えるため、表情が読み取りづらい問題もあった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 冒頭フェーズを `camera → splash → walking → ready` に変更し、人数サマリー表示前に3D世界の導入時間を挟むようにした。
- 2Dフォールバックでも `camera` フェーズ中は来訪者の列を出さず、人数サマリー前の間を保つようにした。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `camera` フェーズを追加し、3Dシーン開始時は上空視点から門前の自分キャラへカメラが降りるようにした。
- 冒頭の `camera` / `splash` 中は自分キャラを門前に立たせ、来訪者はまだ表示しないようにした。
- 顔の曲面メッシュとプロシージャル顔テクスチャの描画範囲を大きくし、頭に対して表情が小さく見えないようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 冒頭カメラ導入と顔テクスチャ拡大の方針を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり演出の冒頭テンポ、カメラワーク、顔テクスチャの見え方

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、演出開始直後に上空から門前の自分キャラへカメラが降り、その後に人数サマリーが表示されることを確認
- iOS Previewで、住人の顔テクスチャが以前より大きく見え、表情が読み取りやすいことを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 人数サマリー前に3D世界へ入るカメラ導入を追加した
- ✅ 導入中は自分キャラが広場の門前に立ち、来訪者列はまだ表示されない
- ✅ 顔曲面とテクスチャ内の顔パーツを拡大し、頭に対して表情が小さく見えにくいようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.16：めぐり会話中に新エリア開放マップ演出を追加

### 背景・問題意識

オーナーから、ひとりひとりの挨拶中に相手が所属都道府県を話したあと、その都道府県が自分にとって新しいエリアだった場合、マップが開いて場所が開放される演出を挟みたいという要望があった。「新しいエリアの人に出会いました！」のような表示と、該当エリアに光がぱっと灯って点滅する演出を会話中に自然にインサートする必要があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 会話行に `kind: "area"` を追加し、都道府県を話す行を判定できるようにした。
- 自分のエリアを初期開放済みとして、会話中に出会った新しい都道府県を `unlockedAreas` で管理するようにした。
- 都道府県行を全文表示した後の次タップで、未開放エリアなら会話を進めず `AreaUnlockOverlay` を表示するようにした。
- マップ演出では、抽象化した日本地図、該当エリアの光るピン、点滅するグロー、「新しいエリアの人に出会いました！」のテキストを表示するようにした。
- マップ演出をタップすると閉じ、元の会話フローの次のセリフへ戻るようにした。
- 同じ都道府県は開放済みとして扱い、演出が重複しないようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 都道府県会話の後に新エリア開放マップ演出を挟む仕様を追記した。

### 影響範囲

- iOS版の `meguri-intro` 会話演出
- めぐり中の都道府県開放・マップ表示演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、新しい都道府県の相手のエリア会話後にマップ演出が挟まることを確認
- iOS Previewで、同じ都道府県ではマップ演出が重複しないことを確認
- iOS Previewで、マップ演出後に会話が次のセリフへ戻ることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 都道府県行の直後にだけ新エリア判定を行うようにした
- ✅ 初期状態で自分のエリアは開放済み扱いにした
- ✅ 新しい都道府県ではマップ上のピンと光が点滅する演出を表示する
- ✅ 同じ都道府県で開放演出が重複しないようにした
- ✅ マップ演出後は元の会話フローへ戻る
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.15：めぐり住人の光を全体マット寄りに調整

### 背景・問題意識

オーナーから、キャラクターに当たる光が反射しているように見え、もう少しキャラクター全体に光が当たる見え方にしたいという指摘があった。ぬいぐるみ風の住人としては、強い一点ライトのハイライトよりも、全身の形と色が均等に読み取れる柔らかいライティングが合っている。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 3Dシーンに `HemisphereLight` を追加し、上からの暖色光と下からの淡い反射光で全体へ光を回すようにした。
- `AmbientLight` を少し強め、キャラクターの暗部が潰れにくいようにした。
- 強い `DirectionalLight` と `PointLight` を弱め、局所的な反射感を抑えた。
- 反対側から弱いフィルライトを追加し、顔や体の片側だけが暗くなりすぎないようにした。
- ぬいぐるみ住人の毛・服・顔・耳内側を `MeshLambertMaterial` に変更し、反射感の少ないマットな見え方へ寄せた。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人のライティング、顔・体・服の質感

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- コードレビューで、キャラクター材質が `MeshLambertMaterial` になっていることを確認
- iOS Previewで、強い反射感が抑えられ、キャラクター全体に柔らかく光が回っていることを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 強い一点ライトを弱め、環境光・半球ライト・弱いキー/フィルライトへ再配分した
- ✅ ぬいぐるみ住人の材質を反射感の少ない `MeshLambertMaterial` へ変更した
- ✅ 顔テクスチャも同じマット寄り材質にし、顔だけ反射・発光して見えにくくした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.14：めぐり曲面顔の表示復旧と退出待ち短縮

### 背景・問題意識

オーナーから、顔テクスチャが見えなくなってしまったこと、またキャラクターが画面外に出てから次へ進むまで少し時間がかかることが指摘された。iter162.13 で顔を曲面化した結果、曲面メッシュの表面向きや深度判定が厳しくなり、顔が描画されにくくなっていた可能性があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 曲面顔マテリアルを `DoubleSide` にし、表面向きで消えないようにした。
- `depthWrite: false` と `alphaTest` を設定し、頭メッシュとの深度干渉や透明部分の描画を安定させた。
- 曲面顔メッシュを頭表面から少し外側へ出し、埋もれやZ-fightingを避けた。

#### `mobile/app/meguri-intro.tsx`
- 退出演出の待機時間を `4300ms` から `3400ms` に短縮し、キャラクターが見えなくなってからの待ちを減らした。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の顔テクスチャ表示
- 会話後の退出から次キャラへ移るテンポ

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- コードレビューで、曲面顔が `DoubleSide` / `depthWrite: false` / 外側オフセットを持つことを確認
- iOS Previewで、顔テクスチャが見え、画面外に出た後の待ちが短くなっていることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 曲面顔メッシュの描画面を `DoubleSide` にした
- ✅ 頭との深度干渉を避けるため `depthWrite: false` と外側オフセットを入れた
- ✅ 退出後の待ち時間を短縮した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.13：めぐり顔テクスチャ曲面化と体型再調整

### 背景・問題意識

オーナーから、顔のテクスチャが顔から離れて張り付いて見え、不自然であると指摘された。また、参照画像のような体型、つまり大きな頭、小さな胴、細く下がる腕、短い脚のシルエットへさらに寄せたいという要望があった。従来の顔は平面テクスチャを頭の前に置いていたため、角度によってシールが浮いたように見える問題があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 顔テクスチャを `PlaneGeometry` から、頭の楕円体前面に沿うカスタム曲面 `BufferGeometry` へ変更した。
- 曲面側にUVを割り当て、既存の顔テクスチャと口パクテクスチャをそのまま頭の表面に沿って表示するようにした。
- 顔テクスチャのマテリアルを `MeshStandardMaterial` にし、周囲の立体と同じライティングに馴染むようにした。
- 頭をさらに大きく、胴を小さく、腕を細く長めに、脚と足を短く小さめに再調整した。
- 服の前面も小さい胴に合わせて縮め、菱形のディテールを追加した。
- 大きくした頭に合わせて、ねこ・うさぎ・くまの耳と毛束位置を上げた。

#### `notes/21_oshi_encounter_strategy.md`
- 顔テクスチャを平面板として置かず、頭の曲面へ沿わせる方針と、参照体型の基本シルエットを追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の顔テクスチャ表示
- めぐり住人の体型・耳・服シルエット

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- コードレビューで、顔が `PlaneGeometry` ではなく `createCurvedFaceGeometry()` を使っていることを確認
- コードレビューで、頭・胴・腕・脚のスケールが参照体型寄りに変更されていることを確認
- iOS Previewで、顔が頭から浮いて見えず、体型が大きい頭・小さい胴に寄っていることを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 顔テクスチャ用の `PlaneGeometry` を廃止し、頭前面に沿う曲面 `BufferGeometry` にした
- ✅ 顔テクスチャと口パクは同じ曲面上で動く
- ✅ `MeshStandardMaterial` に変え、顔だけ不自然に発光した板に見えにくくした
- ✅ 頭を大きく、胴を小さく、腕を細く、脚を短くして参照体型へ寄せた
- ✅ 大きい頭に合わせて耳と毛束の位置を再調整した
- ✅ コードレビューで `PlaneGeometry` が顔用に残っていないことを確認した
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.12：めぐり退出の向きと歩行速度を再調整

### 背景・問題意識

オーナーから、最後に門へ入っていく時のキャラクターの向きが逆になっていること、歩くスピードが早く吸い込まれているように見えること、もっと画面外まで歩いていく感じにしたいという指摘があった。門へ向かう退出は、方向転換、歩行、画面外への抜けが分かる尺にする必要があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 退出演出の尺を `2100ms` から `4300ms` に伸ばし、歩いて抜ける時間を確保した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 退出開始直後の方向転換時間を少し伸ばした。
- 退出時の `rotationY` を進行方向へ向く角度に修正した。
- 退出ターゲットを門の奥さらに画面外側へ移動した。
- 退出時の移動速度と歩行テンポを下げ、吸い込まれる見え方を抑えた。

#### `notes/21_oshi_encounter_strategy.md`
- 退出時は進行方向へ向き、ゆっくり画面外まで歩いて抜ける仕様として追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- 会話完了後の門くぐり・退出モーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、退出時にキャラが門方向を向き、早すぎず、画面外まで歩いて抜けることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 退出時の向きを進行方向へ修正した
- ✅ 退出速度を落とし、歩行テンポもゆっくりにした
- ✅ 退出ターゲットを画面外まで伸ばした
- ✅ 退出演出の尺を伸ばし、吸い込まれる見え方を抑えた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.11：めぐり口パクを口テクスチャ差し替え方式へ修正

### 背景・問題意識

オーナーから、会話中に口はパクパクするようになったが、元の口テクスチャが残ったまま開いた口が重なって見え、気持ち悪いという指摘があった。閉じ口と開き口を別々に重ねるのではなく、同じ口の形が会話に合わせて変化しているように見せる必要があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 顔テクスチャのベースデータから口を外し、口なしの顔を `baseData` として保持するようにした。
- 初期表示時は口なしベースに閉じ口を描くようにした。
- 口パク時は毎回、口なしベースへ戻してから、閉じ口または開き口を描き直すようにした。
- 閉じ口と開き口を `drawMouth` に集約し、既存の笑い口と開いた口が同時に残らないようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 口パクは既存口の上書きではなく、口なしベースから閉じ口・開き口を描き替える仕様として追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の顔テクスチャと口パク表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、会話中に閉じ口と開き口が二重に表示されず、同じ口が開閉して見えることを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 元の笑い口が開いた口の下に残らないようにした
- ✅ 口なしベースから閉じ口・開き口を毎回描き直す方式にした
- ✅ 顔テクスチャ方式を維持し、別メッシュの口パーツは追加していない
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.10：めぐり退出セリフ削除と門くぐり・雲を再調整

### 背景・問題意識

オーナーから、別れ際の「まためぐりあえますように」は不要であり、最後はキャラクターがまず門の方を向いてから、ゆっくり歩いて門をくぐるようにしたいという要望があった。また、空に流れる雲が小さく見えるため、より大きく、画面上部を流れる環境演出にしたいという指摘があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- `exiting` 中の吹き出し表示をやめ、別れ際の追加セリフを出さないようにした。
- 退出中は発話扱いにせず、口パクも発生しないようにした。
- 退出演出の表示時間を延ばし、門へ向かう動きが見える時間を確保した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 住人ランタイムに直近のモーションロールと開始時刻を持たせた。
- 退出開始直後はその場で門の方向へ向きを変え、その後に歩き出すようにした。
- 退出ターゲットを門の奥側へずらし、キャラクターが門をくぐって抜けるようにした。
- 退出時の歩行スピードと歩幅を落とし、ゆっくり歩いている見え方に調整した。
- 雲のサイズを大きくし、Y座標を上げて画面上部の空を流れるようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 別れ際セリフ削除、門の方を向いてからゆっくりくぐる退出、上部に大きく流れる雲を仕様メモに追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- 会話終了後の退出演出
- 3D背景の雲演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、最後の会話後に追加セリフが出ないことを確認
- iOS Previewで、退出時にキャラクターが門の方へ向き、ゆっくり歩いてくぐることを確認
- iOS Previewで、雲が画面上部を大きめに流れることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 別れ際の「まためぐりあえますように」を削除した
- ✅ 退出中の吹き出しと口パクを止めた
- ✅ 退出開始直後に門の方へ向きを変える時間を入れた
- ✅ その後にゆっくり歩いて門をくぐるターゲットへ移動するようにした
- ✅ 雲を大きくし、上部を流れる配置にした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.9：めぐり会話の全文表示タップと話者カメラを追加

### 背景・問題意識

オーナーから、会話本文が一文字ずつ出ている途中でも、タップしたら現在のセリフ全文を表示できるようにしたいという要望があった。また、話し手に合わせて画面視点がゆっくり切り替わり、左のキャラクターが話す時は左側へ、右のキャラクターが話す時は右側へカメラが向くようにしたいという要望があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- 会話中の本文表示途中にタップした場合、次のセリフへ進まず、現在の本文を即時に全文表示するようにした。
- 全文表示後の次のタップで次のセリフへ進むようにした。
- 前のセリフで使った全文表示シグナルが次のセリフへ持ち越されないようにした。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 3Dランタイムにカメラの注視点を保持するようにした。
- 会話中の `speakingId` に合わせて、カメラ位置と注視点を毎フレームゆっくり補間するようにした。
- 自分が話す時は左側へ、相手が話す時は右側へ視点が寄り、会話以外では全体構図へ戻るようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 文字送り途中のタップで全文表示する挙動と、話者に合わせたカメラ寄りの仕様を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- 会話UIのタップ挙動
- 会話中の3Dカメラ演出

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、文字送り中のタップで全文表示され、次タップで次セリフへ進むことを確認
- iOS Previewで、自分/相手の発話に合わせてカメラがゆっくり左右へ寄ることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 文字送り中のタップは次のセリフへ進まず、現在の本文を全文表示するようにした
- ✅ 全文表示後の次タップで次のセリフへ進む
- ✅ 全文表示シグナルが次セリフへ持ち越されないようにした
- ✅ 話者に合わせてカメラがゆっくり左右へ寄る
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.8：めぐり顔テクスチャの上下反転を修正

### 背景・問題意識

オーナーから、めぐり住人の顔テクスチャが上下逆になっている可能性があると指摘された。`DataTexture` は通常の画像テクスチャとY方向の扱いがずれやすく、プロシージャルに描いた顔の上下がPlaneGeometry上で反転して見える可能性があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 顔用 `DataTexture` に `flipY = true` を設定し、描画データの上方向と3D平面上のUVの上方向を合わせた。
- 口パクも同じ顔テクスチャ上で動くため、口の開閉方向も合わせて補正される。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の顔テクスチャ表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、目が上・口が下に表示されること、口パクの上下方向が自然なことを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 顔テクスチャのY方向を `flipY` で補正した
- ✅ 口パクは同じテクスチャ上で動くため追加の個別補正は不要
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.7：めぐり会話中の口パクを追加

### 背景・問題意識

オーナーから、会話中に話しているキャラクターの口がバクバク動くようにしたいという要望があった。めぐり住人の顔は iter162.6 でテクスチャ表現へ寄せたため、別メッシュを貼るのではなく、顔テクスチャ内の口だけを会話中に描き替える形で対応する必要があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 3Dシーンに `speakingId` / `speaking` を渡せるようにし、現在話している住人だけを判定できるようにした。
- 顔テクスチャのベースデータを保持し、会話中だけ口の開き具合をフレームごとに描き替えるようにした。
- 文字表示完了後や聞き手・待機列では口を閉じるようにした。
- `DataTexture` の破棄漏れを避けるため、material dispose 時に `map` も破棄するようにした。

#### `mobile/app/meguri-intro.tsx`
- 会話中の発話者が自分か相手かを `MeguriThreeScene` へ渡すようにした。
- 吹き出し本文が出きる前だけ `speaking` を true にし、本文完了後は口パクを止めるようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 会話本文が一文字ずつ出ている間だけ、話者キャラの口を開閉する仕様を追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の会話中表情アニメーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、自分/相手それぞれの発話中だけ口が開閉し、本文表示完了後に止まることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 口パクは顔の上に別パーツを載せず、顔テクスチャ内の口を描き替える方式にした
- ✅ 発話者だけが口パクし、聞き手・待機列は動かない
- ✅ 本文表示完了後は口が閉じる
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.6：めぐり演出の待機・顔・吹き出し・門を再調整

### 背景・問題意識

オーナーから、待機中のキャラクターが歩き続けて見えること、動物の顔が図形パーツの貼り足しに見えること、冒頭サマリー表示が唐突で味気ないこと、吹き出しと本文が同時に出てしまうこと、吹き出し内の「タップで次へ」が不要であること、広場入口の門と雲の品質を上げたいことが指摘された。めぐり演出として、止まる・歩く・話す・広場へ入るが自然につながるように調整する必要があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 待機列のキャラクターが目標位置に着いた後は、歩行用の腕脚アニメーションを止めるようにした。
- 顔の目・鼻・口・ほっぺ・ねこのひげ等を、個別メッシュではなく `DataTexture` のプロシージャルテクスチャへまとめた。
- 動物種ごとに目の丸さ、鼻色、ひげ、マズルの出方を少し変え、デフォルメされた「めぐり住人」寄りにした。
- 広場入口の門を、細い棒と半円から、厚みのある黄色いアーチ板・足元の小道・葉っぱ飾りの構成へ作り直した。
- 背景の雲に速度を持たせ、3Dシーン内でゆっくり流れるようにした。

#### `mobile/app/meguri-intro.tsx`
- 冒頭の「X人とめぐりあいました！」を、スプリング感のあるぬるっとした表示にした。
- 吹き出しは先にポップ表示し、その後に本文が一文字ずつ出るようにした。
- 本文表示完了後に、吹き出し右下の `▼` が点滅するようにした。
- 吹き出し内の「タップで次へ」テキストを削除し、会話中の下部ボタンも非表示にした。
- 本文が出きる前のタップでは次のセリフへ進まないようにした。

#### `notes/21_oshi_encounter_strategy.md`
- 顔テクスチャ、門の品質、流れる雲、スプラッシュ表示、吹き出しの文字送りと `▼` 表示を仕様メモに追記した。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の待機・歩行・顔表現
- 冒頭サマリー、吹き出しUI、広場入口背景

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、待機列が止まること、顔がテクスチャ表現に寄ること、サマリー表示・文字送り・点滅 `▼`・門・雲を確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 待機中のキャラクターは歩行用の腕脚スイングを止めた
- ✅ 顔は個別メッシュの積み重ねではなく、1枚のプロシージャルテクスチャへ寄せた
- ✅ 冒頭サマリーを唐突な静的表示ではなく、ぬるっと出るAnimated表示にした
- ✅ 吹き出しポップ後に本文が一文字ずつ表示され、完了後だけ `▼` が点滅する
- ✅ 吹き出し内の「タップで次へ」と会話中の下部ボタンを削除した
- ✅ 本文表示完了前の誤タップで会話が飛ばないようにした
- ✅ 門を厚みのある黄色いアーチへ作り直し、雲をゆっくり流れる演出にした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.5：めぐり住人の頭身と連続歩行演出を再調整

### 背景・問題意識

オーナーから、3Dキャラクターの見た目がイメージから離れているとの指摘があった。参照画像のように、大きな顔、小さな体、手先に向かって細くなる腕、顔の構成がはっきり分かる造形へ寄せる必要があった。また、キャラクターが地面にめり込んで見える問題、会話中に「10人とめぐりあいました！」が残る問題、会話後と次の人の登場が連続的に見えない問題、吹き出しが即表示されすぎる問題も合わせて修正する必要があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 住人の頭身を、大きい頭・小さい胴体へ再調整した。
- 顔の白い面、縦長の目、瞳、ハイライト、口、鼻、ほっぺの位置を再調整し、顔の構成が前面から読みやすい形にした。
- 腕と脚を円柱/球だけではなく、先端に向かって細くなるテーパー形状へ変更した。
- 足裏が地面に乗るよう、脚・足・影のY座標を調整した。
- 歩行中の上下揺れが地面より下へ沈まないよう、バウンドを上方向だけにした。

#### `mobile/app/meguri-intro.tsx`
- 内部演出フェーズに `approaching` を追加し、会話前に相手が前へ歩いてくる時間を作った。
- 1人目の会話後はその人が門へ歩き、次に2人目が前へ歩き出し、残りの列が続いて詰める流れにした。
- 会話中は「10人とめぐりあいました！」ヘッダーを表示しないようにした。
- 吹き出しをタップ直後に文字付きで出すのではなく、ポップ表示後に文字が出る流れにした。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の造形、足元、会話前後の歩行、吹き出し表示タイミング

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、足元・頭身・会話中ヘッダー非表示・吹き出しポップ・次の人の歩き出しを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 既存IPの直接模倣ではなく、Megrum独自の住人として頭身・顔構成の方向性を寄せた
- ✅ 手先に向かって細くなる腕・脚にした
- ✅ 地面めり込みを避けるため、足裏とバウンド方向を調整した
- ✅ 会話中の「10人とめぐりあいました！」表示を外した
- ✅ 会話後の退出と次キャラの歩き出しを連続的にした
- ✅ 吹き出しのポップ後に文字表示されるようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.4：めぐり3D住人の造形と歩行モーションを強化

### 背景・問題意識

オーナーから、めぐり3Dキャラクターをより高品質にし、参照画像のように手・足・顔がはっきり分かるキャラクターへ近づけたいという要望があった。既存のプロシージャル3Dは丸いマスコット感が強く、腕脚の動きも全身の揺れ中心だったため、Megrum独自のぬいぐるみ住人として、パーツ密度と歩行アニメーションを上げる必要があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 3D住人を、胴体・頭・耳・腕・手・脚・足・しっぽ・顔・服パーツに分けて生成する構造へ変更した。
- 顔に白目、黒目、ハイライト、眉、鼻、口、ほっぺ、マズルを追加し、表情が読み取れるようにした。
- 服・襟・ボタン風パーツを追加し、毛色だけでなくキャラごとの見た目に奥行きが出るようにした。
- ねこ / うさぎ / くまの耳としっぽの形状差を強めた。
- 入場・退出など移動中は、腕と脚を交互に振り、足先も踏み出しに合わせて回転する歩行アニメーションにした。
- 会話中や待機中は歩行ではなく小さなアイドル揺れに抑え、話している時に不自然に歩き続けないようにした。

### 影響範囲

- iOS版の `meguri-intro` 3D演出
- めぐり住人の見た目、歩行、待機アニメーション

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、住人の手足・顔・服パーツと、遠くから歩いてくる時の腕脚モーションを確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 既存IPのキャラを直接模倣せず、Megrum独自のぬいぐるみ住人として造形密度を上げた
- ✅ 手・足・顔・しっぽ・服パーツを追加した
- ✅ 移動中の腕脚スイングと足先回転を追加した
- ✅ 会話中はアイドル揺れに抑えた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.3：めぐり演出に入場フェーズと吹き出し会話を追加

### 背景・問題意識

オーナーから、めぐり演出の冒頭は最初に「10人とめぐりあいました！」が大きく出て、その後めぐり合った人たちが遠くからとことこ歩いてくる流れにしたいという要望があった。また、会話中のUIは下部カードではなく、キャラクターたちの上側に吹き出しとして表示し、どちらが話しているかを吹き出しの突き出し位置で判別できるようにする必要があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- `summary` 内に `splash` / `walking` / `ready` の入場フェーズを追加した。
- 冒頭に「10人とめぐりあいました！」を大きく表示し、その後に入場フェーズへ自動遷移するようにした。
- 入場中は進行ボタンをロックし、列が整ってから「一人ずつ話す」へ進めるようにした。
- 下部の会話カードを廃止し、キャラクターの上側に吹き出しUIを表示するようにした。
- 自分が話す時は吹き出しの突き出しを左側、相手が話す時は右側に寄せ、発話者が構図から分かるようにした。
- 2Dフォールバックでも冒頭スプラッシュ中は相手列を隠すようにした。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `introPhase` を受け取り、`splash` 中は相手キャラを遠くの待機位置に置いて非表示にするようにした。
- `walking` へ進むと、相手キャラが遠くから右側の待機列へ補間移動するようにした。
- 自分キャラは左手前に固定し、相手だけが入場してくる見え方にした。

### 影響範囲

- iOS版の `meguri-intro` 演出画面
- 3D演出の冒頭タイミング
- 会話UIの表示位置と発話者判別

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、冒頭スプラッシュ、相手列の入場、吹き出し位置を確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 冒頭に「X人とめぐりあいました！」を大きく出す流れにした
- ✅ 相手キャラが遠くから待機列へ歩いてくる入場フェーズを追加した
- ✅ 会話UIをキャラクター上側の吹き出しに変更した
- ✅ 吹き出しの突き出し位置で、自分 / 相手の発話を区別できるようにした
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.2：めぐり3D演出を全画面の左右構図へ調整

### 背景・問題意識

Preview確認後、オーナーから「左側が自分ユーザー、右で並んでいるのがめぐり合った人の列」という参照画像ベースの構図指定があった。また、演出画面はカード内ではなく画面いっぱいに見せたいという要望があったため、3Dシーンの座標と画面レイアウトを調整する必要があった。

### 変更内容

#### `mobile/app/meguri-intro.tsx`
- `Screen` の通常余白を外し、めぐり演出を画面いっぱいのフルスクリーンステージとして表示するようにした。
- 戻る / 進捗 / スキップ、会話カード、進行ボタンをステージ上にオーバーレイ配置した。
- 2Dフォールバックでも、自分を左、めぐり相手の列を右側に並べる構図へ変更した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- 自分キャラを左手前、めぐり相手の列を右側から奥へ続く配置に変更した。
- 会話中の相手は列から前に出て自分と向き合い、会話後は左奥の門へ歩いていく座標にした。
- 参照画像の印象に合わせ、空色背景、芝生床、黄色い門、雲、スパークルを追加・調整した。
- 縦長画面でも左右構図が収まるよう、カメラFOVと距離を調整した。

### 影響範囲

- iOS版の `meguri-intro` 演出画面
- 3D演出の構図、2Dフォールバックの構図

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewで、めぐり演出が画面いっぱいになり、左に自分・右にめぐり列が表示されることを確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`

### セルフレビュー結果

- ✅ 指定された「左が自分、右がめぐり合った人の列」の構図へ変更した
- ✅ 演出画面をカード状の内側表示ではなく、フルスクリーンステージにした
- ✅ 3Dと2Dフォールバックの両方で構図を揃えた
- ✅ 状態ID追加なしのため `notes/09_state_machines.md` の更新は不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` の更新は不要
- ✅ DB変更なしのため `notes/05_data_model.md` の更新は不要

---

## イテレーション162.1：めぐり3D描画をGLView直結へ修正

### 背景・問題意識

Previewビルド確認で、めぐり演出の3Dモデルが表示されない問題が出た。iter162 の初期実装は React Three Fiber native Canvas に依存しており、Preview環境でCanvas側が描画されないと3Dシーン全体が空白になるリスクがあった。また、正式な `.glb` モデル資産ではなく、アプリ内でぬいぐるみ風キャラをプロシージャルに組み立てる実装である点を明確にする必要があった。

### 変更内容

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- React Three Fiber依存をやめ、Expo公式の `GLView` で取得したGLコンテキストへ `three` の `WebGLRenderer` を直接接続する実装に変更した。
- ねこ / うさぎ / くまのぬいぐるみ風3Dキャラ、待機列、自分キャラ、広場の門、床、ライト、スパークルをThree.jsオブジェクトとして直接生成する形にした。
- アニメーションは `requestAnimationFrame` で各キャラの位置・回転・スケールを補間し、会話中・退出中・待機中の見え方を維持した。
- 描画リソースをunmount時にdisposeし、再表示時のGLリソース残りを抑えるようにした。

#### `mobile/app/meguri-intro.tsx`
- GL初期化失敗時は失敗表示だけを残さず、既存の2Dフォールバック演出へ切り替えるようにした。

#### `mobile/package.json` / `package-lock.json`
- 不要になった `@react-three/fiber` と `expo-three` を削除し、実運用で必要な `expo-gl` / `expo-asset` / `three` の構成に整理した。

#### `notes/21_oshi_encounter_strategy.md`
- 初期実装方針を、React Three Fiber前提から `GLView` + `three` 直結へ更新した。

### 影響範囲

- iOS版の `meguri-intro` 演出画面
- iOS Preview / EAS Build（`expo-gl` 追加済みのため、ネイティブ反映にはPreview再ビルドが必要）
- 将来の `.glb` モデル資産差し替え方針

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run config:ios:preview`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewを再ビルド後、めぐりトップの「今日のめぐりを見る」から3D演出を確認

### 関連ファイル

- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/app/meguri-intro.tsx`
- `mobile/package.json`
- `package-lock.json`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 3Dキャラクターは外部モデル未配置ではなく、アプリ内でThree.jsオブジェクトとして生成する実装にした
- ✅ 3D描画失敗時は2Dフォールバックに切り替わる
- ✅ ねこ / うさぎ / くま、毛色、会話後に門へ向かう演出の仕様は維持した
- ✅ 新しい状態IDは追加していないため `notes/09_state_machines.md` の更新は不要
- ✅ 初回は仮データ運用でDB追加なしのため `notes/05_data_model.md` の更新は不要
- ✅ 新しい用語追加はないため `notes/10_glossary.md` の更新は不要

---

## イテレーション162：めぐり3D演出をiOSに実装

### 背景・問題意識

iter161.9 で確定した「めぐり3D演出」を、まずiOS版のめぐり演出画面へ実装する必要があった。初回はめぐりのみを対象にし、グッズ交換側のクラッカー等の3D演出は保留する。正式な `.glb` モデル資産がまだないため、R3F上で高品質なぬいぐるみ風のプロシージャル3Dキャラクターを組み、後から正式モデルへ差し替えられる土台にした。

### 変更内容

#### `mobile/package.json` / `mobile/package-lock.json` / `package-lock.json`
- `expo-gl` / `expo-asset` / `three` / `@react-three/fiber` を追加し、iOS版で3Dシーンを描画できる依存を入れた。
- `@types/three` を追加し、Three.jsまわりのTypeScript型チェックを通した。

#### `mobile/app.config.js`
- Expoの動的configに `expo-asset` plugin を追加した。

#### `mobile/src/components/meguri/MeguriThreeScene.tsx`
- めぐり用の3Dシーンコンポーネントを追加した。
- ねこ / うさぎ / くまの3種類のぬいぐるみ風キャラクターを、球体・耳・手足・顔・毛束パーツで構成した。
- 自分キャラ、待機列、会話中の相手、門へ歩いていく相手をR3Fの `useFrame` で滑らかに補間するようにした。
- 広場の床、門、淡い光、スパークルを入れ、めぐり広場の入口として見えるステージにした。
- 3D描画エラー時に2D演出へ戻れる `MeguriThreeBoundary` を追加した。

#### `mobile/app/meguri-intro.tsx`
- 既存の3ステップ演出を、タップ進行の3D会話演出へ置き換えた。
- 「X人とめぐりあいました！」から始まり、相手自己紹介、自分自己紹介、都道府県、相手の今日のひとこと、自分の今日のひとこと、門へ歩く流れにした。
- 10人ごとの一区切りに合わせ、最大10人を1回の演出対象にした。
- スキップ導線、2Dフォールバック表示、ひとこと未設定時の代替文を入れた。

#### `mobile/app/(tabs)/encounters.tsx`
- `MeguriUser` に仮の `animalType` / `furColor` を追加した。
- ねこ / うさぎ / くま、複数毛色の仮データを既存ユーザーに付与した。
- 今日のめぐりCTA文言を、10人区切りの3D演出に合わせた。

#### `notes/21_oshi_encounter_strategy.md`
- 初期実装は正式 `.glb` 資産待ちではなく、R3Fのプロシージャル3Dキャラで先に実装し、後から `.glb` 差し替え可能にする方針を追記した。

### 影響範囲

- iOS版の `めぐり` タブ
- `meguri-intro` 演出画面
- iOS Preview / EAS Build（`expo-gl` 追加により再ビルド必須）
- 将来のプロフィール設定（毛色選択）と3Dモデル差し替え設計

### 確認方法

- `npm --prefix mobile run typecheck`
- `npm --prefix mobile run config:ios:preview`
- `npm --prefix mobile run export:ios:preview`
- iOS Previewを再ビルド後、めぐりトップの「今日のめぐりを見る」から3D演出を確認

### 関連ファイル

- `mobile/app/meguri-intro.tsx`
- `mobile/src/components/meguri/MeguriThreeScene.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app.config.js`
- `mobile/package.json`
- `mobile/package-lock.json`
- `package-lock.json`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 初回実装範囲をめぐり演出だけに限定し、交換側3D演出は入れていない
- ✅ ねこ / うさぎ / くま、ぬいぐるみ風、毛色仮データ、10人区切り、柔らかい会話文を反映した
- ✅ 3Dエラー時の2Dフォールバックを実装した
- ✅ ネイティブ依存 `expo-gl` を追加したため、EAS UpdateだけではなくPreview再ビルドが必要であることを影響範囲に明記した
- ✅ 新しい状態IDは追加していないため `notes/09_state_machines.md` の更新は不要
- ✅ 初回は仮データ運用のため `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は iter161.9 で追加済みのため `notes/10_glossary.md` の追加更新は不要

---

## イテレーション161.9：めぐり3D演出仕様を確定

### 背景・問題意識

オーナーから、めぐり機能で巡り合った時の演出を、既存の「歩くプロフカード」よりも立体的で高品質な3D体験にしたいという相談があった。グッズ交換側はキャラ必須ではなく、将来的にクラッカー等の立体エフェクトを検討する一方、まずはめぐり側に絞って、ぬいぐるみ風3Dキャラクターが会話し、自分の広場へ入っていく演出仕様を固める必要があった。

### 変更内容

#### `notes/21_oshi_encounter_strategy.md`
- 「めぐり3D演出仕様（iter161.9）」を追加した。
- 初回実装範囲をめぐりのみとし、交換側3D演出は保留にした。
- `expo-gl` + `three` / React Three Fiber系で `.glb` を表示する方針、2Dフォールバック、Preview再ビルドが必要な点を明記した。
- 初期キャラ種を、ねこ / うさぎ / くまの3種類にし、ぬいぐるみ風の質感と毛色仮データ運用を定義した。
- タップごとの会話フロー、10人ごとの区切り、未設定ひとこと代替文、スキップ導線、会話後に門をくぐって広場へ入る演出を整理した。

#### `notes/10_glossary.md`
- `めぐり`、`めぐり3D演出`、`めぐり住人`、`めぐり広場` を用語として追加した。

### 影響範囲

- iOS版の `めぐり` タブ
- `mobile/app/meguri-intro.tsx` の次期3D化方針
- `mobile/app/(tabs)/encounters.tsx` の2Dフォールバック方針
- 将来のプロフィール設定（毛色選択）と3Dモデル資産設計

### 確認方法

- `notes/21_oshi_encounter_strategy.md` §16 を読み、会話フロー・キャラ仕様・リスク対策が今回の合意と一致していることを確認
- `notes/10_glossary.md` §B で追加用語の定義を確認

### 関連ファイル

- `notes/21_oshi_encounter_strategy.md`
- `notes/10_glossary.md`
- `mobile/app/meguri-intro.tsx`
- `mobile/app/(tabs)/encounters.tsx`

### セルフレビュー結果

- ✅ めぐり側の3D演出に絞り、グッズ交換側の3D演出は保留として分離した
- ✅ 「ねこ / うさぎ / くま」「ぬいぐるみ風」「毛色は初回仮データ、将来プロフィール設定」を明記した
- ✅ 都道府県は公開プロフィール項目だが、会話文では柔らかく表示する方針にした
- ✅ 10人ごとの区切り、スキップ、2Dフォールバック、ネイティブ再ビルドリスクを明記した
- ✅ 新しい状態IDは追加していないため `notes/09_state_machines.md` の更新は不要
- ✅ 初回はDB追加なしの仮データ運用のため `notes/05_data_model.md` の更新は不要

---

## イテレーション161.8：Expo Routerの解決パスをMetro設定側で固定

### 背景・問題意識

iter161.7 でEAS Build profileに `NODE_PATH=mobile/node_modules` を追加したが、EASのiOS Bundle JavaScript phaseでは作業ディレクトリが変わり、相対 `NODE_PATH` が期待通りに効かない可能性が残った。実際にPreviewビルドで再度 `EXPO_ROUTER_APP_ROOT` がインライン化されないエラーが出たため、環境変数だけに頼らず、Metro設定の読み込み時点でNodeの解決パスを固定する必要があった。

### 変更内容

#### `mobile/metro.config.js`
- `expo/metro-config` を読み込む前に `mobile/node_modules` とrepo root `node_modules` を `NODE_PATH` に追加し、`Module._initPaths()` でNodeの解決パスへ反映するようにした。
- これにより、root側にいる `babel-preset-expo` からも `mobile/node_modules/expo-router` を解決でき、Expo Router Babel pluginが `process.env.EXPO_ROUTER_APP_ROOT` を文字列へ変換できるようにした。

#### `mobile/eas.json`
- `NODE_PATH` を `./node_modules:mobile/node_modules` に変更し、EASのcwdがrepo rootでもmobile配下でも解決できるようにした。

### 影響範囲

- iOS Preview Build
- iOS Preview向けEAS Update
- Expo Routerの本番バンドル処理
- npm workspace上のMetro/Babel解決

### 確認方法

- `cd mobile && npm run export:ios:preview`
- `npm --prefix mobile run typecheck`
- `cd mobile && npm run build:ios:preview:clear`

### 関連ファイル

- `mobile/metro.config.js`
- `mobile/eas.json`

### セルフレビュー結果

- ✅ 環境変数だけでなく、Metro設定側で絶対パスをNode解決パスへ追加した
- ✅ iOS標準コンポーネントや画面仕様には触れていない
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要

---

## イテレーション161.7：EAS BuildのExpo Router app root解決を修正

### 背景・問題意識

EAS BuildのPreviewビルドで `node_modules/expo-router/_ctx.ios.js: Invalid call ... process.env.EXPO_ROUTER_APP_ROOT` が発生した。npm workspace構成では `expo` / `babel-preset-expo` がroot側、`expo-router` が `mobile/node_modules` 側に配置されることがあり、公式のExpo Router Babel pluginが `expo-router` を解決できず、`process.env.EXPO_ROUTER_APP_ROOT` を文字列へインライン化できていなかった。

### 変更内容

#### `mobile/eas.json`
- EAS Buildの各profileに `NODE_PATH=mobile/node_modules` を追加し、root側で動くMetro/Babelからも `mobile/node_modules/expo-router` を解決できるようにした。
- `production` profileにも `NPM_CONFIG_LEGACY_PEER_DEPS=true` を明示し、依存解決の挙動をPreview/Developmentと揃えた。

#### `mobile/package.json`
- `export:ios:preview` を追加し、ローカルでもEAS BuildのiOS export相当を検証できるようにした。
- `update:ios:preview` に `NODE_PATH=./node_modules` を追加し、EAS Update配信時にもExpo Routerのapp root変換が確実に効くようにした。

### 影響範囲

- iOS Preview Build
- iOS Preview向けEAS Update
- Expo Routerの本番バンドル処理

### 確認方法

- `cd mobile && npm run export:ios:preview`
- `npm --prefix mobile run typecheck`
- `cd mobile && npm run build:ios:preview:clear`

### 関連ファイル

- `mobile/eas.json`
- `mobile/package.json`

### セルフレビュー結果

- ✅ ローカルで `NODE_PATH=./node_modules APP_VARIANT=preview npx expo export:embed --eager --platform ios --dev false` が成功した
- ✅ EAS Build側はroot cwdで動くため `NODE_PATH=mobile/node_modules`、ローカルscript側はmobile cwdで動くため `NODE_PATH=./node_modules` と分けた
- ✅ iOS標準コンポーネントや画面仕様には触れていない
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要

---

## イテレーション161.6：EAS UpdateでPreviewへJS更新を配信できるように設定

### 背景・問題意識

外出用の `Megrum Preview` はMacなしで単体起動できる一方、これまでは新しい開発内容を反映するたびにEAS Buildを作り直して再インストールする必要があった。オーナーから「EAS Updateを入れてJSだけ配信更新できるようにしてほしい」と依頼があり、Previewビルドへ素早く更新を流せる構成にした。

### 変更内容

#### `mobile/package.json`
- `expo-updates` を追加した。
- `update:ios:preview` を追加し、`preview` チャンネルへiOS向けJS更新を配信できるようにした。

#### `mobile/app.config.js`
- `runtimeVersion: { policy: "appVersion" }` を追加した。
- EAS Update用の `updates.url` を `https://u.expo.dev/<projectId>` で設定した。
- 既存のPreview分離設定は維持し、`Megrum Preview` / `tokyo.megrum.app.preview` / `megrum-preview` のままにした。

#### `mobile/eas.json`
- `preview` profile に `channel: "preview"` を追加し、外出用Previewアプリが `preview` チャンネルを購読するようにした。
- `development` / `production` にもチャンネルを明示した。

### 影響範囲

- iOS版の外出レビュー運用
- EAS Build / EAS Updateの配信フロー
- PreviewアプリのJS更新反映タイミング

### 確認方法

- `npm --prefix mobile run typecheck`
- `cd mobile && npm run config:ios:preview`
- 初回のみ `cd mobile && npm run build:ios:preview:clear`
- 以後JS/画面変更だけなら `cd mobile && npm run update:ios:preview -- --message "更新内容"`

### 関連ファイル

- `mobile/app.config.js`
- `mobile/eas.json`
- `mobile/package.json`
- `mobile/package-lock.json`
- `package-lock.json`

### セルフレビュー結果

- ✅ Previewビルドが `preview` チャンネルを購読する設定になった
- ✅ EAS Updateに必要な `expo-updates` / `updates.url` / `runtimeVersion` を追加した
- ✅ ネイティブ依存やBundle IDなどを変える時は従来通り再ビルドが必要で、JS/画面変更だけをEAS Update対象にした
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要

---

## イテレーション161.5：iOS Previewを別アプリとして共存できる構成に分離

### 背景・問題意識

外出中にMacなしで起動できるPreviewビルドを作る場合、既存の開発ビルドと同じBundle IDのままだとiPhone上で上書きされ、Metro接続用の開発ビルドと単体起動用のPreviewを併用しづらい。オーナーから「それやりたい」と確認があったため、Previewだけ別アプリとしてインストールできる構成にした。

### 変更内容

#### `mobile/app.config.js`
- `APP_VARIANT=preview` の時だけ、表示名を `Megrum Preview`、URLスキームを `megrum-preview`、iOS Bundle IDを `tokyo.megrum.app.preview` に切り替える動的Expo configを追加した。
- 通常の開発ビルドでは既存の `Megrum` / `megrum` / `tokyo.megrum.app` を維持するようにした。

#### `mobile/eas.json`
- `preview` profile に `APP_VARIANT=preview` を設定し、EAS Build上でPreview専用configが解決されるようにした。

#### `mobile/package.json`
- `config:ios:preview` を追加し、ローカルでPreview用Expo configを確認できるようにした。

### 影響範囲

- iOS版のEAS Build運用
- 外出用Previewアプリのインストール・起動導線
- Supabase Authのメールリンク/Deep Link設定

### 確認方法

- `npm --prefix mobile run typecheck`
- `cd mobile && npm run config:ios:preview`
- `cd mobile && npm run build:ios:preview:clear`

### 関連ファイル

- `mobile/app.config.js`
- `mobile/eas.json`
- `mobile/package.json`

### セルフレビュー結果

- ✅ 開発ビルドの既存Bundle IDとスキームは維持し、Previewだけ別Bundle ID / 別スキームに分離した
- ✅ `preview` profileのみ `APP_VARIANT=preview` を渡すため、通常の開発ビルドに影響しない
- ⚠️ Previewでメールリンクログインを使う場合、Supabase AuthのRedirect URLに `megrum-preview://auth/email-confirmed` を追加する必要がある
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要

---

## イテレーション161.4：外出用iOSプレビュービルド導線を追加

### 背景・問題意識

開発ビルドはMac上のMetroサーバーに接続する前提のため、外出中に単体でアプリを開きづらい。オーナーから「外出中にもアプリを開きたい」と相談があり、Macなしで起動できる内部配布用プレビュービルドを作りやすくする必要があった。

### 変更内容

#### `mobile/package.json`
- `build:ios:preview` を追加し、`eas build --platform ios --profile preview` を短いコマンドで実行できるようにした。
- `build:ios:preview:clear` を追加し、依存関係やEASキャッシュが怪しい時に `--clear-cache` 付きで外出用ビルドを作れるようにした。

### 影響範囲

- iOS版のビルド/レビュー運用
- 外出中にMacなしで起動するための内部配布フロー

### 確認方法

- `npm --prefix mobile run typecheck`
- `cd mobile && npm run build:ios:preview`

### 関連ファイル

- `mobile/package.json`
- `mobile/eas.json`

### セルフレビュー結果

- ✅ 既存の `preview` profile は `developmentClient: true` ではないため、Mac上のMetroに依存しない内部配布ビルド用として使える
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要

---

## イテレーション161.3：めぐり文言と各画面再現度を調整

### 背景・問題意識

オーナーから、めぐり機能の表記を「めぐりました」ではなく「めぐりあいました」に統一し、各画面のデザインがモックアップと所々違うため自分でレビューして再現するよう要望があった。トップ画面だけでなく、広場・マップ・実績・レポート・ひとこと・レター・Plus・シェアの個別画面も `Megurum めぐる機能/` のモックアップに近づける必要があった。

### 変更内容

#### `mobile/app/meguri-*.tsx`
- `meguri-report.tsx` を、モックアップの `DAILY REPORT`、大きな人数カード、内訳タイル、今日のカード、実績達成、匿名シェアCTA構成に寄せた。
- `meguri-map.tsx` を、抽象的な丸いマップから都道府県タイル風のめぐりマップへ変更し、点灯済みエリアと回数が見えるようにした。
- `meguri-plaza.tsx` を、フィルタ・統計ピル・広場ステージ・歩くプロフカードの構成に寄せた。
- `meguri-hitokoto.tsx` を、今日のお題、入力欄、文字数、カードプレビュー、過去のひとこと、注意書きの構成に寄せた。
- `meguri-letters.tsx` を、受け取った/送ったのセグメント、未開封レター、Plus導線、送信フォームの構成に寄せた。
- `meguri-plus.tsx` を、Plusヒーロー、月額/無料プラン選択、機能一覧、月額CTAの構成に寄せた。
- `meguri-share.tsx` を、1:1匿名シェア画像プレビュー、表示オプション、背景スウォッチ、保存CTAの構成に寄せた。
- `meguri-achievements.tsx` を、実績数のヒーロー、サマリー、解除/未解除一覧の構成に寄せた。

#### `mobile/app/(tabs)/encounters.tsx`
- 実績説明とひとことモーダルの文言を「めぐりあいました」「めぐりあった人」に統一した。

#### `notes/21_oshi_encounter_strategy.md`
- AIデザインブリーフ内の表記も「めぐりました」「めぐった」から「めぐりあいました」「めぐりあった」に合わせた。

### 影響範囲

- iOS版の `めぐり` タブ
- めぐりトップから遷移する個別画面群
- めぐり機能のデザインブリーフ

### 確認方法

- `npm --prefix mobile run typecheck`
- `rg -n "めぐりました|めぐった" mobile notes/21_oshi_encounter_strategy.md`
- `Megurum めぐる機能/meguri-screens-a.jsx` / `meguri-screens-b.jsx` と各 `mobile/app/meguri-*.tsx` の構成を突き合わせる

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-achievements.tsx`
- `mobile/app/meguri-hitokoto.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/meguri-map.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/app/meguri-plus.tsx`
- `mobile/app/meguri-report.tsx`
- `mobile/app/meguri-share.tsx`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` が成功した
- ✅ `mobile` と `notes/21_oshi_encounter_strategy.md` から「めぐりました」「めぐった」の残存がなくなった
- ✅ 各画面を `Megurum めぐる機能/meguri-screens-a.jsx` / `meguri-screens-b.jsx` と突き合わせ、モックアップの主要ブロック構成を再現した
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要

---

## イテレーション161.2：ナビ・通知・設定・打診送信の改善

### 背景・問題意識

オーナーから、左ドロワーとフッターの役割整理、Xに近い通知一覧/設定一覧、打診送信時のエラー修正の要望があった。通知は左ドロワーから開けるためフッターから外し、フッター右端は取引に固定する。また、打診送信はSupabaseのスキーマキャッシュや一部列の有無に影響されて失敗しないようにする必要があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- フッターから `通知` タブを非表示にし、表示順を `ホーム / 在庫 / Wish / めぐり / 取引` に整理した。
- `通知` は左ドロワーから開ける hidden route として維持した。
- 左ドロワーから `取引` を削除し、`プロフィール` は自分のプロフィール画面へ遷移する導線として維持した。

#### `mobile/app/(tabs)/notifications.tsx`
- 通知一覧をカード型からX寄りのタイムライン型に変更した。
- `すべて / 未読 / 取引` の上部タブを追加し、未読数や件数を見ながら切り替えられるようにした。
- 通知行は左アイコン、タイトル、時刻、本文、未読ドットの構成にし、区切り線で連続的に読める表示にした。

#### `mobile/app/settings-privacy.tsx`
- 設定一覧から `アカウント` と `表示と言語` を削除した。
- `プライバシーと安全` を `プライバシーポリシー` に変更した。
- `プライバシーポリシー` と `規約と法的情報` を下部の法的情報セクションにまとめた。

#### `mobile/app/proposal-confirm.tsx`
- 打診送信時に `proposals` の任意列がSupabase側のスキーマキャッシュや環境差分で見つからない場合、該当列を外して再送するフォールバックを追加した。
- エラー表示をユーザー向けの日本語メッセージに整えた。

### 影響範囲

- iOS版の NativeTabs / 左ドロワー
- 通知一覧画面
- 設定とプライバシー画面
- 打診送信確認画面

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS開発ビルドで、左ドロワーからプロフィール/通知に遷移できること、フッター右端が取引であること、通知/設定一覧の表示を確認
- 打診送信時にスキーマキャッシュ由来の任意列エラーで即失敗しないことを確認

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/notifications.tsx`
- `mobile/app/settings-privacy.tsx`
- `mobile/app/proposal-confirm.tsx`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` が成功した
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 新しい主要用語は追加していないため `notes/10_glossary.md` の更新は不要
- ⚠️ 打診送信の最終確認は実機でSupabase接続状態のまま実送信テストが必要

---

## イテレーション161.1：めぐり導線を個別画面へ分割

### 背景・問題意識

iter161 の初期実装では、めぐりトップの1画面に「広場」「マップ」「実績」「今日のレポート」「レター」「Plus」をまとめて表示していた。オーナーから「1枚の画面に載せず、めぐりトップの各導線をタップしたらそれぞれの画面に飛ぶように」「めぐり演出の画面もきちんと表示」と指摘があったため、トップは入口に戻し、各体験を独立画面として確認できる構成へ修正した。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- めぐりトップから、広場・マップ・実績・レポート・レター・Plusの詳細セクションを削除した。
- トップは「今日のめぐり」ステージ、演出へのCTA、統計、各導線カード、ひとこと設定導線に整理した。
- 各ショートカットを個別ルートへ遷移させるようにした。
- 既存のめぐり用データ・プロフカード・レター・Plusモーダル系コンポーネントを、個別画面から再利用できるよう named export した。

#### `mobile/app/meguri-*.tsx`
- `meguri-intro.tsx` を追加し、今日のめぐり演出、1人ずつの自己紹介、マップに点く演出を3ステップで表示するようにした。
- `meguri-plaza.tsx` を追加し、プロフカードに手足が生えたカードが集まる「めぐり広場」を個別画面化した。
- `meguri-map.tsx` を追加し、正確な位置を出さない抽象マップ画面を個別画面化した。
- `meguri-achievements.tsx` を追加し、実績一覧を個別画面化した。
- `meguri-report.tsx` を追加し、今日のレポートと匿名シェア導線を個別画面化した。
- `meguri-hitokoto.tsx` を追加し、すれ違い用ひとこと設定を個別画面化した。
- `meguri-letters.tsx` を追加し、すれ違いレター一覧・開封/Plus導線・送信枠を個別画面化した。
- `meguri-plus.tsx` を追加し、月額1,000円のPlus説明を個別画面化した。
- `meguri-share.tsx` を追加し、匿名シェア画像のプレビュー画面を個別画面化した。

### 影響範囲

- iOS版の `めぐり` タブ
- めぐりトップからの各導線
- めぐり演出、広場、マップ、実績、今日のレポート、ひとこと、レター、Plus、匿名シェア画面

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS開発ビルドで `めぐり` タブを開き、各カード/ボタンから個別画面へ遷移することを確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/meguri-intro.tsx`
- `mobile/app/meguri-plaza.tsx`
- `mobile/app/meguri-map.tsx`
- `mobile/app/meguri-achievements.tsx`
- `mobile/app/meguri-report.tsx`
- `mobile/app/meguri-hitokoto.tsx`
- `mobile/app/meguri-letters.tsx`
- `mobile/app/meguri-plus.tsx`
- `mobile/app/meguri-share.tsx`
- `Megurum めぐる機能/meguri-app.jsx`
- `Megurum めぐる機能/meguri-intro.jsx`
- `Megurum めぐる機能/meguri-screens-a.jsx`
- `Megurum めぐる機能/meguri-screens-b.jsx`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` が成功した
- ✅ めぐりトップは詳細を抱え込まず、各導線から個別画面へ遷移する構成にした
- ✅ めぐり演出画面を独立ルートとして追加した
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 「推しすれ違い」「すれ違いレター」は既存用語として定義済みのため `notes/10_glossary.md` の追加更新は不要

---

## イテレーション161：めぐりタブを体験モックへ刷新

### 背景・問題意識

ZohoのDNS反映待ちの間に、オーナーから「めぐり」機能のデザイン一式が `Megurum めぐる機能/` に格納されたため、前回整理した推しすれ違い仕様とデザインモックに沿って iOS 版の専用タブを具体化する必要があった。

### 変更内容

#### `mobile/app/(tabs)/encounters.tsx`
- 既存のラフな推しすれ違い画面を、デザインモックの「めぐりトップ」中心の体験UIへ全面差し替えした。
- アプリを開いた瞬間の「今日5人とめぐりあいました！」ステージを追加し、プロフカードに小さな手足が生えて歩いてくる表現をReact Native上で再現した。
- アクティブなカードの自己紹介吹き出し、今日のめぐり数、広場・マップ・実績・今日のレポートのショートカットを追加した。
- 「めぐり広場」「めぐりマップ」「実績」「すれ違いレター」「送信枠」「Megrum Plus」を1つのタブ内に配置し、交換導線ではなく体験価値中心の構成にした。
- 未開封レターは届いたこと・相性・ぼかした場所/時刻を見せ、本文開封と返信は月額Plusに寄せるモーダル導線にした。
- すれ違い用ひとこと、レター作成、Plus確認のモーダルを追加した。

#### `mobile/app/(tabs)/_layout.tsx`
- タブ表示名を `すれ違い` から `めぐり` に変更した。

### 影響範囲

- iOS版の `めぐり` タブ
- NativeTabs の表示ラベル
- 推しすれ違い体験の初期UI、Plus導線、レター導線

### 確認方法

- `npm --prefix mobile run typecheck`
- iOS開発ビルドで `めぐり` タブを開き、ステージ/広場/マップ/レター/Plus導線を確認

### 関連ファイル

- `mobile/app/(tabs)/encounters.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `Megurum めぐる機能/meguri-app.jsx`
- `Megurum めぐる機能/meguri-screens-a.jsx`
- `Megurum めぐる機能/meguri-screens-b.jsx`
- `Megurum めぐる機能/meguri-card.jsx`

### セルフレビュー結果

- ✅ `npm --prefix mobile run typecheck` が成功した
- ✅ 交換マッチングではなく、同担・近い界隈との偶然性、蓄積、レター課金導線を主軸にした
- ✅ 新しい状態IDやDB列は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要
- ✅ 「推しすれ違い」「すれ違いレター」は既に `notes/10_glossary.md` に定義済みのため追加更新は不要

---

## イテレーション160：megrum.jp移行とめぐりブリーフ追記

### 背景・問題意識

オーナーが正式ドメインとして `megrum.jp` を取得したため、ユーザーに見えるURL・問い合わせメール・API仕様上のドメインを `megrum.tokyo` 系から `megrum.jp` 系へ移す必要がある。
また、会話で固めた Megrum「めぐり」機能の仕様を、デザインAIへそのまま渡せる形でファイルに残す必要がある。

### 変更内容

#### `notes/21_oshi_encounter_strategy.md`
- Megrum「めぐり」デザインAI用ブリーフ最新版を追記した。
- 3DSのすれ違い通信を参考にしつつ、任天堂・Mii・既存ゲームUIを模倣しない方針を明記した。
- プロフカードに小さな手足が生えて歩いてくる表現、すれ違い図鑑、抽象マップ、実績、すれ違い用一言、レター課金導線を整理した。
- 月額1,000円、無料送信月2通、単発開封チケットなしをデザイン前提に入れた。

#### `web/src/app/` / `mobile/app/` / `Megrum/legal-pages.jsx`
- ヘルプ、設定、法務ページ、geocode User-Agent/Referer などのユーザー向け連絡先・URLを `megrum.jp` 系へ更新した。
- `support@megrum.tokyo` を `support@megrum.jp` に置き換えた。
- `web/.env.local.example` の Supabase プロジェクト名メモを Megrum に更新した。

#### `notes/13_api_spec.md` / `notes/15_non_functional.md` / `notes/16_monetization.md` / `notes/17_legal_alignment.md` / `notes/19_email_templates.md`
- APIベースURLを `api.megrum.jp` / `api-staging.megrum.jp` に更新した。
- 公開連絡先を `support@megrum.jp` / `info@megrum.jp` に更新した。
- Supabase Auth メールテンプレートのブランド名・URL・問い合わせ先を Megrum / `megrum.jp` 系へ更新した。
- 法務整合メモに、公開ドメイン・問い合わせメールは `megrum.jp` 系へ移行し、Apple bundle identifier 等の技術IDは当面維持する方針を追記した。

### 影響範囲

- Web版 / iOS版のヘルプ・法務・設定表示
- geocode API の外部リクエスト識別ヘッダー
- API仕様ドキュメント
- 法務・非機能・収益化・メールテンプレートの公開連絡先
- めぐり機能のデザイン検討資料

### 確認方法

- `rg` で現行コード・現行仕様ドキュメントに旧ドメイン/旧メールが残っていないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `notes/21_oshi_encounter_strategy.md`
- `notes/13_api_spec.md`
- `notes/15_non_functional.md`
- `notes/16_monetization.md`
- `notes/17_legal_alignment.md`
- `notes/19_email_templates.md`
- `web/src/app/help/page.tsx`
- `web/src/app/settings/page.tsx`
- `web/src/app/legal/*.tsx`
- `web/src/app/api/geocode/route.ts`
- `web/.env.local.example`
- `mobile/app/help.tsx`
- `mobile/app/legal/*.tsx`
- `Megrum/legal-pages.jsx`

### セルフレビュー結果

- ✅ 現行コード・現行仕様ドキュメントの `megrum.tokyo` / `support@megrum.tokyo` / `info@megrum.tokyo` を `megrum.jp` 系へ更新した
- ✅ Apple bundle identifier / Expo scheme / slug は配信・署名影響があるため変更していない
- ✅ 「めぐり」機能のデザインAI用ブリーフを、会話の最新仕様に合わせて追記した
- ✅ 状態遷移・DBスキーマの変更はないため `notes/09_state_machines.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション159.3：表示名をMegrumへ統一

### 背景・問題意識

オーナーから、サービス名を `Megrum` から **Megrum** にしたいという依頼があった。前回の暫定表記として旧綴りが一部に残っていたため、ユーザーに見えるアプリ名・Web metadata・法務表示・ヘルプ文言・設計ドキュメントの正式名を `Megrum` に統一する。

### 変更内容

#### `mobile/app.json`
- Expo のアプリ表示名を `Megrum` に変更した。
- `slug` / `scheme` / `bundleIdentifier` は、EAS・Apple署名・既存リンクに影響するため `megrum` 系のまま維持した。

#### `package.json` / `package-lock.json`
- ワークスペースルートの private package 名を `megrum-platform` に変更した。

#### `mobile/app/` / `mobile/src/`
- 認証、ヘルプ、法務、オンボーディング完了、タブ表示などのユーザー向け表記を `Megrum` に統一した。

#### `web/src/`
- metadata title、Welcome、ヘルプ、法務ページ、サポート表記、User-Agent などのユーザー向け表記を `Megrum` に統一した。

#### `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/17_legal_alignment.md` / `notes/21_oshi_encounter_strategy.md`
- 正式サービス名・デザインAI用ブリーフ・法務整合メモの表記を `Megrum` に統一した。

### 影響範囲

- iOS版 / Web版のユーザー向けブランド表示
- アプリ名
- ヘルプ・法務ページ・デザインブリーフ上のサービス名
- 設計ドキュメントの正式名称

### 確認方法

- 旧綴りの英字表記が残っていないことを `rg` で確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app.json`
- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/signup.tsx`
- `mobile/app/help.tsx`
- `mobile/app/legal/*.tsx`
- `mobile/src/components/LegalDocument.tsx`
- `package.json`
- `package-lock.json`
- `web/src/app/**/*.tsx`
- `web/src/app/api/geocode/route.ts`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/17_legal_alignment.md`
- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ ユーザー向けの現行表記を `Megrum` に統一した
- ✅ `slug` / `scheme` / `bundleIdentifier` は配信・署名に影響するため維持した
- ✅ `npm --prefix mobile run typecheck` が成功した
- ✅ 状態名・DB列の追加変更はないため `notes/05_data_model.md` の更新は不要

---

## イテレーション159.2：Megrumアプリアイコンを差し替え

### 背景・問題意識

オーナーから、生成した Megrum の新しいアプリアイコン案をいったん実アプリのアイコンに設定したいという依頼があった。背景は既存アプリの淡いラベンダー/スカイ/ピンクの雰囲気を踏襲しつつ、中央の `M` と巡る軌道をシンプルに見せる方向で採用する。

### 変更内容

#### `mobile/assets/icon.png`
- 生成済みの Megrum アイコンを 1024x1024 PNG にリサイズして差し替えた。
- Expo `app.json` は既に `./assets/icon.png` を参照しているため、アプリ表示アイコンとして反映される。
- 画像は alpha なしの RGB PNG として確認した。

### 影響範囲

- iOS / Expo アプリの表示アイコン
- ホーム画面・インストール画面・開発ビルド上のアプリアイコン

### 確認方法

- `sips -g pixelWidth -g pixelHeight -g hasAlpha mobile/assets/icon.png`
- `file mobile/assets/icon.png`

### 関連ファイル

- `mobile/assets/icon.png`
- `mobile/app.json`

### セルフレビュー結果

- ✅ `mobile/assets/icon.png` が 1024x1024 であることを確認した
- ✅ alpha なしであることを確認した
- ✅ `mobile/app.json` の `icon` が `./assets/icon.png` を参照していることを確認した
- ✅ 画像差し替えのみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション159.1：推しすれ違いデザインAI用ブリーフを追加

### 背景・問題意識

オーナーから、`notes/21_oshi_encounter_strategy.md` の内容をもとに、画面デザイン生成AIへそのまま渡せるプロンプトと前提情報を整理したいという依頼があった。推しすれ違いは交換機能ではなく体験機能として設計する必要があるため、デザインAIが「近くの交換相手探し」や出会い系UIへ寄らないよう、禁止事項・画面一覧・サンプルデータ・文言候補まで明文化した。

### 変更内容

#### `notes/21_oshi_encounter_strategy.md`
- 「14. デザインAIへ渡す画面生成ブリーフ」を追加した。
- デザインAIへそのまま貼れるメインプロンプトを追加した。
- 9画面分の具体仕様を追加した。
  - 推しすれ違いトップ
  - すれ違いパネル詳細
  - 未開封レター一覧
  - 未開封レター詳細 / 開封前課金導線
  - レター開封後の本文・返信
  - レター作成
  - 推しすれ違い Plus
  - プライバシー・安全設定
  - 初回オンボーディング / 許可説明
- 推しパネル・レター・Plus のサンプルデータを追加した。
- UI文言候補、避ける表現、避けるUIを追加した。
- ビジュアルバリエーション、パネル深掘り、レター課金導線、モーション案用の追加プロンプトを追加した。

### 影響範囲

- 推しすれ違い機能の画面デザイン検討
- 外部/別AIへのデザイン依頼文
- 今後のiOS版 `すれ違い` タブ実装方針

### 確認方法

- `notes/21_oshi_encounter_strategy.md` の 14章だけをコピーして、デザインAIへ渡しても前提が伝わることを確認
- 「交換」「正確な位置」「出会い系」へ寄せない禁止事項が含まれていることを確認
- 月額1000円、無料送信月2通、単発開封チケットなしが反映されていることを確認

### 関連ファイル

- `notes/21_oshi_encounter_strategy.md`

### セルフレビュー結果

- ✅ 画面生成AIに渡せる独立ブリーフとして読める構成にした
- ✅ 既存の推しすれ違い仕様・課金方針・安全設計と矛盾しない
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション159：推しすれ違い体験構想を整理

### 背景・問題意識

オーナーから、現地交換モードとは別に「同担や近い界隈とすれ違う楽しさ」「すれ違うほどパネルが完成していく体験」「課金したらレター本文を開封・返信できる体験」を、交換機能から切り離して深掘りしたいという依頼があった。既存の `すれ違い` タブは骨格があるため、次のUI/機能開発に入る前に、体験価値・課金・安全設計・MVPロードマップを整理した。

### 変更内容

#### `notes/21_oshi_encounter_strategy.md`
- 推しすれ違いのコアコンセプトを「同じ推しを好きな人が、今日もどこかで推し活している実感を集める」と定義した。
- 現地交換モードと混同しないため、グッズ条件・Wish一致・即時合流を主訴にしない方針を明記した。
- すれ違いパネル、めぐり通知、すれ違いレター、同担濃度、すれ違いストーリー、イベント会場の空気などの体験案を列挙した。
- 月額1000円、無料送信月2通、レター開封チケットなしの課金設計を整理した。
- 位置・時刻のぼかし、k匿名性、ブロック、未成年・センシティブ対応などの安全設計を整理した。
- `encounter_presence_windows` / `encounter_events` / `encounter_panels` / `encounter_letters` / `encounter_quotas` のデータモデル候補を追加した。
- 既存 `mobile/app/(tabs)/encounters.tsx` を次に磨くためのUI改善順を整理した。

### 影響範囲

- iOS版 `すれ違い` タブの今後の設計
- 推しすれ違い Plus の課金体験
- 位置情報・Push通知・匿名性の非機能設計

### 確認方法

- `notes/21_oshi_encounter_strategy.md` を読み、交換機能ではなく体験機能として一貫していることを確認
- 既存 `notes/09_state_machines.md` の Oshi Encounter Letter Lifecycle と矛盾しないことを確認
- 既存 `notes/10_glossary.md` の `推しすれ違い` / `すれ違いパネル` / `すれ違いレター` / `推しすれ違い Plus` と矛盾しないことを確認

### 関連ファイル

- `notes/21_oshi_encounter_strategy.md`
- `mobile/app/(tabs)/encounters.tsx`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 交換・打診・取引への自動接続はしない方針を明記した
- ✅ 月額1000円、無料送信月2通、単発開封チケットなしの既存方針と整合した
- ✅ 既存の `received_locked` / `opened` / `replied` / `hidden` / `archived` 状態と矛盾しない
- ✅ 新しい正式用語は追加せず、既存 glossary の用語範囲で整理したため `notes/10_glossary.md` の追加更新は不要
- ⚠️ データモデル候補は未確定のため、実装前に `notes/05_data_model.md` へ正式反映する必要がある

---

## イテレーション158：ユーザー向けサービス名をMegrumへ変更

### 背景・問題意識

オーナーから、サービス名を `Megrum` から `Megrum` に変更する方針が示された。既にApple Developer / EAS / Supabase / ドメイン周りは `megrum` 系識別子で進んでいるため、まずはユーザーに見える表示名・ロゴ文字・ヘルプ・法務ページの画面表示を `Megrum` に変更し、bundle identifier やドメインなど署名・配信に関わる技術識別子は現時点では維持する。

### 変更内容

#### `mobile/app.json`
- アプリ表示名を `Megrum` に変更した。
- `slug` / `scheme` / `bundleIdentifier` は既存の `megrum` 系のまま維持した。

#### `mobile/app/` / `mobile/src/`
- 認証画面、ヘルプ、法務ページ、オンボーディング完了、プロフドロワー等の表示文言を `Megrum` に変更した。
- ロゴ表示文字を `Mg` に統一した。

#### `web/src/`
- ページ metadata title、Welcome 表示、ヘルプ、法務ページ、サポート表記などのユーザー向け `Megrum` 表示を `Megrum` に変更した。
- Geocoding User-Agent も `Megrum/0.1` に変更した。ドメイン・問い合わせメールは現状の `megrum.tokyo` を維持した。

#### `notes/10_glossary.md`
- プラットフォーム名を `Megrum` として登録し、`Megrum` は旧称として残した。

#### `notes/09_state_machines.md`
- ドキュメント目的文のサービス名を `Megrum` に変更した。

#### `notes/17_legal_alignment.md`
- 法務原典は `Megrum` のまま当面維持し、画面表示名のみ `Megrum` に変えたことを追記した。

### 影響範囲

- iOS版 / Web版のユーザー向けブランド表示
- 法務ページの画面表示
- アプリ名
- ロゴ文字

### 確認方法

- iOS版 Welcome / ヘルプ / 法務ページで `Megrum` 表示になっていることを確認
- Web版 Welcome / metadata title / ヘルプ / 法務ページで `Megrum` 表示になっていることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app.json`
- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/signup.tsx`
- `mobile/app/help.tsx`
- `mobile/app/legal/*.tsx`
- `mobile/src/components/MegrumLogo.tsx`
- `mobile/src/components/LegalDocument.tsx`
- `web/src/app/**/*.tsx`
- `web/src/components/auth/MegrumLogo.tsx`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/17_legal_alignment.md`

### セルフレビュー結果

- ✅ `mobile/app` / `mobile/src` / `web/src` のユーザー向け `Megrum` 表示が残っていないことを `rg` で確認した
- ✅ iOS版 typecheck が成功した
- ⚠️ Web版 lint は `web/node_modules` に `eslint` が無く実行できなかった
- ⚠️ `slug` / `scheme` / `bundleIdentifier` / `megrum.tokyo` / `support@megrum.tokyo` は配信・署名・連絡先の移行判断が必要なため維持した

---

## イテレーション157.3：iOS認証後ホーム遷移のNativeTabs警告を修正

### 背景・問題意識

iOS開発ビルドで認証・プレビュー導線からホームへ遷移する際、`The action 'NAVIGATE' ... Do you have a route named '(tabs)'?` という開発時警告が出ていた。Expo Router の route group と `NativeTabs` の組み合わせで、`router.navigate("/")` が内部グループ `"(tabs)"` への navigate として解決され、現在のナビゲータで処理できないケースがあった。

### 変更内容

#### `mobile/app/(auth)/_layout.tsx`
- 認証済み・プレビュー中のホーム遷移を、imperative な `router.navigate("/")` ではなく `<Redirect href="/" />` に変更した。
- `HomeRedirect` コンポーネントを削除し、認証レイアウトが状態に応じて直接リダイレクトする形にした。

#### `mobile/app/(auth)/login.tsx` / `mobile/app/(auth)/welcome.tsx`
- ログイン成功後・プレビュー開始後の `router.navigate("/")` を削除し、AuthProvider の状態変化を受けたレイアウトRedirectに一本化した。

#### `mobile/app/onboarding/done.tsx` / `mobile/app/settings-privacy.tsx` / `mobile/src/components/RouteHeader.tsx` / `mobile/app/(tabs)/notifications.tsx`
- ホームへ戻る導線を `router.navigate("/")` から `router.replace("/")` に変更した。

#### `mobile/app/proposal-confirm.tsx` / `mobile/app/goods-editor.tsx`
- `/(tabs)` route group を直接指定していた箇所を、公開パスの `/` / `/transactions` / `/inventory` / `/wishes` に変更した。

### 影響範囲

- iOS版 認証・プレビュー導線
- オンボーディング完了後のホーム遷移
- 共通ヘッダーの戻り先フォールバック
- 打診完了後・在庫/Wish編集後のタブ遷移

### 確認方法

- iOS開発ビルドでログインまたはプレビュー開始後、`(tabs)` ナビゲーション警告が出ずにホームへ遷移することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(auth)/_layout.tsx`
- `mobile/app/(auth)/login.tsx`
- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/onboarding/done.tsx`
- `mobile/app/settings-privacy.tsx`
- `mobile/src/components/RouteHeader.tsx`
- `mobile/app/(tabs)/notifications.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ `router.navigate("/")` と `router.replace("/(tabs)")` が残っていないことを `rg` で確認した
- ✅ TypeScript typecheck が成功することを確認した
- ✅ ナビゲーション修正のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の追加更新は不要

---

## イテレーション157.2：EAS依存解決にlegacy-peer-depsを固定

### 背景・問題意識

iOS development build が Apple署名・端末登録までは進む一方、EAS Build の `Install dependencies` フェーズで連続して失敗した。ローカルで `npm ci` を再現すると、Expo Router周辺の peer dependency 解決が `--legacy-peer-deps` なしで走り、ローカルで使っていたインストール条件とEAS上の条件がずれていた。

### 変更内容

#### `.npmrc` / `mobile/.npmrc`
- `legacy-peer-deps=true` を追加し、EAS上の依存インストールでもローカルと同じpeer dependency解決にした。
- npm workspaces 構成では `mobile/.npmrc` が無視される場合があるため、ルート `.npmrc` にも同じ設定を置いた。

#### `mobile/eas.json`
- EAS Build 上で確実に効くよう、development / development-simulator / preview プロファイルに `NPM_CONFIG_LEGACY_PEER_DEPS=true` を追加した。

### 影響範囲

- iOS版 EAS development build
- EAS Build の Install dependencies フェーズ

### 確認方法

- `npm --prefix mobile ci --legacy-peer-deps`
- `npm --prefix mobile run typecheck`
- EASで `eas build --platform ios --profile development --clear-cache`

### 関連ファイル

- `.npmrc`
- `mobile/.npmrc`
- `mobile/eas.json`

### セルフレビュー結果

- ✅ ローカルで `npm ci --legacy-peer-deps` が成功することを確認した
- ✅ TypeScript typecheck が成功することを確認した
- ✅ ビルド環境設定のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の追加更新は不要

---

## イテレーション157.1：ホーム右下操作をiOS純正Liquid GlassとSF Symbolsへ変更

### 背景・問題意識

ホーム画面右下の現地交換操作ボタンについて、オーナーから「っぽい方向へ寄せます、ではなく、ちゃんとリサーチして、本物通りに仕上げて」と指摘があった。独自SVGや文字アイコンではなく、iOS標準の見え方に沿うため、AppleのSF SymbolsとiOS 26 Liquid GlassをExpoのネイティブモジュール経由で使う方針にした。

### 変更内容

#### `mobile/package.json`
- `expo-symbols` を追加し、iOSではSF Symbolsを直接描画できるようにした。
- `expo-glass-effect` を追加し、iOS 26対応環境ではネイティブLiquid Glassを使えるようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム右下の現地交換操作ボタンを、SF Symbolsの `location.circle` / `location.circle.fill` に変更した。
- iOS 26対応端末では `expo-glass-effect` の `GlassView` を使い、未対応・未再ビルド環境では `BlurView` / 既存アイコンへフォールバックする構成にした。
- ActionSheetIOS のメニュー構成は維持し、「現地交換モードをオン/オフ」「現地交換情報を編集する」だけを表示する。

### 影響範囲

- iOS版 ホーム画面
- 右下の現地交換操作ボタン
- 開発ビルドのネイティブ依存関係

### 確認方法

- iOS 26対応実機の開発ビルドでホーム右下ボタンがLiquid Glass表示になることを確認
- iOSでボタン内アイコンがSF Symbolsの位置アイコンになることを確認
- ボタン押下でActionSheetIOSが開き、通知系の余計な項目が出ないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/package.json`
- `mobile/package-lock.json`

### セルフレビュー結果

- ✅ iOS標準に寄せるため、独自アイコンではなくSF Symbolsを使用した
- ✅ iOS 26ではネイティブLiquid Glassを使い、未対応環境では既存UIが壊れないようフォールバックを入れた
- ✅ UI表現のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の追加更新は不要

---

## イテレーション157：推しすれ違いタブとレター課金体験を追加

### 背景・問題意識

オーナーから、現地交換モードとは別に「同担や近い界隈とすれ違う楽しさ」「すれ違うほどパネルが完成していく体験」「届いたメッセージの開封・返信は月額課金」という構想が提示された。交換やグッズ条件はいったん忘れ、利便性よりも推し活の偶然性・蓄積・開封したくなる体験を重視する。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- フッターに `すれ違い` 専用タブを追加した。
- 既存のホーム / 在庫 / Wish / 通知 / 取引タブは維持し、既存画面の取得・取引ロジックには接続しない構成にした。

#### `mobile/app/(tabs)/encounters.tsx`
- 新規に `推しすれ違い` 画面を追加した。
- 同担の存在感・濃いすれ違い・未開封レターのサマリーを表示する。
- 推しごとの `すれ違いパネル` を横スクロールで表示し、ピースが埋まるコレクション体験を追加した。
- `すれ違いレター` は到着・相性・推し傾向・ぼかした場所/時刻のみ無料表示し、本文開封と返信は Plus 導線へ分離した。
- 課金は単発チケットなし、月額1000円のみの設計で表示した。
- 送信側は無料枠2通/月とし、追加送信枠は Plus 対象として表示した。
- 位置と時刻はぼかす前提を画面内で明示した。

#### `notes/10_glossary.md`
- `推しすれ違い` / `すれ違いパネル` / `すれ違いレター` / `推しすれ違い Plus` を追加した。

#### `notes/09_state_machines.md`
- `Oshi Encounter Letter Lifecycle` を追加し、`received_locked` / `opened` / `replied` / `hidden` / `archived` を定義した。

### 影響範囲

- iOS版 フッター
- iOS版 推しすれ違い画面
- 新規ソーシャル体験の用語・状態定義

### 確認方法

- iOS実機でフッターに `すれ違い` タブが出ることを確認
- `すれ違い` タブでパネル・未開封レター・月額1000円プラン・月2通の送信枠が表示されることを確認
- Plusプレビュー切替後、レター本文と返信導線が表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/encounters.tsx`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存の交換・打診・取引データ取得には接続せず、新規タブとして分離した
- ✅ 月額1000円のみ、単発開封チケットなし、送信無料枠2通/月の仕様を画面に反映した
- ✅ レター本文と返信はPlus導線に分離し、到着・相性・ぼかした場所/時刻だけ無料表示にした
- ✅ 新用語とレター状態遷移を `notes/10_glossary.md` / `notes/09_state_machines.md` に記録した

---

## イテレーション156.23：ホームヘッダー実験を撤去し上端フェードだけに戻す

### 背景・問題意識

ホーム画面のヘッダーBlur/モザイク実験が実機で不自然な表示になり、見出しタイトルが隠れる・灰色帯が出る・モザイクが荒いなど、ユーザー体験を大きく損ねていた。オーナーから「どういう感じにするかまずここで教えろ」「やって今すぐ」と指示があったため、複雑な固定ヘッダー制御を撤去し、通常のスクロール見出しへ戻す。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 多段 `BlurView` による `HeaderGradientOverlay` を撤去した。
- `マッチしてるよ！` / `交換できるかも` はスクロール内の通常見出しとして維持した。
- 画面最上部だけ、白から透明へ細かく抜ける `TopEdgeFade` に置き換えた。
- 見出しタイトルの固定化・入れ替え・背面Blur制御は追加しない方針に戻した。

### 影響範囲

- iOS版 ホーム画面
- ホーム上部のステータスバー保護表示
- `マッチしてるよ！` / `交換できるかも` の見出し表示

### 確認方法

- 実機でホームを開き、見出しが通常のスクロール内表示に戻っていることを確認
- 画面上部に灰色帯や粗いモザイクが出ないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 複雑な固定ヘッダー/Blur実験を撤去した
- ✅ 見出しタイトルをスクロール内の通常表示に戻した
- ✅ UI表現のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.22：ホーム見出しを元に戻し上部だけ細密グラデーション透過

### 背景・問題意識

固定ヘッダー上で見出しタイトルを入れ替える方式は、実機で不自然な表示になり、オーナーから「元に戻してください。ヘッダー部分だけ、すごく細かいグラデーション透過になるように」と指摘があった。外部資料として、CSS の多段 color stop による透明グラデーション表現と、Expo `BlurView` の「下にあるものをぼかす」仕様を参照し、React Native では細かいバンドを積む形に置き換える。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 固定ヘッダーで `マッチしてるよ！` / `交換できるかも` を入れ替える仕組みを撤去した。
- スクロール内の見出しタイトル表示を復元した。
- 画面上部のヘッダー領域だけに `HeaderGradientOverlay` を追加した。
- `HeaderGradientOverlay` は 28 段の細かい `BlurView` バンドで構成し、上ほど強く、下ほど透明に近づくようにした。

### 影響範囲

- iOS版 ホーム画面
- ホーム上部のグラデーション透過Blur
- `マッチしてるよ！` / `交換できるかも` の通常見出し表示

### 確認方法

- 実機でホームを開き、見出しタイトルがスクロール内に通常表示されることを確認
- 画面上部ヘッダー部分だけに細かいグラデーション透過Blurが載ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 固定ヘッダーのタイトル入れ替え方式を撤去し、見出し表示を元に戻した
- ✅ ヘッダー部分だけに細密な多段Blurバンドを適用した
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.21：ホーム見出しを固定ヘッダーへ一本化

### 背景・問題意識

固定グラデーションヘッダーを追加した後も、スクロール内の見出しタイトルが残っていたため、固定ヘッダー上のタイトルとスクロール内タイトルが重なり、不自然な表示になっていた。また、`Screen` 側の top padding の内側からヘッダーが始まっていたため、ステータスバー周辺まで素材が届きにくかった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- `Screen` の top padding を 0 にし、固定グラデーションヘッダーが画面最上部から始まるようにした。
- スクロールコンテンツ側の top padding を固定ヘッダー高さに合わせて動的に付与し、カードや行タイトルがヘッダー下から始まるようにした。
- スクロール内のセクション見出しテキストを描画しないようにし、固定ヘッダー上のタイトルだけを表示する構造にした。
- スクロール内見出しは、タイトル切り替え判定用の透明な `sectionAnchor` として残した。

### 影響範囲

- iOS版 ホーム画面
- 固定ヘッダーのタイトル表示
- ホーム上部のブラー/モザイク到達範囲

### 確認方法

- 実機でホームを開き、スクロール内と固定ヘッダーで見出しが二重表示されないことを確認
- 固定ヘッダーがステータスバー周辺まで伸びていることを確認
- スクロールに応じて固定ヘッダーのタイトルだけが `マッチしてるよ！` / `交換できるかも` に切り替わることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 見出しタイトルの描画元を固定ヘッダーへ一本化した
- ✅ スクロール内見出しは透明アンカーにし、切り替え判定だけ担わせる構造にした
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.20：ホーム見出しを固定グラデーションヘッダーに分離

### 背景・問題意識

見出しごとの背面Blurでは、見出しタイトル自体がBlur素材の中に巻き込まれ、スクロール中に完全に見えなくなることがあった。オーナーから「ヘッダー自体をグラデーション透過にし、見出しタイトルはその上のレイヤーへ置き、スクロールに従って見出しタイトルが入れ替わる」という方針が提示されたため、見出し表示と背景素材を完全に分離する。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 見出しごとにBlurを持たせる実装を撤去し、画面上部に固定の `HomeGradientHeader` を追加した。
- `HomeGradientHeader` の背景は、上ほど強く下ほど透明になる細かい複数段の `BlurView` バンドで構成した。
- 見出しタイトルはBlurレイヤーより上に別レイヤーで配置し、素材レイヤーに巻き込まれて消えないようにした。
- `Animated.ScrollView` のスクロール位置と各セクション見出しの `layoutY` を使い、固定ヘッダー上のタイトルが `マッチしてるよ！` / `交換できるかも` に切り替わるようにした。

### 影響範囲

- iOS版 ホーム画面
- ホーム上部の固定ヘッダー
- `マッチしてるよ！` / `交換できるかも` の見出し切り替え

### 確認方法

- 実機でホームをスクロールし、上部ヘッダー背景が上ほど強いグラデーション透過Blurになることを確認
- 見出しタイトルがBlurに巻き込まれず常に前面で読めることを確認
- セクションの切り替わりに合わせて固定ヘッダーのタイトルが入れ替わることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 背景素材レイヤーと見出しテキストレイヤーを分離した
- ✅ Blurを細かい複数段バンドにし、単一の均一Blurからグラデーション透過ヘッダーへ変更した
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.19：ホームBlurを上方向へ強まる段階素材に変更

### 背景・問題意識

ホームの見出し背面Blurは方向性として良くなったが、下スクロール時に画面上部のステータスバー周辺がBlurにならず、見出し背面も均一にぼけていた。オーナーから「下から上部にかけてどんどんぼやけていく感じ」と指摘があったため、Blurを1枚ではなく複数段の素材レイヤーとして扱う。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- スクロール量に応じて画面上部へフェードインする `homeStatusMaterial` を追加した。
- `ProgressiveBlurMaterial` を追加し、上ほど強く下ほど弱い5段の `BlurView` バンドで素材感を作るようにした。
- `StickySectionHeader` の背面Blurも `ProgressiveBlurMaterial` へ置き換え、均一なぼけから上方向へ強まるぼけに変更した。

### 影響範囲

- iOS版 ホーム画面
- ステータスバー周辺のスクロール連動Blur
- `マッチしてるよ！` / `交換できるかも` の見出し背面Blur

### 確認方法

- 実機でホームを下スクロールし、画面上部にもBlurが出ることを確認
- 見出し背面のBlurが均一ではなく、下から上へ強まるように見えることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 画面上部の素材レイヤーをスクロール連動で追加した
- ✅ `BlurView` を複数段に分け、均一な灰色帯ではなく上方向へ強まる表現にした
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.18：ホーム見出し背面だけを段階Blur化

### 背景・問題意識

ホーム上部のブラーを画面最上部へ常時貼る実装では、見出しが潜ったり、カードが中途半端に隠れたりして不自然だった。オーナーから「見出しタイトルのところは背景透明で固定し、その一個前のレイヤーに徐々にBlurをかける」という案が提示されたため、見出し自体と背面の素材レイヤーを分離する。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム最上部に常時出していた `BlurView` オーバーレイを撤去した。
- `ScrollView` を `Animated.ScrollView` に変更し、スクロール量 `scrollY` を取得するようにした。
- `StickySectionHeader` に `layoutY` と `scrollY` を渡し、見出しが固定位置へ近づくにつれて背面レイヤーだけ `BlurView` がフェードインするようにした。
- 見出しタイトル自体は透明背景のまま前面に置き、文字の可読性を残した。

### 影響範囲

- iOS版 ホーム画面
- `マッチしてるよ！` / `交換できるかも` の sticky header 表現
- ホーム上部のブラー/モザイク表現

### 確認方法

- 実機でホームを開き、見出しタイトルが背景透明のまま固定されることを確認
- スクロールが進むにつれ、見出し背面だけに薄く `BlurView` が出ることを確認
- 見出しの文字がカード画像に潜らず読めることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 見出しテキスト層とブラー層を分離し、常時最上部にブラーを貼る不自然な構造を撤去した
- ✅ `BlurView` は見出しの背面レイヤーとして使い、下の実コンテンツをぼかす用途に戻した
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.17：公式仕様に合わせたホームBlurとNativeTabsスクロール構造

### 背景・問題意識

ホーム上部がモザイク/ブラーにならず、単にコンテンツがステータスバー裏へ入り込む状態になっていた。またフッターの `NativeTabs minimizeBehavior="onScrollDown"` も、在庫 / Wish では下スクロールしても左下へ集約されなかった。Expo公式では `BlurView` は下にあるものをぼかす用途で、動的コンテンツの後に描画する必要がある。また `NativeTabs` の minimize は iOS 26+ のネイティブ挙動で、スクロール対象が画面内で素直に検知できる構造である必要がある。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部に `expo-blur` の `BlurView` をスクロールコンテンツの後置きオーバーレイとして追加した。
- 公式の「下にあるものをぼかす」構造に合わせ、疑似画像背景ではなく実コンテンツの上に `systemChromeMaterialLight` を重ねる形にした。

#### `mobile/app/(tabs)/inventory.tsx`
- 画面直下の最初のスクロール対象を縦 `ScrollView` に変更し、`NativeTabs` が下スクロールを検知しやすい構造へ寄せた。
- ヘッダーと上部タブは root `ScrollView` の sticky header にまとめた。
- 内側の縦 `ScrollView` を撤去し、表示中タブのグリッドを root `ScrollView` 上に直接描画するようにした。
- タブ横スワイプはジェスチャーで維持した。

#### `mobile/app/(tabs)/wishes.tsx`
- 在庫と同様、画面直下の最初のスクロール対象を縦 `ScrollView` に変更した。
- ヘッダーと上部タブを sticky header 化し、Wish / 個別募集の中身を root `ScrollView` 上に直接描画するようにした。
- 横スワイプによる Wish / 個別募集切り替えは維持した。

### 影響範囲

- iOS版 ホーム画面上部のブラー
- iOS版 マイ在庫 / Wish のフッター最小化
- 在庫 / Wish の上部ヘッダー・タブ・縦スクロール構造

### 確認方法

- 実機でホームを開き、上部ステータスバー付近に `BlurView` のぼかしが出ることを確認
- 在庫 / Wish で下へスクロールし、iOS 26+ 環境で `NativeTabs` が `onScrollDown` に反応して畳まれることを確認
- 在庫 / Wish で横スワイプによるタブ切り替えが残っていることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ `BlurView` は公式推奨どおり、動的なスクロールコンテンツの後に描画して下の内容をぼかす構造にした
- ✅ `NativeTabs` は公式の iOS 26+ `minimizeBehavior="onScrollDown"` を維持し、独自フッター化していない
- ✅ 在庫 / Wish のスクロール構造を、ネイティブタブが検知しやすい root `ScrollView` に寄せた
- ✅ UI構造の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.16：ホーム上部の疑似ブラー背景を撤去

### 背景・問題意識

ホーム上部ヘッダーを参考画像へ寄せるために疑似的な候補画像背景を敷いたが、実機では「変な感じ」になり、参考のInstagram系UIとは根本的に違う見え方になった。調査した結果、iOS/Instagram系の見え方は、ヘッダー背景を別素材で作るのではなく、スクロール中の本物のコンテンツをバーの背後まで流し、その上に半透明/ブラーのバーを重ねる構造であると整理した。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 上部に候補カード由来の疑似背景を敷く `HomeHeaderAmbient` を撤去した。
- ホーム上部に固定表示していた `homeHeaderGlassBridge` を撤去した。
- `StickySectionHeader` ごとの全幅ブラー/灰色帯を撤去し、セクションタイトル自体は透明背景で表示するよう戻した。
- `BlurView` を背景素材づくりに使う実装を外し、今後は「本物のスクロールコンテンツを背後へ流す」構造へ寄せる前提に戻した。

### 影響範囲

- iOS版 ホーム画面
- ホーム上部の背景表現
- `マッチしてるよ！` / `交換できるかも` の sticky header 背景

### 確認方法

- 実機でホームを開き、上部の変な疑似画像背景と灰色のタイトル帯が消えていることを確認
- `マッチしてるよ！` / `交換できるかも` が透明背景で表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 参考画像から遠ざけていた疑似背景と全幅の灰色ブラー帯を撤去した
- ✅ iOS/Instagram系の基本構造である「本物のコンテンツを背後に流す」方向へ設計を戻した
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.15：ホーム上部ブラーを参考画像寄せに再調整

### 背景・問題意識

ホーム画面の上部ヘッダーについて、修正後アプリと参考画像を比較すると、アプリ側は「白い半透明の板」が大きく被さり、`マッチしてるよ！` の文字までブラーの下に沈んでいた。参考画像は、背後の写真グリッドが上端まで流れ込み、それをガラスが自然にぼかしている見え方であり、現状は構造・強度ともに違っていた。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 上部の常時ブラー領域を短くし、セクションタイトルを覆って文字がぼける状態を解消した。
- 上部ブラーの背後に、ホーム候補カードから作る `HomeHeaderAmbient` を追加し、白地ではなくカード画像/色がにじむ下地にした。
- `StickyGlassBackground` の白い wash / band / shade を大幅に薄くし、参考画像のように背後の情報が残るブラーへ寄せた。

### 影響範囲

- iOS版 ホーム画面
- ホーム上部のステータスバー付近のブラー
- `マッチしてるよ！` / `交換できるかも` の sticky header 背景

### 確認方法

- 実機でホームを開き、上部が白い板ではなくカード画像由来のにじみになることを確認
- `マッチしてるよ！` の文字がブラー下に沈まず、前面で読めることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 参考画像との差分だった「白い大きな覆い」「タイトルのブラー沈み」を解消する方向へ修正した
- ✅ iOS標準寄りの `BlurView` は維持し、独自タイルモザイクには戻していない
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.14：NativeTabs直返しとプロフドロワー分離

### 背景・問題意識

在庫 / Wish の実機確認で、ヘッダーは旧構造へ戻した一方、フッターがまだ下スクロールで畳まれないことが確認された。旧版では `(tabs)/_layout.tsx` が `NativeTabs` を直返ししていたが、現行版ではプロフドロワーのために `NativeTabs` 全体を `View` で包んでおり、iOS のネイティブタブ最小化がスクロール連動を拾えない可能性が高い。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- `ProfileDrawerHost` で `NativeTabs` を包む構造をやめ、`NativeTabs` を旧版に近い形で直返しする構造へ戻した。
- プロフドロワーは `ProfileDrawerOverlay` として `NativeTabs` の兄弟に分離し、左端スワイプの導線とドロワー表示は維持した。
- ドロワーのルートを `pointerEvents="box-none"` の絶対配置オーバーレイにし、通常時にタブ/画面側のスクロール検知を邪魔しないようにした。

### 影響範囲

- iOS版 全タブのフッター最小化
- 左端スワイプのプロフドロワー
- `NativeTabs` のネイティブスクロール連動

### 確認方法

- 実機で在庫 / Wish を開き、下スクロール時にフッターが畳まれることを確認
- 左端から右スワイプしてプロフドロワーが従来どおり開くことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ iOS標準の `NativeTabs` を最優先し、独自ラッパーで包まない構造へ戻した
- ✅ プロフドロワーは機能を残したまま、ネイティブタブのスクロール連動を阻害しにくい兄弟オーバーレイへ分離した
- ✅ UI構造の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.13：ホーム固定ヘッダーをiOSブラーへ刷新

### 背景・問題意識

ホーム画面の固定ヘッダーについて、オーナーからInstagram風の参考画像が共有され、「こんな感じにして欲しい」と指摘があった。従来のタイル状モザイクは粗く、背景のコンテンツが自然ににじむ表現ではなかったため、iOSらしいブラー表現へ置き換える。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- `expo-blur` の `BlurView` を使い、ホーム上部と sticky section header の背景を本物のブラーへ変更した。
- タイル状モザイクの生成ロジックを撤去し、上ほど白の重なりが強く、下へ自然にフェードする半透明バンドへ置き換えた。
- `マッチしてるよ！` / `交換できるかも` の固定ヘッダーが、参考画像のように背後のカードをぼかして受ける見た目になるよう調整した。

#### `mobile/package.json`
- ホームヘッダーのネイティブブラー用に `expo-blur` を追加した。

### 影響範囲

- iOS版 ホーム画面
- sticky header の背景表現
- ホーム上部のステータスバー付近の半透明ブラー

### 確認方法

- ホーム画面を開き、上部の固定ヘッダーがタイル状ではなく滑らかなブラーになっていることを確認
- `マッチしてるよ！` / `交換できるかも` が sticky になった時、背後のカードが自然にぼけることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/package.json`

### セルフレビュー結果

- ✅ 参考画像に合わせ、粗いモザイクではなく `BlurView` によるブラー表現へ変更した
- ✅ iOS標準寄りのネイティブ表現を優先し、独自の擬似モザイクを撤去した
- ✅ UI表現の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.12：在庫Wishを旧NativeTabs時代の構造へ戻す

### 背景・問題意識

在庫とWishのヘッダー収納を独自の固定オーバーレイで制御しようとした結果、昔「フッターにプロフがあった時」に自然に動いていた構造から離れ、ヘッダー固定やフッター最小化の挙動が不安定になった。オーナーから「昔、フッターにプロフがあったときのヘッダーをそのまま再現してくれたらいい。過去のVerを参照して」と指摘があったため、旧 `NativeTabs` 時代の `Screen` ベース構造を再参照した。

### 変更内容

#### `mobile/app/(tabs)/inventory.tsx`
- 固定オーバーレイ式のヘッダー収納実装を外し、旧実装と同じ `Screen scroll={false}` + 上部ヘッダー + 横ページャー + ページ内縦 `ScrollView` 構造へ戻した。
- 上部タブのインジケータだけは、横スワイプ中に追従するよう `SectionTabs` の `position` 連動を残した。
- 削除フェードや確認モーダルなど、既存の現在版機能は維持した。

#### `mobile/app/(tabs)/wishes.tsx`
- 固定オーバーレイ式のヘッダー収納実装を外し、旧実装と同じ `Screen scroll={false}` + ヘッダー + `SectionTabs` + コンテンツ内縦 `ScrollView` 構造へ戻した。
- Wish / 個別募集の手動横スワイプ切り替え、削除フェード、個別募集デッキ表示は維持した。
- 同一グッズが複数表示される場合の duplicate key warning を避けるため、重複し得る描画箇所だけ index 付き key にした。

### 影響範囲

- iOS版 マイ在庫一覧
- iOS版 Wish / 個別募集一覧
- 上部ヘッダー、上部タブ、各タブ内スクロール

### 確認方法

- 過去版 `04767dd` の `mobile/app/(tabs)/inventory.tsx` / `wishes.tsx` と構造を比較
- 在庫 / Wish のヘッダーが固定オーバーレイ由来の揺れを起こさないことを確認
- Wish / 個別募集の削除・編集・表示が維持されていることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ 独自フッター化はせず、iOS標準 `NativeTabs` / Liquid Glass は維持した
- ✅ 旧NativeTabs時代の `Screen` ベース構造へ戻し、固定オーバーレイ制御を撤去した
- ✅ UI構造の調整のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.11：在庫Wishヘッダー収納の高速スクロール反動を抑制

### 背景・問題意識

在庫とWishの一覧画面で、ゆっくり下にスクロールするとヘッダーは収まるが、勢いよく下へスクロールすると画面が「ガガガガッ」と揺れ、最終的にヘッダーが再表示されてしまう問題があった。原因は、ヘッダーを畳む高さアニメーションがコンテンツ高さを変え、その直後の `contentOffset` 補正や下端バウンスを「上スクロール」と誤判定していたこと。

### 変更内容

#### `mobile/app/(tabs)/inventory.tsx`
- ヘッダー開閉直後の短時間は、反動由来の上方向デルタで再表示しないようにした。
- 下端バウンス付近の上方向デルタをヘッダー再表示判定から除外した。
- ヘッダー再表示は、一定量以上の上スクロールが蓄積された時だけ行うようにした。
- 新しい開閉アニメーション開始時に既存アニメーションを止め、競合を抑えた。

#### `mobile/app/(tabs)/wishes.tsx`
- 在庫と同じヘッダー収納判定を適用し、高速スクロール時の再表示揺れを抑えた。

### 影響範囲

- iOS版 マイ在庫一覧
- iOS版 Wish / 個別募集一覧
- 下スクロール時のヘッダー収納と、上スクロール時のヘッダー再表示

### 確認方法

- 在庫 / Wish で下方向へ勢いよくフリックし、ヘッダーが途中で再表示されず収まることを確認
- ゆっくり下へスクロールしても従来通りヘッダーが収まることを確認
- 上方向へ明確に戻した時はヘッダーが再表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ `NativeTabs` / Liquid Glass フッターは維持し、独自フッター化していない
- ✅ 高速スクロール時の反動・下端バウンスをヘッダー再表示に使わないようにした
- ✅ UI挙動の調整のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.10：NativeTabs最小化の対象ScrollViewを主要タブで先頭化

### 背景・問題意識

iOS版のフッターは最新iOSの `NativeTabs` / Liquid Glass を使い、下スクロール時に現在タブのアイコンへ畳まれる標準挙動を期待している。しかし、ホーム以外の主要タブでは画面の先頭にヘッダーや横ページャーがあり、react-native-screens が `first descendant chain` で実際の縦 `ScrollView` を見つけられず、フッターが「左に一つへ集約」されない状態だった。

### 変更内容

#### `mobile/app/(tabs)/inventory.tsx`
- `NativeTabs` は維持したまま、画面の最初の実子を縦 `ScrollView` に変更した。
- 在庫ステータスの横スワイプページャーは外側の縦 `ScrollView` 内に残し、各ページの内側縦 `ScrollView` を廃止した。
- 既存のヘッダー折りたたみ判定は、外側の縦 `ScrollView` の `onScroll` で受けるようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish / 個別募集画面も、最初の実子を縦 `ScrollView` に変更した。
- 横スワイプ中に上部タブが追従する既存の `Animated.ScrollView` は維持しつつ、内側の縦 `ScrollView` を外側へ集約した。

#### `mobile/app/(tabs)/transactions.tsx`
- 取引一覧も、最初の実子を縦 `ScrollView` に変更した。
- 打診中 / 進行中 / 完了の横スワイプページャーは維持し、各ページ内のリストは外側の縦スクロールに載せた。

### 影響範囲

- iOS版 マイ在庫 / Wish / 取引一覧
- iOS NativeTabs の `minimizeBehavior="onScrollDown"` 発火条件
- 各画面の横スワイプページャーと上部タブ追従

### 確認方法

- iOS開発ビルドで在庫 / Wish / 取引一覧を開き、下スクロール時にNativeTabsフッターが現在タブのアイコンへ畳まれることを確認
- 上スクロールで通常のLiquid Glassフッターへ戻ることを確認
- 各画面の横スワイプ切り替えが維持されていることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ 独自フッター化せず、既存のiOS `NativeTabs` / Liquid Glassフッターを維持した
- ✅ ネイティブタブ側の `first descendant chain` 条件に合わせ、主要タブの最初の実子を縦 `ScrollView` にした
- ✅ 横スワイプページャーと上部タブ追従は残した
- ✅ UI構造の調整のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.09：iOS標準コンポーネント優先ルールをBootstrapへ明文化

### 背景・問題意識

iOS版のフッター最小化挙動について、既存の `NativeTabs` を維持すべき場面で、独自フッター実装へ倒れかけた。iOSアプリでは、最新iOSの標準コンポーネントやネイティブ挙動をできるだけ採用し、標準で実現できるものを独自実装で置き換えないことを、今後の基本ルールとして明文化する必要があった。

### 変更内容

#### `CLAUDE.md`
- 「iOSネイティブ標準コンポーネント優先（最重要）」を追加した。
- `NativeTabs` / iOS標準タブバー、`ActionSheetIOS`、iOS標準シート、標準戻る遷移、標準スクロール連動、Apple Map などを優先する方針を明記した。
- iOS標準を捨てる可能性がある指示が来た場合、実装前にオーナーへ確認するルールを明記した。

#### `AGENTS.md`
- Codex側にも同じルールを追加し、Claude / Codex のどちらが作業しても判断基準が揃うようにした。

### 影響範囲

- iOSアプリ実装全般
- フッター、シート、アクションメニュー、地図、画面遷移、スクロール連動などの設計判断
- Claude / Codex の作業ルール

### 確認方法

- `CLAUDE.md` と `AGENTS.md` に同一方針が追記されていることを確認
- 今後、iOS標準コンポーネントを独自実装へ置き換える前に、標準側の設定・制約を調査すること

### 関連ファイル

- `CLAUDE.md`
- `AGENTS.md`

### セルフレビュー結果

- ✅ Claude / Codex の両Bootstrapに同じルールを記載した
- ✅ オーナー指示がルールに反する可能性がある場合の確認義務を明記した
- ✅ 作業ルールの追記のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.08：NativeTabs最小化の前提に合わせてホームのScrollView配置を補正

### 背景・問題意識

iOS版のフッターは `NativeTabs` の `minimizeBehavior="onScrollDown"` を使い、下スクロール時に現在タブのアイコンへ畳まれるネイティブ挙動を期待している。以前のプロフ画面ではこの挙動が出ていたが、ホームでは発火していなかった。調査すると、react-native-screens / React Navigation の Native Bottom Tabs は、タブ画面から見た `first descendant chain` にある `ScrollView` を対象にインセット調整やスクロール連動を行う仕様だった。ホームでは装飾用の `homeHeaderMosaicBridge` が `ScrollView` より前にあり、最初の子孫チェーンがスクロールビューに到達していなかった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- `NativeTabs` フッターは維持したまま、ホームのメイン `ScrollView` が `Screen` 内の最初の実子になるよう配置を変更した。
- `homeHeaderMosaicBridge` は見た目を変えず、`ScrollView` の後ろに回して absolute / zIndex で背景として表示する構造にした。

### 影響範囲

- iOS版 ホーム画面
- iOS NativeTabs の `minimizeBehavior="onScrollDown"` 発火条件

### 確認方法

- ホーム画面で下スクロールし、NativeTabs フッターが右端の現在タブアイコンへ畳まれることを確認
- 上スクロールで通常のフッターへ戻ることを確認
- 上部モザイク背景の見た目が維持されていることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/node_modules/@react-navigation/bottom-tabs/src/unstable/types.tsx`
- `mobile/node_modules/react-native-screens/src/components/bottom-tabs/BottomTabsScreen.types.ts`

### セルフレビュー結果

- ✅ 独自フッター化ではなく、既存の iOS NativeTabs / Liquid Glass フッターを維持した
- ✅ ローカルのライブラリ型定義で確認した `first descendant chain` 条件に沿って修正した
- ✅ UI構造の調整のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.07：ホーム固定ヘッダーのモザイク粒度と上部連続性を調整

### 背景・問題意識

ホーム画面で「マッチしてるよ」「交換できるかも」が固定ヘッダーになった際、モザイクの粒が大きく、半透明ブロックの柄に見えてしまっていた。また、タイトル直上の固定領域が単色の覆いに見え、モザイク背景がそこで途切れているように見える問題があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 固定ヘッダーのモザイクを 5行×14列から 10行×36列へ細分化し、粒を小さくした。
- モザイクの色・透明度の出方を deterministic にばらけさせ、粗い横帯に見えにくくした。
- 固定ヘッダー内の強い単色 wash / veil を削除し、モザイク自体で薄く背景を作るようにした。
- ホーム上部の safe-area 側に `homeHeaderMosaicBridge` を追加し、タイトル直上の固定色領域にも同じ細かいモザイクが見えるようにした。

### 影響範囲

- iOS版 ホーム画面
- ホームの sticky section header（マッチしてるよ / 交換できるかも）

### 確認方法

- ホームをスクロールし、「マッチしてるよ」「交換できるかも」が固定された時のモザイク粒が細かくなっていることを確認
- タイトル直上の領域が単色帯ではなく、同じモザイク表現でつながって見えることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ モザイク粒度と色のばらけ方だけを調整し、ホームの既存スクロール・カード挙動には触れていない
- ✅ 上部 safe-area 側も同じ `StickyMosaicBackground` を再利用し、別表現を増やさない形にした
- ✅ UI表現のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.06：iOSフッター左シュッ挙動のスクロール連動補正

### 背景・問題意識

iOS版のフッターは `NativeTabs` の `minimizeBehavior="onScrollDown"` で、下スクロール時に左へシュッとまとまる挙動にしている。しかし、React Native の `ScrollView` は標準で `contentInsetAdjustmentBehavior` が `never` になり、ネイティブタブ側がスクロールビューを十分に連動できない画面があった。特にプロフ画面で以前見えていたようなフッター最小化が、他画面で再現されないことが問題になった。

### 変更内容

#### `mobile/src/components/Screen.tsx`
- 共通 `Screen` の縦スクロールに `contentInsetAdjustmentBehavior="automatic"` と `automaticallyAdjustsScrollIndicatorInsets` を追加した。
- プロフ・通知など、共通 `Screen` のスクロールを使う画面でネイティブタブのスクロール連動を拾いやすくした。

#### `mobile/app/(tabs)/index.tsx`
- ホームのメイン縦スクロールに同じiOSスクロール連動設定を追加した。

#### `mobile/app/(tabs)/inventory.tsx`
- 各在庫ステータスページの縦スクロールに同じiOSスクロール連動設定を追加した。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish / 個別募集ページの縦スクロールに同じiOSスクロール連動設定を追加した。

#### `mobile/app/(tabs)/transactions.tsx`
- 取引一覧の各タブページの縦スクロールに同じiOSスクロール連動設定を追加した。

### 影響範囲

- iOS版 全フッター表示画面
- ホーム / マイ在庫 / Wish / 通知 / 取引 / 自分プロフィールのスクロール時フッター挙動

### 確認方法

- iOS開発ビルドで各タブを開き、下スクロール時にフッターが左へシュッとまとまることを確認
- 上スクロールでフッターが元の表示へ戻ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/src/components/Screen.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ Expo Router / React Navigation 側の型定義にある `contentInsetAdjustmentBehavior="automatic"` 要件に合わせた
- ✅ 独自フッターを重ねるのではなく、iOS NativeTabs の本物の最小化挙動を活かす修正にした
- ✅ スクロール連動設定のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.05：iOS譲るグッズ登録の写真複数選択

### 背景・問題意識

譲るグッズを写真から登録する時、写真ライブラリで1枚ずつしか選べないと、同じ推し・同じ種別のグッズをまとめて登録する体験が重くなる。既存のiOS在庫新規登録フローは、内部的には複数写真を `photos` と `metas` で扱い、写真ごとに1件ずつ登録できる構造だったが、ライブラリピッカーの `allowsMultipleSelection` が無効になっていた。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫新規登録フローの写真ライブラリ選択で `allowsMultipleSelection: true` を有効化した。
- iOSで選択順が分かるよう `orderedSelection: true` を指定し、選んだ順にラベル設定へ進めるようにした。
- 複数選択と相互排他になるため、ライブラリ選択時の `allowsEditing` は `false` にした。
- 写真選択画面の説明文とボタン文言を「複数枚を一度に選べる」内容に更新した。

### 影響範囲

- iOS版 マイ在庫 > 譲る候補 > 追加 > 写真を選ぶ
- 写真ライブラリからの在庫一括登録

### 確認方法

- マイ在庫の譲る候補で「追加」から新規登録へ進み、写真ライブラリで複数枚を選べることを確認
- 複数枚選択後、アップロード済み枚数が増え、ラベル設定で写真ごとに1件ずつ設定できることを確認
- カメラ撮影は従来通り1枚ずつ追加できることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ 既存の複数写真登録ロジックを活かし、入口のピッカー設定だけを複数選択対応にした
- ✅ 複数選択時はトリミング非対応というExpo/iOS制約に合わせ、ライブラリ側だけ `allowsEditing` を無効化した
- ✅ UI/入力挙動のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.04：iOS自分プロフィール画面を公開プロフ中心に再構成

### 背景・問題意識

左端プロフィールドロワーの「プロフィール」から遷移する画面が必要になった。既存のiOS `profile` 画面は、プロフィール編集・推し設定・通知設定などの設定ハブ寄りで、ユーザーが「自分のプロフィールとして他人にどう見えるか」を確認する画面としては弱かった。Web版の自分プロフは、hero、評価、推し、スケジュール、各設定導線を持つため、iOS版もまず公開プロフィールとして見える情報を前面に出す必要があった。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- 自分プロフィール画面を作り直し、ドロワーの「プロフィール」から開く閲覧用の自分プロフにした。
- heroにアバター、ハンドル、表示名、エリア、取引回数、評価サマリを表示するようにした。
- 評価 / 取引 / 譲る候補 / 個別募集のミニ統計を追加した。
- 自分の `for_trade + active` な在庫を「譲る候補」としてグリッド表示し、タップで在庫編集へ進めるようにした。
- 推しサマリ、プロフィール編集、推し設定、スケジュール、通知設定、ヘルプ、ログアウト導線を残した。
- Supabaseから `users` / `user_oshi` / `proposals` / `listings` / `user_evaluations` / `goods_inventory` を読み込み、自分用の画面データを構築するようにした。

### 影響範囲

- iOS版 左端プロフィールドロワー > プロフィール
- iOS版 自分プロフィール
- iOS版 自分の譲る候補プレビュー

### 確認方法

- 左端ドロワーから「プロフィール」を押し、自分プロフィール画面が開くことを確認
- 評価サマリ、取引数、譲る候補、個別募集数が表示されることを確認
- 譲る候補のカードを押すと該当在庫編集へ進むことを確認
- プロフィール編集、推し設定、スケジュール、通知設定、ヘルプ、ログアウトがそれぞれ動くことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `web/src/app/profile/ProfileView.tsx`

### セルフレビュー結果

- ✅ 自分プロフィールを設定ハブではなく、公開プロフ確認を主目的にした
- ✅ Web版の自分プロフで使っている評価・取引・推し・編集導線の構成をiOS版へ反映した
- ✅ 既存DB列の参照のみで新しい状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.03：プロフィールドロワーの白フラッシュ抑止

### 背景・問題意識

左端からプロフィールドロワーを出す時、スワイプ開始直後に画面が一瞬白くなるとユーザーから指摘があった。原因は、エッジスワイプ開始時に `visible=true` へ変えた瞬間、位置同期用の `useEffect` がドロワーの `translateX` を開いた状態へ即時リセットしていたため、指に追従する前に白いドロワー面が一瞬全面に出ていたこと。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- ドロワーの表示状態変更では `translateX` をリセットしないよう、`visibleRef` を使って幅変更時だけ位置を同期する構造にした。
- `drawerHost` に背景色を指定し、ネイティブ描画の隙間にもアプリ背景色が出るようにした。

### 影響範囲

- iOS版 全タブ共通の左端プロフィールドロワー
- エッジスワイプ開始時の描画

### 確認方法

- ホーム/在庫/Wish/通知/取引の各画面で左端からゆっくりスワイプし、白いフラッシュが出ないことを確認
- ドロワーを途中で戻した時、閉じた後に再度スワイプしても位置が破綻しないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ スワイプ開始時の位置ジャンプをなくし、指の動きに沿ってドロワーが出るようにした
- ✅ ドロワーの表示内容・遷移先・フッター構成には触れていない
- ✅ UI挙動のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.02：ホーム固定見出しのモザイク背景

### 背景・問題意識

ホームの「マッチしてるよ！」「交換できるかも」を固定見出しにしたところ、背景が単純な半透明ベタになっていた。ユーザーから、固定ヘッダー部分は下から上にいくにつれて強さが増す半透明のモザイクがかかるようにしたいと要望があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- `StickySectionHeader` 内に `StickyMosaicBackground` を追加した。
- 依存追加なしで、半透明タイルを複数行に敷き、上側ほどopacityが強くなる疑似モザイク背景にした。
- 見出し背景のベタ塗りを弱め、モザイク層と薄い上部ウォッシュでガラス越しの固定ヘッダーに見えるよう調整した。

### 影響範囲

- iOS版 ホーム
- ホームの固定セクション見出し背景

### 確認方法

- ホームをスクロールし、「マッチしてるよ！」「交換できるかも」が固定された時に、背景が上ほど濃い半透明モザイクとして見えることを確認
- 見出し文字がモザイク背景に埋もれず読めることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 依存追加なしで軽量なモザイク背景を実装した
- ✅ 固定見出しの文字レイヤーは維持し、可読性を落とさない構造にした
- ✅ UI表現のみの変更で状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.01：ホーム安全余白とセクション固定見出し

### 背景・問題意識

ホーム画面を最上部までスクロールした時に、「マッチしてるよ！」の大見出しがiPhoneの時計やDynamic Island付近に重なってしまっていた。前iterでホーム上部の固定空白を外した結果、不要な覆いは消えた一方で、ステータスバー領域への上限がなくなっていた。また、「マッチしてるよ！」「交換できるかも」は、該当エリアまでスクロールしたら薄いヘッダーとして残る方が、今どの区分を見ているか分かりやすい。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム画面に `useSafeAreaInsets` を導入し、上部余白を `safeArea.top + 12px` 相当で確保した。
- ホームの縦 `ScrollView` に `stickyHeaderIndices` を設定し、「マッチしてるよ！」「交換できるかも」をセクション単位の固定見出しにした。
- セクション見出しを `StickySectionHeader` に分離し、薄い背景とhairlineの下線でスクロール中も自然に読めるようにした。
- 既存のグッズ行表示は `ShelfSectionRows` として分離し、カードの横スクロールや優先度演出は維持した。

### 影響範囲

- iOS版 ホーム
- ホームのマッチセクション見出し
- ホーム最上部のsafe area余白

### 確認方法

- iPhone実機でホームを最上部までスクロールし、タイトルがステータスバーやDynamic Island領域に重ならないことを確認
- 「マッチしてるよ！」「交換できるかも」付近までスクロールし、該当見出しが薄い固定ヘッダーとして残ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ safe area を使って端末ごとの上部余白を確保した
- ✅ セクション名は既存文言のまま、薄い固定ヘッダーとして表示するようにした
- ✅ ホームカード行の横スクロール・優先度表示・現地交換演出には触れていない
- ✅ UI/レイアウト変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション156.00：iOSフッター縮小統一とヘッダー退避

### 背景・問題意識

`NativeTabs` の公開APIでは、下スクロール時にフッターを完全に下へ収納する挙動は用意されておらず、iOS標準の `onScrollDown` は左へ縮むMinimize挙動になる。ユーザーから「では、左にシュッで統一」と方針が確定した。また、ホーム画面では上部とフッター上に固定された空白の覆いが見えるため、ホームだけ安全余白の扱いを分離する必要があった。マイ在庫/Wishでは、スクロール時に元のタイトルヘッダーが上へすっこみ、上スクロールで戻る挙動が求められた。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- `NativeTabs` の `minimizeBehavior` を `onScrollDown` に変更し、下スクロール時はiOS標準の左へ縮む挙動で統一した。

#### `mobile/src/components/Screen.tsx`
- `bottomInset` と `topPadding` props を追加し、画面ごとに固定の上下余白を調整できるようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム画面だけ `topPadding={0}` / `bottomInset={false}` を指定し、上部とフッター上に固定表示されていた空白の覆いをなくした。
- ホームのスクロール内容側に下余白を持たせ、フッター下に内容が隠れすぎないようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫のタイトルヘッダーを `Animated.View` で包み、縦スクロール下方向で上へ収納、上方向で再表示するようにした。
- タブ切替時はヘッダーを再表示するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish画面のタイトルヘッダーもマイ在庫と同じく、縦スクロール方向に応じて収納/再表示するようにした。
- Wish/個別募集の横スワイプ追従は維持したまま、各ページ内の縦スクロールだけでヘッダーを制御するようにした。

### 影響範囲

- iOS版 全タブのフッター縮小挙動
- iOS版 ホーム
- iOS版 マイ在庫
- iOS版 Wish / 個別募集一覧
- 共通 `Screen` レイアウト

### 確認方法

- 各タブで下スクロール時にフッターがiOS標準の左へ縮む挙動になることを確認
- ホーム画面上部とフッター上の固定空白が消えていることを確認
- マイ在庫で下スクロールすると「マイ在庫」ヘッダーが上へ収納され、上スクロールすると戻ることを確認
- Wish画面で下スクロールすると「ウィッシュ」ヘッダーが上へ収納され、上スクロールすると戻ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/src/components/Screen.tsx`

### セルフレビュー結果

- ✅ フッターは独自実装ではなく、iOS標準 `NativeTabs` の `onScrollDown` に統一した
- ✅ ホームだけ上下固定余白を外し、他画面の安全余白には影響しないprops追加に留めた
- ✅ マイ在庫/Wishの横スワイプ挙動は維持し、縦スクロール時だけタイトルヘッダーを出し入れするようにした
- ✅ UI/レイアウト変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.99：フッター順序訂正と設定導線整備

### 背景・問題意識

通知タブ追加時に、フッターの左右順を逆に解釈してしまった。ユーザーから、左から「ホーム、在庫、Wish、通知、取引」にする訂正が入った。また、プロフィールドロワー内の「設定とプライバシー」「ヘルプ」が仮でプロフィールへ戻る状態だったため、実画面へつなぐ必要があった。ホーム右下の操作ボタンについても、通知導線はフッターへ移ったため、現地交換モード操作だけに絞る要望があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- `NativeTabs` の表示順を左から「ホーム / 在庫 / Wish / 通知 / 取引」に訂正した。
- プロフィールドロワーの「設定とプライバシー」を `/settings-privacy` へ、「ヘルプ」を `/help` へ遷移させるようにした。
- 「プロフィール」は hidden tab の自分プロフィール `/profile` へ進む導線として維持した。

#### `mobile/app/(tabs)/profile.tsx`
- 自分プロフィール画面の見出しを「プロフ」から「プロフィール」へ整えた。

#### `mobile/app/settings-privacy.tsx`
- 設定とプライバシー画面を追加した。
- X系の設定一覧に近い、中央タイトル・ユーザーID・検索欄・大きめの設定リスト構成にした。
- アカウント、セキュリティ、通知、プライバシー、規約、ヘルプなど既存画面へつながる導線を配置した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム右下の操作ボタンから「通知を見る」を削除した。
- iOSでは `ActionSheetIOS` で「現地交換モードをオン/オフにする」「現地交換情報を編集する」だけを表示するようにした。
- ボタンアイコンからベルを外し、OFF時は時計、ON時は現地交換中の強調アイコンにした。

### 影響範囲

- iOS版 フッター
- iOS版 プロフィールドロワー
- iOS版 自分プロフィール
- iOS版 設定とプライバシー
- iOS版 ホーム右下アクション

### 確認方法

- フッターが左から「ホーム / 在庫 / Wish / 通知 / 取引」になっていることを確認
- 左端スワイプでドロワーを開き、「プロフィール」「設定とプライバシー」「ヘルプ」がそれぞれ該当画面へ進むことを確認
- 設定とプライバシー画面で検索欄と設定リストが表示されることを確認
- ホーム右下ボタンを押し、通知ではなく現地交換操作だけが出ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/settings-privacy.tsx`

### セルフレビュー結果

- ✅ フッター順序をユーザー訂正どおりに直した
- ✅ ドロワーの仮遷移を実画面への遷移に置き換えた
- ✅ ホーム右下の通知導線重複をなくし、現地交換操作に特化した
- ⚠️ `NativeTabs` の公開APIでは「下スクロールで完全に下へ収納」を指定できず、iOS標準の `onScrollDown` は左側へ縮むMinimize挙動になる。現時点では `minimizeBehavior="never"` で左シュッ挙動を止めており、完全収納を実現するにはNativeTabsからカスタムフッターへの移行が必要
- ✅ UI/遷移変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.98：通知タブ追加とフッター順序整理

### 背景・問題意識

フッターからプロフタブを外した後、通知への明確な導線がフッター上にない状態になっていた。ユーザーから、プロフの代わりに通知アイコンを置き、フッターの並びを右から「ホーム、在庫、Wish、通知、取引」にする要望があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- `NativeTabs` に通知タブを追加した。
- 表示順を左から「取引 / 通知 / Wish / 在庫 / ホーム」に変更し、右から見た時に「ホーム / 在庫 / Wish / 通知 / 取引」になるようにした。
- プロフはフッター表示から外したまま、左端スワイプのプロフィールドロワー用 hidden route として維持した。

#### `mobile/app/(tabs)/notifications.tsx`
- 既存の通知一覧画面をタブ配下へ移動し、フッターの通知アイコンから通知一覧を直接開けるようにした。
- 既存の既読処理、未読件数表示、通知リンク遷移のロジックは維持した。

### 影響範囲

- iOS版 フッター
- iOS版 通知一覧
- iOS版 プロフィールドロワー内の通知導線

### 確認方法

- フッターに通知タブが表示され、タップすると通知一覧が開くことを確認
- フッターの右端から順に「ホーム / 在庫 / Wish / 通知 / 取引」になっていることを確認
- 左端スワイプでプロフィールドロワーが開き、プロフ導線は維持されていることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(tabs)/notifications.tsx`

### セルフレビュー結果

- ✅ プロフの代替として通知をフッターへ追加した
- ✅ 右から見たフッター順がユーザー指定どおりになるよう、NativeTabsの表示順を調整した
- ✅ 通知一覧の取得・既読・リンク遷移ロジックは既存実装を流用した
- ✅ UI/ルート整理のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.97：ホーム下部操作とプロフ左ドロワー化

### 背景・問題意識

スマホ大型化により、ホーム上部の通知・現地交換モード切替・場所設定ボタンが押しづらくなっていた。ユーザーから、右下の届きやすい位置に操作入口を置き、そこから現地交換モードON/OFFと現地交換情報編集へ進める案が提示された。また、フッターのプロフタブをなくし、Xのように左端スワイプでプロフィール系メニューを引き出す導線へ変更する要望があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部の通知アイコン、場所ボタン、現地交換トグル、全国/現地切替セグメントを撤去した。
- 画面右下に `FloatingHomeActionButton` を追加し、iOSでは `ActionSheetIOS` で以下の操作を出すようにした。
  - 通知を見る
  - 現地交換モードをオン/オフにする
  - 現地交換情報を編集する（現地交換モードON時のみ）
- 現地交換モードON時は、候補カードを非表示に絞るのではなく、同じ行内で現地交換候補を先頭に並べるようにした。
- 現地交換モードON中は左右の画面端に脈動する紫のフォーカスエフェクトを出し、視野が狭まるような集中感を演出した。

#### `mobile/app/(tabs)/_layout.tsx`
- フッターからプロフの表示を削除し、`profile` タブは hidden route として残した。
- 画面左端から右スワイプするとプロフィールドロワーが出る `ProfileDrawerHost` を追加した。
- ドロワー内にプロフィール概要、プロフィール編集、推し設定、通知、取引、スケジュール、設定/ヘルプ/ログアウト導線を配置した。
- `NativeTabs` の `minimizeBehavior="onScrollDown"` をやめ、左に縮む挙動を止めるため `minimizeBehavior="never"` に変更した。

### 影響範囲

- iOS版 ホーム
- iOS版 フッター
- iOS版 プロフィール導線
- iOS版 全タブ画面の左端スワイプ操作

### 確認方法

- ホーム右下の丸ボタンを押し、通知/現地交換ON-OFF/現地交換情報編集が出ることを確認
- 現地交換モードON時、ホームの画面端に脈動する紫のフォーカスエフェクトが出ることを確認
- フッターからプロフが消えていることを確認
- ホーム/在庫/Wish/取引の左端から右へスワイプし、プロフィールドロワーが出ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ 上部の届きづらいホーム操作を下部の届く位置へ移した
- ✅ 現地交換ON時は現地交換候補を優先表示する設計に寄せた
- ✅ フッターからプロフを外し、左端スワイプのプロフィールドロワーを追加した
- ⚠️ `NativeTabs` の公開APIには「完全に下へ隠す」指定がなく、今回は左に縮む原因の `onScrollDown` を止める対応に留めた。完全退避を実現するには、NativeTabsを捨てたカスタムフッター化が必要
- ✅ UI/ナビゲーション変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.96：Wishタブ横スワイプ追従のカクつき解消

### 背景・問題意識

Wish画面で横スワイプに合わせて上部タブの選択面が動くようになったが、マイ在庫と比べて動きがカクついていた。Wish画面はWishグリッドと個別募集一覧を同時に抱えており、横スクロールの `onScroll` でReact stateを毎フレーム更新すると、重いリスト部分まで再描画されやすい構造になっていた。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- `SectionTabs.position` が数値だけでなく `Animated.Value` / `AnimatedInterpolation` を受け取れるようにした。
- 外部からAnimated値が渡された場合は、内部でReact stateを介さず選択面の位置だけをアニメーションで更新するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- 横Pagerのスクロール位置をReact stateではなく `Animated.Value` で管理するようにした。
- `Animated.ScrollView` + `Animated.event(..., { useNativeDriver: true })` で、タブ追従をネイティブアニメーション側へ逃がした。
- タブ確定時だけ `tab` stateを更新し、スワイプ中にWishカード/個別募集一覧が毎フレーム再描画されないようにした。

### 影響範囲

- iOS版 Wish画面
- `SectionTabs` の追従アニメーション

### 確認方法

- Wish画面でWish/個別募集を横スワイプし、上部タブの選択面がカクつかず指に追従することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/wishes.tsx`
- `mobile/src/components/GoodsGrid.tsx`

### セルフレビュー結果

- ✅ Wish画面のスワイプ中React再描画を避ける設計に変更した
- ✅ マイ在庫側の既存挙動は壊さず、`SectionTabs` の受け口だけ拡張した
- ✅ UIパフォーマンス修正のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.95：個別募集編集のWish候補カード巨大化修正

### 背景・問題意識

iOS版の個別募集編集画面で、求めるものを選択する横スクロール候補の画像カードが極端に巨大化して表示されていた。譲グッズの3列グリッド用カードと、横スクロール内のWish候補カードが同じ幅指定を共有しており、横スクロール側で `width: "31%"` の基準が崩れていた。

### 変更内容

#### `mobile/app/listing-editor.tsx`
- `GoodsPanelCard` に `compact` props を追加し、横スクロールのWish候補では固定幅のコンパクトカードを使うようにした。
- `panelWrapCompact` を追加し、横スクロール内でカードが画像実寸やScrollView幅に引っ張られないようにした。
- 写真表示は `resizeMode="cover"` を明示し、カード枠内に収まるようにした。

### 影響範囲

- iOS版 個別募集編集 / 作成
- 求めるもののWish候補横スクロール

### 確認方法

- 個別募集編集画面を開き、求めるものの候補画像が巨大化せず横スクロール内の小カードとして表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/listing-editor.tsx`

### セルフレビュー結果

- ✅ 譲グッズ側の3列グリッド幅は維持し、横スクロール側だけ固定幅へ分離した
- ✅ UIサイズ修正のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.94：iOS実部品への切替と横スワイプ追従

### 背景・問題意識

前iterではホームのモード切替をLiquid Glass「風」の独自UIとして実装してしまい、ユーザーから「独自のものにするな」「iOSの本物のデザインにしろ」と明確に指摘された。iOS版では見た目を近づけるのではなく、利用できる範囲で実際のiOS標準部品・ネイティブコンテナを優先し、独自表現は補助に留める方針へ訂正した。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホームの「全国交換 / 今すぐ現地交換」切替を独自アニメーションから `@react-native-segmented-control/segmented-control` のネイティブ `UISegmentedControl` へ置き換えた。
- 現地交換設定シートを、iOSでは `Modal` の `pageSheet` 表示へ切り替え、独自の暗幕付き下部シートをiOSでは使わないようにした。

#### `mobile/src/components/GoodsGrid.tsx`
- `SectionTabs` に `position` を追加し、横スワイプ中のページ位置に合わせて選択面が指の動きへ追従するようにした。
- 在庫/Wish/個別募集カードの操作メニューは、iOSで `ActionSheetIOS` の本物のアクションシートを使う方針を維持した。

#### `mobile/app/(tabs)/inventory.tsx` / `mobile/app/(tabs)/wishes.tsx` / `mobile/app/(tabs)/transactions.tsx`
- 横Pagerの `onScroll` から `SectionTabs.position` を更新し、ページ切替中に上部タブも連動して動くようにした。
- 取引一覧は打診中/進行中/完了を横Pager化し、上部タブとページ位置のズレをなくした。

#### `mobile/app/search.tsx`
- 検索画面を独自検索フォームから、ネイティブStackヘッダーの `headerSearchBarOptions` へ切り替えた。

#### `mobile/app/profile-edit.tsx` / `mobile/app/oshi-settings.tsx` / `mobile/app/goods-editor.tsx` / `mobile/app/listing-editor.tsx` / `mobile/app/transaction-detail.tsx`
- プロフ編集、推し設定、グッズ/Wish編集、個別募集編集、取引詳細を `Stack.Screen` のネイティブヘッダーへ寄せた。
- プロフの活動エリア選択、推し追加、推し/メンバー追加リクエスト、待ち合わせ場所設定はiOSで `pageSheet` として表示するようにした。

#### `mobile/app/onboarding/oshi.tsx` / `mobile/app/onboarding/members.tsx`
- オンボーディング中の推し追加リクエスト、メンバー追加リクエストもiOSでは `pageSheet` に揃えた。

#### `mobile/package.json` / `package.json`
- ネイティブ `UISegmentedControl` 利用のため `@react-native-segmented-control/segmented-control` を追加した。
- 依存解決のためルートに `@types/react` を追加した。

### 影響範囲

- iOS版 ホーム
- iOS版 マイ在庫 / Wish / 個別募集一覧
- iOS版 取引一覧
- iOS版 検索
- iOS版 プロフ編集 / 推し設定 / グッズ編集 / 個別募集編集 / 取引詳細
- iOS版 現地交換設定 / 活動エリア設定 / 待ち合わせ場所設定 / 追加リクエスト

### 確認方法

- iOS実機でホームを開き、モード切替が独自UIではなくネイティブSegmentedControlとして表示されることを確認
- 在庫/Wish/取引一覧を横スワイプし、上部タブの選択面が指の位置に追従することを確認
- 検索画面を開き、iOSのヘッダー検索欄として表示されることを確認
- 現地交換設定、待ち合わせ場所設定、推し追加/追加リクエストがiOSシートとして出ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/search.tsx`
- `mobile/app/profile-edit.tsx`
- `mobile/app/oshi-settings.tsx`
- `mobile/app/goods-editor.tsx`
- `mobile/app/listing-editor.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/onboarding/oshi.tsx`
- `mobile/app/onboarding/members.tsx`
- `mobile/src/components/GoodsGrid.tsx`
- `mobile/src/components/Screen.tsx`
- `mobile/package.json`
- `package.json`

### セルフレビュー結果

- ✅ ホームのモード切替は独自Liquid Glass風UIからネイティブ `UISegmentedControl` へ切り替えた
- ✅ 横スワイプ可能な画面では、ページ位置と上部タブの選択位置を同期した
- ✅ iOSで本物のシステムUIを使える箇所は `ActionSheetIOS` / `pageSheet` / `Stack.Screen` / `headerSearchBarOptions` へ寄せた
- ⚠️ `@react-native-segmented-control/segmented-control` はネイティブ依存のため、既存のdevelopment buildに入っていない場合はiOS dev buildの作り直しが必要
- ✅ UI/遷移の変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.93：iOS操作部をLiquid Glass系に再整理

### 背景・問題意識

iOS版のフッターは `NativeTabs` によって最新版iOSのLiquid Glass系デザインへ寄せられたが、ホームのモード切替、在庫/Wish/個別募集のタップ操作、上部タブ、共通戻るヘッダーはまだカスタムUI感が強く、画面全体の洗練度に差があった。ユーザーから「今のフッターみたいにIOS最新版のデザインを流用できるところ」を順に実装するよう依頼されたため、まず効果が大きい操作部をiOS寄りへ揃えた。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホームの全国交換/今すぐ現地交換モード切替を、半透明のガラスレイヤー、白い可動サム、淡いプリズム反射、周辺グローを持つLiquid Glass系セグメントに刷新した。
- モード切替中のステータス表示は既存の即時フィードバックを維持し、上部に短時間表示されるピルとして残した。
- 現地交換OFF時の場所表示は「（現地交換モードOFF）」のまま維持し、既存の現地交換設定シート導線を消さないようにした。

#### `mobile/src/components/GoodsGrid.tsx`
- 在庫/Wish/個別募集のタップ操作に使う `BottomOptionSheet` を、iOSでは `ActionSheetIOS` のネイティブアクションシートで表示するようにした。
- iOS以外では既存の下部シートを維持し、操作順・削除確認・既存のフェードアウト挙動は変えないようにした。
- 在庫/Wish/取引一覧で使う `SectionTabs` を、選択面がスプリングで移動するガラス系セグメントに変更した。
- 列数切替の小型セグメントも、フッターと馴染む白い半透明の操作部へ寄せた。

#### `mobile/src/components/RouteHeader.tsx`
- 共通の戻るヘッダーを、半透明のガラスカプセルと軽い影を持つiOS寄りの操作部へ変更した。
- 戻り先がない場合は `router.navigate("/")` に統一し、未処理の `replace` 警告を避ける既存方針を維持した。

#### `mobile/app/goods-editor.tsx` / `mobile/app/profile-edit.tsx`
- グッズ/Wish画像とプロフィールアイコンの写真選択を、iOSでは `ActionSheetIOS` のネイティブメニューで表示するようにした。
- iOS以外では既存の `Alert.alert` を維持し、カメラ/写真ライブラリの権限・アップロード処理は変更していない。

### 影響範囲

- iOS版 ホーム
- iOS版 マイ在庫 / Wish / 個別募集一覧
- iOS版 取引一覧など `SectionTabs` 利用画面
- iOS版 `RouteHeader` 利用画面全般
- iOS版 グッズ/Wish編集・作成、プロフィール編集の画像選択

### 確認方法

- ホームで全国交換/今すぐ現地交換モードを切り替え、可動サムと切替中ピルがスムーズに出ることを確認
- iOS実機でマイ在庫/Wish/個別募集カードを押し、ネイティブのアクションシートが出ることを確認
- iOS実機でグッズ画像・プロフィールアイコンの画像選択を押し、ネイティブのアクションシートが出ることを確認
- 在庫/Wish/取引一覧のタブを切り替え、選択面がぬるっと移動することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/app/goods-editor.tsx`
- `mobile/app/profile-edit.tsx`
- `mobile/src/components/GoodsGrid.tsx`
- `mobile/src/components/RouteHeader.tsx`

### セルフレビュー結果

- ✅ 既存のWeb版追従差分、Apple ID導線、現地交換設定シート、検索フローティングボタンは消していない
- ✅ iOSで本物のシステムUIを使えるカード操作は `ActionSheetIOS` へ寄せた
- ✅ モード切替とタブは新しい状態名・DB列を追加しない純UI変更のため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.92：iOS取引チャットの画面骨格をWeb版へ再同期

### 背景・問題意識

前iterでは取引チャットの機能をWeb版へ寄せたが、UI構造はWeb版 `ChatView` と大きく異なっていた。Web版は「相手ヘッダー」「固定の取引内容＋待ち合わせカード」「メッセージリスト」「下部固定composer」というチャット専用の画面骨格であり、iOS版のような縦積みの詳細画面ではない。ユーザーから「取引チャットのUIと全然違う」と指摘されたため、機能追加ではなく見た目の骨格から再同期した。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- `Screen` の通常スクロール画面をやめ、Web版と同じく `KeyboardAvoidingView` ベースのチャット専用レイアウトに変更した。
- 上部ヘッダーを、戻るボタン・相手アイコン・ユーザーID・到着/打診ステータス・エリア表示の1行構成に変更した。
- 取引内容と待ち合わせを1つの白いコンパクトカードにまとめ、Web版の `DealCard` に近い小画像サムネ・交換矢印・ミニ地図構成へ変更した。
- 合意前はWeb版の `ExpireBanner` / `AgreementBar` に合わせ、期限バナーと合意ステータスバーを固定カード下に表示するようにした。
- 合意後はWeb版の `OutfitCompactRow` に合わせ、服装写真の共有状態をコンパクトな1行表示にした。
- メッセージ領域に日付セパレーターを追加し、証跡撮影CTAもWeb版のメッセージ内カードに近い配置へ移した。
- クイックアクションと入力欄を画面下部固定にし、Web版の `QuickChip` + composer の構成へ寄せた。

### 影響範囲

- iOS版 取引詳細 / 取引チャット
- iOS版 打診中ネゴチャット / 合意後取引チャット

### 確認方法

- 取引一覧からパネルを開き、相手ヘッダー・取引内容カード・メッセージリスト・下部composerがWeb版と同じ骨格で表示されることを確認
- 合意前の打診で、期限/合意ステータス/再打診導線が下部composer側に出ることを確認
- 合意後の取引で、服装写真・現在地・到着ステータス・証跡撮影CTAがWeb版と同じ位置関係で表示されることを確認
- `npm --prefix mobile run typecheck`
- `git diff --check`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `web/src/app/transactions/[id]/ChatView.tsx`
- `Megrum/c-flow.jsx`
- `Megrum/nego-flow.jsx`

### セルフレビュー結果

- ✅ Web版 `ChatView` と `Megrum/c-flow.jsx` / `Megrum/nego-flow.jsx` の構造を確認してから実装した
- ✅ 機能だけでなく、固定ヘッダー・固定composer・ピン留め取引内容カードという画面骨格をWeb版に寄せた
- ✅ 前iterで追加したApple導線、写真添付、現在地共有、地図プレビュー、再打診導線は消していない
- ✅ 画面構成変更のみで状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.91：iOS取引チャットと認証導線のWeb版追従

### 背景・問題意識

iOS版の取引チャットがWeb版の取引チャットと比べて、申告中バナー、期限延長、合意状態、合意後の当日ライブ状態、再打診導線の見え方が薄く、ユーザーから「Web版と乖離がある」と指摘された。また、新規登録導線ではApple IDの入口を最初の認証画面へ集約し、メール入力画面の下部からはAppleサインアップを消す必要があった。加えて、開発環境でホーム遷移時に `REPLACE /(tabs)` が未処理になる警告と、Wish一覧で同一グッズIDの重複key警告が出ていた。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- Web版 `ChatView` に合わせて、申告中バナー、打診期限/延長、合意状態バー、合意後の当日ライブ準備パネルを追加した。
- 合意前チャットのクイックアクションに「カレンダー」「条件を変えて再打診」「写真添付」を並べ、Web版の操作導線へ寄せた。
- `extension_count`、open dispute、到着ステータス、服装写真を実データから集約して表示できるようにした。
- `extension_count` が未反映の環境でも落ちないよう、期限延長更新は該当列なしの場合にフォールバックするようにした。

#### `mobile/app/(auth)/welcome.tsx`
- 最初の新規登録画面にApple IDで新規登録する導線を追加した。
- プレビュー開始後のホーム遷移を `replace` ではなく `navigate` に変更した。

#### `mobile/app/(auth)/signup.tsx`
- メールアドレス新規登録の各項目入力画面下部からAppleサインアップボタンを削除した。

#### `mobile/app/_layout.tsx` / `mobile/app/(auth)/_layout.tsx`
- Root Stackで `(tabs)` / `(auth)` を明示し、ログイン済みで認証画面に入った時のホーム遷移を `navigate` ベースにした。

#### `mobile/app/(tabs)/wishes.tsx`
- 同一グッズが複数候補に出る場合でもReact keyが重複しないよう、表示indexを含むkeyに変更した。

### 影響範囲

- iOS版 取引詳細 / 取引チャット
- iOS版 新規登録・ログイン後ホーム遷移
- iOS版 Wish > 個別募集一覧

### 確認方法

- 取引一覧から打診中/進行中のパネルを開き、取引チャット上部に合意状態・期限・再打診導線が出ることを確認
- 新規登録最初の画面にApple ID導線があり、メール入力画面下部にはApple導線がないことを確認
- Wish個別募集一覧で重複key警告が出ないことを確認
- `npm --prefix mobile run typecheck`
- `git diff --check`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/signup.tsx`
- `mobile/app/_layout.tsx`
- `mobile/app/(auth)/_layout.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ ユーザーが追加で要望した写真添付・現在地共有・地図プレビュー等の既存差分は消さずに取引チャットを拡張した
- ✅ Apple ID新規登録導線は最初の認証画面へ集約し、メール入力画面下部からは削除した
- ✅ `REPLACE /(tabs)` 警告につながるホームへの `replace` を避け、ホーム遷移を `navigate` に寄せた
- ✅ 新しいDB列追加は行わず、既存 `extension_count` 参照は列なし環境でもフォールバックするため `notes/05_data_model.md` の更新は不要
- ✅ 状態名・用語の追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション155.90：iOSタブ外ルートの認証初期化待ちを追加

### 背景・問題意識

iOS版でログイン済みアカウントを開いた時、タブ画面は認証・プロフィール初期化を待つが、取引詳細や編集画面などタブ外のルートはRoot Stackがすぐ描画されるため、セッション確認前の一瞬にプレビュー/フォールバック情報が見える余地があった。ユーザー体験として「どの画面でもプレビュー用の情報が一瞬読み込まれる」印象につながるため、Web版と同じく実データ接続前の表示を抑える必要があった。

### 変更内容

#### `mobile/app/_layout.tsx`
- Root Stackを直接描画せず、`RootNavigator` を挟むようにした。
- `useAuth().loading` または `profileLoading` が true の間は背景色を揃えた中央ローディングのみ表示するようにした。
- 認証初期化完了後に従来通り `Stack` を表示し、既存の右スライド遷移は維持した。

### 影響範囲

- iOS版 全ルート
- タブ外画面（取引詳細、在庫/Wish編集、個別募集編集、プロフ編集など）の初期表示

### 確認方法

- ログイン済み状態でアプリを再起動し、タブ外画面へ遷移してプレビュー用の仮情報が一瞬出ないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/_layout.tsx`
- `mobile/src/auth/AuthProvider.tsx`

### セルフレビュー結果

- ✅ 既存のタブ/認証レイアウトガードを消さず、Root側の初期化待ちだけ追加した
- ✅ 画面遷移アニメーションと既存の追加要望は維持した
- ✅ 認証表示制御のみのため、新しい状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.89：iOSパスワードリセット画面を追加

### 背景・問題意識

iOS版ログイン画面には「パスワードを忘れた方」の導線があるが、遷移先の `/password-reset` 画面が未実装だった。Web版にはパスワードリセット画面があるため、スマホアプリでも同じくメールアドレス入力からリセットメールを送れる必要があった。

### 変更内容

#### `mobile/app/(auth)/password-reset.tsx`
- パスワードリセット画面を新規追加した。
- メールアドレス入力、簡易バリデーション、エラー表示、成功メッセージ表示を実装した。
- Supabase Auth の `resetPasswordForEmail` を使ってリセットメールを送信するようにした。
- Web版と同じ案内文・戻る導線・「リセットメールを送信」アクションに揃えた。

### 影響範囲

- iOS版 ログイン > パスワードを忘れた方
- iOS版 認証導線

### 確認方法

- ログイン画面の「パスワードを忘れた方」からパスワードリセット画面へ遷移できることを確認
- メールアドレスを入力してリセットメール送信が成功することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(auth)/password-reset.tsx`
- `mobile/app/(auth)/login.tsx`
- `web/src/app/password-reset/page.tsx`
- `web/src/app/password-reset/ResetForm.tsx`

### セルフレビュー結果

- ✅ 既存のログイン導線から404にならないよう、未実装画面を追加した
- ✅ Supabase Authの既存機能を使うだけで新しい状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.88：iOS取引詳細の待ち合わせを地図付きに同期

### 背景・問題意識

Web版の取引チャットでは、取引内容カード内の待ち合わせ欄にミニマップがあり、合流場所を視覚的に確認できる。iOS版の取引詳細は待ち合わせ候補を時間と場所名だけで表示していたため、現地交換時の位置確認がWeb版より弱かった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 待ち合わせ候補に緯度経度がある場合、`NativeMapPreview` のミニマップを表示するようにした。
- 待ち合わせカードを押すとApple Mapsで該当地点を開けるようにした。
- 緯度経度がない候補は、従来通り時間と場所名のみで表示するようにした。

### 影響範囲

- iOS版 取引詳細
- 待ち合わせ候補カード

### 確認方法

- 取引詳細で緯度経度付きの待ち合わせ候補にミニマップが表示されることを確認
- そのカードを押すとApple Mapsへ遷移することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/src/components/NativeMapPreview.tsx`
- `web/src/app/transactions/[id]/ChatView.tsx`

### セルフレビュー結果

- ✅ Web版の待ち合わせミニマップ表示をiOS版にも追加した
- ✅ 既存の候補時間・場所名表示は維持した
- ✅ 既存のmeetup緯度経度を使うため、新しい状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.87：iOS位置情報メッセージを地図表示へ同期

### 背景・問題意識

Web版の取引チャットでは、現在地共有メッセージがテキストだけではなくミニマップ付きで表示され、必要なら地図アプリへ開ける。iOS版は location message の本文表示に留まっていたため、現地合流時に「どこにいるか」を直感的に確認しづらかった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- location message 用の `LocationChatBubble` を追加した。
- 緯度経度がある場合は `NativeMapPreview` でチャット内に小さな地図とピンを表示するようにした。
- 「地図アプリで開く」から Apple Maps のURLを開けるようにした。
- 既存のテキスト・写真・服装写真・到着ステータスの表示は維持した。

### 影響範囲

- iOS版 取引チャット
- 現在地共有メッセージの表示

### 確認方法

- 取引チャットで現在地を送信し、チャット内に地図付きのlocation bubbleが表示されることを確認
- 「地図アプリで開く」を押すとApple Mapsへ遷移することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/src/components/NativeMapPreview.tsx`
- `web/src/app/transactions/[id]/ChatView.tsx`

### セルフレビュー結果

- ✅ Web版のミニマップ付きlocation bubbleへiOS版を近づけた
- ✅ 既存の `messages.location_lat/location_lng/location_label` を使うため、新しい状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.86：iOS取引チャットに写真・現在地共有を追加

### 背景・問題意識

Web版の取引チャットには、合意後の現在地共有、向かう/到着、服装写真、通常写真添付がクイックアクションとして用意されている。iOS版はテキスト送信と到着ステータスが中心で、当日の取引体験に必要な「見つけやすさ」「現地共有」の機能が不足していた。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引チャットの入力欄上にクイックアクションチップを追加した。
- 合意済み取引では「現在地」「服装写真」「写真添付」を表示し、合意前のネゴチャットでは「写真添付」を表示するようにした。
- `expo-location` で現在地を取得し、可能なら逆ジオコードした場所名つきの location message を送信するようにした。
- `expo-image-picker` で通常写真 / 服装写真を選び、`chat-photos` storage へアップロードして signed URL を message に保存するようにした。
- 服装写真はWeb版同様、合意済み取引でのみ送れるように防御した。

### 影響範囲

- iOS版 取引詳細 / 取引チャット
- 合意前ネゴチャットの写真添付
- 合意後取引チャットの現在地共有・服装写真・写真添付

### 確認方法

- 取引チャットで写真添付を押し、写真選択後にチャットへ画像メッセージが追加されることを確認
- 合意済み取引で現在地を押し、location message が追加されることを確認
- 合意済み取引で服装写真を押し、outfit_photo message が追加されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `web/src/app/transactions/[id]/ChatView.tsx`
- `web/src/app/transactions/actions.ts`

### セルフレビュー結果

- ✅ Web版の取引チャットの主要クイックアクションをiOS版にも追加した
- ✅ 既存のテキスト送信・到着ステータス・証跡撮影導線は残した
- ✅ 既存の `messages` / `chat-photos` を使うため、新しい状態名・用語・DB列追加はなく `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.85：iOS取引詳細の補助取得失敗を分離

### 背景・問題意識

取引一覧から取引詳細へ入る導線では、打診データそのものが取れれば取引チャットを表示できるべきである。iOS版は詳細画面で相手プロフィール、在庫リレーション、証跡写真などの補助データを並列取得していたため、補助テーブルや任意列の取得失敗でも詳細全体が「読み込みに失敗しました」へ落ちる可能性があった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 相手プロフィール、取引グッズ、証跡写真の取得をそれぞれ安全な helper に分離した。
- `users.avatar_url` がない環境では、avatarなしのselectへフォールバックするようにした。
- 在庫リレーションや証跡写真テーブルの取得に失敗しても、取引詳細全体は落とさず、取れる範囲の情報で表示するようにした。
- 補助取得の失敗は `console.warn` に留め、メインの打診取得とチャット表示を優先するようにした。

### 影響範囲

- iOS版 取引一覧 > 取引詳細
- iOS版 取引チャット表示
- 証跡写真・相手アバター・交換物サムネイルの補助表示

### 確認方法

- 取引一覧の打診中 / 進行中 / 完了パネルから詳細へ入れることを確認
- `avatar_url` や証跡写真テーブルが取得できない環境でも、取引詳細がエラー画面にならないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ メインの `proposals` 取得と補助データ取得を分離し、補助情報欠落で取引チャットが開けなくなるリスクを下げた
- ✅ 既存の一覧スナップショット復元フォールバックも残している
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.84：iOSログイン後のプレビュー残留を抑止

### 背景・問題意識

iOS版では、ログイン後の画面でプレビュー用の情報が一瞬読み込まれることがあり、実アカウントで操作している感覚を損ねていた。特に取引詳細では `previewMode` が残ると「Preview_hanaでは取引チャットを開けません」という表示へ寄る可能性があるため、実セッションが存在する時はプレビュー状態を明示的に無効化する必要があった。

### 変更内容

#### `mobile/src/auth/AuthProvider.tsx`
- Supabaseの既存セッション取得時、または auth state change でセッションが入った時に `previewMode` を解除するようにした。
- Contextへ渡す `previewMode` は、セッションがない時だけ有効な `effectivePreviewMode` に変更した。
- オンボーディング判定も `effectivePreviewMode` を参照し、ログイン済みユーザーがプレビュー扱いでガードをすり抜けないようにした。

### 影響範囲

- iOS版 認証状態管理
- ログイン後のホーム / 取引一覧 / 取引詳細 / プロフなど、プレビュー表示を持つ画面

### 確認方法

- プレビュー表示後にログインし、実セッションがある状態ではプレビュー情報が出ないことを確認
- 取引詳細で、ログイン済みなのに `Preview_hana` 向けの案内へ落ちないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ 実セッションが存在する時はプレビュー扱いにならないよう、AuthProviderの根元で抑止した
- ✅ プレビュー機能自体は、未ログインかつ明示的にプレビューへ入った場合だけ残した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.83：iOSカード表示を画像準備後へ同期

### 背景・問題意識

Web版のホーム・在庫・Wishでは、画像が読み込まれてからカードの登場アニメーションを始めるため、写真が空のままパネルだけ先に出る違和感が出にくい。iOS版はカード本体の表示が画像ロードより先に始まる可能性があり、ユーザーが気に入っている表示速度は維持しつつ、写真準備前の不恰好さを抑える必要があった。

### 変更内容

#### `mobile/src/lib/useImageReady.ts`
- React Native向けに画像URLのプリフェッチ完了を管理する `useImageReady` を追加した。
- 一度準備できた画像URLはセッション内でキャッシュし、再表示時に待ちすぎないようにした。
- 画像取得に失敗した場合もカードが永久に隠れないよう、失敗時は準備完了扱いにした。

#### `mobile/src/components/GoodsGrid.tsx`
- 在庫 / Wish 共通のグッズカードを、画像準備後に登場アニメーションへ入るよう変更した。
- 画像準備に時間がかかった場合は、経過済みの登場ディレイを差し引いて、現在の速いテンポをできるだけ維持するようにした。
- 準備前の透明カードがタップを吸わないよう、pointer events を止めた。

#### `mobile/app/(tabs)/index.tsx`
- ホームのマッチング候補カードも画像準備後に右からスライドインするよう変更した。
- 行内の順番ディレイは維持しつつ、画像ロード待ちで不必要に遅くならないようにした。

### 影響範囲

- iOS版 ホーム画面のマッチング候補カード
- iOS版 マイ在庫のグッズカード
- iOS版 Wishのグッズカード

### 確認方法

- ホーム画面で画像付きマッチングカードが、写真準備後に右から表示されることを確認
- マイ在庫 / Wishで、画像付きグッズカードが写真の空白を見せずに登場することを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/src/lib/useImageReady.ts`
- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/index.tsx`
- `web/src/components/common/useImageReady.ts`
- `web/src/components/home/HomeView.tsx`
- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/wishes/WishView.tsx`

### セルフレビュー結果

- ✅ Web版の `useImageReady` と同じ「画像準備後にカードを出す」考え方へ寄せた
- ✅ 登場アニメーションの速さを損なわないよう、画像待ち中に経過したディレイは再度待たせない実装にした
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.82：iOS Wishタブを指追従ページャーへ変更

### 背景・問題意識

iOS版のWish画面は、Wish / 個別募集の切り替えを横スワイプで判定していたが、画面そのものは指の動きに追従せず、切り替え完了時に内容だけが変わる実装だった。在庫画面やiOS標準の画面移動に寄せるには、横ページャーとして実際に画面が動く必要がある。

### 変更内容

#### `mobile/app/(tabs)/wishes.tsx`
- Wish / 個別募集の2画面を、横 `ScrollView` + `pagingEnabled` のページャーに変更した。
- 上部タブを押した時は該当ページへ滑らかにスクロールし、横スワイプ時は指の動きに合わせてページが移動するようにした。
- ページの着地後に上部タブ状態を同期し、選択中のWish/個別募集シートは閉じるようにした。

### 影響範囲

- iOS版 Wishタブ
- Wish一覧 / 個別募集一覧のタブ切り替え
- Wish一覧 / 個別募集一覧内の縦スクロール

### 確認方法

- Wish画面で左右にスワイプすると、画面が指に追従してWish/個別募集が切り替わることを確認
- 上部タブを押しても同じページャーで滑らかに切り替わることを確認
- 各ページ内の縦スクロールが維持されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/wishes.tsx`
- `web/src/app/wishes/WishView.tsx`

### セルフレビュー結果

- ✅ 手動のスワイプ判定だけでなく、実際の横ページャーへ変更した
- ✅ 既存のWish削除、個別募集編集/停止/削除、列数切替は維持した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.81：iOS待ち合わせ長押しの初期枠を30分へ調整

### 背景・問題意識

提示物選択の待ち合わせカレンダーでは、1回タップ時は30分候補を作れる一方で、長押し開始時のドラッグプレビューが60分相当で始まっていた。Google Calendar的な「押した位置から必要な分だけ伸ばす」感覚に寄せるには、最初の候補枠は控えめな30分から始まる方が直感的である。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 長押しで時間選択に入った瞬間のドラッグプレビューを、開始スロットから30分ぶんに変更した。
- 24時付近で長押ししても範囲がカレンダー外へはみ出さないよう、初期 `currentSlot` を `SLOT_COUNT - 1` で丸めた。

### 影響範囲

- iOS版 提示物の選択 > 待ち合わせタブ
- 長押しでの候補時間作成

### 確認方法

- 待ち合わせカレンダーで長押しすると、最初に30分幅の候補として表示されることを確認
- そのまま上下へドラッグすると候補時間が自然に伸び縮みすることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ タップ作成と長押し開始時の時間幅を揃えた
- ✅ 既存の候補追加、場所設定、週スワイプ、候補移動/リサイズは変更していない
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.80：iOS推し設定を楽観更新へ同期

### 背景・問題意識

Web版の推し設定は、推しやメンバーを追加した瞬間に画面へ反映し、保存処理は裏側で順番に流す設計になっている。iOS版は保存ごとに再読み込みしていたため、登録のたびにグループ表示が前後したり、次のメンバーをすぐ追加できないように見える余地があった。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- 推し設定の保存処理をキュー化し、画面上は先に反映する楽観更新へ変更した。
- 登録済みマスタの推し追加、推し削除、メンバー追加、メンバー削除、推し/メンバー追加リクエストを、Web版と同じく即時にUI反映してからバックグラウンド保存するようにした。
- 保存中に `fetchOshiData` の結果でローカル表示を上書きしないようにし、保存キューが空になったタイミングだけ再同期するようにした。
- 追加リクエストは送信直後に「承認待ち」の仮登録として表示し、失敗時は直前の表示へ戻すようにした。

### 影響範囲

- iOS版 プロフ > 推し設定
- 登録済み推し追加モーダル
- 推し/メンバー追加リクエスト
- 推しメンバー追加/削除

### 確認方法

- 推し設定で登録済みの推しを追加して、画面上へ即時に追加されることを確認
- メンバーを連続で追加しても、登録ローディング待ちで次の操作が止まらないことを確認
- 推し/メンバー追加リクエスト後、承認待ちの仮登録として即時表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/oshi-settings.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`

### セルフレビュー結果

- ✅ Web版の「先にUI反映、保存は裏で順番に処理」に合わせた
- ✅ 既存の追加リクエスト導線、登録済み推し検索、ジャンルタブは残した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.79：iOS待ち合わせカレンダーのジェスチャーロック追加

### 背景・問題意識

提示物選択の待ち合わせカレンダーでは、長押しで時間帯を選択したり、カレンダー上で横スワイプして週を切り替える操作がある。iOS版はドラッグ状態そのものは持っていたが、週スワイプや長押し選択に入った瞬間のスクロール抑制が弱く、時間帯を選ぼうとした時に縦スクロールへ逃げる可能性があった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- カレンダー操作専用の `calendarGestureLock` を追加した。
- 長押し時間選択、候補の移動/リサイズ、時間グリッド上の横スワイプが始まった時に、カレンダーの縦スクロールを明示的に停止するようにした。
- タッチ終了・キャンセル・候補編集終了時にロックを解除し、通常の軽い縦スクロールは従来通り使えるようにした。

### 影響範囲

- iOS版 提示物の選択 > 待ち合わせタブ
- カレンダー上の長押し時間選択
- カレンダー上の横スワイプ週切替
- 候補時間ブロックの移動 / 終了時刻調整

### 確認方法

- 待ち合わせカレンダーで長押し後に下方向へドラッグしても、画面スクロールではなく時間帯選択が伸びることを確認
- 時間グリッド上で横スワイプすると、週が切り替わることを確認
- 軽い縦スクロールでは、これまで通り0時〜24時へスクロールできることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 長押し・横スワイプ・候補編集時だけスクロールを止め、通常の縦スクロールは残した
- ✅ カレンダー候補の保存・場所設定・送信確認へのルートは変更していない
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.78：iOSホームのモード切替フィードバックをWeb版へ同期

### 背景・問題意識

Web版ホームでは、全国交換モードと今すぐ現地交換モードを切り替える瞬間に、短時間の「切り替え中」表示を出して操作の手応えを作っている。iOS版はセグメント自体のアニメーションはあったが、切り替え処理中のステータスが出ず、Web版より反応が薄く見える余地があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- モード切替時に、画面上部へ短時間のステータスピルを表示するようにした。
- 現地表示へ切り替える時は `今すぐ現地交換モードに切り替え中…`、全国表示へ切り替える時は `全国交換モードに切り替え中…` を表示するようにした。
- 右上トグルで現地交換モード自体をOFFにしない限り、全国表示へ切り替えても `localMode` は維持する既存挙動を残した。

### 影響範囲

- iOS版 ホーム画面
- 全国交換モード / 今すぐ現地交換モードの表示切替

### 確認方法

- ホームのセグメントを押すと、上部に短時間の切り替え中ピルが出ることを確認
- 現地交換モードON中に全国交換モード表示へ切り替えても、右上トグルがONのまま維持されることを確認
- 右上トグルをOFFにした時だけ現地交換モード自体がOFFになることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ Web版の切り替え中フィードバックをiOS版にも追加した
- ✅ ユーザー要望の「全国表示を見ても現地交換モード自体はOFFにしない」挙動は維持した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.77：iOS在庫登録のメンバー追加リクエストをWeb版へ同期

### 背景・問題意識

Web版の在庫登録フローでは、ラベル設定中に「メンバーが見つからない場合は追加リクエスト」を押すと、その場でメンバー名と任意メモを入力でき、送信済みリクエストが審査中チップとして表示される。iOS版は一行のOSプロンプトでメンバー名だけを送る形だったため、Web版のマスタ管理フローと情報量がズレていた。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫登録フローのメタ設定ステップに、Web版と同じくインラインのメンバー追加リクエストフォームを追加した。
- メンバー名に加えて、公式リンク・別名などを書ける任意メモを `character_requests.note` へ保存するようにした。
- 送信後はフォームを閉じ、送信済みリクエストを「審査中」チップとして表示するようにした。
- 送信したリクエストはそのままメンバー候補にも追加され、登録ラベルで選択できるようにした。

### 影響範囲

- iOS版 マイ在庫 > 新規登録 > ラベル設定
- iOS版 在庫登録中のメンバー追加リクエスト

### 確認方法

- マイ在庫の新規登録で写真選択または写真なし登録へ進み、ラベル設定で追加リクエストフォームが開くことを確認
- メンバー名とメモを入力して送信すると、審査中候補として選べることを確認
- 送信済みリクエストのチップが表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/goods-editor.tsx`
- `web/src/app/inventory/new/CaptureFlow.tsx`

### セルフレビュー結果

- ✅ Web版のメンバー追加リクエストと同じ入力項目・送信後表示に寄せた
- ✅ 既存の在庫登録・タグ・説明メモ・写真登録フローは残した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.76：iOS取引詳細の一覧スナップショット復元

### 背景・問題意識

iOS版の取引一覧からパネルを押した時、一覧では打診データを取得できているのに詳細画面側の再取得で失敗すると「読み込みに失敗しました」だけが表示され、取引チャットへ進めない体験になっていた。Web版は一覧から詳細へ入る導線が取引体験の主軸なので、詳細取得が一時的に失敗しても一覧で見えていた最低限の情報は崩さず表示する必要がある。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 取引パネル押下時に、打診IDだけでなく相手名、アバター、ステータス、受け取る/出すグッズ、場所、時間、メモをルートパラメータへ渡すようにした。

#### `mobile/app/transaction-detail.tsx`
- 詳細画面で `proposals` の再取得に失敗した場合、一覧から渡されたスナップショットを使って取引詳細を復元するフォールバックを追加した。
- フォールバック表示でも相手情報、交換物、候補場所/時間、メッセージを最低限表示できるようにした。
- 日時が実ISO文字列でないフォールバック候補でも `NaN` 表示にならないよう、日時フォーマッタに防御を入れた。

### 影響範囲

- iOS版 取引一覧 > 取引詳細
- iOS版 打診中 / 進行中 / 完了パネルの詳細遷移

### 確認方法

- 打診中の「相手待ち」パネルを押して、404や「読み込みに失敗しました」だけで止まらないことを確認
- 詳細取得が成功する場合は従来通り実データの取引チャットが表示されることを確認
- 詳細取得に失敗する場合も、一覧で見えていた相手名・交換物・場所/時間が表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/transaction-detail.tsx`
- `web/src/app/transactions/TransactionsView.tsx`
- `web/src/app/proposals/[id]/ProposalDetailView.tsx`

### セルフレビュー結果

- ✅ 一覧の実データを詳細画面へ渡すだけで、新しいDB列や状態を追加していない
- ✅ 実データ取得成功時の既存チャット・合意・到着ステータス処理は残した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.75：iOSオンボーディング完了判定をWeb版へ同期

### 背景・問題意識

Web版はメール認証後、性別、推し、メンバー、活動エリアの順でオンボーディングを進め、最後の活動エリア保存で `account_status` を `active` にする。一方、iOS版は `account_status=active` の場合に性別や推しの登録有無を見ずホームへ入れる余地があり、新規登録後にオンボーディングを経ずホームへ進む挙動が起きやすかった。

### 変更内容

#### `mobile/src/auth/AuthProvider.tsx`
- プロフィール取得時に `user_oshi` の件数も読み込み、`hasOshi` として認証コンテキストへ持たせるようにした。
- `account_status=active` でも、性別または推しが未登録ならオンボーディングが必要と判定するようにした。
- 未完了状態に応じて `/onboarding/gender`、`/onboarding/oshi`、`/onboarding/members` へ進める `onboardingPath` を追加した。
- Appleログイン直後のように React state の `session` 反映前でもプロフィールを読めるよう、`supabase.auth.getUser()` をフォールバックにした。

#### `mobile/app/(tabs)/_layout.tsx`
- ログイン済みだがオンボーディング未完了の場合、確認完了画面ではなく未完了ステップへ直接戻すようにした。

#### `mobile/app/(auth)/_layout.tsx`
- 認証画面側でも、ログイン済み未完了ユーザーは未完了ステップへ戻すようにした。

#### `mobile/src/components/AppleAuthButton.tsx`
- Apple IDログイン後の遷移判定を `gender` / `hasOshi` / `account_status` の順に見直し、Web版と同じオンボーディング導線へ進めるようにした。

#### `mobile/app/auth/email-confirmed.tsx`
- 認証完了ボタンの遷移先を、現在の未完了ステップに合わせるようにした。

### 影響範囲

- iOS版 ログイン / 新規登録 / Apple IDログイン
- iOS版 メール認証完了後のオンボーディング導線
- iOS版 タブ画面へ入る前のガード

### 確認方法

- 性別未登録ユーザーでログインすると `/onboarding/gender` に進むことを確認
- 性別登録済み・推し未登録ユーザーでログインすると `/onboarding/oshi` に進むことを確認
- 推し登録済みだが `account_status` が未完了のユーザーでログインすると `/onboarding/members` に進むことを確認
- 既に `active` かつ性別・推しがあるユーザーはホームに進むことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(auth)/_layout.tsx`
- `mobile/src/components/AppleAuthButton.tsx`
- `mobile/app/auth/email-confirmed.tsx`
- `web/src/app/onboarding/actions.ts`

### セルフレビュー結果

- ✅ Web版のオンボーディング完了条件に合わせ、`account_status` だけでホームへ通さないようにした
- ✅ 活動エリアはWeb版同様に任意入力のため、未設定でも `active` ユーザーを再オンボーディングへ戻さない
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.74：iOS関係図を実個別募集データで描画

### 背景・問題意識

ホームから個別募集に合致したマッチ候補を押した時、Web版はその候補に紐づく実際の個別募集・選択肢・グッズ画像を使って関係図を描画する。一方、iOS版の関係図は `listingIds` が渡っていても、ルートパラメータとプレビュー用の仮データから関係図を組み立てていたため、実データの画像が抜けたり、Web版と違う関係が表示されやすかった。

### 変更内容

#### `mobile/app/match-detail.tsx`
- `listingIds` が渡された場合、`listings` / `listing_wish_options` / `goods_inventory` を読み込み、実際の個別募集データから関係図を組み立てるようにした。
- 実データから譲グッズ、求めるWish、候補グッズの画像・タイトル・グループ/メンバー/種別を復元するようにした。
- 自分の個別募集か相手の個別募集かを `listings.user_id` とログインユーザーIDで判定し、Web版と同じ向きで「私が出す」「受け取る」を集計できるようにした。
- 実データ取得に失敗した場合は既存の簡易関係図へフォールバックし、画面遷移自体は止めないようにした。

### 影響範囲

- iOS版 ホーム > 関係図
- iOS版 関係図から提示物選択へ進む時の初期選択
- 個別募集ヒット候補の画像表示

### 確認方法

- ホームで個別募集に合致した候補を押し、関係図内のグッズ画像が実データの画像になることを確認
- 自分の個別募集 / 相手の個別募集それぞれで、譲と求の向きが崩れないことを確認
- 実データ取得に失敗しても画面全体が落ちないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/match-detail.tsx`
- `web/src/components/home/HomeView.tsx`
- `web/src/app/listings/new/ListingNewForm.tsx`

### セルフレビュー結果

- ✅ Web版と同じく、関係図を候補に紐づく個別募集単位のデータで描く経路を追加した
- ✅ 既存のスワイプ遷移・提示物選択への遷移・簡易Wish一致フローは残した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.73：iOSホーム候補を候補単位のWebロジックへ同期

### 背景・問題意識

Web版ホームでは、候補カードごとに「自分の個別募集に含まれるか」「相手の個別募集に含まれるか」を判定し、その候補自身が個別募集に絡む場合だけ関係図へ進む。iOS版は相手とのマッチ全体に個別募集があると、個別募集に含まれていない候補まで関係図へ進みやすく、以前指摘された「選べない候補なのに関係図へ飛ぶ」挙動が再発しうる状態だった。また、Web版で行っているタグ類似度による並び替えとタグ表示が、iOS版の実データ取得では未反映だった。

### 変更内容

#### `mobile/src/data/homeSupabase.ts`
- 個別募集ヒットを相手単位ではなく、相手の譲グッズ候補ID単位で保持するようにした。
- 候補カードの優先度を「双方の個別募集」「一方の個別募集」「通常の譲 × Wish」の順で、候補ごとに再計算するようにした。
- 個別募集に含まれない通常候補は `listingIds` を空にし、ホームから押した時に関係図ではなく提示物選択へ進めるようにした。
- `goods_inventory_tags` / `tags_master` を読み込み、候補タグの表示とタグJaccard類似度による並び替えをiOS側にも追加した。
- ホーム棚はWeb版と同じく「自分のWishに届いた相手の譲グッズ」を対象にし、自分が出すだけの候補をホームの受け取り棚へ混ぜないようにした。

#### `mobile/src/data/homeMatches.ts`
- 候補に `tagScore` を持たせ、ホーム棚のソートに使えるようにした。

#### `mobile/app/(tabs)/index.tsx`
- 現地交換OFF時の右上表示をWeb版と同じ `（現地交換モードOFF）` に寄せ、長い表示でも収まりやすい幅に調整した。

### 影響範囲

- iOS版 ホーム画面
- ホームのマッチ候補カードの並び順・タグ表示・押下後の遷移
- 現地交換モードOFF時の場所表示

### 確認方法

- 個別募集に含まれていない通常候補を押すと、関係図ではなく提示物選択へ進むことを確認
- 個別募集に含まれる候補だけ関係図へ進むことを確認
- タグ付きの相手譲グッズで、カード下部にタグが表示され、タグ類似度が高い候補が上に来ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/src/data/homeSupabase.ts`
- `mobile/src/data/homeMatches.ts`
- `mobile/app/(tabs)/index.tsx`
- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ Web版の候補単位判定に合わせ、マッチ全体の個別募集状態を候補へ雑に流用しない形にした
- ✅ タグ類似度は既存の `goods_inventory_tags` / `tags_master` を読むだけで、新しいDB列は追加していない
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.72：iOS取引一覧にWeb版の補助情報を同期

### 背景・問題意識

Web版の取引一覧は、取引パネル上で相手アバター、完了取引の自分の評価、進行中の異議申告、定価交換のプレビューを表示している。一方、iOS版の取引一覧は最小限の相手名とグッズ画像だけで、Web版に比べて状態判断の情報量が不足していた。また、取引一覧から詳細へ進む時に、異議申告中の取引はWeb版では申告詳細へ進む設計になっている。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 取引一覧のデータ取得で、相手の `avatar_url`、完了取引に対する自分の `user_evaluations.stars`、open な `disputes` を取得するようにした。
- `avatar_url` は列がない環境でも壊れないよう、選択列フォールバック付きで取得するようにした。
- 定価交換の打診では、Web版と同じく `¥` のキャッシュ用ミニカードを取引プレビューに表示するようにした。
- open dispute がある取引パネルは要対応扱いにし、タップ時は取引詳細ではなく `dispute-detail` へ進むようにした。

### 影響範囲

- iOS版 取引一覧
- 取引パネルの状態表示
- 異議申告中取引の遷移先

### 確認方法

- 完了タブで自分の評価済み取引に `★ n` が表示されることを確認
- 異議申告中の進行中取引が要対応表示になり、タップで申告詳細へ進むことを確認
- 定価交換を含む打診で `¥` のプレビューが表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `web/src/app/transactions/page.tsx`
- `web/src/app/transactions/TransactionsView.tsx`

### セルフレビュー結果

- ✅ Web版の取引一覧で参照している補助情報をiOS側にも追加した
- ✅ 取得できない補助情報は空として扱い、一覧全体が落ちないようにした
- ✅ 状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.71：iOS待ち合わせ空カレンダー案内を鼓動表示へ

### 背景・問題意識

オーナーから、提示物の選択 > 待ち合わせタブで候補が未設定のときは、カレンダー中央に固定された黒い半透明の案内を出し、その背景が少し大きくなったり小さくなったりするような動きにしたいと要望があった。iOS版では案内自体は中央固定で表示できていたが、静的表示のままで「ここから操作できる」サインが弱かった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 候補未設定かつドラッグプレビューがない時だけ、案内バッジに `Animated.loop` の軽いスケール/透明度アニメーションを付与した。
- 候補作成またはドラッグ中はアニメーションを停止し、既存のカレンダー操作・候補作成・場所設定導線を邪魔しないようにした。

### 影響範囲

- iOS版 提示物の選択 > 待ち合わせタブ
- 候補未設定時の空状態ガイド

### 確認方法

- 待ち合わせタブを候補0件で開き、黒い半透明の案内がカレンダー中央付近で控えめに拡縮することを確認
- 候補時間を作成したら案内が消え、場所設定シートが開くことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 既存の長押しドラッグ、タップ30分作成、週スワイプ、候補移動/リサイズは変更していない
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.70：iOS待ち合わせ候補から場所設定へ即接続

### 背景・問題意識

Web版の提示物選択 > 待ち合わせでは、候補時間を作った後にその候補へ場所を紐づける流れが自然につながる。一方、iOS版では候補時間だけが追加され、ユーザーが改めて候補ブロックを押さないと場所設定へ進めなかった。過去要望でも「ドラッグで候補時間を選択した後、自動的に交換場所の設定ポップアップが出てくる」挙動が求められていた。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 待ち合わせ候補を新規作成した直後に、作成した候補を active にし、場所設定シートを自動で開くようにした。
- 候補IDを `Date.now()` 単独からランダム suffix 付きへ変更し、連続作成時のID衝突リスクを下げた。

### 影響範囲

- iOS版 提示物の選択 > 待ち合わせタブ
- 候補時間作成後の場所設定導線

### 確認方法

- 待ち合わせタブで空き枠をタップし、30分候補が作成されて場所設定シートが開くことを確認
- 長押しドラッグで時間帯を作成し、同じく場所設定シートが開くことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 既存の場所未設定アラート、前の設定適用、削除、候補移動/リサイズの挙動は残した
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.69：iOS在庫編集をWeb版の廃止項目に再同期

### 背景・問題意識

オーナーから「在庫の編集画面も、Wishの編集画面もちゃんとWebアプリ版に合わせてください。機能も、それぞれの項目のマスタ管理のところも。寸分違わず」と指摘があった。Web版の在庫編集では過去 iter65.8 / iter61.10 の判断により、既存在庫編集の「シリーズ・弾名」と「コンディション」はUIから廃止されており、説明欄も編集時は500文字上限になっている。一方、iOS版の既存在庫編集ではこの2項目をまだ表示・更新でき、説明も1000文字上限だった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 既存在庫の編集画面から「シリーズ・弾名」と「コンディション」セクションを非表示にした。
- 既存在庫の保存時に `series` / `condition` を更新対象から外し、画面にない項目を編集操作で変更しないようにした。
- 在庫編集時の説明 / メモの上限をWeb版編集画面と同じ500文字にした。
- 在庫新規登録フローにある共通メモ・シリーズ・コンディションは、現行作成フロー側の入力として維持した。

### 影響範囲

- iOS版 マイ在庫の既存グッズ編集
- iOS版 マイ在庫の詳細のみ表示

### 確認方法

- 既存在庫の編集画面で「シリーズ・弾名」「コンディション」が表示されないことを確認
- 説明 / メモが 500 文字カウントになり、500文字を超えて入力できないことを確認
- 保存時に写真・グループ・メンバー・種別・数量・タグ・説明は更新できることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/goods-editor.tsx`
- `web/src/app/inventory/[id]/EditForm.tsx`

### セルフレビュー結果

- ✅ Web版の既存在庫編集UIで廃止済みの項目をiOS版からも外した
- ✅ 新規登録フローの直近追加項目は削除せず、既存編集画面だけを再同期した
- ✅ 状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.68：iOS取引一覧のプレビューID混入を抑止

### 背景・問題意識

iOS版でログイン後も、画面によってプレビュー用の情報が一瞬読み込まれると指摘があった。取引一覧では、プレビュー状態から実ログイン状態へ切り替わった直後に、実データ取得が完了するまで既存 state のプレビュー取引（`tx-xx`）が残る可能性があり、そのパネルを押すと実DB上の打診IDではないため詳細画面で「読み込みに失敗しました」につながり得る。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 実ログイン状態で取引一覧の取得を開始する直前に、既存の `transactions` state を空配列へクリアするようにした。
- これにより、実データ取得中にプレビュー用 `tx-xx` パネルが押せる状態を作らないようにした。

### 影響範囲

- iOS版 取引一覧
- プレビュー状態からログイン状態へ切り替わる直後の表示
- 取引詳細への遷移ID

### 確認方法

- プレビュー表示後にログインし、取引一覧を開いて実データ取得中に `tx-xx` のプレビューパネルが表示されないことを確認
- 実データの取引パネルを押して `/transaction-detail?id=<proposal_uuid>` で開くことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ ユーザー指摘の「プレビュー情報が一瞬見える」問題を取引一覧で抑止
- ✅ 取引状態名・DB列は変更していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.67：iOS在庫新規登録に説明メモを追加

### 背景・問題意識

Web版の在庫新規登録では「説明 / メモ」を入力でき、状態の補足や入手経路などを `goods_inventory.description` に保存できる。一方、iOS版の在庫新規登録フローは写真ごとのラベル設定とタグまでは対応していたが、保存時に `description: null` を固定で入れていたため、作成時点で補足情報を残せなかった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫新規登録フローに、全グッズへ共通付与する「説明 / メモ」入力欄を追加した。
- 入力文字数を Web版と同じ 1000 文字上限にし、保存前バリデーションも追加した。
- 新規登録時の `goods_inventory.description` に入力内容を保存するようにした。

### 影響範囲

- iOS版 マイ在庫の新規登録
- 複数写真をまとめて登録する場合の共通説明メモ

### 確認方法

- iOS版マイ在庫の新規登録で、ラベル設定画面に「説明 / メモ」が表示されることを確認
- 入力したメモが登録後の編集画面で表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/goods-editor.tsx`
- `web/src/app/inventory/new/InventoryNewForm.tsx`

### セルフレビュー結果

- ✅ Web版在庫新規登録にある説明メモをiOS版にも追加
- ✅ 既存DB列の利用のみで新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.66：iOSプロフィール編集の活動エリアを選択式に同期

### 背景・問題意識

Web版のプロフィール編集では「主な活動エリア（都道府県）」をプルダウンで選択するが、iOS版では「活動エリア」の自由入力欄のままだった。Webアプリとスマホアプリを照合すると、同じプロフィール情報なのに入力方式と表示セクションがずれており、ユーザーが異なる値を保存しやすい状態だった。

### 変更内容

#### `mobile/app/profile-edit.tsx`
- Web版と同じ47都道府県リストを追加し、活動エリアを自由入力から選択式に変更した。
- 性別と活動エリアを「公開情報」セクションにまとめ、Web版の「マッチング前に表示」文脈に寄せた。
- 活動エリア選択用のネイティブ下部シートを追加し、背景タップ・閉じるボタン・「指定なし」選択に対応した。
- 保存前バリデーションを「50文字以内」から「都道府県リストから選択」に変更した。

### 影響範囲

- iOS版 プロフィール編集
- `users.primary_area` に保存される活動エリアの入力方式

### 確認方法

- iOS版プロフィール編集で「主な活動エリア（都道府県）」を押し、都道府県選択シートが開くことを確認
- 「指定なし」または任意の都道府県を選択して保存できることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/profile-edit.tsx`
- `web/src/app/profile/edit/ProfileEditForm.tsx`

### セルフレビュー結果

- ✅ Web版の都道府県選択方式とラベルに寄せた
- ✅ 性別はWeb版と同じく再タップで未選択に戻せるようにした
- ✅ 既存DB列の利用のみで新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.65：iOS取引完了フィルタの潰れを修正

### 背景・問題意識

iOS版の取引一覧で、完了タブ上部のステータスフィルタ表示が潰れて見えるという指摘があった。従来は「キャンセル 0」のようにラベルと件数を1つのテキストに押し込んでおり、横幅やフォント描画によって窮屈に見えやすかった。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 完了タブのフィルタチップを、ラベルと件数バッジに分離した。
- チップの高さ・最小幅・余白を少し広げ、横スクロール内で文字が潰れないようにした。
- active時の件数バッジも白透明背景にして、iOS版の取引一覧トーンに合わせた。

### 影響範囲

- iOS版 取引一覧の完了タブ
- 完了 / キャンセル / 終了フィルタの表示

### 確認方法

- iOS版取引一覧で「完了」タブを開き、各フィルタチップの文字と件数が潰れず表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ ラベルと件数を分離し、長い「キャンセル」でも圧迫されにくい表示にした
- ✅ データ取得・状態名・DBには影響なし
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.64：iOS在庫編集にシリーズと状態を同期

### 背景・問題意識

Web版の在庫作成・編集では「シリーズ・弾名」と「コンディション」を登録できるが、iOS版は同じ `goods_inventory` を扱っているにもかかわらず、この2項目を常に `null` 保存していた。オーナーから「在庫の編集画面もWishの編集画面もWebアプリ版に合わせて」と指摘があり、グッズの同定・交換判断に使う情報差を埋める必要があった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫編集フォームに「シリーズ・弾名」と「コンディション」を追加した。
- 在庫新規登録フローにも同じ2項目を追加し、複数写真からまとめて登録する場合も全グッズへ反映するようにした。
- `goods_inventory.series` / `goods_inventory.condition` を読み込み、更新・新規作成時に保存するようにした。
- 在庫の説明文字数上限をWeb版に合わせて 1000 文字へ広げた。

### 影響範囲

- iOS版 マイ在庫の新規登録
- iOS版 マイ在庫の編集
- `goods_inventory.series` / `goods_inventory.condition` の保存内容

### 確認方法

- iOS版で在庫を新規登録し、シリーズ・コンディションが保存されることを確認
- 既存在庫を編集し、シリーズ・コンディションが初期表示され、更新できることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ Web版の在庫作成フォームにある情報項目をiOS版にも追加
- ✅ ステータス更新機能は追加しておらず、過去要望の「編集画面からステータス更新をなくす」に抵触しない
- ✅ 既存DB列の利用のみで新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.63：iOS Apple認証後のオンボーディング遷移を修正

### 背景・問題意識

iOS版で「新規登録してもそのままホーム画面に行ってしまう」と指摘があった。Apple ID認証ボタンは、サインアップ/サインインの区別やプロフィール状態に関係なく、認証成功後に `router.replace("/")` していたため、オンボーディング未完了ユーザーでも一瞬ホームへ向かう挙動になりやすかった。

### 変更内容

#### `mobile/src/components/AppleAuthButton.tsx`
- Apple ID認証成功後に `refreshProfile()` を呼び、現在のプロフィール状態を確認するようにした。
- サインアップ導線、または `account_status` が `active` でない / `gender` 未設定の場合は `/onboarding/gender` へ直接遷移するようにした。
- 既存のアクティブユーザーは従来通りホームへ遷移する挙動を維持した。

### 影響範囲

- iOS版 Apple IDで新規登録
- iOS版 Apple IDでログイン
- オンボーディング未完了ユーザーの初回導線

### 確認方法

- Apple ID新規登録後、ホームではなくオンボーディングの性別画面へ進むことを確認
- オンボーディング完了済みアカウントでApple IDログインした場合はホームへ進むことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/src/components/AppleAuthButton.tsx`

### セルフレビュー結果

- ✅ Web版と同じく、登録後にプロフィール/オンボーディング設定へ進む導線に寄せた
- ✅ 既存ユーザーの通常ログイン導線は維持
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.62：iOSプロフィール編集にアイコン選択を追加

### 背景・問題意識

Web版のプロフィール編集は、アイコン画像を選択して切り抜き、`avatars` bucket にアップロードして `avatar_url` として保存できる。一方iOS版は「ネイティブの画像選択は次の実装で追加します」という未実装文言が残っており、Web版との機能差がはっきり見えていた。

### 変更内容

#### `mobile/app/profile-edit.tsx`
- アイコン画像の「選択 / 変更」ボタンを追加した。
- カメラ撮影または写真ライブラリ選択を選べるアクションを追加した。
- 選択画像は 1:1 で切り抜き、`avatars` bucket にアップロードしてフォームの `avatarUrl` に反映するようにした。
- アップロード中表示と権限エラー表示を追加し、既存の削除・保存導線と接続した。

### 影響範囲

- iOS版 プロフィール編集
- プロフィールアイコン画像の選択・変更・削除・保存

### 確認方法

- iOS版プロフィール編集で「選択」または「変更」を押し、カメラ/写真選択が出ることを確認
- 画像選択後、1:1切り抜き後にアイコンプレビューへ反映されることを確認
- 保存後、プロフ画面のアバターに反映されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/profile-edit.tsx`

### セルフレビュー結果

- ✅ Web版プロフィール編集のアイコンアップロード機能に近づけた
- ✅ 未実装文言を削除し、実際の操作導線へ置き換えた
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.61：iOS編集画面のフォールバック表示を抑止

### 背景・問題意識

iOS版で「どの画面でもプレビュー用かなにかの情報が一瞬読み込まれる」と指摘があった。プロフィール編集と在庫/Wish編集は、実データの読み込み中でも初期フォールバック値をフォームとして描画しており、通信が終わるまでの一瞬だけ仮の表示名・仮のマスタ・仮タイトルが見えてしまう可能性があった。

### 変更内容

#### `mobile/app/profile-edit.tsx`
- 実アカウントのプロフィール読み込み中は、フォーム本体を描画せず「プロフィールを読み込み中…」だけを表示するようにした。

#### `mobile/app/goods-editor.tsx`
- 在庫作成フローでは、マスタ読み込み中に `InventoryCreateFlow` を描画しないようにした。
- 在庫/Wish編集フローでは、マスタと登録内容の読み込み完了までフォーム本体と保存ボタンを描画しないようにした。

### 影響範囲

- iOS版 プロフィール編集
- iOS版 マイ在庫 作成/編集
- iOS版 Wish 作成/編集
- 読み込み中の表示体験

### 確認方法

- 実ログイン状態でプロフィール編集を開き、読み込み完了前に仮の `michi` / `ゲスト` がフォーム表示されないことを確認
- 実ログイン状態で在庫/Wish編集を開き、マスタ読み込み中に仮の候補フォームが出ないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/profile-edit.tsx`
- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ ユーザーに見えるプレビュー/フォールバック値の一瞬表示を抑えた
- ✅ previewMode や Supabase未設定時のプレビュー導線は維持
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.60：iOS送信確認のデモ候補混入を停止

### 背景・問題意識

待ち合わせタブでは、何も候補を設定していないのに送信確認側で候補があるように見えると、ユーザーは「見えない候補が勝手に入っている」と感じる。iOS版の送信確認画面には、`meetups` パラメータが無い・壊れている場合にデモ用の待ち合わせ候補を返すフォールバックが残っており、実データの確認画面として不自然だった。

### 変更内容

#### `mobile/app/proposal-confirm.tsx`
- `meetups` パラメータが無い場合、送信確認画面では待ち合わせ候補を空配列として扱うようにした。
- `meetups` のJSONが配列でない場合やパースできない場合も、デモ候補へ戻さず空配列にした。
- 候補が空の場合は既存の送信時バリデーションで「交換できる時間と場所を設定してください」と止める挙動にした。

### 影響範囲

- iOS版 提示物の選択 > 送信確認
- 待ち合わせ候補未設定時の表示
- 送信前バリデーション

### 確認方法

- `meetups` なしで送信確認を開いても、デモ候補が表示されないことを確認
- 通常の待ち合わせタブから候補を設定して進んだ場合は、設定した候補だけが表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/proposal-confirm.tsx`

### セルフレビュー結果

- ✅ 実フローに存在しないデモ候補が混入しないようにした
- ✅ 送信時の時間・場所必須ガードは維持
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.59：iOS待ち合わせ候補を時間先行で追加

### 背景・問題意識

待ち合わせタブでは「まず交換できる時間だけ複数押さえて、その後に場所を設定する」体験が求められている。iOS版は候補時間を追加した瞬間に場所設定シートを開いており、続けて候補2・候補3をカレンダー上で作る流れを遮りやすかった。また候補追加時に既存候補を3件へ丸める処理があり、ユーザーに見えない形で候補が消える可能性があった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- カレンダー上で候補時間を追加した時、自動で場所設定シートを開かず、時間候補だけを配置するようにした。
- 場所未設定候補は従来通り `!` 表示で示し、候補ブロックをタップすると場所設定へ進む挙動を維持した。
- 候補追加時に既存候補を `slice(0, 2)` で丸める処理をやめ、複数候補をそのまま積み上げられるようにした。

### 影響範囲

- iOS版 提示物の選択 > 待ち合わせタブ
- カレンダーでの候補時間追加
- 候補場所設定シートへの遷移

### 確認方法

- iOS版の待ち合わせタブで、場所を設定しないまま候補1・候補2を連続して追加できることを確認
- 場所未設定候補に `!` が表示され、候補をタップすると場所設定シートが開くことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 後続仕様の「先に時間、後で場所」に寄せた
- ✅ 送信前に全候補の場所設定を要求する既存ガードは維持
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.58：iOS取引詳細の取得フォールバックを追加

### 背景・問題意識

iOS版の取引一覧からカードを押した時に「読み込みに失敗しました」と出るケースが残っていた。取引詳細はWeb版の取引チャットより多めの任意カラム（複数待ち合わせ候補、証跡、完了承認など）を一括取得しており、環境差やスキーマキャッシュ差分で任意カラム側が不安定な場合に、詳細画面全体が開けなくなるリスクがあった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- 取引詳細の `proposals` 取得を、Web版に近い基本カラムとiOS拡張用の任意カラムに分けた。
- まず従来通り拡張カラム込みで取得し、失敗した場合は基本カラムだけで再取得するフォールバックを追加した。
- 任意カラムが取れない場合も、相手・提示物・基本メッセージ・待ち合わせ基本情報で詳細画面を表示できるようにした。

### 影響範囲

- iOS版 取引一覧から取引詳細への遷移
- iOS版 取引チャット / ネゴチャット表示
- スキーマ差分がある環境での取引詳細表示

### 確認方法

- iOS版取引一覧で打診中・進行中・完了のカードを押し、詳細が開けることを確認
- 任意カラムが利用できる環境では、これまで通り証跡や完了承認情報も表示されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ Web版の基本取引チャット取得に近い最低限の表示経路を確保
- ✅ 任意カラムを削ったわけではなく、取得失敗時のフォールバックのみ追加
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.57：iOS編集画面の写真差し替えを同期

### 背景・問題意識

Web版の在庫編集は「撮り直す / 差し替え」、Wish編集は「差し替え / 画像を選択」という導線で、編集時にも写真を自然に入れ替えられる。一方iOS版の在庫/Wish編集は写真ライブラリ固定で、在庫作成フロー側のカメラ撮影・切り抜き体験とも少しズレていた。Web版の編集体験とiOS版の作成体験を近づけるため、編集画面の写真差し替え導線を整える。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫/Wish編集画面の写真ボタン押下時に、カメラ撮影・写真選択・閉じるを選べるアクションを追加した。
- 編集時の写真差し替えでも、作成フローと同じく 1:1 の切り抜き編集を挟むようにした。
- カメラ権限と写真ライブラリ権限のエラー文を、それぞれの操作に合わせて出し分けるようにした。

### 影響範囲

- iOS版 マイ在庫編集画面
- iOS版 Wish編集画面
- 画像差し替え・追加導線

### 確認方法

- iOS版の在庫編集で写真ボタンを押し、カメラ撮影と写真選択の選択肢が出ることを確認
- iOS版のWish編集で画像未登録時・登録済み時の写真ボタンから同じ選択肢が出ることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ Web版の編集時写真差し替え導線に近づけた
- ✅ 既存の個別募集紐付けWishの画像削除ロックは維持
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.56：iOS通常マッチの遷移を同期

### 背景・問題意識

Web版では、ホームのマッチングパネルを押した時、選んだグッズが自分または相手の個別募集に含まれている場合だけ関係図へ進み、個別募集に紐づかない通常の譲×Wish一致は提示物選択へ進む。iOS版は `listingIds` が空の通常候補でも関係図へ遷移しており、選択できない候補が関係図に出るという過去フィードバックと同じズレが残っていた。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホームの候補カード押下時、個別募集IDがない候補は `/match-detail` ではなく `/proposal-select` へ直接遷移するようにした。
- 遷移時に `candidateId` / `partnerId` / `matchType` / `gives` / `receives` を渡し、選んだ通常マッチ候補を提示物選択へ引き継げるようにした。
- 個別募集に紐づく候補は従来通り関係図へ進む挙動を維持した。

### 影響範囲

- iOS版 ホーム
- iOS版 マッチングパネル押下後の遷移
- 個別募集マッチと通常の譲×Wish一致の分岐

### 確認方法

- iOS版ホームで、個別募集に紐づく候補を押すと関係図へ進むことを確認
- iOS版ホームで、通常の譲×Wish一致候補を押すと提示物選択へ進むことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ Web版の「関係図へ進む条件」とiOS版の遷移条件を揃えた
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.55：iOS取引一覧に交換物画像を表示

### 背景・問題意識

Web版の取引一覧カードは、交換物の小さな画像プレビューを表示して、ユーザーが「どの取引か」を視覚的に思い出しやすい。一方iOS版は `goods_inventory.photo_urls` を取得しておらず、カード内の交換物が文字プレースホルダー中心になっていた。Web版との情報量差があり、取引一覧から詳細へ進む前の判断が弱く見えるため、iOS版にも実画像プレビューを反映する。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 取引一覧の `goods_inventory` 取得に `photo_urls` を追加した。
- `TradeItem` に `photoUrl` を持たせ、画像がある交換物はカード内サムネイルとして表示するようにした。
- 画像がない場合は従来通り、文字プレースホルダーを表示するフォールバックを維持した。

### 影響範囲

- iOS版 取引一覧
- 打診中 / 進行中 / 完了カード内の交換物プレビュー

### 確認方法

- iOS版取引一覧で、写真付きの在庫/Wishに紐づく取引カードに画像サムネイルが出ることを確認
- 写真なしの取引カードは従来通り文字プレースホルダーで崩れないことを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ Web版取引一覧の交換物画像プレビューに近づけた
- ✅ 画像なしデータへのフォールバックを維持
- ✅ 新しい状態名・用語・DB列追加はないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` の更新は不要

---

## イテレーション155.54：iOS個別募集保存に市場残数ガードを追加

### 背景・問題意識

Web版の個別募集作成・更新は、保存直前に `assertProposalItemsMarketAvailable` で「自分の譲グッズか」「交換対象か」「合意済み打診で予約された分を差し引いても残数が足りるか」を検証している。一方iOS版は、画面を開いた時点の市場残数で選択上限を制御していたが、保存直前の再検証が弱く、古い画面を開いたまま更新した場合にWeb版よりキャパ超過に弱かった。

### 変更内容

#### `mobile/app/listing-editor.tsx`
- 個別募集の作成・更新直前に、譲グッズの所有者・分類・状態・市場残数を再検証する `assertListingHavesMarketAvailable` を追加した。
- 合意済み打診で未完了承認の譲在庫を市場残数から差し引くロジックを、表示時だけでなく保存時にも使うようにした。
- Web版と同じ文脈のエラー文（使えない譲グッズ名、状態、必要数/市場残数/登録数）をiOS側でも返すようにした。

### 影響範囲

- iOS版 個別募集 作成画面
- iOS版 個別募集 編集画面
- マイ在庫の市場残数と個別募集条件の整合性

### 確認方法

- iOS版で個別募集を作成・更新し、通常の保存が通ること
- 合意済み打診で市場残数が不足している譲グッズを含めた場合、具体的なエラーが表示されること
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/listing-editor.tsx`

### セルフレビュー結果

- ✅ Web版の市場残数ガードと同じ事故防止方針をiOS版にも追加
- ✅ DBスキーマ変更なし。既存 `goods_inventory` / `proposals` 読み取りのみ
- ✅ 新しい状態名・用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` の更新は不要

---

## イテレーション155.53：iOS取引一覧の要対応判定をWeb版へ同期

### 背景・問題意識

オーナーから、Webアプリとスマホアプリを継続照合し、未開発・未同期の機能を止めるまで開発し続けるよう指示があった。照合したところ、Web版の取引一覧は `negotiating` の「要対応／相手待ち」を最新メッセージの送信者で判定している一方、iOS版はネゴ中を常に要対応扱いにしていた。ユーザーが本当に見るべき「自分が返す番かどうか」の精度が落ちるため、Web版ロジックに合わせる。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- `messages` から proposal ごとの最新メッセージ送信者を取得し、`latestMessageFrom` として取引カードの判定に渡すようにした。
- `negotiating` の要対応判定をWeb版と同じく、最新メッセージが相手由来なら要対応、自分由来なら相手待ちにした。
- `messages` の列差分や未作成環境では一覧全体を落とさず、従来の方向ベース判定へ戻るフォールバックにした。

### 影響範囲

- iOS版 取引一覧
- 打診中 > 要対応 / 相手待ち の分類

### 確認方法

- iOS開発ビルドで取引一覧を開き、ネゴ中カードが最新メッセージ送信者に応じて「要対応」または「相手待ち」に分類されることを確認
- `npm --prefix mobile run typecheck`

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ Web版 `TransactionsView` の `pendingNeedsAction` と同じ判定方針へ同期
- ✅ 新しい状態名・用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` の更新は不要
- ✅ DBスキーマ変更なし。既存 `messages` 読み取りの追加のみ

---

## イテレーション155.52：iOS在庫新規登録で写真切り抜きを必須化

### 背景・問題意識

Web版の在庫新規登録は、写真を選んだあとに切り抜きステップを経てラベル設定へ進む。一方iOS版は、写真をそのままアップロードしてラベル設定へ進んでおり、Web版の「見せたいグッズ部分を整えてから登録する」体験と差があった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫新規登録フローのカメラ / ライブラリ選択で、iOSのネイティブ切り抜きUIを通すようにした。
- ライブラリ選択は1枚ずつ切り抜いて追加する仕様に変更し、複数登録したい場合は続けて選ぶ案内に更新した。
- 写真なし登録、写真ごとのラベル設定、まとめて登録の流れは維持した。

### 影響範囲

- iOS版 マイ在庫新規登録
- iOS版 写真追加からラベル設定までの導線

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版マイ在庫の新規登録で、カメラ / ライブラリ選択後に切り抜きUIが出ること
- 切り抜いた写真がアップロード済み写真として並び、ラベル設定へ進めること

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ Web版の「写真を整えてから登録する」意図にiOS版を近づけた
- ✅ 追加依存なしで、Expo / iOS標準の写真切り抜きを利用する形にした
- ✅ 写真なし登録と複数グッズまとめ登録の既存導線は維持
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.51：iOS通知アイコンをベル表示へ修正

### 背景・問題意識

ホーム画面の通知導線はベルアイコンとして認識されるべきだが、iOS版の共通アイコン定義では `notifications-outline` が `!` で表示されており、通知ではなく警告に見えていた。オーナーからも「びっくりのアイコンは、通知のベルアイコンのはず」と指摘があった。

### 変更内容

#### `mobile/src/components/IconSymbol.tsx`
- `notifications-outline` のグリフを `!` からベルアイコンに変更した。
- `warning-outline` は警告用途として `!` のまま維持した。

### 影響範囲

- iOS版 ホーム左上の通知ボタン
- iOS版 共通 `IconSymbol` の通知表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版ホームで通知ボタンが警告記号ではなくベルとして表示されること

### 関連ファイル

- `mobile/src/components/IconSymbol.tsx`

### セルフレビュー結果

- ✅ ホーム画面の通知導線がベルとして認識しやすくなった
- ✅ 警告用途の `warning-outline` は変更していない
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.50：iOS現地交換設定に持参グッズ選択を追加

### 背景・問題意識

Web版の現地交換モード設定シートは、場所・時間・半径に加えて「持参するグッズ」を選べる。これは現地交換のマッチング市場に出す在庫を絞る重要な設定だが、iOS版の設定シートには未実装で、Web版と機能差があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 現地交換モード設定シートに「持参するグッズ」セクションを追加した。
- 自分の `goods_inventory` の `kind=for_trade` / `status=active` を読み込み、横スクロールのカードで選択できるようにした。
- 選択した在庫IDを `user_local_mode_settings.selected_carrying_ids` に保存するようにした。
- Previewモードでも挙動確認できるよう、プレビュー用の持参グッズ候補を表示するようにした。

### 影響範囲

- iOS版 ホーム
- iOS版 現地交換モード設定シート
- iOS版 現地交換モードのDB保存内容

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版ホームで現地交換モード設定を開き、持参グッズ候補が表示されること
- グッズカードをタップすると選択状態が切り替わること
- 「この設定で表示」後に `selected_carrying_ids` が保存されること

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ Web版の現地交換設定にある「持参するグッズ」機能をiOS版へ追加
- ✅ 既存の場所・時間・半径設定と同じシート内で完結するようにした
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.49：iOS在庫編集のメンバーリクエスト導線をWeb版へ同期

### 背景・問題意識

オーナーから「在庫の編集画面も、Wishの編集画面もWebアプリ版に合わせて。機能も、それぞれの項目のマスタ管理のところも。寸分違わず」と指摘があった。Web版の在庫編集画面は、既に登録済みまたは審査中のメンバーを選ぶ画面であり、編集フォーム内に新規メンバー追加リクエスト導線はない。一方iOS版の在庫編集には追加リクエストボタンが残っていた。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫編集・詳細フォームの「メンバーが見つからない場合は追加リクエスト」ボタンを削除した。
- 編集フォームではWeb版と同じく、登録済みメンバーと既存の審査中メンバーのみ選択できる状態にした。
- 在庫新規作成フローのラベル設定ステップにある追加リクエスト導線は、Web版 `CaptureFlow` に存在するため維持した。

### 影響範囲

- iOS版 マイ在庫編集
- iOS版 マイ在庫詳細
- iOS版 メンバー選択UI

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版の既存在庫編集画面で、メンバー追加リクエストボタンが表示されないこと
- 審査中メンバーがある場合は、Web版同様に選択肢として表示されること
- iOS版の新規在庫作成フローでは、ラベル設定ステップの追加リクエスト導線が残っていること

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ Web版在庫編集のマスタ選択仕様とiOS版の不要導線を同期した
- ✅ 新規作成フロー側のWeb版に存在するリクエスト導線は保持した
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.48：iOSマイ在庫削除を確認モーダルとフェードアウトへ同期

### 背景・問題意識

Web版のマイ在庫削除は、削除確認後に対象パネルがフェードアウトし、残りのパネルが自然に詰まる体験を前提にしている。一方iOS版のマイ在庫は「削除」を押すと即時にリストから消えており、Wish削除と手触りが揃っていなかった。

### 変更内容

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫の削除前に中央確認モーダルを表示するようにした。
- 確認後、対象在庫パネルを `GoodsGrid` の削除フェードアウトに載せ、アニメーション完了後にローカル一覧とSupabaseから削除するようにした。
- サーバー削除に失敗した場合はエラー表示し、対象在庫を一覧に戻すようにした。
- 削除中のタイルはタップしてボトムシートが開かないようにした。

### 影響範囲

- iOS版 マイ在庫一覧
- iOS版 マイ在庫削除フロー

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版マイ在庫で譲る候補または自分用キープのグッズをタップし、「削除」を押すと確認モーダルが出ること
- 「削除する」後に対象パネルがフェードアウトし、残りのパネルが詰まること
- 過去に譲ったタブでは削除アクションが出ないこと

### 関連ファイル

- `mobile/app/(tabs)/inventory.tsx`

### セルフレビュー結果

- ✅ Wish削除と同じ確認・フェードアウト・reflow体験へ揃えた
- ✅ 過去に譲ったタブは従来通り詳細確認のみで、削除導線を出していない
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.47：iOS Wish削除を確認モーダルとフェードアウトへ同期

### 背景・問題意識

Web版のWish削除は、確認モーダルを挟んだうえで対象パネルがフェードアウトし、残りのパネルが自動整理される。一方iOS版はボトムシートの「削除」を押すと即時にリストから消えており、以前オーナーが希望した「Wishと同じようにフェードアウトして自動整理」に対して、スマホアプリ側の手触りが不足していた。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- グッズタイルに削除フェードアウト用の `deletingIds` / `onItemFadeOutEnd` を追加した。
- 削除対象タイルは `Animated.timing` で奥へ消えるようにし、完了時に親へ通知するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish削除前に、Web版と同じく確認モーダルを表示するようにした。
- 確認後、対象Wishをフェードアウトさせ、アニメーション完了後にローカル一覧とSupabaseから削除するようにした。
- サーバー削除に失敗した場合はエラー表示し、対象Wishを一覧へ戻すようにした。

### 影響範囲

- iOS版 Wish一覧
- iOS版 グッズグリッド共通コンポーネント
- iOS版 Wish削除フロー

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版Wish一覧でWishをタップし、「削除」を押すと確認モーダルが出ること
- 「削除する」後に対象パネルがフェードアウトし、残りのパネルが詰まること
- サーバー削除失敗時に対象Wishが戻ること

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版Wish削除の確認・フェードアウト・reflow体験へ近づけた
- ✅ グッズグリッドは既存呼び出しに影響しないoptional propsで拡張
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.46：iOS在庫編集から持参切替を外してWeb版へ同期

### 背景・問題意識

オーナーから「在庫の編集画面も、Wishの編集画面もWebアプリ版に合わせて」と要望があった。Web版の在庫編集フォームは、グループ、メンバー、種別、数量、タグ、説明、写真、削除に絞っており、編集フォーム内で `carrying` を切り替えるUIはない。一方iOS版には「今日から持参中にする」が残っており、Web版と挙動がズレていた。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫編集フォームから「今日から持参中にする」切替を削除した。
- 既存在庫の編集保存時に `carrying` を更新しないようにした。
- 新規在庫の撮影登録フロー側の持参設定は、既存仕様として維持した。

### 影響範囲

- iOS版 マイ在庫 > 在庫編集
- iOS版 既存在庫保存時の `carrying` 更新

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版の既存在庫編集画面で、Web版と同様に持参切替が表示されないこと
- 編集保存しても `carrying` が変更されないこと

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ Web版在庫編集フォームとの差分を削減
- ✅ 新規在庫登録フローの既存仕様は維持
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過

---

## イテレーション155.45：iOS取引詳細のチャット取得をWeb版へ近づける

### 背景・問題意識

オーナーから「取引一覧でパネルを押しても読み込みに失敗しましたと出る」と指摘があった。Web版の取引チャットは、打診時メッセージを仮想チャットとして表示し、複数の取引証跡写真や位置情報付きメッセージを扱う。一方iOS版の取引詳細は、チャット取得列や証跡判定がWeb版より狭く、環境差・古いDB列差分があると読み込み体験が崩れやすかった。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- Web版と同じく `cash_offer` / `cash_amount` を proposal 取得対象に追加した。
- `proposal_evidence_photos` を取得し、複数証跡写真がある場合も取引証跡ありとして判定するようにした。
- `messages` 取得で `location_lat` / `location_lng` を含め、欠落カラムがある場合は該当列を外して再取得する互換処理を追加した。
- `proposal.message` をWeb版と同じく先頭の仮想チャットメッセージとして挿入するようにした。
- proposal/messages の欠落カラム検出を共通化し、schema cache 差分に対する耐性を上げた。

### 影響範囲

- iOS版 取引一覧 > 取引詳細 / ネゴチャット / 取引チャット
- iOS版 取引証跡の表示判定
- iOS版 メッセージタイムライン

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版取引一覧から打診中・進行中のパネルを開き、読み込み失敗にならず詳細が表示されること
- 打診時メッセージがチャット先頭に表示されること
- 証跡写真が複数枚ある取引で証跡ありとして扱われること

### 関連ファイル

- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ Web版の取引チャット取得仕様に近づけた
- ✅ 欠落カラムへのフォールバックを追加
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.44：iOSオンボーディング推しメンバー追加リクエストを実装

### 背景・問題意識

Web版のオンボーディング推しメンバー選択は、マスタに存在しないメンバーを `character_requests` として追加リクエストし、その場で選択状態に反映できる。一方iOS版は承認待ち推しに対して「承認後にメンバー選択できます」と表示するだけで、通常グループでも承認待ちメンバーの選択・仮登録ができなかった。

### 変更内容

#### `mobile/app/onboarding/members.tsx`
- `user_oshi.character_request_id` を読み込み、承認待ちメンバーの既存選択を復元するようにした。
- `character_requests` の pending レコードを取得し、通常グループ・承認待ち推しごとに審査中メンバーとして表示するようにした。
- 箱推し、マスタメンバー、承認待ちメンバーを同じ選択状態で扱い、保存時に `character_id` / `character_request_id` をそれぞれ `user_oshi` に保存するようにした。
- 画面内モーダルでメンバー追加リクエストを送信できるようにし、送信後は作成された審査中メンバーを即時リストへ追加して選択済みにするようにした。
- 承認待ち推しでも、メンバー追加リクエストによる仮登録ができるようにした。

### 影響範囲

- iOS版 新規登録オンボーディング > 推しメンバー選択
- iOS版 `character_requests` 追加リクエスト
- iOS版 `user_oshi.character_request_id` 保存・復元

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版オンボーディング推しメンバー画面で、マスタメンバー・審査中メンバーを選択できること
- 「メンバーが見つからない場合は追加リクエスト」から送信すると、チップが追加され選択済みになること
- 次へ進むと `user_oshi.character_request_id` として保存されること

### 関連ファイル

- `mobile/app/onboarding/members.tsx`

### セルフレビュー結果

- ✅ Web版の承認待ちメンバー表示・追加リクエスト導線をiOS版へ同期
- ✅ 既存 `character_requests` / `user_oshi.character_request_id` スキーマ内で実装
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.43：iOSオンボーディング推し追加リクエストを実装

### 背景・問題意識

Web版のオンボーディング推し選択は、検索して該当する推しが見つからない場合に追加リクエストへ進める導線を持つ。一方iOS版は検索結果が0件の時に「該当する推しが見つかりません」と出すだけで、リクエスト送信や選択状態への反映ができなかった。

### 変更内容

#### `mobile/app/onboarding/oshi.tsx`
- 検索結果が0件の時に「追加リクエストを送る」ボタンを表示するようにした。
- 画面内モーダルで、推し名、種別（グループ/作品/ソロ）、ジャンル、補足を入力して `oshi_requests` に登録できるようにした。
- リクエスト送信後、作成された審査中推しを選択肢リストへ追加し、同時に選択済みにするようにした。
- 既存の保存処理は、選択済みの審査中推しを `user_oshi.oshi_request_id` として保存する既存設計を維持した。

### 影響範囲

- iOS版 新規登録オンボーディング > 推し選択
- iOS版 `oshi_requests` 追加リクエスト
- iOS版 審査中推しの選択状態

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版オンボーディング推し選択で検索結果が0件の時、追加リクエストモーダルを開けること
- リクエスト送信後、その推しが選択済みとしてリストに追加されること
- 次へ進むと `user_oshi` に保存されること

### 関連ファイル

- `mobile/app/onboarding/oshi.tsx`

### セルフレビュー結果

- ✅ Web版の「見つからない場合の追加リクエスト」導線をiOS版へ追加
- ✅ 既存 `oshi_requests` / `user_oshi` スキーマ内で実装
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.42：iOS推し設定をWeb版の検索・仮登録導線へ同期

### 背景・問題意識

オーナーから以前「推し設定の画面で、追加リクエストを送ったものについても、ちゃんと推し設定として仮登録」「登録済みの推しを追加はオンボーディングに飛ばず、検索バー・カテゴリタブ・マスタ追加リクエストを画面内で」と要望があった。Web版 `profile/oshi` はこの仕様を実装済みだったが、iOS版 `oshi-settings` は「登録済みの推しを追加」ボタンが `preview-detail` に飛ぶだけで、検索・カテゴリタブ・マスタ追加・追加リクエスト・仮登録が未実装だった。

### 変更内容

#### `mobile/app/oshi-settings.tsx`
- `preview-detail` への仮導線を廃止し、画面内モーダルで登録済み推しマスタを検索・追加できるようにした。
- Web版と同様に、自由検索バー、ジャンルタブ、追加済み表示、検索ヒットなし時の追加リクエスト導線を追加した。
- `groups_master` / `genres_master` / `characters_master` を取得し、推しマスタと追加可能メンバーを組み立てるようにした。
- 登録済みマスタの推し追加時は `user_oshi` に `kind='box'` で追加するようにした。
- 推し追加リクエスト時は `oshi_requests` に登録したうえで、`user_oshi.oshi_request_id` に紐付けて仮登録するようにした。
- メンバー追加リクエスト時は `character_requests` に登録したうえで、`user_oshi.character_request_id` に紐付けて仮登録するようにした。
- グループ内で追加可能なマスタメンバーをチップで出し、選択すると箱推し行を外して `kind='specific'` の推しメンバーとして追加するようにした。
- メンバー削除後に同グループの行が空になった場合は、Web版と同じく箱推し行を復活させるようにした。

### 影響範囲

- iOS版 プロフ > 推し設定
- iOS版 推しマスタ検索・追加
- iOS版 推し追加リクエスト / メンバー追加リクエスト
- iOS版 `user_oshi` の箱推し/個別推し切り替え

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版プロフから推し設定を開き、「登録済みの推しを追加」で検索モーダルが開くこと
- マスタを追加すると推し設定に表示されること
- 検索で見つからない場合、追加リクエストを送ると仮登録されること
- グループ内でメンバー追加/削除、マスタに無いメンバーの追加リクエストができること

### 関連ファイル

- `mobile/app/oshi-settings.tsx`

### セルフレビュー結果

- ✅ Web版の検索モーダル・カテゴリタブ・追加リクエスト・仮登録仕様に合わせた
- ✅ `user_oshi` / `oshi_requests` / `character_requests` の既存スキーマ内で実装
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.41：iOS個別募集フォームのプレビューを画像対応

### 背景・問題意識

Webアプリとの照合を継続したところ、iOS版の個別募集作成/編集フォームでは、選択用カード自体は画像表示に対応している一方、上部の「交換条件」プレビューが頭文字表示のままだった。直前iterで個別募集一覧デッキを写真付き構造へ同期したため、作成/編集画面内のプレビューも同じ情報表現に揃える必要があった。

### 変更内容

#### `mobile/app/listing-editor.tsx`
- 個別募集フォーム上部の `PreviewCard` / `PreviewSide` で、選択中の譲グッズ・Wishに画像がある場合は画像を表示するようにした。
- 画像がない場合のみ、従来通り色付きの頭文字フォールバックを表示するようにした。

### 影響範囲

- iOS版 個別募集作成画面
- iOS版 個別募集編集画面

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版で個別募集作成/編集を開き、画像付きグッズを選んだ時に上部プレビューへ画像が反映されること
- 画像なしグッズは頭文字で表示されること

### 関連ファイル

- `mobile/app/listing-editor.tsx`

### セルフレビュー結果

- ✅ Web版の写真付き候補表示に合わせ、フォーム内プレビューも画像対応
- ✅ 状態遷移・DBスキーマ変更なし
- ✅ 新用語追加なし
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.40：iOS個別募集デッキを写真付き構造へ同期

### 背景・問題意識

オーナーから「個別募集の編集画面、作成画面も、仕様もデザインをWebアプリに合わせてください」「在庫の編集画面も、Wishの編集画面もちゃんとWebアプリ版に合わせてください」と継続指示があった。照合したところ、iOS版の個別募集作成/編集フォームはWeb版の条件ロジックにかなり近づいていた一方、Wishタブ内の個別募集一覧は、Web版の写真つき「募集デッキ」に対して頭文字中心の簡略表示になっており、グッズ画像・数量・選択肢構造の情報が欠けていた。

### 変更内容

#### `mobile/app/(tabs)/wishes.tsx`
- 個別募集一覧のデータ構造を、単純な `give/want` 文字列配列だけでなく、譲グッズ配列・求める選択肢配列・各グッズの写真URL/数量/グループ/メンバー/種別を保持する形へ拡張した。
- Supabase取得時に `have_qtys`、`listing_wish_options.position`、`wish_qtys`、`exchange_type`、`photo_urls` を取得し、Web版の募集デッキに近い描画情報を組み立てるようにした。
- iOS版の募集デッキカードで、実画像がある場合は画像を表示し、画像がない場合だけ従来の頭文字フォールバックを使うようにした。
- 譲側は重なった写真スタック、求側は選択肢スロットの写真クラスタとして表示し、数量バッジも出るようにした。
- 通常リスト側のミニ表示でも、可能な範囲で写真付きアイテムを使うようにした。

### 影響範囲

- iOS版 Wishタブ内の個別募集一覧
- iOS版 個別募集デッキ表示
- iOS版 個別募集の写真/数量/選択肢表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版 Wish > 個別募集タブで、募集デッキに譲/求の画像と数量が表示されること
- 画像がないグッズは従来通り頭文字で自然に表示されること
- 編集/一時停止/削除の導線が残っていること

### 関連ファイル

- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版個別募集一覧の写真付きデッキ構造へデータモデルを寄せた
- ✅ 既存状態名 `active` / `paused` / `matched` / `closed` の範囲内で実装
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.39：iOS在庫登録を撮影フローへ同期

### 背景・問題意識

オーナーから「在庫の編集画面も、Wishの編集画面もちゃんとWebアプリ版に合わせてください。機能も、それぞれの項目のマスタ管理のところも。寸分違わず」と指摘があり、前iterで編集画面を同期した。続けてWeb版との差分を確認すると、iOS版の在庫新規登録だけが単票フォームのままで、Web版 `inventory/new` の「同じ推し・種別でまとめて撮影し、写真ごとにメンバー/数量を設定する」体験を再現できていなかった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫の新規作成時だけ、従来の単票編集フォームではなく、`共通条件 → 写真撮影/選択 → 写真ごとのラベル設定` の3ステップ登録フローを表示するようにした。
- 共通条件では `user_oshi` 由来の推しグループと `goods_types_master` のグッズ種別を選ばせるようにした。
- 写真ステップではカメラ撮影・ライブラリ選択・複数画像選択・写真なし登録に対応し、選んだ画像を `goods-photos` にアップロードしてから次へ進めるようにした。
- ラベル設定では写真ごとにメンバー/審査中メンバー、数量、その他種別のタイトルを設定し、共通タグと持参中フラグをまとめて付与できるようにした。
- メンバーが見つからない場合は `character_requests` に追加リクエストを送り、その場で審査中メンバーとして選択肢へ追加できるようにした。

### 影響範囲

- iOS版 マイ在庫の新規登録
- iOS版 マイ在庫からのカメラ/写真ライブラリ利用
- iOS版 審査中メンバー追加リクエスト
- iOS版 在庫タグ付与

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版マイ在庫の追加ボタンから、推し/種別選択、写真選択、写真ごとのメンバー/数量設定、まとめて登録ができること
- 写真なしでも1件登録できること
- メンバー追加リクエスト後、その候補を選べること

### 関連ファイル

- `mobile/app/goods-editor.tsx`

### セルフレビュー結果

- ✅ Web版の在庫新規登録フローに合わせて、単票フォームから段階式のまとめ登録へ変更
- ✅ 既存状態名 `for_trade` / `active` の範囲内で実装
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過
- ⚠️ Web版の手動クロップUIまでは未実装。iOS側はまず複数写真の登録・写真ごとのラベル設定を優先同期した。

---

## イテレーション155.38：iOS在庫/Wish編集をWeb仕様へ同期

### 背景・問題意識

オーナーから「在庫の編集画面も、Wishの編集画面もちゃんとWebアプリ版に合わせてください。機能も、それぞれの項目のマスタ管理のところも。寸分違わず」と指摘があった。iOS版の `goods-editor` は URL パラメータ由来の仮フォームで、Web版にある `user_oshi` ベースのグループ候補、`characters_master` / `goods_types_master` のマスタ選択、審査中メンバー、画像アップロード、タグ同期、DB保存が未実装だった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫/Wish 共通の仮フォームを、Supabase から対象アイテム・ユーザー推し・マスタ・タグを読み込む実フォームへ差し替えた。
- 在庫編集は Web版と同じく、グループチップ、メンバー/審査中メンバーチップ、グッズ種別チップ、その他種別のみタイトル入力、数量、タグ、説明、画像差し替え、持参中フラグ、削除を扱うようにした。
- Wish編集/作成は Web版と同じく、グループ、メンバー、グッズ種別、その他種別のみタイトル入力、数量、画像、タグ、メモを扱うようにした。
- Wish画像は、個別募集で使用中の場合に削除不可・差し替え可のガードを入れた。
- タグは `search_tags` / `attach_inventory_tag` / `detach_inventory_tag` RPC で検索・追加・同期するようにした。
- 在庫削除時は Web版の `removeUnavailableHavesFromListings` と同じ考え方で、開いている個別募集の譲条件から削除済み在庫を外し、譲条件が空になった募集は `closed` にするようにした。
- `status='traded'` の在庫は詳細確認のみで、更新・削除できないようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- 在庫編集画面へ遷移する時に対象 `id` と `quantity` を渡すようにした。
- 保存後に一覧へ戻った時、`refresh` パラメータで再取得できるようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wish編集画面へ遷移する時に対象 `id` と `quantity` を渡すようにした。
- Wish一覧取得で `quantity` も取得し、編集画面の初期値に使えるようにした。

### 影響範囲

- iOS版 マイ在庫編集/作成
- iOS版 Wish編集/作成
- iOS版 在庫/Wish一覧から編集画面への遷移
- iOS版 個別募集と連動する Wish画像削除ガード / 在庫削除時の募集条件整理

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS版でマイ在庫のグッズを開き、グループ/メンバー/種別/タグ/画像/数量/説明を編集して保存できること
- iOS版でWishを開き、グループ/メンバー/種別/タグ/画像/数量/メモを編集して保存できること
- 個別募集で使用中のWish画像は削除できず、差し替えはできること
- 譲り済み在庫は詳細確認のみで更新/削除できないこと

### 関連ファイル

- `mobile/app/goods-editor.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版の在庫/Wish編集で使う既存テーブル・RPCに合わせて実装
- ✅ 既存状態名 `active` / `keep` / `traded` / `archived` のみ利用
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ DBスキーマ変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態遷移追加なしのため `notes/09_state_machines.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.37：iOS取引詳細取得とオンボーディング導線を補正

### 背景・問題意識

オーナーから「取引一覧でパネルをタップしてもまだ『読み込みに失敗しました』と出る」「新規登録しても、そのままホーム画面にいってしまう」と指摘があった。取引詳細側は `proposals` の新旧カラム差分を吸収する fallback が `PGRST204` / schema cache 形式に偏っており、PostgREST が `42703` や `column ... does not exist` 形式で返した場合に復旧できなかった。また、Supabase Auth でサインアップ直後に session が返る設定だと、iOS版は `account_status` を見ずにタブ画面へ通していた。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- `proposals` 取得時の欠損カラム検出を `PGRST204` だけでなく `42703` / `column proposals.xxx does not exist` 形式にも対応させた。
- PostgREST の plain object エラーでも実際の `message` を表示できるようにした。

#### `mobile/app/transaction-detail.tsx`
- 取引詳細の `proposals` 取得 fallback も同様に拡張し、`meetup_candidates` / `evidence_*` / `approved_by_*` などのDB差分で画面全体が落ちないようにした。
- 取得失敗時に generic な「読み込みに失敗しました」だけでなく、Supabase の実エラー文を表示できるようにした。

#### `mobile/src/auth/AuthProvider.tsx`
- ログイン中ユーザーの `users.account_status` / `gender` / `primary_area` を AuthProvider で保持するようにした。
- `needsOnboarding` を追加し、`registered` / `verified` / `onboarding` または gender 未設定のユーザーをオンボーディング未完了として判定するようにした。
- `refreshProfile()` を追加し、オンボーディング完了後にAuthProvider側の状態も更新できるようにした。

#### `mobile/app/(auth)/_layout.tsx`
- session があってもオンボーディング未完了ならホームへ飛ばさず `/auth/email-confirmed` へ誘導するようにした。

#### `mobile/app/(tabs)/_layout.tsx`
- タブ画面もオンボーディング未完了ユーザーを `/auth/email-confirmed` へ戻すようにした。

#### `mobile/app/auth/email-confirmed.tsx`
- メール認証コード交換後、Web版と同様に `account_status: registered` を `verified` へ同期し、AuthProvider のプロフィール状態を再読込するようにした。

#### `mobile/app/onboarding/area.tsx`
- オンボーディング完了で `account_status: active` にした後、AuthProvider のプロフィール状態を再読込してから完了画面へ進むようにした。

### 影響範囲

- iOS版 取引一覧
- iOS版 取引詳細 / 取引チャット
- iOS版 認証後ルーティング
- iOS版 新規登録後オンボーディング
- iOS版 オンボーディング完了後のホーム遷移

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- 取引一覧のパネルをタップして、対象 proposal の詳細画面が開くこと
- 新規登録直後に session が存在しても、ホームではなく認証完了 / プロフィール設定へ誘導されること
- オンボーディング4/4完了後に `account_status` が `active` になり、ホームへ進めること

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(auth)/_layout.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/auth/email-confirmed.tsx`
- `mobile/app/onboarding/area.tsx`

### セルフレビュー結果

- ✅ 取引詳細取得のDBカラム差分 fallback を拡張
- ✅ PostgREST plain object エラーでも message を表示
- ✅ 新規登録/Apple認証などで session が即時発行されてもオンボーディング未完了ならホームに入れない
- ✅ Web版と同じ `registered → verified → onboarding → active` の大枠に合わせた
- ✅ 既存ステータス値の利用のみで新状態名なしのため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ 既存 `users.account_status` 利用のみでデータモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.36：iOSホームの現地ON状態と表示モードを分離

### 背景・問題意識

オーナーから「現地交換モードに切り替えても、右上のトグルをOFFにしないと、このモードがOFFにならないようにして。Webアプリと同様。つまり、現地交換できる状態でありながら、全国交換モードの表示を見れるようにしたい」と指摘があった。iOS版ホームでは `localMode` ひとつで「現地交換ON/OFF」と「全国/現地フィード表示」を兼ねていたため、中央のモード切替で全国へ戻すと現地交換状態自体もOFFになっていた。

また、モード切替UIについて「iOS標準のやつ」「フッターのリキッド仕様のように」と要望があったため、AppleのHIGとLiquid Glass資料を確認した。標準のLiquid GlassはUIKit/SwiftUIなどの標準コンポーネントで自動適用されるが、現在のExpo dev buildにはネイティブ `UISegmentedControl` ブリッジ（`@react-native-segmented-control/segmented-control`）が未導入で、追加するとdev build再ビルドが必要になる可能性がある。そのため、今回の範囲では既存レビュー環境を壊さず、状態分離と標準セグメント寄りの見た目へ修正した。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- `localMode` を実際の現地交換ON/OFF状態として残し、新たに `viewMode: "national" | "local"` を追加した。
- 右上の `Switch` だけが `user_local_mode_settings.enabled` をOFFにできるようにした。
- 中央の「全国交換モード / 今すぐ現地交換」は表示フィードの切替専用にした。
- 現地交換ON中に「全国交換モード」を押しても、現地交換ON状態・右上の場所表示・右上トグルONを維持するようにした。
- 現地交換ON中に「今すぐ現地交換」を押すと、現地候補のみを表示するようにした。
- 現地交換OFF中に「今すぐ現地交換」を押した場合は、これまで通り現地交換設定シートを開くようにした。
- 現地表示中のみ候補カードのLIVEエフェクトを出すようにし、全国表示では現地交換ON中でも通常カードとして見られるようにした。
- モード切替UIの紫ブロブ装飾を外し、等幅2セグメント・白い選択面・控えめなスプリング移動のiOS標準セグメント寄りの見た目へ調整した。

### 影響範囲

- iOS版ホーム画面
- iOS版ホームの全国交換 / 今すぐ現地交換表示切替
- iOS版現地交換モードON/OFF
- iOS版ホーム候補カードのLIVEエフェクト表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- 現地交換ON後、中央の「全国交換モード」を押しても右上トグルがONのまま維持されること
- その状態で「今すぐ現地交換」を押すと現地候補表示に戻ること
- 右上トグルをOFFにした時だけ現地交換モード自体がOFFになり、表示も全国へ戻ること
- 現地交換OFF中に中央の「今すぐ現地交換」を押すと設定シートが開くこと

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ Web版の `localMode` と `visualViewMode` 相当をiOS側でも分離
- ✅ 真のOFFは右上トグル操作だけに限定
- ✅ 現地交換ON中でも全国表示を見られる
- ✅ 既存テーブル利用のみでデータモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態名の追加・変更なしのため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.35：iOS個別募集の作成・編集画面をWeb仕様へ寄せる

### 背景・問題意識

オーナーから「個別募集の編集画面、作成画面も、仕様もデザインをWebアプリに合わせてほしい」と指示があった。iOS版の `listing-editor` は、譲・求をテキスト入力するだけの仮画面で、Web版の `listings/new/ListingNewForm.tsx` が持つ「譲グッズ選択、求の最大5選択肢、AND/OR、数量、画像ありWishでの交換タイプ非表示、定価交換、DB保存」仕様と大きく乖離していた。

### 変更内容

#### `mobile/app/listing-editor.tsx`
- 仮のテキスト入力型UIを撤去し、Web版と同じデータモデルに沿った作成・編集フォームへ作り替えた。
- Supabaseから自分の譲る候補・Wish・編集対象の `listings` / `listing_wish_options` を読み込むようにした。
- 譲側でグループ・種別を選び、該当する譲グッズを画像カードで複数選択できるようにした。
- 譲側の数量ステッパーを追加し、市場残数を上限にした。
- 複数譲の `and` / `or` を「全部」「1pick」で切り替えられるようにした。
- 求側は最大5つの選択肢を追加でき、選択肢ごとにグループ・種別・Wish・数量・`and` / `or` を設定できるようにした。
- 選択したWishがすべて画像ありの場合は、Web版同様に同種 / 異種の交換タイプ指定を不要表示にした。
- 画像なしWishを含む場合は、交換タイプ（同異種 / 同種のみ / 異種のみ）を表示するようにした。
- 定価交換選択肢を追加し、金額入力と `is_cash_offer` 保存に対応した。
- Web版と同じ OR×OR の曖昧条件をバリデーションで防ぐようにした。
- 作成時は `listings` をinsertし、`listing_wish_options` をbulk insertするようにした。
- 編集時は `listings` を更新し、既存 `listing_wish_options` を削除して再insertするWeb版相当の全置換更新にした。
- 成立・完了済みの個別募集は編集不可として表示するようにした。
- 保存後はWishタブの個別募集一覧へ戻り、一覧を再読込するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- 個別募集編集画面へ遷移する際に `id` を渡すようにした。
- Wishから個別募集作成へ進む際に `wishId` を渡し、求側選択肢のプリセットに使えるようにした。
- 保存後の `tab=listings` / `refresh` パラメータを受け、個別募集一覧タブを開いて再読込するようにした。

### 影響範囲

- iOS版 Wish タブ > 個別募集一覧
- iOS版 個別募集作成画面
- iOS版 個別募集編集画面
- `listings`
- `listing_wish_options`

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- Wishタブの個別募集一覧から編集を開くと、対象のDBデータがカード選択UIで復元されること
- 個別募集作成で譲る候補、求めるWish、数量、AND/OR、交換タイプ、定価交換を設定できること
- 画像ありWishのみを選ぶと交換タイプ指定が不要表示になること
- 保存後に個別募集一覧へ戻り、一覧が再読込されること

### 関連ファイル

- `mobile/app/listing-editor.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版の作成・編集仕様に合わせて `listings` / `listing_wish_options` へ保存
- ✅ テキスト入力だけの仮UIを撤去し、カード選択・数量・AND/OR・交換タイプ・定価交換を実装
- ✅ 既存テーブル利用のみでデータモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ 状態名の追加・変更なしのため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.34：iOSホームの現地モード切替を設定シート連動へ

### 背景・問題意識

iOS版フッターを NativeTabs へ切り替えたことで、オーナーから「まさに求めていたもの」と評価された。続けて、ホーム画面の全国交換モード / 今すぐ現地交換モードの切り替えも同じ方向のリキッド感に寄せ、現地交換モードへ切り替えたら Webアプリ版と同じく交換場所などを設定する画面が出るようにしたいという要望があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部のモード切り替えUIを、白い半透明面・柔らかいハイライト・スプリング移動のリキッド寄り表現に調整した。
- 右上の小さな現地交換トグルは React Native の `Switch` に置き換え、iOS 標準のスイッチ操作感に寄せた。
- 現地交換モードを ON にした瞬間に、ホーム上で `LocalModeSheet` を表示するようにした。
- `LocalModeSheet` に交換場所、Apple Maps ベースの地図、現在地取得、半径、有効時間、適用ボタンを追加した。
- シートを設定せず閉じた場合は全国交換モードへ戻し、適用した場合のみ `user_local_mode_settings` と `activity_windows` を更新するようにした。
- 既存の現地モード AW があれば更新し、なければ作成して `aw_id` に紐づける Web版の `applyLocalModeAW` 相当の処理を iOS 側にも追加した。
- 適用後はホーム候補を再読込し、場所表示も即時更新するようにした。

### 影響範囲

- iOS版ホーム画面
- iOS版ホームの全国交換 / 現地交換モード切り替え
- iOS版現地交換モード設定
- `user_local_mode_settings` / `activity_windows` の更新

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- ホームで「今すぐ現地交換」を押すと設定シートが下から表示されること
- 設定せず閉じると全国交換モードへ戻ること
- 交換場所・半径・有効時間を設定して「この設定で表示」を押すと現地交換モードが維持されること
- 右上の場所ボタンを押すと既存設定の編集シートが開くこと

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ ON時の設定シート表示を Web版の挙動に寄せた
- ✅ 適用前にDBだけONへ残る挙動を避けるため、適用時にAW/設定を確定する流れへ整理
- ✅ 既存状態名の追加/変更なしのため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ 既存テーブル利用のみでデータモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.33：iOSフッターをNativeTabsへ切り替え

### 背景・問題意識

オーナーから「風ではなく、本物を使いたい」と明確な要望があった。前回までの React Navigation 標準タブバーやカスタムガラス風UIは、いずれもJS側で見た目を寄せるアプローチであり、最新iOSの Liquid Glass / floating tab bar / minimize behavior をシステムに任せる構成ではなかった。Expo Router 6.0.23 には `expo-router/unstable-native-tabs` が同梱されており、内部的に `react-native-screens` の native bottom tabs を利用できるため、既存5タブを NativeTabs へ切り替える。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- `Tabs` / `StyleSheet` / `useSafeAreaInsets` ベースのJSタブバーを撤去した。
- `expo-router/unstable-native-tabs` の `NativeTabs` / `NativeTabs.Trigger` へ切り替えた。
- 各タブに SF Symbols を設定した。
  - ホーム: `house` / `house.fill`
  - 在庫: `shippingbox` / `shippingbox.fill`
  - Wish: `heart` / `heart.fill`
  - 取引: `arrow.left.arrow.right`
  - プロフ: `person.crop.circle` / `person.crop.circle.fill`
- `backgroundColor={null}` と `blurEffect="systemDefault"` を指定し、背景描画をiOS側に任せる方針にした。
- iOS 26+ の `minimizeBehavior="onScrollDown"` を指定し、スクロール時の最小化挙動をネイティブ側へ任せるようにした。

### 影響範囲

- iOS版共通フッター
- iOS版ホーム/在庫/Wish/取引/プロフのタブ遷移
- development build / EAS build でのネイティブタブ表示

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOS development build で、フッターがJSカスタムではなく NativeTabs として表示されること
- iOS 26環境で、システム側の floating tab bar / Liquid Glass / minimize behavior が有効になること
- iOS 25以前では、OSが提供する通常の native tab bar として破綻なく表示されること

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ フッターをJSカスタムではなく NativeTabs へ切り替え
- ✅ SF Symbols を利用し、テキスト記号アイコンを撤去
- ✅ 状態遷移・用語・データモデル変更なしのため `notes/09` / `notes/10` / `notes/05` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.32：iOS待ち合わせカレンダーの週切り替え瞬間の表示崩れを抑制

### 背景・問題意識

待ち合わせカレンダーの横スワイプ週切り替えで、切り替え完了の瞬間に表示が一瞬変になるという指摘があった。前回実装では、ページを端までアニメーションした後に `weekOffset` を更新し、同時に `Animated.Value` をリセットしていたため、React state と native animation value の更新タイミング差で一瞬別週のページが見える可能性があった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 週切り替えの確定処理を、端までスライドしてから週を差し替える方式から、リリース位置を引き継いで先に週を確定し、そのまま中央へ戻す方式へ変更した。
- `Animated.timing(... toValue: ±calendarWidth)` による終端アニメーションを廃止した。
- 週確定時に引き継ぐ横位置を最大 42% 幅に抑え、極端にスワイプした時のページ差し替えジャンプを抑制した。

### 影響範囲

- iOS版提示物の選択 > 待ち合わせタブ
- 待ち合わせカレンダーの横スワイプ週切り替え

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- カレンダーを横スワイプして週を切り替えた瞬間に、別週や空白が一瞬見えないこと
- 横スワイプ後、現在の5日表示が中央へ自然に戻ること
- 長押しによる時間選択に影響がないこと

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 週差し替え時の animated value reset による一瞬の表示崩れリスクを低減
- ✅ 状態遷移・用語・データモデル変更なしのため `notes/09` / `notes/10` / `notes/05` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.31：iOSフッターを標準寄りへ戻しカレンダー週スワイプを追従化

### 背景・問題意識

iter155.30 のiOSフッターは、最新iOS風のガラス表現をカスタムで再現しようとした結果、オーナーから「あまりにもデザインが変」「iOSの共通コンポーネントみたいなのを使えないか」と指摘された。Expo/React Native から iOS のシステム Tab Bar そのものを直接呼ぶ構成ではないため、まずは独自装飾を撤去して Expo Router / React Navigation の標準タブバー寄りに戻す。また、待ち合わせタブのカレンダーは、時間選択できるグリッド上でも横スワイプで週切り替えでき、iPhone のホーム画面のように指の動きへ追従する必要があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- 独自実装の `LiquidTabBar` を撤去し、Expo Router の標準タブバー表示へ戻した。
- 変な記号アイコン、水っぽい膨らみ、虹彩アクセント、独立検索丸ボタンを削除した。
- タブバーは白背景・薄い上罫線・シンプルなラベルのみの控えめな表示にした。

#### `mobile/app/proposal-select.tsx`
- 待ち合わせカレンダーの5日表示を、前週・現在週・次週の3ページ構成にした。
- 日付ヘッダーだけでなく、時間選択グリッド上の横スワイプでも週切り替えできるようにした。
- 横スワイプ中は `Animated.Value` でページ全体が指に追従し、隣の5日分が横から見えてくるようにした。
- 横移動がしきい値未満なら元の週へ戻り、しきい値を超えたら前後の週へアニメーションして切り替えるようにした。

### 影響範囲

- iOS版共通フッター
- iOS版ホーム/在庫/Wish/取引/プロフのタブ遷移
- iOS版提示物の選択 > 待ち合わせタブ
- 待ち合わせカレンダーの週切り替え操作

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- フッターに前回の水っぽいカスタム装飾が残っていないこと
- カレンダーの日付ヘッダー上で横スワイプすると、前後5日分が指に追従して切り替わること
- カレンダーの時間グリッド上で横スワイプしても、同じように前後5日分へ切り替わること
- 長押しによる時間帯選択は従来通り使えること

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 変な独自フッター装飾を撤去し、標準タブバー寄りへ戻した
- ✅ 時間グリッド上でも週切り替え横スワイプを受け付けるようにした
- ✅ 週切り替え時に前後ページが指へ追従する表示へ変更
- ✅ 既存状態名の追加/変更なしのため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ データモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.30：iOSフッター刷新と待ち合わせカレンダー操作改善

### 背景・問題意識

iOS版のフッターは既存のガラス風タブバーだったが、オーナーから「最新のiOSがよく使っている添付の感じ」に寄せたいという要望があった。また、ホームのマッチングパネルから提示物の選択へ進んだ後の待ち合わせカレンダーで、長押しして時間帯を選ぶ際に縦スクロールすると画面全体も一緒に動いてしまい、時間帯選択がしづらかった。さらに、候補未選択時の案内はカレンダーをスクロールしても常に中央に固定表示し、横スワイプで前後の週へ移動できる必要があった。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- 共通フッターを、横長の白いガラスバー + 独立した検索丸ボタンの構成へ刷新した。
- 選択中タブの背景を、水っぽい半透明の膨らみと薄い虹彩アクセントを持つ表示へ変更した。
- タブの記号を単文字アルファベットから、ホーム/在庫/Wish/取引/プロフの意味が伝わる記号に変更した。
- 検索丸ボタンから `/search` へ遷移できるようにした。

#### `mobile/app/proposal-select.tsx`
- 提示物の選択画面を `Screen scroll={false}` にし、待ち合わせカレンダー操作中に親画面が一緒に縦スクロールしないようにした。
- 長押しドラッグ中、および候補移動/リサイズ中はカレンダー内部の縦スクロールも停止し、時間帯選択に集中できるようにした。
- 候補未選択時の「長押しで時間帯を選択できるよ」案内を、カレンダー内スクロール位置に追従しない固定中央表示へ変更した。
- カレンダーの日付ヘッダー、またはカレンダー領域の横スワイプで前後5日分へ切り替わるようにした。
- 候補に `dateId` を持たせ、週をまたいだ表示・移動・送信確認の日時生成が実日付に紐づくようにした。

### 影響範囲

- iOS版共通フッター
- iOS版ホーム/在庫/Wish/取引/プロフのタブ遷移
- iOS版検索導線
- iOS版提示物の選択 > 待ち合わせタブ
- iOS版送信確認へ渡す待ち合わせ候補日時

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- フッターが横長ガラスバー + 検索丸ボタンの見た目になっていること
- フッターの各タブと検索ボタンが遷移すること
- 待ち合わせカレンダーで長押し後に縦ドラッグしても、画面全体が一緒に動かないこと
- 候補未選択時の案内がカレンダーの表示位置に関係なく中央固定で見えること
- カレンダーを横スワイプすると前後5日分へ切り替わること

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 共通フッターを添付方向のガラスUIへ刷新
- ✅ カレンダー長押し選択時の親スクロール干渉を抑制
- ✅ 候補未選択ガイドを固定中央表示へ変更
- ✅ 5日表示の横スワイプ切り替えを追加
- ✅ 既存状態名の追加/変更なしのため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ データモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.29：iOS実データ読み込み前のプレビュー表示を停止

### 背景・問題意識

iOS版で実アカウントにログインしていても、各画面の初期stateにプレビュー用データが入っていたため、実データ取得前にダミーのマッチ・取引・予定・通知などが一瞬表示されていた。特に取引一覧では、プレビュー取引 `tx-01` などを押せてしまい、取引詳細で「読み込みに失敗しました」につながっていた。また、プロフ画面の推しカードは表示のみで、推し設定へ遷移できなかった。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 実ログイン時は取引一覧の初期値を空にし、プレビュー取引を出さないようにした。
- 実データ取得中は最初から loading 表示にし、空状態のチラつきを抑えた。
- 取得失敗時もプレビュー取引へ戻さず、空＋エラー表示にした。

#### `mobile/app/(tabs)/profile.tsx`
- 実ログイン時はプロフィール初期値を空にし、取得完了後に表示するようにした。
- 推しカード全体を押せるようにし、`/oshi-settings` へ遷移するようにした。

#### `mobile/app/(tabs)/index.tsx`
- 実ログイン時はホームのマッチ候補初期値を空にし、プレビュー候補を一瞬出さないようにした。
- 実データ取得失敗時もプレビュー候補に戻さないようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- 実ログイン時はマイ在庫の初期値を空にし、プレビュー在庫を一瞬出さないようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- 実ログイン時はWish/個別募集の初期値を空にし、プレビューWishや個別募集を一瞬出さないようにした。

#### `mobile/app/notifications.tsx`
- 実ログイン時は通知一覧の初期値を空にし、プレビュー通知を一瞬出さないようにした。

#### `mobile/app/schedules.tsx`
- 実ログイン時はスケジュール初期値を空にし、プレビュー予定を一瞬出さないようにした。

#### `mobile/app/search.tsx`
- Supabase接続済みの実ログイン時は検索結果にプレビューヒットを使わないようにした。

### 影響範囲

- iOS版ホーム
- iOS版取引一覧/取引詳細導線
- iOS版プロフ/推し設定導線
- iOS版マイ在庫
- iOS版Wish/個別募集
- iOS版通知
- iOS版スケジュール
- iOS版検索

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- 実ログイン後、各画面でプレビュー用のユーザー・取引・マッチ・通知・予定が一瞬表示されないこと
- 取引一覧のパネルを押した時、実 proposal ID で取引詳細に遷移すること
- プロフ画面の推しカードを押すと推し設定へ遷移すること

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/notifications.tsx`
- `mobile/app/schedules.tsx`
- `mobile/app/search.tsx`

### セルフレビュー結果

- ✅ 実ログイン中にプレビュー初期値を見せない方針へ統一
- ✅ 取引一覧から存在しないプレビューIDを押せる問題を解消
- ✅ 推しカードから推し設定へ遷移できるようにした
- ✅ 状態遷移・用語・データモデル変更なしのため `notes/09` / `notes/10` / `notes/05` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.28：iOSアイコンhookエラーを解消

### 背景・問題意識

iOSプレビューでホーム表示時に `Invalid hook call` / `Cannot read property 'useContext' of null` が発生し、`@expo/vector-icons` の `Ionicons` を描画した箇所でクラッシュしていた。ホーム以外にも通知・検索・予定・ヘルプ画面で同じライブラリを使っていたため、同系統の再発リスクがあった。

### 変更内容

#### `mobile/src/components/IconSymbol.tsx`
- `@expo/vector-icons` に依存しない、軽量な自前アイコン表示コンポーネントを追加した。
- 既存画面で使っている `Ionicons` 名に対応する記号をマップした。

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部の通知アイコンと左下固定検索アイコンを `IconSymbol` に置き換えた。

#### `mobile/app/notifications.tsx`
- 通知種別アイコンを `IconSymbol` に置き換えた。

#### `mobile/app/search.tsx`
- 検索、クリア、詳細導線アイコンを `IconSymbol` に置き換えた。

#### `mobile/app/schedules.tsx`
- 予定追加・予定カードアイコンを `IconSymbol` に置き換えた。

#### `mobile/app/help.tsx`
- メール、FAQ開閉、法的ページ導線アイコンを `IconSymbol` に置き換えた。

#### `mobile/app/notification-settings.tsx`
- 通知設定の行アイコンを `IconSymbol` に置き換えた。

#### `mobile/app/user-profile.tsx`
- 打診CTAの矢印アイコンを `IconSymbol` に置き換えた。

### 影響範囲

- iOS版ホーム
- iOS版通知一覧
- iOS版検索
- iOS版スケジュール
- iOS版ヘルプ/法的ページ導線
- iOS版通知設定
- iOS版相手プロフィール

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- iOSプレビューでホームを開いて `Invalid hook call` が出ないこと
- ホームの通知/検索、通知一覧、検索、予定、ヘルプ、通知設定、相手プロフィールを開けること

### 関連ファイル

- `mobile/src/components/IconSymbol.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/notifications.tsx`
- `mobile/app/search.tsx`
- `mobile/app/schedules.tsx`
- `mobile/app/help.tsx`
- `mobile/app/notification-settings.tsx`
- `mobile/app/user-profile.tsx`

### セルフレビュー結果

- ✅ `@expo/vector-icons` 参照をiOS画面から削除し、hookエラー再発リスクを下げた
- ✅ React重複は `npm ls react` で発生していないことを確認
- ✅ 状態遷移・用語・データモデル変更なしのため `notes/09` / `notes/10` / `notes/05` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.27：iOSキャンセル同意を追加

### 背景・問題意識

WebAppの取引チャットでは、キャンセル要請を受け取った側がチャット内カードから「同意してキャンセル」または「申告する」を選べる。iOS版は遅刻通知/キャンセル相談の送信までは実装済みだったが、受信側の同意導線が不足しており、キャンセル相談が完結しなかった。

### 変更内容

#### `mobile/src/lib/transactionActions.ts`
- Web版 `approveTradeCancel` に合わせて、iOS版にもキャンセル同意アクションを追加した。
- 合意済み取引のみキャンセルできるようにし、`proposals.status='cancelled'` と `last_action_at` を更新するようにした。
- 同意完了時に「評価への影響なし」のsystem messageを投稿するようにした。

#### `mobile/app/transaction-detail.tsx`
- `messages.meta.action='cancel_requested'` のsystem messageを、受信側だけキャンセル要請カードとして表示するようにした。
- カード内に「申告する」と「同意してキャンセル」を配置し、同意前にiOS標準アラートで確認するようにした。
- 同意後は取引一覧へ戻る導線にした。

### 影響範囲

- iOS版取引チャット
- iOS版キャンセル相談フロー
- iOS版申告入口

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- 相手からのキャンセル要請メッセージでカードが表示されること
- 「申告する」から申告作成画面へ進むこと
- 「同意してキャンセル」で取引が `cancelled` になり、取引一覧へ戻ること

### 関連ファイル

- `mobile/src/lib/transactionActions.ts`
- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ Web版と同じ受信側キャンセル同意導線をiOSチャットに追加
- ✅ 既存の `cancelled` 状態を使うため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ データモデル変更なしのため `notes/05_data_model.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.26：iOS申告詳細を追加

### 背景・問題意識

WebAppには `/disputes/[id]` の申告ステータス画面があり、申告後や通知から現在の進行状況・相手回答・運営確認を確認できる。一方iOS版では申告フォームの入口は追加済みだったが、作成後や通知から開く申告詳細画面が不足していた。

### 変更内容

#### `mobile/app/dispute-detail.tsx`
- Web版 `/disputes/[id]` に合わせて、申告ステータス画面を追加した。
- 申告カテゴリ、申告本文、証跡写真、進行状況、結果、追加メッセージを表示するようにした。
- 被申告者の場合、事実を認める/反論を提出する回答UIを追加した。
- クローズ前は追加情報を `dispute_messages` に送信できるようにした。

#### `mobile/app/dispute-new.tsx`
- 申告送信後、取引詳細ではなく申告詳細へ遷移するようにした。

#### `mobile/app/notifications.tsx`
- `/disputes/:id` のlink_pathをiOSの申告詳細へマップした。

### 影響範囲

- iOS版申告フォーム
- iOS版申告詳細
- iOS版通知リンク解決

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- 申告フォーム送信後に申告詳細へ遷移すること
- 通知の `/disputes/:id` link_path から申告詳細へ遷移すること
- 被申告者アカウントで回答UIが表示されること

### 関連ファイル

- `mobile/app/dispute-detail.tsx`
- `mobile/app/dispute-new.tsx`
- `mobile/app/notifications.tsx`

### セルフレビュー結果

- ✅ Web版の申告詳細に対応するiOS実画面を追加
- ✅ 申告作成後と通知から申告詳細へ到達できるようにした
- ✅ 被申告者回答・追加情報送信の最低限の操作をiOS版にも追加
- ✅ 既存D-flow状態に沿った実装のため `notes/09_state_machines.md` 更新不要
- ✅ 新用語追加なしのため `notes/10_glossary.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.25：iOS遅刻通知/キャンセル相談を追加

### 背景・問題意識

WebAppの取引チャットには、合意済み取引で「遅刻を連絡」「取引キャンセルを相談」する導線がある。iOS版では合意後に向かう/到着/証跡撮影はあっても、遅刻やキャンセルの避難導線が不足していたため、当日の取引体験がWeb版より弱くなっていた。

### 変更内容

#### `mobile/app/transaction-cancel-or-late.tsx`
- Web版 `/transactions/[id]/cancel-or-late` に合わせて、遅刻通知/キャンセル相談画面を追加した。
- 遅刻時は 10分/20分/30分/1時間/1時間以上の選択、理由、任意メモを送信できるようにした。
- キャンセル時は理由、任意メモ、確認アラートを経て、取引チャットへsystem messageを投稿するようにした。

#### `mobile/src/lib/transactionActions.ts`
- `notifyLate` と `requestTradeCancel` を追加した。
- Web版同様、`messages.meta.action='late_notice'` / `cancel_requested` として記録し、キャンセル要請は相手への通知も作成するようにした。

#### `mobile/app/transaction-detail.tsx`
- 合意済み取引のC-3パネル内に「遅刻を連絡」「キャンセル相談」を追加した。

#### `mobile/app/notifications.tsx`
- `/transactions/:id/cancel-or-late?kind=...` のlink_pathをiOS画面へマップした。

### 影響範囲

- iOS版取引詳細
- iOS版遅刻通知
- iOS版キャンセル相談
- iOS版通知リンク解決

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- 合意済み取引の取引詳細から「遅刻を連絡」「キャンセル相談」へ遷移
- 送信後に取引詳細へ戻り、取引チャットへsystem messageが追加されることを確認

### 関連ファイル

- `mobile/app/transaction-cancel-or-late.tsx`
- `mobile/src/lib/transactionActions.ts`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/notifications.tsx`

### セルフレビュー結果

- ✅ Web版の遅刻通知/キャンセル相談に対応するiOS実画面を追加
- ✅ 取引詳細から当日の避難導線へ到達できるようにした
- ✅ 状態遷移は既存 `agreed` 取引上の通知/相談追加であり、`notes/09_state_machines.md` 更新は不要
- ✅ 新用語追加はないため `notes/10_glossary.md` 更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.24：iOS法的ページと評価一覧を追加

### 背景・問題意識

WebAppとの差分を再スキャンしたところ、iOS版には利用規約・プライバシーポリシー・特商法表記の法的ページと、プロフィールから遷移する評価一覧が不足していた。法的ページは登録/審査/サポート導線として重要で、評価一覧はプロフ上の評価サマリをタップした後の実画面が必要なため、プレビュー止まりを解消した。

### 変更内容

#### `mobile/src/components/LegalDocument.tsx`
- 法的ページ共通のヘッダー、情報ボックス、記事、データ行、フッター表示を追加した。

#### `mobile/app/legal/terms.tsx`
- Web版 `/legal/terms` に合わせて、利用規約ページを追加した。

#### `mobile/app/legal/privacy.tsx`
- Web版 `/legal/privacy` に合わせて、プライバシーポリシーページを追加した。

#### `mobile/app/legal/notice.tsx`
- Web版 `/legal/notice` に合わせて、特定商取引法に基づく表記ページを追加した。
- `notes/17_legal_alignment.md` の方針通り、代表者名・所在地・電話番号は非公表（請求があれば回答）として表示した。

#### `mobile/app/help.tsx`
- ヘルプ下部に、利用規約・プライバシーポリシー・特商法表記への導線を追加した。

#### `mobile/app/user-evaluations.tsx`
- Web版 `/users/[id]/evaluations` に合わせて、評価一覧画面を追加した。
- 平均評価、星別ヒストグラム、コメント付き評価一覧を表示するようにした。

#### `mobile/app/(tabs)/profile.tsx` / `mobile/app/user-profile.tsx`
- 自分/相手プロフィールの評価サマリから、評価一覧へ遷移するようにした。

### 影響範囲

- iOS版ヘルプ
- iOS版法的ページ
- iOS版プロフィール
- iOS版相手プロフィール
- iOS版評価一覧

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- ヘルプ下部から3つの法的ページへ遷移
- プロフィールの評価サマリから評価一覧へ遷移
- 相手プロフィールの評価サマリから評価一覧へ遷移

### 関連ファイル

- `mobile/src/components/LegalDocument.tsx`
- `mobile/app/legal/terms.tsx`
- `mobile/app/legal/privacy.tsx`
- `mobile/app/legal/notice.tsx`
- `mobile/app/help.tsx`
- `mobile/app/user-evaluations.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/user-profile.tsx`

### セルフレビュー結果

- ✅ `notes/17_legal_alignment.md` を確認し、代表者情報は非公表方針で実装
- ✅ Web版の法的ページ3種に対応するiOS画面を追加
- ✅ 評価一覧を実画面化し、自分/相手プロフィールの評価サマリから接続
- ✅ 状態遷移変更はないため `notes/09_state_machines.md` は更新不要
- ✅ 新用語追加はないため `notes/10_glossary.md` は更新不要
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.23：iOS取引C-3をWeb版へ接続

### 背景・問題意識

WebAppでは合意後の取引体験が「取引チャット → 証跡撮影 → 双方承認 → 評価 → 必要なら申告」までC-3として通っている。一方iOS版は取引詳細/チャット中心で、合流後の証跡撮影・承認・評価が実画面として不足していたため、取引体験の最重要部分がWeb版と乖離していた。

### 変更内容

#### `mobile/app/transaction-capture.tsx`
- Web版 `/transactions/[id]/capture` に合わせて、証跡撮影画面を追加した。
- `expo-image-picker` でカメラ/ライブラリから写真を追加し、`chat-photos` Storage と `proposal_evidence_photos` に保存するようにした。
- 証跡完了時に `messages.meta.action='open_approve'` のsystem messageを投稿し、取引詳細へ戻すようにした。

#### `mobile/app/transaction-approve.tsx`
- Web版 `/transactions/[id]/approve` に合わせて、証跡写真、交換物サマリ、両者承認状態、承認CTAを追加した。
- 承認時に自分側の在庫減算、受け取り在庫の自分キープ追加、wish数量減算、個別募集の譲条件縮退、両者承認時の完了遷移を実行するようにした。

#### `mobile/app/transaction-rate.tsx`
- Web版 `/transactions/[id]/rate` に合わせて、完了後の評価画面を追加した。
- 5段階評価、任意コメント、既評価時の表示を実装した。

#### `mobile/app/dispute-new.tsx`
- Web版 `/disputes/new` の入口に合わせて、相違申告フォームを追加した。
- カテゴリ選択、事実メモ、C-3証跡写真の自動添付、`disputes` 作成、取引チャットへのsystem message投稿を実装した。

#### `mobile/src/lib/transactionActions.ts`
- iOS版クライアントから使う取引C-3共通処理を追加した。
- 証跡アップロード、証跡行追加/削除、証跡完了通知、完了承認、評価送信をWeb版のserver actionに沿って実装した。

#### `mobile/app/transaction-detail.tsx`
- 合意済み取引に「合流したら証跡を撮影」「証跡を確認して承認」「完了後に評価」のCTAを追加した。
- `open_approve` system messageをタップ可能にし、承認画面へ遷移できるようにした。

#### `mobile/app/notifications.tsx`
- `/transactions/:id/capture` / `/approve` / `/rate` のlink_pathをiOS画面へマップした。

#### `mobile/package.json` / `mobile/package-lock.json` / `mobile/app.json`
- 証跡撮影のため `expo-image-picker` を追加し、Expo pluginに登録した。

### 影響範囲

- iOS版取引詳細
- iOS版取引証跡撮影
- iOS版取引完了承認
- iOS版評価
- iOS版相違申告入口
- iOS版通知からの取引C-3遷移

### 確認方法

- `npm --prefix mobile run typecheck`
- 合意済み取引の取引詳細で「撮影する」から証跡撮影画面へ遷移
- 証跡追加後、完了CTAで取引詳細に戻り、system messageから承認画面へ遷移
- 承認後、両者承認なら評価画面へ遷移
- 承認画面の「相違あり」から申告フォームへ遷移

### 関連ファイル

- `mobile/app/transaction-detail.tsx`
- `mobile/app/transaction-capture.tsx`
- `mobile/app/transaction-approve.tsx`
- `mobile/app/transaction-rate.tsx`
- `mobile/app/dispute-new.tsx`
- `mobile/app/notifications.tsx`
- `mobile/src/lib/transactionActions.ts`
- `mobile/package.json`
- `mobile/package-lock.json`
- `mobile/app.json`

### セルフレビュー結果

- ✅ Web版C-3の主要状態（証跡撮影、証跡確認、双方承認、評価）に対応するiOS実画面を追加
- ✅ 完了承認時の在庫減算/受け取り在庫追加/wish減算/個別募集整理をWeb版の処理に合わせた
- ✅ 取引チャットのsystem messageから承認画面へ進む導線を追加
- ✅ `notes/09_state_machines.md` は既存C-3状態にiOS実装を追従しただけなので更新不要
- ✅ `notes/10_glossary.md` は新用語なし
- ⚠️ `expo-image-picker` 追加のため、既存のdevelopment buildでカメラ機能を使うにはネイティブ再ビルドが必要
- ✅ `npm --prefix mobile run typecheck` 通過

---

## イテレーション155.22：iOS検索/通知/予定導線を本体化

### 背景・問題意識

WebApp と照合すると、iOS版ではホーム左下検索、ホームのベル通知、プロフィール内のスケジュール/通知設定/ヘルプが無反応またはプレビュー画面止まりになっていた。またログイン画面の「パスワードを忘れた方」もメッセージ表示だけで、Web版のパスワード再設定導線に到達できていなかった。

### 変更内容

#### `mobile/src/components/RouteHeader.tsx`
- Web版 `HeaderBack` 相当の戻るボタン付きヘッダーをiOS共通コンポーネントとして追加した。

#### `mobile/app/search.tsx`
- Web版 `/search` に合わせて、他ユーザーの `goods_inventory(kind=for_trade, status=active)` をキーワード検索できる画面を追加した。
- title / character / group の部分一致検索、検索履歴、人気検索チップ、wish候補の優先表示を実装した。
- 検索結果から相手プロフィールへ遷移できるようにした。

#### `mobile/app/user-profile.tsx`
- Web版 `/users/[id]` に対応する相手プロフィール画面を追加した。
- 相手の基本情報、評価、取引回数、譲る候補を表示し、打診導線へつなげるようにした。

#### `mobile/app/notifications.tsx`
- Web版 `/notifications` に合わせて通知一覧を追加した。
- 未読/既読の見た目、相対時刻、タップで既読化、すべて既読、`link_path` から取引詳細/相手プロフィール等への遷移を実装した。

#### `mobile/app/notification-settings.tsx`
- Web版 `/settings/notifications` に合わせて通知設定画面を追加した。
- アプリ内通知は常時ON、メール通知は `user_notification_settings.email_enabled` を upsert するようにした。

#### `mobile/app/schedules.tsx` / `mobile/app/schedule-editor.tsx`
- Web版 `/schedules` と `/schedules/new` / `/schedules/[id]` に対応する予定一覧・作成/編集画面を追加した。
- 今後/過去の予定分割、削除、追加、編集、終日、メモ保存を実装した。

#### `mobile/app/help.tsx`
- Web版 `/help` に合わせて、FAQと運営問い合わせ導線を追加した。

#### `mobile/app/password-reset.tsx` / `mobile/app/auth/password-reset-confirm.tsx`
- Web版のパスワード再設定に合わせて、リセットメール送信と新パスワード設定画面を追加した。

#### `mobile/app/(tabs)/index.tsx`
- ホームのベルを通知一覧へ、左下検索ボタンを検索画面へ、場所表示をスケジュール画面へ接続した。

#### `mobile/app/(tabs)/profile.tsx`
- スケジュール、通知設定、ヘルプ・FAQをプレビューではなく実画面へ接続した。

#### `mobile/app/(auth)/login.tsx`
- 「パスワードを忘れた方」をパスワード再設定画面へ接続した。

### 影響範囲

- iOS版ホーム
- iOS版検索
- iOS版通知一覧/通知設定
- iOS版スケジュール
- iOS版ヘルプ
- iOS版パスワード再設定
- iOS版相手プロフィール

### 確認方法

- `npm --prefix mobile run typecheck`
- `git diff --check`
- ホーム左下検索から検索画面へ遷移し、検索履歴/人気検索/検索結果が表示されることを確認
- ホームのベルから通知一覧へ遷移し、未読既読とすべて既読が動くことを確認
- プロフィールのスケジュール/通知設定/ヘルプが実画面へ遷移することを確認
- ログイン画面からパスワード再設定メール送信画面へ遷移できることを確認

### 関連ファイル

- `mobile/src/components/RouteHeader.tsx`
- `mobile/app/search.tsx`
- `mobile/app/user-profile.tsx`
- `mobile/app/notifications.tsx`
- `mobile/app/notification-settings.tsx`
- `mobile/app/schedules.tsx`
- `mobile/app/schedule-editor.tsx`
- `mobile/app/help.tsx`
- `mobile/app/password-reset.tsx`
- `mobile/app/auth/password-reset-confirm.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/(auth)/login.tsx`

### セルフレビュー結果

- ✅ Web版に存在してiOSでプレビュー止まりだった検索/通知/通知設定/スケジュール/ヘルプを実画面化
- ✅ ホームとプロフィールの主要導線を無反応/プレビューから本体画面へ接続
- ✅ パスワード再設定をメール送信から新パスワード設定まで追加
- ✅ DBスキーマ・状態名の変更はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新しい業務用語は追加していないため `notes/10_glossary.md` は更新不要
- ⚠️ 取引証跡/承認/評価、申告、法的ページはWeb版との差分が残るため次の継続対象
- ✅ `npm --prefix mobile run typecheck` 通過
- ✅ `git diff --check` 通過

---

## イテレーション155.21：iOS Apple ID認証導線追加

### 背景・問題意識

iOS版の新規登録/ログインで、Web版アカウントのメール認証だけでなく Apple ID 経由でも入れるようにしたい。実機レビュー時にメール入力だけでは手間が残るため、iOSネイティブの Sign in with Apple を Supabase Auth に接続する。

### 変更内容

#### `mobile/src/auth/AuthProvider.tsx`
- Supabase Auth の `signInWithIdToken` を使う `signInWithAppleIdToken` を追加した。
- Apple ID認証後も通常ログインと同じく session を更新し、Preview mode を解除するようにした。

#### `mobile/src/components/AppleAuthButton.tsx`
- `expo-apple-authentication` の公式 Apple ボタンを共通コンポーネント化した。
- iOSで利用可能かを確認し、Apple の `identityToken` を Supabase へ渡す流れを実装した。
- キャンセル時はエラーを出さず、認証設定や token の問題は日本語メッセージへ変換するようにした。

#### `mobile/app/(auth)/login.tsx`
- ログイン画面の「または」以下を Apple IDログインに差し替えた。

#### `mobile/app/(auth)/signup.tsx`
- 新規登録画面に Apple IDで登録する導線を追加した。
- Apple ID登録でも利用規約/プライバシーポリシーへの同意がない場合は進めないようにした。

#### `mobile/app.json`
- iOS の `usesAppleSignIn` と `expo-apple-authentication` plugin を追加し、EAS iOS build で Sign in with Apple entitlement を付与できるようにした。

#### `mobile/package.json` / `mobile/package-lock.json`
- Expo SDK 54 対応版の `expo-apple-authentication@~8.0.8` を追加した。

### 影響範囲

- iOS版ログイン
- iOS版新規登録
- Supabase Auth 接続
- iOS development build / EAS build 設定

### 確認方法

- `npm --prefix mobile run typecheck`
- 新規登録画面で利用規約に同意後、Apple IDボタンから認証を開始できることを確認
- ログイン画面でApple IDボタンから認証を開始できることを確認
- Supabase側の Apple provider が未設定の場合、日本語エラーが表示されることを確認

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/src/components/AppleAuthButton.tsx`
- `mobile/app/(auth)/login.tsx`
- `mobile/app/(auth)/signup.tsx`
- `mobile/app.json`
- `mobile/package.json`
- `mobile/package-lock.json`

### セルフレビュー結果

- ✅ Apple公式ボタンを使用し、独自描画のAppleロゴは追加していない
- ✅ ログイン/新規登録どちらも同じ共通コンポーネントを利用
- ✅ 既存の session 管理・Preview解除フローに統合
- ✅ DBスキーマ・状態名の変更はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新しい業務用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm --prefix mobile run typecheck` 通過

---

## イテレーション155.20：iOSホーム/関係図/待ち合わせ入力の微修正

### 背景・問題意識

iOS版でホーム上部に「ログイン中」や Megrum ロゴ行が残っていて、Web版で整理したホームの軽さとズレていた。通知も `!` 表示のままでベルとして認識しづらかった。また、関係図のグッズ画像が文字プレースホルダーになりやすく、提示物選択の待ち合わせカレンダーは長押ししないと候補枠が作れず、取引一覧下部に大きな余白/グレー領域が出ていた。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- ホーム上部の Megrum ロゴ/タイトル/ログイン状態行を削除した。
- 上部通知ボタンを `!` からベルアイコンへ変更した。
- 検索アイコンを上部から外し、画面左下の固定フローティングボタンへ移動した。
- ホーム画面を `scroll={false}` + 内部 `ScrollView` にして、検索ボタンが画面に固定される構成にした。

#### `mobile/app/(tabs)/_layout.tsx`
- カスタムタブバーを絶対配置にして、画面下部に不要な占有領域が出ないようにした。

#### `mobile/app/match-detail.tsx`
- 関係図の `MiniItem` に `photoUrl` を持たせ、`ItemPhoto` が画像URLを表示できるようにした。
- ホームから渡される選択元画像と、提示物IDから取得した `goods_inventory.photo_urls` を関係図へ反映するようにした。

#### `mobile/src/data/proposalItems.ts`
- ホーム候補由来のアイテム解決でも `photoUrl` を引き継ぐようにした。

#### `mobile/app/proposal-select.tsx`
- 待ち合わせカレンダーで通常タップした場合、その時刻から30分の候補枠を作るようにした。
- 空状態の案内文を「タップで30分、長押しで時間を伸ばせるよ」に変更した。

### 影響範囲

- iOS版ホーム
- iOS版関係図
- iOS版提示物選択 > 待ち合わせ
- iOS版タブフッター

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- ホームで Megrum ロゴ行/ログイン中表示が出ないこと、通知がベルであること、検索が左下固定であることを確認
- 関係図で選択したグッズや提示物ID由来の画像が表示されることを確認
- 待ち合わせカレンダーでタップだけで30分枠が作れることを確認
- 取引一覧下部に大きなグレー領域が出ないことを確認

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/match-detail.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/src/data/proposalItems.ts`

### セルフレビュー結果

- ✅ ホーム上部から不要なログイン状態/ブランド行を削除
- ✅ 通知はベルアイコン、検索は左下固定ボタンへ変更
- ✅ 関係図のグッズ表示を画像URL対応に変更
- ✅ 待ち合わせカレンダーはタップで30分枠を生成
- ✅ DBスキーマ・状態名の変更はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.19：iOS取引詳細と編集画面のWeb寄せ

### 背景・問題意識

iOS版で実ログイン後、取引一覧のカードを押すと「読み込みに失敗しました」と表示されることがあった。加えて、完了タブ上部のステータスフィルタが潰れて見え、マイ在庫の横スワイプが指の動きに追従せず、マイ在庫/Wish/個別募集の作成・編集画面もWeb版の情報構造とズレていた。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 実データ取得失敗時にプレビュー用サンプル取引へフォールバックしないようにした。
- `proposals` の任意列がSupabase schema cacheに無い場合、その列を外して再取得するフォールバックを追加した。
- `rejected` を完了系ステータスとして扱い、「終了」フィルタに含めるようにした。
- 完了タブの横フィルタに高さ・折り返し制御を入れ、表示潰れを抑えた。

#### `mobile/app/transaction-detail.tsx`
- 取引詳細でも `meetup_candidates` など任意列が無い場合に列を外して再取得するようにした。
- メッセージ取得失敗だけで詳細全体が落ちないよう、チャット履歴は空配列にフォールバックした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫のステータス切替を手動タッチ判定から横ページャーに変更し、指の動きに追従して画面が動くようにした。

#### `mobile/app/goods-editor.tsx`
- マイ在庫/Wishの作成・編集画面をWeb版に近い順序（推し、グッズ、画像/状態、タグ、メモ）へ整理した。
- マイ在庫側にコンディション、数量、今日から持参中のUIを追加した。
- Wish側は画像、数量、タグ、メモの構造をWeb版に寄せた。

#### `mobile/app/listing-editor.tsx`
- 個別募集の作成・編集画面に「譲る条件」「求める条件（選択肢1、1pick/すべて、同異種/同種のみ/異種のみ）」を追加し、Web版の条件構造へ寄せた。

### 影響範囲

- iOS版取引一覧/取引詳細
- iOS版マイ在庫の横スワイプ
- iOS版マイ在庫/Wish/個別募集の作成・編集画面

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- 実ログイン後、取引一覧の打診中/進行中/完了カードから詳細へ遷移する
- マイ在庫で左右スワイプし、画面が指に追従することを確認
- マイ在庫/Wish/個別募集の作成・編集画面を開き、Web版に近い入力順になっていることを確認

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/goods-editor.tsx`
- `mobile/app/listing-editor.tsx`

### セルフレビュー結果

- ✅ 取引詳細の schema cache 差分に対するフォールバックを追加
- ✅ 実ログイン時に存在しないプレビュー取引IDへ遷移しないよう修正
- ✅ マイ在庫の横スワイプはページャー化し、指追従の挙動へ変更
- ✅ DBスキーマ・状態名の追加はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.18：iOSログイン設定の実機導線修正

### 背景・問題意識

iOS版でログインを押しても「Supabase設定待ち」から preview 導線しか出ず、Web版で作成済みの michilion アカウントでログインできなかった。原因は `mobile/.env.local` が無く、Expo 側が Supabase 公開設定を読めていなかったこと。また、新規登録画面からログインへ戻る導線も不足していた。

### 変更内容

#### ローカル環境
- `web/.env.local` の公開用 Supabase URL / publishable key だけを `mobile/.env.local` に反映した。
- `SUPABASE_SECRET_KEY` は反映していない。

#### `mobile/app/(auth)/signup.tsx`
- 新規登録画面下部に「すでにアカウントをお持ちの方は ログイン」を追加した。
- ログイン押下時は `/login` へ明示的に遷移するようにした。

### 影響範囲

- iOS版ログイン画面表示
- iOS版新規登録からログインへの導線
- ローカルExpo起動時のSupabase接続

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- Metroを再起動し、Welcome > ログインでログインフォームが出ることを確認
- 新規登録画面下部のログインリンクからログイン画面へ戻れることを確認

### 関連ファイル

- `mobile/app/(auth)/signup.tsx`
- `mobile/.env.local`（gitignore、ローカルのみ）

### セルフレビュー結果

- ✅ Web版と同じSupabase Authへ接続する前提を満たした
- ✅ secret key はmobileへコピーしていない
- ✅ DBスキーマ・状態名の変更はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.17：iOSプロフ下部ログアウトとログイン安定化

### 背景・問題意識

iOS版プロフ画面のログアウトが画面下部のアカウント操作として十分に明示されておらず、ログアウト後も遷移先が分かりづらかった。また、Web版で作成済みのメール/パスワードアカウントでiOS版へ入る前提なので、ログイン成功時にsessionを即時反映し、ホーム遷移が認証状態の更新待ちでブレないようにした。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- プロフ画面の最下部に「アカウント」セクションを追加し、メールアドレスとログアウトボタンを明示した。
- ログアウト押下時はSupabase signOut後に `/welcome` へ戻すようにした。
- ログアウト中のloading表示とエラー表示を追加した。

#### `mobile/src/auth/AuthProvider.tsx`
- `signIn` 成功時に返却されたsessionを即時 `setSession` へ反映するようにした。
- `signOut` 成功時にsessionを即時nullへ更新するようにした。

#### `mobile/app/(auth)/login.tsx`
- Web版と同じメールアドレス・パスワードでログインできる旨をログイン画面に明記した。

### 影響範囲

- iOS版ログイン
- iOS版ログアウト
- iOS版プロフ画面下部

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- Web版で作ったメール/パスワードアカウントでiOS版ログイン画面からログインできることを確認
- プロフ最下部のログアウトボタンを押し、Welcomeへ戻ることを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`
- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(auth)/login.tsx`

### セルフレビュー結果

- ✅ Web版と同じSupabase Authを使う前提に沿っている
- ✅ DBスキーマ・状態名の変更はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `PrimaryButton` を使い回している
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.16：iOS認証とオンボーディングをWeb版構成へ拡張

### 背景・問題意識

iOS Preview から実アカウントへ移る導線だけでは不十分で、Web版と同じ「Welcome → ログイン/新規登録 → メール認証 → プロフィール設定」の構成がiOS側に無かった。michilion の既存アカウントでログインし、今後の新規登録もWeb版と同じ流れで検証できるように、認証入口とオンボーディングをネイティブ画面として追加した。

### 変更内容

#### `mobile/app/(auth)/welcome.tsx`
- Web版の未ログイン Welcome と同じ構成で、ロゴ、キャッチコピー、新規登録、ログイン導線を追加した。
- Supabase未設定時のみ preview 起動導線を残した。

#### `mobile/app/(auth)/login.tsx`
- 既存の簡易セグメント式フォームを廃止し、Web版と同じログイン専用画面へ差し替えた。
- メールアドレス/パスワードで Supabase Auth にログインし、成功後ホームへ戻るようにした。
- 新規登録、Googleログイン枠、パスワード忘れ導線をWeb版の構成に合わせて配置した。

#### `mobile/app/(auth)/signup.tsx`
- Web版の新規登録と同じく、ハンドル名、メールアドレス、パスワード、確認、利用規約同意を持つ画面を追加した。
- パスワード強度バー、ハンドル形式チェック、ハンドル重複チェックを追加した。
- Supabase Auth signup 時に handle / display_name を metadata として渡すようにした。

#### `mobile/app/(auth)/verify-email.tsx`
- 確認メール送信後の案内画面を追加した。
- メール再送、メール変更、認証済みログイン導線を追加した。

#### `mobile/app/auth/email-confirmed.tsx`
- メール認証完了画面を追加し、`code` 付き deep link の session 交換を行うようにした。
- ログイン済みならプロフィール設定へ、未ログインならログインへ進めるようにした。

#### `mobile/app/onboarding/*`
- Web版と同じ4ステップ構成で、性別、推し、メンバー、活動エリア、完了画面を追加した。
- `users.gender` / `users.primary_area` / `users.account_status` と `user_oshi` を更新するようにした。
- 推し選択は `genres_master` / `groups_master` / pending `oshi_requests` を読み、ジャンルフィルタ・検索・複数選択に対応した。
- メンバー選択は `characters_master` と既存 `user_oshi` を読み、箱推し/個別メンバーを保存するようにした。

#### `mobile/src/auth/AuthProvider.tsx`
- `signUp` が handle / displayName を受け取り、Supabase Auth metadata と email redirect を設定できるようにした。

#### `mobile/app/(tabs)/_layout.tsx`
- 未ログイン時の遷移先を `/login` から `/welcome` に変更した。

#### `mobile/src/components/MegrumLogo.tsx`
- Web版の画面構成に合わせやすいよう、任意サイズ指定に対応した。

### 影響範囲

- iOS版未ログイン体験
- iOS版ログイン/新規登録
- iOS版メール認証後導線
- iOS版オンボーディング
- iOS版Supabase Auth signup metadata

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- 未ログイン状態でアプリを開き、Welcome → ログインへ進めることを確認
- michilion のメールアドレス/パスワードでログインし、ホームへ戻ることを確認
- Welcome → 新規登録 → verify-email まで進めることを確認
- 認証後に onboarding 4ステップへ進めることを確認

### 関連ファイル

- `mobile/app/(auth)/welcome.tsx`
- `mobile/app/(auth)/login.tsx`
- `mobile/app/(auth)/signup.tsx`
- `mobile/app/(auth)/verify-email.tsx`
- `mobile/app/auth/email-confirmed.tsx`
- `mobile/app/onboarding/gender.tsx`
- `mobile/app/onboarding/oshi.tsx`
- `mobile/app/onboarding/members.tsx`
- `mobile/app/onboarding/area.tsx`
- `mobile/app/onboarding/done.tsx`
- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/src/components/MegrumLogo.tsx`

### セルフレビュー結果

- ✅ Web版の認証・オンボーディング構成を確認してから実装した
- ✅ `打診` / `取引チャット` 等の既存用語は変更していない
- ✅ 既存の `users` / `user_oshi` / master tables を使用し、DBスキーマ変更はない
- ✅ 新しい状態名は追加していないため `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.15：iOS Previewから実ログインへ抜ける導線

### 背景・問題意識

iOS Preview では `Preview_hana` のアカウント表示のまま取引チャットを開くと「ログイン後に取引詳細を確認できます」と出るだけで、michilion の実アカウントへ切り替える入口が分かりづらかった。取引チャットは実データに接続しているため、preview からログインへ迷わず進める導線を追加した。

### 変更内容

#### `mobile/src/auth/AuthProvider.tsx`
- `signIn` / `signUp` 成功時に `previewMode` を解除するようにした。

#### `mobile/app/(tabs)/profile.tsx`
- preview 中のプロフ画面下部に「michilionでログインする」ボタンを追加し、preview を解除して `/login` へ遷移するようにした。
- preview 終了だけを行うサブボタンを分離した。

#### `mobile/app/transaction-detail.tsx`
- preview または未ログインで取引詳細を開いた時、理由を明示したうえでログイン CTA を表示するようにした。
- CTA から preview を解除して `/login` へ遷移できるようにした。

#### `mobile/app/(auth)/login.tsx`
- ログイン画面の説明文を、取引チャット確認のために実アカウントでログインする文脈へ合わせた。
- Supabase未設定時の preview 開始は、ログイン画面側から明示的にホームへ遷移するようにした。

#### `mobile/app/(auth)/_layout.tsx`
- preview 中に `/login` を開いた場合でもログイン画面を表示できるよう、previewMode による自動ホームリダイレクトを廃止した。

### 影響範囲

- iOS版ログイン導線
- iOS版プロフ画面
- iOS版取引詳細/取引チャットの未ログイン表示

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- iOS Preview のプロフから「michilionでログインする」を押し、ログイン画面へ遷移することを確認
- Preview_hana 状態で取引詳細を開いた時、ログイン CTA が表示されることを確認

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/(auth)/_layout.tsx`
- `mobile/app/transaction-detail.tsx`
- `mobile/app/(auth)/login.tsx`

### セルフレビュー結果

- ✅ `取引チャット` / `打診` の既存用語に沿って表示している
- ✅ DBスキーマ・状態名の変更はないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過

---

## イテレーション155.14：iOS推し設定を実データ一覧へ接続

### 背景・問題意識

iOS版プロフの「推し設定」もプロフィール編集と同様に `preview-detail` へ飛ぶだけで、Web版の `profile/oshi` のように登録済み推しを確認・管理できなかった。まずは既存の `user_oshi` を読み、グループ/メンバー単位で表示・削除できる画面へ差し替えた。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- 「推し設定」行の遷移先を `preview-detail` から `/oshi-settings` に変更した。

#### `mobile/app/oshi-settings.tsx`
- iOS版推し設定画面を追加した。
- `user_oshi` を `groups_master` / `characters_master` / `oshi_requests` / `character_requests` と合わせて取得し、グループ単位にまとめて表示するようにした。
- 承認待ちの仮登録グループ/メンバーも表示できるようにした。
- グループ削除、メンバー削除を `user_oshi` へ反映するようにした。
- 「登録済みの推しを追加」は次段階の検索/追加リクエスト本画面へ接続するため、現時点では明示的なNEXTプレビューにした。

### 影響範囲

- iOS版プロフ画面
- iOS版推し設定画面
- iOS版 `user_oshi` 表示/削除

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- iOSアプリでプロフ > 推し設定を開き、登録済み推しが表示されることを確認
- グループ/メンバー削除後、一覧が更新されることを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/oshi-settings.tsx`

### セルフレビュー結果

- ✅ Web版 `profile/oshi` と同じ `user_oshi` / request 系データソースを確認してから実装した
- ✅ 既存の `仮登録` / `承認待ち` の意味に沿って表示した
- ✅ 新しい状態名・DBカラムは追加していないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過

---

## イテレーション155.13：iOSプロフィール編集を保存可能画面へ差し替え

### 背景・問題意識

iOS版プロフ画面は前iterで表示データをWeb版と同期したが、アイデンティティ内の「プロフィール編集」はまだ `preview-detail` に遷移しており、Web版のように実際のプロフィールを編集・保存できなかった。プロフ周りの導線をWeb版へ近づけるため、まずプロフィール編集を本画面化した。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- 「プロフィール編集」行の遷移先を `preview-detail` から `/profile-edit` に変更した。

#### `mobile/app/profile-edit.tsx`
- iOS版プロフィール編集画面を追加した。
- `users` から handle / display_name / gender / primary_area / avatar_url を読み込み、編集フォームに反映するようにした。
- handle 重複チェック、handle/displayName/primaryArea のバリデーションを行い、`users` を更新するようにした。
- 既存アイコン画像は表示・削除できるようにした。ネイティブ画像選択/アップロードは次段階で追加する。

### 影響範囲

- iOS版プロフ画面
- iOS版プロフィール編集導線
- iOS版 `users` 更新

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- iOSアプリでプロフ > プロフィール編集を開き、保存できることを確認
- 保存後にプロフ画面へ戻り、表示名・ハンドル・エリアが反映されることを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`
- `mobile/app/profile-edit.tsx`

### セルフレビュー結果

- ✅ Web版 `profile/edit` と同じ主要入力項目を確認してから実装した
- ✅ `users` 既存カラムのみを更新しており、DBスキーマ変更はない
- ✅ 新しい状態名・用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.12：iOS取引詳細に取引チャットを接続

### 背景・問題意識

iOS版の取引詳細は、前iterで `proposals` の内容確認と基本応答までは実データ接続できたが、Web版の C-1.5 / C-2 にある `messages` ベースのネゴチャット・取引チャットがまだ表示されていなかった。打診後の体験が「内容を見るだけ」に寄るとWeb版との差が大きいため、まずメッセージ表示・送信・到着ステータス投稿を同じ `messages` テーブルに接続した。

### 変更内容

#### `mobile/app/transaction-detail.tsx`
- `messages` を proposal 単位で取得し、取引詳細内にネゴチャット/取引チャットとして表示するようにした。
- `text` / `system` / `arrival_status` / `photo` / `outfit_photo` / `location` の既存 `message_type` を読み分け、吹き出し・システム表示へ反映した。
- テキストメッセージ送信を `messages` へ INSERT するようにした。
- `agreed` 状態では「向かう」「到着」ボタンから `arrival_status` メッセージを投稿できるようにした。

### 影響範囲

- iOS版取引詳細
- iOS版ネゴチャット
- iOS版取引チャット

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- iOSアプリで取引一覧から打診/取引詳細を開き、既存メッセージが表示されることを確認
- メッセージ送信後、同じ画面に反映されることを確認
- 合意済み取引で「向かう」「到着」がシステム表示として投稿されることを確認

### 関連ファイル

- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ `取引チャット` / `ネゴチャット` / `打診` の用語は既存定義に沿っている
- ✅ `messages.message_type` は既存スキーマの範囲のみを使用している
- ✅ 新しい状態名・DBカラムは追加していないため `notes/05_data_model.md` / `notes/09_state_machines.md` は更新不要
- ✅ 新用語は追加していないため `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過

---

## イテレーション155.11：iOSプロフの表示データをWeb版と同期

### 背景・問題意識

前iterでホーム・打診・取引・在庫/Wishを実データへ接続した一方で、iOS版プロフは `michi`、取引18回、固定の推し表示など静的なプレビュー値が残っていた。Web版プロフィールは `users`、`user_oshi`、完了取引数、評価サマリを組み合わせて表示しているため、iOS版も同じデータソースに接続する必要があった。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- `users` から handle / display_name / primary_area / avatar_url を取得してヒーローに表示するようにした。
- `user_oshi` から登録済み推しをグループ単位にまとめ、推しカードのタイトル/件数を実データ化した。
- `proposals(status='completed')` から取引回数を取得し、`user_evaluations` から評価平均と件数を算出するようにした。
- Supabase未設定・プレビューモードでは従来のプレビュー値にfallbackするようにした。

### 影響範囲

- iOS版プロフ画面
- iOS版推しサマリ表示
- iOS版評価/取引回数表示

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- iOSアプリでプロフを開き、登録済みプロフィール・推し・評価・取引回数が表示されることを確認
- プレビュー/未接続時に画面が崩れずfallback表示になることを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`

### セルフレビュー結果

- ✅ Web版 `profile/page.tsx` と同じ主要データソースを確認してから接続した
- ✅ 新しい状態名・用語・DBカラムは追加していない
- ✅ `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.10：iOS主要画面を実データ接続へ前進

### 背景・問題意識

iOS版はWeb版の画面構成に近づいてきたが、ホーム・関係図・提示物選択・打診送信・取引一覧・在庫/Wish がまだ静的データ中心で、Webアプリと同じ市場データを見ている感覚が弱かった。オーナーから「Webアプリ画面通りに実装できていない部分があると思うので、実装してください」「チャットを止めずに進めてもらっていい」と指示があったため、まず主要フローをSupabaseの実データに接続した。

### 変更内容

#### `mobile/src/data/homeSupabase.ts`
- ホーム用のマッチ候補を `goods_inventory` / `listings` / `listing_wish_options` / `activity_windows` / `user_local_mode_settings` から生成するデータレイヤーを追加した。
- 「マッチしてるよ！」と「交換できるかも」を、個別募集マッチと通常の譲×Wish候補で分けて返すようにした。
- 候補カードから後続画面へ渡すため、相手ID・在庫ID・個別募集ID・写真URL・現地交換可否を保持するようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホームのマッチ行をSupabase由来の候補へ切り替えた。
- 現地交換モードの場所表示、通知未読数、モード切替更新を実データに接続した。
- 候補カードに実画像がある場合は画像を表示するようにした。

#### `mobile/app/match-detail.tsx`
- ホームで選んだ候補の相手ID・譲/受け取り在庫ID・個別募集IDを関係図/提示物選択へ引き継ぐようにした。
- 静的候補だけでなく、実データ候補から入っても後続の打診作成に必要なIDが落ちないようにした。

#### `mobile/src/data/proposalItems.ts`
- 提示物選択と送信確認で、静的カタログだけでなく `goods_inventory` の実在庫を表示できる override を追加した。
- 実画像URL、グッズ名、グループ、種別、色を共通変換できるようにした。

#### `mobile/app/proposal-select.tsx`
- 関係図経由で受け取った在庫IDをSupabaseから取得し、実画像付きの提示物選択として表示するようにした。
- 待ち合わせ候補の日時をISO形式で送信確認へ渡すようにした。

#### `mobile/app/proposal-confirm.tsx`
- 送信確認の提示物サムネイルを実在庫画像に対応させた。
- 打診送信時に `proposals` へ実レコードを保存する処理を追加した。
- `meetup_candidates` カラムがスキーマキャッシュ未更新の場合は、既存の `meetup_*` 列だけで再送する fallback を入れた。

#### `mobile/app/(tabs)/transactions.tsx`
- 取引一覧を `proposals` から読み込み、打診中/進行中/完了に分類するようにした。
- パネルの受け取る/私が出す/場所/時間/要対応判定を、ログインユーザー視点で組み立てるようにした。
- パネルタップ時はプレビューではなく実打診詳細へ遷移するようにした。

#### `mobile/app/transaction-detail.tsx`
- iOS版の取引/打診詳細画面を追加した。
- 相手情報、受け取るもの、私が出すもの、待ち合わせ候補、メッセージをSupabaseから表示する。
- 基本応答として、合意・条件相談・見送りを `proposals` と `messages` に反映できるようにした。

#### `mobile/app/(tabs)/inventory.tsx`
- マイ在庫を `goods_inventory(kind='for_trade')` から読み込み、画像・数量・ステータス・フィルタを実データ化した。
- 自分キープ/譲る候補への移動と削除をSupabaseへ反映するようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wishを `goods_inventory(kind='wanted')` から読み込み、画像と個別募集紐付け件数を表示するようにした。
- 個別募集一覧を `listings` と `listing_wish_options` から組み立てるようにした。
- 個別募集の一時停止/再開・削除、Wish削除をSupabaseへ反映するようにした。

#### `mobile/src/components/GoodsGrid.tsx`
- グッズカードが `photoUrl` を持つ場合、文字グリフではなく実画像を表示するようにした。

### 影響範囲

- iOS版ホーム
- iOS版マッチ詳細/関係図導線
- iOS版提示物選択・送信確認・打診作成
- iOS版取引一覧・取引詳細
- iOS版マイ在庫/Wish/個別募集一覧
- iOS版共通グッズグリッド

### 確認方法

- `npm run typecheck`（`mobile/`）
- `git diff --check`
- iOSアプリでログイン後、ホームに実データ由来のマッチ候補と画像が出ることを確認
- ホームの候補カードから提示物選択へ進み、選択した在庫IDと画像が送信確認まで残ることを確認
- 打診送信後、取引一覧に `proposals` 由来のパネルが出ることを確認
- 取引一覧のパネルを押して、取引詳細画面が404/プレビューではなく実データで開くことを確認
- マイ在庫/Wishで登録済み画像と件数が表示されることを確認

### 関連ファイル

- `mobile/src/data/homeSupabase.ts`
- `mobile/src/data/homeMatches.ts`
- `mobile/src/data/proposalItems.ts`
- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/match-detail.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/app/transaction-detail.tsx`

### セルフレビュー結果

- ✅ `打診` / `取引` / `個別募集` / `Wish` / `現地交換モード` は既存用語に沿っている
- ✅ `proposals.status` は既存の `sent` / `negotiating` / `agreement_one_side` / `agreed` / `completed` / `rejected` / `expired` / `cancelled` の範囲で扱っている
- ✅ DBは既存テーブル・既存カラムを利用しており、新規スキーマ変更はないため `notes/05_data_model.md` は更新不要
- ✅ 新状態・新用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` は更新不要
- ✅ `npm run typecheck`（`mobile/`）通過
- ✅ `git diff --check` 通過

---

## イテレーション155.09：iOS在庫とWishをWeb画面構成へ追加整合

### 背景・問題意識

iOS版の在庫/Wish周りは導線が増えたものの、Webアプリ画面そのものと比べると、在庫一覧の先頭追加カード、白いヘッダー、フォームのセクション構造などがまだ揃っていなかった。オーナーから「Webアプリ画面通りに実装できていない部分があると思うので、実装して」と指摘があったため、Web版 `InventoryView` / `WishView` / 追加編集フォームの画面構成にさらに寄せた。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- Web版 `AddCard` に近い、グリッド先頭に置ける点線枠の追加タイルを `GoodsGrid` に追加した。
- 追加タイルがある場合でも既存カードのスタガー表示が崩れないよう、表示遅延を調整した。

#### `mobile/app/(tabs)/inventory.tsx`
- ヘッダーを白いパネル型に変更し、Web版に近い `マイ在庫` + 列数切替 + フィルタ/検索アイコンの構成にした。
- `譲る候補` タブのグリッド先頭に追加カードを表示するようにし、ローカル浮遊ボタンよりWeb版の在庫画面構成に寄せた。
- 在庫追加導線は、先頭追加カードから `goods-editor` の登録画面へ進むようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- ヘッダーをWeb版に近い白いパネル型へ変更し、`ウィッシュ` + Wishタブ時のみ列数切替の構成にした。

#### `mobile/app/goods-editor.tsx`
- Web版の追加/編集フォームに合わせ、`写真` / `推し` / `グッズ` / `タグ` / `メモ` のセクション構造に変更した。
- 写真カードはセクション内に配置し、編集可否や追加予定などの補助表示を右上に出すようにした。

#### `mobile/app/listing-editor.tsx`
- 個別募集フォームを `譲る条件` / `求める条件` / `メモ` のセクション構造に変更した。
- `求める条件` では `1pick` / `すべて` の選択状態をセクションの文脈で見せるようにした。

### 影響範囲

- iOS版マイ在庫一覧
- iOS版Wish一覧
- iOS版在庫/Wish追加編集画面
- iOS版個別募集追加編集画面
- iOS版共通グッズグリッド

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでマイ在庫を開き、ヘッダーが白パネル化し、譲る候補の先頭に追加カードが出ることを確認
- iOSアプリでWishを開き、白パネル型ヘッダーと列数切替がWeb版の構成に近いことを確認
- iOSアプリで在庫/Wish/個別募集の追加・編集画面を開き、セクション単位でフォームが並ぶことを確認

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`
- `mobile/app/goods-editor.tsx`
- `mobile/app/listing-editor.tsx`

### セルフレビュー結果

- ✅ Web版の在庫/Wish一覧と追加編集フォームの構成を再確認してから修正した
- ✅ 在庫一覧はWeb版の先頭追加カード構成へ寄せた
- ✅ 追加/編集画面はWeb版のセクション構造へ寄せた
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.08：iOS在庫・Wishの追加編集導線を実体化

### 背景・問題意識

iOS版のマイ在庫・Wishは一覧表示がWeb版へ近づいた一方で、カードやボトムシートからの `編集する` / `追加` 導線がまだローカル追加やシートを閉じるだけの挙動だった。Web版では在庫・Wish・個別募集がそれぞれ追加/編集画面へ進むため、iOS版でも右スライド遷移で次画面を開き、画面上で内容を確認・編集できる状態に寄せる必要があった。

### 変更内容

#### `mobile/app/goods-editor.tsx`
- 在庫とWishで共用できる追加/編集/閲覧専用のネイティブ画面を追加した。
- カードプレビュー、タイトル、グループ/作品、グッズ種別、数量ステッパー、タグ、メモを編集できる構成にした。
- 過去に譲った在庫は `readonly` モードとして開き、Web版と同じく更新・削除できない詳細確認にした。

#### `mobile/app/listing-editor.tsx`
- 個別募集の作成/編集用ネイティブ画面を追加した。
- 譲る候補、求めるもの、`1pick` / `すべて`、ACTIVE/一時停止を編集できる構成にした。
- 入力内容に連動する紐付きプレビューを表示し、Web版の募集デッキの関係性表現と揃えた。

#### `mobile/app/(tabs)/inventory.tsx`
- `編集する` で `goods-editor` の在庫編集画面へ進むようにした。
- 過去に譲った在庫をタップした場合は、ボトムシートではなく閲覧専用詳細へ進むようにした。
- `+` ボタンはローカル仮カード追加ではなく、在庫登録画面へ進むようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- Wishの `編集する` / `+ 個別募集を追加` / `個別募集を作る` から、対応する編集・作成画面へ進むようにした。
- 個別募集カード右上の編集アイコンとボトムシートの `編集する` から、個別募集編集画面へ進むようにした。
- Wish/個別募集の `+` ボタンをローカル仮追加ではなく、追加画面への導線に変更した。

### 影響範囲

- iOS版マイ在庫
- iOS版Wish
- iOS版個別募集
- iOS版追加/編集/閲覧専用の画面遷移

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでマイ在庫の `+` / `編集する` / 過去に譲ったカードタップから、それぞれ追加・編集・閲覧専用画面へ進むことを確認
- iOSアプリでWishの `+` / `編集する` / 個別募集追加導線から、それぞれ該当画面へ進むことを確認
- iOSアプリで個別募集の編集アイコンとボトムシートから、個別募集編集画面へ進むことを確認

### 関連ファイル

- `mobile/app/goods-editor.tsx`
- `mobile/app/listing-editor.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ 一覧だけでなく、追加・編集・閲覧専用の遷移先を用意した
- ✅ 過去に譲った在庫はWeb版同様に更新不可の詳細確認へ分けた
- ✅ Expo Router の右スライド遷移を使う既存画面遷移文法に揃えた
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.07：iOSグッズカードをWeb版カード文法へ寄せる

### 背景・問題意識

イテレーション155.06で在庫/Wishの情報設計はWeb版へ近づいたが、iOS版の共通グッズグリッドは画像枠の外にタイトルと種別が出る構成のままで、Web版の `ItemCard` / `WishCard` にある「3:4カード内にメンバー名・募集バッジ・種別ストリップを載せる」文法とまだ差があった。列数を4列・5列にした時も、カード外テキストが密になりやすいため、カード内に情報を収める方がWeb版に近く、見た目も安定する。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- 共通グッズタイルを、Web版と同じ3:4寄りのカード内情報配置へ変更した。
- タイトルを左上の白プレート、募集/在庫バッジを右上の小バッジとしてカード内に表示するようにした。
- `未紐付け` バッジは警告色で表示し、Wishの状態が見分けやすいようにした。
- 種別・グループ情報はカード下部の白ストリップ内に収め、カード外テキストを廃止した。

### 影響範囲

- iOS版マイ在庫グリッド
- iOS版Wishグリッド
- iOS版共通グッズタイル表示

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでマイ在庫とWishを開き、3列/4列/5列でカード内にタイトル・バッジ・種別が収まることを確認

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`

### セルフレビュー結果

- ✅ Web版 `ItemCard` / `WishCard` の情報配置に近いカード内レイアウトへ寄せた
- ✅ 4列・5列でもカード外テキストが詰まらない構成にした
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.06：iOS在庫とWishをWeb版構成へ寄せる

### 背景・問題意識

iOS版のマイ在庫とWishは画面の土台はできていたが、Web版で確定している情報設計との差分が残っていた。マイ在庫では推し・種別フィルタが固定表示で動作せず、Wishでは紐付け中の個別募集数や個別募集一覧の見せ方がWeb版より薄く、オーナーから「マイ在庫周りとかWishあたりもちゃんとWebアプリに沿って」開発するよう要望があった。

### 変更内容

#### `mobile/app/(tabs)/inventory.tsx`
- 固定の種別チップを廃止し、登録済みアイテムから `group` / `type` を抽出する実データ駆動フィルタに変更した。
- Web版 `InventoryView` と同じく、フィルタ適用後の件数で `譲る候補` / `自分用キープ` / `過去に譲った` のタブ数を更新するようにした。
- グッズ追加時はフィルタをリセットし、新規追加した譲る候補がすぐ見えるようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- ヘッダー表示を `ウィッシュ` に寄せ、Wishタブ内の固定フィルタを廃止した。
- Wishカードのバッジを `未紐付け` / `募集 N` のWeb版ルールへ寄せた。
- Wishのボトムシートで、紐付け済みの場合は `+ 個別募集を追加` を出すようにした。
- 個別募集タブにWeb版 `ListingsView` の「募集デッキ」に相当する横スクロールの大きめカードを追加した。
- 個別募集カードでは、複数グッズの選択肢だけ枠で囲み、`すべて` / `1pick` をタグとして見せる構成に寄せた。
- 編集・一時停止/再開・削除の操作をカード右上の小アイコンとして押せるようにした。

### 影響範囲

- iOS版マイ在庫
- iOS版Wish
- iOS版個別募集一覧
- iOS版在庫/Wishのプレビュー用ローカル状態

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでマイ在庫を開き、推し・種別チップで各タブ件数とグリッド内容が変わることを確認
- iOSアプリでWishを開き、カード上に `未紐付け` / `募集 N` が表示されることを確認
- iOSアプリでWish → 個別募集を開き、募集デッキと一覧カードが表示されることを確認

### 関連ファイル

- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版のInventory/Wish/Listingsの情報設計を確認してからiOS版へ反映した
- ✅ マイ在庫のフィルタと件数集計は実データ由来にした
- ✅ Wishの募集連携バッジと個別募集追加導線をWeb版文言へ寄せた
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.05：iOS待ち合わせ候補2の追加判定を安定化

### 背景・問題意識

iOS版の提示物選択の待ち合わせタブで、候補1を設定した後にカレンダー上で候補2を追加しようとしても、候補1を再度選ぶような挙動になることがあった。空き枠で新規候補を作るタッチ操作と、既存候補を選択・移動するタッチ操作の状態が残ると、直前の候補1操作に吸われる余地があった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 空き枠の長押し開始時に、既存候補のタッチ状態を必ずクリアするようにした。
- 空き枠の新規候補作成中は `activeCandidateId` を一度外し、候補1の選択状態が残ったまま候補2作成へ入らないようにした。
- 空き枠側の touch start / move / end で `stopPropagation` を呼び、既存候補操作と新規候補作成のイベント経路を分離した。
- touch cancel 時も既存候補の編集状態をクリアし、次の候補追加操作に古い状態が残らないようにした。

### 影響範囲

- iOS版提示物選択
- iOS版待ち合わせタブの候補追加
- iOS版待ち合わせ候補の既存候補選択・移動

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで候補1を設定後、別の空き時間を長押しして候補2の場所設定シートが開くことを確認
- 既存候補を長押しした場合は、従来通り候補移動として扱われることを確認

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 空き枠からの候補追加と既存候補操作のタッチ状態を分離した
- ✅ 候補1設定後も候補2を新規作成できる経路を明確にした
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.04：iOS場所設定で現在地とピン位置を自動反映

### 背景・問題意識

iOS版の提示物選択の待ち合わせタブで、場所設定シートの `現在地を中心に` を押しても固定のプリセット座標に移動するだけで、自分の現在地にはならなかった。また、地図をタップしてピンを立てても場所名が自動取得されず、下部の2つの候補ボタンも固定のままだったため、ユーザーが選んだピンと表示候補が連動していなかった。

### 変更内容

#### `mobile/package.json`
- 現在地取得と逆ジオコード用に `expo-location` を追加した。

#### `mobile/app/proposal-select.tsx`
- `現在地を中心に` 押下時に位置情報権限を確認し、許可されていれば端末の現在地へピンと地図中心を移動するようにした。
- 現在地取得後・地図タップ後に `Location.reverseGeocodeAsync` で場所名を取得し、入力欄へ自動反映するようにした。
- 地図タップ時は、選んだピン座標をもとに下部の候補ボタン2件を更新するようにした。
- 位置情報取得中は `取得中…` を表示し、許可なし・取得失敗時は短いメッセージを表示するようにした。
- 既存の開発ビルドに native module が含まれていない場合でも画面全体が即落ちしないよう、`expo-location` は場所取得時に動的 import するようにした。

### 影響範囲

- iOS版提示物選択
- iOS版待ち合わせタブの場所設定シート
- iOS版現在地取得・地図タップ・候補場所ボタン

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで提示物選択 → 待ち合わせタブ → 候補時間選択 → 場所設定を開き、`現在地を中心に` で端末現在地に移動することを確認
- 地図をタップして、入力欄と下部候補ボタンがピン位置由来の内容へ更新されることを確認

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `mobile/package.json`
- `mobile/package-lock.json`

### セルフレビュー結果

- ✅ 固定プリセットではなく端末位置情報を使う導線に変更した
- ✅ 地図タップ後に場所名と候補ボタンがピン座標へ連動するようにした
- ✅ 位置情報権限文言は既存 `app.json` の `NSLocationWhenInUseUsageDescription` と整合している
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.03：iOS待ち合わせカレンダーのタップ位置ズレを修正

### 背景・問題意識

iOS版の提示物選択の待ち合わせタブで、カレンダーを長押し・ドラッグしても、実際に押した時刻と違う位置に候補時間が作られることがあった。時間の罫線セルがタッチ対象になると、`locationY` が日付列全体ではなくセル内基準で渡り、slot 計算がずれる可能性があった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- カレンダーの時間罫線セルを `pointerEvents="none"` にして、タッチ座標を日付列全体で受けるようにした。
- 空状態のガイド表示も `pointerEvents="none"` にし、ガイド上で長押ししても下のカレンダー列へ操作が届くようにした。
- 測定対象のカレンダーグリッドに `collapsable={false}` を付け、候補移動時の座標測定を安定させた。

### 影響範囲

- iOS版提示物選択
- iOS版待ち合わせタブのカレンダー時間選択
- iOS版待ち合わせ候補の長押し移動・終了時間調整

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで提示物選択 → 待ち合わせタブを開き、10時・14時・20時など複数位置を長押しして、押した時刻付近に候補が作られることを確認

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 見た目用の罫線セルがタッチ座標の基準を奪わないようにした
- ✅ 空状態ガイドがカレンダー操作を邪魔しないようにした
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.02：iOS送信確認の候補地図カードをWeb版へ寄せる

### 背景・問題意識

Web版の送信確認では、交換できる候補が「待ち合わせ候補」ヘッダーと件数バッジ、地図、候補リストのまとまりとして見える。iOS版は地図とリストだけが表示され、送信確認で何件の候補を送るのかが一目で分かりにくかった。

### 変更内容

#### `mobile/app/proposal-confirm.tsx`
- `MeetupMapCard` の上部に `待ち合わせ候補` ヘッダーと候補件数バッジを追加した。
- Web版 `MeetupPlanPreview` と同じ「ヘッダー → 地図 → 候補リスト」の情報順に寄せた。

### 影響範囲

- iOS版送信確認
- iOS版交換できる候補の地図カード

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで提示物選択 → 待ち合わせ候補設定 → 送信確認を開き、候補地図カード上部に候補件数が表示されることを確認

### 関連ファイル

- `mobile/app/proposal-confirm.tsx`

### セルフレビュー結果

- ✅ Web版の候補地図カードと同じ情報順へ寄せた
- ✅ カレンダー表示は追加せず、ユーザー指示通り送信確認は地図中心のまま維持した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.01：iOS打診フローで相手ハンドルを引き継ぐ

### 背景・問題意識

iOS版の送信確認と打診完了画面は、関係図から遷移しても相手表示が固定の `@michilion` に閉じていた。今後マッチングパネルや取引相手が増えた時に、遷移元の相手文脈を後続画面へ渡せる必要がある。

### 変更内容

#### `mobile/app/match-detail.tsx`
- 関係図から提示物選択へ進む route params に `partnerHandle` を追加した。

#### `mobile/app/proposal-select.tsx`
- `partnerHandle` を受け取り、送信確認画面へそのまま引き継ぐようにした。

#### `mobile/app/proposal-confirm.tsx`
- 送信確認の宛先表示と打診完了演出の相手ハンドルを、route params 由来の値で表示するようにした。
- params が無い場合のみ既存のプレビュー用 fallback を使うようにした。

### 影響範囲

- iOS版関係図から提示物選択への遷移
- iOS版送信確認
- iOS版打診完了画面

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでホーム → マッチングパネル → 関係図 → 打診に進む → 送信確認 → 打診送信を開き、相手ハンドルが画面間で維持されることを確認

### 関連ファイル

- `mobile/app/match-detail.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`

### セルフレビュー結果

- ✅ 相手表示を固定値前提から route params 優先へ寄せた
- ✅ 既存プレビュー単体起動時の fallback は維持した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション155.00：iOS提示物選択に関係図の選択内容を反映

### 背景・問題意識

iOS版の関係図から提示物選択へ進む時、関係図側では `gives` / `receives` / `listings` を渡していたが、提示物選択と送信確認は固定サンプルを表示していた。ホームで選んだマッチングパネルの文脈が後続画面に反映されず、Web版の「選んだ候補を持ったまま打診へ進む」体験と差分が残っていた。

### 変更内容

#### `mobile/src/data/proposalItems.ts`
- 関係図から渡されるグッズIDを、提示物選択カードと送信確認サムネイル用の表示データへ変換する共通ヘルパーを追加した。
- ホームのマッチ候補IDは `findCandidateContext` を使ってラベル・キャラ名・種別・色を解決し、未知IDでもプレビュー表示が破綻しない fallback を用意した。

#### `mobile/app/proposal-select.tsx`
- route params の `gives` / `receives` / `listings` / `candidateId` を読み取り、関係図で選ばれた譲・受け取り候補を初期選択として表示するようにした。
- 提示物カードを複数選択できる形にし、選択数を上部タブの count に反映するようにした。
- 送信確認へ進む時に、選択済みの `gives` / `receives` と関係図由来の `listings` / `candidateId` を引き継ぐようにした。

#### `mobile/app/proposal-confirm.tsx`
- 送信確認の「交換内容」を固定サンプルではなく、前画面で選ばれた譲・受け取り候補から組み立てるようにした。

### 影響範囲

- iOS版関係図から提示物選択への遷移
- iOS版提示物選択の `私が出す` / `受け取る` タブ
- iOS版送信確認の交換内容表示

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでホーム → マッチングパネル → 関係図 → 打診に進む → 提示物選択 → 送信確認を開き、関係図で選ばれた候補が提示物選択と送信確認に引き継がれることを確認

### 関連ファイル

- `mobile/src/data/proposalItems.ts`
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`

### セルフレビュー結果

- ✅ 関係図側で既に渡している `gives` / `receives` をiOS版C-0で利用するようにした
- ✅ 送信確認の交換内容が固定サンプルに戻らず、選択済みグッズで表示されるようにした
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.99：iOS関係図スワイプ終端のちらつきを抑制

### 背景・問題意識

iOS版の関係図で横スワイプして隣のマッチ詳細へ切り替える時、切り替え終端で別ページが一瞬見えるようなちらつきがあった。スワイプ終端で `activeContext` の差し替えと `dragX` のリセットが別タイミングで画面に反映され、旧ページや隣接プレビューが一瞬表に出る余地があった。

### 変更内容

#### `mobile/app/match-detail.tsx`
- スワイプ確定アニメーション完了時に、到着先ページの静止カバーを一時的に最前面へ表示するようにした。
- 静止カバーを表示したまま、次フレームで `activeContext` 差し替えと `dragX` リセットを行い、さらに次フレームでカバーを外すようにした。
- unmount 時に予約済み `requestAnimationFrame` をキャンセルし、画面遷移中の不要な state 更新を避けるようにした。

### 影響範囲

- iOS版関係図
- iOS版関係図の横スワイプページング

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでホーム → マッチングパネル → 関係図を開き、左右スワイプの終端で別ページが一瞬見えないことを確認

### 関連ファイル

- `mobile/app/match-detail.tsx`

### セルフレビュー結果

- ✅ スワイプ終端のページ差し替えを静止カバーで覆い、ちらつきが見えにくい構成にした
- ✅ 通常の横スワイプ追従・隣接プレビュー・1スワイプ1遷移の挙動は維持した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.98：iOSプロフヒーローをWeb版へ寄せる

### 背景・問題意識

Web版のプロフ画面は、上部ヒーローが紫〜水色のブランド面として表示され、アバター・ハンドル・表示名・取引回数・評価が一つの塊で見える。iOS版は白いカード内にステータスカードを3つ並べる構成で、Web版の「他人プロフと同じ仕様のヒーロー」に比べて印象が離れていた。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- プロフ画面上部の補足文とプレビューステータス pill を外し、Web版同様にシンプルな `プロフ` ヘッダーにした。
- ヒーローを白カードからブランドカラー面へ変更し、アバター・ハンドル・表示名・エリア・取引回数をまとめて表示する構成へ寄せた。
- 下段の `成立 / 評価 / 現地` 3カードを廃止し、Web版と同じ右側評価パネルに集約した。
- 評価パネル押下時は、既存の右スライド詳細導線で評価一覧プレビューへ進むようにした。

### 影響範囲

- iOS版プロフ画面
- iOS版プロフから評価一覧への導線

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでプロフタブを開き、Web版のプロフヒーローと同じ情報構成になっていることを確認
- 評価パネルを押して、詳細画面へ進み戻れることを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`

### セルフレビュー結果

- ✅ Web版のプロフヒーローに合わせ、評価を右側パネルに集約した
- ✅ 設定ボタンやアカウント削除など、不要導線は追加していない
- ✅ 既存のプロフィール編集・推し設定・スケジュール行は維持した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.97：iOS在庫とWishに横スワイプタブを追加

### 背景・問題意識

Web版のマイ在庫とWishは、上部タブをタップするだけでなく、画面内を横スワイプして隣のタブへ切り替えられる。iOS版ではタップ切り替えだけだったため、ネイティブアプリとしての手触りとWeb版の機能再現に差分が残っていた。

### 変更内容

#### `mobile/app/(tabs)/inventory.tsx`
- `譲る候補` / `自分用キープ` / `過去に譲った` のタブを、横スワイプでも切り替えられるようにした。
- 縦スクロールと競合しないよう、横移動が十分大きい場合のみタブ切り替え判定に入るようにした。
- タブ切り替え時は、開いている下部アクションシートを閉じるようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- `Wish` / `個別募集` のタブを、横スワイプでも切り替えられるようにした。
- 縦スクロール中の誤判定を避けるため、在庫画面と同じ軸ロック判定を使った。
- タブ切り替え時は、Wish・個別募集の選択状態をクリアするようにした。

### 影響範囲

- iOS版マイ在庫
- iOS版Wish
- iOS版個別募集一覧入口

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでマイ在庫を開き、グッズ一覧上で左右にスワイプしてタブが切り替わることを確認
- iOSアプリでWishを開き、Wish一覧と個別募集一覧が左右スワイプで切り替わることを確認

### 関連ファイル

- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版のスワイプタブ操作をiOS版にも追加した
- ✅ 軸ロックを入れ、縦スクロールの操作感を壊しにくい実装にした
- ✅ 既存のタップ切り替え・下部アクションシート・列数切り替えは維持した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.96：iOS関係図をWeb版の構成へ近づける

### 背景・問題意識

iOS版のホームからマッチングパネルをタップした後の関係図は、Web版 `MatchDetailModal` と同じ見た目・機能へ寄せる必要がある。前回までで横スワイプと候補選択は入ったが、iOS版だけ先頭に「選択したグッズの文脈カード」があり、Web版より一段余計な画面構成になっていた。

### 変更内容

#### `mobile/app/match-detail.tsx`
- Web版と同じく、関係図の先頭はすぐ `あなたの個別募集` / `相手の個別募集` / `譲 × wish の関係` が見える構成にした。
- iOS版独自の文脈カードと関連スタイルを削除し、選択元の強調は既存のサムネイル枠で表現するようにした。
- 関係図から提示物選択へ進む際、`tab=meetup` だけでなく `candidateId` / `gives` / `receives` / `listings` を次画面へ渡すようにした。

### 影響範囲

- iOS版ホームのマッチングパネル押下後
- iOS版関係図
- iOS版関係図から提示物選択への遷移

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでホーム → マッチングパネル → 関係図を開き、Web版と同じく関係図本体から始まることを確認
- 関係図で候補を選択して `打診に進む` を押し、待ち合わせタブへ直接進むことを確認

### 関連ファイル

- `mobile/app/match-detail.tsx`

### セルフレビュー結果

- ✅ Web版にない先頭文脈カードを削除し、関係図の情報密度と開始位置を揃えた
- ✅ 選択元の目立たせ方は、Web版と同じく関係図内サムネイルの強調に寄せた
- ✅ 後続画面へ選択情報を渡す土台を追加し、Web版の `gives` / `receives` / `listings` 連携に近づけた
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.95：iOS C-0と取引一覧をWeb版へ寄せる

### 背景・問題意識

iOS版の提示物選択は、待ち合わせ候補の作成まではWeb版に近づいたが、一度作った候補の移動・終了時間調整や、提示物選択タブの横スワイプがまだ弱かった。また、取引一覧はWeb版で調整した「一度見せたパネルは再登場アニメを繰り返さない」「完了内の絞り込みを用意する」挙動に追いついていなかった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 「私が出す」「受け取る」タブ上で横スワイプすると、隣の提示物タブへ切り替わるようにした。
- 待ち合わせタブの候補ブロックを長押しすると、ふわっと浮いた状態になり、日をまたいだドラッグ移動ができるようにした。
- 候補ブロック下部のハンドルを長押しして上下に動かすと、終了時間を15分単位で調整できるようにした。
- 待ち合わせタブのCTAを、Web版と同じ粒度で `次へ：送信確認 →` / `場所未設定の候補があります` / `交換できる時間を設定してください` に分けた。

#### `mobile/app/proposal-confirm.tsx`
- 送信確認の主ボタンを `この内容で打診を送信` に変更した。
- 打診完了後の説明文に相手IDを入れ、Web版同様に通知と打診一覧で確認できることを伝える文言へ寄せた。
- 完了後の導線を `まだ他に探す` / `打診一覧に飛ぶ` に揃えた。

#### `mobile/app/(tabs)/transactions.tsx`
- 進行中・完了タブでも、初回表示後にタブを戻した時はパネルの登場アニメを繰り返さないようにした。
- 完了タブ内に `すべて` / `完了` / `キャンセル` / `期限切れ` の絞り込みチップを追加した。

### 影響範囲

- iOS版提示物選択
- iOS版送信確認・打診完了
- iOS版取引一覧

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで、関係図 → 提示物の選択 → 横スワイプ → 待ち合わせ候補の長押し移動/終了時間調整 → 送信確認 → 打診完了、の順に確認
- iOSアプリで取引一覧の `打診中` / `進行中` / `完了` を切り替え、2回目以降にカード登場アニメが繰り返されないことを確認

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ Web版 `ProposeFlow` の待ち合わせ候補編集に近い、長押し移動・終了時間リサイズ・場所未設定CTAをiOS版へ反映した
- ✅ 送信確認と完了画面の主要文言をWeb版の表現へ寄せた
- ✅ 取引一覧はタブ初回表示時だけ登場アニメを出し、以降は違和感なく戻れるようにした
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.94：iOS待ち合わせカレンダーを15分ドラッグ作成へ寄せる

### 背景・問題意識

前 iter でiOS版の待ち合わせタブにカレンダーと地図シートを追加したが、Web版で決めていた「Google Calendar っぽく、長押しからドラッグして交換できる時間を設定する」操作としてはまだ粗かった。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- 待ち合わせカレンダーを1時間単位から15分スロットへ変更した。
- 日付ヘッダーを固定日付ではなく、端末日付から5日分生成するようにした。
- 今日の列を薄紫でハイライトし、曜日ずれが起きないようにした。
- カレンダー領域で長押しするとドラッグ選択プレビューが出て、指を離した範囲で候補時間を作成するようにした。
- 何も動かさず長押しだけで離した場合も、最小1時間の候補として作成するようにした。
- 候補作成後は従来どおり場所設定シートを自動表示する。

### 影響範囲

- iOS版提示物選択の待ち合わせタブ

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで、待ち合わせタブのカレンダーを縦スクロールし、任意の列を長押しして上下にドラッグし、候補時間と場所設定シートが出ることを確認

### 関連ファイル

- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 15分単位のスロットと5日表示に寄せ、Web版の待ち合わせカレンダー体験へ近づけた
- ✅ 長押し前の軽い縦スクロールでは候補作成に入らず、スクロール操作を阻害しにくい実装にした
- ✅ 場所未設定の `!` 表示と場所設定シート連携は維持した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.93：iOS待ち合わせと送信確認をネイティブ地図へ寄せる

### 背景・問題意識

iOS版の関係図横スワイプで、一度のスワイプが二段階の画面遷移に見えてしまっていた。また、提示物選択の待ち合わせタブと送信確認画面がWeb版の体験に比べて簡略化されており、地図もiOSらしい見え方になっていなかった。

### 変更内容

#### `mobile/app/match-detail.tsx`
- 関係図の横スワイプ確定時に、退出アニメーション後さらに新画面を入場させる二段アニメーションをやめた。
- スワイプ確定中の二重入力を防ぐロックを追加し、1スワイプにつき1候補だけ切り替わるようにした。

#### `mobile/app/proposal-select.tsx`
- 待ち合わせタブを5日表示・24時間縦スクロールのカレンダーUIへ寄せた。
- 長押しで候補時間を作成し、場所未設定の候補は中央の `!` で警告表示するようにした。
- 候補作成後に場所設定シートを開き、場所入力・プリセット・前の設定流用・地図タップでの座標更新をできるようにした。
- 送信確認へ進む際、設定済みの候補時間・場所・座標を `proposal-confirm` へ渡すようにした。

#### `mobile/app/proposal-confirm.tsx`
- 送信確認画面の交換候補地図を描画風パネルからネイティブ地図へ差し替えた。
- 待ち合わせタブで指定した候補をパースし、地図上のピンと候補リストに反映するようにした。
- 任意メッセージ欄のプレースホルダーを外した。

#### `mobile/src/components/NativeMapPreview.tsx`
- `react-native-maps` の共通地図コンポーネントを追加した。
- iOSではプロバイダを指定しないため、標準のApple Maps表示でレビューできる。

### 影響範囲

- iOS版関係図
- iOS版提示物選択の待ち合わせタブ
- iOS版送信確認
- iOS版地図プレビュー

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで、ホーム → マッチングパネル → 関係図横スワイプ → 打診に進む → 待ち合わせ → 送信確認、の順に確認

### 関連ファイル

- `mobile/app/match-detail.tsx`
- `mobile/app/proposal-select.tsx`
- `mobile/app/proposal-confirm.tsx`
- `mobile/src/components/NativeMapPreview.tsx`

### セルフレビュー結果

- ✅ 関係図の横スワイプは、確定後の二段階入場アニメーションを廃止し、1スワイプ1遷移に揃えた
- ✅ 待ち合わせタブは候補時間作成・場所未設定警告・場所設定シート・送信確認連携まで一連で確認できる
- ✅ 送信確認ではカレンダーを出さず、候補場所をネイティブ地図とリストで見せる構成にした
- ✅ iOS地図は `react-native-maps` のデフォルトプロバイダを使うためApple Maps表示になる
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.92：iOS送信確認画面を専用化

### 背景・問題意識

iOS版の提示物選択では、待ち合わせタブから「送信確認へ進む」を押した後、汎用の `preview-detail` に遷移していた。

Web版では送信確認画面が、交換内容・交換できる候補・任意メッセージ・スケジュール共有・送信後の完了演出までを担う。iOS版でもこの体験を確認できるよう、汎用詳細ではなく専用画面へ差し替える。

### 変更内容

#### `mobile/app/proposal-confirm.tsx`
- iOS版の送信確認画面を追加した。
- `交換内容` では、相手の譲とあなたの譲を左右に置き、中央の矢印で交換関係を示すようにした。
- `交換できる候補` では、地図風パネルに候補ピンを立て、下に候補時間と場所を並べるようにした。
- `メッセージ（任意）` は空の入力欄として用意し、余計なプレースホルダー文章を避けた。
- `スケジュールを共有する` のON/OFFを用意した。
- `打診を送る` 押下後は `打診が完了しました` の完了演出を表示し、`まだ他に探す` / `打診一覧に行く` の2導線を出すようにした。

#### `mobile/app/proposal-select.tsx`
- 待ち合わせタブの `送信確認へ進む` の遷移先を、汎用 `preview-detail` から専用 `proposal-confirm` に変更した。

### 影響範囲

- iOS版提示物選択
- iOS版送信確認
- iOS版打診完了後の導線

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリで関係図 → 提示物の選択 → 待ち合わせ → 送信確認へ進む、の順に進み、専用確認画面と完了演出が表示されることを確認

### 関連ファイル

- `mobile/app/proposal-confirm.tsx`
- `mobile/app/proposal-select.tsx`

### セルフレビュー結果

- ✅ 汎用プレビューではなく、打診送信前の確認に特化したネイティブ画面へ置き換えた
- ✅ Web版の送信確認で重要な交換内容・交換できる候補・任意メッセージ・スケジュール共有・送信後導線をiOS版に反映した
- ✅ まだ実送信APIには接続していない。現時点ではネイティブUIと遷移確認の土台
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.91：iOS関係図の横スワイプ遷移を追加

### 背景・問題意識

Apple Developer Program の登録反映待ちで実機 Development Build が一時停止している間も、iOS版の実装を進めることにした。

直近の指摘では、ホームのマッチングパネルをタップした後の画面について「WEB版と見た目も機能も再現すること」が重視されている。Web版 `MatchDetailModal` には、関係図画面間をiPhoneのホーム画面のように横スワイプで移動する体験があるため、iOS版にも同じ方向性の操作を入れる。

### 変更内容

#### `mobile/src/data/homeMatches.ts`
- ホームのマッチ候補データを `mobile/app/(tabs)/index.tsx` から分離した。
- `MATCH_SECTIONS`、候補型、候補のフラット化、前後候補取得、マッチ詳細遷移パラメータ生成を共通化した。

#### `mobile/app/(tabs)/index.tsx`
- ホーム画面は共通データ `MATCH_SECTIONS` を参照するように変更した。
- マッチカード押下時に `candidateId` を含めて `match-detail` へ遷移するようにした。

#### `mobile/app/match-detail.tsx`
- `candidateId` から現在のマッチ候補を特定し、左右の隣接候補を取得するようにした。
- `PanResponder` と `Animated.Value` を使い、関係図画面を指の横移動に追従させるようにした。
- 一定距離または速度を超えたスワイプで、前後のマッチ詳細へ切り替えるようにした。
- スワイプ中に左右の隣接画面プレビューを表示し、ページが横に続いている感覚を出した。
- 候補切り替え時には選択状態・OR譲の選択・wishポップアップを現在候補に合わせてリセットするようにした。

#### `mobile/app.json`
- EAS初回設定で付与された `extra.eas.projectId` を反映した。
- iOSの暗号利用確認に対応する `ITSAppUsesNonExemptEncryption: false` を反映した。

### 影響範囲

- iOS版ホームのマッチカード押下後
- iOS版関係図画面
- Development Build / EAS Build 設定

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- iOSアプリでホームのマッチカードを押し、関係図画面を左右にスワイプして隣の候補へ移動できることを確認

### 関連ファイル

- `mobile/src/data/homeMatches.ts`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/match-detail.tsx`
- `mobile/app.json`

### セルフレビュー結果

- ✅ ホームと関係図で同じ候補順を参照するようにし、隣接マッチへの移動がデータ的にずれないようにした
- ✅ Web版の横スワイプ関係図に近い、指追従・隣接プレビュー・スワイプ確定後のページ切替をiOS版へ追加した
- ✅ 新しい正式用語・状態名・DBカラムは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.90：iOS Development Build設定を追加

### 背景・問題意識

オーナーから、Expo Goで毎回QRを読み込むレビュー運用が面倒なので、もっと簡単に確認できる方法にしたいという相談があった。

iOS版のレビュー頻度が上がってきているため、Expo Go前提ではなく、iPhoneにMegrum専用の開発版アプリを入れて、ホーム画面のMegrumアイコンから開ける運用に移行できるようにする。

### 変更内容

#### `mobile/package.json`
- `expo-dev-client` を追加した。
- `start:dev` を追加し、Development Build用のMetroを起動できるようにした。
- `build:ios:dev` / `build:ios:sim` を追加した。

#### `mobile/package-lock.json`
- `expo-dev-client` の依存解決を反映した。

#### `mobile/eas.json`
- EAS Build用の設定を追加した。
- `development` profile は実機iPhone向けのDevelopment Buildにした。
- `development-simulator` profile はiOS Simulator向けにした。
- `preview` / `production` profile も将来用に用意した。

#### `notes/21_ios_review_guide.md`
- Expo GoレビューとDevelopment Buildレビューを分けて記載した。
- 初回セットアップ、開発版アプリのインストール、普段のレビューコマンドを追加した。
- 実機iPhoneのEAS Development BuildではApple Developer accountが必要なことを明記した。

### 影響範囲

- iOS版レビュー運用
- Expo GoからDevelopment Buildへの移行準備
- EAS Buildの初回設定

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- `mobile/package-lock.json` に `expo-dev-client` が反映されていることを確認

### 関連ファイル

- `mobile/package.json`
- `mobile/package-lock.json`
- `mobile/eas.json`
- `notes/21_ios_review_guide.md`

### セルフレビュー結果

- ✅ Megrum専用の開発版アプリを作るための `expo-dev-client` とEAS profileを追加した
- ✅ Expo Go運用とDevelopment Build運用の違いをレビュー手順に追記した
- ✅ 実機iPhoneにはApple Developer accountが必要な点を明記した
- ✅ UI・状態遷移・DBスキーマには影響しないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.89：iOSマッチ詳細をWeb版関係図へ寄せ直し

### 背景・問題意識

オーナーから「ホームのマッチングパネルをタップした後の画面がWEB版と全然違う。見た目も機能も再現することを必ず達成してほしい」と指摘があった。

iter154.87 の iOS マッチ詳細は、関係図の雰囲気を持つ仮プレビューだったが、Web版の `MatchDetailModal` が持つ構造・操作を再現できていなかった。そこで前回実装を作り直し、Web版の関係図モーダルを基準に、iOS版でも同じ情報構造と主要操作を確認できる画面へ差し替える。

### 変更内容

#### `mobile/app/match-detail.tsx`
- 既存の簡易マッチ詳細を撤回し、Web版 `MatchDetailModal` に沿う全画面の関係図UIへ差し替えた。
- ヘッダーを `関係図` / `@相手とのマッチ詳細` / 閉じるボタンの構成にした。
- 個別募集マッチでは `あなたの個別募集` と `@相手の個別募集` セクションを表示するようにした。
- 各セクション内はWeb版と同じく、左に `@相手 が譲るもの`、右に `あなた が譲るもの` を置く2カラム構成にした。
- listing の `個別募集N（選択肢 X 件）`、定価交換pill、AND/OR選択肢、wish行、候補数、選択中候補のインライン表示を追加した。
- 候補がないwishは `条件外の選択肢` アーカイブに折りたたむようにした。
- 譲がOR条件の場合、タップで対象を選択でき、選択中は紫リングとチェックを表示するようにした。
- wish行をタップするとWeb版同様の候補ポップアップを表示し、候補をタップして選択/解除できるようにした。
- 選択中の候補を集計し、画面下部に `リセット` と `打診に進む（n件）→` を表示するようにした。
- 通常の譲×wishマッチではWeb版の `SimpleRelationPanel` に近い `譲 × wish の関係` パネルと `この内容で打診へ →` フッターを表示するようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホームのマッチカードから `tag` を遷移先へ渡すようにした。
- iOS側の関係図で、双方条件 / 自分条件 / 相手条件 / 通常マッチを出し分けるために使う。

### 影響範囲

- iOS版ホームのマッチカード押下後
- iOS版関係図画面
- iOS版提示物選択へ進む前の選択操作

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goでホームのマッチカードを押し、以下を確認：
  - ヘッダーが `関係図` になっている
  - 個別募集マッチでは `あなたの個別募集` / `@相手の個別募集` がWeb版と同じ文法で表示される
  - wish行タップで候補ポップアップが開き、候補を選べる
  - 選択後に下部の `打診に進む（n件）→` が表示される
  - 通常マッチでは `譲 × wish の関係` パネルが表示される

### 関連ファイル

- `mobile/app/match-detail.tsx`
- `mobile/app/(tabs)/index.tsx`
- `web/src/components/home/MatchDetailModal.tsx`（再現元）

### セルフレビュー結果

- ✅ Web版 `MatchDetailModal` の主要構造（関係図ヘッダー、section group、listing tree、HaveList、OptionList、WishPopup、GlobalSummary、footer）をiOS版に反映した
- ✅ まだ実データ・実画像・隣接マッチへのスワイプ移動は未接続。今回の目的は、ホームカード押下後画面の見た目と主要操作をWeb版の文法に揃えること
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.88：iOS提示物選択の土台を追加

### 背景・問題意識

ホームのマッチ詳細から次に進む先として、提示物の選択画面が必要になった。

Web版では「関係図経由で提示物の選択へ進む場合は、私が出す/受け取るを経由せず待ち合わせタブへ進む」「wish一致という分かりにくい表記は使わない」「上部の案内文は出さない」というFBが確定している。iOS版でもこの方針を守りながら、まずレビューできるネイティブ土台を作る。

### 変更内容

#### `mobile/app/proposal-select.tsx`
- iOS版の提示物選択画面を追加した。
- `私が出す` / `受け取る` / `待ち合わせ` の3タブ構成にした。
- 関係図/マッチ詳細経由では `tab=meetup` を受け取り、待ち合わせタブを初期表示できるようにした。
- `私が出す` では `相手がほしいものかも？`、`受け取る` では `私がほしいものかも？` の表記を使った。
- 各タブ上部の説明文は置かず、カードとタブだけで進める構成にした。
- 待ち合わせタブには5日表示のカレンダープレビューを置き、候補時間をタップで切り替えられるようにした。
- 待ち合わせタブから送信確認プレビューへ進めるようにした。

#### `mobile/app/match-detail.tsx`
- `提示物の選択へ進む` ボタンの遷移先を `proposal-select` に変更した。
- マッチ詳細から進む場合は待ち合わせタブを初期表示するようにした。

### 影響範囲

- iOS版マッチ詳細から提示物選択へ進む導線
- iOS版提示物選択 / 待ち合わせタブの初期プレビュー

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goでホームのマッチカード → マッチ詳細 → `提示物の選択へ進む` を押し、待ち合わせタブが初期表示されることを確認
- `私が出す` / `受け取る` タブに説明文がなく、wish一致ではない文言になっていることを確認

### 関連ファイル

- `mobile/app/proposal-select.tsx`
- `mobile/app/match-detail.tsx`

### セルフレビュー結果

- ✅ 関係図/マッチ詳細経由では待ち合わせタブへ直接進む方針をiOS版に反映した
- ✅ `wish一致` 表記を使わず、画面ごとに意味が伝わる文言へ置き換えた
- ✅ 待ち合わせカレンダーはまだドラッグ操作・場所設定・送信確認の地図表示までは未実装。今回はネイティブ画面遷移とタブ構成の土台
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.87：iOSマッチ詳細プレビューを関係図寄りに分離

### 背景・問題意識

iter154.86でホームのマッチカードから右スライド遷移する土台はできたが、汎用詳細画面では、オーナーが重視している「選んだグッズが目立つ」「関係図で交換可能性を理解する」「交換できなさそうな候補は最初から見せすぎない」という体験を確認できない。

そこで、ホームのマッチカード押下先だけを専用のマッチ詳細プレビューへ分離し、今後の関係図/提示物選択フローにつながる見え方を先に作る。

### 変更内容

#### `mobile/app/match-detail.tsx`
- ホームのマッチカード押下専用の詳細プレビュー画面を追加した。
- 選んだグッズを画面上部で大きく表示し、優先度に応じて枠の派手さを変えるようにした。
- 現地交換できる候補は控えめなライブ表示を付けた。
- `相手の譲` と `私が出す` を左右に並べ、中央の線で関係図らしく結ばれる構成にした。
- 選んだグッズは候補内でも枠を強調した。
- 交換できなさそうな候補は初期状態では隠し、`+` ボタンで展開できるようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホームのマッチカード押下先を汎用 `preview-detail` から `match-detail` へ変更した。
- 選んだグッズのタイトル、キャラ×種別、メンバー記号、色、優先度、現地交換可否を遷移先に渡すようにした。

### 影響範囲

- iOS版ホームのマッチカード押下後
- 関係図/提示物選択へ進む前のiOSプレビュー

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goでホームのマッチカードを押し、選んだグッズの強調、左右の関係図、条件外候補の折りたたみを確認

### 関連ファイル

- `mobile/app/match-detail.tsx`
- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ ホームカード押下後を汎用詳細から専用のマッチ詳細プレビューへ分離した
- ✅ 選択グッズの強調と、条件外候補の初期折りたたみをiOS版でも確認できる状態にした
- ✅ まだ実データ・本物の関係図ロジック・提示物選択画面は未接続
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.86：iOS右スライド詳細プレビューを接続

### 背景・問題意識

オーナーから、iOS版でもWeb版で重視してきた「画面右からひゅんっと入る遷移」を、ホームのマッチカード、取引一覧、プロフ導線に適用したいという要望があった。

iter154.80〜154.85で各タブの一覧UIは触れる状態になったが、カードや行を押した先が下部シートや未接続のままだと、iOSアプリとしての画面移動の気持ちよさを確認できない。そこで、本格的な各詳細画面を作る前段として、共通の詳細プレビュー画面へ右スライドで遷移する土台を先に用意した。

### 変更内容

#### `mobile/app/preview-detail.tsx`
- 共通の詳細プレビュー画面を追加した。
- Stackの `slide_from_right` を活かし、戻るボタン付きの詳細画面として表示できるようにした。
- `match` / `transaction` / `profile` の種別ごとに説明カードの文言を切り替えるようにした。

#### `mobile/app/(tabs)/index.tsx`
- ホームのマッチカードをタップした時、選んだグッズ名・キャラ×種別・タグ情報を持って詳細プレビューへ遷移するようにした。
- これにより、今後の関係図/提示物選択への右スライド遷移を確認できる状態にした。

#### `mobile/app/(tabs)/transactions.tsx`
- 取引カードタップ時の下部シートを廃止し、取引詳細プレビューへ右スライド遷移するようにした。
- 要対応/相手待ち、ステータス、時間、場所を遷移先に渡すようにした。

#### `mobile/app/(tabs)/profile.tsx`
- プロフィール編集、推し設定、スケジュール、通知、ヘルプの行タップを下部シートから右スライド遷移へ変更した。
- `設定` / `アカウント削除` を追加しない方針は維持した。

### 影響範囲

- iOS版ホームのマッチカード遷移
- iOS版取引一覧カード遷移
- iOS版プロフの各導線
- 今後の個別詳細画面実装の共通入口

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goでホームのカード、取引カード、プロフの各行を押し、右から詳細画面が表示されて戻れることを確認

### 関連ファイル

- `mobile/app/preview-detail.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/transactions.tsx`
- `mobile/app/(tabs)/profile.tsx`

### セルフレビュー結果

- ✅ 既存のRoot Stack設定 `slide_from_right` を活かし、主要導線を右スライド遷移で確認できるようにした
- ✅ 詳細画面本体はまだプレビュー段階。関係図、提示物選択、取引チャット、推し設定本体は次以降で個別実装する
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.85：iOSプロフ画面をアイデンティティハブ化

### 背景・問題意識

オーナーから、区切りごとにレビュー用コマンドを共有しつつ、止まらず開発を進めてほしいという指示があった。

iOS版ではホーム、在庫、Wish、取引一覧がプレビュー可能になったため、残っていたプロフタブも土台カードのままではなく、Web版で固まっている情報設計に合わせる必要があった。特に過去FBで「設定は不要」「アカウント削除は消す」「アイデンティティにスケジュールを含める」が確定しているため、iOS版でもその前提を崩さない構成にする。

### 変更内容

#### `mobile/app/(tabs)/profile.tsx`
- 土台カードを廃止し、プロフタブをネイティブUIで実装した。
- 画面上部に本人サマリ、ハンドル、表示名、エリア、成立数、評価、現地モード状態をまとめた。
- 「アイデンティティ」に `プロフィール編集` / `推し設定` / `スケジュール` の3導線を置いた。
- 「推し」セクションを追加し、登録済み推しの概要が見えるカードを置いた。
- 「通知・サポート」に `通知設定` / `ヘルプ・FAQ` を置いた。
- `設定` と `アカウント削除` の導線は追加しない構成にした。
- 各行タップ時は下部アクションシートを出し、今後の右スライド詳細遷移へつなげる仮導線にした。

### 影響範囲

- iOS版プロフタブ
- プロフィール編集 / 推し設定 / スケジュール / 通知 / ヘルプの今後の詳細画面導線

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goで「プロフ」タブを開き、本人サマリ、アイデンティティ、推し、通知・サポート、行タップ時の下部シートを確認

### 関連ファイル

- `mobile/app/(tabs)/profile.tsx`

### セルフレビュー結果

- ✅ Web版で確定済みの「設定なし」「アカウント削除なし」「スケジュールはアイデンティティ内」をiOS版にも反映した
- ✅ まだ実データ・右スライド詳細画面は未接続。今回はプロフタブの情報設計と導線プレビュー段階
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.84：iOS取引一覧をチケット型で実装

### 背景・問題意識

オーナーから、区切りごとにレビュー用コマンドを共有しつつ、止まらず開発を進めてほしいという指示があった。

iOS版ではホーム、下部タブ、在庫/Wishがプレビュー可能になったため、次に主要導線である取引一覧をネイティブ画面化する。Web版で確定した「打診中 / 進行中 / 完了」「打診中の要対応 / 相手待ち」「コンパクトなチケット型パネル」の情報設計をiOSでも確認できる状態にする必要があった。

### 変更内容

#### `mobile/app/(tabs)/transactions.tsx`
- 土台カードを廃止し、取引一覧をネイティブUIで実装した。
- 上位タブを「打診中」「進行中」「完了」にした。
- 打診中タブ内に「要対応」「相手待ち」の2分割タブを追加した。
- 取引カードを、相手ID、送信/受信、状態、受け取る/私が出す、時間、場所を短く見られるチケット型にした。
- 要対応カードは左端アクセントと赤系の状態pillで優先度が分かるようにした。
- 進行中カードと完了カードも同じ文法で表示し、取引予定/相違申告/完了/キャンセルを見分けられるようにした。
- カード表示時はspringで薄い状態からふわっと出るようにした。
- カードタップ時は下部アクションシートを表示するようにした。

### 影響範囲

- iOS版取引タブ
- 打診中 / 進行中 / 完了の一覧プレビュー
- 取引カードの今後の詳細遷移導線

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goで「取引」タブを開き、打診中/進行中/完了、要対応/相手待ち、カードタップを確認

### 関連ファイル

- `mobile/app/(tabs)/transactions.tsx`

### セルフレビュー結果

- ✅ Web版で確定した取引一覧のタブ構成と要対応/相手待ち分類をiOS版に反映した
- ✅ まだ実データ・詳細画面遷移は未接続。今回は一覧UIのプレビュー段階
- ✅ 既存の状態名に沿って `sent` / `negotiating` / `agreement_one_side` / `agreed` / `completed` 等を使った
- ✅ 新しいDBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.83：iOS在庫/Wishのネイティブ画面を追加

### 背景・問題意識

iOS版ホームと下部タブの土台ができたため、次にレビュー対象として重要な「マイ在庫」と「Wish」をネイティブ画面化する。

Web版では在庫/Wishともに、列数切替、下から出るアクション、右下の追加ボタン、Wish内の個別募集タブが重要な操作になっている。iOS版でも同じ構成を先にプレビュー用データで触れる状態にして、今後の実データ連携や細かいアニメーション調整へ進める必要があった。

### 変更内容

#### `mobile/src/components/GoodsGrid.tsx`
- iOS版の在庫/Wishで共用する `GoodsGrid` を追加した。
- `ColumnSwitcher`（3/4/5列切替）、`SectionTabs`、`BottomOptionSheet`、`FloatingAddButton`、`FilterChips` を追加した。
- グッズカードは表示時にspringでふわっと出るようにした。
- アクションは画面下から出るシートで選ぶ形にした。

#### `mobile/app/(tabs)/inventory.tsx`
- 土台カードを廃止し、マイ在庫画面をネイティブUIで実装した。
- 「譲る候補」「自分用キープ」「過去に譲った」の3タブを追加した。
- 3/4/5列の列数切替を追加した。
- グッズタップ時に下部アクションシートを表示するようにした。
- 「譲る候補」では `編集する` / `自分キープへ` / `削除` / `閉じる` の順で表示するようにした。
- 「自分用キープ」では `自分キープへ` ではなく `譲る候補へ` を表示するようにした。
- 「過去に譲った」は編集・削除できない読み取り扱いにした。
- 右下の追加ボタンからプレビュー用カードを追加できるようにした。

#### `mobile/app/(tabs)/wishes.tsx`
- 土台カードを廃止し、Wish画面をネイティブUIで実装した。
- `Wish` / `個別募集` の2タブを追加した。
- Wishタブでは列数切替、フィルタチップ、グッズグリッド、下部アクションシートを追加した。
- 個別募集タブでは、譲/求の関係が見えるカードを追加した。
- 右下の追加ボタンをタブに応じて Wish / 個別募集の追加プレビューとして動かすようにした。

### 影響範囲

- iOS版マイ在庫タブ
- iOS版Wishタブ
- iOS版の共通グッズグリッド/下部アクションUI

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goで「在庫」「Wish」タブを開き、列数切替・カードタップ・下部シート・右下追加ボタンを確認

### 関連ファイル

- `mobile/src/components/GoodsGrid.tsx`
- `mobile/app/(tabs)/inventory.tsx`
- `mobile/app/(tabs)/wishes.tsx`

### セルフレビュー結果

- ✅ Web版で確定している在庫/Wishの主要操作をiOS版のプレビューとして触れる状態にした
- ✅ 画像・DB・削除API連携はまだ未接続。次以降でSupabaseデータに差し替える
- ✅ 在庫の「過去に譲った」は編集/削除できない扱いにした
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.82：iOS下部タブをガラス調カスタムバーへ刷新

### 背景・問題意識

iOS版ホームの操作感改善に続き、全画面で常に目に入る下部タブもExpo標準の表示からiOSアプリらしい質感へ寄せる必要があった。

Web版では下部フッターの見た目・切り替え感を重視してきたため、iOS版でも今後の各画面レビュー前に、共通ナビゲーションの土台を先に整える。

### 変更内容

#### `mobile/app/(tabs)/_layout.tsx`
- Expo Routerの標準tabBar表示をやめ、`LiquidTabBar` を追加した。
- 白い半透明のガラス調 pill を下部タブとして表示するようにした。
- 選択中の背景 indicator を `Animated.spring` でぬるっと移動させるようにした。
- 各タブの glyph / label を `TAB_CONFIG` に集約した。
- safe area inset を見て、iPhone下部に自然な余白が出るようにした。
- キーボード表示時はtabBarを隠す設定を維持した。

### 影響範囲

- iOS版の全タブ画面
- ホーム / 在庫 / Wish / 取引 / プロフの下部ナビゲーション

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goで各タブを切り替え、indicatorの移動とsafe area余白を確認

### 関連ファイル

- `mobile/app/(tabs)/_layout.tsx`

### セルフレビュー結果

- ✅ Expo標準のタブ表示から、iOS向けのガラス調カスタムタブへ置き換えた
- ✅ タブ切替時の選択背景はspringで移動し、即時ジャンプしない
- ✅ 画面個別ロジックやDBスキーマには触れていない
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.81：iOSホームのモード切替と横スクロール慣性を改善

### 背景・問題意識

オーナーから、iOS版ホームの細かい挙動は今後実装する理解でよいか確認があり、特に「最新のiOSの水のような切り替え感」と「マッチングパネル行をぐわっとスクロールした時に途中で止まらず流れる感じ」が例として挙がった。

iter154.80 のホームは構成確認用の第一弾だったため、次の区切りとして触り心地に直結するモード切替と横スクロール棚の慣性を先に磨くことにした。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 上部の小さい現地交換トグルを `Animated.spring` で滑るように変更した。
- 全国交換モード / 今すぐ現地交換モードの segmented control を `ModeSwitch` コンポーネント化した。
- segmented control の thumb を spring で移動させ、切り替え時に横方向へ少し伸びる pulse を追加した。
- thumb 内に光沢レイヤーと柔らかい blob を重ね、最新iOS系の水っぽい質感に近づけた。
- 横スクロール棚に `alwaysBounceHorizontal` / `bounces` / `decelerationRate="normal"` / `scrollEventThrottle` を明示し、snapせず慣性で流れる挙動へ寄せた。

### 影響範囲

- iOS版ホームタブ
- 現地交換モード切替の操作感
- マッチ棚の横スクロール操作感

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goでホームタブを開き、モード切替と横スクロール棚を操作する

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ モード切替が即時ジャンプではなく、spring/pulseで動く構造になった
- ✅ 横スクロール棚はsnap指定なしで、iOSの慣性スクロールを妨げない設定にした
- ✅ まだ本格的なhapticsやblur overlayは未導入。次以降の触り心地改善候補として残す
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.80：iOSホームのマッチ棚プレビューを実装

### 背景・問題意識

オーナーがExpo GoでiOS版の起動確認に成功し、「開発を進めてください」と指示した。

iOS版はまだ土台画面の状態だったため、最初にレビューしやすいホーム画面から着手する。Web版ホームで確定している「マッチしてるよ！」「交換できるかも」の二段構成、現地交換モードの上部導線、横スクロール棚、優先度による枠表現を、Supabase連携前のプレビュー用データで先に確認できる形にする必要があった。

### 変更内容

#### `mobile/app/(tabs)/index.tsx`
- 土台カードのホームを廃止し、iOSネイティブ向けのホームプレビューに差し替えた。
- 画面上部に検索・通知ボタン、場所表示、現地交換モードのトグルを配置した。
- 全国交換モード / 今すぐ現地交換モードの segmented control を追加した。
- 「マッチしてるよ！」「交換できるかも」の2セクションを追加し、キャラ × 種別ごとに横スクロール棚を表示するようにした。
- スマホ幅で約2.5枚のカードが見えるよう、カード幅を画面幅から算出するようにした。
- カードを右側から滑り込ませる初期表示アニメーションを追加した。
- 現地交換候補には控えめな紫の外側 aura を付け、候補優先度（双方条件 / 一方条件 / 通常 wish 合致）で枠と影の強さを変えた。
- タグをカード下部に重ねて表示し、長いタグは `...` で省略するようにした。

### 影響範囲

- iOS版ホームタブ
- Expo Goでの画面レビュー
- Supabase接続前のプレビューモード表示

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`
- Expo Goで「画面だけプレビューする」→ ホームタブを確認

### 関連ファイル

- `mobile/app/(tabs)/index.tsx`

### セルフレビュー結果

- ✅ 既存Webホームの二段構成と横スクロール棚の考え方をiOS版に移植した
- ✅ 以前のFBに合わせ、上部の大きい現地交換バナーや「Wishに届いた譲」表記は入れていない
- ✅ まだ実データ連携前のため、候補データはレビュー用モックとして実装した
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.79：iOS認証リダイレクトをlayout単位へ移動

### 背景・問題意識

iter154.78 の修正後も、オーナーのExpo Go画面で `Attempted to navigate before mounting the Root Layout component` が再発した。

`RouteGuard` をRoot Layout配下に置いたまま `router.replace()` を実行する構成では、Expo RouterのRoot Layout初回renderと競合する可能性が残る。Root Layoutではnavigatorだけを確実に描画し、認証状態による遷移は各route group layoutが宣言的に `<Redirect />` を返す構造へ変更する必要があった。

### 変更内容

#### `mobile/app/_layout.tsx`
- `<RouteGuard />` を削除し、Root Layoutは `AuthProvider` と `<Stack />` だけを描画する構造にした。

#### `mobile/app/(tabs)/_layout.tsx`
- 未設定・未ログイン時は `<Redirect href="/login" />` を返すようにした。
- 認証確認中は中央ローディングを表示するようにした。

#### `mobile/app/(auth)/_layout.tsx`
- プレビューモードまたはログイン済みの場合は `<Redirect href="/" />` を返すようにした。
- 認証確認中は中央ローディングを表示するようにした。

#### `mobile/src/auth/RouteGuard.tsx`
- Root Layout起動時エラーの原因になりうる命令的リダイレクトを廃止したため削除した。

### 影響範囲

- iOS版のExpo Go起動
- 未ログイン時のログイン画面遷移
- プレビューモードからタブ画面へ入る導線

### 確認方法

- `npm run typecheck`（`mobile/`）
- `npx expo config --type public`（`mobile/`）
- `git diff --check`

### 関連ファイル

- `mobile/app/_layout.tsx`
- `mobile/app/(tabs)/_layout.tsx`
- `mobile/app/(auth)/_layout.tsx`
- `mobile/src/auth/RouteGuard.tsx`

### セルフレビュー結果

- ✅ Root Layoutで命令的な `router.replace()` が走らない構造にした
- ✅ Expo Routerのroute group layoutで宣言的に `<Redirect />` を返す構成にした
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.78：iOS起動時のRoot Layout遷移エラーを修正

### 背景・問題意識

オーナーがExpo GoでiOS版を起動したところ、`Attempted to navigate before mounting the Root Layout component` というRender Errorが表示された。

原因は、`RouteGuard` がRoot Layoutのナビゲーター準備前に `router.replace("/login")` を実行していたこと。Expo RouterではRoot Layoutの初回renderでStack/Slotなどのnavigatorが先に描画されている必要があるため、リダイレクトはroot navigation stateが準備できるまで待たせる必要があった。

### 変更内容

#### `mobile/src/auth/RouteGuard.tsx`
- `useRootNavigationState()` を使い、root navigation state の `key` ができるまでリダイレクトしないようにした。

#### `mobile/app/_layout.tsx`
- `<Stack />` を先に描画し、その後に `<RouteGuard />` を置く順序へ変更した。

### 影響範囲

- iOS版のExpo Go起動
- 未ログイン時の `/login` リダイレクト
- プレビュー導線の初回表示

### 確認方法

- `npm run typecheck`
- `npx expo config --type public`（`mobile/`）
- `git diff --check`

### 関連ファイル

- `mobile/src/auth/RouteGuard.tsx`
- `mobile/app/_layout.tsx`

### セルフレビュー結果

- ✅ Root Layoutがnavigatorを先にrenderする構造にした
- ✅ リダイレクトはroot navigation state準備後にのみ実行するようにした
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.77：iOS Metroのmonorepo監視エラーを修正

### 背景・問題意識

オーナーがExpo GoでiOS版を確認しようとしたところ、`Could not connect to the server` が表示され、Mac側では `ENOENT: no such file or directory, watch '/.../Goods_exchange_platfform_Megrum/node_modules'` で Metro が落ちていた。

原因は、root `package.json` で npm workspaces を定義したことで Expo/Metro がリポジトリ直下を workspace root と認識し、存在しない root `node_modules` を watch 対象に含めていたこと。現状は `mobile/node_modules` に依存が入っているため、root `node_modules` が無くても起動できるよう Metro 設定で存在しない watch path を除外する必要があった。

### 変更内容

#### `mobile/metro.config.js`
- Expo の default Metro config を読み込んだうえで、存在しない `watchFolders` と `resolver.nodeModulesPaths` を除外するようにした。
- 将来 `@megrum/core` / `@megrum/design` / `@megrum/supabase` を iOS側から参照できるよう、`extraNodeModules` に package alias を追加した。

#### `notes/21_ios_review_guide.md`
- `Could not connect to the server` の場合は tunnel 起動へ切り替える手順を追加した。
- `ENOENT ... node_modules` エラーの原因と、最新版取得後の再起動手順を追加した。

### 影響範囲

- iOS版のExpo/Metro開発サーバ起動
- iOS画面レビュー手順
- 今後の共通パッケージ参照

### 確認方法

- `node -e "const config = require('./mobile/metro.config'); console.log(config.watchFolders); console.log(config.resolver.nodeModulesPaths)"`
- `npm run typecheck`
- `git diff --check`

### 関連ファイル

- `mobile/metro.config.js`
- `notes/21_ios_review_guide.md`

### セルフレビュー結果

- ✅ root `node_modules` が無い環境でも Metro config 上は存在しない watch path を持たない
- ✅ 既存Web実装には触れていない
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / `git diff --check` 通過

---

## イテレーション154.76：iOS認証骨格とレビュー手順を追加

### 背景・問題意識

オーナーから、iOSアプリ版の画面をレビューできる段階になったら開き方も案内してほしい、そのうえで次に進めてほしいという依頼があった。

iOS版は今後Web版と同じSupabase基盤に接続するため、画面量産前にログイン状態、Supabase未設定時の案内、ログイン済みタブ表示の骨格を先に作る必要がある。また、オーナーが都度レビューしやすいように、Expo Go / iOS Simulator での開き方をドキュメント化しておくことにした。

### 変更内容

#### `mobile/src/auth/`
- `AuthProvider` を追加し、Supabase Auth の session / user / signIn / signUp / signOut をアプリ全体で参照できるようにした。
- `RouteGuard` を追加し、未ログイン時は `/login`、ログイン済み時はタブ画面へ寄せる導線を作った。

#### `mobile/app/(auth)/`
- ログイン画面を追加した。
- Supabase環境変数が未設定の場合は、設定待ちの案内を表示するようにした。
- Supabase環境変数が未設定でも「画面だけプレビューする」からタブ画面を確認できるようにした。
- 環境変数が設定されている場合は、ログイン/新規登録フォームを表示するようにした。

#### `mobile/app/(tabs)/`
- ホーム画面でログイン状態とユーザーemailを表示するようにした。
- プロフィール画面にログイン状態とログアウトボタンを追加した。

#### `mobile/src/components/`
- `PrimaryButton` と `TextField` を追加し、iOS版のフォーム/CTAの最小共通部品を用意した。

#### `notes/21_ios_review_guide.md`
- iOS画面レビュー手順を新規作成した。
- Expo Go / iOS Simulator / Supabase環境変数の扱いを整理した。

#### `README.md` / `notes/20_ios_app_roadmap.md`
- iOSレビュー手順への導線を追加した。

### 影響範囲

- iOSアプリ版のログイン前後導線
- iOS画面レビュー手順
- 今後のSupabase連携PoC

### 確認方法

- `npm run typecheck`
- `npx expo config --type public`（`mobile/`）
- `git diff --check`

### 関連ファイル

- `mobile/src/auth/AuthProvider.tsx`
- `mobile/src/auth/RouteGuard.tsx`
- `mobile/app/(auth)/login.tsx`
- `mobile/app/(tabs)/index.tsx`
- `mobile/app/(tabs)/profile.tsx`
- `notes/21_ios_review_guide.md`

### セルフレビュー結果

- ✅ Web側の既存実装には触れず、iOS側の認証骨格だけを追加した
- ✅ Supabase未設定でもレビュー画面が崩れず、設定待ちとして見える
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `typecheck` / Expo config 確認 / `git diff --check` 通過

---

## イテレーション154.75：iOSアプリ基盤を追加

### 背景・問題意識

オーナーから、Webアプリ版と機能連動する iOS ネイティブアプリを React Native / Expo 方針で進めたいという相談と依頼があった。

Megrum は地図、カレンダー、Push通知、カメラ、横スワイプ、取引チャットなど iOS 固有の操作感が重要になる。一方で Web と iOS の状態判定やマッチング判定がズレると、在庫残数や打診ステータスで重大な不整合が起きる。そこで、先に monorepo と共通パッケージの土台を作り、iOS側は Expo Router ベースで立ち上げることにした。

### 変更内容

#### `mobile/`
- Expo / React Native / TypeScript の iOS アプリ scaffold を追加した。
- Expo Router を導入し、ホーム/在庫/Wish/取引/プロフのタブ画面を作成した。
- Supabase Auth 連携用のクライアント初期化ファイルを追加した。
- Expo Notifications と `react-native-maps` を導入し、Push通知とApple Maps利用に進める依存関係を追加した。
- `mobile/.env.example` を追加し、iOS側の公開環境変数を明示した。

#### `packages/core/`
- Web/iOS共通化の第一歩として、proposal の pending 判定と詳細遷移先判定を切り出した。
- マッチ強度の優先度判定の土台を追加した。

#### `packages/design/`
- ブランドカラー、余白、角丸、影の共通トークンを追加した。

#### `packages/supabase/`
- Supabase公開環境変数の型と検証補助を追加した。

#### `package.json` / `.nvmrc`
- root を npm workspace 化し、`web/`、`mobile/`、`packages/*` を同一リポジトリで管理する土台を作った。
- Expo/RN の要求に合わせて Node.js `20.19.4` を `.nvmrc` に明示した。

#### `notes/20_ios_app_roadmap.md`
- iOSアプリ化の方針、リポジトリ構成、PoC範囲、実装順、オーナー依頼事項を新規整理した。

#### `notes/14_implementation_phases.md`
- モバイル技術スタックを React Native + Expo 方針に更新した。
- Post-MVP の「アプリ化」記述を、iOSネイティブ強化に差し替えた。

#### `notes/10_glossary.md`
- `Webアプリ版` / `iOSアプリ版` / `共通ロジック` を用語として追加した。

### 影響範囲

- iOSアプリ開発の開始点
- Web/iOS共通ロジックの置き場
- 今後のCI/CD、EAS、TestFlight運用
- 実装フェーズ計画と用語管理

### 確認方法

- `npm run typecheck`（`mobile/`）
- `./mobile/node_modules/.bin/tsc -p packages/core/tsconfig.json --noEmit`
- `./mobile/node_modules/.bin/tsc -p packages/design/tsconfig.json --noEmit`
- `./mobile/node_modules/.bin/tsc -p packages/supabase/tsconfig.json --noEmit`
- `npx expo config --type public`（`mobile/`）
- `git diff --check`

### 関連ファイル

- `mobile/`
- `packages/core/`
- `packages/design/`
- `packages/supabase/`
- `package.json`
- `.nvmrc`
- `notes/20_ios_app_roadmap.md`
- `notes/14_implementation_phases.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 既存Webアプリの実装ファイルには触れず、iOS版の基盤を別ディレクトリに追加した
- ✅ Web/iOSでズレやすい pending 判定と遷移先判定を `packages/core/` に置き始めた
- ✅ 新しい正式用語は `notes/10_glossary.md` に追加した
- ✅ 状態の追加・削除・名称変更はないため `notes/09_state_machines.md` は更新不要
- ✅ DBスキーマ変更はないため `notes/05_data_model.md` は更新不要
- ⚠️ 最新Expo/RNは Node.js `>=20.19.4` を要求するが、現在のローカルは `v20.11.1`。`.nvmrc` に要求バージョンを明示済み
- ✅ `mobile` / `packages/*` の typecheck、Expo config 確認、`git diff --check` 通過

---

## イテレーション154.74：相手待ち打診の遷移先を修正

### 背景・問題意識

オーナーから、打診一覧の「打診中 > 相手待ち」にあるパネルを押すと、まだ 404 になるという報告があった。

前回 iter154.73 では `/proposals/[id]` の取得耐性を上げたが、相手待ちのうち「自分が送った未応答打診」は受信者が承諾・拒否するための `/proposals/[id]` に飛ぶべきではない。送信者にとっては「返事待ちの詳細」を見る導線なので、取引詳細側で開けるようにする必要があった。

### 変更内容

#### `web/src/app/transactions/TransactionsView.tsx`
- 打診中カードのリンク先を整理し、`sent` かつ `received` の未応答打診だけ `/proposals/[id]` へ残した。
- `sent` かつ `sent` の相手待ち打診、`negotiating`、`agreement_one_side` は `/transactions/[id]` へ遷移するようにした。

#### `web/src/app/transactions/[id]/page.tsx`
- `/transactions/[id]` で、送信者本人の `sent` 打診を「相手待ち詳細」として表示できるようにした。
- 受信者の `sent` 打診は、今まで通り応答用の `/proposals/[id]` へ redirect するように残した。

#### `web/src/app/transactions/[id]/ChatView.tsx`
- 送信者本人が `sent` 打診を開いた場合は、合意ボタンを押せない「相手の返信待ち」表示にした。
- 同ファイルの既存 `Date.now()` レンダー呼び出しを、初期 render 時刻の state 経由にして ESLint の purity ルールに合わせた。

### 影響範囲

- 取引一覧の「打診中 > 相手待ち」カード
- 送信者本人が開く未応答打診の詳細表示
- 受信者が開く未応答打診の承諾・拒否導線

### 確認方法

- `npx eslint 'src/app/transactions/TransactionsView.tsx' 'src/app/transactions/[id]/page.tsx' 'src/app/transactions/[id]/ChatView.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/transactions/TransactionsView.tsx`
- `web/src/app/transactions/[id]/page.tsx`
- `web/src/app/transactions/[id]/ChatView.tsx`

### セルフレビュー結果

- ✅ 相手待ちの送信済み打診だけ、受信者向け詳細ではなく送信者向け詳細へ開くようにした
- ✅ 受信者側の未応答打診は、承諾・拒否・反対提案ができる `/proposals/[id]` のまま維持した
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.73：打診中カード詳細の404を抑制

### 背景・問題意識

オーナーから、取引一覧の打診中カードをクリックすると 404 になるという報告があった。

取引一覧には対象の打診が表示されているため、打診自体は取得できている。一方で打診詳細 `/proposals/[id]` は、詳細表示用に追加カラムをまとめて select しており、DB の schema cache や一部環境のカラム反映差分で select 全体が失敗すると `row=null` と同じ扱いになり 404 へ落ちる可能性があった。ユーザーにとっては「一覧にあるのに詳細だけ存在しない」見え方になるため、詳細ページ側をカラム差分に強くする必要があった。

### 変更内容

#### `web/src/app/proposals/[id]/page.tsx`
- `meetup_candidates` 専用だった schema cache エラー判定を、`proposals` の不足カラム名を抽出する汎用処理へ変更した。
- 打診詳細の select をフィールド配列から組み立て、不足カラムが schema cache エラーになった場合はそのカラムだけ外して再試行するようにした。
- `meetup_candidates` / `rejected_template` / `extension_count` / `meetup_lat` / `meetup_lng` は、取得できない場合でも安全なデフォルト値を入れるようにした。

### 影響範囲

- `/transactions` の打診中カードから開く `/proposals/[id]`
- 打診詳細画面の初期データ取得

### 確認方法

- `npx eslint 'src/app/proposals/[id]/page.tsx' 'src/app/transactions/TransactionsView.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/proposals/[id]/page.tsx`

### セルフレビュー結果

- ✅ 取引一覧カードの見た目やリンク先の情報設計は変えず、詳細ページ側の取得耐性だけを上げた
- ✅ 一覧で取得できている proposal が、詳細ページの追加カラム差分だけで 404 になりにくい
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.72：フッター遷移インジケータを中央配置

### 背景・問題意識

オーナーから、フッター遷移時の小さなインジケータはフッター付近ではなく、画面の中央に表示してほしいという要望があった。

読み込み中の視線を画面中央に集めることで、「画面が準備中である」ことがより自然に伝わるため、既存のガラス幕は維持しつつインジケータ位置だけを調整した。

### 変更内容

#### `web/src/app/globals.css`
- `body.megrum-bottom-nav-loading::after` のインジケータ位置を、フッター上部から画面中央へ変更した。
- 中央配置に合わせて登場アニメーションの `transform` を `translate(-50%, -50%)` 基準に調整した。
- 回転は `rotate` プロパティのまま維持し、中央からずれずに回るようにした。

### 影響範囲

- ボトムナビ経由のページ遷移ローディング表示

### 確認方法

- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ インジケータの位置だけを変更し、フッターの仮アクティブ移動や遷移ロジックには触れていない
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `git diff --check` / `npm run build` 通過

---

## イテレーション154.71：フッター遷移を即時反応型に調整

### 背景・問題意識

オーナーから、フッターを押した時に選択箇所はぬるっと先に変わってほしいが、画面自体にはローディングが必要になるはずなので、読み込み中はローディング画面を見せて完了後に表示する形にできないかという要望があった。

フッターはタップ直後の反応が遅いと「押せていない」感覚になりやすい。一方で、ページのデータ取得を待たずに画面だけ切り替えたように見せると内容が追いつかない。そこで、フッターの選択状態だけを先行して動かし、画面側はガラスのローディング幕で読み込み中を明示する設計にした。

### 変更内容

#### `web/src/components/home/BottomNav.tsx`
- フッターリンク押下時に、遷移完了を待たず `optimisticTarget` で押した先を仮アクティブ表示するようにした。
- アクティブ判定を「実際の現在地」と「見た目用の現在地」に分離し、`aria-current` は実際の現在地だけに残すようにした。
- フッター遷移開始時に `body.megrum-bottom-nav-loading` を付け、遷移完了前の画面ローディング幕を出せるようにした。

#### `web/src/components/home/BottomNavTransitionBridge.tsx`
- ルート変更後に `megrum-bottom-nav-loading` を消し、次ページのフェード/リフトインへ自然につなげるようにした。

#### `web/src/app/globals.css`
- `body.megrum-bottom-nav-loading::before` で画面全体に薄いガラス幕を表示するようにした。
- `body.megrum-bottom-nav-loading::after` でフッター上部に小さな回転インジケータを表示するようにした。
- `prefers-reduced-motion` ではローディング幕/遷移アニメーションを止めるようにした。

### 影響範囲

- ボトムナビ経由のホーム/在庫/wish/取引/プロフ遷移
- フッタータップ直後のアクティブ表示
- ページ読み込み中の共通ローディング表示

### 確認方法

- `npx eslint 'src/components/home/BottomNav.tsx' 'src/components/home/BottomNavTransitionBridge.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/home/BottomNav.tsx`
- `web/src/components/home/BottomNavTransitionBridge.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ フッターの見た目だけ先行して動かし、読み込み中の画面はガラス幕で受ける設計にした
- ✅ `aria-current` は実際の現在ページにのみ付けているため、仮アクティブ表示でアクセシビリティ上の現在地がずれない
- ✅ ローディング幕は `body` クラス限定で、詳細画面の右スライドや削除アニメーションとは分離している
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.70：ホーム検索をフッター左下へ移動

### 背景・問題意識

オーナーから、ホーム画面左上の検索アイコンを、フッター左下に固定表示される丸い虫眼鏡アイコンへ移したいという要望があった。

iter154.69 でボトムナビをガラスフッター化したため、検索導線も画面上部ではなく下部の手が届きやすい位置に寄せ、ホームのヘッダーを少し軽くする方針にした。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホーム画面ヘッダー左上の検索ボタンを削除した。
- ホーム画面の左下、ボトムナビの上に固定表示される丸い検索ボタンを追加した。
- 新しい検索ボタンはガラスフッターに合わせ、半透明白背景・blur・丸型の影を付けた。

### 影響範囲

- ホーム画面の検索導線
- ホーム画面ヘッダー左側の表示

### 確認方法

- `npx eslint 'src/components/home/HomeView.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 取引一覧ヘッダーなど、今回指定外の画面には触れていない
- ✅ 検索導線は `/search` のまま維持し、配置だけをホーム下部へ移した
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.69：ボトムナビをガラスフッター化

### 背景・問題意識

オーナーから、フッターの「ホーム」などのナビゲーションを、添付画像のような最新版iOS風のガラスUIにできないかという相談があった。

共通フッターは毎日触る導線なので、単なる白い固定バーではなく、画面上にふわっと浮くガラスカプセルとして見せることで、アプリ全体の質感を引き上げる必要があった。また、タブ切替時にアクティブ状態が瞬時に切り替わるだけだと硬いため、選択ハイライトと画面遷移の両方をなめらかにする方針にした。

### 変更内容

#### `web/src/components/home/BottomNav.tsx`
- 白い固定バー型のボトムナビを、浮いたガラスカプセル型へ変更した。
- アクティブ項目の背景を、項目幅に合わせたガラスのハイライトが横にスライドする設計にした。
- アイコンは `currentColor` に揃え、アクティブ時の色替えをテキストカラーと一体で制御するようにした。
- フッタータブのSPA遷移時だけ `sessionStorage` にフラグを立て、通常の詳細遷移や戻る操作には影響しないようにした。

#### `web/src/components/home/BottomNavTransitionBridge.tsx`
- ルート変更後にフッター遷移フラグを消費し、次ページの `main` を軽くフェード/リフトインさせるクライアントブリッジを追加した。

#### `web/src/app/layout.tsx`
- `BottomNavTransitionBridge` をルートレイアウトに追加し、全ページで共通フッター遷移を受け取れるようにした。

#### `web/src/app/globals.css`
- ボトムナビ遷移専用の View Transition / fallback animation を追加した。
- `body.megrum-bottom-nav-transitioning` / `body.megrum-bottom-nav-route-entering` の時だけ効くようにして、既存の削除アニメーションや詳細画面の右スライド演出と干渉しないようにした。

#### `web/src/app/inventory/InventoryView.tsx`
- 在庫画面の専用フッターも新しいガラス型 `BottomNav` を使うようにし、CTAとの一体白バーをやめた。
- CTAのブランドカラー指定を Tailwind の `from-megrum-lavender` / `to-megrum-pink` に寄せた。

### 影響範囲

- 共通ボトムナビが表示される主要画面
- 在庫画面のCTA付きフッター
- ボトムナビ経由のホーム/在庫/wish/取引/プロフ遷移

### 確認方法

- `npx eslint 'src/components/home/BottomNav.tsx' 'src/components/home/BottomNavTransitionBridge.tsx' 'src/app/layout.tsx' 'src/app/inventory/InventoryView.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`
- `npm run dev` → `http://localhost:3000` のHTTP応答確認

### 関連ファイル

- `web/src/components/home/BottomNav.tsx`
- `web/src/components/home/BottomNavTransitionBridge.tsx`
- `web/src/app/layout.tsx`
- `web/src/app/globals.css`
- `web/src/app/inventory/InventoryView.tsx`

### セルフレビュー結果

- ✅ 共通 `BottomNav` を一箇所で更新し、ホーム/取引/wish/プロフなどの主要画面に同じ質感が波及するようにした
- ✅ アクティブハイライトは `transform` で移動させ、レイアウトシフトせずふわっと切り替わる
- ✅ ボトムナビ遷移だけをフラグで判定し、既存の詳細画面スライドや削除時 View Transition とは分離した
- ✅ 今回追加したブランド色指定は Tailwind theme の `megrum-*` を使用し、CTAの既存直書きも一部是正した
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.68：現地モード切替を非リロード化

### 背景・問題意識

オーナーから、ホーム画面で現地交換モードに切り替えようとすると画面がリロードされ、全国交換モードのままになってしまうという報告があった。

モード切替はユーザーが「いま探し方を変える」操作なので、画面全体が再取得されたように見えたり、押した後に元の全国表示へ戻ったように見えると体験を大きく損なう。ボタン押下時はまずホーム内で即時に表示を切り替え、DBへのON/OFF保存は裏で追いつく設計にする必要があった。

### 変更内容

#### `web/src/app/page.tsx`
- 現地交換モードON中だけでなく、現在のAWがある場合は常に現地マッチ判定を付与するようにした。
- URLの `view` に応じたサーバー側のマッチ候補フィルタをやめ、ホーム画面に必要な候補をまとめて渡すようにした。
- 距離計算は `user_local_mode_settings.last_lat/lng` がない場合でも、現在AWの `center_lat/lng` を使えるようにした。

#### `web/src/components/home/HomeView.tsx`
- 全国交換モード/今すぐ現地交換モードの表示切替を、`router.push` ではなくクライアント状態と `history.replaceState` で処理するようにした。
- 現地モードのON/OFF保存後、`localEnabledOverride` と `clientViewMode` で画面上のモードを即時反映するようにした。
- ホームの候補一覧は、全候補から「全国表示なら全部」「現地表示なら `localAvailable` の候補だけ」にクライアント側で切り替えるようにした。
- 切替中オーバーレイ終了後に `optimisticMode` をクリアし、次の操作で古い見た目が残らないようにした。

#### `web/src/components/home/actions.ts`
- `enableLocalMode` / `disableLocalMode` では `revalidatePath("/")` を呼ばず、ホームの画面再取得が起きたように見える挙動を抑えた。
- AW設定適用や現地モード内の選択更新では、候補や場所情報を再取得する必要があるため既存の `revalidatePath("/")` を維持した。

### 影響範囲

- ホーム画面上部の全国交換モード/今すぐ現地交換モード切替
- 現地交換モードON/OFF時の表示反映
- ホームのマッチ候補一覧の全国/現地フィルタ

### 確認方法

- `npx eslint 'src/components/home/HomeView.tsx' 'src/components/home/actions.ts' 'src/app/page.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/page.tsx`
- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/actions.ts`

### セルフレビュー結果

- ✅ モード切替の画面遷移をホーム内の状態更新へ寄せ、リロードのように見える `router.push` / ON-OFF時の `revalidatePath("/")` を避けた
- ✅ 現地候補の判定はサーバーで常に付与し、表示フィルタだけをクライアントで切り替えるため、全国/現地の往復で候補が欠落しにくい
- ✅ AW設定適用・選択更新の再検証は維持しており、場所や持参グッズの変更が反映される導線は残している
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.67：取引一覧全タブをチケット型へ統一

### 背景・問題意識

オーナーから、打診中だけでなく進行中と完了タブも同様に整えてほしいという要望があった。

また、タブを横スライドするたびに各パネルが毎回登場アニメーションする挙動が違和感になっていた。一度見たタブについては、戻ってきた時に再度ふわっと現れるのではなく、そこに残っている画面として自然に見える必要があった。

### 変更内容

#### `web/src/app/transactions/TransactionsView.tsx`
- 進行中カードを打診中と同じ画像付きチケット型へ変更した。
- 進行中カードでは、相手アバター・ユーザーID・取引予定/まもなく合流/申告中の状態・更新時刻・受け取る/出すグッズ・待ち合わせ情報を同じ構成で表示するようにした。
- 申告中の進行中カードは左アクセントと赤系の強調を残し、通常の取引予定と優先度が分かれるようにした。
- 完了カードも画像付きチケット型へ変更し、ステータス、日付、評価、受け取る/出すグッズ、待ち合わせ情報を同じ情報設計に揃えた。
- 進行中は申告中・合流間近・開始時刻順で並ぶようにし、次に見たい取引が上に来るようにした。
- タブごとに初回表示済みかを管理し、打診中/進行中/完了それぞれで一度表示された後は、横スライドで戻ってきてもカードの登場アニメーションを再実行しないようにした。
- 初回アニメーションは最後のカードの animation end で表示済みにすることで、途中のカードのアニメーションが切れないようにした。

### 影響範囲

- `/transactions` の進行中タブ
- `/transactions` の完了タブ
- `/transactions` のタブ横スライド時のカード登場アニメーション

### 確認方法

- `npx eslint 'src/app/transactions/TransactionsView.tsx' 'src/app/transactions/page.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/transactions/TransactionsView.tsx`

### セルフレビュー結果

- ✅ 取引一覧内の表示とアニメーション制御だけを変更
- ✅ 打診中・進行中・完了のカード文法を画像付きチケット型に統一
- ✅ 一度表示済みのタブでは、再訪時にカード登場アニメーションが再実行されない
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.66：打診中チケットの判断しやすさを仕上げ

### 背景・問題意識

オーナーから、打診一覧の画面を作りきっておいてほしい、ただしそれ以外は触らないようにという指示があった。

iter154.65 で「要対応／相手待ち」とチケット型パネルは入ったが、実運用で最初に見るべきものを自然に出す、期限・更新時刻・送受信方向・合意待ちの意味を短いパネル内で判断できる状態まで仕上げる必要があった。

### 変更内容

#### `web/src/app/transactions/TransactionsView.tsx`
- 要対応が0件で相手待ちだけある場合、空の要対応タブではなく相手待ちタブを見せるようにした。
- 打診中カードを優先度順に並べ替えるようにした。相手合意済み、自分の返信待ち、相手からの最新返信、期限間近を上に出す。
- カード上部に相手アバター、ユーザーID、届いた／送ったチップを並べ、誰とのどちら向きの打診かを先に認識できるようにした。
- ステータス文を「相手は合意済み」「あなたは合意済み」「返信が届いています」など、次に何が起きているかが分かる表現に調整した。
- 更新時刻を追加し、動きがあった打診を把握しやすくした。
- 待ち合わせ未設定は赤みのある強調表示にし、時間だけ／場所だけ未設定の場合も具体的に分かるようにした。
- グッズ画像のサムネイルを少し大きくし、チケットの高揚感と視認性を上げた。

### 影響範囲

- `/transactions` の打診中タブ
- 打診中の「要対応／相手待ち」分類表示
- 打診中カードの並び順・表示情報

### 確認方法

- `npx eslint 'src/app/transactions/TransactionsView.tsx' 'src/app/transactions/page.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/transactions/TransactionsView.tsx`

### セルフレビュー結果

- ✅ 変更対象は取引一覧の打診中表示に限定
- ✅ 進行中・完了タブの表示ロジックには触れていない
- ✅ 新しい状態名・DBカラム・正式用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.65：打診中一覧をチケット型に刷新

### 背景・問題意識

オーナーから、取引一覧は上位タブを「打診中／進行中／完了」のまま維持し、打診中の中だけ「要対応」と「相手待ち」に分けたいという要望があった。

また、当初案のように情報量を盛りすぎると1つのパネルが縦長になってしまうため、見たい情報を保ちながら、短時間で判断できるコンパクトなチケット型パネルに寄せる必要があった。

### 変更内容

#### `web/src/app/transactions/page.tsx`
- 打診中の対応要否を判定できるよう、`proposals.agreed_by_sender` / `agreed_by_receiver` を一覧取得に追加した。
- `messages` の最新送信者を proposal ごとに取得し、ネゴ中の「要対応／相手待ち」判定に使うようにした。
- `goods_inventory.photo_urls` を取得し、取引一覧カードへ譲・受け取るグッズの小さな画像プレビューを渡すようにした。
- 定価交換の候補は画像なしの金額チップとして扱うようにした。

#### `web/src/app/transactions/TransactionsView.tsx`
- 上位タブの「過去取引」を「完了」に変更した。
- 打診中タブ内に「要対応」「相手待ち」の2分割タブを追加した。
- 未返信・相手最新メッセージ・一方合意の自分待ちを「要対応」に、それ以外を「相手待ち」に分類するようにした。
- 打診中カードを、ステータス／期限／相手ID／受け取る画像列／出す画像列／待ち合わせ要約／CTAだけに絞ったコンパクトなチケット型へ変更した。
- 要対応カードは左端に細いアクセントを置き、一覧で優先して気づける見た目にした。

### 影響範囲

- `/transactions` の取引一覧画面
- 打診中タブの分類・カード表示
- 進行中／完了タブの上位タブラベル表示

### 確認方法

- `npx eslint 'src/app/transactions/TransactionsView.tsx' 'src/app/transactions/page.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/transactions/page.tsx`
- `web/src/app/transactions/TransactionsView.tsx`

### セルフレビュー結果

- ✅ 上位タブは「打診中／進行中／完了」に統一
- ✅ 打診中のみ「要対応／相手待ち」の内側タブで分類
- ✅ パネルは縦長化を避け、画像付きの短いチケット型に整理
- ✅ 既存の `sent` / `negotiating` / `agreement_one_side` / `agreed` 状態を使っており、新しい状態名は追加していない
- ✅ 新しいDBカラムやmigrationは追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要

---

## イテレーション154.64：待ち合わせ候補の長押しリフト表現を追加

### 背景・問題意識

オーナーから、一度設定した待ち合わせ時間候補について、長押ししたときに候補がふわっと浮く感じにして、動かせる対象であることが直感的に伝わるようにしたいという要望があった。

既存実装では長押しで移動モードには入れるが、見た目の変化が弱く、「掴んだ」「動かせる」という手応えが不足していた。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 既存候補が `candidateEdit` 状態に入った時、カードを `translateY(-4px) scale(1.035)` で少し持ち上げるようにした。
- 編集中の候補カードだけ影を強め、軽く明るく表示するようにした。
- 横移動時の `translateX` と長押し時のリフト表現を同時に適用できるよう、transform を合成する形に変更した。
- `transition-[transform,box-shadow,filter]` を追加し、長押し成立時にふわっと浮くようにした。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 設定済み候補の長押し移動
- 設定済み候補の終了時刻リサイズ開始時の視覚フィードバック

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 長押し編集状態でカードが少し浮き、動かせる印象を追加
- ✅ 既存の日跨ぎ横移動 `translateX` とリフト表現を両立
- ✅ 場所未設定候補・設定済み候補どちらにも同じフィードバックを適用
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.63：地図初回タップで場所自動取得を開始

### 背景・問題意識

オーナーから、待ち合わせ場所の地図を開いて1回タップしても、なぜか場所の自動取得が始まらないという指摘があった。

確認したところ、場所設定シートを開いた直後は初回 mount の reverse geocode を避けるための `skipReverseRef` が立っており、最初の地図タップによる center 変更でもそのフラグが残ったままになっていた。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 地図タップ・ピンドラッグ由来の `handleMapCenterChange` で `skipReverseRef.current = false` を明示するようにした。
- 「現在地を中心に」ボタンでも同様に `skipReverseRef.current = false` を明示し、初回操作から reverse geocode が走るようにした。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 場所設定シート内の地図タップ・ピンドラッグ
- 「現在地を中心に」ボタン
- 「交換できる場所」入力欄の `取得中…` placeholder 表示

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 初回 mount の自動 reverse skip は維持
- ✅ ユーザーによる地図操作では初回から reverse geocode を許可
- ✅ 現在地ジャンプでも初回から場所名取得を許可
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.62：待ち合わせカレンダーを5日表示へ変更

### 背景・問題意識

オーナーから、待ち合わせカレンダーの一度に表示する日数が7日だと横幅が狭く、時間帯を選びづらいという指摘があった。

ドラッグで候補時間を選択する画面では、1日あたりの列幅が操作性に直結するため、表示日数を減らして各日のタッチ領域を広げる必要があった。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 待ち合わせカレンダーの表示日数を7日から5日に変更した。
- 日付ヘッダーと時間グリッドの列数を5日分に合わせた。
- カレンダー内の横スワイプ送り幅も、表示単位に合わせて5日ずつ進む／戻るようにした。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- カレンダーの日付ヘッダー
- 候補時間のドラッグ選択・候補カード移動時の列幅
- カレンダー横スワイプによる日付送り

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 表示日数を5日に変更し、1日あたりの列幅を広げた
- ✅ 日付ヘッダーとカレンダーグリッドの列数を揃えた
- ✅ 横スワイプの送り幅も5日単位に統一
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.61：待ち合わせカレンダーの空状態ガイドを中央固定化

### 背景・問題意識

オーナーから、待ち合わせカレンダーの空状態ガイドは、カレンダーをスクロールしても位置が変わらないよう、カレンダー領域の中央に固定表示したいという指摘があった。

また、黒背景は半透明にしつつ、テキスト裏だけを濃くしたり、水玉を浮かばせたりするのではなく、黒い背景自体が少し大きくなったり小さくなったりする表現に寄せる必要があった。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 空状態ガイドをカレンダーグリッド内の絶対位置から、スクロールコンテナ外のオーバーレイに移動した。
- カレンダー日付ヘッダー下の表示領域中央に固定されるよう、オーバーレイの表示範囲を調整した。
- 水玉状の装飾とテキスト裏の濃い背景を削除した。
- 黒半透明の単一パネルに変更し、背景そのものがゆっくり拡縮する `megrum-meetup-hint-breathe` アニメーションを追加した。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 候補未設定時のカレンダー空状態ガイド
- カレンダー縦スクロール時の案内表示位置

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 空状態ガイドはスクロール中のグリッドから分離し、カレンダー表示領域中央に固定
- ✅ 黒背景は半透明の単一パネルに整理
- ✅ 水玉装飾・テキスト裏の追加背景を削除
- ✅ 背景パネルが控えめに拡縮するアニメーションへ変更
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.60：待ち合わせ場所の前回設定ボタンを調整

### 背景・問題意識

オーナーから、場所設定シートの「同じ場所を全候補に」は意味と配置が強すぎるため、「前の設定と同じに」へ文言変更し、現在地ボタンと同じ行の右端に配置してほしいという指摘があった。

また、取得中表示はラベル横ではなく「交換できる場所」入力欄の placeholder として出し、前回設定ボタンは直前に設定した場所を現在の候補へ反映する挙動にする必要があった。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 現在編集中の候補より前にある、場所設定済みの直近候補を `previousMeetupForActive` として参照するようにした。
- 「同じ場所を全候補に」を廃止し、「前の設定と同じに」で直前の設定済み候補の場所・座標を現在候補へ適用するようにした。
- 「前の設定と同じに」ボタンを「現在地を中心に」と同じ行の右端に配置し、青い塗りのボタンとして視認性を上げた。
- reverse geocode 中の「取得中…」表示を、場所入力欄の placeholder に移動した。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 候補時間を選択した後に開く場所設定シート
- 複数候補の場所設定補助導線

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 「前の設定と同じに」は全候補一括コピーではなく、現在候補へ直前の設定済み場所を反映する挙動に変更
- ✅ ボタンを現在地ボタン行の右端に移動し、ボタンとして見つけやすい塗り・影を追加
- ✅ 「取得中…」は場所入力欄の placeholder に集約
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.59：待ち合わせ候補の横ドラッグ継続を修正

### 背景・問題意識

オーナーから、待ち合わせタブで候補をドラッグ&ドロップして1つ横の日にずらすと、その後は横移動ができなくなり、縦移動だけ続くという指摘があった。

確認したところ、ドラッグ中の候補カードを移動先の日付列へ描き直す実装だったため、横に日付をまたいだ瞬間に、指で掴んでいるDOM要素が別列へ移動・再描画され、ポインターキャプチャが途切れる可能性があった。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- ドラッグ中の候補編集 state に `originalDayIndex` を追加した。
- 編集中の候補カードはDOM上では元の日付列に保持し、見た目だけ `translateX` で横の列へ移動するようにした。
- 横方向に日付をまたいでも、掴んでいるカード要素がアンマウントされないため、横移動を継続しやすくした。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 既存候補の長押し横移動
- 日をまたぐドラッグ操作

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 横移動中にカードDOMを別列へ移動させない実装へ変更
- ✅ 日付列をまたぐ見た目は `translateX` で維持
- ✅ 縦移動・終了時刻リサイズの既存挙動を維持
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.58：待ち合わせカレンダーの警告アイコン位置と曜日計算を修正

### 背景・問題意識

オーナーから、待ち合わせ候補の `!` アイコンが左寄りに見えることと、今日が金曜日のはずなのにカレンダー上では土曜日になっているという指摘があった。

未設定候補の警告は中央に見えないと不自然であり、曜日は端末・ブラウザ・実行環境のタイムゾーン差に影響されないよう、日付キーから安定して計算する必要がある。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 場所未設定候補の `!` アイコンを候補ブロック中央に絶対配置した。
- `formatDateKeyWeekday` を `new Date(...+09:00).getDay()` ではなく、`YYYY-MM-DD` を `Date.UTC` で組み立てて `getUTCDay()` する方式へ変更した。
- これにより、`2026-05-08` は必ず金曜日として表示される。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- カレンダー上の曜日表示
- 場所未設定候補ブロックの警告アイコン表示

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ `!` アイコンを候補ブロック中央に配置
- ✅ 曜日計算をタイムゾーン差に影響されにくい実装へ変更
- ✅ `2026-05-08` が金曜日として計算されることを確認
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.57：待ち合わせ未設定時の長押し案内を追加

### 背景・問題意識

オーナーから、待ち合わせタブでどこにも候補を設定していない時、薄い黒の透明背景と丸型の図形が浮かぶ中に `長押しで時間を選択できるよ` のような案内を出したいという要望があった。

カレンダーはドラッグ操作が主導線だが、初回状態では何をすれば良いか分かりにくいため、候補未設定時だけ操作を邪魔しないヒントを表示する。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 待ち合わせ候補がまだ時間設定されていない時だけ、カレンダー上に空状態の案内を表示するようにした。
- 薄い黒の透明背景に、丸い図形がふわっと浮くアニメーションを追加した。
- 案内文は `長押しで時間を選択できるよ` とし、候補作成中・既存候補ありの時は表示しない。
- 案内 overlay は `pointer-events-none` にして、長押し操作を塞がないようにした。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 候補未設定時のカレンダー空状態

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 候補未設定時だけ案内が出る
- ✅ 候補作成中・候補設定後は案内が消える
- ✅ overlay が長押し入力を塞がない
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.56：待ち合わせカレンダーの24時選択余白を追加

### 背景・問題意識

オーナーから、待ち合わせタブのカレンダーで24時まで候補をドラッグ選択できず、一番下に操作用の遊びがないことが原因かもしれないという指摘があった。

スマホ操作では、24:00 の最後の15分枠に指を正確に置くのが難しく、下端に余白がないと終了時刻を24:00に合わせづらい。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- カレンダー下端の余白を広げ、24:00 の下にも指を置ける遊びを作った。
- 下端の余白エリアまでドラッグした場合も、最後の15分枠として扱い、終了時刻が24:00になるようにした。
- pointer / touch / 既存候補編集の座標計算を共通 helper にまとめ、下端余白での判定を揃えた。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- カレンダー候補のドラッグ作成
- 既存候補の移動・終了時刻リサイズ

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 24:00 下に操作用余白を追加
- ✅ 下端余白へドラッグしても24:00終了として扱える
- ✅ pointer / touch / 既存候補編集の座標判定を共通化
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.55：未設定候補のカレンダー表示を警告アイコン化

### 背景・問題意識

オーナーから、待ち合わせタブのカレンダー候補で、場所未設定時の文字が狭いカード内で `場...` のように省略され、何を意味しているか分からないという指摘があった。

未設定状態は文字で説明するより、狭い候補ブロック内では警告アイコンとして示した方が判別しやすい。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 場所未設定の候補ブロックでは `場所を設定` のテキストを表示しないようにした。
- 代わりに、丸の中に `!` を載せた警告アイコンを表示するようにした。
- 場所が設定済みの場合は警告アイコンを消し、場所名だけを表示する。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- カレンダー上の場所未設定候補ブロック

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 未設定候補の `場...` 表示を解消
- ✅ 場所未設定は丸い `!` アイコンで示す
- ✅ 場所設定後は `!` が消え、場所名のみ表示される
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.54：待ち合わせ候補移動の確定漏れを修正

### 背景・問題意識

オーナーから、待ち合わせタブで候補ブロックを長押しドラッグして一度は移動できるが、その後に画面をタップすると元の場所へ戻ってしまうという指摘があった。

タッチ環境では、移動中の見た目を管理する一時 state は更新される一方で、`pointerup` が拾えないケースでは本体の `meetupCandidates` へ確定反映されず、次のタップや再描画で一時 state が消えて元位置に戻る可能性があった。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 既存候補の移動・終了時間リサイズ中に、プレビューだけでなく本体 state にも最新の時間帯を逐次反映するようにした。
- 同じ編集内容の重複反映を避けるため、候補編集キーを保持して同一更新をスキップするようにした。
- `pointercancel` で終了した場合も、編集中の最新位置を確定してから一時 state を消すようにした。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 既存候補の長押し移動
- 候補下端ハンドルによる終了時刻リサイズ

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ ドラッグ中の最新位置を本体 state へ反映
- ✅ `pointerup` が拾えない終了パターンでも `pointercancel` で確定
- ✅ 同一編集内容の重複 state 更新を抑制
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.53：待ち合わせカレンダー操作をGoogle Calendar風に調整

### 背景・問題意識

オーナーから、待ち合わせタブの場所設定ポップアップとカレンダー候補の操作について、Google Calendar に近い直感的な操作へ寄せたいという指摘があった。

具体的には、場所設定ポップアップは外側タップで閉じたい、同じ場所を全候補へ適用する導線を右端に置きたい、カレンダー候補ブロックは `候補X` ではなく場所名だけを表示したい、既存候補を長押しドラッグで移動・終了時間変更できるようにしたい、初期表示は10時付近から始めたい、という要望。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 場所設定シートの背景部分を押すとシートが閉じるようにした。
- `同じ場所を全候補に` ボタンを「交換できる場所」行の右端へ移動し、適用後は `適用済み` 表示に変わるようにした。
- カレンダー上の候補ブロックから `候補X` 表示を外し、場所名のみを表示するようにした。
- 候補ブロックの確定色を紫から青へ変更した。
- 候補ブロック本体の長押し / ドラッグで、日を跨いだ移動ができるようにした。
- 候補ブロック下端のハンドルを長押し / ドラッグすると、終了時刻を15分単位で変更できるようにした。
- カレンダー初期表示を10時付近へスクロールするようにした。
- 0時付近が詰まって見えないよう、タイムライン上下に余白を追加した。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 場所設定シート
- 交換できる候補のカレンダー作成・移動・リサイズ操作

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 場所設定シートの外側タップ閉じに対応
- ✅ 同じ場所を全候補へ適用する導線と適用済みフィードバックを追加
- ✅ カレンダー候補ブロックは場所名中心の青い表示へ整理
- ✅ 既存候補の移動・終了時刻リサイズを15分単位で実装
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.52：待ち合わせ候補の初期採番を修正

### 背景・問題意識

オーナーから、提示物の選択 > 待ち合わせタブで、最初から見えない候補が1つ設定されているように見え、普通に1件目を設定したのに `候補2` になるという指摘があった。

確認したところ、新規打診でも初期 state に `nowPlusHoursLocal(1)` / `nowPlusHoursLocal(2)` の時間入り候補1が作られており、ユーザーがドラッグで時間を設定すると「候補1はすでに時間あり」と判定されて候補2が作られていた。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 新規打診の初期 `meetupCandidates` は、時間・場所のない空の `candidate-1` から始めるようにした。
- 再打診・既存 proposal 由来の `initial.meetupCandidates` は従来通り復元する。
- 旧形式の `meetupStartAt` / `meetupEndAt` が渡された場合のみ、既存候補として `candidate-1` を復元する。
- 未使用になった `nowPlusHoursLocal` を削除した。

### 影響範囲

- `/propose/[partnerId]` の待ち合わせタブ
- 新規打診時の候補作成・候補番号表示
- 再打診 / 既存 proposal の待ち合わせ候補復元

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 新規打診で見えない時間入り候補を作らない
- ✅ 1回目のドラッグ設定が `候補1` に反映される
- ✅ 既存 proposal / 再打診の候補復元は維持
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.51：地図attribution表示を小さく調整

### 背景・問題意識

オーナーから、地図右下に残っている `OpenStreetMap / CARTO` 表示も消すか小さくしたいという指摘があった。

地図データ提供元の attribution は完全に消すと利用条件に抵触しうるため、表示は維持したまま、UI上の存在感を大きく下げる。

### 変更内容

#### `web/src/components/map/MapPicker.tsx`
- Leaflet attribution control を小さいピル状表示に調整した。
- OpenStreetMap / CARTO 表示は残しつつ、フォントサイズ・背景・余白・色を控えめにした。

#### `web/src/components/map/MapTilerPicker.tsx`
- MapTiler / MapLibre 側の attribution 表示も同じトーンに調整した。
- MapTiler API キー設定時と未設定 fallback のどちらでも、地図右下の表記が目立ちすぎないようにした。

### 影響範囲

- 提示物選択フローの場所設定地図
- 送信確認画面の待ち合わせ地図
- `MapPicker` / `MapTilerPicker` を使う地図表示全般

### 確認方法

- `npx eslint src/components/map/MapPicker.tsx src/components/map/MapTilerPicker.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/map/MapPicker.tsx`
- `web/src/components/map/MapTilerPicker.tsx`

### セルフレビュー結果

- ✅ 地図提供元の attribution は維持
- ✅ Leaflet / MapTiler 両方の表示サイズを調整
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.50：Leafletの地図prefix表示を非表示化

### 背景・問題意識

オーナーから、地図の右端に表示される `Leaflet` のような表記を消したいという指摘があった。

地図データ提供元の attribution は残す必要があるが、`Leaflet` は地図ライブラリ側の prefix 表示なので、データ attribution を維持したまま非表示にできる。

### 変更内容

#### `web/src/components/map/MapPicker.tsx`
- `MapContainer` のデフォルト attribution control を無効化した。
- `AttributionControl` を明示的に追加し、`prefix={false}` で `Leaflet` prefix だけを非表示にした。
- OpenStreetMap / CARTO の attribution は `TileLayer` 側に残し、地図データの権利表示は維持した。

### 影響範囲

- Leaflet ベースの `MapPicker` を使う地図全般
- MapTiler API キー未設定時の提示物選択フロー地図フォールバック

### 確認方法

- `npx eslint src/components/map/MapPicker.tsx src/components/map/MapTilerPicker.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/map/MapPicker.tsx`

### セルフレビュー結果

- ✅ `Leaflet` prefix のみ非表示化
- ✅ OpenStreetMap / CARTO の attribution は維持
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.49：送信確認の待ち合わせ表示を地図中心に整理

### 背景・問題意識

オーナーから、提示物の選択フローの送信確認画面ではカレンダー表示は不要で、メッセージも任意のままでよく、プレースホルダーにも余計な文言を入れないでほしいという指摘があった。

送信確認では、すでに待ち合わせタブで時間候補を作成済みなので、もう一度カレンダーを見せるより、場所のピンと候補詳細だけを見せた方が最終確認として軽い。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 送信確認画面の `MeetupPlanPreview` からカレンダー表示を削除した。
- 待ち合わせ候補の確認カードを、地図 + 候補詳細リストだけの構成にした。
- カレンダー表示に使っていた送信確認専用の計算処理を削除した。
- メッセージ欄の placeholder を削除し、任意入力に余計な誘導文が出ないようにした。

### 影響範囲

- `/propose/[partnerId]` 送信確認画面
- 待ち合わせ候補プレビュー
- メッセージ入力欄

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 送信確認からカレンダー表示を削除
- ✅ 地図と候補詳細だけで待ち合わせ内容を確認できる
- ✅ メッセージ欄の placeholder を削除し、任意入力の圧を下げた
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.48：MapTiler未設定時の地図フォールバックを軽量化

### 背景・問題意識

オーナーから、提示物の選択の待ち合わせタブで日程を選んでも、まだ OpenStreetMap 標準表示のままに見えるという指摘があった。

確認したところ、ローカルの `.env.local` に `NEXT_PUBLIC_MAPTILER_API_KEY` が未設定だったため、前回追加した MapTiler 用コンポーネントが旧 `MapPicker` にフォールバックしていた。これにより、MapTiler Streets ではなく OpenStreetMap 標準タイルが表示され、地図がごちゃついて見えていた。

MapTiler Streets そのものには API キーが必要だが、キー未設定時にも旧標準タイルへ戻ると見た目の改善が分かりにくい。暫定表示でも軽い見た目になるよう、フォールバックを light 系タイルへ変更する。

### 変更内容

#### `web/src/components/map/MapPicker.tsx`
- 既存 `MapPicker` に `tileStyle` prop を追加した。
- デフォルトは従来通り `standard` とし、既存画面の挙動は変えない。
- `tileStyle="light"` の場合は CARTO の light 系タイルを使うようにした。

#### `web/src/components/map/MapTilerPicker.tsx`
- `NEXT_PUBLIC_MAPTILER_API_KEY` 未設定時のフォールバックを、旧 OpenStreetMap 標準表示ではなく `MapPicker tileStyle="light"` に変更した。
- MapTiler API キーが設定されれば、従来通り `MapStyle.STREETS` + `Language.JAPANESE` を使う。

### 影響範囲

- `/propose/[partnerId]` C-0 提示物の選択フロー
- MapTiler API キー未設定時の場所設定シート / 送信確認地図
- 既存 `MapPicker` 呼び出しは `tileStyle` 未指定のため標準表示のまま

### 確認方法

- `npx eslint src/components/map/MapPicker.tsx src/components/map/MapTilerPicker.tsx 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/map/MapPicker.tsx`
- `web/src/components/map/MapTilerPicker.tsx`

### セルフレビュー結果

- ✅ MapTiler API キー未設定時に OpenStreetMap 標準タイルへ戻らない
- ✅ 既存画面の `MapPicker` はデフォルト挙動維持
- ✅ MapTiler API キー設定後は `MapStyle.STREETS` + 日本語ラベル指定を使用
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.47：提示物選択フローの地図をMapTiler Streetsへ切替

### 背景・問題意識

オーナーから、現状の OpenStreetMap 標準タイルは情報量が多く、ごちゃついて見えるため、iOS マップのようなシンプルな地図に寄せたいという相談があった。

Apple MapKit JS は見た目は近いが、既存の Leaflet ベースの `MapPicker` とは SDK が異なり、Apple Developer の Maps ID / private key / token 配布設計が必要になる。まずは実装しやすく、日本語ラベル指定もできる MapTiler SDK の `MapStyle.STREETS` を提示物の選択フローから試す。

### 変更内容

#### `web/src/components/map/MapTilerPicker.tsx`
- MapTiler SDK ベースの新しい地図ピッカーを追加した。
- `MapStyle.STREETS` と `Language.JAPANESE` を指定し、日本語地名を優先表示するようにした。
- 既存 `MapPicker` と同じ props（`center` / `radiusM` / `markers` / `interactive` / `onCenterChange`）で使えるようにした。
- 単一ピンのドラッグ・地図クリックで中心座標を更新できるようにした。
- 複数ピン表示時は番号付きピンを表示し、全ピンが入るように地図範囲を自動フィットするようにした。
- 交換範囲の円を GeoJSON レイヤーとして表示するようにした。
- `NEXT_PUBLIC_MAPTILER_API_KEY` が未設定の場合は、既存 Leaflet `MapPicker` へフォールバックするようにした。

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 提示物の選択フロー内の場所設定シートと送信確認プレビュー地図を `MapTilerPicker` に差し替えた。
- 横スワイプ除外対象に `.maplibregl-map` を追加した。

#### `web/.env.local.example`
- `NEXT_PUBLIC_MAPTILER_API_KEY` の設定例を追加した。

#### `web/package.json` / `web/package-lock.json`
- `@maptiler/sdk` を追加した。

### 影響範囲

- `/propose/[partnerId]` C-0 提示物の選択フロー
- 場所設定シートの地図
- 送信確認画面の待ち合わせプレビュー地図
- 既存の他画面の `MapPicker` 呼び出しは未変更

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx' src/components/map/MapTilerPicker.tsx src/components/map/MapPicker.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/map/MapTilerPicker.tsx`
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- `web/.env.local.example`
- `web/package.json`
- `web/package-lock.json`

### セルフレビュー結果

- ✅ 提示物の選択フローだけ MapTiler Streets へ差し替え
- ✅ 日本語ラベル優先のため `Language.JAPANESE` を指定
- ✅ 既存 Leaflet 地図は他画面では維持
- ✅ APIキー未設定時は旧地図へフォールバックし、画面が壊れない
- ✅ 新しい状態名・DB migration は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` は更新不要
- ✅ 地図サービス名の追加であり、Megrum の業務用語追加ではないため `notes/10_glossary.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.46：個別募集デッキを紐で結ばれる表現へ調整

### 背景・問題意識

オーナーから、個別募集一覧のデッキ表示について「ちょっとださい」「もっとふわふわする感じがいい」「VS ではなく、紐で結ばれる感じにして欲しい」という指摘があった。

前回のデッキは格ゲーの対決感を優先したため、`VS` 表示が強く、個別募集の「条件が結びつく」感覚よりも勝負感が前に出ていた。推し活グッズ交換の文脈では、対立よりも、譲と求がふわっとつながる表現の方が自然。

### 変更内容

#### `web/src/app/listings/ListingsView.tsx`
- 個別募集デッキ内の `VS` 表示を削除した。
- `DeckCord` を追加し、譲と求を薄い曲線の紐で結ぶ表現に変更した。
- `DeckKnot` を追加し、対決マークの代わりに小さな結び目アイコンを表示するようにした。
- 対決型・扇型・オーブ型の各レイアウトに、紐の SVG を重ねるようにした。
- デッキカード全体にゆっくり上下する浮遊アニメーションを追加した。
- 紐に控えめな流れのアニメーションを追加し、静止した設定カード感を弱めた。
- `prefers-reduced-motion` では浮遊・紐アニメーションを停止するようにした。

### 影響範囲

- `/listings` 個別募集一覧
- 他人プロフィール等で `ListingsView` を readOnly 利用している公開個別募集表示

### 確認方法

- `npx eslint src/app/listings/ListingsView.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/listings/ListingsView.tsx`

### セルフレビュー結果

- ✅ `VS` を撤去し、譲と求が紐で結ばれる表現へ変更
- ✅ デッキカード全体の浮遊感を追加し、設定画面らしい硬さを軽減
- ✅ 対決型・扇型・オーブ型すべてで紐表現を維持
- ✅ 動きが苦手な環境では `prefers-reduced-motion` でアニメーション停止
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.45：待ち合わせ候補を時間先行で複数設定可能に

### 背景・問題意識

オーナーから、待ち合わせカレンダーで場所を設定しなくても複数の時間候補を先にドラッグ登録できるようにしたいという要望があった。

先に時間だけを押さえ、その後に場所設定で「同じ場所を全候補に使う」を適用できる方が、Google Calendar 的な操作感に近く、候補作成の勢いを止めない。また、設定した候補を消せないと、候補が増えるだけで修正できない。

送信確認画面についても、候補リストと主候補地図を別々に読むより、カレンダー上の時間と地図上のピンを1枚の図で見られる方が、送信前の理解負荷が低い。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 待ち合わせ候補の作成条件を「場所まで設定済み」から「時間が設定済み」に変更し、場所未設定のまま複数候補をドラッグ追加できるようにした。
- 時間ドラッグ後に場所設定シートを自動表示しないようにし、先に複数の時間帯を連続で押さえられる流れへ変更した。
- 場所未設定の候補がある場合も、カレンダー上には警告色の候補ブロックとして残すようにした。
- 各候補ブロック右上に削除ボタンを追加し、候補を減らせるようにした。
- 候補が1件だけの状態で削除した場合は、空の候補1へ戻して再度ドラッグ登録できるようにした。
- 送信確認画面の待ち合わせセクションを、上部にカレンダー、下部に地図、さらに候補の詳細を並べた1枚のプレビューカードへ変更した。

#### `web/src/components/map/MapPicker.tsx`
- 既存の地図ピッカーを、読み取り専用表示と複数ピン表示にも使えるように拡張した。
- `markers` を渡した場合、候補番号付きピンを複数表示し、範囲に合わせて地図をフィットするようにした。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- `/propose/[partnerId]` 送信確認画面
- `MapPicker` を使う既存画面（既存呼び出しはデフォルト挙動維持）

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx' src/components/map/MapPicker.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- `web/src/components/map/MapPicker.tsx`

### セルフレビュー結果

- ✅ 場所未設定のまま、時間候補を複数連続で作れる
- ✅ 後から場所設定シートで「同じ場所を全候補に使う」を適用できる
- ✅ 候補ブロック右上の削除で候補を減らせる
- ✅ 送信確認画面でカレンダーと複数ピン地図を1枚の図として確認できる
- ✅ 既存の `MapPicker` 呼び出しは props 追加のみで互換維持
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.44：個別募集一覧に募集デッキを追加

### 背景・問題意識

オーナーから、個別募集一覧はシンプルになった一方で、まだワクワク感やエンタメ性が足りず、脳内で関係性を処理する負担が重いという相談があった。

中心オーブ型をベースにしつつ、求めるものが少ない場合に過剰にならないよう、募集ごとに見せ方を切り替えながら「格ゲーのようにくるくるスワイプして見れる」上部デッキを追加する。

### 変更内容

#### `web/src/app/listings/ListingsView.tsx`
- 個別募集一覧の上部に `ListingDeck` を追加し、1募集を1枚の大きな横スワイプカードとして閲覧できるようにした。
- 横スクロール中の中央カードを検出し、中央カードを少し大きく、左右カードを軽く傾けて、くるくる回している感覚を出した。
- 求の数が1件以下なら対決カード型、2〜3件なら扇型、4件以上なら中心オーブ型へ自動で切り替えるようにした。
- 譲が複数ある場合は重ねカードと `すべて` / `1pick` のタグで表現し、求が多い場合は周囲に配置して関係性を一目で掴めるようにした。
- 既存の縦一覧と編集・一時停止・削除導線はそのまま残し、詳細確認や管理のしやすさは維持した。

### 影響範囲

- `/listings` 個別募集一覧
- 他人プロフィール等で `ListingsView` を readOnly 利用している公開個別募集表示

### 確認方法

- `npx eslint src/app/listings/ListingsView.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/listings/ListingsView.tsx`

### セルフレビュー結果

- ✅ 少数 wish では対決型、複数 wish では扇型・オーブ型に切り替わり、過剰演出になりすぎない
- ✅ 既存の縦一覧を残しているため、管理画面としての読みやすさは維持
- ✅ 編集 / 一時停止 / 削除の操作導線はデッキ内と既存一覧の両方で維持
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.43：待ち合わせカレンダーのタッチ選択を自前制御へ変更

### 背景・問題意識

オーナーから、待ち合わせカレンダーでまだ長押しドラッグ選択ができないという指摘があった。

前回の修正では、長押し後に touchmove を拾ってドラッグへ切り替える設計だったが、iOS Safari では `pan-y` のブラウザスクロール判定に持っていかれ、長押し成立後の移動が安定して届かないケースが残っていた。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- カレンダーの日別列を `touch-action: none` にし、iOS のブラウザ pan 判定に依存しないようにした。
- 長押し前に軽く縦へ動いた場合は、カレンダーの `scrollTop` を自前で更新して通常スクロールとして扱うようにした。
- 長押し成立後は touch を `dragging` モードへ固定し、その後の移動を候補時間の preview 更新に使うようにした。
- 横方向へ動いた場合は週切り替え用のスワイプ判定へ渡すため、候補作成タイマーだけ解除するようにした。
- タッチ操作の内部状態を `pending` / `scrolling` / `dragging` の3モードに整理し、スクロールと候補作成の競合を減らした。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- iOS Safari / モバイルブラウザでのカレンダー縦スクロールと候補時間ドラッグ作成

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 軽い縦移動は自前スクロールとして扱う
- ✅ 長押し成立後はブラウザ pan 判定に頼らず候補時間ドラッグへ固定
- ✅ 横スワイプの週切り替え余地は維持
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` 通過

---

## イテレーション154.42：待ち合わせカレンダーの長押し復旧と現在時刻表示

### 背景・問題意識

オーナーから、待ち合わせカレンダーで長押ししてもドラッグできなくなっているという指摘があった。

また、候補時間に場所を設定した後でも、その時間帯を再タップして場所を再設定できる必要がある。加えて、当日の列や現在時刻が見えないと、カレンダー上で「今どこを見ているか」が分かりにくい。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 長押し後のドラッグ状態を React state だけでなく ref にも保持し、iOS の touchmove 初回からドラッグ選択が追従するようにした。
- 長押し前の軽い移動は従来通りスクロール扱いにし、長押し成立後だけ `preventDefault` して候補時間のドラッグ選択へ切り替えるようにした。
- 場所設定済みの候補ブロックをタップした時も、場所設定シートを再表示できるようにした。
- カレンダー表示週に今日が含まれる場合、今日の日付ヘッダーと列背景を淡い紫でハイライトするようにした。
- 現在時刻が表示範囲内にある場合、左の時間軸に「今」ラベル、当日列に紫の横線を表示するようにした。
- 現在時刻表示は 1 分ごとに更新するようにした。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- iOS Safari での候補時間ドラッグ作成
- 候補時間ブロックからの場所再設定

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 長押し成立後のドラッグ選択を ref ベースで安定化
- ✅ 場所設定済み候補も再タップで場所シートを開ける
- ✅ 今日の列と現在時刻線でカレンダー上の現在地が分かりやすくなった
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` 通過

---

## イテレーション154.41：個別募集一覧の関係図表示を整理

### 背景・問題意識

オーナーから、個別募集一覧で「#X」や「X選択肢」の表記が設定画面らしく見えること、単体グッズにも枠が付きすぎていること、画像付き wish にも同種・異種タグが出ていること、譲が複数で求が単体の時に譲の2つ目が途切れるという指摘があった。

個別募集カードは、番号や内部設定値を見せるよりも、譲と求の関係そのものが直感的に読める表示へ寄せる。

### 変更内容

#### `web/src/app/listings/ListingsView.tsx`
- カードヘッダーから `#X` と `X 選択肢` の表記を削除した。
- 求側の各選択肢から `#1` などの番号タグを削除した。
- 譲側・求側とも、単体グッズの場合は外側のグループ枠を出さず、複数グッズの場合だけ枠を出すようにした。
- 複数グッズ枠の左上に、AND は「すべて」、OR は「1pick」として表示するタグを追加した。
- 画像付き wish のみで構成される選択肢では、同種・異種・同異種の交換タイプタグを表示しないようにした。
- 画像なし wish を含む選択肢のみ、交換タイプタグを表示するようにした。
- 関係図の高さを固定行高ではなく、譲側と求側の実際の表示高さから計算するようにし、譲2点以上 × 求1点の時に譲の2つ目が途切れないようにした。

### 影響範囲

- `/listings` 個別募集一覧
- 他人プロフィール等で `ListingsView` を readOnly 利用している公開個別募集表示

### 確認方法

- `npx eslint src/app/listings/ListingsView.tsx`
- `npx tsc --noEmit`
- `git diff --check`

### 関連ファイル

- `web/src/app/listings/ListingsView.tsx`

### セルフレビュー結果

- ✅ 内部番号・選択肢数の表示を削除し、募集内容の可読性を優先
- ✅ 単体グッズは枠なし、複数グッズだけ枠 + 条件タグで表現
- ✅ 画像付き wish の交換タイプタグを非表示化
- ✅ 譲複数 × 求単体でも高さが足りるように動的レイアウトへ変更
- ✅ 新しい状態名・DB migration は追加していないため `notes/09_state_machines.md` / `notes/05_data_model.md` は更新不要
- ✅ 既存の AND/OR 表現の UI ラベル変更のみで、新しい概念追加ではないため `notes/10_glossary.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` 通過

---

## イテレーション154.40：待ち合わせ候補の連続登録を修正

### 背景・問題意識

オーナーから、候補1を登録した後にカレンダーでドラッグして候補2を登録しようとしても、候補2ではなく候補1が再度設定されてしまうという指摘があった。

また、iOS ではカレンダーを長押しした時にブラウザ側のテキスト選択や虫眼鏡表示が走り、候補時間作成の体験を邪魔するため、待ち合わせカレンダー面だけを選択不能にする。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 候補時間をドラッグ確定する時、現在の候補が場所まで設定済みなら、次の未完成候補を優先して更新するようにした。
- 未完成候補が無く、候補数が上限 3 件未満なら `candidate-2` / `candidate-3` を自動作成して、その候補へ時間を設定するようにした。
- 新規候補を作成した場合は、その候補を active に切り替えて場所設定シートを開くようにした。
- 候補2が場所未設定など未完成の間は、次のドラッグで候補2の時間を調整するようにした。
- カレンダー面に `user-select: none` / `-webkit-user-select: none` / `-webkit-touch-callout: none` と context menu 抑制を追加し、iOS の長押し選択が出にくいようにした。
- 入力欄を含む場所設定シート側には選択不能指定を広げず、検索・入力の操作性は維持した。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- 複数の交換できる候補時間を連続登録する操作
- iOS Safari でのカレンダー長押し操作

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 候補1が完成済みなら次のドラッグで候補2を作成・選択する
- ✅ 未完成候補がある間はその候補を更新し、候補番号が無駄に増えない
- ✅ iOS の長押しテキスト選択対策はカレンダー面だけに限定
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` 通過

---

## イテレーション154.39：待ち合わせカレンダーの操作判定を調整

### 背景・問題意識

オーナーから、待ち合わせタブのカレンダー全体を縦スクロールできるようにした結果、候補時間のドラッグ選択と通常スクロールの判定がぶつかるという指摘があった。

Google Calendar のように、軽く縦に動かした場合はスクロール、少し長押ししてからドラッグした場合は予定作成として扱う体験へ寄せる。

また、24:00 までスクロールした後にさらに下へスクロールすると、親画面側のスクロールに連鎖して日付ヘッダーが元の画面ヘッダー領域へ食い込んで見えるため、待ち合わせカレンダー内でスクロールが完結するようにする。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- タッチ操作では押した瞬間に候補作成を開始せず、320ms の長押し後に候補時間選択モードへ入るようにした。
- 長押し前に指が一定距離以上動いた場合は候補作成をキャンセルし、通常の縦スクロールを優先するようにした。
- 長押し後のドラッグ中だけ preview を更新し、指を離した時点で候補時間として確定するようにした。
- mouse / pen 操作は従来通り、押した直後からドラッグ選択できる挙動を維持した。
- 待ち合わせタブ表示中は親画面の高さを `100dvh` に固定し、カレンダーの縦スクロールが親画面へ連鎖しないようにした。
- カレンダーのスクロールコンテナから `min-h-[520px]` を外し、`overscroll-y-contain` を付与して、日付ヘッダーが画面ヘッダーへ食い込んで見える状態を抑制した。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- 打診作成時の交換できる時間候補のドラッグ選択

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 軽い縦スワイプはカレンダーのスクロールとして扱う
- ✅ 長押し後のドラッグだけ候補時間作成として扱う
- ✅ カレンダー末尾から親画面へスクロールが連鎖しにくい構造へ変更
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` 通過

---

## イテレーション154.38：待ち合わせタブをカレンダー面へ寄せる

### 背景・問題意識

オーナーから、待ち合わせタブのカレンダーが枠の中に収まっているため、添付の Google Calendar 風画面のように「タブ内そのものがカレンダー画面」に見えてほしいという指摘があった。

「候補1の交換できる時間」「5/6〜5/12」「＋候補」などのヘッダー要素や、下部の「候補1の交換場所を設定する」ボタンは不要。場所未設定は下の別ボタンではなく、カレンダー上の候補時間ブロック自体が警告を出している状態にする。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 待ち合わせタブ内の白いカード枠、候補ヘッダー、週ラベル、＋候補ボタン、下部の時間・場所サマリーを削除した。
- カレンダーをタブ内で横幅いっぱいに表示し、Google Calendar 風に日付ヘッダーと時間グリッドが直接見えるレイアウトへ寄せた。
- 日付ヘッダーは曜日 + 大きい日付の2段表示に変更した。
- 候補時間ブロックは、場所設定済みなら紫、場所未設定ならオレンジの警告ブロックとして表示するようにした。
- 場所未設定ブロックには「⚠ 場所を設定」と表示し、カレンダー上から直接タップできる導線にした。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`（Google Fonts 取得のためネットワーク権限付きで通過）

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ カレンダーがカード内パーツではなく、待ち合わせタブの主画面として見える構成へ変更
- ✅ 不要な「候補N」「週ラベル」「＋候補」「下部場所ボタン」を削除
- ✅ 場所未設定状態はカレンダー上の候補ブロックで警告表示
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.37：待ち合わせカレンダーの週固定と場所導線改善

### 背景・問題意識

オーナーから、C-0 待ち合わせタブの週カレンダーについて、候補時間を選ぶたびに表示週の左端が選択日へ変わってしまうのが不自然という指摘があった。

また、0〜24 時まで縦スクロールで見たい、週切り替えはカレンダー内の横スワイプにしたい、場所未設定の文言ではタップ導線と分かりにくい、ドラッグ後に自動で場所設定シートを出したい、カレンダー日付をヘッダーに固定表示したいという要望があった。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- カレンダー表示週を active candidate の開始日に連動させるのをやめ、表示中の週を `calendarWeekStartKey` として固定管理するようにした。
- 候補時間を 5/19 などにドラッグしても、表示中の 5/17〜5/23 週は自動で動かないようにした。
- 週切り替えはカレンダー内の横スワイプで前週／翌週へ移動するようにした。
- カレンダーの表示範囲を 0:00〜24:00 に広げ、カレンダー内の縦スクロールで全時間帯を見られるようにした。
- 日付ヘッダーをカレンダー内で sticky 表示し、縦スクロール中も日付が固定されるようにした。
- 待ち合わせタブ上部の「交換できる候補」カード一覧を削除した。
- 場所未設定ボタンの文言を「候補Nの交換場所の候補を設定する」に変更した。
- 時間帯をドラッグ選択した直後に、場所設定シートを自動表示するようにした。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- 打診作成時の時間・場所候補入力体験

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`（Google Fonts 取得のためネットワーク権限付きで通過）

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 候補時間選択で表示週が勝手に変わらない
- ✅ 週切り替えはカレンダー内の横スワイプに寄せた
- ✅ 0:00〜24:00 の時間帯をカレンダー内縦スクロールで確認できる
- ✅ 日付ヘッダーは縦スクロール時も固定表示
- ✅ 時間選択後に場所設定シートが自動で開く
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.36：交換候補を週カレンダー選択へ変更

### 背景・問題意識

オーナーから、C-0 の交換できる時間を Google Calendar のように週表示上でドラッグして設定したいという要望があった。

また、時間を入れた後は「場所未設定」として明示し、そこをタップして地図設定ポップアップを開く設計にしたい、場所未設定のままでは打診できないようにしたいという指示があった。

あわせて、打診送信時に `Could not find the 'meetup_candidates' column of 'proposals' in the schema cache` が出て進めない問題、マイ在庫のキープ／譲り済み説明バナー、個別募集一覧の設定感も指摘された。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 待ち合わせタブの時間入力を、プリセット／日時 input から週カレンダー型 UI へ変更した。
- 10:00〜22:00 の 7 日表示で、ドラッグした範囲を 15 分単位の交換できる時間として設定できるようにした。
- 時間を変更した候補は場所を空に戻し、「場所未設定」として表示するようにした。
- 場所未設定部分をタップすると、下から地図設定シートが開き、検索・現在地・地図ピンで場所を設定できるようにした。
- 場所未設定の候補が残っている場合は、送信確認へ進めないようにした。

#### `web/src/app/propose/actions.ts`
- `meetup_candidates` 列が schema cache に存在しない場合、既存の主候補列（`meetup_start_at` / `meetup_end_at` / `meetup_place_name` / `meetup_lat` / `meetup_lng`）だけで insert / update を retry するフォールバックを追加した。
- migration 反映前や schema cache 更新前でも、少なくとも主候補で打診送信・再打診できるようにした。

#### `web/src/app/propose/[partnerId]/page.tsx`
- 再打診プリフィル時、`meetup_candidates` を含む select が schema cache エラーになった場合は、既存主候補列だけで再取得するようにした。

#### `web/src/app/proposals/[id]/page.tsx`
- 打診詳細取得時も `meetup_candidates` の schema cache エラー時に fallback select を行い、詳細画面が落ちないようにした。

#### `web/src/app/inventory/InventoryView.tsx`
- 「自分用キープ」「過去に譲った」タブ上部の説明バナーを削除した。

#### `web/src/app/listings/ListingsView.tsx`
- 個別募集一覧の「編集」「一時停止／再開」「削除」を下部ボタン列からヘッダー右端のアイコンへ移動した。
- active カードは少しだけ影と淡い ring を足し、個別募集の関係図そのものが主役に見えるようにした。

### 影響範囲

- `/propose/[partnerId]` C-0 待ち合わせタブ
- `/proposals/[id]` 打診詳細
- `/inventory` マイ在庫タブ表示
- `/listings` 個別募集一覧
- DB スキーマ自体は変更なし。`meetup_candidates` 未反映環境への runtime fallback のみ追加

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx' src/app/propose/actions.ts 'src/app/propose/[partnerId]/page.tsx' 'src/app/proposals/[id]/page.tsx' src/app/inventory/InventoryView.tsx src/app/listings/ListingsView.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`（Google Fonts 取得のためネットワーク権限付きで通過）

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- `web/src/app/propose/actions.ts`
- `web/src/app/propose/[partnerId]/page.tsx`
- `web/src/app/proposals/[id]/page.tsx`
- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/listings/ListingsView.tsx`

### セルフレビュー結果

- ✅ 時間指定は 15 分単位のドラッグ選択になり、入力フォーム中心の体験からカレンダー操作へ寄せた
- ✅ 時間変更後は場所未設定に戻し、場所未設定の候補がある状態では次へ進めない
- ✅ `meetup_candidates` の schema cache エラー時も主候補列で保存・読込できるため、打診送信が止まらない
- ✅ マイ在庫のキープ／譲り済み説明バナーを削除
- ✅ 個別募集一覧の操作をアイコン化し、ヘッダー右端へ集約
- ✅ 新しい状態名・用語・DB migration は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` / `notes/05_data_model.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.35：関係図候補整理と打診完了演出

### 背景・問題意識

オーナーから、推し設定で登録のたびにグループ表示順が前後して混乱すること、関係図で条件外の選択肢が個別にグレーアウトされて悲しく見えること、打診後の完了体験が淡泊なこと、マイ在庫編集でステータスを変えられることへの懸念が出た。

また、管理者画面については先に「何を載せるべきか」「どうログインさせるべきか」を設計整理する段階とした。

### 変更内容

#### `web/src/app/profile/actions.ts`
- 箱推しから個別メンバー追加へ切り替える際、親グループの既存 priority を保持するようにした。
- 承認待ちメンバー追加リクエストでも同じ priority 保持ロジックを使い、登録のたびにグループ順が動かないようにした。
- 最後のメンバー削除で箱推し行へ戻す場合も、削除対象行の priority を引き継ぐようにした。

#### `web/src/app/profile/oshi/page.tsx`
- 推しグループ集約時に group priority を保持し、`priority -> groupName` の安定順で表示するようにした。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- 楽観更新で追加する master / request グループにも priority を付け、サーバー再読込前後で並び順が崩れにくいようにした。

#### `web/src/components/home/MatchDetailModal.tsx`
- 関係図上部の説明文を削除した。
- 条件に合う wish 候補をすべて上へ集め、条件外の選択肢は最下部の「＋ 条件外の選択肢」内へまとめた。
- 条件外リストは畳んだ状態を初期表示にし、必要な時だけ展開できるようにした。

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 通常の打診送信後にホームへ即遷移せず、「打診が完了しました」画面を表示するようにした。
- 完了画面には華やかなチェック演出と、「まだ他に探す」「打診一覧に飛ぶ」の2導線を配置した。

#### `web/src/app/inventory/[id]/EditForm.tsx`
- マイ在庫編集画面からステータス更新セクションを削除した。
- 在庫の状態変更は一覧側の専用導線に寄せ、編集画面ではグッズ情報編集に集中させる。

### 管理者画面の初期設計案

- 管理者入口は `/admin` とし、通常ユーザー画面とはナビゲーションを分離する。
- ログインは「隠しURL」ではなく、Supabase Auth の通常ログインに加えて `admin_users` または `users.role = 'admin'` のサーバー側チェックで制御する。
- 管理者操作は RLS / server action の両方で admin 判定し、すべて監査ログへ `actor / action / target / before / after / reason` を残す。
- 初期搭載機能は、推し・メンバー追加リクエスト審査、通報・異議申し立て対応、ユーザー停止・警告、マスタ管理、取引ステータス監視、運営お知らせ、基本指標ダッシュボードを優先する。
- UI はスマホ用ボトムナビではなく、PC 向けの左サイドバー + 検索 + 審査キュー + テーブル中心にする。
- 破壊的操作は理由入力必須、確認モーダル必須、取り消し可能な soft action を優先する。

### 影響範囲

- `/profile/oshi` 推し設定
- ホームから開く関係図モーダル
- `/propose/[partnerId]` 打診送信後
- `/inventory/[id]` マイ在庫編集
- 管理者画面は設計案のみで、実装は未着手

### 確認方法

- `npx eslint src/app/profile/actions.ts src/app/profile/oshi/page.tsx src/app/profile/oshi/OshiEditView.tsx src/components/home/MatchDetailModal.tsx 'src/app/propose/[partnerId]/ProposeFlow.tsx' 'src/app/inventory/[id]/EditForm.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`（Google Fonts 取得のためネットワーク権限付きで通過）

### 関連ファイル

- `web/src/app/profile/actions.ts`
- `web/src/app/profile/oshi/page.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `web/src/components/home/MatchDetailModal.tsx`
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- `web/src/app/inventory/[id]/EditForm.tsx`

### セルフレビュー結果

- ✅ 推し設定の表示順は priority を基準に安定化し、追加・削除・仮登録の楽観更新にも反映した
- ✅ 関係図の条件外候補は下部の単一アーカイブに集約し、条件合致候補を先に見せる設計へ変更した
- ✅ 打診完了後の体験に完了演出と次アクション導線を追加した
- ✅ マイ在庫編集からステータス変更 UI を削除し、意図しない状態変更のリスクを下げた
- ✅ 新しい取引状態・在庫状態・用語は追加していないため `notes/09_state_machines.md` / `notes/10_glossary.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過

---

## イテレーション154.34：待ち合わせを交換できる候補へ刷新

### 背景・問題意識

オーナーから、C-0 の待ち合わせタブが「なんの時間設定？なんの場所設定？」と見えやすく、分単位指定も重いという相談があった。

打診段階では合流を確定するよりも、「交換できる時間・場所の候補」を相手に提示する方が自然。今日このあと／日時指定を軽く選び、必要なら複数候補を送れる設計へ変更する。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 待ち合わせタブを「交換できる候補」UIへ刷新し、最大3件の候補を追加・削除・切替できるようにした。
- 候補ごとに「今日このあと」「日時を指定」を切り替え、30分/1時間/2時間/今日中、今日/明日/昼/夕方/夜のプリセットを用意した。
- 日時入力は JST 前提で ISO へ変換し、確認画面では候補1を主候補として表示するようにした。
- 複数候補の場所を一括コピーできるようにした。

#### `web/src/app/propose/actions.ts`
- `meetupCandidates` を create / revise の入力として受け取り、最大3件・時間順序・場所・座標を検証するようにした。
- 候補1を既存の `meetup_start_at` / `meetup_end_at` / `meetup_place_name` / `meetup_lat` / `meetup_lng` へミラーし、全候補を `meetup_candidates` へ保存するようにした。
- C-0 確認画面の「メッセージ（任意）」表記と合わせ、空メッセージでも打診送信できるようにした。

#### `web/src/app/propose/[partnerId]/page.tsx`
- 再打診時に `meetup_candidates` を読み込み、C-0 の候補 UI へ復元するようにした。
- 既存の単一待ち合わせデータやクエリ override との互換を維持した。

#### `web/src/app/proposals/[id]/page.tsx`
- 打診詳細で `meetup_candidates` を読み込み、旧データは既存 `meetup_*` 5列から候補1として復元するようにした。

#### `web/src/app/proposals/[id]/ProposalDetailView.tsx`
- 受信側の提案内容カードで「交換できる候補」を候補リストとして表示するようにした。
- 候補1を主候補として強調し、地図は主候補の座標を表示するようにした。
- 表示時刻を Asia/Tokyo 基準で整えた。

#### `supabase/migrations/20260506100000_add_proposal_meetup_candidates.sql`
- `proposals.meetup_candidates jsonb not null default []` を追加した。
- 既存レコードは `meetup_*` 5列から候補1へバックフィルするようにした。
- JSON 配列かつ最大3件の CHECK 制約を追加した。

#### `notes/05_data_model.md`
- `proposals.meetup_candidates` と候補1ミラー方針を追記した。

#### `notes/10_glossary.md`
- 「交換できる候補」を用語として追加した。

#### `notes/13_api_spec.md`
- proposal 作成・修正 API の待ち合わせ入力を `meetup_candidates` 方式へ更新した。

### 影響範囲

- `/propose/[partnerId]` 提示物選択 C-0 待ち合わせタブ
- `/proposals/[id]` 打診詳細の受信・送信表示
- `proposals` DB スキーマ
- 再打診時の待ち合わせ復元

### 確認方法

- `npx eslint src/app/propose/actions.ts 'src/app/propose/[partnerId]/page.tsx' 'src/app/propose/[partnerId]/ProposeFlow.tsx' 'src/app/proposals/[id]/page.tsx' 'src/app/proposals/[id]/ProposalDetailView.tsx'`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`（sandbox 内では Google Fonts 取得失敗。ネットワーク権限付き再実行は自動レビューがタイムアウト）

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- `web/src/app/propose/[partnerId]/page.tsx`
- `web/src/app/propose/actions.ts`
- `web/src/app/proposals/[id]/page.tsx`
- `web/src/app/proposals/[id]/ProposalDetailView.tsx`
- `supabase/migrations/20260506100000_add_proposal_meetup_candidates.sql`
- `notes/05_data_model.md`
- `notes/10_glossary.md`
- `notes/13_api_spec.md`

### セルフレビュー結果

- ✅ 「今日このあと」と「日時を指定」の入口を分け、分単位の細かい操作をプリセット中心へ寄せた
- ✅ 複数の交換できる候補を保存・再編集・受信側表示まで接続した
- ✅ 候補1を既存 `meetup_*` 列へミラーするため、旧画面や取引チャットの単一待ち合わせ参照と互換
- ✅ メッセージ任意の UI 表記と server action のバリデーションを揃えた
- ✅ 新しい proposal 状態は追加していないため `notes/09_state_machines.md` は更新不要
- ✅ 対象ファイルの `eslint` / `tsc --noEmit` / `git diff --check` 通過
- ⚠️ `npm run build` は Google Fonts の外部取得で sandbox 失敗。権限付き再実行は自動レビューがタイムアウトしたため未完了

---

## イテレーション154.33：追加リクエストを推し仮登録へ反映

### 背景・問題意識

オーナーから、推し設定画面で追加リクエストを送った推しが、そのまま推し設定として仮登録されてほしいという指摘があった。

また、仮登録中の推しグループに対しても、メンバー／キャラクターを追加リクエストとして登録できる必要がある。

### 変更内容

#### `web/src/app/profile/actions.ts`
- `requestOshiAndAddToProfile` を追加し、`oshi_requests` 作成後に `user_oshi.oshi_request_id` へ即時仮登録するようにした。
- `requestCharacterAndAddToProfile` を追加し、既存 master グループだけでなく仮登録中の `oshi_request_id` にも `character_requests` を紐付け、`user_oshi.character_request_id` として即時仮登録するようにした。
- 推しグループ削除・推しメンバー削除を `group_id` と `oshi_request_id` の両方に対応させた。

#### `web/src/app/profile/oshi/page.tsx`
- `user_oshi` の `oshi_request` / `character_request` relation を読み込み、承認待ちの推し・メンバーも推し設定カードへ集約するようにした。
- master グループと仮登録グループを `source` で区別し、仮登録グループでは master メンバー候補を出さず、追加リクエスト導線を残すようにした。

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- 推し追加リクエスト送信後、画面上に即「承認待ち」グループとして表示するようにした。
- メンバー追加リクエスト送信後、該当グループ内に「承認待ち」メンバーとして即表示するようにした。
- 仮登録中の推しグループからもメンバー追加リクエストモーダルを開けるようにした。

#### `web/src/app/profile/page.tsx`
- プロフ画面の推し要約でも、仮登録中の推し・メンバー名を拾えるようにした。

#### `notes/05_data_model.md`
- `user_oshi` の `oshi_request_id` / `character_request_id` を明記し、仮登録の扱いを補足。

#### `notes/10_glossary.md`
- 「追加リクエスト」「仮登録」「承認待ち」を用語として追加。

### 影響範囲

- `/profile/oshi` 推し設定画面
- 推し追加リクエスト / メンバー追加リクエストの送信後 UX
- `/profile` プロフ画面の推し要約
- `user_oshi` の request id 利用方針

### 確認方法

- `npx eslint src/app/profile/actions.ts src/app/profile/page.tsx src/app/profile/oshi/page.tsx src/app/profile/oshi/OshiEditView.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/actions.ts`
- `web/src/app/profile/page.tsx`
- `web/src/app/profile/oshi/page.tsx`
- `web/src/app/profile/oshi/OshiEditView.tsx`
- `notes/05_data_model.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 推し追加リクエストは `oshi_requests` 作成と同時に `user_oshi.oshi_request_id` へ仮登録される
- ✅ メンバー追加リクエストは master グループ / 仮登録グループの両方に紐付けられる
- ✅ 仮登録中の推し・メンバーは推し設定画面上で「承認待ち」として識別できる
- ✅ 新しい状態名は追加していないため `notes/09_state_machines.md` は更新不要
- ✅ `eslint` / `tsc --noEmit` / `git diff --check` / `npm run build` 通過（build は Google Fonts 取得のためネットワーク許可付きで再実行）

---

## イテレーション154.32：関係図経由の提示物選択を待ち合わせ起点へ

### 背景・問題意識

オーナーから、関係図経由で提示物の選択へ進んだ場合、すでに提示物は関係図で選んでいるため、「私が出す」「受け取る」ではなく、そのまま「待ち合わせ」タブから始めたいという指摘があった。

また、提示物選択へ進む直前に一瞬ホーム画面が見える挙動、`wish一致` の意味が伝わりにくい表記、各タブ上部の案内文が重い点も合わせて改善する。

### 変更内容

#### `web/src/components/home/MatchDetailModal.tsx`
- 関係図から生成する `/propose/[partnerId]` URL に `tab=meetup` を付与。
- 通常の譲 × wish 関係から打診へ進む場合も、モーダル内の導線では `tab=meetup` を付与するようにした。

#### `web/src/components/home/HomeView.tsx`
- 関係図からルート遷移する時は、モーダルを先に閉じず、URL の履歴整理だけ行うように変更。
- これにより、提示物選択へ進む前にホーム画面が一瞬見える挙動を抑える。

#### `web/src/app/propose/[partnerId]/page.tsx`
- `tab` query を読み取り、`mine` / `theirs` / `meetup` の初期タブとして `ProposeFlow` へ渡すようにした。

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- `initialTab` prop を追加し、関係図経由では「待ち合わせ」タブから開始できるようにした。
- `★ wish 一致` 表記を廃止し、「私が出す」では「相手がほしいものかも？」、「受け取る」では「私がほしいものかも？」に変更。
- 「私が出す」「受け取る」「待ち合わせ」各タブ上部の案内文を削除。
- 待ち合わせ入力のラベルを「交換できる開始」「交換できる終了」「交換できる場所」に変更。
- iter138 以前の未使用メッセージテンプレ関数と未使用ステップコンポーネントを整理。

### 影響範囲

- `/` ホーム画面の関係図モーダルから打診へ進む導線
- `/propose/[partnerId]` 提示物選択画面
- 提示物選択の wish ヒット表示

### 確認方法

- `npx eslint src/components/home/HomeView.tsx src/components/home/MatchDetailModal.tsx src/app/propose/[partnerId]/page.tsx src/app/propose/[partnerId]/ProposeFlow.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/MatchDetailModal.tsx`
- `web/src/app/propose/[partnerId]/page.tsx`
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 関係図経由の打診 URL は `tab=meetup` を持ち、提示物選択画面は待ち合わせタブから始まる
- ✅ 遷移時に関係図モーダルを先に消さないため、ホーム画面の瞬間表示を抑制
- ✅ `wish一致` は画面文言から除去
- ✅ 状態名・DB スキーマ・公式用語の追加はないため `notes/09_state_machines.md`、`notes/10_glossary.md`、`notes/05_data_model.md` は更新不要
- ⚠️ `npm run build` は Google Fonts の woff2 取得タイムアウトで失敗。`eslint` / `tsc --noEmit` / `git diff --check` は通過

---

## イテレーション154.31：推し追加モーダルを中央固定化

### 背景・問題意識

オーナーから、推し設定の「登録済みの推しを追加」ポップアップで、自由検索欄に文字を入れるとヒット件数に応じてフォーム全体の縦幅が変わり、使いづらいという指摘があった。

検索結果が増減しても操作面が揺れないよう、フォーム自体は画面中央に固定し、結果リストだけを内部スクロールさせる。

### 変更内容

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- `MasterSelectModal` をボトムシート型から画面中央の固定モーダルに変更。
- モーダル本体に一定の高さを持たせ、検索結果の件数で外枠が伸び縮みしないようにした。
- 検索バー・ジャンルタブ・ヘッダーは固定領域に置き、候補リストだけ `overflow-y-auto` でスクロールする構成にした。
- ボトムシートのつまみを外し、中央モーダルとして自然に見える角丸・影へ調整した。

### 影響範囲

- `/profile/oshi` 推し設定画面
- 登録済みマスタから推しを追加するポップアップ

### 確認方法

- `npx eslint src/app/profile/oshi/OshiEditView.tsx src/components/home/HomeView.tsx src/components/home/MatchDetailModal.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/oshi/OshiEditView.tsx`

### セルフレビュー結果

- ✅ 検索結果件数によってモーダル外形が変わらない
- ✅ 候補一覧だけが内部スクロールし、検索欄・タブ・閉じるボタンは安定して操作できる
- ✅ 新しい state / DB フィールド / 公式用語は追加していないため `notes/09_state_machines.md`、`notes/10_glossary.md`、`notes/05_data_model.md` は更新不要

---

## イテレーション154.30：関係図の選択元強調と不可候補折りたたみ

### 背景・問題意識

オーナーから、ホーム画面のマッチングパネルを押して関係図へ進んだ時、選んだ画像の候補が複数候補の中で目立つようにしたいという要望があった。

また、自分が交換できなさそうな候補が最初からグレーアウト表示されると体験が暗くなるため、初期状態では折りたたみ、「＋」で見られる設計にする。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホームでタップした候補の `item.id` を関係図モーダルへ渡すようにした。

#### `web/src/components/home/MatchDetailModal.tsx`
- タップ元の候補 ID を `highlightedItemId` として受け取り、候補サムネ・譲サムネ・通常マッチ要約のサムネを淡いピンクのリングで強調。
- 選択元候補が関係図内の候補に含まれる場合、初期選択にも反映して、ユーザーが押した画像と遷移先の文脈がつながるようにした。
- 候補なし wish と未一致の譲候補は初期表示から折りたたみ、「＋ 交換できない候補」で展開するようにした。
- OR 条件の譲候補では、タップ元の譲が含まれる場合にその候補を初期選択するようにした。

### 影響範囲

- `/` ホーム画面からの関係図モーダル
- 個別募集マッチ / 通常の譲 × wish マッチの候補表示

### 確認方法

- `npx eslint src/app/profile/oshi/OshiEditView.tsx src/components/home/HomeView.tsx src/components/home/MatchDetailModal.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/MatchDetailModal.tsx`

### セルフレビュー結果

- ✅ ホームで選んだ画像の候補が関係図内で視覚的に追える
- ✅ 交換できない候補は初期表示から外れ、必要時だけ展開できる
- ✅ 既存の関係図・スワイププレビュー構造を流用し、DB スキーマ変更なし
- ✅ 新しい state / 公式用語は追加していないため `notes/09_state_machines.md`、`notes/10_glossary.md`、`notes/05_data_model.md` は更新不要

---

## イテレーション154.29：推し設定にマスタ検索追加モーダルを導入

### 背景・問題意識

オーナーから、「＋ 登録済みの推しを追加（グループ・作品）」がオンボーディングの推し登録画面へ遷移してしまうため、推し設定の文脈で完結するよう抜本的に変えたいという指摘があった。

登録済みマスタの追加は、オンボーディング画面を流用せず、推し設定内で自由検索・ジャンルタブ・未ヒット時の追加リクエストまで一連で扱える設計にする。

### 変更内容

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- 「登録済みの推しを追加」ボタンをページ遷移から画面内モーダル起動に変更。
- モーダル上部に自由検索バーを配置し、入力に応じてリアルタイムでマスタ候補を絞り込むようにした。
- 「すべて」+ `genres_master` のタブを横並びで表示し、K-POP / 2.5次元 / アニメ / ゲームなどのジャンルごとに候補を切り替えられるようにした。
- モーダル右上に「追加リクエスト」ボタンを追加し、検索文字列があればその名前を引き継いで追加リクエストモーダルを開くようにした。
- 検索結果が 0 件の場合、該当名で追加リクエストへ進める空状態を追加。
- マスタ候補を選択したら、推し設定画面に即反映しつつ `addOshiGroup` で保存するようにした。

#### `web/src/app/profile/oshi/page.tsx`
- 推し設定ページ側で `groups_master` と `genres_master`、関連 `characters_master` を取得し、マスタ選択モーダルへ渡すようにした。

#### `web/src/app/profile/actions.ts`
- 登録済みマスタを箱推しとして追加する `addOshiGroup` server action を追加。
- 既に登録済みの group は重複追加せず、未登録の場合はユーザー内 priority の末尾へ追加する。

### 影響範囲

- `/profile/oshi` 推し設定画面
- 登録済みマスタからの推し追加
- 推し追加リクエストへの導線

### 確認方法

- `npx eslint src/app/profile/oshi/OshiEditView.tsx src/app/profile/oshi/page.tsx src/app/profile/actions.ts src/app/onboarding/oshi/OshiForm.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/oshi/OshiEditView.tsx`
- `web/src/app/profile/oshi/page.tsx`
- `web/src/app/profile/actions.ts`
- `web/src/app/onboarding/oshi/OshiForm.tsx`

### セルフレビュー結果

- ✅ 登録済みマスタ追加はオンボーディングへ遷移せず推し設定内で完結
- ✅ 自由検索・ジャンルタブ・未ヒット時追加リクエストの導線を実装
- ✅ 追加リクエストは既存の `saveOshiRequest` を流用し、検索文字列の引き継ぎに対応
- ✅ `user_oshi` への追加は既存スキーマに沿った `kind=box` 追加のため DB スキーマ変更なし
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル構造変更なしのため更新不要

---

## イテレーション154.28：推し追加リクエストを画面内モーダル化

### 背景・問題意識

オーナーから、推し設定の追加リクエスト導線がオンボーディングの推しグループ設定へ流れてしまい、プロフィール編集文脈から外れるという指摘があった。

推し設定からの追加リクエストは、登録済みマスタを選ぶ導線とは分け、推し設定画面のまま必要情報を入力できるポップアップとして完結させる。メンバー追加リクエストも同様に、オンボーディングのメンバーリクエスト画面へ遷移させない。

### 変更内容

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- 推し追加リクエスト / メンバー追加リクエスト用の画面内モーダルを追加。
- 推し追加リクエストは名前・ジャンル・種類・メモを入力し、既存の `saveOshiRequest` server action で送信するようにした。
- メンバー追加リクエストは追加先グループを表示し、名前・メモを入力して `saveCharacterRequest` で送信するようにした。
- 既存マスタから推しを追加する導線は残しつつ、「マスタに無い推しを追加リクエスト」を別ボタンとして明示した。
- グループカード内の「マスタに無いメンバーを追加リクエスト」はページ遷移ではなくモーダル起動に変更した。
- 送信成功後は推し設定画面上に完了メッセージを表示し、プロフィール側のキャッシュを更新する。

#### `web/src/app/profile/oshi/page.tsx`
- 推し追加リクエストモーダルで使う `genres_master` を推し設定ページ側で取得して渡すようにした。

#### `web/src/app/onboarding/oshi/OshiForm.tsx`
- プロフ編集から `return=profile` で入った場合、追加リクエスト枠はオンボーディング内のリクエストページではなく `/profile/oshi?request=oshi` へ戻し、推し設定画面内モーダルを開くようにした。

### 影響範囲

- `/profile/oshi` 推し設定画面
- `/onboarding/oshi?return=profile` からの追加リクエスト導線
- `oshi_requests` / `character_requests` への登録処理

### 確認方法

- `npx eslint src/app/profile/oshi/OshiEditView.tsx src/app/profile/oshi/page.tsx src/app/onboarding/oshi/OshiForm.tsx`
- `npx tsc --noEmit`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/oshi/OshiEditView.tsx`
- `web/src/app/profile/oshi/page.tsx`
- `web/src/app/onboarding/oshi/OshiForm.tsx`
- `web/src/app/onboarding/actions.ts`

### セルフレビュー結果

- ✅ 推し設定からの推し追加リクエストは画面内モーダルで完結
- ✅ 推し設定からのメンバー追加リクエストも画面内モーダルで完結
- ✅ 登録処理は既存の `saveOshiRequest` / `saveCharacterRequest` を流用し、DB スキーマ変更なし
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.27：画像読み込み後にカード入場を開始

### 背景・問題意識

オーナーから、ホーム画面・マイ在庫・Wish で画面自体は早く表示される一方、肝心の画像ロードが終わる前に各パネルが出てしまい不恰好に見えるという指摘があった。

ただし、現在のパネル表示速度は気に入っているため、アニメーション自体を遅くするのではなく、画像の読み込み・decode が終わったカードから今の速い入場アニメーションを始める設計にする。

### 変更内容

#### `web/src/components/common/useImageReady.ts`
- 画像 URL を `Image()` で事前読み込みし、可能なら `decode()` まで待つ hook を追加。
- 読み込み済み URL は session 内キャッシュし、同じ画像を再表示する時は即表示できるようにした。
- 画像なし / 読み込み失敗時はカードを隠し続けないよう ready 扱いにした。

#### `web/src/components/home/HomeView.tsx`
- ホームのマッチ候補パネルは、候補画像の ready 後に `animate-home-shelf-panel-in` を付与するようにした。
- ready 前は透明かつ非タップにし、画像がないカードは従来通り即表示。

#### `web/src/app/inventory/InventoryView.tsx`
- マイ在庫の各カードを `InventoryCardPanel` に分離。
- 画像 ready 後に従来の `animate-panel-pop` を走らせ、削除フェードアウトとの組み合わせは維持。

#### `web/src/app/wishes/WishView.tsx`
- Wish の各カードを `WishCardPanel` に分離。
- 画像 ready 後に従来の `animate-panel-pop` を走らせ、削除フェードアウトとの組み合わせは維持。

#### `web/src/app/inventory/ItemCard.tsx`
#### `web/src/app/wishes/WishView.tsx`
- 実画像に `decoding="async"` を付け、プリロード後の描画を安定させた。

### 影響範囲

- `/` ホーム画面のマッチ候補パネル
- `/inventory` マイ在庫グリッド
- `/wishes` Wish グリッド

### 確認方法

- `npx eslint src/components/common/useImageReady.ts src/components/home/HomeView.tsx src/app/inventory/InventoryView.tsx src/app/inventory/ItemCard.tsx src/app/wishes/WishView.tsx`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/components/common/useImageReady.ts`
- `web/src/components/home/HomeView.tsx`
- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/inventory/ItemCard.tsx`
- `web/src/app/wishes/WishView.tsx`

### セルフレビュー結果

- ✅ 既存のパネル入場アニメーション速度・stagger 間隔は維持
- ✅ 画像ありカードは画像 ready 後に表示開始
- ✅ 画像なしカード・画像エラーは表示が詰まらない
- ✅ 削除フェードアウト / reflow 挙動は維持
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.26：プロフ画面から設定導線を削除

### 背景・問題意識

オーナーから、プロフ画面の「設定」は不要であり、その遷移先でできることはプロフ画面から直接できるという指摘があった。

プロフィール編集・推し設定・通知設定・ヘルプは既にプロフ画面に直接導線があるため、重複する設定トップへの入口を減らし、プロフ画面を軽くする。

### 変更内容

#### `web/src/app/profile/ProfileView.tsx`
- 「設定・サポート」セクションから「設定」行を削除。
- セクション名を「通知・サポート」に変更し、残る導線の意味に合わせた。
- 「通知設定」「ヘルプ・FAQ」「ログアウト」は維持。

#### `Megrum/hub-screens.jsx`
- プロフハブのモックアップから「設定」行を削除。
- セクション名を「通知・サポート」に変更。

#### `notes/11_screen_inventory.md`
- `PRO-hub` の説明を「活動＋設定」から「活動＋通知・サポート」へ更新。

### 影響範囲

- `/profile` プロフ画面
- プロフハブ mockup
- 画面マトリクスの `PRO-hub` 説明

### 確認方法

- `npx eslint src/app/profile/ProfileView.tsx`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/ProfileView.tsx`
- `Megrum/hub-screens.jsx`
- `notes/11_screen_inventory.md`

### セルフレビュー結果

- ✅ プロフ画面の重複する「設定」行を削除
- ✅ 通知設定・ヘルプ導線は維持
- ✅ セクション名を実際の残り導線に合わせて変更
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.25：推し設定の連続追加と戻り先を改善

### 背景・問題意識

オーナーから、推し設定でメンバーを登録するたびにローディング状態になり、その間ほかのメンバーを推せないためユーザー体験が損なわれるという指摘があった。

また、推し設定から追加グループをリクエストするとオンボーディング側の画面に入り、進めると新規登録後の welcome 画面へ到達してしまうため、追加リクエスト後は元の推し設定へ戻る設計にする必要がある。

### 変更内容

#### `web/src/app/profile/oshi/OshiEditView.tsx`
- メンバー追加・削除・グループ削除を optimistic UI 化し、タップ直後に画面上のチップ/候補を更新するようにした。
- DB 保存は内部キューで順番に実行し、複数メンバーを続けて押しても UI を止めないようにした。
- 保存失敗時は optimistic 更新を巻き戻し、画面内エラーで知らせるようにした。
- `useTransition` の単一 `pending` によるグループ内一括 disabled を撤去した。

#### `web/src/app/onboarding/oshi/page.tsx`
- `?return=profile` で開いた場合はオンボーディング進捗ドットを出さず、プロフィール編集からの追加画面として見えるようにした。

#### `web/src/app/onboarding/oshi/OshiForm.tsx`
- profile 戻りの時は追加リクエストリンクにも `return=profile` を引き継ぐようにした。
- profile 戻りの時の保存ボタン文言を「この内容で保存」に変更し、通常 onboarding の「次へ」と分けた。

#### `web/src/app/onboarding/oshi/request/page.tsx`
#### `web/src/app/onboarding/oshi/request/RequestForm.tsx`
- グループ追加リクエスト画面で `return=profile` を受け取り、送信後は `/profile/oshi` へ戻るようにした。
- 戻るボタンは `/onboarding/oshi?return=profile` に戻し、途中で戻った場合も onboarding 完了フローへ流れないようにした。

#### `web/src/app/onboarding/actions.ts`
- 推し保存・推し追加リクエスト・メンバー追加リクエスト後に `/profile/oshi` を revalidate するようにした。

### 影響範囲

- `/profile/oshi` 推し設定編集
- `/onboarding/oshi?return=profile` プロフィールからの推し追加
- `/onboarding/oshi/request?return=profile` プロフィールからの推しグループ追加リクエスト
- `/onboarding/members/request?return=profile` プロフィールからのメンバー追加リクエスト

### 確認方法

- `npx eslint src/app/profile/oshi/OshiEditView.tsx src/app/profile/oshi/page.tsx src/app/onboarding/oshi/page.tsx src/app/onboarding/oshi/OshiForm.tsx src/app/onboarding/oshi/request/page.tsx src/app/onboarding/oshi/request/RequestForm.tsx src/app/onboarding/members/request/page.tsx src/app/onboarding/members/request/RequestForm.tsx src/app/onboarding/actions.ts`
- `git diff --check`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/oshi/OshiEditView.tsx`
- `web/src/app/onboarding/oshi/page.tsx`
- `web/src/app/onboarding/oshi/OshiForm.tsx`
- `web/src/app/onboarding/oshi/request/page.tsx`
- `web/src/app/onboarding/oshi/request/RequestForm.tsx`
- `web/src/app/onboarding/actions.ts`

### セルフレビュー結果

- ✅ メンバー追加時に同じグループ内の他候補が disabled にならない
- ✅ 連続タップ時も保存処理は内部キューで順番に実行し、priority 競合を避ける
- ✅ 追加リクエストの `return=profile` が途切れず、welcome 画面へ流れない
- ✅ profile 戻りの推し追加では onboarding 進捗 UI を表示しない
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.24：プロフ・取引詳細の右スライド遷移を追加

### 背景・問題意識

オーナーから、プロフ画面で「プロフィール編集」「推し設定」などのボタンを押した時、ホーム画面で個別募集マッチの関係図が右から出てくるのと同じように、遷移先画面が画面右からひゅんっとスライドして登場してほしいという要望があった。

また、取引一覧画面で各パネルを押した時の遷移先にも同じ挙動を適用し、遷移先の戻るボタンで前画面に戻れるようにする必要がある。

### 変更内容

#### `web/src/app/globals.css`
- 通常 route 用の `routeSlideInFromRight` / `.animate-route-slide-in-right` を追加。
- ホームのマッチ詳細に近い、右画面外から少しだけ行き過ぎて止まる 420ms の遷移にした。
- `prefers-reduced-motion` ではアニメーションを無効化。

#### プロフ導線の遷移先
- `/profile/edit`、`/profile/oshi`、`/schedules`、`/settings`、`/settings/notifications`、`/help`、`/users/[id]/evaluations` の main に `.animate-route-slide-in-right` を付与。
- `/schedules` は独自ヘッダーから `HeaderBack` に変更し、プロフィールから来た時に戻るボタンで前画面へ戻れるようにした。

#### 取引一覧パネルの遷移先
- `/transactions/[id]`、`/proposals/[id]`、`/disputes/[id]` の main に `.animate-route-slide-in-right` を付与。
- 既存の `HeaderBack` は `router.back()` を使うため、取引一覧から入った場合は戻るボタンで一覧へ戻る挙動を維持。

### 影響範囲

- `/profile` から開くプロフィール編集・推し設定・スケジュール・設定・通知設定・ヘルプ・評価一覧
- `/transactions` から開く取引チャット・打診詳細・申告ステータス
- 通常 route 遷移の初期表示アニメーション

### 確認方法

- `npx eslint ...`（対象ページ一式）
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/app/profile/edit/page.tsx`
- `web/src/app/profile/oshi/page.tsx`
- `web/src/app/schedules/page.tsx`
- `web/src/app/schedules/new/page.tsx`
- `web/src/app/schedules/[id]/page.tsx`
- `web/src/app/settings/page.tsx`
- `web/src/app/settings/notifications/page.tsx`
- `web/src/app/help/page.tsx`
- `web/src/app/users/[id]/evaluations/page.tsx`
- `web/src/app/transactions/[id]/page.tsx`
- `web/src/app/proposals/[id]/page.tsx`
- `web/src/app/disputes/[id]/page.tsx`

### セルフレビュー結果

- ✅ プロフ画面からの主要遷移先に右スライド登場を追加
- ✅ 取引一覧パネルからの主要遷移先に右スライド登場を追加
- ✅ スケジュール画面にも戻るボタンを追加し、`router.back()` の前画面復帰に統一
- ✅ `prefers-reduced-motion` ではアニメーションを無効化
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.23：マッチ詳細スワイプの画像暗転と候補上操作を改善

### 背景・問題意識

オーナーから、個別募集の関係図を横スワイプした後に、各グッズ画像が一瞬ローディングするように暗く見えること、また対象グッズを選択する候補ボタン上では横スワイプで画面を切り替えられないことが指摘された。

iter154.22 で横並びページング自体は自然になったが、写真ありサムネの読み込み待ち背景が濃色だったため、スワイプ後の再描画で暗い下地が一瞬見える。また、ジェスチャー開始対象から `button` を丸ごと除外していたため、候補グッズボタン上の横移動がページングに入らなかった。

### 変更内容

#### `web/src/components/home/MatchDetailModal.tsx`
- 写真ありサムネの読み込み待ち背景を濃色から `#fbf9fc` に変更し、暗いフラッシュが出ないようにした。
- グッズ写真は `loading="eager"` に変更し、現在・前・次の関係図に含まれる写真 URL を `Image()` で事前読み込みするようにした。
- スワイプ除外条件から `button` 全体を外し、候補グッズボタン上でも横スワイプできるようにした。
- 閉じる / 打診 / リセットなどの操作ボタンには `data-swipe-ignore="true"` を付け、意図しないページングを防ぐようにした。
- 候補ボタン上で横スワイプした場合は、その後の click を抑制し、スワイプと同時に候補選択が誤発火しないようにした。

### 影響範囲

- `/` ホーム / 個別募集マッチの関係図画面
- 関係図画面間の横スワイプ
- 関係図内の候補グッズ選択ボタン
- グッズ画像サムネイル表示

### 確認方法

- `npx eslint src/components/home/MatchDetailModal.tsx src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/MatchDetailModal.tsx`

### セルフレビュー結果

- ✅ 写真ありサムネの暗い読み込み待ち背景を撤去
- ✅ 前後ページの画像を事前読み込みし、スワイプ後の画像ちらつきを抑制
- ✅ 候補グッズボタン上の横スワイプでページ切り替え可能に変更
- ✅ 操作ボタンは `data-swipe-ignore` でスワイプ対象から除外
- ✅ 横スワイプ後の候補選択 click 誤発火を抑制
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.22：マッチ詳細を横並びページングへ変更

### 背景・問題意識

オーナーから、iter154.21 の指追従スワイプについて「ほとんど変わっていないようにみえます」「iPhone のホーム画面のスワイプのイメージ」と再指摘があった。

前回は現在の関係図 1 枚だけを横に動かしていたため、隣の画面そのものが指の動きに合わせて入ってくる感覚が弱かった。iPhone のホーム画面に近づけるには、現在・前・次の画面を横並びのページとして配置し、ドラッグ中に隣ページが実際に見える構造が必要。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 選択中の個別募集マッチ詳細に対して、前後の候補を `previousPage` / `nextPage` として `MatchDetailModal` に渡すようにした。
- 横スワイプで詳細を確定移動した後は `slideDirection="none"` にし、すでに見えている隣ページへ二重スライドしないようにした。
- 現在・前・次の詳細データ生成を `buildMatchDetailPage` に集約した。

#### `web/src/components/home/MatchDetailModal.tsx`
- `MatchDetailPageData` を追加し、隣接ページのプレビュー情報を受け取れるようにした。
- 現在の詳細シェルの左右に、前後の関係図画面を `left-[-100%]` / `left-full` で実配置した。
- ドラッグ中は現在画面だけでなく、左右に置いた実際の隣画面も一緒に動くため、iPhone のホーム画面のように隣ページが見えながら移動する。
- 隣がない方向では従来通り抵抗付きで戻る。
- プレビュー画面は `pointer-events-none` にして、ドラッグ中に誤タップや選択状態変更が起きないようにした。

### 影響範囲

- `/` ホーム / 個別募集マッチの関係図画面
- 関係図画面間の横スワイプ体験
- 横スワイプ後の詳細切替アニメーション

### 確認方法

- `npx eslint src/components/home/MatchDetailModal.tsx src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/MatchDetailModal.tsx`

### セルフレビュー結果

- ✅ 隣接する関係図画面を実際に左右へ配置し、ドラッグ中に見える構造へ変更
- ✅ 初回に個別募集マッチを開く時の右スライド UI は維持
- ✅ スワイプ確定後は二重アニメーションを避けるため、次の current 化では追加スライドしない
- ✅ プレビュー画面は非操作にして、選択状態やポップアップが誤って動かないようにした
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.21：マッチ詳細スワイプを指追従型へ調整

### 背景・問題意識

オーナーから、個別募集の関係図画面間のスワイプについて「もっとスムーズというか指の動きに合わせて画面も動くように」「iPhone のホーム画面の画面移動のように」という指摘があった。

iter154.20 では横スワイプ終了時に隣の詳細へ移動できるようにしたが、ドラッグ中は画面が動かず、指を離した後に切り替わるため、ネイティブアプリ的な追従感が弱かった。

### 変更内容

#### `web/src/components/home/MatchDetailModal.tsx`
- 横スワイプ中の `dx` を `translate3d` に反映し、関係図画面が指の動きに合わせて横へ動くようにした。
- 指を離した時、距離または速度が閾値を超えていれば現在の画面を左右へ吸着退場させ、その後で隣のマッチ詳細へ移動するようにした。
- 閾値に届かない場合は、iOS 風に元の位置へ戻る settle animation を入れた。
- 隣の詳細がない方向へ引っ張った場合は、移動量を弱める抵抗を入れ、端に到達していることが分かる挙動にした。
- 縦スクロールと競合しないよう、最初の移動方向が縦寄りの場合は横スワイプをロックしないようにした。
- ルート全体ではなく内側の詳細シェルだけを動かし、ドラッグ中にホーム画面が不自然に露出しないようにした。

### 影響範囲

- `/` ホーム / 個別募集マッチの関係図画面
- 関係図画面内の横スワイプ移動
- 縦スクロールと横スワイプのジェスチャー競合

### 確認方法

- `npx eslint src/components/home/MatchDetailModal.tsx src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/MatchDetailModal.tsx`

### セルフレビュー結果

- ✅ 既存の右から入る関係図 UI は維持
- ✅ 横スワイプ中に画面が指へ追従する挙動へ変更
- ✅ 距離・速度の両方でページ移動を判定し、短く素早いスワイプにも反応
- ✅ 隣がない方向は抵抗付きで戻るため、不自然にページ移動しない
- ✅ 縦スクロール優先時は横スワイプに入らないため、詳細画面内の閲覧を妨げない
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.20：マッチ詳細の履歴復帰と横スワイプ移動

### 背景・問題意識

オーナーから、ホーム画面で個別募集マッチのパネルを押した時に右からスッと出てくる関係図 UI は維持したまま、遷移先からブラウザの「前の画面に戻る」を使った時にマッチング画面へ戻れるようにしたいという要望があった。

また、個別募集の関係図画面で横スワイプし、隣のマッチングパネルの個別募集画面へ移動できるようにしたいという要望もあった。ネイティブアプリ的な横移動感を保ちながら、ブラウザ履歴としては「詳細を閉じる」だけを 1 ステップにする必要がある。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 個別募集マッチ詳細を開く時、`?matchDetail=...` を `history.pushState` で積むようにした。
- `popstate` を監視し、`matchDetail` が URL から外れた時は関係図を閉じてホームのマッチング一覧へ戻すようにした。
- 関係図内で隣の候補へ横スワイプした時は、履歴を積まず `history.replaceState` で現在の detail key だけ置き換えるようにした。
- そのため、複数の詳細を横スワイプした後でも、ブラウザ戻るは「直前の詳細」ではなくマッチング一覧へ戻る。

#### `web/src/components/home/MatchDetailModal.tsx`
- 関係図画面に横スワイプ検知を追加。
- 左スワイプで次、右スワイプで前の個別募集マッチ詳細へ移動できるようにした。
- 縦スクロールやボタン操作を妨げないよう、横移動が十分大きく、縦移動より明確な場合だけ反応するようにした。
- 打診画面へ進む時は履歴 back を発火しない専用フックに分け、詳細閉じる操作と route 遷移を分離。

#### `web/src/app/globals.css`
- 前の詳細へ戻る時用に、左側から入る `matchDetailSlideInFromLeft` animation を追加。
- 既存の右スライド UI は維持し、次の詳細は右から、前の詳細は左から入るようにした。

### 影響範囲

- `/` ホーム / マッチング画面
- 個別募集マッチの関係図画面
- ブラウザ戻る / 進む操作
- 関係図内の横スワイプ移動

### 確認方法

- `npx eslint src/components/home/HomeView.tsx src/components/home/MatchDetailModal.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/MatchDetailModal.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ 個別募集マッチ詳細を開く時の右スライド UI を維持
- ✅ ブラウザ戻るでホームのマッチング一覧へ戻る履歴を追加
- ✅ 詳細内の横スワイプで隣の個別募集マッチ詳細へ移動
- ✅ 横スワイプ移動は履歴を積まず replace するため、戻る操作は一覧復帰になる
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.19：グッズ操作シートを画面全体レイヤーへ移動

### 背景・問題意識

オーナーから、マイ在庫やウィッシュのグッズ画像を押した時のポップアップが、画面全体ではなくグッズ画像の中に選択肢が出ているように見え、前のカード内メニューと変わらないという指摘があった。

`BottomActionSheet` は `position: fixed` で実装していたが、呼び出し元のカードは pop-in / bounce アニメーションで `transform` を使っている。CSS では transform 配下の fixed 要素がその祖先に閉じ込められるため、カード内にメニューが出ているように見えていた。

### 変更内容

#### `web/src/components/common/BottomActionSheet.tsx`
- `BottomActionSheet` を `document.body` へ `createPortal` する構成に変更。
- 在庫・Wish のカードアニメーションやグリッドの overflow の影響を受けず、画面全体に対する下部シートとして表示されるようにした。

### 影響範囲

- `/inventory` マイ在庫のカード操作シート
- `/wishes` Wish のカード操作シート
- `BottomActionSheet` を利用する今後の画面

### 確認方法

- `npx eslint src/components/common/BottomActionSheet.tsx src/app/inventory/InventoryView.tsx src/app/wishes/WishView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/common/BottomActionSheet.tsx`

### セルフレビュー結果

- ✅ グッズカード内ではなく `document.body` に操作シートを描画
- ✅ マイ在庫と Wish の両方で共通修正として反映
- ✅ シート自体は画面いっぱいではなく、従来通り下部から出る `max-w-md` のパネルを維持
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.18：在庫キープ導線と譲り済み履歴を整理

### 背景・問題意識

オーナーから、マイ在庫の「自分用キープ」タブでカードをタップした時に「自分キープへ」が出てしまう不整合と、「過去に譲った」タブで削除できると取引履歴の不正につながりそうという指摘があった。

自分用キープ中のアイテムに必要なのは、同じ状態への移動ではなくマッチング対象へ戻す操作。一方、譲り済みアイテムは取引履歴として残すべきもので、ユーザーが後から更新・削除できると履歴の整合性が崩れる。そこで、状態ごとの操作を明確に分ける。

### 変更内容

#### `web/src/app/inventory/InventoryView.tsx`
- `keep` のカードアクションを「自分キープへ」から「譲る候補へ」に変更し、`status='active'` へ戻す操作に修正。
- `traded` のカードはアクションシートを出さず、タップで `/inventory/[id]` の詳細画面へ直接遷移するように変更。

#### `web/src/app/inventory/[id]/page.tsx`
- `status='traded'` の在庫はヘッダーを「グッズ詳細」に切り替えるよう変更。

#### `web/src/app/inventory/[id]/EditForm.tsx`
- `status='traded'` の在庫は詳細確認専用に変更。
- 写真差し替え、メタ情報、数量、タグ、説明、ステータスの編集を無効化。
- 保存ボタン・削除ボタンを非表示にし、更新・削除できない理由を画面上に表示。

#### `web/src/app/inventory/actions.ts`
- `status='traded'` の在庫に対する `updateInventoryStatus` / `updateInventoryItem` / `deleteInventoryItem` をサーバーアクション側で拒否。
- UI を迂回した更新・削除でも、譲り済み履歴が消えないように防御。

#### `Megrum/b-inventory.jsx`
- 「過去に譲った」タブの説明文を、詳細表示のみ・更新削除不可の方針に合わせて更新。

#### `notes/09_state_machines.md`
- Item Lifecycle のビジネスルールに `traded` の不変性を追記。

#### `notes/05_data_model.md`
- `status='traded'` の在庫は履歴証跡として update/delete 不可にする方針を追記。

### 影響範囲

- `/inventory` マイ在庫一覧
- `/inventory/[id]` 在庫詳細・編集画面
- 在庫更新・削除サーバーアクション
- B-1 在庫一覧モック

### 確認方法

- `npx eslint src/app/inventory/InventoryView.tsx src/app/inventory/actions.ts src/app/inventory/[id]/page.tsx src/app/inventory/[id]/EditForm.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/inventory/[id]/page.tsx`
- `web/src/app/inventory/[id]/EditForm.tsx`
- `web/src/app/inventory/actions.ts`
- `Megrum/b-inventory.jsx`
- `notes/09_state_machines.md`
- `notes/05_data_model.md`

### セルフレビュー結果

- ✅ 自分用キープタブでは「譲る候補へ」と表示し、`active` へ戻す操作に変更
- ✅ 過去に譲ったタブではアクションシートを出さず、詳細画面へ直接遷移
- ✅ 譲り済み詳細画面は更新・削除ボタンを出さない読み取り専用表示に変更
- ✅ サーバーアクション側でも `traded` の更新・削除を拒否
- ✅ `notes/09_state_machines.md` は `traded` 不変性の状態ルール追加のため更新
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` は履歴証跡としての update/delete 不可ルールを追記

---

## イテレーション154.17：プロフのスケジュール導線をアイデンティティへ統合

### 背景・問題意識

オーナーから、プロフ画面の「アイデンティティ」にスケジュールを含めるよう指摘があった。

スケジュールは単なる活動メニューではなく、取引相手に任意公開する個人予定や候補日の整理に関わるため、プロフ上では「自分を表す設定群」の一部として扱う方が自然。独立した「予定」セクションではなく、アイデンティティ内の行に統合する。

### 変更内容

#### `web/src/app/profile/ProfileView.tsx`
- 独立していた「予定」セクションを撤去。
- `/schedules` への「スケジュール」行を「アイデンティティ」セクション内へ移動。
- セクション数が減ったため、後続セクションのフェードイン delay を詰めた。

#### `Megrum/hub-screens.jsx`
- ProfileHub モックの「アイデンティティ」セクションに「スケジュール」行を追加。
- スケジュールをプロフィール編集・推し設定と同じ文脈で見えるように整理。

### 影響範囲

- `/profile` 自分のプロフ画面
- `Megrum/hub-screens.jsx` の ProfileHub モック

### 確認方法

- `npx eslint src/app/profile/ProfileView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/ProfileView.tsx`
- `Megrum/hub-screens.jsx`

### セルフレビュー結果

- ✅ スケジュール導線を「アイデンティティ」セクション内に統合
- ✅ 独立した「予定」セクションを削除し、プロフ画面のまとまりを整理
- ✅ モック側にも同じ情報設計を反映
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は既存用語「スケジュール」の配置変更のみのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.16：プロフ最下部のアカウント削除導線を撤去

### 背景・問題意識

オーナーから、プロフ画面の最下部にある「アカウント削除」は消してほしいという指摘があった。

プロフ画面最下部に削除導線があると、通常のプロフィール確認・設定導線の文脈に対して重く見えやすい。現状は準備中表示でもあるため、プロフ最下部からは撤去し、ログアウトだけを残す。

### 変更内容

#### `web/src/app/profile/ProfileView.tsx`
- 最下部の disabled な「アカウント削除（準備中）」行を削除。
- 最下部セクションはログアウトのみ表示する構成に変更。

#### `Megrum/hub-screens.jsx`
- ProfileHub モックの最下部から「アカウント削除」行を削除。
- ログアウト行を単独の last row として整理。

### 影響範囲

- `/profile` 自分のプロフ画面
- `Megrum/hub-screens.jsx` の ProfileHub モック

### 確認方法

- `npx eslint src/app/profile/ProfileView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/profile/ProfileView.tsx`
- `Megrum/hub-screens.jsx`

### セルフレビュー結果

- ✅ プロフ画面最下部から「アカウント削除（準備中）」を削除
- ✅ モック側の ProfileHub からも「アカウント削除」を削除
- ✅ ログアウト導線は維持
- ✅ `notes/09_state_machines.md` はアカウント削除状態の仕様変更ではなく表示導線削除のため更新不要
- ✅ `notes/10_glossary.md` は新用語・廃止用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.15：在庫とWishの操作を下部シート化

### 背景・問題意識

オーナーから、マイ在庫・ウィッシュで列数を 4 列以上にした時、グッズをタップして出る選択肢が画像内にはみ出して不格好になるという指摘があった。

これまではカード内に「編集する」「自分キープへ」「削除」「閉じる」などのメニューを重ねていたが、カード幅が狭い表示ではボタンの視認性と余白が足りない。カード内に押し込めず、下からにゅっと出るアクションシートで選ばせるモバイル UI に寄せる。

### 変更内容

#### `web/src/components/common/BottomActionSheet.tsx`
- グッズ画像・タイトル・サブ情報・アクション一覧を受け取る共通の下部アクションシートを追加。
- 背景 blur + 下からの slide-in で、カードサイズに依存しない操作面を提供。
- `primary` / `normal` / `danger` / `muted` の action tone を用意。

#### `web/src/app/inventory/InventoryView.tsx`
- マイ在庫カード内の黒い重ねメニューを廃止し、カードタップで `BottomActionSheet` を表示。
- 「編集する」「自分キープへ」は従来通りカードのバウンス後に実行。
- 「削除」は従来通り確認モーダル → フェードアウト削除フローへ接続。
- 「閉じる」はシートを閉じるだけにし、カードが跳ねないように変更。

#### `web/src/app/wishes/WishView.tsx`
- Wish カード内の重ねメニューを廃止し、カードタップで `BottomActionSheet` を表示。
- 「編集する」「個別募集を作る / + 個別募集を追加」は従来通りカードのバウンス後に実行。
- 「削除」は確認モーダル → フェードアウト削除フローへ接続。
- 「閉じる」はシートを閉じるだけにした。

#### `web/src/app/globals.css`
- 下部アクションシート用の slide-in / backdrop fade-in animation を追加。
- `prefers-reduced-motion` ではアニメーションを無効化。

#### `web/src/app/inventory/ItemCard.tsx`
- 親の操作説明コメントを、カード内メニューからアクションシートに更新。

### 影響範囲

- `/inventory` マイ在庫一覧
- `/wishes` ウィッシュ一覧
- 3 列 / 4 列 / 5 列表示時のカード操作

### 確認方法

- `npx eslint src/components/common/BottomActionSheet.tsx src/app/inventory/InventoryView.tsx src/app/inventory/ItemCard.tsx src/app/wishes/WishView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/common/BottomActionSheet.tsx`
- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/inventory/ItemCard.tsx`
- `web/src/app/wishes/WishView.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ 4 列 / 5 列でもカード内に選択肢がはみ出さない構造に変更
- ✅ マイ在庫の「閉じる」はカードを跳ねさせず、シートを閉じるだけに変更
- ✅ 削除のフェードアウト・自動整理フローは維持
- ✅ 編集 / 個別募集追加 / 自分キープのバウンス挙動は維持
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要

---

## イテレーション154.14：個別募集編集の隠れ譲参照を除外

### 背景・問題意識

オーナーから、個別募集更新時に「交換条件に使えない譲グッズがあります」として `V トレカ` や `ジョングク トレカ` が表示されるが、実際の編集画面上部の譲候補にも表示されず、選択もしていないためユーザーが外しようがないという指摘があった。

個別募集作成後にマイ在庫側で自分キープ化・取引成立による市場残数減少などが起きると、DB の `listings.have_ids` には古い参照が残る一方、編集画面の候補一覧には出ないことがある。この古い参照をフォーム内部の初期選択として保持したまま更新 payload に送っていたため、ユーザーに見えない譲グッズでバリデーションが止まっていた。

### 変更内容

#### `web/src/app/listings/[id]/edit/page.tsx`
- 個別募集編集時、譲側は「現在 active かつ市場残数がある候補」だけを `inventoryItems` として渡すように整理。
- 過去に `listing.have_ids` に入っていたが、現在候補に出せない譲は初期選択から除外。
- 既存 `have_group_id` / `have_goods_type_id` が現在の候補 dropdown に存在しない場合は、初期選択を空にしてユーザーが選び直せる状態にした。
- wish 側は既存選択を編集画面で外せるよう、参照中 wish の union fetch を維持。

#### `web/src/app/listings/new/ListingNewForm.tsx`
- edit 初期化時、`inventoryItems` に存在しない譲 ID や `availableQty < 1` の譲 ID は `selectedHaves` に入れない。
- submit 直前にも、現在候補に存在する譲だけを `haveIds` / `haveQtys` として送る防御を追加。
- 数量は現在の `availableQty` で clamp し、過去の数量が市場残数を超えたまま送られないようにした。

### 影響範囲

- `/listings/[id]/edit` 個別募集編集画面
- 個別募集更新時の市場残数・在庫状態バリデーション
- 自分キープ化、成立済み取引による市場残数 0、在庫数減少後の個別募集更新体験

### 確認方法

- `npx eslint 'src/app/listings/[id]/edit/page.tsx' src/app/listings/new/ListingNewForm.tsx`

### 関連ファイル

- `web/src/app/listings/[id]/edit/page.tsx`
- `web/src/app/listings/new/ListingNewForm.tsx`

### セルフレビュー結果

- ✅ 候補に出ない譲グッズが hidden selection として送信されない
- ✅ 見えていないグッズ名で更新エラーになり続ける状態を解消
- ✅ wish 側の既存参照は編集で外せるよう維持
- ✅ `notes/09_state_machines.md` は既存の Listing Lifecycle ルール内の実装修正のため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` は既存の `have_ids` 整合ルールの実装修正のため更新不要

---

## イテレーション154.13：モード切替中表示を上部ステータス化

### 背景・問題意識

オーナーから、ホームの「XXモードに切り替え中…」表示について、画面中央ではなくもう少し上部に出してほしいという指摘があった。

切り替え自体は 0.3 秒前後で終わるため、中央に一瞬だけ出るとユーザーが「何て書いてあったのか」を気にしてしまう。モーダル感を弱め、上部のステータス通知として見える位置と形に寄せる。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- モード切替中 overlay の表示位置を中央から画面上部へ移動。
- 表示カードを角丸パネルから丸い status pill に変更し、短時間表示でも軽く読める見え方にした。
- blur 背景を少し控えめにし、操作待ちの重さを減らした。
- 即時切り替えの体感は維持しつつ、ステータス表示だけ約 0.48 秒残るように調整。

### 影響範囲

- `/` ホーム / マッチング画面
- 全国交換モード / 今すぐ現地交換モードの切り替え中表示

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 切り替え中表示を画面上部へ移動
- ✅ 一瞬表示でも意味が取りやすい status pill 風に調整
- ✅ 実際のモード切替自体は遅くしていない
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.12：関係図を右スライド遷移に変更

### 背景・問題意識

オーナーから、マッチング画面で個別募集にマッチしたパネルを押した時、遷移先の関係図画面が右側からにゅっと出てくる感じにしたいという要望があった。

これまでは関係図モーダルが即時に全画面表示され、マッチカードから詳細へ「入った」感が弱かった。モバイルアプリらしく、右から画面が乗ってくる遷移にして、詳細画面へ進んだことを自然に感じられるようにする。

### 変更内容

#### `web/src/components/home/MatchDetailModal.tsx`
- 関係図モーダルのルートに `animate-match-detail-slide-in` を追加。
- 個別募集マッチのパネル押下後、関係図が右側の画面外から入ってくるようにした。

#### `web/src/app/globals.css`
- `matchDetailSlideIn` keyframes を追加。
- 右から入り、わずかに行き過ぎてから収まる 380ms の transition に設定。
- `prefers-reduced-motion` ではアニメーションを無効化。

### 影響範囲

- `/` ホーム / マッチング画面
- 個別募集マッチのパネル押下後に出る関係図画面
- 通常マッチで同じ `MatchDetailModal` を使う場合の表示

### 確認方法

- `npx eslint src/components/home/MatchDetailModal.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/MatchDetailModal.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ 関係図画面が右からスライドインする
- ✅ 全画面の関係図として、カードから画面遷移した感が出る
- ✅ `prefers-reduced-motion` に配慮
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.11：提示物選択を横スワイプ対応

### 背景・問題意識

オーナーから、提示物の選択画面でも横スワイプで画面を切り替えられるようにしたいという要望があった。

C-0 は「私が出す」「受け取る」「待ち合わせ」の 3 タブを行き来しながら条件を整える画面なので、スマホではタブを押すだけでなく、左右スワイプで自然に前後のタブへ移動できる方が操作しやすい。

### 変更内容

#### `web/src/app/propose/[partnerId]/ProposeFlow.tsx`
- 選択ステップの本文エリアに touch handler を追加し、左右スワイプで `私が出す → 受け取る → 待ち合わせ` の順にタブ移動できるようにした。
- 横移動が十分大きく、縦移動より明確な場合だけスワイプ判定するようにし、通常の縦スクロールを妨げないようにした。
- スワイプ直後に元のタップ操作が誤発火しないよう、次の click を capture で抑止。
- 地図、入力欄、検索欄、textarea/select/contenteditable はスワイプ対象から除外し、地図操作やフォーム入力と競合しないようにした。
- 場所検索の短い入力時クリア処理を input 変更ハンドラ側へ移し、React Hooks lint の `set-state-in-effect` 警告を回避。

### 影響範囲

- `/propose/[partnerId]` 提示物の選択画面
- C-0 の「私が出す」「受け取る」「待ち合わせ」タブ移動
- 待ち合わせタブ内の場所検索・地図操作

### 確認方法

- `npx eslint 'src/app/propose/[partnerId]/ProposeFlow.tsx'`
- `npm run build`

### 関連ファイル

- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`

### セルフレビュー結果

- ✅ 横スワイプで前後タブへ移動できる
- ✅ 縦スクロール、フォーム入力、地図操作と競合しないよう除外条件を設定
- ✅ スワイプ後の誤クリックを抑止
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.10：ホームのモード切替を即時反応化

### 背景・問題意識

オーナーから、ホーム画面の「全国交換モード」と「今すぐ現地交換モード」の切り替え動作は良くなったものの、押した瞬間から実際に切り替わるまで少しラグがあり、ユーザー体験を損ねているという指摘があった。

DB 更新・URL 更新・GPS 取得を待ってからピルの見た目が変わると、ユーザーには「押せていない」ように感じられる。切り替え自体は即時に見せ、実データ更新中は画面全体にぼかしと切り替え中表示を出して、待ち時間を状態として理解できるようにする。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- モード切替 pill に `optimisticMode` を追加し、押した瞬間に選択中ピルと文字色が先に切り替わるようにした。
- DB 更新・URL 更新・GPS 取得中は `modeSwitching` と既存の transition pending を使い、画面全体に軽い blur overlay を表示。
- overlay は「全国交換モードに切り替え中…」「今すぐ現地交換モードに切り替え中…」を出し分けるようにした。
- 実際の server props が optimistic な見た目に追いついたら optimistic state を解除し、DB 状態と再同期するようにした。
- 右上の場所表示・現地モード ON/OFF トグルは、ビュー切替ではなく実際の `localMode.enabled` に基づく表示を維持。

### 影響範囲

- `/` ホーム / マッチング画面
- 全国交換モード / 今すぐ現地交換モードの pill 切り替え
- 現地交換モードの再 ON / OFF / 初回設定導線

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 押下直後に pill の見た目が optimistic に切り替わる
- ✅ 実データ更新中は画面全体を blur し、「切り替え中」として待ち状態を明示
- ✅ 右上の場所表示と実 ON/OFF トグルは DB 状態に基づくため、全国 view 表示中でも現地設定が消えたように見えない
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.9：個別募集更新エラーを具体化

### 背景・問題意識

オーナーから、個別募集の更新時に「すでに交換対象ではないグッズが含まれています」とだけ表示され、何がだめなのか分からず更新できないという指摘があった。

個別募集の譲条件は、マイ在庫側で削除・キープ化・譲渡済み化・別取引で確保済みになると更新時の市場残数チェックで止まる。ユーザーが直せるように、対象グッズ名と理由を具体的に返す必要がある。

### 変更内容

#### `web/src/lib/marketAvailability.ts`
- 市場残数チェックのエラーを、最初の抽象メッセージで止めず、対象グッズごとの理由として集約するように変更。
- グッズ名の fallback として、グループ / キャラ / 種別名も取得して表示できるようにした。
- 削除済み・参照不可、譲る候補以外、非 active 状態、成立済み取引による市場残数不足をそれぞれ別理由で表示。
- 数量不足時は `必要数 / 市場残数 / 登録数` を出すようにした。

#### `web/src/app/listings/new/ListingNewForm.tsx`
- server action から返る複数行エラーを読みやすくするため、エラー表示に `whitespace-pre-line` と行間を追加。

### 影響範囲

- `/listings/[id]/edit` 個別募集編集画面
- `/listings/new` 個別募集作成画面
- 同じ市場残数チェックを使う打診確定前ガード

### 確認方法

- `npx eslint src/lib/marketAvailability.ts src/app/listings/new/ListingNewForm.tsx`
- `npm run build`

### 関連ファイル

- `web/src/lib/marketAvailability.ts`
- `web/src/app/listings/new/ListingNewForm.tsx`

### セルフレビュー結果

- ✅ 何がだめかをグッズ単位で表示
- ✅ 削除済み / 譲る候補外 / 非 active / 市場残数不足を区別
- ✅ 個別募集フォームで複数行エラーが読める
- ✅ `notes/09_state_machines.md` は状態追加・変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.8：ホームのモード切替をiOS風に調整

### 背景・問題意識

オーナーから、ホーム画面の「全国交換モード」と「今すぐ現地交換モード」の切り替え時に、ボタンがふわっと切り替わってほしいという要望があった。

現在は各ボタン自身の背景が切り替わるだけで硬く見えるため、iOS の segmented control のように、選択中の白いピルが滑って移動する見え方に寄せる。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- モード切替を `flex` ボタン背景切替から、`grid` + 背面の白い選択ピル方式へ変更。
- 選択中ピルに `cubic-bezier(0.22,1,0.36,1)` の transition を付け、全国/現地の切替時にふわっと横移動するようにした。
- ボタン自体はテキスト色と軽い active scale のみにし、背景の切替感をピルの移動へ集約。
- `prefers-reduced-motion` では transition を止める `motion-reduce:transition-none` を付与。

### 影響範囲

- `/` ホーム / マッチング画面
- 全国交換モード / 今すぐ現地交換モードの切り替え UI

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 選択中の白いピルが左右に滑る iOS 風 segmented control に変更
- ✅ テキスト色の切り替えもスムーズに調整
- ✅ `prefers-reduced-motion` に配慮
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.7：ホーム見出しと現地交換時間設定を調整

### 背景・問題意識

オーナーから、ホームの「マッチ！」見出しを「マッチしてるよ！」へ変更し、文字ももう少し大きくしたいという指示があった。

また、マッチング画面から現地交換の詳細設定を開いて交換時間を指定した際、開始時間の初期値や「この設定で表示」後の反映時間がずれていること、スマホでは設定シートが上部まで開きすぎて閉じにくいことも指摘された。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 個別募集マッチセクションのタイトルを「マッチ！」から「マッチしてるよ！」へ変更。
- ホーム候補セクション見出しを `18px` から `22px` に拡大。

#### `web/src/components/home/LocalModeSheet.tsx`
- 現地交換設定の保存時、`datetime-local` 用のローカル文字列ではなく UTC 付き ISO 文字列を server action へ渡すように修正。
- サーバー実行環境のタイムゾーン解釈により、設定した開始/終了時間がずれる問題を防止。
- 設定シートの最大高さを `92vh` から `78vh` に下げ、スマホで上部の閉じる余白を確保。

### 影響範囲

- `/` ホーム / マッチング画面
- 現地交換モード設定シート
- AW の開始/終了時刻保存

### 確認方法

- `npx eslint src/components/home/HomeView.tsx src/components/home/LocalModeSheet.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/LocalModeSheet.tsx`

### セルフレビュー結果

- ✅ 「マッチしてるよ！」へ文言変更
- ✅ ホーム候補セクション見出しを拡大
- ✅ 現地交換設定の時刻保存を ISO 文字列に統一し、サーバー側タイムゾーン差を回避
- ✅ 設定シートの最大高さを下げ、スマホで閉じやすい余白を確保
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.6：ホーム候補をマッチと交換できるかもで区切る

### 背景・問題意識

オーナーから、ホームの候補一覧について、個別募集にマッチしているものと、個別募集にはマッチしていないが互いの譲と求が合致しているものを、表示場所として一旦区切りたいという指示があった。

前者には「マッチ！」、後者には「交換できるかも」という黒文字太字タイトルを付け、各セクション内はこれまで通りキャラ × 種別ごとに 1 行ずつ横スクロールで並べる。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホーム候補行を、候補グッズ単位の priority に基づいて 2 セクションへ分割。
- `priority=0/1`（双方または一方の個別募集合致）は「マッチ！」へ表示。
- `priority=2`（通常の譲 × Wish 合致）は「交換できるかも」へ表示。
- 空のセクションは表示せず、候補があるセクションだけ黒太字タイトルを出すようにした。
- 各セクション内の表示は、既存のキャラ × 種別ごとの行と横スクロール候補タイルをそのまま利用。

### 影響範囲

- `/` ホーム / マッチング画面
- 候補タイル一覧のセクション分け
- 候補タイルの表示順とアニメーション開始タイミング

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 個別募集にマッチしている候補を「マッチ！」へ分離
- ✅ 通常の譲 × Wish 合致候補を「交換できるかも」へ分離
- ✅ 空セクションは非表示にし、ホームが余計に寂しくならないようにした
- ✅ 既存のキャラ × 種別ごとの行表示と横スクロール体験を維持
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.5：ホーム下端グローを抑えてフッターを白に統一

### 背景・問題意識

オーナーから、前回の `BottomNav` 背景白化後も、ホーム画面のフッターだけまだグラデーションがかかって見えるため、他画面のフッターと統一したいという追加指摘があった。

共通フッター自体は白になっているが、ホームの現地交換モード用 ambient glow が画面下端にも出ていたため、フッター周辺に色が残って見える可能性がある。ホームの下端にはグローを出さず、上端と左右だけで現地感を出す設計に改める。

### 変更内容

#### `web/src/app/globals.css`
- `.local-mode-glow` の inset box-shadow 演出を廃止。
- 上端・左右端だけに淡い radial-gradient を出す背景演出へ変更。
- `localGlowPulse` は影量ではなく opacity のゆらぎだけにし、画面下端・フッター領域へグラデーションが出ないようにした。

### 影響範囲

- `/` ホーム / マッチング画面
- 現地交換モード ON 時の画面端グロー
- ホーム下部フッター周辺の見え方

### 確認方法

- `npx eslint src/components/home/HomeView.tsx src/components/home/BottomNav.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ ホーム下端に ambient glow が出ないよう調整
- ✅ フッター本体は共通 `BottomNav` の白背景を維持
- ✅ 現地交換モードの高揚感は上端・左右端の淡い光として残した
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.4：ホーム候補の個別募集判定をグッズ単位へ修正

### 背景・問題意識

オーナーから、ホームのマッチングパネルで特定グッズ（例：ニンニン）を押した時、そのグッズ自体が自分または相手の個別募集に含まれていないにもかかわらず関係図へ進んでしまい、関係図側ではそのグッズを選べないという指摘があった。

また、候補一覧の派手な枠演出も相手カード全体ではなく、押す対象のグッズが個別募集に関係しているかどうかに沿って弱めたいという指示があった。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホーム候補タイルごとに、その受け取り候補グッズが自分の個別募集の選択肢候補に含まれているかを判定。
- 同じく、その受け取り候補グッズが相手の個別募集の譲として matched しているかを判定。
- 候補枠の優先度を、相手カード全体ではなくグッズ単位の `双方個別募集 / 一方個別募集 / 通常の譲 × Wish` で決めるように変更。
- 押したグッズが個別募集に関係する場合だけ、該当する個別募集だけを渡して関係図モーダルを開くように変更。
- 押したグッズが個別募集に関係しない場合は、関係図を開かず、`receives` にそのグッズを入れた状態で打診作成画面へ直接遷移するように変更。

### 影響範囲

- `/` ホーム / マッチング画面
- 候補タイル押下時の遷移先
- 候補タイルの優先度別フレーム演出
- 関係図モーダルへ渡す個別募集の範囲

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ グッズ単位で個別募集に関係する候補だけ関係図へ遷移
- ✅ 個別募集に関係しない候補は、そのグッズを受け取り候補にした状態で打診作成画面へ直接遷移
- ✅ 候補枠の派手さもグッズ単位の個別募集合致に合わせて調整
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.3：ボトムナビ背景を白に統一

### 背景・問題意識

オーナーから、ホーム画面のフッターだけ他画面と違ってグラデーションがついて見えるため、他画面に合わせたいという指摘があった。

ホームでは現地交換モードのグローや背景が半透明のボトムナビ越しに透け、フッターだけ色が乗って見える可能性があるため、共通ボトムナビの背景を不透明にして画面間の見え方を揃える。

### 変更内容

#### `web/src/components/home/BottomNav.tsx`
- fixed 表示時の `BottomNav` から `bg-white/95 backdrop-blur-xl` を撤去。
- 背景を `bg-white` に統一し、ホームだけ背景グローが透けてグラデーション状に見える状態を防止。

### 影響範囲

- 共通ボトムナビを使う画面
- `/` ホーム / マッチング画面のフッター表示

### 確認方法

- `npx eslint src/components/home/BottomNav.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/BottomNav.tsx`

### セルフレビュー結果

- ✅ ホームのフッター背景が他画面と同じ白ベースになるよう調整
- ✅ 共通 `BottomNav` の変更に留め、各画面ごとの個別上書きは追加していない
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.2：ホーム候補棚を2.5枚見えに調整

### 背景・問題意識

オーナーから、ホーム画面の候補パネル行について「1行につきスマホの画面で2.5枚は映るようにしてほしい」と指示があった。

横にまだ候補が続いていることを自然に気づかせ、横スクロールを促すため、候補タイルの表示幅をスマホ幅から逆算する設計にしたい。

### 変更内容

#### `web/src/app/globals.css`
- `.home-shelf-tile` を追加し、`max-w-md` のホーム幅、左右余白、カード間 gap を前提に、1行で約 2.5 枚が見える幅を `calc((min(100vw, 28rem) - 64px) / 2.5)` で算出。
- `.home-shelf-tile-card` を追加し、既存カード比率を保ったまま幅に合わせて高さが決まるよう `aspect-ratio: 112 / 142` を指定。

#### `web/src/components/home/HomeView.tsx`
- ホーム候補タイルの固定 `112px × 142px` 指定を撤去。
- 新しい `.home-shelf-tile` / `.home-shelf-tile-card` を使って、スマホ幅に応じた 2.5 枚見えのレイアウトに変更。

### 影響範囲

- `/` ホーム / マッチング画面
- キャラ × 種別ごとの候補パネル行のカードサイズと横スクロール誘導

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ スマホ幅で候補カードが約 2.5 枚見えるサイズに調整
- ✅ 右側に続きが見えるため、横スクロール可能なことが伝わりやすい
- ✅ 固定 px ではなく画面幅と `max-w-md` を前提に算出するため、一般的なスマホ幅で破綻しにくい
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154.1：ホーム候補棚の縦スクロール許可

### 背景・問題意識

オーナーから、ホーム画面の候補パネル行が縦に動かないようになった一方で、そのパネル領域からページ全体を縦スクロールできなくなって不便だという指摘があった。

意図としては、候補棚自体は横方向にだけスクロールしつつ、縦フリックはページスクロールとして自然に効く状態にしたい。

### 変更内容

#### `web/src/app/globals.css`
- `.home-shelf-row-scroll` の `touch-action` を `pan-x` 固定から `pan-x pan-y` に変更。
- 横方向の overscroll は引き続き `contain` で抑え、縦方向は `auto` に戻して親ページへスクロールが伝わるようにした。

### 影響範囲

- `/` ホーム / マッチング画面
- キャラ × 種別ごとの候補パネル行のタッチスクロール挙動

### 確認方法

- `npx eslint src/app/page.tsx src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ 候補棚の横スクロール専用感は維持
- ✅ 候補棚の上から縦フリックした場合もページスクロールへ伝わる設定に変更
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション154：列数切替と追加導線を丸型FABへ整理

### 背景・問題意識

オーナーから、ホーム候補カードの枠が「双方の個別募集が合致 → 一方の個別募集が合致 → 通常の譲×Wish合致」の優先度順に派手になる設計になっているか確認があった。

また、マイ在庫と Wish はヘッダー右上から 3列 / 4列 / 5列に切り替えられるようにし、Wish と個別募集の追加導線は右上テキストボタンではなく、画面右下の固定丸型 `+` アイコンへ移したいという指示があった。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホーム候補カードの優先度枠を再調整。
- `priority=0`（双方の個別募集が合致）を最も強い lavender/pink ring + glow にした。
- `priority=1`（一方の個別募集が合致）は中程度の sky/lavender 枠にした。
- `priority=2`（通常の譲 × Wish 合致）は薄い標準枠に抑えた。

#### `web/src/components/common/ColumnCountButton.tsx`
- 3 / 4 / 5 列を循環切替する小型グリッドアイコンを追加。
- 現在の列数を右上の小さな数値バッジで表示。

#### `web/src/components/common/FloatingAddButton.tsx`
- 画面右下に固定表示する丸型 `+` の追加ボタンを共通化。

#### `web/src/app/inventory/InventoryView.tsx`
- ヘッダー右上に列数切替アイコンを追加。
- マイ在庫の各サブタブのカードグリッドを 3 / 4 / 5 列で切替可能にした。

#### `web/src/app/wishes/WishView.tsx`
- Wish タブのヘッダー右上に列数切替アイコンを追加。
- Wish のカードグリッドを 3 / 4 / 5 列で切替可能にした。
- 右上の「wish を追加」ボタンとグリッド内の追加カードを撤去し、右下固定の丸型 `+` へ集約。
- 個別募集タブ表示中は同じ丸型 `+` が `/listings/new` へ遷移するようにした。

#### `web/src/app/listings/page.tsx`
- 個別募集一覧の右上「募集を追加」テキストボタンを撤去。
- 右下固定の丸型 `+` から個別募集追加へ進むようにした。

### 影響範囲

- `/` ホーム / マッチング画面の候補カード枠
- `/inventory` マイ在庫のカード列数
- `/wishes` Wish タブのカード列数と追加導線
- `/wishes` 内の個別募集タブの追加導線
- `/listings` 個別募集一覧の追加導線

### 確認方法

- `npx eslint src/components/common/ColumnCountButton.tsx src/components/common/FloatingAddButton.tsx src/components/home/HomeView.tsx src/app/inventory/InventoryView.tsx src/app/wishes/WishView.tsx src/app/listings/page.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/common/ColumnCountButton.tsx`
- `web/src/components/common/FloatingAddButton.tsx`
- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/wishes/WishView.tsx`
- `web/src/app/listings/page.tsx`

### セルフレビュー結果

- ✅ ホーム候補カードは双方個別募集 > 一方個別募集 > 通常合致の順で枠が派手になる
- ✅ マイ在庫に 3 / 4 / 5 列切替アイコンを追加
- ✅ Wish に 3 / 4 / 5 列切替アイコンを追加
- ✅ Wish の追加導線を右下固定の丸型 `+` に集約
- ✅ 個別募集一覧 / Wish 内の個別募集タブも右下固定の丸型 `+` に統一
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 ESLint / build 成功

---

## イテレーション153：市場残数と個別募集の在庫整合を追加

### 背景・問題意識

オーナーから、個別募集に譲として登録したグッズを削除したり別の人に譲ってしまった場合、その交換条件から自動で抜くよう指示があった。

また、打診が成立した段階でマイ在庫の見た目は減らさず、マッチング市場上の交換可能数だけを減らして、在庫キャパ以上にマッチ・打診成立しないようにしたいという要望があった。

### 変更内容

#### `web/src/lib/marketAvailability.ts`
- `agreed` の打診から、未完了承認の `sender_have_*` / `receiver_have_*` を集計する市場残数 helper を追加。
- `market_available_qty = quantity - agreed 未完了承認 qty` を計算し、0 以下の譲在庫を市場から除外する helper を追加。
- 個別募集の `have_ids` / `have_qtys` を市場残数で評価し、AND は不足時に非表示、OR は残数のある譲だけへ縮退する helper を追加。
- 打診成立前の最終ガードとして、双方の譲在庫が市場残数を超えていないか検証する helper を追加。
- 譲在庫が削除・非 active 化された時に、開いている個別募集の譲条件から該当 item を外し、譲が 0 件なら `closed` にする helper を追加。

#### `web/src/app/page.tsx`
- ホームのマッチング演算で、実在庫ではなく市場残数のある譲在庫だけを使用。
- ホームの関係図 / 打診導線で使う自分の在庫上限も、市場残数を渡すように変更。
- 個別募集マッチも市場残数を考慮し、残数不足の条件を候補に出さないようにした。

#### `web/src/app/propose/actions.ts`
- 打診作成・再打診・合意成立直前に市場残数を検証し、キャパ超過なら成立させないようにした。
- `agreed` に遷移した場合はホームも再検証されるよう revalidate。

#### `web/src/app/propose/[partnerId]/page.tsx`
- 打診作成画面の自分 / 相手の譲候補と数量上限を市場残数ベースに変更。
- 個別募集経由のプリフィルでも、市場残数不足の譲条件を初期選択に入れないようにした。

#### `web/src/app/inventory/actions.ts`
- 譲在庫を削除、または `active` 以外へ変更した時、関連する開いている個別募集から該当 item を除外。
- 個別募集 / ホームも revalidate。

#### `web/src/app/listings/actions.ts`
- 個別募集の作成・編集時に、譲数量が市場残数を超えないかサーバー側で検証。

#### `web/src/app/listings/new/page.tsx`, `web/src/app/listings/[id]/edit/page.tsx`
- 個別募集作成 / 編集フォームに渡す譲候補と数量上限を市場残数ベースに変更。

#### `web/src/app/transactions/actions.ts`
- 取引完了承認で実在庫が 0 になった譲 item は、関連する開いている個別募集から除外。

#### `notes/09_state_machines.md`
- `agreed` 到達時の市場残数確保ルール、キャパ超過防止、Item / Listing 側の整合ルールを追記。

#### `notes/05_data_model.md`
- スキーマ追加ではなく派生値として、市場残数の定義と proposal/listing での利用ルールを追記。

#### `notes/10_glossary.md`
- 新用語「市場残数」を追加。

### 影響範囲

- `/` ホーム / マッチング画面
- `/propose/[partnerId]` 打診作成・再打診
- `/listings/new`, `/listings/[id]/edit` 個別募集作成・編集
- `/inventory` マイ在庫の削除・ステータス変更
- `/transactions/[id]/approve` 取引完了承認
- `proposals.status='agreed'` 以降の市場在庫計算

### 確認方法

- `npx eslint src/lib/marketAvailability.ts src/app/page.tsx src/app/propose/actions.ts 'src/app/propose/[partnerId]/page.tsx' src/app/inventory/actions.ts src/app/listings/actions.ts src/app/listings/new/page.tsx 'src/app/listings/[id]/edit/page.tsx' src/app/transactions/actions.ts`
- `npm run build`

### 関連ファイル

- `web/src/lib/marketAvailability.ts`
- `web/src/app/page.tsx`
- `web/src/app/propose/actions.ts`
- `web/src/app/propose/[partnerId]/page.tsx`
- `web/src/app/inventory/actions.ts`
- `web/src/app/listings/actions.ts`
- `web/src/app/listings/new/page.tsx`
- `web/src/app/listings/[id]/edit/page.tsx`
- `web/src/app/transactions/actions.ts`
- `notes/09_state_machines.md`
- `notes/05_data_model.md`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 打診が `agreed` になった時点で市場残数から数量を差し引く派生計算を追加
- ✅ マイ在庫の表示数量は合意時点では減らさず、取引完了承認時の実在庫減算と分離
- ✅ 打診作成・再打診・合意成立直前にキャパ超過をサーバー側で防止
- ✅ ホーム / 打診作成 / 個別募集作成・編集で市場残数ベースの候補・数量上限を使用
- ✅ 譲在庫の削除・非 active 化・取引完了承認時に個別募集の譲条件から該当 item を除外
- ✅ `notes/09_state_machines.md` に `agreed` 時点の市場残数確保と Listing 整合を追記
- ✅ `notes/10_glossary.md` に「市場残数」を追加
- ✅ `notes/05_data_model.md` に派生値ルールを追記（スキーマ変更なし）
- ✅ 対象 ESLint / build 成功

---

## イテレーション152.7：ホーム候補行の横固定とタグ表示を調整

### 背景・問題意識

オーナーから、ホーム画面の候補パネル行を上下にフリックした時に行自体が上下方向にも動く違和感があるため、横方向にだけ動くようにしたいという指摘があった。

また、現地交換できる候補のエフェクトが強すぎること、行の枠で不自然に切り取られて見えること、前に定義した優先順位に応じてカード枠を派手にしたいこと、譲グッズにタグがある場合はカード下部へ重ねて表示したいことも追加で指示された。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホーム候補カードに `tagLabels` を持たせ、表示対象の譲グッズにタグがある場合はカード下部に白いタグ pill を重ねて表示。
- タグ表示は 8 文字を超えた場合に ASCII の `...` で省略するようにした。
- 候補優先度（双方の個別募集合致 / 一方の個別募集合致 / それ以外）に応じて、カードの border / ring / shadow を段階的に変えるようにした。
- ホーム候補行の横スクロール領域に `home-shelf-row-scroll` を付与し、上下方向の pan を抑制。
- 現地交換候補のホーム用エフェクトを、既存の強い炎粒演出から控えめな外光演出へ切り替え。
- 横スクロール領域の上下 padding を広げ、外光が途中で切れたように見えにくい余白を確保。

#### `web/src/app/page.tsx`
- `goods_inventory_tags` 取得時に `tags_master(label)` も取得し、タグ ID とタグ名の両方を HomeView へ渡すようにした。

#### `web/src/app/globals.css`
- ホーム候補棚専用の `home-shelf-row-scroll` を追加し、`touch-action: pan-x` と overscroll 制御を設定。
- ホーム候補棚専用の `home-shelf-local-aura` と `homeShelfLocalAura` keyframes を追加し、現地交換候補は淡い紫の外光が自然にフェードする見え方に調整。
- `prefers-reduced-motion` ではホーム用の外光アニメーションを停止。

### 影響範囲

- `/` ホーム / マッチング画面
- ホーム候補棚の横スクロール挙動
- ホーム候補カードの優先度別装飾
- ホーム候補カードの現地交換エフェクト
- ホーム候補カードのタグ表示

### 確認方法

- `npx eslint src/components/home/HomeView.tsx src/app/page.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/app/page.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ ホーム候補棚のタッチ挙動を横方向中心に制御
- ✅ 現地交換候補のエフェクトを控えめな外光へ変更し、上下余白で切り取られ感を軽減
- ✅ 優先度に応じてカード枠の強さが変わるように調整
- ✅ 譲グッズのタグ名をカード下部に重ねて表示し、長いタグは `...` で省略
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` は既存タグテーブルの表示利用のみでスキーマ変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152.6：ホームと取引一覧の着地アニメーションを滑らかに調整

### 背景・問題意識

オーナーから、ホームの候補パネルが右からスライドしてくる動きは良いが、終着点に近づいたところで一度また動き出すようなぎこちなさがあると指摘があった。同じ違和感が取引一覧にも出ているため、両方のアニメーションを滑らかに着地するよう調整する。

また、ホームでは上の行から順に少し早くカードが来るようにしつつ、全体の動きは少しゆっくりでよいという指示があった。

### 変更内容

#### `web/src/app/globals.css`
- `homeShelfPanelIn` から終点直前の中間 transform keyframe を削除し、右外から終点まで単調に減速する動きに変更。
- ホーム候補パネルの duration を `680ms` から `860ms` に延長。
- `transactionPanelIn` から終点直前の中間 transform keyframe を削除し、取引一覧も滑らかに着地するよう変更。
- 取引一覧パネルの duration を `760ms` から `900ms` に延長。

#### `web/src/components/home/HomeView.tsx`
- ホーム候補行の row delay を `55ms` から `95ms` に広げ、上の行から順にカードが先に来る見え方を強めた。
- 同一行内の候補 stagger を `70ms` から `85ms` に広げ、全体の動きを少しゆっくりにした。

### 影響範囲

- `/` ホーム / マッチング画面
- `/transactions` 取引一覧
- ホーム候補画像パネルの登場アニメーション
- 取引一覧カードの登場アニメーション

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 終点手前の中間 transform を削除し、二段階に動く違和感を解消
- ✅ ホーム候補パネルの duration / stagger を少し遅めに調整
- ✅ 上の行から順に候補が先に来る row delay を調整
- ✅ 取引一覧の登場アニメーションも同じ着地方針に統一
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152.5：ホーム場所表示のOFF文言と省略記号を調整

### 背景・問題意識

オーナーから、ホーム右上の交換場所表示について、現地交換モードを OFF にしたら `（現地交換モードOFF）` と表示し、8 文字を超える場所名には `…` を付けるよう指示があった。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 現地交換モード OFF 時の場所ボタン表示を `（現地交換モードOFF）` に変更。
- 現地交換モード ON 時の場所名は 8 文字を超えた場合、8 文字目まで表示して末尾に `…` を付けるようにした。
- OFF 文言が収まるよう、場所ボタンの最大幅を少し拡張。

### 影響範囲

- `/` ホーム / マッチング画面
- 右上の場所表示ボタン

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ OFF 時の場所表示を `（現地交換モードOFF）` に変更
- ✅ 8 文字を超える場所名に `…` を付ける処理へ変更
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152.4：ホーム候補パネルの右入りアニメーションと影を追加

### 背景・問題意識

オーナーから、ホーム画面の各パネルについて「一番左のものから順に、右側の画面外からひゅんっとくる感じ」「最初の初速は早く、到着につれて遅くなるタイプ」の動きにしたい、また各パネルに薄く右下へ落ちる影を付けたいという指示があった。

### 変更内容

#### `web/src/app/globals.css`
- `homeShelfPanelIn` keyframes を追加。
- `translate3d(115vw, 0, 0)` から入ることで、右側の画面外から滑り込む動きを作成。
- easing は `cubic-bezier(0.16, 1, 0.3, 1)` にし、初速が速く到着に向けて減速する挙動にした。
- `prefers-reduced-motion` ではアニメーションを停止。

#### `web/src/components/home/HomeView.tsx`
- `WishShelfTile` に `delayMs` を渡し、行内の左のパネルから順に `70ms` ずつ遅延して表示。
- 候補パネルに `animate-home-shelf-panel-in` を適用。
- 画像パネルの影を `7px 9px 18px` 方向へ変更し、右下に薄く落ちる見え方に調整。

### 影響範囲

- `/` ホーム / マッチング画面
- 「Wishに届いた譲」候補画像パネルの登場アニメーション
- 候補画像パネルの影表現

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 右側の画面外から候補パネルが入る keyframes を追加
- ✅ 左の候補から順に表示される stagger delay を追加
- ✅ 初速が速く、到着につれて減速する easing を使用
- ✅ 影を右下方向へ薄く落とすように変更
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152.3：ホーム上部の左右配置と候補行間を調整

### 背景・問題意識

オーナーから、ホーム最上部について「左から、検索のアイコン、通知」「右端からは、いまの現地交換モードで設定している場所と、その横にトグル」とするよう指示があった。

また、キャラ名×グッズ種別の行の間が不自然に空いているため、候補棚の行間を詰める必要があった。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 最上部の左側を検索アイコン → 通知アイコンの順に変更。
- 右側に場所名ボタンと現地交換モード toggle を並べる構成に変更。
- toggle は AW 未設定時にも表示し、押すと初回現地交換設定へ進むようにした。
- 候補棚の `space-y`、行 padding、横スクロール領域の上下 padding を縮小し、キャラ×種別行の間隔を詰めた。

### 影響範囲

- `/` ホーム / マッチング画面
- 最上部ナビゲーション
- 「Wishに届いた譲」候補棚の行間

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 左側に検索・通知、右側に場所・toggle の並びへ変更
- ✅ AW 未設定でも toggle が初回設定導線として機能
- ✅ キャラ×種別行の縦間隔を縮小
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152.2：ホーム上部と候補棚をミニマル化

### 背景・問題意識

オーナーから、ホーム画面上部の「マッチング」表記をなくし、現地交換モード中に表示していた場所 / 時間 / 持参グッズの大きなサマリー枠を削除したうえで、代わりに場所名だけを載せた導線ボタンを置くよう指示があった。

また、マッチングパネル周りについて、キャラ×種別ごとの白い枠、`双方条件 / 候補N件 / 現地N件` などの補助表示、ユーザーID、交換距離を消し、画像を大きくして、現地交換できる候補には以前の紫の炎のような枠エフェクトを付ける方針になった。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- ホーム上部の `マッチング` 見出しを削除。
- 左上に交換場所導線ボタンを追加し、AW の場所名を最大 8 文字だけ表示するようにした。
- 既存の現地交換モード ON 時の大きな設定サマリー枠を削除。
- 現地モード ON/OFF 操作用の chip は文字なしの compact toggle に縮小。
- 「Wishに届いた譲」見出しと件数バッジを削除。
- キャラ×種別ごとの白い枠 / 影 / 補助メタ情報を削除し、行は見出し + 横スクロール画像だけに整理。
- 候補画像を `88×112` から `112×142` に拡大。
- 候補下の優先度ラベル、ユーザーID、距離表示を削除。
- 現地交換候補に既存の `match-card-local-aura` / spark エフェクトを適用。

### 影響範囲

- `/` ホーム / マッチング画面
- 現地交換モード時の上部導線
- 「Wishに届いた譲」候補棚の見た目

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 上部の `マッチング` 見出しを削除
- ✅ 場所名のみの導線ボタンを追加し、8 文字までに制限
- ✅ 添付画像のような大きい現地交換サマリー枠を削除
- ✅ 候補行の白いカード枠と補助メタ表示を削除
- ✅ 候補画像を拡大し、画像以外のユーザーID / 距離表示を削除
- ✅ 現地交換候補には既存の紫オーラエフェクトを再利用
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152.1：ホーム候補にタグ類似度優先を追加

### 背景・問題意識

オーナーから、ホームの候補表示について「タグに一致しているかどうかも優先度としてあげるようにしてください。いまタグの類似度もマッチングアルゴリズムに搭載していると思うので、それを流用する形で」と指示があった。

iter152 では個別募集の成立度を主な優先順にしたが、既に `tagsByInvId` と Jaccard 類似度によるタグ比較が関係図候補で使われているため、同じスコアをホーム候補の並び替えにも反映する。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 既存の `jaccardScore` を流用し、相手の譲グッズと自分の Wish のタグ類似度を `tagScore` として算出。
- `isMatching` で同じキャラ / グループ・種別の Wish に絞り、その中で最大のタグ類似度を候補スコアにするようにした。
- 候補の並び順を、個別募集優先度 → タグ類似度 → 現地交換 → ユーザーID の順に変更。
- 行の並び順も、同じ個別募集優先度ならタグ類似度が高い行を先に出すように変更。
- タグが 1 件以上重なる候補には `タグ一致`、完全一致相当には `タグ完全一致` の小バッジを表示。

### 影響範囲

- `/` ホーム / マッチング画面
- 「Wishに届いた譲」の行順・候補順
- タグ付き Wish / 譲グッズがある場合の候補の見え方

### 確認方法

- `npx eslint src/components/home/HomeView.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 既存の Jaccard 類似度計算を流用
- ✅ 追加 DB fetch なしで、既にロード済みの `tagsByInvId` を使用
- ✅ 個別募集優先度は維持し、同ランク内でタグ一致候補を上位化
- ✅ タグ一致候補が視覚的にも分かるよう小バッジを追加
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は既存のタグ概念の利用のみのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション152：ホームをWish別候補一覧へ再構成

### 背景・問題意識

オーナーから、ホーム画面について「キャラ✖️種別ごとに、求めてるグッズの画像リストが並ぶ感じ」「自分のWishではなく、自分のWishに合致する人の譲グッズの画像」「双方の個別募集合致→一方の個別募集合致→それ以外の順番」「現地交換で交換できれば左上にバッチ」「タップしたら関係図の画面に飛ぶ」構成で実装に進むよう指示があった。

また、同じ相手の同じグッズが複数の Wish 行に出る可能性については、同じ partner × inventory item はホーム上では 1 件までに dedupe する方針で確定した。

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- 既存の「注目マッチ + タブ別カード一覧」を撤去し、`theirGives` を表示単位にした「Wishに届いた譲」一覧へ再構成。
- 相手の譲グッズを `キャラ名 × 種別` ごとの行にまとめ、各行を横スクロールの候補画像リストとして表示。
- 候補の優先度を、双方の個別募集が成立 → 片側の個別募集が成立 → 通常の譲 × wish 候補の順に並べるようにした。
- 同じ partner × inventory item は `seen` で 1 件までに dedupe。
- 現地交換できる候補は画像左上に `LIVE` バッジを表示し、行ヘッダーにも現地件数を表示。
- 候補画像を押したら既存の関係図モーダルを開くように接続。

#### `web/src/components/home/MatchDetailModal.tsx`
- 関係図モーダルを個別募集専用から、通常の譲 × wish マッチにも流用できる形に拡張。
- 個別募集がない候補では「あなたが受け取る / あなたが譲る」の簡易関係図を表示。
- 通常マッチ用の「この内容で打診へ」CTA を追加し、選択中の相手譲を `receives`、自分の譲候補を `gives` として `/propose/[partnerId]` に渡す。
- 既存の個別募集関係図・候補選択・在庫超過チェックは維持。

### 影響範囲

- `/` ホーム / マッチング画面
- ホームから関係図を開く導線
- 個別募集なしの通常マッチでの関係図表示
- `/propose/[partnerId]` への通常マッチ prefill 導線

### 確認方法

- `npx eslint src/components/home/HomeView.tsx src/components/home/MatchDetailModal.tsx`
- `npm run build`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/MatchDetailModal.tsx`

### セルフレビュー結果

- ✅ ホームの表示単位を「相手の譲グッズ画像」に変更
- ✅ `キャラ × 種別` ごとの 1 行表示に変更
- ✅ 双方個別募集 → 片側個別募集 → 通常候補の優先順を実装
- ✅ 同じ partner × inventory item の重複表示を抑止
- ✅ 現地交換できる候補に左上 `LIVE` バッジを表示
- ✅ タップ先は既存の関係図モーダルを流用
- ✅ 個別募集なしの候補でも関係図が空にならないよう簡易表示を追加
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新しい正式用語追加なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション151.9：取引一覧パネルの登場をゆっくり薄く調整

### 背景・問題意識

オーナーから、取引一覧のパネルについて「もう少しゆっくり出てくるようにしてほしい。最初は薄い状態から出てきて欲しい」と指示があった。

iter151.7 ではプロフ画面と同じ `animate-section-fade-down` を流用したが、取引一覧のカード群には少し速く、初期の薄さも弱かった。取引一覧専用の登場アニメーションに分離し、よりゆっくり、薄い状態から現れるようにする。

### 変更内容

#### `web/src/app/globals.css`
- `transactionPanelIn` keyframes を追加。
- 初期状態を `opacity: 0.08`、軽い `blur`、少し上方向の `translateY` に設定。
- duration を `760ms` にし、プロフ用の `460ms` よりゆっくり表示されるようにした。
- `prefers-reduced-motion` では既存どおりアニメーションを停止。

#### `web/src/app/transactions/TransactionsView.tsx`
- 取引一覧カード / 空状態のアニメーション class を `animate-section-fade-down` から `animate-transaction-panel-in` に変更。
- 打診中 / 進行中カードの stagger delay を `65ms` から `95ms` に拡大。
- 過去取引カードの stagger delay を `55ms` から `85ms` に拡大。

### 影響範囲

- `/transactions` 取引一覧
- 打診中 / 進行中 / 過去取引のカード登場アニメーション
- 取引一覧の空状態表示

### 確認方法

- `npx eslint src/app/transactions/TransactionsView.tsx src/app/globals.css`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/app/transactions/TransactionsView.tsx`

### セルフレビュー結果

- ✅ 取引一覧専用のゆっくりした登場アニメーションを追加
- ✅ 初期 opacity をかなり低くし、薄い状態から出るように変更
- ✅ stagger delay を広げ、カード群が急に出すぎないよう調整
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション151.8：注目マッチの現地ON/OFFカードサイズを統一

### 背景・問題意識

オーナーから、注目マッチのマッチングパネルについて「現地交換モードOFF中とON中とで、大きさが違っているので不自然。OFFモードの方の大きさに統一してほしい」と指摘があった。

原因は iter151.6 で、現地ONカードだけ外周オーラ用に `-m-3 p-3` を wrapper に持たせたこと。エフェクトは安定したが、注目マッチ内でカード本体の見え方が OFF カードより大きくなっていた。

### 変更内容

#### `web/src/components/home/MatchCard.tsx`
- local match wrapper の `-m-3 p-3` を削除。
- 現地ON/OFFともにカード本体のレイアウト寸法が同じになるよう `rounded-2xl` の通常 wrapper に統一。

#### `web/src/app/globals.css`
- 外周オーラ / 火花は wrapper の余白ではなく、疑似要素の negative inset で外側に出す方式へ調整。
- spark の配置をカード外側へ移し、カード本体サイズには影響しないようにした。

### 影響範囲

- ホーム / マッチング画面 `/`
- 注目マッチの `localAvailable=true` カード
- 通常マッチ一覧の `localAvailable=true` カード

### 確認方法

- `npx eslint src/components/home/MatchCard.tsx src/app/globals.css`
- `npm run build`

### 関連ファイル

- `web/src/components/home/MatchCard.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ 現地ONカードだけ wrapper padding / negative margin で大きくなる問題を解消
- ✅ OFFカードと同じカード本体サイズに統一
- ✅ エフェクトは疑似要素だけで外側に出し、カード寸法へ影響しない構造に変更
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション151.7：取引一覧の初期タブと表示アニメーションを修正

### 背景・問題意識

オーナーから、取引一覧画面について以下の指摘があった。

- 初期画面は「打診中」のはずだが、画面上部では「進行中」が選択されている表示になっている
- 「取引」ヘッダーと「打診中 / 進行中 / 過去取引」タブヘッダーの間に少し溝があり不自然
- それぞれのパネルが、プロフ画面のコンポーネントと同様に最初に現れる時に表示されてほしい

原因は `TransactionsView` の初期タブ state が `ongoing` になっていたこと。横スクロールの先頭は打診中だが、選択状態だけ進行中を指していた。また、上位の「取引」ヘッダーに border があり、直下のタブヘッダーとの境目が二段の区切りに見えていた。

### 変更内容

#### `web/src/app/transactions/TransactionsView.tsx`
- 初期タブを `ongoing` から `pending` に修正。
- `PendingList` / `OngoingList` / `PastView` に active 状態を渡し、表示中のタブだけカードへ `animate-section-fade-down` を付けるようにした。
- カードごとに `animationDelay` を付け、プロフ画面と同じ上からふわっと現れるスタガー表示にした。
- EmptyState も表示中タブでは同じ fade-down を使うようにした。
- React 19 purity rule に合わせ、`Date.now()` を render 中に呼ばず、初期 state の `now` をカードへ渡す形に整理。

#### `web/src/app/transactions/page.tsx`
- 「取引」ヘッダーの下 border を削除し、タブヘッダーと白背景が連続して見えるようにした。
- `invById` を `const` に変更し、対象 lint を通した。

### 影響範囲

- `/transactions` 取引一覧
- 打診中 / 進行中 / 過去取引のタブ選択表示
- 取引一覧カードの初期表示アニメーション

### 確認方法

- `npx eslint src/app/transactions/TransactionsView.tsx src/app/transactions/page.tsx`
- `npm run build`

### 関連ファイル

- `web/src/app/transactions/TransactionsView.tsx`
- `web/src/app/transactions/page.tsx`

### セルフレビュー結果

- ✅ 初期選択タブは「打診中」
- ✅ 取引ヘッダーとタブヘッダーの間の余計な区切りを削除
- ✅ 取引カード / 空状態にプロフ画面と同じ `animate-section-fade-down` を適用
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象ファイル ESLint / build 成功

---

## イテレーション151.6：現地マッチを外周オーラ表現へ変更

### 背景・問題意識

オーナーから、現地交換可能マッチの炎エフェクトについて「親の枠内にしか炎が波及してないから、途中でブツっとキレてる感じ」「思ったより炎じゃない」と指摘があった。また、マッチングパネル右上のユーザーアイコンやユーザーネームはもっと小さくしてよく、その下の説明文は不要との指示があった。

原因は、横スクロール / 縦スクロールの親要素が overflow を持つため、カード外側へ大きく出した blur がスクロール領域で切られて見えること。純粋な外側 blur だけで「炎の枠」を作るより、カード自身に発光用の余白を持たせ、そこに揺れるオーラと火花を置く方が安定して見える。

### 変更内容

#### `web/src/app/globals.css`
- `match-card-local-flame` を `match-card-local-aura` に置き換え。
- 外にはみ出す巨大 blur ではなく、カード外周の専用余白内で光が揺れる構造に変更。
- 上部 / 側面に小さな紫の火花 `match-card-local-spark-*` を追加し、単なる線ではなく LIVE 感のあるオーラ表現へ寄せた。
- `prefers-reduced-motion` ではオーラ / 火花アニメーションを停止。

#### `web/src/components/home/MatchCard.tsx`
- local match の wrapper を `-m-3 p-3` にし、カードサイズを保ったまま外周エフェクト用の余白を確保。
- local match 時に spark 用 span を追加。
- パートナー avatar を `featured: 32px / normal: 30px` に縮小。
- ユーザーネームを `12px`、距離を `9.5px` に縮小。
- match pattern の説明文（`pattern.sub`）をカード上から削除。

#### `web/src/components/home/HomeView.tsx`
- 注目マッチ横スクロールと通常リストの上下余白を増やし、外周オーラがスクロール領域で切れにくいように調整。

### 影響範囲

- ホーム / マッチング画面 `/`
- `localAvailable=true` のマッチカード外周表現
- マッチカード上部のプロフィール表示密度

### 確認方法

- `npx eslint src/components/home/MatchCard.tsx src/components/home/HomeView.tsx src/app/globals.css`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/components/home/MatchCard.tsx`
- `web/src/components/home/HomeView.tsx`

### セルフレビュー結果

- ✅ 親 overflow で切れやすい巨大外側 blur から、カード外周余白内のオーラ表現へ変更
- ✅ 紫の火花を追加し、単なる枠線より LIVE / 炎寄りに調整
- ✅ カード本体には色を乗せず、白背景を維持
- ✅ avatar / user handle / distance を小型化
- ✅ `pattern.sub` の説明文をカードから削除
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション151.5：マイ在庫の削除・操作アニメーションを Wish と統一

### 背景・問題意識

オーナーから、マイ在庫について「Wishと同じように削除するを押したらフェードアウトして自動整理されたり、削除以外のボタンを押したら、上に飛び跳ねる感じにしてほしい」と指示があった。

Wish 画面では iter149/150 で、削除は確認モーダル後に fade-out し、View Transitions API で残りのパネルが滑らかに詰まる。一方、マイ在庫は削除が `window.confirm` と即時 refresh のみで、編集・自分キープ・閉じるにも操作フィードバックがなかった。

### 変更内容

#### `web/src/app/inventory/InventoryView.tsx`
- 在庫削除を Wish と同じカスタム確認モーダルに変更。
- 「削除する」確定後、対象パネルに `animate-fade-out-back` を付けて奥へフェードアウト。
- fade-out 後に削除済み ID をローカルに保持して表示リストから外し、残りのパネルが自動整理されるようにした。
- View Transitions API が使える環境では `body.panel-deleting` を付け、並び替えを滑らかにした。
- サーバー削除は UI 反映後に実行し、失敗時は削除済み ID を戻してロールバック。
- 「編集する」「自分キープへ」「閉じる」は `animate-panel-bounce` で上に跳ねてから実行するようにした。

#### `web/src/app/globals.css`
- View Transitions API の適用対象に `body.panel-deleting` を追加。
- Wish 既存の `body.wish-deleting` も維持。

### 影響範囲

- `/inventory` マイ在庫一覧
- 在庫パネルタップ時のメニュー操作
- 在庫削除時の確認モーダル / fade-out / reflow

### 確認方法

- `npx eslint src/app/inventory/InventoryView.tsx src/app/inventory/ItemCard.tsx src/app/inventory/actions.ts`
- `npm run build`

### 関連ファイル

- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ 削除は確認モーダルの「削除する」後に fade-out
- ✅ fade-out 後に表示リストから外れ、パネルが自動整理される
- ✅ 編集 / 自分キープ / 閉じるは上方向バウンスを挟む
- ✅ Wish 既存アニメーション class を再利用し、手触りを統一
- ✅ `notes/09_state_machines.md` は状態追加なし、既存の削除遷移で表現済みのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象ファイル ESLint / build 成功

---

## イテレーション151.4：現地マッチ炎を外向きエフェクトに限定

### 背景・問題意識

オーナーから、現地交換で成立できそうなマッチカードについて「またパネル内に色がついてしまっている。色はつけなくていい。パネルの枠が外側に向かってエフェクトがでてる感じにしたい」と再指摘があった。

iter151.2 では `conic-gradient` を撤去したが、`match-card-local-flame` wrapper 自体に背景グラデーションが残っており、カード外周の padding / 角部分に色面が見えていた。また、local card でも match pattern の淡い背景色がそのまま残るため、「パネル内に色がつく」印象を消し切れていなかった。

### 変更内容

#### `web/src/app/globals.css`
- `.match-card-local-flame` 本体の背景を完全に透明化。
- 紫の炎表現は `::before` / `::after` の疑似要素だけに移動。
- 疑似要素をカード背面かつ外側へ広げ、カード本体の白背景で内側が覆われる構造にした。
- inset / blur / radial gradient を調整し、外側に向かって漏れる発光へ変更。

#### `web/src/components/home/MatchCard.tsx`
- local match の wrapper から `p-[2px]` を削除し、色付き padding が出ない構造に変更。
- `localAvailable=true` のカード本体背景を `#ffffff` に固定。
- local match のカード本体 border はニュートラルに戻し、紫の表現は外側エフェクトだけに限定。

### 影響範囲

- ホーム / マッチング画面 `/`
- `localAvailable=true` のマッチカード外周エフェクト

### 確認方法

- `npx eslint src/components/home/MatchCard.tsx src/app/globals.css`
- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`
- `web/src/components/home/MatchCard.tsx`

### セルフレビュー結果

- ✅ wrapper の背景グラデーションを撤去
- ✅ local match のカード本体背景を白に固定
- ✅ 紫の表現は疑似要素による外向き glow / flame のみに限定
- ✅ `notes/09_state_machines.md` は状態変更なしのため更新不要
- ✅ `notes/10_glossary.md` は新用語なしのため更新不要
- ✅ `notes/05_data_model.md` はデータモデル変更なしのため更新不要
- ✅ 対象 TSX ESLint / build 成功

---

## イテレーション151.3：マイ在庫メニューを削除導線へ整理

### 背景・問題意識

オーナーから、マイ在庫のパネルタップ時メニューについて「譲渡履歴へ」はなくし、「削除」を追加したいとの指示があった。

現在のメニューはステータス移動を中心に「譲る候補に」「キープに」「譲渡履歴へ」「編集する」「閉じる」が条件付きで並び、目的の操作順が読み取りにくかった。頻度の高い編集、自分用キープ、削除、閉じるだけに整理する。

### 変更内容

#### `web/src/app/inventory/InventoryView.tsx`
- パネルタップ時のメニューを上から「編集する」「自分キープへ」「削除」「閉じる」の固定順に変更。
- 「譲渡履歴へ」を削除。
- 「譲る候補に」「キープに」の条件分岐を廃止し、指定された操作だけを表示するよう整理。
- 「削除」は既存の `deleteInventoryItem` server action に接続し、実行前に確認ダイアログを出すようにした。
- 未使用だった `useTransition` を削除。

#### `web/src/app/inventory/ItemCard.tsx`
- ItemCardWrapper のメニュー説明コメントを実装後の4項目に更新。

### 影響範囲

- `/inventory` マイ在庫一覧
- 在庫パネルをタップした時のオーバーレイメニュー

### 確認方法

- `npx eslint src/app/inventory/InventoryView.tsx src/app/inventory/ItemCard.tsx src/app/inventory/actions.ts`
- `npm run build`

### 関連ファイル

- `web/src/app/inventory/InventoryView.tsx`
- `web/src/app/inventory/ItemCard.tsx`

### セルフレビュー結果

- ✅ メニュー順を「編集する」「自分キープへ」「削除」「閉じる」に統一
- ✅ 「譲渡履歴へ」は表示されない
- ✅ 削除は確認後に既存の削除 server action を呼ぶ
- ✅ `notes/09_state_machines.md` は既存の在庫削除遷移で表現済みのため更新不要
- ✅ `notes/10_glossary.md` は既存の「自分用キープ」「削除」で表現済みのため更新不要
- ✅ `notes/05_data_model.md` は新規フィールドなしのため更新不要
- ✅ 対象ファイル ESLint / build 成功

---

## イテレーション151.2：現地マッチ炎エフェクトを枠外周だけに修正

### 背景・問題意識

オーナーから、iter151 の現地交換可能カードについて「枠から紫の炎がメラメラなっている感じにしてと言ったはず。いま、DVDのディスク裏みたいにパネルの背景まで変わってしまっている」と指摘があった。

原因は `match-card-local-flame` の外側 wrapper に `conic-gradient` を使っていたこと。padding 部分に円盤状のグラデーションが見え、炎の枠ではなく面の模様として認識されていた。

### 変更内容

#### `web/src/app/globals.css`
- `conic-gradient` を廃止。
- カード本体の外側だけに radial gradient の火の舌を置く構造へ変更。
- `::before` を外周 glow / 火の揺らぎ、`::after` を紫の発光ラインとして使い、パネル本体の背景には干渉しないようにした。
- `matchFlameFlicker` も色相回転ではなく、透明度と微小な上下揺れに変更。

### 影響範囲

- ホーム / マッチング画面 `/`
- `localMatch=true` のマッチカード外枠のみ

### 確認方法

- `npm run build`

### 関連ファイル

- `web/src/app/globals.css`

### セルフレビュー結果

- ✅ ディスク状の `conic-gradient` を撤去
- ✅ パネル内側ではなく、カード外周だけに紫の炎/glow が出る構造に変更
- ✅ `prefers-reduced-motion` は既存どおり維持
- ✅ build 成功

---

## イテレーション151.1：現地モード候補が RLS で消える不具合修正

### 背景・問題意識

オーナーから「交換場所と交換時間、そしてグッズの情報的にマッチできるはずだけど、現地交換モードにしても候補に出ない」と報告があった。

原因は、ホームの現地モード絞り込みで「相手が現地モード ON か」を `user_local_mode_settings` から読む必要がある一方、このテーブルの RLS が本人行のみ参照可になっていたこと。通常の session client で他者の `enabled=true` 行を読めず、結果として `othersLocalModeOnRows` が空になり、相手 AW がすべて除外されていた。

### 変更内容

#### `web/src/app/page.tsx`
- `createServiceRoleClient` を import。
- `othersLocalModeOnRows` の取得だけ service role client に切り替え。
- 取得列は `user_id` のみに限定し、`last_lat` / `last_lng` / `selected_carrying_ids` / `selected_wish_ids` は取得しない。
- これにより RLS を緩めずに、サーバー内のマッチング処理だけが「相手が現地モード ON か」を判定できるようにした。

#### `web/src/lib/supabase/server.ts`
- service role client の使用シーンコメントに「RLS では直接公開しない派生情報のサーバー内集計」を追加。

### 影響範囲

- ホーム / マッチング画面 `/`
- 現地交換モードの候補表示
- 現地交換可能カードの `localMatch` / 炎フレーム表示

### 確認方法

- `npx eslint src/app/page.tsx src/lib/supabase/server.ts src/lib/matching.ts`
- `npm run build`
- Supabase 実データ確認：service role では `enabled=true` の local mode rows が取得でき、通常 client では RLS により 0 件になることを確認

### 関連ファイル

- `web/src/app/page.tsx`
- `web/src/lib/supabase/server.ts`

### セルフレビュー結果

- ✅ RLS を緩めず、サーバー側だけで `enabled=true` の user_id を取得
- ✅ 位置情報や選択グッズ配列は取得していない
- ✅ 状態遷移・用語・DBスキーマ変更なし
- ✅ 対象ファイル ESLint と build 成功

---

## イテレーション151：マッチング注目枠と候補パターン表示

### 背景・問題意識

オーナーから、マッチング画面について「ユーザーの利便性」と「マッチングを見つけるワクワクするプロセス」を両立したいという相談があり、以下の具体指示があった：

- 注目マッチ 3 件くらいを大きめに出し、その下に従来の一覧を並べる
- タブ名を短く分かりやすくする
- 個別募集がある候補では「打診する」押下時も詳細（関係図）へ進める
- 「相手プロフ →」ボタンをなくし、相手アイコン / ユーザーIDを押したらプロフへ遷移する
- 「相手の個別募集にもマッチ！」「個別募集マッチ」などの明示バナーを一旦非表示にする
- 個別募集の成立方向 5 パターン × 現地交換可能/それ以外 2 パターン = 10 パターンで表示差分を持たせる

### 変更内容

#### `web/src/components/home/HomeView.tsx`
- タブ名を `成立しそう` / `相手が欲しい` / `私が欲しい` / `探す` に短縮。
- 4 タブの通常一覧の上に、全マッチから上位 3 件を横スクロールの `注目マッチ` として大きめカードで表示。
- `MatchCard` に `featured` prop を渡し、注目枠ではカード内サムネイルと余白を少し大きく表示。
- `matchToCard` で `localAvailable` をカードへ渡すようにした。

#### `web/src/components/home/MatchCard.tsx`
- 個別募集ありカードから上部バナー（「相手の個別募集にもマッチ！」「個別募集マッチ」）を削除。
- 「セット」「いずれか OK」表示を詳細行から削除。
- 個別募集ありカードの `打診する` は、直接 C-0 へ行かず関係図モーダルを開く挙動に変更。
- 個別募集なしカードは従来通り `/propose/[partnerId]` へ進む。
- `相手プロフ →` ボタンを削除し、相手アバター / `@handle` を `/users/[id]` へのリンクに変更。
- 5 パターン表示を追加：
  - ① `双方の条件が交差`
  - ② `あなたの条件で候補`
  - ③ `相手の条件に応えられる`
  - ④ `片方向の候補`
  - ⑤ `譲 × wish 双方向`
- 各パターンに色、説明文、CTA 文言の差分を持たせた。

#### `web/src/lib/matching.ts` / `web/src/app/page.tsx`
- `Match.localMatch` を追加。
- 現地モード中に自分と相手の AW が重なっている候補へ `localMatch=true` を付与。
- 距離が取れない環境でも「現地交換できる可能性あり」を UI に出せるよう、`distanceMeters` と分離。

#### `web/src/app/globals.css`
- `match-card-local-flame` を追加。
- `localMatch=true` のカードだけ紫〜ピンク〜水色の揺れる炎風フレームを表示。
- `prefers-reduced-motion` ではアニメーションを停止。

### 影響範囲

- ホーム / マッチング画面 `/`
- マッチカード一覧
- 個別募集の関係図モーダルへの導線
- 相手プロフィールへの遷移導線

### 確認方法

- `http://localhost:3000/`
- `npm run build`
- `npx eslint src/components/home/HomeView.tsx src/components/home/MatchCard.tsx src/app/page.tsx src/lib/matching.ts`

### 関連ファイル

- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/MatchCard.tsx`
- `web/src/lib/matching.ts`
- `web/src/app/page.tsx`
- `web/src/app/globals.css`
- `notes/10_glossary.md`

### セルフレビュー結果

- ✅ 注目マッチ 3 件を通常一覧の上に追加
- ✅ タブ名を短縮
- ✅ 個別募集ありカードの `打診する` を関係図モーダルへ変更
- ✅ 個別募集なしカードは従来通り C-0 へ遷移
- ✅ `相手プロフ →` ボタンを削除し、相手アイコン / ID をプロフリンク化
- ✅ 「個別募集マッチ」系の上部バナーを非表示化
- ✅ 「セット」「いずれか OK」表示を削除
- ✅ 5 パターン × 現地可否 2 パターンの表示差分を追加
- ✅ 状態遷移・DBスキーマ変更なし（`localMatch` は画面用の計算結果）
- ⚠️ 全体 `npm run lint` は既存の別画面エラーで失敗。今回変更ファイルに絞った ESLint と build は成功

---

## 現状サマリ

### 完了画面
ホーム → C-1〜C-3（打診→チャット→取引完了）→ B-1〜B-3（在庫管理＋撮影＋X投稿）→ AW（参戦予定編集）→ 一括再訪 → C-3 相違あり詳細フロー → コレクション図鑑（4画面）

### ファイル状況
- `Megrum MVP.html`（統合版、4セクション×18アートボード）
- `Megrum Dispute Flow _standalone_.html`（8.7MB、Dispute Flow 10画面）
- コレクション図鑑（独立4画面、ファイル名未確認）

### 完了確認（直近 イテレーション15・16）
- Dispute Flow standalone：前回フィードバック（②'ラベル修正・「任意で追加」明示・進捗バー3パターン分岐・申告者名警告・キャンセル理由中立化・⑥b評価ロジック）すべて反映済
- コレクション図鑑 4画面：F10達成感の具現化、譲るとして登録CTA・探し中パルス＋所持ユーザーリスト・コンプ演出、ハナ評価95点

---

## 確定設計判断（28項目）

詳細は [07_mvp_handoff.md](07_mvp_handoff.md) 参照。要約：
- 現地交換特化MVP／ジャンル横断スタート（KPOPから）／全公開モデル
- 4タブマッチング＋昇格導線／打診プロセス（両者通知→打診→諾否）／L4多者間はMVP外
- C-3① 証跡撮影：「左=相手 / 右=自分」固定
- AW 編集案①／② 両方残す（事前計画／当日現地）

---

## MVP仕様への追加機能（採用済 24件）

| # | 機能 | 出処 |
|---|------|------|
| 1 | メッセージトーン切替（標準／カジュアル／丁寧） | C-1 |
| 2 | 推奨合流ポイント自動提案＋@Megrum推奨バッジ | C-1 |
| 3 | 取引完了時のX連携自動投稿 | C-3 |
| 4 | 「今すぐ交換」エクスプレス（5分以内合流） | AW |
| 5 | クローズ時間自動促進通知 | AW |
| 6 | 終了AWの自動アーカイブ | AW |
| 7 | AW一時無効トグル | AW |
| 8 | QR本人確認（相互スキャン） | C-2 |
| 9 | 送信前確認モーダル | C-1 |
| 10 | 服装写真の撮影 › CTA | C-1 |
| 11 | 「相違あり」進捗3ステップ表示 | C-3 |
| 12 | 「相違あり」5種カテゴリ（ドタキャン/遅刻分離） | C-3詳細 |
| 13 | 仲裁SLA（当日4h／それ以外24h） | C-3詳細 |
| 14 | 申告中の打診凍結（共に新規のみ） | C-3詳細 |
| 15 | 反論機会付与（相手側通知） | C-3詳細 |
| 16 | 受付番号採番 | C-3詳細 |
| 17 | 24h残時間カウンタ | C-3詳細 |
| 18 | 「書き方のコツ」アドバイス | C-3詳細 |
| 19 | キャンセル＝警告色／遅刻＝通常色 | 関連フロー |
| 20 | 遅刻30分以上→相手側キャンセル可 | 関連フロー |
| 21 | コンプ達成バッジ＋演出（MVP静的） | コレクション図鑑 |
| 22 | 図鑑→wish自動追加（1タップ） | コレクション図鑑 |
| 23 | 取引成立時の写真を図鑑で表示 | コレクション図鑑 |
| 24 | コレクションのXシェア | コレクション図鑑 |

---

## ターン1 実行内容（次のスコープ）

### A. Bフロー軽微修正
- 「下書き」→「**登録中**」表記統一
- 「自動」→「**補正**」（傾き・コントラスト補正の意）
- B-2 撮影モード3つ（通常／クイック／連続）の説明テキスト追加

### B. コレクション図鑑微調整
- ①「推し全員」→「全メンバー」リネーム
- ③ メトリクス3つ並びレイアウト修正
- ②「譲るとして登録」CTA は MVP採用済として維持
- ④ 達成メタは静的表示＋PRD付記
- ④ コンプ演出は静的SVG＋フルアニメは後フェーズ明記

### C. Dispute派生 B-1／B-2 画面追加（既存 Dispute Flow に派生）

| ID | 画面 | 仕様 |
|----|------|------|
| B-1 | 運営追加情報リクエスト UI | **D-5d 派生**として作る。仲裁中ステータスの「運営に追加情報を送る」ボタンの中身。進捗バーに「運営からの追加質問」ステップ挿入。中身：質問本文＋返信テキスト＋追加証跡アップロード。**「24時間以内に回答」表記入れる** |
| B-2 | 再審査申請＋受付ステータス | **D-6 から「結果に納得いかない場合」リンク → シンプル申立てフォーム**（理由500字＋追加証跡）。申立て後「**再審査受付中(48h)**」ステータス表示 |

### D. B-3 評価保留中バッジ仕様（今ターンは仕様確定のみ、実装はターン2）
- プロフ画面（自分／他者）：「★4.7 取引89回 ／ **保留中 1件**」サマリ表示
- ホーム画面マッチカード：「★4.5 取引157」に **「保留中1件」**追記
- 取引タブ（ターン2で作る）：保留中の取引行に**「保留中」バッジ**

---

## ターン分割計画

```
ターン1（実行中）：Bフロー軽微修正＋図鑑微調整＋Dispute派生 B-1/B-2
ターン2：MVP必須未画面化4画面（取引タブ／規約違反通報／運営問い合わせ／設定）
ターン3：オンボーディング（性別→推しグループ→メンバー→AW初期設定）
ターン4：MVP仕様書 v2 反映＋ハンドオフ完成
```

---

## MVP必須の未画面化エリア（ターン2以降で対応）

| # | 領域 | 必須度 | 備考 |
|---|------|--------|------|
| D | **取引タブの中身**（ボトムナビ） | **最重要** | 打診中／進行中／過去取引のタブ構成 |
| E | 利用規約違反通報 | 必須 | C-3 とは別系統、ユーザー単位の通報 |
| F | 運営問い合わせ動線 | 必須 | FAQ・規約違反・本人確認・機能要望 |
| G | 設定画面（最小版） | 必須 | 通知・プライバシー・アカウント管理 |

---

## 残課題（小）

- ⑤b（相手が認めた）／⑤c（24h無回答）の「提出済み証跡」セクションのラベル分岐（コピー artifact 可能性）
- 「相手の反論」詳細の開示範囲（プライバシー設計確定要）
- B-3 評価保留中バッジの実装（ターン2の取引タブ＋既存マッチカードで反映）

---

## 過去のイテレーション索引（参考のみ）

- 1〜4：ホーム＋C-1〜C-3 visual＋方針確定
- 5〜8：B 在庫管理＋撮影＋X投稿（11質問回答→出力評価）
- 9〜10：AW 方針＋一覧＋他人プレビュー（11質問→出力評価）
- 11：統合ファイル一括再訪（蓄積フィードバック消化）
- 12〜13：C-3 相違あり詳細方針（8質問→Dispute Flow 10画面出力）
- 14〜15：コレクション図鑑方針＋Dispute standalone 反映確認
- 16：コレクション図鑑 4画面出力（95点）
- 17：ターン1 完了（Bフロー軽微修正＋図鑑微調整＋Dispute派生3画面）

---

## イテレーション17：ターン1 完了確認

### 反映確認 ✅

**Bフロー軽微修正**：
- 「下書き保存中」→「登録中」（aw-edit）
- 「自動生成」→「補正済」「下書き作成」（b-inventory）
- B-2 撮影モード3種に説明＋現在モード説明バッジ

**図鑑微調整**：
- 「推し全員」→「全メンバー」
- メトリクス3つを単独カード化（ラベル位置上、数字大きく）

**Dispute派生3画面（既存ファイル拡張）**：
- ⑤d 運営追加質問：質問本文＋返信フォーム＋追加証跡＋24h残カウント
- ⑥c 再審査申立て：4種理由区分＋500字本文＋追加証跡＋7日期限
- ⑥d 再審査受付ステータス：48h可否判断＋進捗4ステップ＋評価再保留

### 気になる小さな点（次マイルストーン対応で OK）

1. **⑥d 進捗の「部下通知」タイポ** → 「結果通知」が正解
2. **⑤d「保存」ボタンの挙動補助**（ホバーテキスト or サブラベル）
3. **⑥c 理由区分の文言ソフト化**（事実認定に誤り → 事実の判断に納得できない 等）

---

## ターン2 仕様確定

### D. 取引タブ
- **3タブ構成**：打診中／進行中／過去取引
- **打診中タブ**：統合表示＋方向アイコン（送信→/受信←）＋行内ラベル「打診を送った/届いた」
- **進行中タブ**：B-3 評価保留中バッジ表示（仲裁中ステータスへの導線）
- **過去取引タブ**：完了＋キャンセル済両方含む／フィルタチップ（すべて／完了／キャンセル／申告不成立）／新着降順デフォルト＋★順・相手別ソート／各完了行に「コレクション図鑑へ」リンク／B-3バッジも表示
- **空状態UI**：3タブそれぞれに必須（次のアクション CTA 付き）

### E. 利用規約違反通報
- **起動口**：プロフ「・・・」メニュー＋ブロック後ボトムシート連携 の両方併設
- **理由カテゴリ**：6種（嫌がらせ／スパム／偽装／詐欺／不適切な内容／その他）＋「不適切」の例示プレースホルダー
- **証跡**：スクショ任意×3＋本文500字
- **通報後**：完了画面＋「ブロックする」CTA＋受付番号 #REP-xxxx 採番（C-3 #DPT- と整合）＋「48-72h で運営確認」表記

### F. 運営問い合わせ動線
- **構成**：FAQ一覧（検索バー付き）→「問い合わせる」CTA → カテゴリ選択 → フォーム の3ステップ
- **カテゴリ**：5種（機能の使い方／不具合報告／本人確認／機能要望／その他）
- **FAQ**：MVPは10件程度（5カテゴリ×2件）
- **返信**：メール優先＋アプリ内プッシュ通知（両方）

### G. 設定画面（最小版）
- アカウント（プロフ編集／推し設定／本人確認状態）
- 自分の AW 一覧
- 通知設定（プッシュ／メール、トピック別）
- プライバシー（ブロックリスト／公開範囲）
- ヘルプ＆問い合わせ（→ F へ）
- 利用規約／プライバシーポリシー
- **アプリ情報（バージョン・利用状況サマリ）** ← ハナ追加
- ログアウト／アカウント削除

### 配置場所
**新規ファイル**（仮）`Megrum MVP Surfaces.html` または `Megrum Account & Support.html`
- 4画面が密接に関連、別ファイルで管理

---

## イテレーション18：ターン2 完了確認（11画面）

### 反映確認 ✅

**D. 取引タブ（4画面）**：3タブ＋件数バッジ／送信→/←受信ラベル／申告中・仲裁中分離表示＋DPT番号＋SLA残時間／過去取引フィルタ4種＋図鑑リンク／空状態UI

**E. 規約違反通報（2画面）**：6カテゴリ＋説明文／受付番号#REP-3942／ブロックCTA連携

**F. ヘルプ・問い合わせ（2画面）**：FAQ検索＋クイックリンク＋アコーディオン／5カテゴリ＋環境情報自動添付

**G. 設定（3画面）**：プロフィールチップ／AW一覧ハブ＋本日バッジ＋未設定警告／通知トピック別12項目＋夜間モード

### 重要な flag 🚨：ボトムナビ変更

**「ホーム／在庫／取引／ウィッシュ／プロフ」→「ホーム／探索／取引／図鑑／マイ」** に変更されている。

- **要確認**：在庫管理・ウィッシュ管理の動線（マイ→深い階層？）
- **要確認**：「探索」タブと「ホーム画面の探索タブ」の関係
- 影響範囲：ホーム画面・B-1（在庫管理）・ウィッシュリスト管理

### 残った小さな点
- E通報：虚偽通報警告が画面で目立たない、CTA直前に注記検討
- 「Bフロー軽微修正」「図鑑微調整」の反映を画面で再確認したい

---

## 次の推奨：ホーム画面見直し → PRD更新 → オンボーディング

```
次：(b) ホーム画面の見直し（ボトムナビ整理＋Bフロー再確認＋マッチカード密度）
↓
(c) PRD更新（MVP仕様書 v2、採用機能30件超を反映）
↓
ターン3：オンボーディング（性別→推しグループ→メンバー→AW初期設定）
↓
ターン4：MVP最終ハンドオフ
```

---

## ボトムナビ確定（仕様書準拠＋役割分担明確化）

| # | タブ | 役割 | 中身 |
|---|------|------|------|
| 1 | **ホーム** | マッチ提案（出会いの場） | 4タブ：完全マッチ／私の譲が欲しい人／私が欲しい譲を持つ人／探索 |
| 2 | **在庫** | 自分の在庫管理（CRUD） | B-1〜B-3：一覧＋撮影＋X投稿、携帯モード切替、コレクション進捗バー |
| 3 | **取引** | 取引の進捗・履歴 | D：打診中／進行中／過去取引 |
| 4 | **ウィッシュ** | 自分のwish管理 | wish一覧＋優先度＋flexibility＋「探し中」ステータス |
| 5 | **プロフ** | アイデンティティハブ | プロフ編集／推し設定／**私の図鑑**／取引履歴サマリ／**自分のAW一覧**／**設定**（ヘルプ・問い合わせ・通報含む） |

### 動線確定
- **図鑑（F10・4画面）**：プロフ → 「私の図鑑」セクション → 図鑑詳細
  - 深いリンク：C-3取引完了の「あと5枚でコンプ」、取引タブ完了行「図鑑で見る ›」
- **設定（G・3画面）**：プロフ → 「設定」リンク
- **AW一覧（G-②）**：プロフ → 「自分のAW一覧」または「+AWを追加」
- **問い合わせ（F・2画面）**：プロフ → 設定 → ヘルプ＆問い合わせ
- **規約違反通報（E・2画面）**：プロフ画面の「・・・」メニュー or ブロック後ボトムシート連携
- **マッチ通知**：ホーム画面の「私が欲しい譲を持つ人」タブに集中（ウィッシュタブとは重複させない）

### ウィッシュタブ仕様（新規画面）
- 自分のwish一覧 CRUD
- 各行に：グッズ画像＋名前／優先度バッジ／flexibility表示／**「探し中」ステータス**（マッチあり◯件・AW近隣◯人・◯日前から探し中）
- タップで編集（優先度・flexibility・通知設定）

### (b) ホーム見直しのスコープ
1. ボトムナビを「ホーム／在庫／取引／ウィッシュ／プロフ」に戻す
2. プロフタブを **アイデンティティハブ**に再構成（図鑑・AW・設定・履歴を集約）
3. ウィッシュタブを新規作成（CRUD＋ステータス）
4. Bフロー軽微修正の画面確認（下書き→登録中、自動→補正）
5. マッチカード密度・優先度ロジック可視化の調整
6. **AW 仕様の修正**（重要）

---

## AW 仕様の修正（イテレーション18.5）

### 問題発覚
Claude Design の現状実装：
- AW = "**Active Window**"（アクティブウィンドウ）と誤解釈
- 「**イベントに参戦している／する予定**」が前提
- 位置主導モードでも「自動でイベントを推測」
- マッチングが「同じイベント参戦者」基準

### 確定仕様の再確認
[確定設計判断 #1] **「現地」の射程 = 場所＋時間の Availability Window を基本、イベントは便利タグ**

- AW = "**Availability Window（合流可能枠）**"
- 基本データモデル = 場所×時間×半径
- イベント = optional tag、UX ショートカット
- **イベントなしでも AW は成立**（販売会・突発交流・空き時間の現地交換等）

### 修正項目

| 項目 | 修正内容 |
|------|---------|
| AW 略称の意味 | "Availability Window（合流可能枠）" を明記 |
| AW 編集画面 | 位置主導で「イベントを紐付けない」を明示的に許容（イベント任意） |
| AW 一覧画面 | イベント名のないAWの表示パターン追加（例：「渋谷駅周辺 / 4/30 14:00-16:00」） |
| ホームのマッチ提案 | 「時空交差」が基本、イベント一致は加点要素として明記 |
| 画面文言 | 「参戦予定」→「合流可能枠」or「予定」、イベント前提でない表現に |

### 修正規模
軽微〜中規模（データモデルは元々 `availability_windows.event_id` nullable で設計済、UI と文言の調整が中心）

---

## 在庫＋コレクション図鑑 仕様修正（イテレーション18.6）

### 問題発覚
1. 在庫タブと図鑑タブが分離 → ナビ冗長
2. 図鑑が「シリーズ全種類コンプ」前提 → ヲタの楽しみ方が画一的
3. シリーズ全件カタログ化が運営負担として非現実的
4. 「自分用キープ」を表現する仕組みがない

### 新仕様（在庫タブに統合 ＋ wish ベース図鑑）

#### ボトムナビ
- 図鑑タブを廃止、「ホーム／在庫／取引／ウィッシュ／プロフ」のまま
- プロフから「コレクションサマリ」の小さい表示のみ

#### user_haves に新ステータス
- 既存：active / reserved / traded / withdrawn
- 追加：**keep**（自分用キープ、マッチング対象外、図鑑には反映）

#### 在庫タブの構造
- 上タブ：譲るもの / 求めるもの
- 譲るもの内のサブビュー：譲る候補 / 自分用キープ / 過去に譲った
- **表示モード切替**：📋 リスト / 📚 コレクション

#### コレクション表示モード（wish ベース）
| 状態 | 表示 |
|------|------|
| wish登録＋未取得 | シルエット＋「探し中」 |
| wish登録＋取得済（active/keep/traded 経験） | カラー |
| wish未登録 | 表示されない |

#### 達成演出の発火条件
- 旧：「シリーズ全種類取得」 → **廃止**
- 新：**「フィルタした範囲の wish 全件取得」** で発火
- 例：「スアのwish 4件全部取得」→「スアコレ コンプ達成！」演出

#### データモデル簡素化
- シリーズマスタの「全件カタログ化」は **不要**
- 運営マスタはジャンル → グループ → メンバー → グッズ種別の階層のみ
- コンプ判定は wish 基準で動的計算

### 修正対象ファイル
- Megrum B Inventory.html（表示モード切替＋3サブビュー＋コレクション表示）
- Megrum B Inventory.html（メタ入力に譲る/自分用キープ2択）
- Megrum Collection Pokedex.html → **廃止**
- Megrum Hub Screens.html プロフハブ（コレクションサマリのみ）
- Megrum Home v2.html（マッチカードの文言を個人達成ベースに）
- Megrum C Flow.html C-3（「あと◯枚でコンプ」を個人達成ベースに）

### 反映確認（イテレーション19）

✅ ナビ統一5タブ：ホーム／在庫／取引／ウィッシュ／プロフ
✅ リスト／コレクション切替の上タブ
✅ 3サブビュー（譲る候補 / 自分用キープ / 過去に譲った）＋切替時の説明文
✅ コレクション表示の wish 基準フィルタ（全wish 14 / スアのwish 4 / ヒナのwish 5）
✅ 「スアのwish 4/4 コンプ達成！」演出＋達成記念バッジ＋Xに投稿CTA
✅ 求めるもの ↔ ウィッシュタブの同期説明
✅ 重複検出警告「似たトレカが2件あります」

### 残った確認希望（次回スクショ）
- B-2 メタ入力 STEP3 の「譲る／自分用キープ」トグル
- コレクション表示で未取得 wish のシルエット表示
- 達成前のコレクション表示
- プロフハブの「コレクションサマリ」縮小版
- 達成記念をXに投稿 CTA の表示条件（常時？達成時のみ？）

---

## 進行中タスクと次のステップ

| # | タスク | 状態 |
|---|--------|------|
| A | 在庫＋コレクション統合 | ✅ 反映済 |
| B | AW仕様修正（位置主導でイベントなし可） | 反映状況要確認 |
| C | ターン3 認証＋オンボーディング | 投げ準備済 |
| D | (b) ホーム見直し＋プロフハブ＋ウィッシュタブ | ターン1の本来作業（再開） |
| E | ターン4 MVP仕様書 v2 ＋ハンドオフ | 最後 |

### 推奨順序
1. AW修正の反映確認
2. ターン3（認証＋オンボーディング）投げ
3. (b) ホーム見直し＋プロフハブ＋ウィッシュタブ
4. ターン4 PRD更新でMVP完成

---

## イテレーション19.7〜19.9：コレクション機能の最終整理

### 19.7 コレクションを在庫→ウィッシュへ移動
在庫タブに「リスト/コレクション切替」を入れていたが、コンセプト的に矛盾。
コレクションは wish 基準の達成感ビュー → ウィッシュタブへ移動

### 19.8 ウィッシュタブからもコレクション削除
ウィッシュ＝欲しいもの一覧、シンプルさ優先。コレクション機能は不要と判断。
- `WishlistCollection` / `WishCollectionTile` を hub-screens.jsx から削除
- `WishlistList` の view toggle 削除
- Megrum Hub Screens.html から「コレクション表示」アートボード削除
- ウィッシュタブはリスト・空状態・編集 の 3画面のみ

### 19.9 自分用キープへの影絵追加案 → 不採用（A: 現状維持）
ヲタの達成感ビューを自分用キープにリッチ化する案を検討したが、ウィッシュリストとの機能重複を避けて却下。

### 達成感の演出は C-3 取引完了画面のみに残る
日常的に達成度を眺める専用画面はなし。取引で wish が埋まった瞬間にだけ演出。

### 最終的なタブ構造（確定）

| タブ／ビュー | 役割 |
|------------|------|
| ホーム | マッチ提案 |
| 在庫・譲る候補 | 譲渡可能な手持ち |
| 在庫・自分用キープ | 譲らない手持ち（シンプル一覧） |
| 在庫・過去に譲った | 履歴 |
| 取引 | 進捗・履歴 |
| ウィッシュ | 欲しいもの一覧 |
| プロフ | アイデンティティ・設定 |

---

## イテレーション68.1：C-2 大幅 UX 改善 + 証跡複数枚 + 戻る導線

### 背景

iter68-B〜F を実機確認したオーナーから複数フィードバック：

> ・待ち合わせ場所の地図がめっちゃ小さい → タップで拡大ポップアップ
> ・交換内容を画像で見せて。1 行超過時はタップで詳細ポップアップ
> ・メッセージ横の ＋ ボタンの「向かう/到着」3 サイクルは使いにくい → クイックアクション行に「向かっています / 到着しました」2 個を追加
> ・服装写真シェアセクションが画面占有しすぎ → コンパクト 1 行に
> ・証跡は複数枚撮れるように、修正もできるように
> ・撮影したら前のチャットに戻れない → 撮影完了したら自動で「✓ 取引証跡が届きました」system message が投稿され、タップで /approve に遷移する流れに

### 変更内容

#### A. DB マイグレーション（`20260503240000_proposal_evidence_photos.sql`）

`proposal_evidence_photos` テーブル新設：
- `proposal_id × position` で複数枚管理
- `taken_by` ＋ unique(proposal_id, position) で撮影順保持
- RLS：参加者 read/insert、撮影者本人のみ delete
- 旧 `proposals.evidence_photo_url` は **互換ミラー** として残す（最初の写真の URL）

#### B. server actions 拡張

**新規**：
- `addEvidencePhoto(proposalId, photoUrl)` — 1 枚追加 + 撮影者は自動承認 + position 自動採番
- `removeEvidencePhoto(photoId, proposalId)` — 撮影者本人のみ削除可
- `notifyEvidenceComplete(proposalId, photoCount)` — 撮影完了をチャットに system message として投稿（meta.action='open_approve' で tap 可能カードに）

**旧 `setEvidencePhoto`** は撤廃して上記に置き換え。

#### C. C-2 ChatView 改修（コンパクト + リッチ）

**取引内容カード**：
- アイテムを **画像（ItemThumb）** で表示（写真 or イニシャル + 数量バッジ ×N）
- PREVIEW_MAX=2 件まで横並び、超過は「+N」で省略
- カード全体タップで `TradeDetailModal`（ボトムシート）が開く
  - 拡大版アイテム（48×64px）+ 名前 + 種別を grid 表示
  - 「📍 待ち合わせ場所を地図で見る」リンク
- 待ち合わせ部分の mini map を **44×68px** に縮小、タップで `MapModal`（中央 360px 大画面）

**地図モーダル `MapModal`**：
- 黒背景 + 92% width 白カード
- 360px 高で大きく地図表示、ピン操作不可（read-only）
- 待ち合わせ日時 + 場所表示
- 「地図アプリで開く →」リンク

**服装写真シェア → コンパクト 1 行**：
- 「👕 服装写真　あなた：未シェア / @相手：✓共有済　[📷撮影]」
- 紫枠の薄背景 + 1 行 + クリッカブル
- 旧グラデバナー（80px height）→ 30px に縮小

**クイックアクション行（5 chip 横スクロール）**：
- 現在地を送る（lavender）
- **向かっています**（lavender、active 時に紫塗り）← 新規
- **到着しました**（emerald、active 時に緑塗り）← 新規
- 服装写真（pink）
- 写真添付（neutral）
- ＋ メニュートグル削除（クイックアクションに統合）

**system message 拡張**：
- `meta.action='open_approve'` を持つ system message は **タップ可能カード**として描画
  - 紫枠 + 薄グラデ背景
  - 「✓ 取引証跡が届きました（N枚） — タップで取引完了の確認画面へ →」
  - クリックで `/approve` に遷移

#### D. page.tsx：強制 redirect 撤廃

**旧**：撮影済み → `/approve` 強制 redirect。撮影後にチャットに戻れない問題。

**新**：
- 撮影済みでもチャット画面に留まれる（再撮影 / メッセージ送信可）
- system message からタップで `/approve` へ任意遷移
- 完了済かつ未評価のときのみ `/rate` に redirect（評価リマインド）

#### E. CaptureView（複数枚 + 戻る）

**追加**：
- 上部右端に「N 枚」カウンタ
- 既存写真の **ギャラリー**（横スクロール、自分の写真は ✕ で削除可）
- ビューファインダーをギャラリー有無で位置調整
- 撮影コントロールに **「完了 →」** ボタン（紫グラデ pill）
  - タップで `notifyEvidenceComplete` → chat に system message 投稿 → `/transactions/[id]` に戻る
  - チャットの「✓ 取引証跡が届きました」をタップで `/approve` に進む
- 撮影コントロールの「履歴」を **「←」（チャットに戻る）** に置換
- 上部 ✕ も `Link` でチャット画面へ
- 1 枚も無い状態で「完了」は disabled + グレーアウト

#### F. ApproveView（複数枚ギャラリー）

- props を `photoUrl` (single) → `photos: ApprovePhoto[]` (gallery) に変更
- 写真はカード化して縦に並べる（# 番号 + メタストリップ）
- 上部に「**追加撮影 / 差し替え →**」リンク（`/capture` へ戻る）
- page.tsx で `proposal_evidence_photos` を fetch、0 枚時は capture に redirect

### 影響範囲

- DB：新テーブル `proposal_evidence_photos` 追加
- 取引チャット画面：UI 大幅刷新（コンパクト化 + 画像化 + モーダル群）
- 撮影画面：複数枚対応、戻る導線、完了通知
- 承認画面：複数枚ギャラリー
- フローの強制 redirect が緩和され、ユーザーが自由に行き来できる

### 設計判断

- **「✓ 取引証跡が届きました」はチャットに残る system message として投稿**：履歴に残る + 後から再 tap 可能 + 相手にも伝わる
- **複数枚は position で順序保持**：1 枚目がメイン（互換のため `proposals.evidence_photo_url` にミラー）
- **削除権限は撮影者本人のみ**：別の参加者が勝手に消せない
- **モーダル群は ChatView 内に分離コンポーネント化**：再利用しやすく、レビューしやすい
- **クイックアクションを 5 chip に**：「向かう/到着」を独立 chip にすることで、＋ メニュー不要に。視認性向上

### TODO

- iter69-A：服装写真 / 通常写真 の Storage upload UI（chat-photos バケットは既存）
- iter69-B：QR ジェネレーター
- iter69-C：dispute 本実装
- iter69-D：期限自動切替 cron
- iter69-E：Supabase Realtime（5 秒 polling 撤廃）

### 関連ファイル

**Migration**：
- `supabase/migrations/20260503240000_proposal_evidence_photos.sql`

**Server actions**：
- `web/src/app/transactions/actions.ts`（addEvidencePhoto / removeEvidencePhoto / notifyEvidenceComplete）

**ルート**：
- `web/src/app/transactions/[id]/page.tsx`（redirect 緩和、複数 evidence fetch）
- `web/src/app/transactions/[id]/ChatView.tsx`（全面 UX 刷新、5 モーダルコンポーネント追加）
- `web/src/app/transactions/[id]/capture/page.tsx` + `CaptureView.tsx`（複数枚、戻る、完了通知）
- `web/src/app/transactions/[id]/approve/page.tsx` + `ApproveView.tsx`（ギャラリー化、差し替えリンク）

---

## イテレーション68-B〜F：C-2 デザイン整合性修正 + C-3 撮影/承認/評価フル実装

### 背景

iter68-A の C-2 チャットを実機確認したオーナーから「ちょいちょいデザインと違う」指摘。
CLAUDE.md の「画面実装時の絶対ルール」通り、c-flow.jsx を精読してセルフレビュー → 修正。
ついでに C-3（撮影 / 双方承認 / 評価+コレクション）まで一気に実装。

### セルフレビュー結果（C-2）

c-flow.jsx の `ChatScreen` 実装と私の前 iter 実装の差分：

| 項目 | デザイン | 前実装 | 修正 |
|---|---|---|---|
| ヘッダー右上 | 「QR」chip ボタン | 無し | ✅ 追加 |
| 取引内容カード | mini map サムネ + 詳細 | 単純 grid | ✅ MapPicker 埋め込み |
| 服装写真セクション | **紫グラデバナー** + 双方ステータス + 白い大ボタン | 薄ボックス | ✅ グラデ化 |
| クイックアクション | 入力欄上に **常時 chip** 横並び | ＋ メニュー | ✅ 常時表示 |
| メッセージ day separator | 中央チップで日時 | 無し | ✅ 追加 |
| 到着システムメッセージ | 緑チップ + 動的色 | 部分的 | ✅ 強化 |
| 「合流したら証跡撮影」案内 | dashed border + 撮影 CTA | 無し | ✅ 追加（C-3 入口） |

### 変更内容

#### A. DB マイグレーション

**`20260503220000_proposal_evidence_and_evaluations.sql`**：
- `proposals` に追加：
  - `evidence_photo_url text`、`evidence_taken_at timestamptz`、`evidence_taken_by uuid`
  - `approved_by_sender boolean`、`approved_by_receiver boolean`
  - `completed_at timestamptz`
- `proposals.status` CHECK に `'completed'` 追加
- `user_evaluations` 新設：
  - proposal_id × rater_id × ratee_id × stars(1-5) × comment
  - `unique (proposal_id, rater_id)` で 1 取引 1 評価
  - RLS：参加者のみ read、completed のみ insert

**`20260503230000_chat_photos_bucket.sql`**：
- Supabase Storage バケット `chat-photos` 作成
- パス：`{proposal_id}/{type}-{timestamp}.{ext}`
- RLS：参加者のみ read/upload、自分の object のみ delete

#### B. C-2 チャット改修（`ChatView.tsx` 全面書き直し）

**新コンポーネント**：
- `ChatHeaderBar`：相手アバター + 到着ステータス + QR ボタン
- `DealCard`：取引内容カード（紫枠＋mini map サムネ）
- `OutfitShareBanner`：紫グラデの服装写真シェアバナー（双方ステータス + 白いボタン）
- `EvidenceCallout`：合意済 + 撮影前のときに「合流したら証跡撮影」dashed カード
- `QrModal`：QR 確認モーダル（簡易、QR ジェネレーターは次イテ）
- `QuickChip`：lavender / pink / neutral 3 トーン
- メッセージ day separator + 強化された arrival_status バブル

**動作**：
- 入力欄左の ＋ ボタン → 「向かう / 到着 / 離脱」3 サイクルトグル
- 入力欄上に「現在地を送る / 服装写真 / 写真添付」常時表示
- メッセージ送信時に自動下スクロール
- 5 秒 polling で相手のメッセージを取得

#### C. C-3 取引証跡撮影画面（`/transactions/[id]/capture`）

c-flow.jsx `CaptureStep` 準拠：
- 黒背景＋紫グラデ装飾
- ヘッダー：✕ 戻る + 「オフライン保存」chip
- タイトル：「取引証跡を撮影 / 両者の交換物を1枚に収めてください」
- ビューファインダー：紫枠 + 4 隅コーナーマーク + 中央 dashed line + ↔ 白円
  - 左右に myCount/theirCount 分のゴーストカード（傾き付き）
  - 「相手のN点」「あなたのM点」黒チップ
- Hint chip：「自動メタ: HH:mm · 場所」
- 撮影コントロール：履歴 / シャッター（白い大円） / メニュー

**実装**：
- `<input type="file" accept="image/*" capture="environment">` でモバイル背面カメラ起動
- Supabase Storage に upload（path: `{proposal_id}/evidence-{timestamp}.{ext}`）
- signed URL（1 年）を取得して `proposals.evidence_photo_url` に保存
- 撮影者は自動承認（approved_by_sender or receiver = true）
- アップロード中はオーバーレイで進捗表示

#### D. C-3 双方承認画面（`/transactions/[id]/approve`）

c-flow.jsx `ApproveStep` 準拠：
- 撮影写真表示（4:3、影あり、メタストリップ「YYYY-MM-DD HH:mm · 場所」）
- アイテムリスト 2 行（@相手 / @あなた）：イニシャル ×N サムネ + 数量
- 両者の確認ステータス：
  - ✓ 緑円（承認済）/ ○ dashed 紫枠（待ち）
- 注意 box「内容に問題がある場合は『相違あり』を選び、後でサポートに通報できます」
- フッター：[相違あり] + [承認して完了]（紫グラデフル幅）

**動作**：
- `approveCompletion(proposalId)` で自分側 approved を true に
- 双方 true なら status='completed' + completed_at + system message
- `flagDispute(proposalId)` で system message として記録（dispute フローは次イテ）
- 双方承認後は `/transactions/[id]/rate` に自動遷移

#### E. C-3 完了画面（`/transactions/[id]/rate`）

c-flow.jsx `RateStep` 準拠：
- 紫グラデの ✓ アイコン + 「取引完了！」
- 「@相手 との交換が記録されました」
- **評価**：5 星 + コメント textarea（評価済なら disable + 「✓ 評価送信済み」）
- **コレクション更新**：紫×ピンクグラデの box
  - 受け取ったアイテムから character + goods_type を抽出
  - 私の wish 該当数（total） vs 私の inv 該当数（acquired）
  - プログレスバー + 「あと N枚 で {名前} コンプ」or「コンプリート達成 🎉」
- **X 投稿カード**：交換完了の御礼テキスト + handle を `https://twitter.com/intent/tweet` で開く
- フッター：[評価を送信]（紫グラデフル幅）

**評価フロー**：
- `submitEvaluation(proposalId, stars, comment?)` で `user_evaluations` に insert
- unique 制約違反（既に評価済）は user-friendly メッセージ
- 完了後は `/transactions` に redirect

### 進入導線

```
/transactions/[id]
  ├ status=agreed && evidence_photo_url=null → そのまま（チャット画面 + 「合流したら撮影」案内）
  ├ status=agreed && evidence_photo_url exists → /approve に redirect
  └ status=completed → /rate に redirect

/capture → 撮影 → setEvidencePhoto → /approve に redirect
/approve → approveCompletion → 双方承認なら /rate に redirect
/rate → submitEvaluation → /transactions に redirect
```

### 影響範囲

- 新ルート 3 つ（capture / approve / rate）
- 取引チャット画面：c-flow.jsx 完全準拠にリニューアル
- DB：proposals 6 列追加、user_evaluations テーブル新設、Storage バケット作成
- C-3 完全フロー（撮影 → 承認 → 完了 → 評価 → コレクション更新）が回る

### 設計判断

- **Storage バケットは private + signed URL**：写真は participant 以外に見せない。期限 1 年（実用上十分）
- **撮影者は自動承認**：UX 上、撮ったら自分は承認しているので追加タップ不要
- **コレクション進捗は character + goods_type 単位**：「スア × トレカ」みたいな粒度で集計
- **dispute は flagDispute system message のみ**：本格実装は次イテ（D-flow）
- **X 投稿は Web Intent で**：API 不要、テキストだけ生成して Twitter に渡す

### TODO（次イテ）

- iter69-A：QR ジェネレーター（取引時の本人確認）
- iter69-B：dispute（D-flow / 異議申し立て）— `disputes` テーブル + フロー
- iter69-C：期限自動切替 cron（expires_at 過ぎたら status=expired）
- iter69-D：Supabase Realtime（5 秒 polling 撤廃）
- iter69-E：deals テーブル整備（proposals 分離 / 過去取引の長期保存）
- iter69-F：服装写真 / 通常チャット写真 の upload UI

### 関連ファイル

**Migration**：
- `supabase/migrations/20260503220000_proposal_evidence_and_evaluations.sql`
- `supabase/migrations/20260503230000_chat_photos_bucket.sql`

**Server actions**：
- `web/src/app/transactions/actions.ts`（setEvidencePhoto / approveCompletion / flagDispute / submitEvaluation 追加）

**ルート**：
- `web/src/app/transactions/[id]/page.tsx`（リダイレクトチェーン追加）
- `web/src/app/transactions/[id]/ChatView.tsx`（全面書き直し、c-flow.jsx 準拠）
- `web/src/app/transactions/[id]/capture/page.tsx` + `CaptureView.tsx`（新規）
- `web/src/app/transactions/[id]/approve/page.tsx` + `ApproveView.tsx`（新規）
- `web/src/app/transactions/[id]/rate/page.tsx` + `RateView.tsx`（新規）

---

## イテレーション68-A：取引チャット（C-2）— messages テーブル + チャット画面

### 背景

iter67-E までで打診サイクル + 取引タブが揃った。次に **合意後の当日運用** が必要。
モックアップ案の「C-2 チャット」画面：
- 取引内容＋待ち合わせ（確定済）固定カード
- 服装写真シェア（双方の状態 + 撮影 CTA）
- メッセージリスト（テキスト / 写真 / 現在地 / 到着ステータス）
- 入力欄（＋ メニューで現在地・服装写真・写真添付）

iter68-A は **messages テーブル + テキスト/位置/到着ステータス** を完全実装。
写真 upload（Storage 整備）と C-3 撮影/承認/評価は別 iter で。

### 変更内容

#### A. DB マイグレーション（`20260503210000_add_messages.sql`）

```
messages
  id, proposal_id, sender_id,
  message_type 'text'|'photo'|'outfit_photo'|'location'|'arrival_status'|'system',
  body, photo_url,
  location_lat, location_lng, location_label,
  meta jsonb,
  created_at
```

CHECK 制約：`messages_type_consistency` で各 type に必要なフィールドを担保
- text → body 必須
- photo / outfit_photo → photo_url 必須
- location → lat/lng 必須
- arrival_status → meta 必須

RLS：proposal の sender or receiver のみ SELECT/INSERT 可（UPDATE/DELETE は許可しない＝追記型）

インデックス：`(proposal_id, created_at)` で取引ごとの時系列取得を高速化

#### B. server actions（`/transactions/actions.ts`）

- `sendTextMessage(proposalId, body)`：テキスト送信、2000 文字以内
- `sendLocationMessage(proposalId, lat, lng, label?)`：現在地共有
- `updateArrivalStatus(proposalId, status)`：'enroute' / 'arrived' / 'left' を `arrival_status` メッセージとして追記。最新の status が現在の到着状態として扱われる

各 action 内で proposal 参加者チェック（RLS でも担保）。

#### C. `/transactions/[id]/page.tsx`（server）

- proposal + messages + 関連 inventory + 相手 user を fetch
- ユーザー視点で「私が出す ↔ 私が受け取る」に整形
- 双方の最新 arrival_status を計算（partner が「会場到着」中なら header に表示）
- 双方の最新 outfit_photo を抽出（次イテで写真 upload 実装後に活用）
- 合意済 / ネゴ中 / 一方合意 のみアクセス可（draft/expired/cancelled は `/proposals/[id]` にリダイレクト）

#### D. `ChatView.tsx`（client）

**レイアウト構成**：
1. **取引内容カード**（上部固定、紫/青グラデ背景）
   - 「📦 取引内容＋待ち合わせ（確定済）」+ 「合意済」緑バッジ
   - 受け取る ⇄ 出す（grid_3、定価交換時は ¥金額カード）
   - 場所 + 時間帯
2. **服装写真シェアセクション**
   - あなた / @partner の双方カード（共有済 ✓ or 未シェア —）
   - 「📷 服装写真を撮影してシェア」ボタン（実装は次イテ、今は alert）
3. **メッセージリスト**（自動下スクロール）
   - text：紫グラデバブル（自分）/ 白枠バブル（相手）
   - location：📍 + ラベル + 「地図で見る →」（Google Maps リンク）
   - arrival_status：中央寄せの緑チップ「会場に到着しました ・ 18:43」
   - photo / outfit_photo：画像表示（実 url が来たら表示）
   - system：中央寄せのグレーチップ
4. **入力欄**（下部）
   - ＋ メニュー（タップで展開）：現在地を送る / 向かう→到着→離脱 / 服装写真（disabled）
   - textarea（Enter 送信、Shift+Enter で改行、IME 対応）
   - 紫グラデの送信ボタン

**リアルタイム**：5 秒ごとに `router.refresh()` で polling（Supabase realtime 化は次イテ）

#### E. 進入導線

- **`/proposals/[id]`**：status が `agreed` / `negotiating` / `agreement_one_side` のとき、紫グラデの「💬 取引チャットへ進む →」or「💬 ネゴチャットへ進む →」CTA を表示
- **`/transactions` 進行中カード**：タップで `/transactions/[id]` へ（既存リンク先 `/proposals/[id]` から変更）

#### F. ヘッダー
- HeaderBack の sub に「● 会場到着」or「向かっています」or「未到着」+ エリア
- 状態（合意済以外）の場合のみ右上にステータスバッジ

### 影響範囲

- 新ルート `/transactions/[id]`（取引チャット）
- `/proposals/[id]` 詳細：合意後の遷移先 CTA 追加
- `/transactions` 進行中カード：リンク先を `/proposals/[id]` → `/transactions/[id]` に変更
- DB：messages テーブル新規

### 設計判断

- **チャットは追記型**（UPDATE/DELETE 無し）：訴訟リスク削減、改ざん防止
- **arrival_status をメッセージで表現**：別カラムにするより簡潔。最新を見るだけで現状把握
- **5 秒 polling は MVP**：Supabase Realtime 導入は写真 upload 等と同じ iter で
- **取引内容カードは折り畳まない**（モックアップ準拠）：当日見返す情報なので常時表示
- **取引内容は不変**：合意した内容なので変更不可、再交渉は新打診

### TODO（次の小iter）

- iter68-B：Supabase Storage 整備 + 服装写真 / 通常写真 upload 実装
- iter68-C：QR 表示（モックアップでヘッダー右上にあった「QR」ボタン → 取引完了用の本人確認）
- iter68-D：C-3 取引完了 撮影画面
- iter68-E：C-3 双方承認 + 完了 → 評価 + コレクション更新
- iter68-F：deals テーブル整備（proposals → deals 分離）
- iter68-G：Supabase Realtime（5 秒 polling 撤廃）

### 関連ファイル

- `supabase/migrations/20260503210000_add_messages.sql`（新規）
- `web/src/app/transactions/actions.ts`（新規）
- `web/src/app/transactions/[id]/page.tsx`（新規）
- `web/src/app/transactions/[id]/ChatView.tsx`（新規）
- `web/src/app/proposals/[id]/ProposalDetailView.tsx`（チャット導線追加）
- `web/src/app/transactions/TransactionsView.tsx`（リンク先変更）

---

## イテレーション67-E：取引タブ追加（フッター）+ `/transactions` 一覧画面

### 背景

オーナーから iter67-D 後にデザイン案の画像（取引タブ・C-2 チャット・C-3 撮影/承認/評価）共有 + フッター指示：

> デザイン案見ました？こんな感じだったと思いますが。
> 打診を送る画面は別に変えなくていいけど。
> あとフッターに「取引」を追加してほしい

C-2 / C-3 などの個別画面は別 iter で。今回は **取引タブの導線整備** のみ：

### 変更内容

#### A. `BottomNav.tsx` に「取引」タブ追加
- 中央に配置：ホーム / 在庫 / **取引** / wish / プロフ
- アイコンは双方向矢印 SVG（取引のシンボル）
- アクティブ判定は `pathname.startsWith("/transactions")`

#### B. `/transactions/page.tsx` + `TransactionsView.tsx`（新規）

モックアップ準拠の **3 タブ** 構造：

| タブ | 元データ | 説明 |
|---|---|---|
| 打診中 | proposals.status in (sent, negotiating, agreement_one_side) | やり取り中の打診 |
| 進行中 | proposals.status = agreed | 合意済 → 当日合流予定 / C-2 / C-3 段階 |
| 過去取引 | proposals.status in (rejected, expired, cancelled) | 終了済の打診 |

`deals` テーブルはまだ無いので、進行中・過去は proposals.status で代用（次イテで合流）。

サーバー側：proposals + 相手 user + 関連 inventory を bulk fetch、サマリ文字列に整形。

クライアント側カード：
- **進行中カード**：ユーザー視点「受け取る ⇄ 出す」+ 場所 + 時間帯 + **合流カウントダウン**（緑インジケータ）
  - 「合流まで 3時間」「当日まで 7日」「合流 5分前」など動的計算
- **打診中 / 過去カード**：状態バッジ + NEW + 期限残日 + 簡易サマリ
- 過去カードは opacity 0.7 で薄く表示

#### C. ユーザー視点「私が出す ↔ 私が受け取る」

旧（/proposals）：sender → receiver の方向
新（/transactions）：**ログインユーザー視点**で「あなたが受け取る ⇄ あなたが出す」を統一

```
direction = sender_id === user.id ? "sent" : "received"
if (sent)     myGive = senderItems,    myReceive = receiverItems
if (received) myGive = receiverItems,  myReceive = senderItems
```

定価交換時：私が受け取る or 私が出す が「💴 ¥金額」になる

#### D. 合流カウントダウン

進行中カード専用の動的表示：
- 未来：分→時間→日 で粒度切替
- 過ぎた時刻：分前 → 時間経過 → 日経過
- 緑のステータスインジケータ + テキスト

### 影響範囲

- 全ページのフッターに「取引」タブが出現
- 新ルート `/transactions`
- proposals データを取引視点で再表示（既存 `/proposals` も並存）
- C-2 / C-3 などの取引中／完了画面は **iter68 以降**

### 設計判断

- **`/transactions` と `/proposals` の併存**：機能重複だが、視点が違う（取引フロー視点 vs 打診サイクル視点）。用途で使い分け
- **deals テーブルは MVP では proposals で代用**：DB 増やす前に UI で慣らす。次イテで分離検討
- **「申告中・仲裁中」セクションはスキップ**：dispute 機能未実装のため
- **進行中カードに合流カウントダウン**：当日感を演出（モックアップの「合流 5分前」「当日まで 7日」を再現）

### TODO（次の iter / iter68 系）

- C-2 取引チャット：messages テーブル + チャット UI + 服装写真シェア + 現在地共有
- C-3 撮影：取引証跡撮影（カメラ + メタ）
- C-3 双方承認：写真 + 双方の承認ボタン → 完了
- C-3 完了 / 評価：評価 + コレクション更新 + X 投稿
- deals テーブル整備（proposals → deals 分離）
- 期限自動切替 cron

### 関連ファイル

- `web/src/components/home/BottomNav.tsx`（取引タブ追加）
- `web/src/app/transactions/page.tsx`（新規）
- `web/src/app/transactions/TransactionsView.tsx`（新規）

---

## イテレーション67-D：打診の受信表示 `/proposals` + `/proposals/[id]`

### 背景

iter67-C で **送信側** の打診画面（`/propose/[partnerId]`）は完成、iter67.6/.7/.8 でマッチ → 詳細モーダル → 打診プリフィルまで導線が繋がった。
ただし、**受信側がそれを見て応答する画面** が無いため、打診サイクルが閉じていなかった。

iter67-D で：
- `/proposals` 一覧（受信 / 送信タブ）
- `/proposals/[id]` 詳細表示 + 受信者向け応答 CTA（承諾 / 拒否 / ネゴ）

### 変更内容

#### A. `/proposals/page.tsx`（一覧・server）+ `ProposalsView.tsx`（client）

- 自分が sender or receiver の打診を `or(sender_id.eq.., receiver_id.eq..)` で fetch
- draft 除外、`last_action_at desc` 順
- 相手の handle / display_name は bulk fetch
- タブ：「受信」「送信」（カウント付き）
- カード：状態バッジ（色分け）、定価交換 chip、未応答に NEW、期限 残N日（≤1日 で警告色）
  - 待ち合わせ要約（時間帯 + 場所）+ メッセージ抜粋（60 文字）
  - タップで詳細へ

#### B. `/proposals/[id]/page.tsx`（server）+ `ProposalDetailView.tsx`（client）

server：
- proposals + 関連 inventory（sender_have_ids + receiver_have_ids を flatten）+ 相手 user を fetch
- 自分が sender / receiver か判定
- `ProposalDetail` 型に整形して client に渡す

client：
- ヘッダーカード：ステータス、定価交換 chip、期限、相手 user
- 交換内容：grid（譲 ↔ ⇄ 譲 + 中央 ArrowDot）。定価交換時は片側に「💴 ¥金額」カード
- 待ち合わせ：日時範囲 + 場所 + 地図プレビュー（read-only MapPicker）
- メッセージ：トーン chip + 全文表示
- その他：スケジュール共有 ON/OFF、listing_id 経由表示、拒否理由表示
- **受信者向け CTA**（status=`sent`/`negotiating` のみ）：
  - 「✓ この内容で承諾する」（紫グラデフル幅）
  - 「ネゴ（条件相談）」「拒否」（2 ボタン横並び）
  - 「ネゴ：日時 / 数量 / 提示物の調整を打診相手と相談（C-1.5、次イテレーションで実装）」案内
- **拒否モード**：
  - REJECT_TEMPLATES：「条件が合わない / 時間が合わない / 場所が遠い / 理由非開示」
  - 4 ボタン + 「理由なしで拒否を確定」+ 「← 戻る」
- **送信者向け表示**：状態に応じた一文（「相手の応答を待っています」「ネゴ中です」「合意済 ✓」など）

#### C. `respondToProposal` action は既存（iter67-C で実装済）
- 引数：`id`, `action: 'accept'|'reject'|'negotiate'`, `rejectedTemplate?`
- 受信者チェック、status sent/negotiating のみ通過、新 status へ更新

#### D. プロフ画面に「📨 打診」リンク追加
`/profile/ProfileView.tsx` の「あなたの活動」セクションに、スケジュールの上に「📨 打診 — 送信・受信した打診一覧」を追加。

### 影響範囲

- 新ルート：`/proposals`、`/proposals/[id]`
- プロフィール：「📨 打診」エントリ追加
- 打診サイクルが閉じる（送信→受信→応答→確認）

### 設計判断

- **受信専用画面ではなく一覧 + 詳細**：送信側も自分が送った打診を見て状態追跡できる必要があるため、両方扱う
- **タブで切替**：受信 / 送信のメンタルモデルを分離
- **承諾 CTA は紫グラデフル幅で目立たせる**：最頻パターンを推奨
- **拒否は 2 段階**（拒否ボタン → 理由選択モード）：誤タップ防止 + 理由を集める動機付け
- **ネゴはまだ flag 化のみ**：C-1.5 ネゴチャットは iter68 以降。今は status=`negotiating` に変えるだけで、UI は「次イテで実装」案内
- **取引タブ未整備**：合意後の遷移先は表記のみ（「取引画面へ進めます（次イテで実装）」）

### TODO（次の iter）

- iter68：C-1.5 ネゴチャット（messages テーブル + UI）
- iter68：合意後の取引画面（C-2 / C-3）
- フッターに「取引」タブ追加
- 期限自動切替 cron（expires_at 過ぎたら status=expired）

### 関連ファイル

- `web/src/app/proposals/page.tsx`（新規）
- `web/src/app/proposals/ProposalsView.tsx`（新規）
- `web/src/app/proposals/[id]/page.tsx`（新規）
- `web/src/app/proposals/[id]/ProposalDetailView.tsx`（新規）
- `web/src/app/profile/ProfileView.tsx`（リンク追加）

---

## イテレーション67.8：詳細モーダル UX 改善（複数選択肢 + 在庫チェック + 線統一 + チェック削除）

### 背景

iter67.7 の詳細モーダルを実機確認したオーナーから 3 点指示：

> ・緑のチェックマークは不要
> ・複数の選択肢を選んで打診に飛べるルートも作って（フッターに固定の「打診に進む」、こちら側 / 相手側の手持ちが足りなくなる組合せはアラート）
> ・実線と点線が今は実質意味をなしてないので、全部実線に

### 変更内容

#### A. 緑チェックマーク削除
- OptionRow ヘッダーから ✅ バッジ撤廃
- 成立 / 未成立は **枠色 + opacity** のみで表現（成立=紫枠、未成立=薄い灰枠+opacity 0.6）

#### B. 線を全部実線に
- SVG line の `strokeDasharray` を撤廃（条件分岐廃止）
- すべて `strokeWidth=1.8` の実線、選択中は 2.4px に強調
- opacity だけで「成立 / 未成立 / 選択中」を区別

#### C. 複数選択肢トグル + フッター「打診に進む」 CTA

**Modal state**：
```ts
selected: { listingId: string; optionIds: Set<string> } | null
```
1 listing 内では複数選択可能、別 listing にまたがる選択は禁止（選択リセット）

**OptionRow**：タップで toggle、選択中は紫太枠 + 背景 tint + 右端に紫レ点バッジ

**フッター CTA**：選択肢が 1 つ以上で出現
- 「この N 件の選択肢で打診に進む →」
- 「選択をクリア」リンク
- リンク：`/propose/[partnerId]?listing={id}&options=p1,p2,...&matchType=...`

#### D. 在庫オーバーチェック

各選択肢の有効化前に「自分が出す総量 vs 自分の在庫」を計算：
```
required[itemId] =
  Σ (listing.perOptionMyCommitment[itemId].qty × N)  ← 私の listing なら haves × N
  + Σ option.myAdditionalCommitments[itemId].qty     ← 相手の listing の場合の per-option my inv
```
`required > myInventoryQty[itemId]` ならアラート表示で toggle 拒否：
```
⚠️ 自分の在庫が足りません（必要 ×N / 在庫 ×M）。選択肢を減らすか、別の組合せを試してください。
```
4 秒で自動消去。

#### E. データモデル拡張
- `MatchCardData.myInventoryQty: Record<string, number>` 追加（自分 inv → quantity）
- `MatchCardListingInfo` に：
  - `isMyListing: boolean`
  - `perOptionMyCommitment: { itemId, qty }[]` — 自分 listing の haves（共通、選択肢ごとに乗算）
- `MatchCardOption` に：
  - `myAdditionalCommitments: { itemId, qty }[]` — 相手 listing の場合の per-option 私の inv

#### F. propose page.tsx：複数 options クエリ受け取り

`searchParams.options=1,2,3` 形式に対応。後方互換で既存 `option=N` も維持。

集計ロジック：
- 私の listing：`haves × N` を sender に、各 option の wishes に該当する partner inv を receiver に
- 相手の listing：逆方向

cash オプション：単独なら従来の cash モード、組合せの一部なら通常打診（cash 部分は無視 + cashOffer 情報だけ伝搬）

### 影響範囲

- 詳細モーダル：UX 大幅改善（複数選択肢 + 在庫チェック）
- 打診画面：複数 options 対応
- HomeView：myInventoryQty を渡す
- page.tsx：goods_inventory.quantity を select に追加

### 設計判断

- **1 listing 内のみ複数選択**：別 listing にまたがる組合せは概念的に複雑（「異なる募集をまとめて打診」になる）ので禁止
- **在庫チェック on toggle**：実際に有効化を試みた瞬間にチェックして拒否、UI で迷わせない
- **アラートは 4 秒で消える**：エラーは一時的に見せて、すぐに次のアクションに進ませる
- **線は全部実線**：オーナー指摘通り、点線/実線の意味が曖昧だった。opacity で「成立/未成立/選択中」を表現

### 関連ファイル

- `web/src/components/home/MatchDetailModal.tsx`（複数選択肢トグル + 在庫チェック + 線統一 + フッター CTA）
- `web/src/components/home/MatchCard.tsx`（type 拡張 + Modal props 追加）
- `web/src/components/home/HomeView.tsx`（matchToCard で commitments 計算 + myInventoryQty 受け渡し）
- `web/src/app/page.tsx`（goods_inventory.quantity fetch + myInventoryQty 構築）
- `web/src/app/propose/[partnerId]/page.tsx`（options クエリで複数選択肢集計）

---

## イテレーション67.7：詳細モーダルのコンパクト化 + 選択肢から打診プリフィル + 定価交換打診

### 背景

iter67.6 の詳細モーダルを実機で見たオーナーから整理依頼：

> Q1: 譲↔︎求の構成で、譲は左側に1度だけ出して、線が伸びて複数選択肢を表示
> Q2: 「この選択肢で打診」ボタンをスタイリッシュに
> Q3: 定価交換にも打診ボタンつける
> Q4: 成立優先表示、未成立は薄く
> 全体：コンパクトに、スクロール削減
> 各選択肢で「打診→」を押すと、その選択肢の譲・求が打診画面に **プリフィル**

### 変更内容

#### A. DB マイグレーション（`20260503200000_proposal_cash_offer.sql`）

`proposals` テーブルに：
- `cash_offer boolean default false`
- `cash_amount integer nullable` (1〜9,999,999)

CHECK 制約：cash_offer=true なら cash_amount 必須 + receiver_have_ids 空、cash_offer=false なら cash_amount null + receiver_have_ids ≥1

#### B. `createProposal` 拡張
- input に `cashOffer?: boolean` `cashAmount?: number` 追加
- cash 分岐：
  - cash=true: receiverHaveIds 空 OK、cashAmount 必須
  - cash=false: receiverHaveIds ≥1 必須
- INSERT 時に cash_offer / cash_amount を埋める
- listingId を保存（既存）

#### C. propose `/propose/[partnerId]/page.tsx`：listing/option クエリ受け取り

searchParams に `listing` + `option` を受け取り、両方ある場合：
1. `listings` と `listing_wish_options` を fetch
2. listing.user_id が自分か相手かで処理分岐
3. 自分の listing：
   - sender = listing.haves
   - receiver = option.wish_ids にヒットする partner inv（matched）
4. 相手の listing：
   - sender = option.wish_ids にヒットする my inv
   - receiver = listing.haves（相手が出すもの）
5. 定価交換 option：cashOffer フィールドを構築
6. `initial: { senderHaveIds, senderHaveQtys, receiverHaveIds, receiverHaveQtys, cashOffer?, listingId }` を ProposeFlow に渡す

#### D. `ProposeFlow.tsx`：initial values + 定価交換モード

- props に `initial?` 追加
- `useState` 初期化で：
  - initial があれば senderIds / receiverIds / qty を反映
  - 無ければ既存の wishMatch pre-check 動作
- `isCashMode = !!initial?.cashOffer`
- 定価交換モード時：
  - 上部に緑バナー「💴 定価交換モード · 受け取り＝¥X,XXX」
  - 「受け取る」タブ：アイテムリストの代わりに定価金額カード
  - canProceedSelect：theirCount チェック skip
  - createProposal 呼び出し時に cashOffer / cashAmount / receiver 空配列

#### E. `MatchDetailModal.tsx`：レイアウト全面書き直し（コンパクト版）

- **左カラム**：listing.haves（共通）を **1 度だけ** 固定（縦中央）
  - 64×84px のサムネ、最大 2 件表示 + 「+N」
  - haves.length > 1 のとき AND/OR バッジ
- **右カラム**：選択肢を **縦並び**（成立優先ソート → 未成立は opacity 0.6）
  - 各選択肢は 1 行（横長）：
    - 左：求アイテム or 💴 アイコン
    - 中央：position chip + exchange_type chip + AND/OR + ✅
    - 右：**スタイリッシュな「打診→」ボタン**（紫グラデの小さな pill）
- **SVG 線**：左カラム中心 → 各選択肢中心
  - 成立 + AND → 実線（2px）
  - 成立 + OR → 点線（1.5px）
  - 未成立 → 薄い点線（opacity 0.3）
- セクションヘッダーをミニマル化：「●● あなたの個別募集 · 3 選択肢」1 行
- 共通の譲セクションは廃止（左カラムに統合）
- 「打診→」リンク → `/propose/[partnerId]?matchType=...&listing={id}&option={pos}`

#### F. `MatchCard.tsx`：modal 呼び出し拡張
`MatchDetailModal` 呼び出しに `partnerId` + `matchType` を追加（打診リンク生成用）

### 影響範囲

- DB：proposals に 2 列追加
- 詳細モーダル：UI 大幅刷新、スクロール量大幅削減
- 打診画面：listing/option クエリでプリフィル可能に
- 定価交換打診フロー：完全実装

### 設計判断

- **左譲 1 回固定**：オーナー意図を直接反映。視覚的に「どの選択肢でも譲は同じ」が伝わる
- **横長 1 行カード**：縦長ではスクロール多くなるので横使い。打診ボタンも右端で押しやすい
- **成立優先ソート**：成立分が上、未成立は下（opacity 0.6 で参考表示）
- **定価交換打診**：proposals に cash_offer / cash_amount 列追加で正面突破。receiver 側は空配列、message に金額情報を追加
- **listingId 保存**：将来「この打診はどの listing 経由か」追跡できる

### 関連ファイル

- `supabase/migrations/20260503200000_proposal_cash_offer.sql`（新規）
- `web/src/app/propose/actions.ts`（cash 対応）
- `web/src/app/propose/[partnerId]/page.tsx`（listing/option fetch + initial 構築）
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`（initial values + cash mode）
- `web/src/components/home/MatchDetailModal.tsx`（レイアウト全面書き直し）
- `web/src/components/home/MatchCard.tsx`（modal props 拡張）

---

## イテレーション67.6：マッチパネル改修（listing 経由のリッチカード + partner listings + 距離）

### 背景

iter67.4/5 で個別募集モデルが整理された後、オーナーから「マッチングパネル一覧」表示の改修：

> Q1: B + popup（相手の条件 + 他の選択肢）
> Q2: B（listing 経由はリッチに、上位表示）
> Q3: A（定価交換も受付サブバッジ）
> Q4: B（距離は現地モード ON 時のみ）
> Q5: C（相手プロフ→は今は触らない）
> Q6: B（色分けはしない）
> Q7: 不要（スワイプ）

### 変更内容

#### A. `matching.ts`：partner listings 評価を追加
- `Match.matchedListings` を **`myMatchedListings` + `partnerMatchedListings`** に分離
- `matchPair` の引数に `partnerListings` / `partnerInvById` / `partnerWishById` 追加
- 既存の `evaluateListingMatch` を再利用（引数を入れ替えるだけで partner 側評価が成立）
- `viaListing` = 自分側 or 相手側いずれかで listing が成立すれば true
- `Match.distanceMeters?` を追加（現地モード ON 時のみ）

#### B. `computeAllMatches`：ソート優先度を変更
- 旧：matchType 順 > viaListing
- **新：viaListing 優先 > matchType 順**
- 個別募集経由マッチがリストの上位に来る

#### C. `page.tsx`：他者 listings + options を fetch
- `othersListings` クエリ追加（`status='active'` のもの）
- `listing_wish_options` を listing_id で bulk fetch
- `othersListingsByUser` Map で user_id 別に集約
- `partnersMap` 各エントリに `listings` を追加
- 距離計算：`isLocal && last_lat/lng` のとき、相手の AW center との haversine 距離を最短値で算出 → `match.distanceMeters` に格納

#### D. `MatchCard.tsx`：リッチ vs シンプルに分離
新規：
- `MatchCard` ディスパッチャー：`myMatchedListings || partnerMatchedListings` の有無で振り分け
- `ListingMatchCard`（リッチ）：
  - 上部に紫グラデバナー「📦 個別募集マッチ」+ source ラベル（あなた/相手/双方の個別募集が成立）
  - 紫枠 1.5px + 強い影 + ソフトな背景グラデ
  - Trade preview は既存
  - バッジ群：「📦 セット」or「いずれか OK」+ 「💴 定価交換も受付」（hasCashOffer 時）
  - 「詳細 →」ボタンが目立つ位置（右寄せ）でグラデ背景
  - 距離テキスト「📍 約 250m」を表示（現地モード ON 時）
- `SimpleMatchCard`：従来通りのシンプルデザイン（wish 経由マッチ用）

#### E. `MatchDetailModal.tsx`：2 セクション構成に
- props を `myListings` + `partnerListings` の 2 配列に分離
- セクションA（紫）「あなたの個別募集」 — 「あなたが出している条件 — 相手の譲がこの条件を満たしました」
- セクションB（ピンク）「@partner の個別募集」 — 「相手が出している条件 — あなたの譲がこの条件を満たしました」
- 各セクション内で listing ごとに既存の関係図を描画
- 譲側のラベルを `ownerLabel` prop で動的に（あなたの譲 / 相手の譲）

#### F. `MatchCardData`：拡張
- `myMatchedListings` + `partnerMatchedListings` （`matchedListings` から rename + 分離）
- `hasCashOffer?: boolean`：定価交換選択肢を含む listing が成立したか
- `distanceText?: string`：「約 Xm」「約 X.X km」（現地モード ON 時のみ）

#### G. `HomeView.tsx`：matchToCard hydrate 拡張
- partnersInventory / partnersWishes を props 追加（listing item 解決用）
- partner listings の haves（=相手の譲）を `partnersInvById` から、wishes を `partnersWishById` から hydrate

### 影響範囲

- ホーム画面のマッチカード一覧：listing 経由マッチがリッチで上位に
- 詳細モーダル：双方の listing を別セクションで明示
- データ構造：Match に partner listings 情報追加

### 設計判断

- **partner listings を独立に評価**：相手も listing を持つ場合があり、両側が独立に成立し得る。両側で違う「条件」を提示してくる可能性がある
- **viaListing 優先ソート**：個別募集はユーザーが意図的に作った「強い意思表示」なので最上位
- **「詳細 →」ボタンを目立たせる**：listing 経由マッチは複雑な構造を持つので、必ず詳細を見てもらう導線を用意
- **距離表示は現地モード ON 時のみ**：通常時は「広域 / 都道府県」で十分

### 関連ファイル

- `web/src/lib/matching.ts`（型 + matchPair + computeAllMatches sort）
- `web/src/app/page.tsx`（partner listings fetch + 距離計算）
- `web/src/components/home/{MatchCard.tsx, MatchDetailModal.tsx, HomeView.tsx}`

---

## イテレーション67.5：listing 作成 UI 微調整 + wish exchange_type 再削除

### 背景

iter67.4 着手後、オーナーから運用視点の細かい指摘：

> 1. 個別募集の際、譲るグッズのグループと種別は、自分が持っている在庫のものから選べるようにしてください。
> 2. 注意書きとして、譲るグッズで複数選ぶ場合は「同じシリーズ」のものに限定してくださいみたいなことを書いて。そうじゃないと同種交換、異種交換の判断がぶれてしまう。
> 3. 求めるものについても、上記の譲るグッズのグループと種別が更新されたらリセットされちゃうので、ちゃんとタイムリーに更新されるように。
> 4. 通常の Wish を登録する時、交換タイプは選択不要にしてください。この情報は個別募集でいきるので。

### 変更内容

#### A. listing 作成 dropdown を **在庫実体** から
- `/listings/new/page.tsx`：master テーブルからの取得を廃止
  - `inventoryRows` から `inventoryGroups`、`inventoryGoodsTypes` を抽出（重複排除 + 五十音ソート）
  - `wishRows` から `wishGroups`、`wishGoodsTypes` を抽出
  - 譲側 dropdown は `inventoryGroups` / `inventoryGoodsTypes`、求側選択肢 dropdown は `wishGroups` / `wishGoodsTypes`

→ 在庫が無い group/goods_type は dropdown に出ない。「選んだのに該当アイテム 0 件」の不整合が消える。

#### B. 同シリーズ注意書き
- 譲るグッズセクションに紫枠の注意 box：
  「⚠️ 譲るグッズで **複数選ぶ場合は同じシリーズ**（同じツアー・同じアルバム等）に限定してください。シリーズが混在すると、求側の **同種 / 異種** 判定が曖昧になります。」

「シリーズ」は DB スキーマ上の項目ではなく、ユーザーの自己判断による絞り込み（同種/異種判定の精度を保つため）。あくまでガイダンス。

#### C. 求側選択肢の追従（customized フラグ）

`WishOption` に `groupCustomized: boolean` と `goodsTypeCustomized: boolean` を追加：
- **新規追加**：customized=false でスタート（譲側追従モード）
- **ユーザーが手動で変更**：customized=true（譲側追従しない）
- **譲側 group/goods_type 変更時**：
  - customized=false の選択肢は新値に追従 + selected wish リセット
  - customized=true の選択肢はそのまま維持

これで：「最初は譲側コピー、その後譲側変えても自動更新」「意図的にカスタムした選択肢は守られる」両立。

#### D. wish 作成 UI の exchange_type 再削除
- `/wishes/new` フォームから交換タイプ 3 ボタンを撤去（iter67.3 で復活したものを再削除）
- `/wishes` 一覧の exchange_type chip も削除
- DB 列 `goods_inventory.exchange_type` は残すが、UI からは触れず default `'any'` で記録
- 個別募集（listing）の **選択肢ごとに** exchange_type を指定する設計に統一されたため、wish レベルでは不要

### 影響範囲

- `/listings/new`：dropdown が在庫由来に絞られる + 同シリーズ警告 + 譲側変更時の自動追従
- `/wishes/new`：交換タイプ ボタン消失（priority/flex/exchange_type 全部廃止 → 推し・グッズ・数量・メモのみ）
- `/wishes` 一覧：exchange_type chip 消失

### 設計判断

- **dropdown の master 由来 vs 在庫由来**：在庫に無い group を選ばせて空表示するのは UX 悪、在庫由来に統一
- **「シリーズ」は DB 化しない**：シリーズは流動的（次のツアーで増える、コラボ系で曖昧）。MVP では DB 構造で持たず UI 警告だけ
- **customized フラグは UI のみ**：DB に保存しない。submit 時には反映されないので、毎回 form 再オープン時にはリセット
- **exchange_type を wish から消す方針**：iter67.4 で per-option 設計が確立したので、wish 重複は避ける

### 関連ファイル

- `web/src/app/listings/new/{page.tsx, ListingNewForm.tsx}`
- `web/src/app/wishes/{new/WishNewForm.tsx, WishView.tsx}`

---

## イテレーション67.4：listings の求側を「複数選択肢」モデルに再設計

### 背景

iter67.3 で N×M × AND/OR を作ったあと、オーナーがさらに整理：

> 譲として選べるのは、同じグループかつ同じ種別のもののみにしてほしい。なぜなら、それに対して、WISHで登録したものに対して、同種／異種／同異種の指定をすると思うけど、その情報が役に立たないため。違うグループだったり違う種別のものが、譲で登録されていたら、どれに対する同種か異種か判定できなくなるため。
>
> 個別募集では、WISHとして下記のような形でも登録できるような設計にして欲しい。
>
> 譲る：TWICE、トレカのサナ・モモ　OR条件
> 求める：
> 　選択肢①TWICE、トレカ：ナヨン・ジョンヨン　OR条件　１対２の割合で受付
> 　選択肢②BTS、ぬいぐるみ：ジョングク・V　AND条件
> 　選択肢③定価交換
>
> 譲るは AND や OR で複数選べるけど、選択肢は１つしか選べないイメージ。
> 求めるは選択肢を増やすイメージ。
>
> WISHの選択肢を作る時、グループ名とグッズ種別を選択するように。デフォルト値は譲るグッズで設定したもので。各選択肢に同種／異種／同異種を設定。

### 仕様（合意済み）

- **譲側**：1 つのバンドル（同 group + 同 goods_type 必須、AND/OR）
- **求側**：**複数の「選択肢」**（最大 5）。選択肢間は OR（相手が 1 つ選ぶ）
  - 各選択肢は独立に：
    - group + goods_type（デフォルト = 譲側の値）
    - exchange_type（同種 / 異種 / 同異種）
    - 複数アイテム（同 group + 同 goods_type 内）+ AND/OR + qty（=比率）
  - **定価交換**選択肢：`is_cash_offer=true` で wish_ids 空、cash_amount に金額。マッチング演算には参加しない（UI 表示のみ）

OR×OR ガード：譲側 OR × 求側選択肢 OR × 両側 ≥2 アイテム は曖昧なため禁止（DB CHECK + UI 警告）。

### 変更内容

#### A. DB マイグレーション（`supabase/migrations/20260503190000_listing_wish_options.sql`）

- `listings` から wish 関連カラム削除（`wish_ids`, `wish_qtys`, `wish_logic`）
- `listings` に譲の代表 group/goods_type 追加（`have_group_id`, `have_goods_type_id` — trigger で自動算出 + 同一性検証）
- 新規 `listing_wish_options`：
  - `listing_id` FK + `position` (1〜5) + `wish_ids[]` + `wish_qtys[]` + `logic` + `exchange_type` + `is_cash_offer` + `cash_amount` + `wish_group_id` + `wish_goods_type_id`
  - trigger `validate_listing_wish_option`：is_cash_offer 分岐、同 group + 同 goods_type 検証、選択肢数 ≤ 5、OR×OR ガード
  - RLS：listing 所有者は CRUD、active な listing なら誰でも SELECT
- 既存 listings は削除（dev のみ）

#### B. matching.ts：選択肢モデルへ全面書き直し

- `ListingForMatch` 型に `options: ListingWishOption[]` を追加
- `MatchedListingInfo` に `options: MatchedOptionInfo[]` を持たせ、各選択肢の matched フラグを伝播
- `evaluateListingMatch()` 再設計：
  - 各選択肢を独立に評価（option.logic に従って AND/OR）
  - listing 全体は **少なくとも 1 つの選択肢が成立** で hit
  - `is_cash_offer` 選択肢はマッチ対象外（matched=false で記録）

#### C. listings actions / page / View

- `actions.ts` `createListing` の input を `{ haveIds, haveQtys, haveLogic, options[], note }` に変更。listing 本体 + listing_wish_options を 2 段階 INSERT（失敗時は listing 削除でロールバック）
- `page.tsx` で listings + listing_wish_options を別 query で fetch、group/goods_type マスタも引いて表示用に hydrate
- `ListingsView`：譲群（1 ブロック） + 求側選択肢（縦に並ぶ複数ブロック）。各選択肢に exchange_type chip と「定価交換」表示

#### D. listing 作成画面（`ListingNewForm.tsx` 全面再構築）

- **譲側**：
  - 「グループ + 種別」セレクタ → その組み合わせの譲のみグリッド表示
  - 複数選択 + qty stepper（写真 / イニシャル + ＋／− バッジ）
  - 複数時に AND/OR トグル
  - グループ or 種別を変えたら選択リセット
- **求側選択肢**：
  - 各選択肢ヘッダーに「グループ + 種別」セレクタ（デフォルト = 譲側と同じ）
  - 「💴 定価交換」トグルで通常 wish ↔ 金額入力に切替
  - 通常時：交換タイプ 3 ボタン（同種/異種/同異種）+ 該当 wish chip 一覧 + qty stepper + AND/OR トグル
  - 「+ 選択肢を追加」ボタン（最大 5 で disabled）
  - OR×OR ガードを UI 警告 + submit 拒否

#### E. MatchCard / MatchDetailModal：選択肢モデル対応

- `MatchCardOption` 型を新設（id / position / logic / exchangeType / isCashOffer / cashAmount / matched / wishes）
- `MatchCardListingInfo.wishes` を `options: MatchCardOption[]` に置換
- `HomeView.matchToCard` を新型に合わせて hydrate
- `MatchDetailModal` 全面書き直し：
  - 譲群を共通で 1 行表示
  - 求側選択肢を縦に並べ、それぞれ独立した SVG 関係図（譲側ラベル ←→ 各 wish）
  - 成立した選択肢に「✅ 成立」バッジ、未成立も含めて全選択肢表示
  - 定価交換選択肢は金額のみ、SVG 線なし、「演算対象外」バッジ
  - 線スタイル：opacity 0.85 (matched) / 0.35 (unmatched)、AND=実線 2.2px、OR=点線 1.6px

### 影響範囲

- DB：listings テーブル変更、listing_wish_options 新規
- 個別募集の作成 / 一覧画面：UI 完全リニューアル
- マッチング演算：選択肢モデルへ
- マッチカード関係図モーダル：選択肢ごとに描画
- ホームの listings fetch / マッチング呼び出し

### 設計判断

- **同 group + 同 goods_type の制約**は譲側 + 各選択肢それぞれに適用。trigger で強制
- **比率 = qty** という思想は維持（別概念は持たない）
- **定価交換**は専用フラグ + cash_amount 列。マッチング演算からは除外しつつ UI には表示
- **選択肢の最大数 = 5**：UI が長くなり過ぎないため
- **wish の重複利用**：1 つの wish を複数の listing / 選択肢で使える（DB 制約なし、UI フィルタなし）

### 関連ファイル

- `supabase/migrations/20260503190000_listing_wish_options.sql`（新規）
- `web/src/lib/matching.ts`（選択肢モデル）
- `web/src/app/listings/{actions.ts, page.tsx, ListingsView.tsx, new/page.tsx, new/ListingNewForm.tsx}`
- `web/src/app/page.tsx`（listings + options fetch）
- `web/src/components/home/{MatchCard.tsx, MatchDetailModal.tsx, HomeView.tsx}`

---

## イテレーション67.3：listings を「N×M × AND/OR」に拡張、wish exchange_type 復活

### 背景

オーナーから iter67.2 のあとに整理の続き：

> マッチについてですが…一つの譲に対して、ユーザーが個別募集で指定したものがあると思うので、それがマッチングのパネルにうまく表現できたらなと思っている。今の機能では、個別募集でしているす WISH が、AND 条件なのか OR 条件なのか指定ができないので、それは実装したい。
>
> 譲るものが複数あって、それが AND か OR かで話していたけど、私は WISH も同じ場合があると思うんですね…1 対複数または複数対 1 でも、OR 条件であれば比率を設定できればいい。AND 条件であれば、比率を考えるとややこしい。
>
> マッチングパネルにすべてを表現する必要はない。パネルには譲と求の組み合わせだけ、タップしたらポップアップで詳細の関係図を出す。
>
> Wish で設定するものには必ず同種か異種か同異種かを設定できるように。

### データモデルの方針（合意済み）

**listings：「N×M × AND/OR」マトリクス**

| 列 | 意味 |
|---|---|
| `have_ids[]` | 譲側のインベントリ（複数可） |
| `have_qtys[]` | 各譲の数量（≒比率を内包） |
| `have_logic` | 'and' or 'or'（複数のとき意味あり） |
| `wish_ids[]` | 求側のウィッシュ（複数可） |
| `wish_qtys[]` | 各 wish の数量 |
| `wish_logic` | 'and' or 'or' |

**「比率」概念は別カラムで持たない** — `qty` がそのまま比率を表現。
**OR × OR × 両側 ≥2 アイテムは禁止**（誰がどれを選ぶか曖昧、組合せ爆発）。

**listings.exchange_type は廃止**（per-wish の `goods_inventory.exchange_type` が source of truth）。

**wish レベルで exchange_type を必須に復活**（iter65.6 で廃止 → iter67.3 で戻す）。

### 変更内容

#### A. DB マイグレーション（`supabase/migrations/20260503180000_listings_and_or_matrix.sql`）

- 旧列削除：`inventory_id`、`exchange_type`、`ratio_give`、`ratio_receive`、`priority`
- 新列追加：`have_ids[]`、`have_qtys[]`、`have_logic`、`wish_qtys[]`、`wish_logic`
- 制約：
  - have/wish の ids[] と qtys[] の長さ一致 + 1 以上
  - all qty >= 1（trigger 内検証）
  - **OR × OR 両側 ≥2 アイテム 禁止**（CHECK）
  - have_ids 全件が `kind=for_trade` で listing 所有者と一致
  - wish_ids 全件が `kind=wanted` で listing 所有者と一致
- インデックス：`have_ids` GIN
- 既存データは delete（dev のみ・運用前）

#### B. matching.ts：AND/OR 対応

- `ListingForMatch` 型を新スキーマに変更（haveIds[]、wishIds[]、qtys[]、logic）
- `Match` 型に `matchedListings?: MatchedListingInfo[]` 追加（UI 用）
- `evaluateListingMatch()` 新関数：
  - wish_logic = AND ⇒ 全 wish_ids が「相手の譲群のいずれか」にヒット必要
  - wish_logic = OR ⇒ 1 件以上で OK
  - have_logic = AND ⇒ 全 have_ids を trade に出す
  - have_logic = OR ⇒ 1 件のみ仮表示（MVP）
- 数量 (qty) はマッチ判定では未使用（タグ表示のみ）。実数量は打診で個別調整

#### C. 個別募集 `/listings`：actions / page / View 全面更新

- `actions.ts`：input 形式を `haveIds[]/haveQtys[]/haveLogic/wishIds[]/wishQtys[]/wishLogic`、validateMatrix 関数で OR×OR ガード
- `page.tsx`：have_ids[] と wish_ids[] を flatten して in-clause で goods_inventory を一括取得
- `ListingsView.tsx`：上下 2 ブロック（譲群 / 求群）。各群に「全部 AND」or「いずれか OR」バッジ。アイテムは chip 表示で `×qty` バッジ + wish 側のみ exchange_type chip（同種/異種）

#### D. 個別募集作成 `/listings/new/ListingNewForm.tsx` 全面リファクタ

- 譲側：3 列のパネルカードで複数選択 + 各カードに ＋/− qty stepper 内蔵
- 求側：chip で複数選択 + 各 chip に ＋/− qty stepper
- 譲・求それぞれが ≥2 のとき AND/OR トグル表示
- OR × OR ガード（UI 警告 + submit 拒否）
- 譲・求ともに「推し / 種別」フィルタ chip 行

#### E. wish 作成/表示で exchange_type 復活

- `WishNewForm.tsx`：交換タイプ 3 ボタン（**同異種** / 同種のみ / 異種のみ）。デフォルト同異種。説明：「システムは弾きません（マッチング表示用のタグ）」
- `WishView.tsx`：wish カード内に exchange_type chip を表示

#### F. マッチカード：listing 経由の「セット / いずれか」バッジ

- `MatchCardData` に `listingBadge?: 'set' | 'any' | null` を追加
- `HomeView.matchToCard()` で `Match.matchedListings` を見て：
  - haveLogic=AND or wishLogic=AND が含まれる → `'set'`
  - その他の listing 経由 → `'any'`
- `MatchCard` 表示：
  - `'set'` → 紫背景の「📦 セット」ピル
  - `'any'` → 透明枠の「いずれか OK」ピル
  - 「※ 個別募集経由」注記

### TODO（次の iter）

- ~~iter67.3-G **詳細モーダル**~~ → ✅ 別 commit で実装（オーナー指示「A」）
- iter67-D：受信表示 `/proposals/[id]`

### 追加：iter67.3-G — 詳細モーダル（SVG 関係図）

別 commit で実装。

#### 仕様

- マッチカードに **「詳細→」** リンクを追加（listing 経由マッチのみ）
- 全画面モーダルで listing の関係を可視化：
  - 左カラム：私の譲（matched 分）
  - 右カラム：求（matched 分）
  - **SVG line で接続**：実線（AND）/ 点線（OR）
  - 数量バッジは各アイテム右上に「×N」
- 各 listing 1 セクション。複数 listing は縦に並ぶ
- 各セクションヘッダーに「全部 AND / いずれか OR」chip × 2（譲側 / 求側）
- OR で他にも候補ある場合は注記表示

#### 実装

- `web/src/components/home/MatchDetailModal.tsx` 新規
  - 固定サイズアイテム（76×96px）
  - 縦 gap 18px、横 col gap 110px で SVG line を計算的に描画
  - body scroll lock
- `MatchCard.tsx` に詳細ボタン + モーダル開閉 state
- `MatchedListingInfo` 型を full listing snapshot（haveIds/haveQtys/wishIds/wishQtys 含む）に拡張
- `HomeView.matchToCard()` で `myInvById` / `myWishById` を使って item details を hydrate
- `page.tsx` から HomeView へ `myInventory` / `myWishes` を追加で渡す

#### 設計判断

- MVP では **matched 分のみ表示**（OR の代替候補は注記で件数だけ示す）。完全な候補展開は将来オーナー要望次第
- 線の太さ：実線=2.2px、点線=1.6px。色 `#a695d8`、opacity 0.85
- listing.wish_qtys は「私が欲しい数量」として右側のバッジに表示（相手のインベントリ qty ではない）

### 設計判断

- **比率 = qty**：別概念にしない。OR の場合は候補ごとに違う qty を持てる。AND は群全体の数量が固定
- **MVP では数量はマッチ判定に使わない**（タグ表示のみ）。実数量は打診時に個別調整（プロポーザル送信フォームで stepper）
- **listings.exchange_type は廃止**。wish レベルが source of truth
- **OR × OR 両側 ≥2 は禁止**（DB CHECK + UI 警告）

### 関連ファイル

- `supabase/migrations/20260503180000_listings_and_or_matrix.sql`（新規）
- `web/src/lib/matching.ts`（型 + matchPair + evaluateListingMatch）
- `web/src/app/listings/{actions.ts, page.tsx, ListingsView.tsx, new/ListingNewForm.tsx}`
- `web/src/app/page.tsx`（listings select の列名更新）
- `web/src/app/wishes/new/WishNewForm.tsx`（exchange_type 復活）
- `web/src/app/wishes/WishView.tsx`（exchange_type chip）
- `web/src/components/home/MatchCard.tsx`（listingBadge）
- `web/src/components/home/HomeView.tsx`（matchToCard）

---

## イテレーション67.1：打診 C-0 改修＋ホームヘッダー整理

### 背景

iter67 で打診 C-0 ウィザードが動き出した。実機で触ったオーナーから整理依頼：

- 提示物選択で **wish 一致が下に埋もれる** → 上に並べてほしい
- 待ち合わせの「いますぐ / 日時指定」**トグルが面倒**。1 画面に統一して、相手が現地交換モードならその AW から自動入力したい。時間は **時間帯**（開始〜終了）で。地図も AW 編集と同じく必要
- フッターの **3 行サマリ（譲・受・待ち合わせ）は冗長** なので削除
- STEP 3 確認画面のグッズが文字一覧 → **マッチパネルみたいに画像** で表示。待ち合わせ場所も **地図** で表示
- ついでにホーム上部の「**オフライン中**」「**推し：LUMENA**」表記を削除（mock 残骸）

### 変更内容

#### A. `web/src/components/home/HomeView.tsx`
- Sync strip（オフライン中・最終同期・ローカル件数）削除
- タイトル行から「推し：LUMENA · スア」サブ表記を削除（h1「マッチング」だけ残す）

#### B. DB マイグレーション（新規 `supabase/migrations/20260503170000_simplify_meetup.sql`）

`proposals` テーブルから旧待ち合わせ列を削除し、新列に置換。

| 旧 | 新 |
|---|---|
| `meetup_type ('now'/'scheduled')` | （削除） |
| `meetup_now_minutes` | （削除） |
| `meetup_scheduled_custom JSONB` | （削除） |
| — | `meetup_start_at timestamptz` |
| — | `meetup_end_at timestamptz` |
| — | `meetup_place_name text (≤200)` |
| — | `meetup_lat numeric(9,6)` |
| — | `meetup_lng numeric(9,6)` |

CHECK 制約 `proposals_meetup_required`：`status='draft'` 以外なら 5 列すべて NOT NULL かつ end > start。

旧テストデータは `delete from proposals` で掃除（運用前なのでロスト懸念無し）。

#### C. `web/src/app/propose/[partnerId]/page.tsx`

server fetch を 1 つ追加：
```ts
supabase.from("user_local_mode_settings")
  .select("enabled, aw_id, last_lat, last_lng")
  .eq("user_id", partnerId)
```
`enabled && aw_id` なら `activity_windows` から `venue / center_lat / center_lng / start_at / end_at` を取得。
ProposeFlow には `partner.localModeEnabled` と `partner.localModeAW` を渡す。

#### D. `web/src/app/propose/[partnerId]/ProposeFlow.tsx` 全面リファクタ

**(1) 提示物選択：wish 一致を上にソート**
- `sortByWishFirst()` を `myItems` / `theirItems` 初期化時に適用

**(2) 待ち合わせの統一フォーム**
- now / scheduled トグル削除
- 単一フォーム：
  - 時間帯：`<input type="datetime-local">` × 2（開始・終了）
  - 場所：`<input type="text">` の「場所名」+ 地名検索バー（`/api/geocode`）+ 「📍 現在地を中心に」ボタン
  - 地図：`MapPicker`（leaflet、ピンのドラッグ・タップで lat/lng 更新）
- 相手が現地交換モード ON → 緑のバナー「@相手 は現地交換モード中」+ AW の値で 5 項目（start/end/venue/lat/lng）を pre-fill
- 相手が現地モード OFF → 1 時間後 〜 2 時間後 / 東京駅をデフォルト

**(3) 送信入力の形式変更**
- `createProposal()` の input から `meetupType`/`meetupNowMinutes`/`meetupScheduledCustom` を削除
- 代わりに `meetupStartAt` / `meetupEndAt` / `meetupPlaceName` / `meetupLat` / `meetupLng` を渡す

**(4) フッターの 3 行サマリ削除**
- `<SummaryRow>` / `<MeetupSummaryRow>` 撤去
- フッターは CTA ボタン 1 つだけに（pb 領域も縮小）

**(5) STEP 3 確認画面のリッチ化**
- 「交換内容」セクションを **マッチパネル風グリッド** に：
  - 左 = 相手の譲、中央 = ↔ 矢印、右 = あなたの譲
  - 各アイテムは `Tcg` ミニカード（写真 or イニシャル、36×48px、数量バッジ右上）
  - `MatchCard.tsx` の Tcg / SidePanel / ArrowDot を ProposeFlow 内で同型再実装
- 「待ち合わせ」セクションに **地図プレビュー**（160px 高、operations 無し read-only）

#### E. `web/src/app/propose/actions.ts`

input 形式を新 schema に合わせて更新：
```ts
meetupStartAt: string  // ISO
meetupEndAt: string    // ISO
meetupPlaceName: string
meetupLat: number
meetupLng: number
```
バリデーション：
- 全項目必須
- end > start
- lat / lng が finite

INSERT 時：`meetup_start_at`, `meetup_end_at`, `meetup_place_name`, `meetup_lat`, `meetup_lng`。`meetup_type` 系は INSERT に含めない（DB 側で削除済み）。

### 影響範囲

- ホーム画面：上部のごみ表記が消えてスッキリ
- `/propose/[partnerId]`：
  - mine / theirs：wish 一致が一番上
  - meetup：1 画面・地図付き・現地モード自動入力
  - フッター：CTA だけ
  - STEP 3：画像グリッド + 地図
- DB：proposals の待ち合わせ 5 列が新形式に

### 設計判断

- 「いますぐ」概念は **時間帯の中に内包**（5 分後〜30 分後の時間帯を入れれば「いますぐ」相当）。UI 上は分岐なし
- 相手が現地モード ON のときに **AW を読み込むだけ**（プロポーザル送信時に AW 自体は変更しない）。AW = マッチング演算用、proposal の meetup = この打診固有の待ち合わせ
- 確認画面の地図は read-only（`onCenterChange={() => {}}`）。STEP 1 の地図で確定済みのため

### 関連ファイル

- `web/src/components/home/HomeView.tsx`（ヘッダー削除）
- `supabase/migrations/20260503170000_simplify_meetup.sql`（新規）
- `web/src/app/propose/[partnerId]/page.tsx`（partner local mode + AW fetch）
- `web/src/app/propose/[partnerId]/ProposeFlow.tsx`（全面リファクタ）
- `web/src/app/propose/actions.ts`（input 形式変更）

---

## イテレーション67：打診（C-0/C-1）と個人スケジュール

### 背景

iter66 で実マッチング演算が動き出し、ホームに本物のマッチカードが並ぶようになった。次に必要なのは「打診を実際に送れる」こと。
オーナー選択：
- **Q1=C（フル装備の C-0）** … 在庫多選択 + qty stepper + メッセージトーン + カレンダー公開
- **Q2=Yes** … 待ち合わせは打診時に決める。AW から選ぶのはやめる（AW はマッチング演算専用）。代わりに **個人カレンダー（スケジュール）** を新設して打診相手にだけ公開できるようにする
- **Q3=案1** … `proposals` テーブルは modal-rich にしてフラグ列を充実させる方針
- **Q4=Yes** … 個別募集（listings）からの打診も同じフローを通る

### 変更内容

#### A. DB マイグレーション（`supabase/migrations/20260503160000_add_proposals_and_schedules.sql`）

- **`proposals`**：sender / receiver / match_type / sender_have_ids[] / sender_have_qtys[] / receiver_have_ids[] / receiver_have_qtys[] / message / message_tone / status (`sent`/`negotiating`/`agreed`/`rejected`/`expired`) / agreed_by_sender / agreed_by_receiver / last_action_at / expires_at / extension_count / rejected_template / **meetup_type** (`now`/`scheduled`) / meetup_now_minutes / **meetup_scheduled_custom**(JSONB: date/time/placeName) / expose_calendar / listing_id
  - **重要**：`meetup_scheduled_aw_id` は **入れない**。AW はマッチング演算専用に分離。
  - RLS：sender / receiver のどちらか一方のみが SELECT/UPDATE 可
- **`schedules`**：id / user_id / title / start_at / end_at / all_day / note
  - RLS：自分のスケジュールは自由に CRUD。`expose_calendar = true` で打診相手は SELECT 可

#### B. 個人スケジュール `/schedules`

`web/src/app/schedules/`：一覧（今後 / 過去で分割）／新規（`/new`）／編集（`/[id]`）／削除。
`ScheduleForm.tsx` で終日トグル・datetime-local 入力。

`profile/ProfileView.tsx` の「あなたの活動」に **「📅 スケジュール」** リンクを追加（自分の AW 動線は削除済み）。

#### C. 打診 C-0 `/propose/[partnerId]`

- **server**（`page.tsx`）：自分・相手の inventory（kind=for_trade, status=active）と wishes（kind=wanted, !=archived）を並列 fetch、`isHit()` で wishMatch フラグを付与してクライアントへ
- **server action**（`actions.ts`）：
  - `createProposal()` — 全フィールド検証 → `proposals` INSERT、`expires_at = now + 7d`、status='sent'。`/proposals` `/` を revalidate
  - `respondToProposal()` — accept / reject / negotiate（受信者用）
- **client wizard**（`ProposeFlow.tsx`、3 ステップ単一コンポーネント）：
  - **STEP 1 / 提示物選択**：3 タブ
    - mine / theirs：チェックボックス多選択 + qty stepper + 「★ wish 一致」バッジ + サムネ（写真 or character/group ID から hash で hue 決定）
    - meetup：「🚀 いますぐ（5/10/15/30 分）」or 「📅 日時指定（日付 + 時刻 + 場所、AW 選択は無し）」
    - matchType に応じた pre-check（perfect=両側 wishMatch、forward=mine wishMatch、backward=theirs wishMatch）
  - **STEP 2 / メッセージ**：標準 / カジュアル / 丁寧 トーン切替で **テンプレ自動生成**（partnerHandle / 自分の譲 / 受け取る / 待ち合わせ を埋め込み）。手で編集も OK。**スケジュール共有**チェックボックス
  - **STEP 3 / 送信確認**：交換内容グリッド + 待ち合わせ + メッセージ全文 + 「📨 この内容で打診を送信」CTA → 成功で `/` へ（取引タブはまだ無いので暫定）

#### D. マッチカード配線（`MatchCard.tsx` + `HomeView.tsx`）

`MatchCardData` に `partnerId` を追加し、`matchToCard()` で `m.partner.id` を埋め込み。
「打診する」ボタンを `<Link href="/propose/${partnerId}?matchType=${matchType}">` に変更。

### 影響範囲

- 新ルート：`/propose/[partnerId]`（C-0 ウィザード）
- 新ルート：`/schedules`、`/schedules/new`、`/schedules/[id]`
- ホーム → マッチカード → 打診 → 提示物選択 → メッセージ → 確認 → 送信 → ホーム
- DB：`proposals`, `schedules` 2 テーブル新設
- プロフ：「📅 スケジュール」エントリ追加

### 設計判断（重要）

- **AW と個人スケジュールは分離**。AW = 「この時間ここに**いる**」マッチング演算用。個人スケジュール = 「この時間 **忙しい**」打診相手向けの予定共有。打診時に AW を流用しない（オーナー指示）
- 待ち合わせは打診時に **fix される**（iter33 の方針継続）。打診を承諾した瞬間に日時・場所が確定する
- カレンダー公開は **全予定一括 ON/OFF**（個別共有は MVP では持たない）
- 取引画面（フッタータブ）は未着手。打診送信後の遷移は暫定 `/`、後で `/transactions` 等に差し替え

### 次（iter67-D 以降）

- `/proposals/[id]`（受信表示）：accept / reject / negotiate ボタン、相手の expose_calendar が ON ならスケジュール overlay
- C-1.5 ネゴチャット
- C-2 取引チャット / C-3 完了
- フッターに「取引」タブ追加

### 関連ファイル

- `supabase/migrations/20260503160000_add_proposals_and_schedules.sql`
- `web/src/app/schedules/{page.tsx,SchedulesView.tsx,actions.ts,ScheduleForm.tsx,new/page.tsx,[id]/page.tsx}`
- `web/src/app/propose/{actions.ts,[partnerId]/page.tsx,[partnerId]/ProposeFlow.tsx}`
- `web/src/components/home/MatchCard.tsx`（partnerId 追加 + Link 化）
- `web/src/components/home/HomeView.tsx`（matchToCard で partnerId 埋め込み）
- `web/src/app/profile/ProfileView.tsx`（スケジュール導線追加）

---

## イテレーション66：実マッチング演算（mock 撤去）

### 背景

iter65 シリーズで在庫・wish・AW・listings・現地モード設定 — 全部品が DB に保存されるようになったが、ホームのマッチカードは依然として **mock 4 件**。実際の交換相手を探せる状態ではなかった。
オーナー選択（A）で iter66 として「実マッチング演算」着手。

### 変更内容

#### A. `web/src/lib/matching.ts`（新規）

純関数のマッチング演算コア:

```ts
isMatching(my, theirs)        // 1 アイテム同士のマッチ判定
matchPair({ ... })             // 私 × 1 パートナーの組合せ → Match | null
computeAllMatches({ ... })    // 全パートナー走査 + ソート
buildLabel(items)              // UI ラベル生成
haversineMeters(...)           // 2 点間距離（時空交差用）
awsOverlap(myAW, theirAW)     // AW 同士の時空交差判定
```

**マッチ判定ルール**:
- `goods_type_id` が一致必須
- 双方が `character_id` 持ち → キャラ一致必須
- どちらか `character_id` null → `group_id` で一致判定（箱推し的）

**個別募集の優先**:
- 私の譲 X に listing がある場合、その listing.wish_ids 群を「私の wish」として優先使用
- listing がない譲は通常 wish との比較

**ソート**:
- complete > they_want_you = you_want_them
- 同タイプ内では viaListing 優先

#### B. `web/src/app/page.tsx`（拡張）

`Promise.all` の中身を 7 件 → 12 件に拡張:
- 自分の inventory + wishes + listings (active)
- 他者の inventory + wishes（公開分）
- 他者の users（display_name / handle / primary_area）
- 他者の AW（時空交差用）

ホーム描画前に `computeAllMatches` で計算 → `matches: Match[]` を HomeView に渡す。

**現地モード時のフィルタ**:
- `localMode.enabled === true` かつ `currentAW` がある場合
- 他者の AW を user_id 単位に集約
- `awsOverlap(myAW, theirAW)` でフィルタ
- どれか 1 つでも交差すればパートナーとして残す

#### C. `web/src/components/home/HomeView.tsx`（mock 撤去）

- `MOCK_CARDS_BY_TAB` 削除
- `matchToCard(m)` ヘルパで `Match → MockMatchCard`（既存 UI 互換のため型は維持）
- `cardsByTab` を `useMemo` でタブ別に振り分け
  - 0: complete / 1: they_want_you / 2: you_want_them / 3: 全部（探索）
- `tabCounts` で各タブの実件数表示

#### D. RLS と公開設定

既存ポリシー流用（変更なし）:
- `goods_inventory`: status in ('active', 'reserved') は誰でも読める
- `users`: 誰でも読める
- `activity_windows`: status='enabled' は誰でも読める
- `listings`: status='active' は誰でも読める

### 関連ファイル

- `web/src/lib/matching.ts`（新規）
- `web/src/app/page.tsx`（fetch + 計算拡張）
- `web/src/components/home/HomeView.tsx`（mock 撤去 + matchToCard 配線）

### スコープ外（後続 iter）

- 同種/異種タグの判定（現状は表示のみ・iter62 確定）
- 「断った」記録の除外（rejected_partners テーブル未作成）
- ブロックリスト除外（テーブル未作成）
- マッチング結果のキャッシュ（毎回計算でも 500 件 LIMIT で実用範囲）
- 距離の数値表示（現状は primary_area or 「広域」）

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: MatchCard の見た目は変更なし（mock → 実データ）✅
- **B. 仕様整合性**: notes/18 §B-1（タグは判定不使用）/ §B-2（listings 優先）/ §B-4（時空交差）と整合 ✅
- **C. レビュー記録**: 500 件 LIMIT は MVP 暫定。スケール時はサーバ側マッチ（PostGIS / 関数）に切替予定 ✅

---

## イテレーション65.9：プロフ画面 + プロフ編集 + 推し設定編集（案 Z ハイブリッド）

### 背景

オーナー要望: 「プロフ画面と推し設定画面が無いとテストできない」。
iter65.8 で BottomNav の「プロフ」タブからのリンク先がまだ無い状態を解消。
推し設定の動線について 3 案（X/Y/Z）を提示しオーナーが **案 Z（ハイブリッド）** を選択。

### 変更内容

#### A. `web/src/app/profile/actions.ts`（新規）

4 つの server action:
- `updateProfile(input)`: handle / display_name / gender / primary_area を更新（handle 重複チェック含む）
- `removeOshiGroup(groupId)`: グループ単位で user_oshi 全行削除
- `addCharacterToOshi({ groupId, characterId })`: メンバー追加。box 推しは specific 化、priority 自動採番
- `removeCharacterFromOshi({ groupId, characterId })`: メンバー削除。最後のメンバーを消すと box 復活

#### B. `/profile`（新規 + ProfileView.tsx）

モックアップ `hub-screens.jsx::ProfileHub` 準拠（**Q1 = B フル構成**）:
- ヘッダー（タイトル + 設定アイコン）
- アイデンティティ hero（紫グラデ + アバター + @handle + サブ + 統計 4 マス）
  - 統計: 評価（mock —）/ 取引（実 count）/ コレ（mock —）/ AW予定（実 count）
- コレクションサマリ（**準備中** chip）
- あなたの活動: 取引履歴（**準備中**）/ 自分の AW（実件数表示、ホームへリンク）
- アイデンティティ: プロフィール編集 / 推し設定 / 本人確認（メール認証済バッジ）
- 設定・サポート: 設定 / 通知 / ヘルプ（全部 **準備中**）
- ログアウト + アカウント削除（準備中）

#### C. `/profile/edit`（新規 + ProfileEditForm.tsx）

モックアップ `account-extras.jsx::ProfileEdit` ベース:
- アバター プレビュー（変更ボタンは disabled・準備中）
- ハンドル名 input（@ プレフィクス + 半角英数 + アンダースコア・3〜20）
- 表示名 input（必須）
- 性別 chip（女性/男性/その他/回答しない、トグル可）
- 主な活動エリア input（任意）

#### D. `/profile/oshi`（新規 + OshiEditView.tsx）— 案 Z ハイブリッド

- 自分の `user_oshi` をグループ単位でまとめてカード表示
- 各グループカード:
  - ヘッダー: グループ名 + イニシャル四角アイコン + 削除ボタン
  - 推しメンバー chip 群: 名前 + × でメンバー削除
  - 「+ 追加」chip → inline で同グループの**未選択**キャラを chip 表示
  - 「マスタに無いメンバーを追加リクエスト →」リンク → `/onboarding/members/request?groupId=X&return=profile`
- 「＋ 推しを追加（グループ・作品）」ボタン → `/onboarding/oshi?return=profile`

#### E. オンボ画面の `?return=profile` 対応

- `/onboarding/oshi/page.tsx`: searchParams から return を読み、HeaderBack の backHref / title を分岐
- `/onboarding/oshi/OshiForm.tsx`: useSearchParams で return 取得、保存後 router.push 先を `/profile/oshi` に分岐
- `/onboarding/members/request/page.tsx`: HeaderBack backHref を分岐
- `/onboarding/members/request/RequestForm.tsx`: 保存後の遷移先を分岐

### 関連ファイル

- `web/src/app/profile/{actions.ts, page.tsx, ProfileView.tsx}`（新規）
- `web/src/app/profile/edit/{page.tsx, ProfileEditForm.tsx}`（新規）
- `web/src/app/profile/oshi/{page.tsx, OshiEditView.tsx}`（新規）
- `web/src/app/onboarding/oshi/{page.tsx, OshiForm.tsx}`（return 対応）
- `web/src/app/onboarding/members/request/{page.tsx, RequestForm.tsx}`（return 対応）

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: hero card 紫グラデ・統計 4 マス・Section/Row UI を ProfileHub と同等にレイアウト ✅
- **B. 仕様整合性**: users / user_oshi / activity_windows / deals テーブルから実データ取得、未実装機能は **「準備中」chip** で明示 ✅
- **C. レビュー記録**: 評価 / コレクション統計は実装未着手のため `—` 表示。bio 列が users にないため自己紹介編集は省略（必要なら別 iter でカラム追加）✅

---

## イテレーション65.8：コンディション廃止・AW フッター除去・現地モード一体化

### 背景

オーナー要望:
1. グッズ登録時のコンディション入力・編集・表示は不要
2. AW はフッターから削除（独立タブとしては不要）
3. 現地交換モードは AW 別画面に飛ばず、シート内で場所・時間・半径を直接設定

### 変更内容

#### A. コンディション UI を全削除

- `CaptureFlow.tsx` (新規登録 meta ステップ): condition select 削除、レイアウトを「数量のみ」に
- `EditForm.tsx` (/inventory/[id]): 「コンディション」Section 削除、`condition` state と `setCondition` 削除、`updateInventoryItem` への condition 引数渡しを廃止
- DB 列 `goods_inventory.condition` は互換のため残置（NULL 許容）

#### B. BottomNav から AW タブ削除

- `BottomNav.tsx`: items 配列から `{ href: "/aw", label: "AW", ... }` を削除
- 5 タブ → 4 タブ（ホーム / 在庫 / wish / プロフ）
- `NavIcon` の `name` 型から `"aw"` を除外、対応 case 削除
- `/aw` ルート自体は残置（直接 URL アクセス可、ホーム経由で機能は使える）

#### C. LocalModeSheet 全面リファクタ

シート内で **AW 作成 + 場所・時間・半径** を完結。AW 編集画面に飛ばない。

新構成:
- **場所**: 検索バー (Nominatim) + 「現在地」ボタン（GPS）+ 地図 (Leaflet) 表示 + venue text input
- **半径**: スライダー (200〜2000m)、地図上に同期表示
- **時間**: 持続時間 chip (1h/2h/3h/6h/終日) + 「開始時刻も指定する」expand で datetime-local 2 個
- **持参グッズ**: `/inventory/select-carrying` への リンクカード + 解除ボタン

「現在のシート対象 AW (currentAW)」を `localMode.aw_id` から決定し、開いたときに既存値で初期化。
シートを開く度に DB 値で再初期化。

旧 prop `aws: SimpleAW[]` は廃止、`currentAW: SimpleAW | null` に変更。

#### D. applyLocalModeAW server action 追加

`web/src/components/home/actions.ts`:

```ts
applyLocalModeAW({ venue, centerLat, centerLng, radiusM, startAt, endAt })
```

ロジック:
1. バリデーション (venue 1-100 文字、半径 50-5000m、終了 > 開始)
2. `user_local_mode_settings.aw_id` を確認
3. 既存 AW があれば UPDATE、なければ INSERT で作成
4. 失敗時は新規作成にフォールバック
5. settings に aw_id・radius_m・last_lat/lng を upsert

これで「シート → 1 ボタンで AW 作成 + モード ON + 設定保存」が完結。

### 関連ファイル

- `web/src/app/inventory/new/CaptureFlow.tsx`
- `web/src/app/inventory/[id]/EditForm.tsx`
- `web/src/components/home/BottomNav.tsx`
- `web/src/components/home/LocalModeSheet.tsx` (大改修)
- `web/src/components/home/HomeView.tsx`
- `web/src/components/home/actions.ts` (`applyLocalModeAW` 追加)
- `web/src/app/page.tsx` (currentAW を選別して渡す)

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: シート内地図・検索・chip 群は既存 `aw/new/location` と統一トーン ✅
- **B. 仕様整合性**: 既存 `activity_windows` テーブル流用、`user_local_mode_settings.aw_id` で紐付け、別経路で AW を 1 つ作る運用 ✅
- **C. レビュー記録**: condition / aw タブは UI のみ廃止、DB / ルートは残置。AW 一覧画面は `/aw` で引き続きアクセス可能（直接 URL）✅

---

## イテレーション65.7：UI さらに簡素化（priority/フィルタ/モック/トグル削除、定価追加）

### 背景

オーナーから連続要望:
1. wish 一覧の「最優先」「2 番手」フィルタを削除
2. wish と個別募集で「定価」を選べるようにしたい
3. 現地モード持参選択画面の右上に「選択解除」ボタン
4. AW 追加で「イベントから埋める」モードを削除
5. 場所から作るモードの「このエリアの近日イベント」リスト削除
6. 場所から作るモードの「19:00」「19:30」固定 chip 削除
7. 「今すぐ交換」「動けます」トグルも削除

### 変更内容

#### A. Migration: 「定価」を goods_types_master に追加

`supabase/migrations/20260503150000_add_cash_goods_type.sql`:
- `('定価', 'other', 90)` を insert
- 既存 CHECK 制約に合わせて category は `other` を流用（cash 専用 category は追加しない）

#### B. WishView: priority フィルタ chip を削除

- 「最優先」「2 番手」「妥協 OK」フィルタ chip 行を削除
- `filter` state, `counts` useMemo, `filtered` ロジックを simplify
- カード内の priority バッジ表示も削除
- `PRIO_LABEL`, `useState`, `useMemo` import 削除

#### C. CarryingSelectView: 右上に「選択解除」ボタン

- ヘッダー下に説明文 + 右寄せの「選択解除」ボタンを配置
- 選択件数 0 のとき disabled
- 既存の inline「解除」ボタンは「表示全選択」のみ残置

#### D. AWAddEntry: 「イベントから埋める」を削除

- secondary card（🎤 イベントから埋める）の Link を削除
- prefetch から `/aw/new/event` を削除
- チューザーの選択肢は「📍 場所から作る」のみ
- `/aw/new/event` ルート自体は残置（直接 URL アクセスは可能）

#### E. LocationLedForm: 不要 UI を一括削除

- 「このエリアの近日イベント」section（イベントなし + MOCK_EVENTS リスト）→ 削除
- 「有効時間」chip から `19:00`, `19:30` を削除（残る: いま / 15分後 / 30分後）
- 「今すぐ交換」トグル削除
- 「動けます」トグル削除
- handleSubmit を `eventless: true, eventName: undefined` 固定に
- 終了時刻表示の chosenEvent 分岐を削除（常に「N 分間」表示）

未使用の MOCK_EVENTS / selectEvent / chosenEvent / express / mobile state を削除。

### 関連ファイル

- `supabase/migrations/20260503150000_add_cash_goods_type.sql`（新規）
- `web/src/app/wishes/WishView.tsx`
- `web/src/app/inventory/select-carrying/{page.tsx, CarryingSelectView.tsx}`
- `web/src/app/aw/new/AWAddEntry.tsx`
- `web/src/app/aw/new/location/LocationLedForm.tsx`

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: 既存の chip / button スタイルを流用、削除のみで新規追加 UI なし ✅
- **B. 仕様整合性**: 「定価」は goods_types_master の通常エントリとして追加（特殊ロジックなし）。AW の `eventless` 列はそのまま、保存時 true 固定 ✅
- **C. レビュー記録**: `/aw/new/event` ルートは残置（直 URL 可）。AWAddEntry チューザーの選択肢が 1 個だけになり「チューザーである必要性」は薄いが、UI 構造を急変させないため残置 ✅

---

## イテレーション65.6：現地モード簡素化・持参グッズ管理を全面再構成・AW 戻り先実装

### 背景

iter65.5 で wish/listings UI を整理した直後、オーナーから連続フィードバック:

1. 「現地交換モードでマッチ範囲を指定するな（AW のを使え）」
2. 「AW 未設定時に AW 追加 → 戻ってきたら現地モード画面に戻る」
3. 「持参グッズは画像で選ばせろ。グッズ一覧と同じ感じで」
4. 「現地モードの『求めるグッズ』選択は不要、削除」
5. 「マイ在庫から持参グッズを指定する機能は全削除」
6. 「wish 追加時の交換タイプも不要（個別募集の時に設定するから）」

### 変更内容

#### A. LocalModeSheet 大幅簡素化

- 半径スライダー削除（AW 自身の radius_m を使う）
- wish multi-select 削除（指定なし → 自動的に全件対象）
- 持参グッズ multi-select chip も削除し、**「グッズを選ぶ →」リンク**に置換
  → `/inventory/select-carrying?return=local-mode` に飛ぶ
- AW カードに「半径 N」chip を追加（AW 値の可視化）
- AW 追加リンクに `?return=local-mode` を付与

#### B. `/inventory/select-carrying` 持参グッズ選択画面（新規）

- 写真付きパネル（aspect 3/4 カード、in-place チェックマーク）
- 推し / 種別フィルタ chip 行
- 「全選択」「解除」ヘルパー
- 下部固定 CTA「N 件で確定して戻る」 → updateLocalModeSelections → router.push(returnTo)
- HeaderBack の戻るリンクも returnTo を尊重

#### C. AW 作成 → 戻り先伝搬

- `/aw/new/page.tsx`: searchParams.return を読み AWAddEntry に渡す
- `AWAddEntry`: location-led / event-led の Link href にクエリ伝搬、close ボタンも `?return=local-mode` のとき `/?openLocalMode=1` に
- `LocationLedForm` / `EventLedForm`: `useSearchParams` で return を取得、saveAW 後の `router.push` を動的化
- `app/page.tsx`: `?openLocalMode=1` を検知して `HomeView` に `autoOpenLocalSheet={true}` を渡す
- `HomeView`: `useEffect` で URL クエリを history.replaceState で除去（戻るボタン対策）

#### D. マイ在庫の持参グッズ管理を全削除

- `InventoryView`:
  - 外出モードバナー削除
  - 一括 carrying トグル（メニュー）削除
  - `toggleCarryingAll` / `toggleGoingOut` / `toggleItemCarrying` の import 削除
  - `isGoingOut` / `showMoreMenu` state 削除
  - `SubPanel` / `ItemCardWrapper` の `onCarryingToggle` prop 削除
- `ItemCard`:
  - 右上の carrying ドット（タップ領域）削除
  - `onCarryingToggle` prop 削除
- `inventory/page.tsx`:
  - `users.is_going_out` の fetch 削除
  - `InventoryView` から `isGoingOut` prop 削除

DB 列（`goods_inventory.carrying`、`users.is_going_out`、`toggleCarryingAll` server action）は互換のため残置。

#### E. wish から「交換タイプ」削除（オーナー追加要望）

- `WishNewForm`: EXCHANGE_OPTIONS / exchangeType state / chip section 削除
- `WishView`: EXCHANGE_LABEL / chip 表示削除、FLEX_LABEL も同時削除
- saveWishItem 呼び出しでは `exchangeType: "any"` 固定
- 交換タイプは個別募集（listings）作成時のみ設定

### 関連ファイル

- `web/src/components/home/{LocalModeSheet.tsx, HomeView.tsx, actions.ts}`
- `web/src/app/page.tsx`
- `web/src/app/inventory/select-carrying/{page.tsx, CarryingSelectView.tsx}`（新規）
- `web/src/app/aw/new/{page.tsx, AWAddEntry.tsx, location/LocationLedForm.tsx, event/EventLedForm.tsx}`
- `web/src/app/inventory/{InventoryView.tsx, ItemCard.tsx, page.tsx}`
- `web/src/app/wishes/{new/WishNewForm.tsx, WishView.tsx}`
- `notes/18_matching_v2_design.md` §11 追加（マッチング仕様 + 65.6 の決定事項）

### 残課題（iter66+）

- 個別募集マッチングロジック（その譲には listing の wish 群でしかマッチしない）の実装
- 現地モードの実マッチング演算（mock を実データに置換）
- 個別募集が登録された譲アイテムの通常マッチ抑制（要確認）

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: シート構造の変更でフットプリント減（半径・wish 選択 UI 削除）、リンク（「グッズを選ぶ →」）に既存 chip スタイル流用 ✅
- **B. 仕様整合性**: notes/18 §A-4（位置情報以外は記憶）、§A-5（wish 不要）と整合 ✅
- **C. レビュー記録**: DB 列削除はせず（マイグレーション影響大）、UI 廃止のみ。「個別募集の譲は通常マッチから除外するか」は要確認として記録 ✅

---

## イテレーション63〜65：マッチング v2 一気実装（ホームモード切替・個別募集・カレンダー overlay）

### 背景

iter62 までで Phase A（wish.exchange_type）が完了。残りの 3 フェーズ（B/C/D）を一気に実装したいというオーナー指示で、3 つの iter を 1 セッションでまとめて実装。

### iter63 — Phase B: ホーム広域/現地モード切替

#### Migration

`supabase/migrations/20260503120000_add_local_mode_settings.sql`:
- `user_local_mode_settings` テーブル新規（user_id PK、enabled、aw_id、radius_m、selected_carrying_ids[]、selected_wish_ids[]、last_lat/lng）
- updated_at trigger、RLS ポリシー

#### Server actions

`web/src/components/home/actions.ts`（新規）:
- `enableLocalMode({ lat, lng })`: 現地モード ON、GPS で位置上書き
- `disableLocalMode()`: 広域モードに戻す
- `updateLocalModeSelections(...)`: AW・半径・持参・wish 選択の永続化
- `resetLocalModeSelections()`: 持参・wish 一括リセット

#### UI

`web/src/app/page.tsx`:
- 並列 fetch: profile + localMode + AW 一覧 + 携帯候補 + wish 一覧
- HomeView へ props で渡す

`web/src/components/home/HomeView.tsx`（大改修）:
- 上部に **「🌐 広域 / 📍 現地交換」モード pill** 追加
- 現地モード ON 切替時に `navigator.geolocation` で GPS 取得 → enableLocalMode
- 現地モード ON 時: AW + 半径 + 件数のサマリ表示 + 「設定」ボタン
- venue banner は廃止（モード pill とサマリに統合）

`web/src/components/home/LocalModeSheet.tsx`（新規）:
- slide-up シート（aria-modal、body スクロールロック、ESC 等は今回省略）
- AW 選択 list（自分の active な AW から）
- 半径スライダー（200〜2000m）
- 持参グッズ multi-select chip
- wish multi-select chip
- 「選択を全解除」ボタン（一括リセット）
- 「この設定で表示」CTA

`web/src/components/home/MatchCard.tsx`:
- `exchangeType` prop 追加
- `any` 以外のときマッチカード末尾に紫 chip + 注釈表示

### iter64 — Phase C: 個別募集（listings）

#### Migration

`supabase/migrations/20260503130000_add_listings.sql`:
- `listings` テーブル新規（user_id, inventory_id, wish_id, exchange_type, ratio_give/receive, priority, status, note）
- ratio_give/receive は 1〜10 CHECK
- priority は 1〜5 CHECK
- status: `active` / `paused` / `matched` / `closed`
- **整合性 trigger** `validate_listing_refs`:
  - listings.user_id == inventory.user_id == wish.user_id
  - inventory は kind='for_trade'、wish は kind='wanted'
- RLS: 自分の全件可視、他人の active なものは誰でも閲覧

#### Server actions

`web/src/app/listings/actions.ts`（新規）:
- `createListing(...)`: 作成
- `updateListing(...)`: 部分更新（status / 比率 / 優先度 / メモ / exchangeType）
- `deleteListing(id)`

#### 画面

- `web/src/app/listings/page.tsx`（新規）: 個別募集一覧
  - join で inventory + wish を取得して一画面でカード表示
- `web/src/app/listings/ListingsView.tsx`（新規）:
  - status バッジ + 優先度 + 交換タイプ
  - 譲（写真 + メンバー）/ 比率（譲 N ↔ 受 M）/ wish（プレースホルダ）
  - 「一時停止」「再開」「削除」アクション
- `web/src/app/listings/new/page.tsx` + `ListingNewForm.tsx`（新規）:
  - 譲 select（自分の active な譲から、写真付き）
  - wish select（wish の exchange_type を引き継ぐ）
  - 交換タイプ chip
  - 比率 stepper（譲 1〜10 ↔ 受 1〜10）
  - 優先度 5 段階 chip
  - メモ
- `WishView.tsx` のヘッダーに「個別募集 →」リンク追加（動線）

### iter65 — Phase D: CalendarOverlay コンポーネント

#### コンポーネント

`web/src/components/calendar/CalendarOverlay.tsx`（新規）:
- props: myAWs / partnerAWs / days（default 7）/ fromDate / colors
- 横軸: 日付（7 日分、横スクロール可）、縦軸: 時刻（8:00〜24:00）
- 自分の AW を左半分に紫帯、相手を右半分にピンク帯で描画
- 重なる時間帯を黄色（#e0a847）でハイライト + 上下ボーダー
- 凡例（自分 / 相手 / 重なり）

打診画面（C-1 / propose-select）が iter67-68 で実装される時、`<CalendarOverlay myAWs={...} partnerAWs={...} />` で組み込む。

#### proposals テーブルへの列追加は保留

`proposals` テーブルが現状未作成のため、`expose_calendar` / `listing_id` の追加 migration は **打診機能実装時（iter67-68）に同時実行**。本 iter ではコンポーネントだけ用意。

### 関連ファイル

- `supabase/migrations/20260503120000_add_local_mode_settings.sql`
- `supabase/migrations/20260503130000_add_listings.sql`
- `web/src/app/page.tsx`
- `web/src/components/home/{actions.ts, HomeView.tsx, LocalModeSheet.tsx, MatchCard.tsx}`
- `web/src/app/listings/{page.tsx, ListingsView.tsx, actions.ts}`
- `web/src/app/listings/new/{page.tsx, ListingNewForm.tsx}`
- `web/src/components/calendar/CalendarOverlay.tsx`
- `web/src/app/wishes/WishView.tsx`（個別募集リンク追加）

### 残り課題

1. 現地モードのマッチング演算は引き続き mock（実演算は iter66+）
2. CalendarOverlay は単体テスト用のページがまだ無い → iter67-68 の打診画面で組み込む
3. 個別募集のマッチカード表示（match card に listing バッジを出す）も iter66+

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: モード pill / シート / 個別募集カード — 既存 Megrum トーン（紫グラデ + 薄紫枠 + chip スタイル）と統一 ✅
- **B. 仕様整合性**: notes/05 / 09 / 18 のスキーマ・ライフサイクルと整合。listings の trigger で参照整合性を強制 ✅
- **C. レビュー記録**: proposals 列追加は打診画面実装時に統合と明記。実マッチング演算は iter66 以降 ✅

---

## イテレーション62：Phase A — wish に exchange_type 追加 + chip 表示

### 背景・問題意識

iter61.11 で確定したマッチング v2 仕様の最初の段階。wish に「同種交換 / 異種交換 / どちらでも」のタグを付けられるようにする。**自己申告タグ**であり、システムはマッチング判定に使わない（notes/18 §A-1）。

### 変更内容

#### A. Migration

**`supabase/migrations/20260503110000_add_exchange_type.sql`**

`goods_inventory` テーブルに `exchange_type` カラム追加:
- 値: `same_kind` / `cross_kind` / `any`（default `any`）
- CHECK 制約付き
- not null（default で埋まる）

**注**: notes/05_data_model.md §3 では `user_wants.exchange_type` と書いていたが、実装上は wish/譲を `goods_inventory` テーブルに統合しているため、`goods_inventory.exchange_type` として実装。`kind='wanted'` の行で wish 用、`kind='for_trade'` では譲側でも使える設計（譲側は iter64 で listings 経由で意味を持つ）。

#### B. Server action

**`web/src/app/wishes/actions.ts`**

- 型定義 `ExchangeType` をエクスポート
- `saveWishItem` に `exchangeType?: ExchangeType` 引数追加（default `any`）
- VALID_EXCHANGE 配列でバリデーション

#### C. wish 新規作成 UI（`WishNewForm.tsx`）

- `EXCHANGE_OPTIONS` 定数（3 件 chip）
- 「交換タイプ」Section 追加（許容範囲の下、メモの上）
- 3 列 grid の chip ボタン: `どちらでも / 同種のみ / 異種のみ`
- アクティブ時は紫グラデ
- 注釈: 「自己申告タグです。マッチング演算では弾かれません。相手の譲るグッズと並べてユーザー自身が判断する用途。」

#### D. wish 一覧表示（`WishView.tsx`）

- `WishItem` 型に `exchangeType: "same_kind" | "cross_kind" | "any"` 追加
- `EXCHANGE_LABEL` 定数追加
- カード右上のチップ群（priority + flexLevel）の右に exchangeType chip を追加
- `any` のときは表示しない（ノイズを避ける）
- 紫透明枠 + 紫文字で他の chip と差別化

#### E. wish 一覧の SELECT 拡張

**`web/src/app/wishes/page.tsx`**

- SELECT 句に `exchange_type` 追加
- `WishRow` 型に列追加
- mapping で `exchangeType: r.exchange_type ?? "any"` を渡す

### 後続フェーズへの繋ぎ

- iter63（Phase B）でホーム画面のマッチカードにも同じ chip を表示する予定（現状ホームは mock data なので未対応）
- iter64（Phase C）で listings にも同じ exchange_type 列を引き継ぐ
- iter65（Phase D）打診の calendar 公開フラグでカードをさらに拡張

### 関連ファイル

- `supabase/migrations/20260503110000_add_exchange_type.sql`（新規）
- `web/src/app/wishes/actions.ts`（saveWishItem 拡張）
- `web/src/app/wishes/new/WishNewForm.tsx`（chip 追加）
- `web/src/app/wishes/page.tsx`（SELECT + mapping）
- `web/src/app/wishes/WishView.tsx`（型 + chip 表示）

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: 既存 chip スタイル（rounded-full, 紫トーン）に揃えた ✅
- **B. 仕様整合性**: notes/18 §A-1（タグのみ・判定なし）と整合。実装上の `goods_inventory` 統合と仕様の `user_wants` の差は本ドキュメントで言及 ✅
- **C. レビュー記録**: ホームのマッチカードに chip 表示は iter63 で同時対応（現状ホーム mock のため）✅

---

## イテレーション61.11：マッチング v2 仕様を主要ドキュメントに反映

### 背景・問題意識

iter61.10 までで在庫まわりの UX が一段落。次の大きな展開（広域/現地マッチ・個別募集・カレンダー公開）に向けて、雑多メモ → notes/18 整理 → オーナー回答 §A の流れで仕様が確定。本 iter は **コード実装には入らず**、既存の主要ドキュメント 5 本に確定事項を反映するだけ。

これがないと iter62〜65 の実装着手時に CLAUDE.md の「着手前精読」ルールが機能しない。

### 変更内容（ドキュメントのみ）

#### A. `notes/10_glossary.md` §E に 11 用語追加

広域マッチ / 現地マッチ / 個別募集 / 同種交換 / 異種交換 / 混合交換 / 交換比率 / カレンダー公開 / カレンダー重ね見 を追加。「同種/異種は自己申告タグのみ」と明記。

#### B. `notes/02_system_requirements.md` F4 マッチング節を v2 に書き換え

- 「2軸構成」 → 「3軸構成（広域 / 現地 / 個別募集）」
- 通知制御は「MVP 範囲外」と明記
- 「同種/異種はタグのみ、システム判定なし」と明記
- 打診時のカレンダー公開（重ね見）を追加

#### C. `notes/05_data_model.md` に 4 つの追加

- `user_wants.exchange_type` 列追加（iter62）
- 新テーブル `listings`（iter64、wish_id 必須・ratio_give/receive・priority）
- 新テーブル `user_local_mode_settings`（iter63、現地モード永続化）
- `proposals.expose_calendar` + `proposals.listing_id` 列追加（iter65）

#### D. `notes/09_state_machines.md` に 3 つの新ライフサイクル追加

- **§8 Listing Lifecycle**: active / paused / matched / closed
- **§9 Calendar Disclosure**: not_disclosed / disclosed / auto_revoked
- **§10 Local Mode**: global / local / local_reset
- 旧 §8 付録は §11 にリネーム

#### E. `notes/11_screen_inventory.md` に 9 画面追加

- C-1 ホームに 4 行（モード pill / 現地 setup / 現地サマリ / カードタグ）
- C-3 ウィッシュに 3 行（exchange tag chip / 個別募集作成 / 個別募集一覧）
- B-2 打診に 2 行（カレンダー公開トグル / カレンダー overlay UI）

### 関連ファイル

- `notes/02_system_requirements.md`
- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`
- `notes/11_screen_inventory.md`
- `notes/18_matching_v2_design.md`（前 iter で作成）

### 次の実装計画

| iter | 内容 | 範囲 |
|---|---|---|
| iter62 | Phase A: `user_wants.exchange_type` 追加 + chip 表示 | 小（migration + UI 1 箇所） |
| iter63 | Phase B: ホームモード切替 + 現地設定 + 一括リセット | 大（home-v2 大改修 + 新テーブル） |
| iter64 | Phase C: 個別募集（listings）UI + マッチング統合 | 大（新画面 2 つ + ロジック） |
| iter65 | Phase D: 打診カレンダー公開 + overlay UI | 中（proposals 列 + overlay コンポーネント） |
| iter66 | 検索＋フィルタ（後送り） | 中（元 iter62） |

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: 該当なし（コード変更なし）
- **B. 仕様整合性**: 5 本のドキュメント間で用語・テーブル名・列名が整合 ✅
- **C. レビュー記録**: 18 → 02/05/09/10/11 への反映漏れなし。「listing」は UI 表記から除外して「個別募集」に統一 ✅

---

## イテレーション61.10：審査中メンバーを在庫の選択肢に + シリーズ廃止

### 背景・問題意識

ユーザー要望:
1. 「グッズ登録の際、追加リクエストしたものも選べる選択肢に含めてほしい」
2. 「グッズの編集画面で『シリーズ』は削除してください。もう使わないので」

iter61.9 で追加リクエスト機能は付けたが、リクエスト中のメンバーは select に出てこず、登録すると `character_id = null` のまま保存され、後で承認されても紐付かなかった。
データモデルとして `goods_inventory.character_request_id` を追加し、user_oshi と同じ「承認時に自動置換」の仕組みを採用。

### 変更内容

#### A. Migration: `goods_inventory.character_request_id` 追加

**`supabase/migrations/20260503100000_add_inventory_character_request.sql`**

- `character_request_id uuid references character_requests(id) on delete set null`
- `character_id is null or character_request_id is null` の XOR 制約（同時に持たない）
- `idx_goods_inventory_character_request` インデックス
- `handle_character_request_approval()` trigger を拡張:
  - 承認時 (`status: pending → merged/approved`) に `goods_inventory.character_request_id → character_id` 置換
  - 却下時 (`pending → rejected`) は `character_request_id` を null にしてメンバー指定なしに戻す（user_oshi のように行ごと削除はしない）

#### B. 新規登録 (`CaptureFlow`) で pending メンバーを選択肢に

**`web/src/app/inventory/new/page.tsx`**

`character_requests` を並列 fetch（自分の `pending` ステータスのみ、推しグループに紐づくもの）し、CaptureFlow に `pendingMembers` prop で渡す。

**`web/src/app/inventory/new/CaptureFlow.tsx`**

- `CropMeta.characterId` の値を文字列のまま prefix encoding で持つ:
  - `""` = 指定なし
  - `"<UUID>"` = `characters_master.id`
  - `"req:<UUID>"` = `character_requests.id`（審査中）
- select に `<optgroup label="審査中">` で pending を表示（"○○（審査中）"）
- meta インラインリクエストフォーム送信成功時、`pendingMembers` ローカル state にも即追加 → select に瞬時に反映
- 保存時に `splitCharacterValue` で分岐し、`characterId` / `characterRequestId` を別々に渡す

**`web/src/app/inventory/actions.ts`**

`saveBatchInventoryItems` と `updateInventoryItem` に `characterRequestId?: string | null` 引数追加。XOR 制約に従い、片方しか入らないように保存。

#### C. 編集画面 (`/inventory/[id]`) でも pending サポート

**`web/src/app/inventory/[id]/page.tsx`**

- SELECT に `character_request_id` を追加、`character_requests` も並列 fetch
- `pendingMembers` prop で EditForm に渡す

**`web/src/app/inventory/[id]/EditForm.tsx`**

- `characterId` / `characterRequestId` を pack/split して `characterValue` 単一 state で管理
- chip UI で pending メンバーを破線枠 + 「審査中」バッジ付きで表示
- 「運営の承認後、自動でメンバーマスタに切り替わります」のヒント表示
- 保存時に分割して `updateInventoryItem` に渡す

#### D. 一覧画面で pending 名を解決

**`web/src/app/inventory/page.tsx`**

- SELECT に `character_request:character_requests(requested_name, status)` を join
- `memberName` の解決順を `character → character_request → group` に
- 「審査中」フラグ `isPending` を渡す

**`web/src/app/inventory/ItemCard.tsx`**

- `isPending` のとき、メンバー名プレートの右に紫の「審査中」バッジを併置

#### E. 「シリーズ」を UI から完全廃止

- `EditForm.tsx`: 「シリーズ」セクションを削除
- `page.tsx` (inventory list): SELECT から `series` を抜き、`series: null` 固定で渡す（ItemCard の表示は `{item.series && ...}` で条件付きなので何も出ない）
- `actions.ts` の DB カラム書き込み (`series`) は互換のため残置（既存データ非破壊、将来的に migration で drop 予定）
- CaptureFlow の `CropMeta.series` も互換のため残置（送信は常に空文字 → null）

### 動線まとめ

1. 在庫登録 → meta ステップ → メンバー select に審査中グループも出る
2. 「+ メンバー追加リクエスト」で送信すると即その場で select 候補に追加 → そのまま選択可能
3. 「審査中」のまま登録 → 一覧カードに「審査中」バッジ表示
4. 運営が承認 → trigger が自動で `character_id` に置換 → カードのバッジが消えて正規メンバー名に

### 関連ファイル

- `supabase/migrations/20260503100000_add_inventory_character_request.sql`（新規）
- `web/src/app/inventory/page.tsx`（pending join、シリーズ非表示）
- `web/src/app/inventory/ItemCard.tsx`（審査中バッジ）
- `web/src/app/inventory/[id]/page.tsx`（pending fetch）
- `web/src/app/inventory/[id]/EditForm.tsx`（pending サポート、シリーズ削除、auto-title）
- `web/src/app/inventory/new/page.tsx`（pending fetch）
- `web/src/app/inventory/new/CaptureFlow.tsx`（select に optgroup）
- `web/src/app/inventory/actions.ts`（characterRequestId 引数）

### セルフレビュー

- **A. デザイン整合性**: 審査中バッジは既存 onboarding の紫トーンと整合 ✅
- **B. 仕様整合性**: trigger で自動置換するので承認後の手動再選択は不要 ✅
- **C. レビュー記録**: シリーズは UI 廃止のみ、DB カラムは互換のため残置 ✅

---

## イテレーション61.9：在庫まわり 5 つの UX 改善

### 背景・問題意識

ユーザーから 4 つの要望:
1. 「グッズ一覧で押すと『キープに/譲渡履歴へ』が出てくる選択肢の中に『編集する』を追加してほしい（編集画面に直接飛ぶ動線ではなく、既存メニュー経由）」
2. 「編集画面で写真を撮り直せるようにしてほしい」
3. 「在庫登録で、タイトルは基本的に入力不要・非表示。グッズ種別『その他』選択時のみ表示」
4. 「メンバーが不足していたら、登録画面でも追加リクエストを入れられるように」
5. 「写真は1枚も取らなくても登録できるように」

### 変更内容

#### A. 既存メニューに「編集する」追加

**`web/src/app/inventory/ItemCard.tsx`**

- iter61.8 で `<Link>` 化していたのを元の `<div>` に戻す（既存の `ItemCardWrapper` がメニューを出す方式に戻す）
- carrying トグルは `e.stopPropagation()` のみ（preventDefault は不要）

**`web/src/app/inventory/InventoryView.tsx`**

`ItemCardWrapper` のメニューに 4 番目のアクション「編集する」追加:
- 紫グラデの prominent ボタン（`/inventory/[id]` への Link）
- 「譲る候補に / キープに / 譲渡履歴へ / 編集する / 閉じる」の順

#### B. 編集画面の写真撮り直し

**`web/src/app/inventory/actions.ts`**

`updateInventoryItem` に `photoUrls?: string[]` 引数追加。指定された場合は `photo_urls` 配列を完全置換。

**`web/src/app/inventory/[id]/EditForm.tsx`**

- 写真エリアを動的に再構築:
  - `<img>` フルブリード or「写真なし」プレースホルダ
  - オーバーレイ位置に「📷 撮り直す / 差し替え」ボタン
  - hidden file input + `capture="environment"`（カメラ起動）
- `handlePhotoChange`:
  - 画像タイプ / 10MB バリデーション
  - Supabase Storage `goods-photos` bucket に `{userId}/{ts}_{rand}.{ext}` で upload
  - `getPublicUrl` で URL 取得 → photoUrls の先頭に置換
  - 旧画像は best-effort で `remove([oldPath])`（ストレージ容量節約）
- `extractStoragePath` ヘルパで public URL から bucket 内 path を抽出

#### C. タイトルを「その他」選択時のみ表示

**`web/src/app/inventory/new/CaptureFlow.tsx`**

- meta ステップで `selectedGoodsType?.name === "その他"` の時のみタイトル input をレンダ
- それ以外は title state は空のまま、`handleBatchSave` 内で「メンバー名 + 種別名」を自動生成（既存ロジック）
- placeholder も「タイトル（その他なので入力）」に変更

#### D. 登録時のメンバー追加リクエスト動線

**`web/src/app/inventory/actions.ts`**

新規 server action `requestCharacterFromInventory(groupId, name, note?)`:
- `character_requests` テーブルに insert（既存スキーマと整合: `user_id`, `group_id`, `requested_name`, `note`）
- 返り値で `id` を返す

**`web/src/app/inventory/new/CaptureFlow.tsx`**

- meta ステップ上部に「+ メンバーが見つからない場合は追加リクエスト」ボタン
- クリック → inline form 展開（名前 + メモ）
- 送信 → `requestCharacterFromInventory` 呼び出し → 成功で local state `requestedNames` に追加
- 「送信済リクエスト」セクションに `審査中` バッジで表示
- 注意: リクエスト中の character は `goods_inventory.character_id` には紐付かない（FK 制約）。承認後に編集画面で再選択する運用

#### E. 写真ナシでも登録可能

**`web/src/app/inventory/actions.ts`**

`saveBatchInventoryItems` の各 item の `photoUrl` を任意化:
- 未指定なら `photo_urls: []` で保存（DB スキーマは default '{}' なので OK）

**`web/src/app/inventory/new/CaptureFlow.tsx`**

- shoot ステップに「写真なしで登録する →」リンク追加
- `skipPhotoToMeta()` で cropMetas に空の 1 件を初期化、step="meta" へ
- `noPhoto` フラグ（`crops.length === 0`）で UI 分岐:
  - meta タイトルを「登録内容を設定」に
  - サムネ表示・削除ボタンを非表示
  - 戻るボタン先を `crop` → `shoot` に
  - CTA 文言を「1 件登録（写真なし）」に
- `handleBatchSave` の noPhoto 分岐: cropMetas[0] のみで 1 件、photoUrl なしで登録

### 関連ファイル

- `web/src/app/inventory/ItemCard.tsx`（Link 戻し）
- `web/src/app/inventory/InventoryView.tsx`（メニューに編集追加）
- `web/src/app/inventory/[id]/EditForm.tsx`（写真撮り直し）
- `web/src/app/inventory/new/CaptureFlow.tsx`（C/D/E 一括）
- `web/src/app/inventory/actions.ts`（`updateInventoryItem` 拡張、`requestCharacterFromInventory` 新規、`saveBatchInventoryItems.photoUrl` 任意化）

### セルフレビュー

- **A. デザイン整合性**: 既存メニューの styling（黒半透明 overlay）に揃える、編集ボタンだけ紫グラデで differentiate ✅
- **B. 仕様整合性**: character_requests テーブルのカラム名（`user_id`, `requested_name`）を既存 onboarding actions と整合 ✅
- **C. レビュー記録**: リクエスト中キャラは FK 制約で紐付け不可 → 編集画面で承認後に再選択する運用と明記。タイトル自動生成ロジックは既存を維持 ✅

---

## イテレーション61.8：在庫アイテムの編集 / 削除画面（/inventory/[id]）

### 背景・問題意識

ユーザーから「在庫を削除できるようにしてほしい。あと編集も。編集画面に飛んで、削除できるのがいいかな」。
現状: 在庫一覧画面にカードがあるだけで、削除や編集の動線がなかった（`updateInventoryStatus` と `deleteInventoryItem` の server action は既存だが UI 未配線）。

### 変更内容

#### `web/src/app/inventory/actions.ts`

`updateInventoryItem` server action 追加:
- 編集対象: group / character / goodsType / title / series / description / condition / quantity
- バリデーション: title 1〜100、quantity 1〜999、condition は VALID_CONDITIONS のいずれか
- `revalidatePath("/inventory")` + `revalidatePath("/inventory/[id]")`

`deleteInventoryItem` は既存。

#### `web/src/app/inventory/[id]/page.tsx`（新規）

- dynamic route `/inventory/[id]`
- 並列取得: item 本体 + user_oshi + goods_types + characters
- アイテムが「現在の推し」に紐付かないグループに属している場合も groups_master から救済取得
- 該当グループに属するキャラだけフィルタしてフォームに渡す
- HeaderBack で `/inventory` への戻りリンク

#### `web/src/app/inventory/[id]/EditForm.tsx`（新規）

フィールド構成（モックアップ b-inventory のラベル UI 流用）:
- 写真表示（先頭 URL のみ、フルブリード）
- グループ（推しから選択）
- メンバー / キャラ（任意、グループ依存）
- グッズ種別（chip）
- タイトル（必須）
- シリーズ（任意）
- コンディション（chip、5 段階 + 指定なし）
- 数量（−/＋ + 直接入力、1〜999）
- 説明 / メモ（500 文字）
- ステータス（active / keep / traded を 3 列 grid）

下部 CTA:
- `PrimaryButton`「変更を保存」（紫グラデ）
- 区切り線の下に赤い「この在庫を削除」ボタン（confirm 必須）

#### `web/src/app/inventory/ItemCard.tsx`

- 外側 `<div>` を `<Link href="/inventory/[id]">` に置換
- カード本体タップで編集画面へ
- 右上の carrying トグルは `e.preventDefault() + e.stopPropagation()` で Link への伝搬を止める

### 動線

1. `/inventory` の在庫グリッドでカードタップ
2. `/inventory/[id]` 編集画面に遷移
3. フィールド変更 → 「変更を保存」 → `/inventory` へ戻る
4. 削除 → confirm → `deleteInventoryItem` → `/inventory` へ戻る
5. carrying ドット（右上）はカード上で個別操作（編集画面に行かない）

### 関連ファイル

- `web/src/app/inventory/[id]/page.tsx`（新規）
- `web/src/app/inventory/[id]/EditForm.tsx`（新規）
- `web/src/app/inventory/actions.ts`（updateInventoryItem 追加）
- `web/src/app/inventory/ItemCard.tsx`（Link 化、ストッププロパゲーション）

### セルフレビュー

- **A. デザイン整合性**: 編集フォームは AWNewForm / WishNewForm と同じ Section ラベル UI に揃えた。削除ボタンは赤系で他と差別化 ✅
- **B. 仕様整合性**: VALID_CONDITIONS / quantity 範囲 / status enum を新規 / 既存 action と整合 ✅
- **C. レビュー記録**: 写真の差し替えは未実装（次 iter で）、carrying トグルの伝搬制御を明示的に preventDefault で対応 ✅

---

## イテレーション61.7：AW slide-up シート + 「今すぐ開始」+ 在庫一覧で写真表示

### 背景・問題意識

ユーザーから 3 つの指摘:
1. 「『AWを追加』を押すと別画面に飛ぶけど、推した瞬間にしたからニュッと出てくる感じにしてほしい」
2. 「AWを今のものに有効にしてみたいんだけど、どうすれば？もしかしてその動線がない？」
3. 「グッズ登録で、登録したものが在庫一覧に乗ると思うけど、ちゃんと画像が表示されるようにしてほしい」

### 変更内容

#### A. AW チューザーを slide-up ボトムシート化

**`web/src/app/aw/AWView.tsx`**

- 「AWを追加」ボタンを `<Link href="/aw/new">` から `<button onClick={setIsAddOpen(true)}>` に変更
- `AWAddSheet` コンポーネントを内部に追加（AWAddEntry の内容を再描画）
- アニメーション:
  - backdrop: opacity 0 → 1（200ms）
  - sheet: translate-y-full → translate-y-0（300ms cubic-bezier(0.32, 0.72, 0, 1)）
- マウント制御: open 時即マウント、close 時 350ms 待ってアンマウント
- ESC キーで閉じる、body スクロールロック、aria-modal/role=dialog で a11y 対応
- シート内の「場所から作る」「イベントから埋める」は引き続き Link で別ルートへ遷移
- `/aw/new` ルート自体は残す（直接 URL アクセス時のフォールバック）

#### B. 「今すぐ開始」アクション

**`web/src/app/aw/actions.ts`**

`activateAWNow(id)` server action 追加:
- 元 AW の duration（end_at - start_at）を計算
- 安全範囲外（5 分未満 or 24h 超）は強制的に 2h
- 現在時刻を 1 分単位に丸めた値を新 start_at に
- new_end = new_start + duration
- status を `'enabled'` にもセット（disabled だった場合も復帰）

**`web/src/app/aw/AWView.tsx`**

SCHEDULED（enabled but not yet started）の AW カードに「今すぐ開始」ボタン追加:
- 紫グラデ背景の prominent ボタン
- クリックで `activateAWNow` → router.refresh() → 該当 AW が ACTIVE NOW セクションに移動
- 既存の「一時無効」「再有効化」ボタンは維持

#### C. 在庫一覧で写真を表示

**`web/src/app/inventory/page.tsx`**

- SELECT に `photo_urls` を追加（`text[]` カラム、すでに DB にあるが取得していなかった）
- `InventoryRow` 型に `photo_urls` 追加
- map 時に `photoUrl: r.photo_urls[0] ?? null` をセット

**`web/src/app/inventory/ItemCard.tsx`**

- `ItemCardData` に `photoUrl?: string | null` 追加
- 写真がある時:
  - 背景を `#3a324a`（dark）に
  - `<img>` でフルブリード `object-cover` 表示
  - メンバー名プレートを白文字 + 黒 backdrop-blur に
  - イニシャル文字（中央大）を非表示
- 写真がない時: 従来通りの縞模様カード

(Storage バケットは iter59 の migration で `public: true` 設定済、SELECT policy も「Anyone can view」なので URL アクセス OK)

### 確認方法

1. `/aw` で「AWを追加」 → シートが下からスッと出る
2. 「キャンセル」or backdrop タップ → スッと下に消える
3. SCHEDULED の AW カード → 「今すぐ開始」 → ACTIVE NOW に移動
4. `/inventory/new` で写真撮影 → 保存
5. `/inventory` 一覧 → 撮影した写真がカード全面に表示される

### 関連ファイル

- `web/src/app/aw/AWView.tsx`（再実装、AWAddSheet 追加）
- `web/src/app/aw/actions.ts`（activateAWNow 追加）
- `web/src/app/inventory/page.tsx`（photo_urls fetch）
- `web/src/app/inventory/ItemCard.tsx`（photo 表示）

### セルフレビュー（CLAUDE.md absolute rule C）

- **A. デザイン整合性**: AWAddEntry の内容は維持しつつアニメーションだけ追加。「今すぐ開始」は紫グラデ統一 ✅
- **B. 仕様整合性**: status 'enabled'/'disabled' 整合、duration 維持ロジック ✅
- **C. レビュー記録**: シートと旧 `/aw/new` ルート両立、安全範囲外 duration の fallback を実装 ✅

---

## イテレーション61.5：AW 編集に本物の地図を統合（Leaflet + OpenStreetMap + Geolocation + Nominatim）

### 背景・問題意識

iter61 で AW 編集 3 画面を実装したが、地図部分は SVG プレースホルダだった。ユーザーから「めっちゃ側だけつくってるやん。位置から指定する時、ちゃんとリアルの地図を呼び出す感じにしてよ。位置情報をユーザーから取得してさ。」と指摘され、本物の地図機能を実装。

### 技術選定

- **地図ライブラリ**: Leaflet + OpenStreetMap タイル
  - 無料・APIキー不要・MVP 向き（Mapbox は無料枠あるが将来課金リスク）
  - `react-leaflet` で React 統合
- **ジオコーディング**: Nominatim (OSM 公式)
  - 無料・APIキー不要
  - 1 req/sec 制限・User-Agent 必須
  - サーバー API ルート (`/api/geocode`) で proxy（CORS / User-Agent 付与）
- **位置情報取得**: Browser Geolocation API（標準）

### 変更内容

#### `web/src/app/api/geocode/route.ts`（新規）

- Nominatim プロキシ API
- `?q=横浜アリーナ` → forward geocoding
- `?lat=35.5&lon=139.7` → reverse geocoding
- User-Agent: `Megrum/0.1 (https://megrum.tokyo; support@megrum.tokyo)`
- `next: { revalidate: 3600 }` で 1 時間キャッシュ

#### `web/src/components/map/MapPicker.tsx`（新規）

- `react-leaflet` ベースの client-only コンポーネント
- OSM タイル + radius circle (lavender) + ドラッグ可能ピン (DivIcon)
- Megrum ブランドカラー (#a695d8) のカスタムピン
- center 変更を `onCenterChange(lat, lng)` で通知
- 地図クリック / ピンドラッグで center 更新

#### `web/src/app/aw/new/location/LocationLedForm.tsx`（再実装）

- SVG プレースホルダを完全廃棄、`MapPicker` を組み込み
- 初回ロード時に `navigator.geolocation.getCurrentPosition` で現在地取得（fallback: 渋谷駅）
- 検索バーは Nominatim API 経由で 350ms debounce → 結果ドロップダウン表示
- 結果クリックで地図中心移動 + 会場名自動入力
- ピン移動時に reverse geocoding で会場名候補を自動入力（ユーザー編集後は上書きしない）
- 「現在地を使う」ボタンで再度 Geolocation 呼び出し
- Geolocation エラー（permission denied 等）はトーストで表示

#### `web/src/app/aw/new/event/EventLedForm.tsx`

- SVG MiniMap を `MapPicker` に置き換え（180px 高さ）
- イベント選択時に Nominatim でその会場座標を自動取得
- 「現在地を使う」を機能化
- ピンドラッグ可能（同 venue 内の細かい場所調整用）

#### `web/src/app/aw/actions.ts`

- `saveAW` に `centerLat` / `centerLng` 引数追加
- バリデーション: 両方揃って範囲内（-90〜90, -180〜180）の時のみ保存
- `activity_windows.center_lat / center_lng` カラムに格納（既存 schema、iter61 マイグレーション）

#### `web/package.json`

- `leaflet@^1.9.4`, `react-leaflet@^5.0.0`, `@types/leaflet@^1.9.21` を追加

### 動作フロー

1. `/aw/new/location` 開く → 現在地取得トライ（fallback 渋谷駅）
2. 地図表示・ピン位置の reverse geocoding で会場名自動入力
3. ユーザーが検索 → Nominatim 結果リスト → クリックで pin 移動
4. ピンドラッグで微調整可
5. 半径スライダーで radius circle がリアルタイム更新
6. 「有効化」で `saveAW({centerLat, centerLng, ...})` 実行 → DB に座標保存

### 影響範囲

- `/aw/new/location`: 完全に本物地図に
- `/aw/new/event`: MiniMap 部分のみ本物地図に
- `/api/geocode`: 新規 API ルート
- `activity_windows.center_lat/lng` に座標が保存されるので、iter63（マッチングロジック）で時空交差計算に直接利用可能になった

### Nominatim 利用ポリシー遵守

- `User-Agent` ヘッダ必須 → サーバー側で付与
- 1 req/sec 上限 → ブラウザ debounce 350ms + サーバーキャッシュ 1h
- 商用利用増加時は別ホスト（Stadia Maps / MapTiler）への切替を検討

### 確認方法

1. `npm run dev` で http://localhost:3000/aw/new/location
2. 初回: ブラウザの位置情報ダイアログ → 許可 / 拒否どちらでも fallback
3. 検索: 「横浜アリーナ」入力 → ドロップダウン → クリックで pin 移動
4. ピンドラッグ: venue 名が reverse geocoding で更新
5. 「有効化」→ DB 確認: `select venue, center_lat, center_lng from activity_windows;`

### 関連ファイル

- `web/src/app/api/geocode/route.ts`（新規）
- `web/src/components/map/MapPicker.tsx`（新規）
- `web/src/app/aw/new/location/LocationLedForm.tsx`（再実装）
- `web/src/app/aw/new/event/EventLedForm.tsx`（部分更新）
- `web/src/app/aw/actions.ts`（saveAW 拡張）
- `web/package.json`（依存追加）

### セルフレビュー（CLAUDE.md absolute rule C 適用）

- **A. デザイン整合性**: モックアップは静的 SVG 地図、本実装は Leaflet+OSM。ピンの色・形状・shadow はモックアップに合わせる ✅
- **B. 仕様整合性**: `activity_windows` の `center_lat / center_lng` カラムを利用、saveAW のバリデーション追加 ✅
- **C. レビュー記録**: Nominatim 制限 / 商用ホスト切替の note を上記に記録 ✅

---

## イテレーション61：AW（合流可能枠）画面 — 一覧 + 編集 3 画面 ピクセル準拠実装

### 背景・問題意識

iter58〜60 で「ホーム / 在庫 / wish」を実装後、ユーザーから「全然デザイン案通りじゃないんだけど。ちゃんとデザインをみて、あと仕様？ちゃんと前に話して整理してルカらそれ通りにして」という強いフィードバック。CLAUDE.md に **「画面実装時の絶対ルール」** を追加し、(1) 着手前にデザイン精読 (2) 共通ルール遵守 (3) 着手後セルフレビュー — を必ず踏むように。

iter61 は AW 編集 3 画面（list / new chooser / new/location / new/event）をモックアップ aw-edit.jsx 完全準拠で再実装する iter。

### 変更内容

#### `web/src/app/aw/AWView.tsx`（一覧画面・iter61 前半 d50a29a で完了済）

- AWListScreen (line 19-114) 完全準拠で再実装
- ACTIVE NOW（pulse dot + LIVE badge）/ SCHEDULED / 自動アーカイブ の 3 セクション
- AWCard: gradient bg + counter row（完全マッチ 14 / 打診中 2 / クローズまで N分）+ 3-action row（一時無効・編集・X告知）
- 不足していた `hand` icon 追加（meta rows）
- shadow-[0_8px_20px_rgba(166,149,216,0.15)] / text-[15.5px] / tracking-[0.3px] などピクセル値完全一致

#### `web/src/app/aw/new/page.tsx` + `AWAddEntry.tsx`（チューザー）

- モックアップ AWAddEntry (1078-1237) 準拠
- 暗転バックドロップ + ボトムシート（rounded-t-22 / shadow 0 -10px 40px）
- 「📍 場所から作る」（おすすめバッジ・gradient bg・1.5px lavender border）→ /aw/new/location
- 「🎤 イベントから埋める」（ショートカットバッジ・白bg）→ /aw/new/event
- 「キャンセル」→ /aw

#### `web/src/app/aw/new/location/page.tsx` + `LocationLedForm.tsx`

- モックアップ AWEditLocationLed (693-998) 準拠
- 上部 360px の地図プレースホルダ（SVG ハッチ + 道路 + 半径200円 + ピン + 半径バブル + キャッシュバッジ）
- 検索バーは実 input（venue 入力）として動作
- ボトムシート: prominent radius slider（22px gradient bg）+ events nearby（イベントなしデフォルト + mock 3件）+ 有効時間 chips + 終了時刻ストリップ + 詳細編集（datetime-local 拡張）+ Express/動けますトグル
- CTA「有効化 — 時空交差を再計算」

#### `web/src/app/aw/new/event/page.tsx` + `EventLedForm.tsx`

- モックアップ AWEditEventLed (276-571) 準拠
- SheetHeader（× / 登録中 / クリア + タイトル）
- イベント picker: 選択済みは LUMENA-style カード（4/27 dateChip + マスタ登録済 pill + 変更 button）、未選択時は mock 3件 + 自由入力
- 位置と範囲: MiniMap + 半径スライダー
- 時間ウィンドウ: タブ（プリセット / 手動調整 / いま）+ 4 つのプリセットカード（開演前後30分推奨など、選択イベントから動的計算）
- 現地交換の希望: マルチ選択チェックボックス 4 種
- 運用オプション: Express toggle + クローズ時間 chips
- CTA「X告知も」+「保存して有効化」

### 影響範囲

- `/aw` 一覧画面のすべて
- `/aw/new` チューザー（旧シンプル form を完全置換）
- `/aw/new/location`, `/aw/new/event` 新規ルート
- `BottomNav.tsx` の AW タブ → `/aw` で正しく動作（iter60 で配線済）
- データ保存: 既存 `saveAW` server action 利用（venue / event_name / eventless / start_at / end_at / radius_m / note）

### 既知の差分（mockup と機能の差）

| 項目 | mockup | 実装 | 理由 |
|---|---|---|---|
| イベント master | 4/27 LUMENA など固定値 | mock 3件 + 自由入力フォールバック | events table 未実装、後続 iter で master 化 |
| 地図 | 静的 SVG | 静的 SVG（同じ） | OSM/Mapbox 連携は後続 |
| 「現在地を使う」「ピン調整」 | 動作 | UI のみ | Geolocation API 連携は後続 |
| 「X告知も」 | 動作 | UI のみ | X (Twitter) 連携は後続 |
| 「詳細編集」 | なし | datetime-local 2 個追加 | chips のみだと細かな時間調整不可、機能性最優先 |

### 確認方法

1. `npm run dev` で http://localhost:3000/aw を開く
2. 右上「AWを追加」→ チューザー（暗転 + ボトムシート）
3. 「📍 場所から作る」→ 地図 + ボトムシート → 「有効化」で /aw に戻る
4. 「🎤 イベントから埋める」→ イベント picker + 位置 + 時間 + 希望 + オプション → 「保存して有効化」

### 関連ファイル

- `Megrum/aw-edit.jsx`（モックアップ）
- `web/src/app/aw/AWView.tsx`
- `web/src/app/aw/new/{page.tsx, AWAddEntry.tsx}`
- `web/src/app/aw/new/location/{page.tsx, LocationLedForm.tsx}`
- `web/src/app/aw/new/event/{page.tsx, EventLedForm.tsx}`
- `web/src/app/aw/actions.ts`（saveAW）
- `supabase/migrations/20260502120000_add_activity_windows.sql`

### セルフレビュー（CLAUDE.md absolute rule C 適用）

- **A. デザイン整合性**: モックアップの 3 関数すべて構造・カラー・ピクセル値合致を逐一確認 ✅
- **B. 仕様整合性**: activity_windows table のすべての列を埋める。enabled status 初期値で公開。RLS は既存 ✅
- **C. レビュー記録**: 既知差分を上記表に明記。後続 iter で解消する項目を todo 化済 ✅

---

## イテレーション57：Phase 0b-3 — Onboarding 5 画面 + 推し/メンバー追加リクエスト共有 + 速度最適化

### 達成事項

iter56 で認証系 UI を仕上げた直後、Onboarding（プロフィール設定）の 5 画面を一気に実装。同時に「マスタに無い推し / メンバーをユーザーが追加リクエストできる」仕組みを構築し、**運営承認時には全選択ユーザーに自動反映される設計**を採用。並行して Vercel リージョン変更・Server Action 高速化・ブランドカラー Tailwind 統合などの基盤強化も実施。**Phase 0b 完全完了**。

### サブセクション

#### A. UI / UX 補完（iter56 の延長）

1. **ボタン挙動 4 種統合**（PrimaryButton, secondaryBaseClass）
   - active:scale-[0.97]（押下時にキュッと縮小）
   - Ripple エフェクト（クリック位置から白い円が広がる）
   - pending 中スピナー（テキスト横で animate-spin）
   - hover:brightness-105 / disabled:opacity-50
2. **ブランドカラーを Tailwind theme に統合**
   - `globals.css` の `@theme`（inline でない）に `--color-megrum-lavender/sky/pink/warn/ok` を追加
   - 全コンポーネントで `bg-megrum-lavender` 等が使えるように
   - opacity 修飾子（`/35` 等）も `color-mix()` で動作
3. **ボタン色合い・サイズをモックアップ完全一致**
   - 旧：`bg-gradient-to-r from-purple-400 to-pink-300`（2色 90deg） → 誤
   - 新：`bg-[linear-gradient(135deg,#a695d8,#a8d4e6)]`（2色 135deg）← モックアップ AOPrimaryButton 準拠
   - rounded-[14px] / py-[14px] / text-sm / shadow-[0_4px_14px_rgba(166,149,216,0.33)]
4. **MegrumLogo（モックアップ AOLogo 準拠）**
   - 角丸正方形（borderRadius: size×0.32）
   - 「Mg」テキスト + Inter Tight 800
   - 2色グラデ（lavender → sky）
   - boxShadow: `0 8px 24px rgba(166,149,216,0.25)`
5. **全画面の背景グラデを再現**
   - Welcome / EmailConfirmed: `linear-gradient(180deg, #a695d822 0%, #a8d4e614 45%, #ffffff 100%)`
   - Signup / Login / VerifyEmail / PasswordReset: `#fbf9fc` 単色
6. **未認証ユーザーの再 signup 対応（iter56 続き）**
   - signup actions で「既存メアド + 未認証」の場合 admin API で削除 → 再登録可

#### B. 速度最適化

1. **Vercel region: `iad1` → `hnd1`（東京）**
   - vercel.json に `"regions": ["hnd1"]`
   - Supabase（東京）との RTT が 200-300ms → 5-10ms に
   - Server Action 全体が大幅高速化
2. **Server Action から redirect を排除**
   - 旧：`redirect("/onboarding/oshi")` → サーバーで次画面 full render してから返す（重い）
   - 新：`return undefined` だけ → Client 側で `router.push()` + `router.prefetch()`
   - 体感 1〜2 秒 → 200〜400ms
3. **revalidatePath で server invalidate**
   - 各 action 末尾で `revalidatePath("/path")`
   - `router.refresh()` 不要に
4. **DB クエリの並列化（Promise.all）**
   - `/onboarding/oshi`、`/onboarding/members`、`/onboarding/done` で 3〜4 クエリを並列実行
   - 4×RTT → 1×RTT

#### C. Onboarding 5 画面（モックアップ AOOnboard\*）

1. **`/onboarding/gender`** （1/4 性別選択）
   - 4 選択肢：女性 / 男性 / その他 / 回答しない
   - users.gender 更新 + account_status='onboarding' に遷移
2. **`/onboarding/oshi`** （2/4 推し選択）
   - groups_master + genres_master をジャンル横断で取得
   - ジャンルチップ（すべて / K-POP / 邦アイ / 2.5次元 / アニメ / ゲーム）
   - 検索（name + aliases）
   - 複数選択可
   - 「人気」バッジ（各ジャンル display_order 上位5件）
3. **`/onboarding/members`** （3/4 メンバー選択）
   - ユーザーの推しグループごとにセクション
   - 「箱推し」chip + 個別メンバー chip（複数選択可）
   - 既存 user_oshi の kind / character_id から initialSelections を構築
4. **`/onboarding/area`** （4/4 活動エリア）
   - 8 エリアチップ（東京/神奈川/千葉/埼玉/大阪/愛知/福岡/その他）複数選択可
   - 「あとで設定する」スキップ可
   - account_status='active' に遷移（onboarding 完了）
5. **`/onboarding/done`** （完了サマリー）
   - グラデ背景 + ✨ + 「Megrum へようこそ！」+ @handle
   - 推し最大 3 件のサマリー + エリア表示
   - 「次は何をする？」3 カード（マッチ / 在庫 / wish）
   - 「ホームに進む」

#### D. 推し追加リクエスト機能（共有可）

1. **oshi_requests テーブル新規**（migration `20260501100000_add_oshi_requests.sql`）
   - 主要カラム: requested_name, requested_genre_id, requested_kind, note
   - status: `pending` / `merged`（既存master統合）/ `approved`（新規追加）/ `rejected`
   - approved_group_id（承認時の紐付け先 master）
2. **`/onboarding/oshi/request`** 画面（名前 / ジャンル / 種類 / メモ）
3. **RLS 緩和**（migration `20260501110000_share_oshi_requests.sql`）
   - 「自分のだけ」→「誰でも全ステータス読める」
   - user_oshi に `oshi_request_id` カラム追加（nullable, FK）
   - check 制約: group_id / character_id / oshi_request_id のいずれか必須
4. **共有**：推し選択画面で全ユーザーの pending を「審査中」chip 表示・selectable
5. **承認トリガー** `handle_oshi_request_approval`
   - status pending → merged/approved 遷移時、approved_group_id がセット済なら：
     - リンクされている全 user_oshi の group_id を一括 UPDATE
     - 紐づく character_requests も同様に更新（後述 E.6）
   - rejected 時：リンクされた user_oshi を全削除

#### E. メンバー追加リクエスト機能（共有可）

1. **character_requests テーブル新規**（migration `20260501130000_add_character_requests.sql`）
   - group_id（必須・どのグループのメンバーか）, requested_name, note
   - status: `pending` / `merged` / `approved` / `rejected`
   - approved_character_id（承認時の紐付け先）
2. **`/onboarding/members/request`** 画面（クエリ groupId or oshiRequestId 必須）
3. **user_oshi に `character_request_id` カラム追加**
   - check 制約: group_id / character_id / oshi_request_id / character_request_id のいずれか必須
4. **共有**：メンバー選択画面で全ユーザーの pending を「🕐」chip 表示・selectable
5. **承認トリガー** `handle_character_request_approval`
   - 承認時：リンクされている全 user_oshi の character_id を一括 UPDATE
   - 却下時：リンクされた user_oshi を全削除
6. **連鎖対応**（migration `20260501140000_link_character_requests_to_oshi_requests.sql`）
   - character_requests に oshi_request_id 追加（審査中グループへのメンバーリクエスト対応）
   - check 制約: group_id か oshi_request_id のいずれか必須
   - oshi_request 承認時、紐づく character_requests も group_id に書き換え（連鎖変換）

#### F. データ seed

1. **K-POP 主要 5 グループ × 31 メンバー**（migration `20260501120000_seed_characters.sql`）
   - BTS（7）/ TWICE（9）/ NewJeans（5）/ IVE（6）/ aespa（4）
   - aliases に韓国語表記・英字・別名を含める

#### G. account_status 自動同期

1. **`/auth/callback` で email 認証完了時**
   - `exchangeCodeForSession` 成功後、`account_status='registered'` の場合に `'verified'` に UPDATE
   - `email_verified_at` に現在時刻
2. **遷移ロジック完成**
   ```
   registered（signup 直後）
     ↓ メール認証
   verified
     ↓ saveGender
   onboarding
     ↓ saveArea（or スキップ）
   active
   ```

#### H. パスワードリセット完了画面

1. **`/auth/password-reset-confirm`** 新規
   - searchParams.code を `exchangeCodeForSession` で session 化
   - 新パスワード入力フォーム（強度メーター + 確認）
   - 完了後 `/login?password_reset=success`
2. **`setNewPassword` action**：`updateUser({ password })`
3. **`/login`** で `?password_reset=success` バッジ表示

#### I. Google OAuth 接続（コードのみ・要 Cloud Console 設定）

1. **trigger 改修**（migration `20260501150000_oauth_handle_generation.sql`）
   - handle が無い場合 `user_xxxxxxxx` 形式でランダム生成（衝突回避ループ）
   - display_name は Google プロフィール（full_name / name）→ handle の順 fallback
   - email_confirmed_at がある（OAuth）なら account_status='verified'
2. **`signInWithGoogle` action**：`signInWithOAuth({ provider: 'google' })`
3. **`GoogleAuthButton`** 共通コンポーネント（Welcome / Login で再利用）
4. **未完了**：Google Cloud Console プロジェクト作成と Supabase Dashboard での Provider 有効化（ユーザー作業）

#### J. Email Templates 日本語化（手動設定）

1. **`notes/19_email_templates.md`** に整備
2. Confirm signup / Reset password の HTML テンプレ全文（Megrum ブランド準拠）
3. 設定済（ユーザーが Supabase Dashboard でコピペ完了）

### 設計判断・トレードオフ

1. **handle 自動生成 vs 入力必須**
   - iter56 では signup 時に handle 入力必須にした（モックアップ準拠）
   - Google OAuth では handle が取れないので、trigger で `user_xxxxxxxx` 自動生成
   - 後で Phase 1 にハンドル変更画面を追加する前提
2. **追加リクエストの公開範囲**
   - 自分の申請のみ表示 vs 全ユーザー pending 表示
   - 後者を採用：同じ推しを複数人がリクエストする無駄を避け、「審査中」共有でコミュニティ感を出す
3. **メンバーリクエストの親グループ**
   - 既存 master のみ vs 審査中グループも対応
   - 後者を採用：「LUMENA」未承認時もそのメンバー「スア」をリクエスト可能、連鎖変換で承認時一括反映
4. **proxy での onboarding 未完了強制リダイレクト**
   - 今は実装しない：保護対象ページ（/home, /inventory）が未実装のため
   - Phase 1 で実装

### 関連ファイル

**新規 migration**:
- `supabase/migrations/20260501100000_add_oshi_requests.sql`
- `supabase/migrations/20260501110000_share_oshi_requests.sql`
- `supabase/migrations/20260501120000_seed_characters.sql`
- `supabase/migrations/20260501130000_add_character_requests.sql`
- `supabase/migrations/20260501140000_link_character_requests_to_oshi_requests.sql`
- `supabase/migrations/20260501150000_oauth_handle_generation.sql`

**新規ページ**:
- `web/src/app/onboarding/{gender,oshi,members,area,done}/`
- `web/src/app/onboarding/{oshi,members}/request/`
- `web/src/app/auth/password-reset-confirm/`

**新規コンポーネント**:
- `web/src/components/auth/PrimaryButton.tsx`（PrimaryButton + PrimaryLinkButton + secondaryBaseClass）
- `web/src/components/auth/Spinner.tsx`
- `web/src/components/auth/useRipple.tsx`
- `web/src/components/auth/ProgressDots.tsx`
- `web/src/components/auth/GoogleAuthButton.tsx`

**新規 actions**:
- `web/src/app/onboarding/actions.ts`（saveGender / saveOshi / saveOshiRequest / saveMembers / saveCharacterRequest / saveArea）
- `web/src/app/auth/actions.ts` に `signInWithGoogle` / `setNewPassword` 追加

**改修**:
- `web/src/app/page.tsx`（Welcome ビューを root に統合 + GoogleAuthButton）
- `web/src/app/login/`（モックアップ準拠 + Google ボタン）
- `web/src/app/auth/callback/route.ts`（account_status sync）
- `web/src/app/globals.css`（Tailwind theme + Ripple keyframe）
- `web/vercel.json`（regions hnd1）
- `web/src/app/layout.tsx`（Inter Tight フォント追加）

**ドキュメント**:
- `notes/19_email_templates.md`

### Phase 0b 完了報告

```
✅ Phase 0a:    Vercel + Supabase 接続（iter49-51）
✅ Phase 0b-1:  DB マイグレーション（iter52）
✅ Phase 0b-2:  Auth 実装 + メール送信基盤（iter53-55）
✅ Phase 0b-3:  認証 UI 完成 + Onboarding 5画面 + 共有リクエスト（iter56-57）
🔵 Phase 0c:    実機能（ホーム / 在庫管理 / wish / 打診 / 取引チャット）← 次
```

### 次の課題

- **Phase 0c 開始**：iter58 以降で実機能の実装
- ハンドル変更画面（OAuth ユーザー向け）
- Google OAuth の最終接続（ユーザー側で Cloud Console + Supabase 設定）
- proxy で onboarding 未完了強制リダイレクト（保護対象ができてから）
- データモデル変更を `notes/05_data_model.md` に反映
- 用語 `notes/10_glossary.md` に追加：「追加リクエスト」「審査中」「マージ」「連鎖変換」等
- 状態遷移 `notes/09_state_machines.md` に追加：oshi_requests / character_requests のステート

---

## イテレーション56：認証系 UI をモックアップ忠実化 + 構造バグ対応

### 達成事項

iter53-55 で動作する認証フローはあったが、UI が `auth-onboarding.jsx` のモックアップと乖離していた。本 iter で **AO* 全画面をモックアップ忠実に再実装**。並行して、iter53 で発覚した「未認証ユーザーが残ってハンドル占有 → 再登録不可」のデッドロック問題を解消。

### 背景・問題意識

iter55 完了時点での課題：
1. UI は最低限動くがモックアップとは見た目が違う（`bg-gradient-to-b from-purple-50 via-white to-pink-50` 一様、ヘッダーも仮）
2. signup 試行を繰り返すと `auth.users` に未認証レコードが残り、同じハンドル/メアドで再登録不可
3. 認証メールリンクが期限切れすると詰む（resend ボタンはあるが UI が貧弱）
4. パスワードリセット画面が未実装

### 変更内容

#### 共通コンポーネント（新規）

**`web/src/components/auth/HeaderBack.tsx`**
- モックアップ AOHeaderBack 準拠：sticky ヘッダー + 戻るアイコン + タイトル + サブ + 進捗
- 半透明 + backdrop-blur

**`web/src/components/auth/MegrumLogo.tsx`**
- モックアップ AOLogo 準拠：紫→水色→ピンクのグラデ円 + 星アイコン
- size プロパティで大小切り替え可

#### 画面実装（モックアップ忠実）

**`web/src/app/page.tsx`** — Welcome（AOWelcome）
- 未ログイン時：Megrum ロゴ大（88px）+ 「Megrum」+ 「グッズ交換を、現地で、もっと簡単に。」+ CTA 2 つ
- ログイン時：暫定ホーム（既存表示・Phase 1 で本実装予定）
- 「メールアドレスで新規登録」+ 「Googleで新規登録」（disabled）+ 「すでにアカウントをお持ちの方は ログイン」

**`web/src/app/signup/SignUpForm.tsx`** — Signup（AOSignup）
- 表示名フィールド削除（display_name は handle で初期化）
- ハンドル名（@プレフィックス + 「後から変更可能」ヒント）
- パスワード強度メーター（4本バー + ラベル「弱い/普通/強い/最強」）
- パスワード確認（リアルタイム一致チェック、ボーダー赤化）
- 利用規約・プライバシーポリシーチェックボックス
- 「次へ」ボタン

**`web/src/app/auth/verify-email/page.tsx`** — VerifyEmail（AOEmailSent）
- ヘッダー：「メール認証」、戻る先 `/signup`
- 紫＆水色グラデの丸 + メールアイコン
- 「確認メールを送りました」（過去形・モックアップ準拠）
- メアド表示（白枠で囲む）
- ピンク背景の注意書き「📧 メールが届かない場合 / 迷惑メールフォルダ・再送・別メアドを試す」
- 60秒クールダウン付き再送ボタン（`ResendButton` で initialCooldown 受け取り）
- 「メールアドレスを変更する」リンク
- `?resent=1` クエリで「✓ 確認メールを再送しました」表示

**`web/src/app/auth/email-confirmed/page.tsx`**（新規） — EmailConfirmed（AOEmailConfirmed）
- 中央：紫→水色グラデの円（96px）+ 大きいチェックマーク + 影
- 「認証完了！」
- 「プロフィール設定へ進む」 → `/onboarding/gender`（iter57 で実装）
- onboarding 完了済（gender 設定済）ユーザーが来たら `/` へ自動転送

**`web/src/app/login/page.tsx` + `LoginForm.tsx`** — Login（AOLogin）
- ヘッダー：「ログイン」
- Megrum ロゴ小（60px）+ 「おかえりなさい」
- メアド + パスワード入力
- 「パスワードを忘れた方」リンク（右寄せ・小）
- 「ログイン」ボタン
- 「または」divider + 「Googleでログイン」（disabled）
- 「アカウントをお持ちでない方は 新規登録」

**`web/src/app/password-reset/page.tsx` + `ResetForm.tsx`**（新規） — PasswordReset（AOPasswordReset）
- ヘッダー：「パスワードリセット」、戻る先 `/login`
- 「パスワードを再設定します」+ 説明
- メアド入力 → `resetPasswordForEmail` → `/auth/verify-email?purpose=reset`

#### 構造バグ対応：actions.ts

**signup の既存メアド + 未認証ユーザーへの対応**：
```
signup() で signUp が "already registered" エラー
  ↓
resend({type: "signup"}) を試行
  ├ 成功 = 未認証 → /auth/verify-email?resent=1 へ転送
  └ 失敗 = 認証済 → 「既に登録済み、ログインしてください」エラー
```

これで iter53 のデッドロック（同じメアド/ハンドルで再 signup できない）を解消。

**`passwordReset` 関数追加**：
- `resetPasswordForEmail` を呼んで `/auth/verify-email?purpose=reset` に遷移
- rate limit エラーの日本語化

#### callback route.ts

- `next` パラメータのデフォルトを `/` から `/auth/email-confirmed` に変更
- 認証直後は EmailConfirmed → Onboarding 入口、onboarding 済なら自動的に `/` へ

### 影響範囲

- 既存 signup フォームと挙動が変わる：display_name フィールド消滅、パスワード確認必須
- 既存 login フォーム見た目が変わる
- メール認証完了時の遷移先：`/` → `/auth/email-confirmed`（新中継ページ）
- 暫定ホーム画面はログイン時のみ表示

### 確認方法

1. シークレットウィンドウで https://megrum.tokyo/ → Welcome 表示
2. https://megrum.tokyo/signup → ハンドル + パス強度メーター + パス確認 動作確認
3. https://megrum.tokyo/login → 「パスワードを忘れた方」リンク存在確認
4. https://megrum.tokyo/password-reset → 「パスワードを再設定します」表示
5. signup 試行を 2回（同じメアドで）→ 2回目は「✓ 確認メールを再送しました」で verify-email に着地

### 関連ファイル

新規:
- `web/src/components/auth/HeaderBack.tsx`
- `web/src/components/auth/MegrumLogo.tsx`
- `web/src/app/auth/email-confirmed/page.tsx`
- `web/src/app/password-reset/page.tsx`
- `web/src/app/password-reset/ResetForm.tsx`

改修:
- `web/src/app/page.tsx`（Welcome ビュー追加）
- `web/src/app/signup/page.tsx`
- `web/src/app/signup/SignUpForm.tsx`
- `web/src/app/login/page.tsx`
- `web/src/app/login/LoginForm.tsx`
- `web/src/app/auth/verify-email/page.tsx`
- `web/src/app/auth/verify-email/ResendButton.tsx`
- `web/src/app/auth/callback/route.ts`
- `web/src/app/auth/actions.ts`

### 次の課題（iter57）

- Onboarding 5画面実装（Gender / Oshi / Member / Area / Done）
- proxy で onboarding 未完了 → 強制リダイレクト
- account_status sync DB trigger（confirm で verified、profile 完成で onboarded）
- パスワードリセット完了画面（/auth/password-reset-confirm）
- Google OAuth 接続（後回し）

---

## イテレーション55：Brevo SMTP セットアップ完了 + Phase 0b-2 認証フロー全動作確認

### 達成事項

iter53 の Auth フロー実装＋ iter54 のフォールバック対応を経て、本 iter で **メール送信の本番運用基盤（Brevo）を構築し、認証フローが Megrum.tokyo 上で end-to-end で動作することを確認**。Phase 0b-2 を完全完了。

### 背景・問題意識

iter53 直後に発生した問題：
- Supabase 組み込み SMTP のレート制限（1時間3〜4通）に即詰まる
- `email rate limit exceeded` で開発・テスト不可
- 本番リリース前にカスタム SMTP 必須

検討した選択肢：
| 選択肢 | 結論 |
|---|---|
| Firebase Auth に戻す | ❌ Supabase RLS / Postgres 設計を全捨てになる |
| AWS SES | △ コスパ最強（$0.10/1000通）だがサンドボックス解除など設定複雑 |
| **Brevo（旧 Sendinblue）** | ⭐ 永続無料 300/日 / 設定簡単 / Supabase 公式手順あり |
| Resend | △ 100/日（Brevo の1/3） |
| ZeptoMail | △ 設定難易度中 |

→ **Brevo 採用**（MVP 期は無料で運用可、スケール時は AWS SES へ移行）

### 作業内容

#### A. Brevo アカウント設定
- 既存アカウント（前プロジェクト Bubble.io 用）に Megrum 用 SMTP Key を追加発行
- SMTP Key 名前：`Megrum Production`（Standard variant・64文字）

#### B. ドメイン認証（DKIM/SPF/DMARC）
- お名前.com の DNS 管理画面で 4 レコード追加：

| Type | Name | Value | 用途 |
|---|---|---|---|
| TXT | （空欄）| `brevo-code:b948bda79e385f2a3935fadb98f04ca7` | ドメイン所有確認 |
| CNAME | `brevo1._domainkey` | `b1.megrum-tokyo.dkim.brevo.com` | DKIM 1 |
| CNAME | `brevo2._domainkey` | `b2.megrum-tokyo.dkim.brevo.com` | DKIM 2 |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:rua@dmarc.brevo.com` | DMARC |

→ Brevo の Authentication 完了

#### C. Supabase に SMTP 接続情報を設定
- Auth → SMTP Settings → Enable Custom SMTP: ON
- Host: `smtp-relay.brevo.com`
- Port: `587`
- Username: Brevo の SMTP Login（`7b1d8e001@smtp-brevo.com`）
- Password: Brevo SMTP Key
- Sender email: **`support@megrum.tokyo`**
- Sender name: **`Megrum`**

#### D. Brevo IP blocking の解除
- Supabase Cloud（AWS 東京 `13.113.119.158` 等）が Brevo の Authorized IPs に含まれず、初回送信時に保留＋本人確認メールが飛ぶ事象が発生
- **Brevo Security → Authorized IPs → SMTP keys → Deactivate for SMTP** を実施
- 理由：Supabase Cloud は IP が変動するため個別認証は運用負担大／SMTP Key 厳重管理でセキュリティ担保

#### E. End-to-end テスト成功
- signup（Gmail エイリアス使用）
- メール `Megrum <support@megrum.tokyo>` から到着
- 「Confirm your mail」リンク → `/auth/callback` で `exchangeCodeForSession` 成功
- ホーム画面に「ログイン中 / ましま / @mashima / ログアウト」表示
- iter54 のフォールバック（root に code が来た時の `/auth/callback` 転送）も正常動作

### 影響範囲

- 本番ドメイン `megrum.tokyo` から正規メール送信可能（DKIM/SPF/DMARC 完備）
- 配信成功率：DKIM 認証済みのため Gmail/Yahoo 等での迷惑メール判定回避
- 永続無料 300/日 → MVP 期は完全無料で運用可
- スケール時の AWS SES 移行は SMTP credentials 差し替えのみ（DKIM/SPF レコードは流用可能）

### Phase 0b-2 完了報告

```
✅ Phase 0a:    Vercel + Supabase 接続（iter49-51）
✅ Phase 0b-1:  DB マイグレーション（iter52）
✅ Phase 0b-2:  Auth 実装 + メール送信基盤（iter53-55）
🔵 Phase 0b-3:  Onboarding 実装（次）
```

### 関連ファイル

- 設定（コード変更なし）
- `notes/08_design_iterations.md`（本 iter 追記）

### 次の課題（メモ）

- 認証メールのテンプレート日本語化（Supabase Auth → Email Templates）
- Phase 0b-3：Onboarding（性別 / 推し / AW 初期）UI + Server Actions
- Phase 0c：本登録時の `users.account_status` を `registered` → `verified` に同期する DB トリガー追加

---

## イテレーション54：認証メール `/?code=xxx` フォールバック対応

### 背景・問題意識

iter53 で Auth フロー実装後、`Confirm your mail` メールリンクをクリックすると以下のような URL に飛んでしまう事象が発生：

```
❌ https://megrum.tokyo/?code=9961e53b-2a89-41bf-b972-d156d3e97f73
```

期待していた挙動：
```
✅ https://megrum.tokyo/auth/callback?code=xxx
```

ルート (`/`) は `page.tsx` がレンダリングされるだけで code 処理ロジックがないため、**確認コードが検証されないままトップページが表示され、ユーザーは認証完了状態にならない**。

### 原因

Supabase Auth の Redirect URLs allowlist 未設定／設定遅延／メールテンプレ古版／www サブドメイン経由など、本番環境で `redirect_to` が想定外の値になるケースが複数存在する。

ユーザー側の Supabase URL Configuration は本 iter 時点で正しく設定済（Site URL=`https://megrum.tokyo`、Redirect URLs に 3 つの `/auth/callback` を登録）だが、**設定変更前に送信された確認メールには古い fallback URL が焼き込まれている**ため、過去メールでの認証は失敗する。

### 変更内容

#### `web/src/app/page.tsx`
- `searchParams` を Props で受け取り、`code` クエリ検出時に `/auth/callback?code=xxx` へサーバーサイドリダイレクト
- `error` クエリ検出時には `/auth/auth-error?error=xxx&error_code=xxx&error_description=xxx` へリダイレクト
- 既存のログイン状態判定ロジックは維持

```typescript
type Props = {
  searchParams: Promise<{
    code?: string;
    error?: string;
    error_code?: string;
    error_description?: string;
  }>;
};

export default async function Home({ searchParams }: Props) {
  const params = await searchParams;
  if (params.code) {
    redirect(`/auth/callback?code=${params.code}`);
  }
  if (params.error) {
    const errorParams = new URLSearchParams({
      error: params.error,
      ...(params.error_code && { error_code: params.error_code }),
      ...(params.error_description && { error_description: params.error_description }),
    });
    redirect(`/auth/auth-error?${errorParams.toString()}`);
  }
  // ... 既存のログイン状態判定
}
```

### 効果

- メールが古い設定状態で送信されていても、root に飛んできた認証コードを `/auth/callback` で正しく検証できる
- Supabase 側の設定漏れに対する保険として恒常的に機能（ローカル開発・別ドメイン経由など）
- 認証エラー（`?error=access_denied&error_code=otp_expired` など）も `/auth/auth-error` に正しく誘導される

### 確認方法

1. `npm run build` でビルド成功（6 routes 不変）
2. Vercel 再デプロイ後、新たに signup → 受信メールリンクをクリック
3. `/auth/callback` または root → `/auth/callback` 転送経由でログイン状態に到達

### 関連ファイル

- `web/src/app/page.tsx`（修正）
- `web/src/app/auth/callback/route.ts`（既存・修正なし）
- `web/src/app/auth/auth-error/page.tsx`（既存・修正なし）

---

## イテレーション53：Phase 0b-2 — Auth フロー実装（signup / login / logout）

### 達成事項

iter52 で DB マイグレーション完了 → 本 iter で **認証フロー UI + Server Actions** を実装。
ユーザーが自分でアカウント作成・ログインできる状態に到達。

### 作業内容

#### Server Actions（`web/src/app/auth/actions.ts`）
- `signup(formData)`：メアド + PW + handle + 表示名で登録、確認メール送信、`/auth/verify-email` へ
- `login(formData)`：メアド + PW でログイン、`/` へ
- `logout()`：セッション削除、`/login` へ
- `resendVerification(formData)`：認証メール再送

バリデーション:
- email: `@` 含むこと
- password: 8文字以上
- handle: `^[a-z0-9_]{3,20}$` 正規表現（DBの CHECK 制約と一致）
- display_name: 1〜50文字
- accepted_terms: 必須（規約同意）

ハンドル重複チェック: 事前に `public.users` を select で確認。

#### Auth Callback（`web/src/app/auth/callback/route.ts`）
- メール認証リンクから `/auth/callback?code=xxx` でアクセス
- `exchangeCodeForSession(code)` で session に交換
- 認証成功 → `/` へ、失敗 → `/auth/auth-error` へ

#### UI ページ
- `web/src/app/signup/page.tsx` + `SignUpForm.tsx`
- `web/src/app/login/page.tsx` + `LoginForm.tsx`
- `web/src/app/auth/verify-email/page.tsx` + `ResendButton.tsx`
- `web/src/app/auth/auth-error/page.tsx`

すべて Server Component（既ログインなら `/` へリダイレクト）+ Client Component フォーム（フォーム状態管理）。

Megrum ブランドカラー（紫→ピンクグラデ）+ Noto Sans JP 統一。

#### `web/src/app/page.tsx` 更新
- ログイン状態を Server Component で取得
- ログイン中：「ようこそ {display_name} @{handle}」+ ログアウトボタン
- 未ログイン：「新規登録」「ログイン」リンク
- Phase 表示：0a → 0b に更新

### 実装したルート（6つ）

```
/             ホーム（ログイン状態切替）
/signup       新規登録フォーム
/login        ログインフォーム
/auth/verify-email  認証メール送信完了画面（再送ボタン付）
/auth/callback Route Handler（メール認証リンクの戻り）
/auth/auth-error  認証エラー画面
```

### ビルド確認

```
$ npm run build
✓ Compiled successfully in 1327ms
✓ Generating static pages 9/9
Route (app)
┌ ƒ /
├ ○ /_not-found
├ ○ /auth/auth-error
├ ƒ /auth/callback
├ ƒ /auth/verify-email
├ ƒ /login
└ ƒ /signup
```

### 09_state_machines / 規約原典との整合

`signup` Server Action は規約原典 §2 会員登録に対応：
- email + password での登録
- 利用規約・プライバシーポリシー同意必須
- ハンドル名は `^[a-z0-9_]{3,20}$` で検証（規約より厳格、DB と一致）

状態遷移（09 §7 Account Lifecycle）：
- `auth.users` INSERT → `handle_new_user()` トリガー → `public.users.account_status = 'registered'`
- メール認証完了 → callback で `email_confirmed_at` セット
  - ※ public.users.account_status の自動更新は未実装、後の iter で auth トリガー追加

### Vercel デプロイ後の必要作業（ユーザー対応）

#### 1. Supabase Auth 設定
Supabase ダッシュボード → Authentication → URL Configuration:

```
Site URL: https://megrum.tokyo

Redirect URLs:
- https://megrum.tokyo/auth/callback
- https://www.megrum.tokyo/auth/callback
- http://localhost:3000/auth/callback  ← ローカル開発用
```

#### 2. Vercel に本番URL 環境変数追加（任意）
```
NEXT_PUBLIC_APP_URL=https://megrum.tokyo
```
これがあると signup の emailRedirectTo が確実に本番URLに。
無くても VERCEL_URL でフォールバック動作する。

### 関連ファイル

新規（8ファイル）:
- `web/src/app/auth/actions.ts`（Server Actions）
- `web/src/app/auth/callback/route.ts`（Route Handler）
- `web/src/app/auth/verify-email/page.tsx` + `ResendButton.tsx`
- `web/src/app/auth/auth-error/page.tsx`
- `web/src/app/signup/page.tsx` + `SignUpForm.tsx`
- `web/src/app/login/page.tsx` + `LoginForm.tsx`

更新:
- `web/src/app/page.tsx`（ログイン状態対応）

### 次のステップ

1. **動作確認**：本番（megrum.tokyo）で実際にユーザー登録 → メール受信 → リンククリック → ログイン状態表示まで
2. **Supabase Auth URL設定**（ユーザー対応）
3. **Phase 0b-3：オンボーディング画面**：性別選択、推しグループ選択、推しメンバー選択、AW初期設定

これで Phase 0 の認証部分完了、次はオンボードへ。

---

## イテレーション52：Phase 0b-1 — Supabase CLI セットアップ + 初回マイグレーション

### 達成事項

リモート Supabase プロジェクトに **DB スキーマ + マスタデータ**を投入。
Phase 0 範囲（基盤・認証・マスタ）の DB 側準備完了。

### 作業内容

#### Supabase CLI セットアップ
- `~/.local/bin/supabase` v2.95.4 をバイナリで配置（Homebrew 不要）
- Personal Access Token（`sbp_xxx`）でログイン
- リポルートで `supabase init` → `supabase/` ディレクトリ作成
- `supabase link --project-ref kwpnlcojzseicqbxefih` でリモート接続

#### 初回マイグレーション作成・適用
- `supabase/migrations/20260501025213_initial_schema.sql`（253 行）
- 以下を作成：
  - **マスタ4つ**: `genres_master` / `groups_master` / `characters_master` / `goods_types_master`
  - **ユーザー拡張**: `public.users`（auth.users と 1:1、ハンドル・推し情報・状態管理）
  - **推し登録**: `user_oshi`（DD/箱推し対応、kind='box'/'specific'/'multi'）
  - **トリガー**:
    - `set_updated_at()`：updated_at 自動更新
    - `handle_new_user()`：auth.users INSERT 時に public.users 自動作成
  - **RLS（Row Level Security）**：全テーブル有効化、適切なポリシー設定
- **シードデータ**：
  - ジャンル 5（K-POP / 邦アイ / 2.5次元 / アニメ / ゲーム）
  - グッズ種別 11（トレカ / 生写真 / 缶バッジ / アクスタ / ペンライト 等）
  - K-POP 主要 10グループ（BTS / TWICE / NewJeans / IVE / Stray Kids / SEVENTEEN / aespa / LE SSERAFIM / ENHYPEN / TXT、aliases 込み）

#### 適用結果
```
$ supabase db push --include-all
Applying migration 20260501025213_initial_schema.sql...
Finished supabase db push.

$ supabase migration list
Local: 20260501025213 | Remote: 20260501025213 ✓ 一致
```

REST API 経由でシードデータも確認済：
- `GET /rest/v1/genres_master` → 5件取得
- `GET /rest/v1/groups_master` → 10件取得（aliases 含む）

### 09_state_machines / 10_glossary との整合

`account_status` の値リストは 09 §7 Account Lifecycle と完全一致：
- registered / verified / onboarding / active / suspended / deletion_requested / deleted

`user_oshi.kind` の値リストは 10 §B 推し関連と一致：
- box / specific / multi

### 関連ファイル

新規:
- `supabase/config.toml`（Supabase CLI 設定）
- `supabase/.gitignore`（ローカル一時ファイル除外）
- `supabase/migrations/20260501025213_initial_schema.sql`（253行）

### 次のステップ

**Phase 0b-2: Auth フロー実装（UI）**
- `/signup` ページ（メアド + パスワード + ハンドル）
- `/login` ページ
- `/logout` API
- /auth/callback（メール認証クリック後の遷移先）
- 認証後のセッション維持確認（既存 proxy.ts）

実装後、ブラウザで実際にユーザー登録 → ログイン → Supabase Studio で確認 → セッション維持確認 までを通す。

---

## イテレーション51：Phase 0a 完了 — https://megrum.tokyo で本番公開 🎉

### 達成事項

設計フェーズ（iter1-48）+ 実装初期（iter49-50）を経て、**本番URL `https://megrum.tokyo` で Megrum アプリが動作**するようになった。

### 完了作業

#### Vercel デプロイ
- 新規 Vercel プロジェクト「megrum」作成
- GitHub `Megrum_design` 連携、Root Directory `web/` 設定
- Application Preset 自動検出が UI 上は失敗したが、`web/vercel.json` の `framework: nextjs` でカバー
- Build / Install / Output コマンドはデフォルト使用
- 環境変数 4つ登録（NEXT_PUBLIC_SUPABASE_URL, _PUBLISHABLE_KEY, SUPABASE_SECRET_KEY, NEXT_PUBLIC_APP_ENV）
- 初回デプロイ成功

#### ドメイン接続（megrum.tokyo）
**Vercel 側設定**:
- `megrum.tokyo`（apex）: Production 環境に Connect
- `www.megrum.tokyo`: Production 環境に Connect（後で apex への redirect 化検討）

**お名前.com DNS 設定**:
- A レコード `@` → `216.198.79.1`（新しい Vercel IP に更新）
- CNAME `www` → `6a1fed19304af02c.vercel-dns-017.com.`（新プロジェクトの専用 CNAME）
- 旧プロジェクトの www CNAME（`668c44...vercel-dns-017`）を更新
- 旧 Firebase 関連レコード4つ削除（CNAME firebase1/2 _domainkey、TXT firebase=、TXT v=spf1 firebaseemail）
- NS レコード4つ（01-04.dnsv.jp）は保持
- TTL: 3600（標準）

**反映確認**:
- Vercel ダッシュボードで両ドメイン「Valid Configuration」（緑）
- HTTPS 証明書 Let's Encrypt 自動発行
- ブラウザで `https://megrum.tokyo` アクセス成功

#### 動作検証

ユーザーがブラウザで確認した結果：
- ✅ ページ表示成功
- ✅ 「★ Megrum」バッジ表示
- ✅ 「Hello Megrum」見出し表示
- ✅ 3カード表示（Phase 0a / Stack Next.js 16 / **Supabase: ✓ 接続（緑）**）
- ✅ Server Component で Supabase auth.getUser を呼び出し → 接続成功
- ✅ HTTPS 通信

つまり：
- Next.js 16 + React 19 が Vercel で正常動作
- Supabase Auth が SSR で動作
- 環境変数が正しく Vercel に渡っている
- Proxy（旧 middleware）が動作してセッション処理OK

### Phase 0a 達成状況

```
✅ Step 1: web/ ディレクトリ作成 + Next.js 16 初期化（iter49）
✅ Step 2: 「Hello Megrum」ページ実装（iter49）
✅ Step 3: Supabase クライアント初期化（iter50）
✅ Step 4: ローカル npm run build 成功（iter50）
✅ Step 5: Supabase 既存削除 → 新規作成（ユーザー対応）
✅ Step 6: API Keys 設定 → web/.env.local（iter50）
✅ Step 7: Vercel 既存削除 → 新規作成（ユーザー対応、iter51）
✅ Step 8: 環境変数登録（ユーザー対応、iter51）
✅ Step 9: 初回デプロイ成功（ユーザー対応、iter51）
✅ Step 10: ドメイン DNS 設定（ユーザー対応、iter51）
✅ Step 11: https://megrum.tokyo 表示確認（ユーザー対応、iter51）
✅ Step 12: Supabase 接続確認 ✓ 緑（ユーザー対応、iter51）
```

**Phase 0a 完全完了**。

### 主要URL

| 項目 | URL |
|---|---|
| 本番（apex） | https://megrum.tokyo |
| 本番（www） | https://www.megrum.tokyo |
| GitHub リポ | https://github.com/mashimabizz/Megrum_design |
| Vercel ダッシュ | https://vercel.com/mashimabizzs-projects/megrum |
| Supabase ダッシュ | https://supabase.com/dashboard/project/kwpnlcojzseicqbxefih |
| GitHub Pages（design preview） | https://mashimabizz.github.io/Megrum_design/ |

### 関連ファイル

更新なし（実装は iter49-50 で完了済、本 iter は本番反映の記録）

### 次のステップ

**Phase 0b へ移行**：
1. Supabase CLI セットアップ
2. `supabase/` ディレクトリ初期化、リモートとリンク
3. 初回 DB マイグレーション（最小構成）：
   - `users`（auth.users 拡張）
   - `user_oshi`（推し登録）
   - マスタテーブル4つ（genres / groups / characters / goods_types）
4. Auth フロー実装：
   - `/signup` ページ（メアド + パスワード + ハンドル）
   - `/login` ページ
   - `/logout` API
5. 確認：実際にユーザー登録 → ログイン → セッション維持

これで Phase 0 の半分（基盤）+ Phase 1 の入口（マスタ）に到達。

---

## イテレーション50：Supabase 接続 + Next.js 16 Proxy 対応

### 背景

iter49 で web/ プロジェクト初期化済。次はSupabase 接続。
ユーザーが新規 Supabase プロジェクト `megrum` を作成し、API URL + Publishable key + Secret key を共有。

### 作業中の発見

#### 新キーフォーマット（Supabase 2024+）

旧:
- `eyJhbGciOiJIUzI1NiI...` JWT形式の anon key / service_role key

新:
- `sb_publishable_xxx`（旧 anon key、ブラウザ用、公開可）
- `sb_secret_xxx`（旧 service_role key、サーバー専用、秘密）

`web/.env.local.example` も新naming convention で更新。

#### Next.js 16 で `middleware` → `proxy` にリネーム

ビルド時に warning：
> The "middleware" file convention is deprecated. Please use "proxy" instead.

Next.js 16 の規約変更。`src/middleware.ts` を `src/proxy.ts` にリネーム、関数名も `middleware()` → `proxy()` に変更。機能は同じ。

### 変更内容

#### `web/.env.local`（gitignore済、commit対象外）
- NEXT_PUBLIC_SUPABASE_URL
- NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
- SUPABASE_SECRET_KEY

#### `web/.gitignore` 修正
- `.env*` のままだと `.env.local.example` も除外される問題を修正
- `!.env.local.example` `!.env.example` を追加して例外指定

#### Supabase ライブラリインストール
- `@supabase/supabase-js@2.105.1`
- `@supabase/ssr@0.10.2`（Next.js SSR 対応、旧 auth-helpers の後継）

#### `web/src/lib/supabase/` 新規作成
- `client.ts`: `createBrowserClient`（Client Component 用）
- `server.ts`: `createServerClient`（Server Component / Route Handler 用）+ `createServiceRoleClient`（特権処理用）
- `middleware.ts`: `updateSession`（セッション refresh ヘルパー）

#### `web/src/proxy.ts`（旧 middleware.ts）
- Next.js 16 規約に従って `proxy.ts` にリネーム
- 関数名 `middleware()` → `proxy()` に変更
- 全リクエストでセッション更新（matcher で静的ファイルは除外）

#### `web/src/app/page.tsx` 更新
- Supabase 接続テスト追加（auth.getUser を試行）
- 接続状態を3列目のカードで表示（`✓ 接続` 緑 / `✗ 失敗` 赤）

### 動作確認

```bash
cd web && npm run build
# ✅ ビルド成功、警告なし
# ✅ Proxy (Middleware) で表示される
# ✅ static + dynamic ルート両方OK
```

### Phase 0a 進捗

```
✅ Step 1-5: Next.js 初期化（iter49）
✅ Step 6: Supabase 既存削除（ユーザー）
✅ Step 7: Supabase 新規作成（ユーザー、Tokyo region）
✅ Step 8: API keys 共有（Publishable + Secret）
✅ Step 9: web/.env.local 設定
✅ Step 10: Supabase クライアント初期化（browser / server / SSR proxy）
✅ Step 11: 接続テスト追加（page.tsx）

📋 残タスク:
[ ] Vercel 既存削除（ユーザー）
[ ] Vercel 新規プロジェクト作成（ユーザー、GitHub Megrum_design 連携）
[ ] Vercel に環境変数登録（ユーザー、Supabase URL/keys）
[ ] Vercel デプロイ確認
[ ] Vercel カスタムドメインに megrum.tokyo 設定（ユーザー）
[ ] お名前.com で DNS 確認/更新（ユーザー）
[ ] https://megrum.tokyo で「Hello Megrum」表示確認
```

### 関連ファイル

新規:
- `web/src/lib/supabase/client.ts`
- `web/src/lib/supabase/server.ts`
- `web/src/lib/supabase/middleware.ts`
- `web/src/proxy.ts`（旧 middleware.ts をリネーム）

更新:
- `web/.gitignore`：env.example の除外解除
- `web/.env.local.example`：新キー名に更新
- `web/.env.local`：実値設定（gitignore で除外）
- `web/package.json`: @supabase/supabase-js + @supabase/ssr 追加
- `web/src/app/page.tsx`: Supabase 接続テスト追加

⚠️ `.env.local` は git に push されない（.gitignore済）。Secret key は安全に管理。

### 次のステップ

ユーザー対応待ち：
1. Vercel 既存 megrum プロジェクト削除
2. Vercel 新規プロジェクト作成・GitHub Megrum_design 連携
3. 環境変数登録（Supabase の3つ + APP_ENV）
4. デプロイ → megrum.tokyo 接続

---

## イテレーション49：Phase 0a 着手 — Next.js 16 プロジェクト初期化

### 背景

設計フェーズ完了後、いよいよ実装着手。
ユーザー方針：
- リポは `Megrum_design` をそのまま monorepo 化（新規リポ作成しない）
- 既存 Supabase / Vercel `megrum` プロジェクトは削除して再作成（クリーンスタート）
- ドメイン `megrum.tokyo` は新 Vercel プロジェクトに繋ぎ直し

### 変更内容

#### `web/` ディレクトリ新規作成

```bash
npx create-next-app@latest web \
  --typescript --tailwind --eslint \
  --app --src-dir --import-alias "@/*" --no-turbopack
```

導入バージョン：
- **Next.js 16.2.4**（破壊的変更あり、要 docs 確認）
- **React 19.2.4**
- TypeScript / Tailwind CSS / ESLint / App Router / src/ 構成

ビルド確認済（`npm run build` 成功）。

#### `web/src/app/layout.tsx` カスタマイズ
- Geist フォント → **Noto Sans JP**（日本語向け）
- title / description を Megrum 用に
- lang="ja"

#### `web/src/app/page.tsx` カスタマイズ
- 「Hello Megrum」ランディング
- Megrum ブランドカラー（紫→ピンク gradient）
- Phase 0a / Stack 情報カード
- 設計 iter数を表示

#### `web/next.config.ts` 設定
- `turbopack.root` を明示的に `web/` に固定（lockfile 検出警告の抑制）

#### `web/.env.local.example` 作成
- Supabase 接続情報のテンプレート（NEXT_PUBLIC_SUPABASE_URL, anon key, service_role key）

#### `vercel.json` 作成（リポ root）
- buildCommand: `cd web && npm run build`
- outputDirectory: `web/.next`
- installCommand: `cd web && npm install`
- framework: nextjs

これで Vercel が `web/` サブディレクトリを Next.js プロジェクトとして認識・ビルド・デプロイ。

#### `CLAUDE.md` 更新
- `web/` ディレクトリ構造を追記
- Next.js 16 注意事項（破壊的変更、AGENTS.md / docs 確認）
- 動作確認コマンド一覧

### Phase 0a 進捗

```
✅ Step 1: web/ ディレクトリ作成 + Next.js 初期化
✅ Step 2: 「Hello Megrum」ページ表示確認（npm run build 成功）
✅ Step 3: vercel.json 設定
✅ Step 4: .gitignore 確認（既存で十分カバー）
✅ Step 5: CLAUDE.md 更新

📋 残タスク（ユーザー対応 + 私の作業）:
[ ] ユーザー: 既存 Supabase megrum プロジェクト削除
[ ] ユーザー: 既存 Vercel megrum プロジェクト削除
[ ] ユーザー: Supabase 新規 megrum プロジェクト作成（Region: Tokyo）
[ ] ユーザー: Supabase API URL + anon key + service_role key を共有
[ ] 私: web/.env.local 設定 + Supabase クライアント初期化
[ ] ユーザー: Vercel 新規 megrum プロジェクト作成（GitHub Megrum_design 連携）
[ ] ユーザー: Vercel に環境変数登録（Supabase keys）
[ ] ユーザー: Vercel カスタムドメインに megrum.tokyo 設定
[ ] ユーザー: お名前.com で DNS 確認/更新
[ ] 私: デプロイ確認、https://megrum.tokyo で「Hello Megrum」表示
```

### 確認方法

ローカル：
```bash
cd web && npm run dev
# http://localhost:3000 で「Hello Megrum」表示
```

GitHub：
```
https://github.com/mashimabizz/Megrum_design/tree/main/web
```

### 関連ファイル

新規:
- `web/`（Next.js 16 プロジェクト一式、約 360 packages）
- `web/.env.local.example`
- `vercel.json`

更新:
- `CLAUDE.md`（web/ 構造追記）

### 次のステップ

ユーザーがクラウド側を削除→再作成 → 私が Supabase クライアント・初期マイグレーションを設定。
1〜2 セッションで「https://megrum.tokyo で Hello Megrum」状態に到達予定。

---

## イテレーション48：メール構造を2つに簡素化 + ハンドル概念整理 + Supabase/Vercel 既設

### 背景

iter47 の確認後、ユーザーから3点の補足：
1. `privacy@megrum.tokyo` は実在しない（不要）
2. 「ハンドル名」の意味を確認 → 公式 X アカウント名のことと判明
3. Supabase / Vercel は既に作成済み（アカウント作成不要）

### 修正

#### メール構造を 3 → 2 に簡素化

| メール | 用途 |
|---|---|
| `support@megrum.tokyo` | メイン（新規登録・問い合わせ・サポート・**個人情報保護関係も**） |
| `info@megrum.tokyo` | お知らせ・通知系 |

`privacy@` は廃止、`support@` に統合。

#### 「ハンドル」用語の整理

2種類の意味を明確化：

| 種類 | 意味 | 例 | 必要性 |
|---|---|---|---|
| **A. Megrumユーザーのハンドル** | アプリ内ユーザー識別子（システムフィールド） | `@hana_lumi`、`@lumi_sua` | **必須** |
| **B. Megrum公式 X アカウント** | 運営の広報用 X アカウント | `@megrum_jp` 等 | **当面なし、Phase β以降検討** |

iter45-47 で「対外ハンドル `@megrum_jp` 暫定」と書いていたが、これは B（公式X）を指していた。
ユーザー判断：**当面 X アカウントは作らない**。Phase β（マネタイズ開始時期）以降に広報強化が必要になったら検討。

#### Supabase / Vercel：既設利用

ユーザーが既に Supabase / Vercel アカウントを作成済み。Phase 0a で**新規プロジェクトのみ作成**する：
- Supabase 新規プロジェクト作成（既アカウント内に Megrum 専用）
- Vercel 新規プロジェクト作成（既アカウント内に Megrum 専用）

### 変更ファイル

- `Megrum/legal-pages.jsx`：`privacy@megrum.tokyo` → `support@megrum.tokyo`
- `notes/15_non_functional.md`：3メール → 2メール
- `notes/16_monetization.md`：
  - 3メール → 2メール
  - 「対外ハンドル」 → 「公式X アカウント未作成」
  - 未確定項目の「対外ハンドル」を Phase β 検討項目に
- `notes/17_legal_alignment.md`：
  - メールアドレスを 2構造に
  - 「プライバシーポリシーの個人情報保護管理者連絡先も support@ に統一」TODO追加

### Phase 0a 着手プラン（更新）

```
旧プラン:
  Step 1: Supabase アカウント作成 ← 不要（既設）
  Step 2: Vercel アカウント作成 ← 不要（既設）

新プラン:
  Step 1: GitHub 上に実装リポ作成（推奨：「megrum」小文字）
  Step 2: Next.js プロジェクト初期化（npx create-next-app@latest）
  Step 3: 既存 Supabase アカウントに Megrum 専用プロジェクト作成
  Step 4: 既存 Vercel アカウントに Megrum_app プロジェクト作成 → デプロイ
  Step 5: お名前.com で DNS 設定 → megrum.tokyo を Vercel に向ける
```

所要時間：1〜2 セッション（合計 2〜4 時間）

### 確認したい残事項

1. 実装リポジトリ名：**`megrum`**（小文字、ドメインと統一）でOK？
2. Supabase 新規プロジェクト名：**`megrum-mvp`** or 別案？
3. Vercel 新規プロジェクト名：**`megrum`** or 別案？

これらが決まったら **Phase 0a 即着手** 可能。

---

## イテレーション47：ドメイン・メール構造確定 + 弁護士OK 判明

### 背景

ユーザー報告：
1. **ドメイン取得完了**：`megrum.tokyo`（お名前.com）
2. **弁護士レビュー結果：「このまま OK」**（規約原典 docx を改訂不要）
3. **メール構造**：support@（メイン）、info@（通知）、privacy@（個人情報）の3つで運用
4. **legal-pages.jsx の方針**：「モックアップなので、実装でちゃんと反映してくれるように」

### 重要な判明事項

#### 弁護士判断「このまま OK」の意味

iter46 で「規約改訂が必要」と判断したが、弁護士は：
- 規約原典 docx を **そのまま運用 OK** と判断
- Megrum MVP は規約の **SUBSET として実装**（MyLog・郵送 は実装しないが、契約上は許可されている）
- これは法的に正常（契約 SUPERSET、実装 SUBSET）

つまり：
- ✅ docx 改訂不要（弁護士費 $500 は使わずに済んだ）
- ✅ 将来 MyLog や 郵送 を追加する際も追加レビュー不要
- ⚠️ `legal-pages.jsx` は実装時に docx を完全反映する必要あり

iter46 で書いた「弁護士再依頼」プランは **不要**になった。

#### legal-pages.jsx の位置づけ確定

`legal-pages.jsx` は **画面UI のモックアップ**であり、実装時には docx を完全反映する：
- 利用規約：572 行 → そのまま反映
- プライバシーポリシー：218 行 → そのまま反映
- 特商法：70 行 → そのまま反映 + 価格 ¥500 等を確定値で埋める

これは `notes/17_legal_alignment.md` に「実装フェーズの TODO」として明記。

### 確定事項

#### ドメイン・URL

| 項目 | 値 |
|---|---|
| ドメイン | **`megrum.tokyo`** |
| API 本番 | `https://api.megrum.tokyo/v1` |
| API staging | `https://api-staging.megrum.tokyo/v1`（暫定） |
| GitHub Pages | `https://mashimabizz.github.io/Megrum_design`（プレビュー用） |

#### メール構造

| メール | 用途 |
|---|---|
| **`support@megrum.tokyo`** | メイン連絡先（新規登録・問い合わせ・サポート） |
| **`info@megrum.tokyo`** | お知らせ・通知系（一斉送信） |
| **`privacy@megrum.tokyo`** | 個人情報保護関係 |

### 変更内容

- `Megrum/legal-pages.jsx`：
  - `hello@megrum.example.com` → `support@megrum.tokyo`
  - `privacy@megrum.example.com` → `privacy@megrum.tokyo`
  - `株式会社Megrum` → `Megrum 運営者`（4箇所、規約原典の表現に合わせる）

- `notes/15_non_functional.md`：3 メールアドレス構造を反映

- `notes/13_api_spec.md`：ベースURL に `megrum.tokyo` 反映

- `notes/16_monetization.md`：3 メールアドレス構造を反映

- `notes/17_legal_alignment.md`：
  - 「弁護士 OK = docx 改訂不要」方針に大幅書き換え
  - 「実装フェーズの TODO」セクション追加（legal-pages.jsx を docx で完全置き換え）

### Phase 進捗

設計フェーズの最終整備が完了：
- ドメイン取得 ✅
- 弁護士レビュー ✅（このまま OK）
- メール構造確定 ✅
- legal-pages.jsx 実装方針確定 ✅

### 次のステップ

**実装フェーズ着手の準備完了。**

残タスク：
1. ハンドル名確認（`@megrum_jp` か `@megrum_tokyo` か）
2. お名前.com でメール転送設定（support@・info@・privacy@ を Gmail に）
3. **Phase 0a 着手**：
   - Supabase アカウント作成（ユーザー）
   - Supabase プロジェクト作成（一緒に）
   - Vercel 連携（一緒に）
   - Next.js プロジェクト初期化
   - 「Hello Megrum」が表示されるところまで

### 関連ファイル

- `Megrum/legal-pages.jsx`
- `notes/13_api_spec.md`
- `notes/15_non_functional.md`
- `notes/16_monetization.md`
- `notes/17_legal_alignment.md`

---

## イテレーション46：規約原典との整合・用語統一・運営者情報修正

### 背景

弁護士納品の規約原典（2024-07-18）が `利用規約など/` ディレクトリに存在することを iter45 後に発見。
読み込んで現状の Megrum 設計と照らし合わせ、齟齬を整理。

iter45 で「松尾満天」を実名表示に変更したが、規約原典では「代表者情報は非公表」が方針だったため、**原典通りに戻す**。

ユーザー判断：
- MyLog 機能 → **削除**
- 郵送機能 → **削除**
- ダイレクトメッセージ → **取引チャットで統一**
- 交換依頼 → **打診で統一**
- 交換募集 → **概念消滅（在庫登録に吸収）**

### 変更内容

#### 新規ファイル
- `notes/17_legal_alignment.md`：規約原典との整合性管理（弁護士再依頼用資料）
  - 規約原典のサマリ（利用規約全40条、プライバシー、特商法）
  - 齟齬一覧（削除4 / 追加5 / 用語統一3 / 価格確定2 / 代表者情報1）
  - 削除事項詳細（MyLog第3章全削除、郵送関連 §3/§13/§17）
  - 追加事項詳細（待ち合わせfix、服装写真、現在地、Dispute詳細、通報）
  - 用語統一マッピング
  - 価格確定（Premium ¥500/月、ブースト ¥150/¥600/¥1,000）
  - 弁護士再依頼の概算費用（$500-800）
  - 変更後の規約構成案（38条、章立て見直し）

#### 更新ファイル
- `notes/10_glossary.md`：
  - §J 廃止用語に MyLog・郵送・交換依頼・交換募集・ダイレクトメッセージ等を追加
  - §M 規約原典マッピングを新設（規約原典 → Megrum設計 の用語対応表）
  - 規約改訂が必要な箇所を弁護士再依頼対象として明示

- `Megrum/legal-pages.jsx`：
  - 代表者名・所在地・電話番号を「**非公表**」（規約原典通り）に戻す
  - フッターの「松尾 満天（Megrum 運営）」を「Megrum 運営」に
  - iter45 で入れた実名表示を取り消し

- `notes/15_non_functional.md`：
  - §11-2 特商法を規約原典方針（非公表）に合わせて修正

- `notes/16_monetization.md`：
  - §1 運営者情報を「非公表方針」に修正
  - 内部情報セクション新設（運営者氏名は規約に書かない、請求対応のみ）

- `CLAUDE.md`：
  - 必読docs リストに `11_screen_inventory.md` 〜 `17_legal_alignment.md` を追加
  - 必読項目 6. に「法的文書に関わる作業は 17_legal_alignment.md を確認」追加
  - 「重要な用語ルール（iter46 確定）」セクション新設
  - 「法的文書の方針」セクション新設

- `.gitignore`：`利用規約など/` を除外（個人情報・著作権配慮）

### 確認した他docsの状態
- `02_system_requirements.md`：「郵送はYahooフリマと棲み分け」のみ言及。修正不要（戦略的記述）
- `03_strategy.md`：同上
- `07_mvp_handoff.md`：同上、`exchange_method='郵送'` も「UI非表示・データ型維持」で整合

### 影響範囲
- 設計ドキュメント全体の用語統一
- `Megrum/legal-pages.jsx` の表示が規約原典と整合
- 弁護士に渡せる改訂依頼資料が完成
- `利用規約など/` ディレクトリは git 管理外として保護

### Phase 2 完了状況

USER_PLAYBOOK の 7タスクは iter44 で完了済。iter45（マネタイズ）+ iter46（法的整合）で**実装着手前の最終整備が完了**。

### 確認方法
- `notes/17_legal_alignment.md`
- `Megrum/legal-pages.jsx`（特商法ページの表示）
- `notes/10_glossary.md` §J + §M

### 関連ファイル

新規:
- `notes/17_legal_alignment.md`

更新:
- `notes/10_glossary.md`
- `Megrum/legal-pages.jsx`
- `notes/15_non_functional.md`
- `notes/16_monetization.md`
- `CLAUDE.md`
- `.gitignore`

### 次フェーズへの示唆

法的整合の最終ステップ：
1. **ドメイン取得 → メールアドレス確定**（hello@megrum.* 等）
2. **`notes/17_legal_alignment.md` を弁護士に共有 → 規約改訂依頼**（$500-800、ユーザー予算内）
3. **改訂版docx 受領 → `利用規約など/` に保管**
4. **`Megrum/legal-pages.jsx` を改訂版docx に合わせて再更新**
5. これで Phase 0a 着手可能

これで設計フェーズ完全完了 + 法的整合まで整理。

---

## イテレーション45：マネタイズ戦略確定 + 運営者情報反映

### 背景

実装フェーズ移行決定を受けて、マネタイズ戦略を正式文書化。

ユーザーの当初プラン：
- 常時表示バナー広告
- 打診時 全画面広告（インタースティシャル）
- ブースト機能（広告スキップ + 上位表示）
- Premium = 保存検索通知 + 月3ブースト配布

ユーザーの問題意識：
- 「Premium = コア機能解放」は筋が悪い（保存検索通知はコア機能であるべき）
- 「コア機能は常時無料」を維持したい

### 確定事項

#### 運営者情報
| 項目 | 値 |
|---|---|
| 運営者氏名 | 松尾 満天 |
| 法形態 | 個人事業主（届出済） |
| 屋号 | なし |
| サービス名 | Megrum |
| 対外ハンドル（暫定） | @megrum_jp |

#### マネタイズ戦略

**広告**：
- 打診時の全画面広告は **削除**（取引フロー離脱リスク高）
- 代わりに **取引完了時** や **マッチ閲覧時** に native ad
- Tier 1: HOM-main / SCH-main / WSH-list に native ad（5件毎）
- Tier 2: PRO-other / TRD-past / AW-list にフッターバナー
- Tier 3: 取引フロー全画面（C-0〜C-3）と認証・設定・法的・ヘルプは**完全に広告ゼロ**

**ブースト機能**：
- 単発 ¥150 / 5個 ¥600 / 10個 ¥1,000
- 24時間有効、上位表示＋広告非表示
- 1日2個発動上限（依存性防止）

**Premium 会員**（月¥500 / 年¥4,800）：
- コア機能の差は**ゼロ**
- 広告完全非表示・月3ブースト無料配布・装飾（背景・絵文字・バッジ）
- 副次的：メッセージ履歴永続・既読確認

**アフィリエイト**（Phase γ〜）：Amazon・楽天・公式チケット販売
**公式コラボ**（Phase δ〜）：ライブ運営との提携、法人化検討

### 変更ファイル

#### 新規
- `notes/16_monetization.md`：マネタイズ戦略 v1.0 完全版

#### 更新（マネタイズ反映）
- `notes/05_data_model.md`：§9 マネタイズ追加（subscriptions / boosts / transactions / ad_overrides テーブル）
- `notes/13_api_spec.md`：§15-17 追加（subscriptions / boosts / ads エンドポイント）
- `notes/14_implementation_phases.md`：§10b 追加（Phase β-γマネタイズ実装、合計 2.5-3 人月追加）
- `notes/15_non_functional.md`：決済セキュリティ・特商法対応追加
- `notes/11_screen_inventory.md`：広告配置注釈追加（HOM-main / SCH-main / WSH-list）、§K 広告配置サマリ追加
- `notes/10_glossary.md`：§L マネタイズ用語追加（ブースト・Premium・Native ad 等）
- `Megrum/legal-pages.jsx`：特商法ページに実名「松尾 満天」反映、有料機能の表記追加

### Phase 2 完了状況

USER_PLAYBOOK の 7タスク中：
- ✅ タスク1〜6（iter38-44）
- 🟡 タスク7（02 機能要件 更新）— 任意

**Phase 2 完了に加えて、マネタイズ戦略 v1.0 確立**。

### 確認方法

- `notes/16_monetization.md`
- 特商法ページ：http://localhost:8000/Megrum%20Legal%20Pages.html

### 関連ファイル

新規：
- `notes/16_monetization.md`

更新：
- `notes/05_data_model.md`、`13_api_spec.md`、`14_implementation_phases.md`、`15_non_functional.md`
- `notes/11_screen_inventory.md`、`10_glossary.md`
- `Megrum/legal-pages.jsx`

### 次フェーズ

ドキュメント整備完了。次は：
1. 法務監修（プライバシーポリシー・利用規約・年齢制限）
2. ドメイン取得＋メールアドレス決定
3. **Phase 0a 着手：Supabase + Next.js プロジェクト作成**

Phase β（半年後）でマネタイズ実装着手の予定。

---

## イテレーション44：非機能要件（USER_PLAYBOOK タスク6）

### 背景

USER_PLAYBOOK タスク6。
機能要件（02）が「何を作るか」だとすると、非機能要件は「**どのレベルで作るか**」。Phase 0 着手前に整備して、設計時点で品質特性を確定。

Megrum は **「現地で会うアプリ」** という特性上、一般的な交換アプリより配慮すべきリスクが多い：
- 対面取引でのトラブル（詐欺・暴力・ストーキング）
- 位置情報の悪用
- 未成年利用の安全性
- 服装写真の悪用

これらに対する明確な方針が必要。

### 変更内容

#### `notes/15_non_functional.md`（新規作成、約 600行）

**12 カテゴリ・約 80 要件**：

1. **Megrum 特有のリスクと前提**：5 リスクの整理、KPOP 限定 MVP、対象年齢⚠️、有人運営前提
2. **プライバシー・個人情報保護**：取り扱う情報の種類分類、位置情報の特殊扱い、未成年対応、プライバシーポリシー要件
3. **セキュリティ**：認証（bcrypt/argon2、JWT、OAuth）、認可、HTTPS、入力検証、Rate limit、監査ログ
4. **パフォーマンス**：応答時間 SLA（p95/p99）、DAU 想定、DB インデックス、画像最適化、CWV 目標値
5. **可用性・スケーラビリティ**：稼働率目標（99.5%→99.9%→99.95%）、ステートレス設計、DB sharding（Post-MVP）
6. **アクセシビリティ**：WCAG 2.1 AA 目標、コントラスト・タップターゲット・キーボード操作
7. **ローカリゼーション**：MVP 日本語のみ、Post-MVP で韓国語・中国語・英語、i18n 基盤導入推奨
8. **ログ・監視・分析**：構造化ログ JSON、個人情報マスキング、エラー監視（Sentry/Datadog 等）、KPI ダッシュボード
9. **災害復旧・バックアップ**：日次フル+1h増分、RPO 1h / RTO 4h、半年に1回の復旧訓練
10. **運用・SRE**：CI/CD、オンコール体制、インシデント Sev 判定、キャパシティプランニング
11. **コンプライアンス・法的**：個人情報保護法、特商法、利用規約、著作権、18歳未満への配慮
12. **未確定項目まとめ**：18件を 5カテゴリで整理

**Megrum 特有の重要設計**：
- 位置情報の3層分類（広域 / 取引相手のみ / メッセージ内）
- 服装写真の扱い（取引終了 30日後削除 ⚠️、顔ブラー Post-MVP）
- 同担拒否文化への配慮（プロフでブロック容易化）
- 対面取引の安全性（通報・dispute・運営仲裁）

### 影響範囲

- 設計ドキュメント完成（00-15 が揃った）
- Phase 0 着手前の最後の整備が完了
- 法務監修・PoC で詰めるべき 18 項目を明示

### Phase 2 進捗

USER_PLAYBOOK タスク：
- 🥇 タスク1（05 最新化） ✅ iter38
- 🎯 5論点擦り合わせ ✅ iter39
- 🥈 タスク2（11 画面マトリクス） ✅ iter40
- 🥈 タスク3（12_screens/ per-screen spec） ✅ iter41
- 🥉 タスク4（13 API spec） ✅ iter42
- 🥉 タスク5（14 実装フェーズ分割） ✅ iter43
- 🟡 **タスク6（15 非機能要件） ✅ iter44 ← 今回**
- 🟡 タスク7（02 機能要件 更新） — 任意

### 🎉 Phase 2 全 6/7 完了！

Phase 2 の主要 5 + 任意 1 完了。残るはタスク7（02 更新）のみで、これは古いままでも実害なし。

設計ドキュメント完全構造：
```
00-04, 06-07  要件定義（既存・更新候補あり）
05            データモデル v2（最新）
09            状態遷移
10            用語集
11            画面インベントリ（89画面）
12_screens/   per-screen spec（主要5画面）
13            API仕様（70+ endpoints）
14            実装フェーズ分割
15            非機能要件 ← 今回
```

### 確認方法

- `notes/15_non_functional.md`
- GitHub: https://github.com/mashimabizz/Megrum_design/blob/main/notes/15_non_functional.md

### 関連ファイル

- `notes/15_non_functional.md`（新規）

### 次フェーズへの示唆

**実装フェーズへの完全準備完了**：
- 機能要件（02）+ 非機能要件（15）= 完全な仕様
- 状態遷移（09）+ データモデル（05）= 実装の正解
- API spec（13）+ 画面 spec（12）= フロント・バック契約
- 実装フェーズ分割（14）= ロードマップ
- 用語集（10）+ 画面インベントリ（11）= 一貫性の基盤

特に注力すべき法務確認事項：
1. 位置情報の保管期間（30日/90日/1年）
2. 服装写真の自動削除タイミング
3. 年齢制限（13/16/18歳）
4. 個人情報保護法対応の細部
5. 越境データ移転の同意取得方式

これらを法務確認後、Phase 0 着手可能。

---

## イテレーション43：実装フェーズ分割（USER_PLAYBOOK タスク5）

### 背景

USER_PLAYBOOK タスク5。**Phase 2 の最後の主要タスク**。
これまでの全 docs（00-13）を統合して、MVP 実装ロードマップを作る。エンジニア募集・着手の最終資料。

### 変更内容

#### `notes/14_implementation_phases.md`（新規作成、約 600行）

**Phase 0〜6 の構成**：

| Phase | 内容 | 概算工数 | 含む画面数 | 含むAPI数 |
|---|---|---|---|---|
| Phase 0 | 基盤・認証・オンボ | 1.5〜2人月 | 15 | 20 |
| Phase 1 | 在庫・AW・ウィッシュ | 1.5〜2人月 | 12 | 25 |
| Phase 2 | マッチング・C-0 | 1〜1.5人月 | 11 | 11 |
| Phase 3 | 打診・ネゴ・合意 | 1.5〜2人月 | 11 | 11 |
| Phase 4 | 取引・C-3 | 1.5〜2人月 | 11 | 11 |
| Phase 5 | Dispute・通報 | 1.5〜2人月 | 17 | 9 |
| Phase 6 | サポート・法的 | 0.5〜1人月 | 13 | （Phase 0と重複多） |
| **合計** | **MVP リリース** | **9〜12.5人月** | **89画面** | **70+ API** |

各 Phase に：
- ゴール（1文）
- 含む機能（要件 ID と紐付け）
- 含む画面（11_screen_inventory.md と紐付け）
- 含む API（13_api_spec.md と紐付け）
- 完了基準（DoD、チェックリスト）
- 概算工数（バックエンド・フロントエンド・インフラ別）
- 主な未確定項目（13_api_spec.md の項番号で参照）
- 並行開発の余地

**追加セクション**：

1. **前提・全体像**：
   - 想定チーム構成（最小3〜5人、3〜4ヶ月想定）
   - 技術スタック候補（⚠️ 要確認、Node/Go/Rails、PostgreSQL、PWA/RN/Flutter 等）
   - Phase 依存関係 mermaid 図

2. **横断的関心事**：
   - ロギング・モニタリング（Sentry、Datadog）
   - プッシュ通知（FCM、トピック別）
   - 国際化（MVP は日本語のみ）
   - パフォーマンス（マッチング計算スケーラビリティ）
   - セキュリティ（HTTPS、JWT、CSRF、XSS）
   - アクセシビリティ（WCAG AA）
   - テスト戦略（unit / integration / E2E / 負荷）

3. **Beta テスト戦略**：
   - 内部テスト（α、Phase 4 後）
   - クローズドβ（Phase 5 後、20-50人）
   - オープンβ（Phase 6 後、KPOP 限定）
   - 本リリース

4. **Post-MVP ロードマップ**：13項目を優先度3段階で整理（ジャンル拡大・GPS到着・WebSocket・国際化・郵送 等）

5. **リスク・前提**：
   - 技術リスク（4件）
   - ビジネスリスク（4件）
   - 法的・運用リスク（4件）
   - プロジェクト前提

### 影響範囲

- 設計ドキュメント完成（00-14 が揃った）
- 実装着手の準備が **完了** レベルに到達
- エンジニア募集の資料として活用可能

### Phase 2 進捗

USER_PLAYBOOK タスク：
- 🥇 タスク1（05 最新化） ✅ iter38
- 🎯 5論点擦り合わせ ✅ iter39
- 🥈 タスク2（11 画面マトリクス） ✅ iter40
- 🥈 タスク3（12_screens/ per-screen spec） ✅ iter41
- 🥉 タスク4（13 API spec） ✅ iter42
- 🥉 **タスク5（14 実装フェーズ分割） ✅ iter43 ← 今回**
- 🟡 タスク6（15 非機能要件） — Post-MVP判断
- 🟡 タスク7（02 機能要件 更新） — 任意

### 🎉 Phase 2 主要タスク完了！

Phase 2 の主要 5/5 完了。**実装フェーズへ移行できる状態**。

設計ドキュメント階層：
```
要件定義層     00-04, 06-07
基本設計層     05 + 09 + 10
詳細設計層     11 + 12_screens/ + 13
実装計画層     14
ガバナンス層   CLAUDE.md / README.md / USER_PLAYBOOK.md / 08
```

別環境の Claude / 別エンジニアでも、これだけあれば Megrum を完全に再現・実装できる状態。

### 確認方法

- `notes/14_implementation_phases.md`
- GitHub: https://github.com/mashimabizz/Megrum_design/blob/main/notes/14_implementation_phases.md

### 関連ファイル

- `notes/14_implementation_phases.md`（新規）

### 次フェーズへの示唆

**Phase 3：実装フェーズ着手**
- 技術スタック確定
- インフラ選定
- エンジニア募集（必要に応じて）
- Phase 0 から段階的に実装

**任意で残せるタスク**：
- タスク6（15 非機能要件）— Phase 0 着手前に整備推奨
- タスク7（02 機能要件 更新） — 古いままでも実害なし
- 残画面の per-screen spec（ホーム・AW・在庫等）— 実装と並行で OK

---

## イテレーション42：API仕様 v1 draft（USER_PLAYBOOK タスク4）

### 背景

USER_PLAYBOOK タスク4。
12_screens/ の per-screen spec で各画面の「関連 API（仮）」を明記したので、それらを集約して REST API 形式に落とす。
- 実装着手前の最後の壁
- 33件の未確定項目の半分くらいはここで解決の道筋がつく
- バックエンド・フロントエンド双方の正解集

### 変更内容

#### `notes/13_api_spec.md`（新規作成、約 800行）

**14 リソースグループ・約 70 エンドポイント**：

1. **Auth（認証）**：register / verify-email / login / OAuth / forgot-password / reset-password / logout / refresh — 9件
2. **Accounts（自分のアカウント）**：me / oshi / onboarding / delete-request / blocks — 9件
3. **Users（他ユーザー）**：参照系のみ — 4件
4. **Masters（マスタデータ）**：genres / groups / characters / goods-types / events — 6件
5. **AWs（活動予定）**：CRUD + pause/resume + intersect — 8件
6. **Items（在庫）**：CRUD + bulk + image upload + carrying toggle — 9件
7. **Wishes（ウィッシュ）**：CRUD + matches — 6件
8. **Matches（マッチング）**：4タブ + feed + saved searches — 6件
9. **Proposals（打診・ネゴ）**：CRUD + send/agree/reject/counter/revise/extend/share-inventory + revisions — 11件（最大ボリューム）
10. **Messages（メッセージ）**：取得・送信・画像アップロード — 3件
11. **Deals（取引）**：CRUD + arrivals + outfit-photos + evidence + approve + dispute + rate + cancel — 10件
12. **Disputes（異議申し立て）**：CRUD + reply + withdraw + admin-question + resolve + reappeal — 7件
13. **Reports（通報）**：通報作成・自分の通報一覧 — 2件
14. **Misc**：通知デバイス・通知設定・WebSocket — 5件

**共通仕様セクション**：
- 認証スキーム（JWT Bearer 推奨、⚠️ 要確認）
- ベースURL `/v1`（API バージョニング）
- リクエスト/レスポンス形式（JSON、ISO 8601、UUID v4）
- ステータスコード一覧
- エラーコード（VALIDATION_ERROR / STATE_CONFLICT 等）
- ページネーション（カーソル方式 + オフセット方式）
- Rate limiting（⚠️ 要確認の数値）
- ファイルアップロード（直接 vs 署名付きURL、MVP は直接）

**各エンドポイントの記述形式**：
```
### POST /api/v1/...
- **Auth**: 必須/不要
- **Request**: { ... }
- **Response 201**: { ... }
- **Errors**: 4xx 一覧
- **Side effects**: メール送信・DB変更・通知等
- **State**: 状態遷移 (09 と一致)
- **Screen**: 関連画面 (11/12 と一致)
- **備考**: ⚠️ 要確認 含む
```

**未確定項目セクション**：30件を5カテゴリで整理：
- 認証・基盤（5件）
- Proposal・ネゴ（6件）
- Deal・dispute（8件）
- マスタ・周辺（6件）
- 画像・ストレージ（3件）
- 通報・運営（2件）

### 影響範囲

- 実装着手の準備が完了レベルに到達
- バックエンドとフロントエンドの実装契約として機能
- 12_screens の各画面と完全クロスリファレンス

### Phase 2 進捗

USER_PLAYBOOK タスク：
- 🥇 タスク1（05 最新化） ✅ iter38
- 🎯 5論点擦り合わせ ✅ iter39
- 🥈 タスク2（11 画面マトリクス） ✅ iter40
- 🥈 タスク3（12_screens/ per-screen spec） ✅ iter41
- 🥉 **タスク4（13 API spec） ✅ iter42 ← 今回**
- 🥉 タスク5（14 実装フェーズ分割） → 次（残り最後の主要タスク）
- 🟡 タスク6（15 非機能要件）
- 🟡 タスク7（02 機能要件 更新）

Phase 2 の主要4タスク完了。**実装フェーズへ移行する準備の 90% が整った状態**。

### 確認方法

- `notes/13_api_spec.md`
- GitHub: https://github.com/mashimabizz/Megrum_design/blob/main/notes/13_api_spec.md

### 関連ファイル

- `notes/13_api_spec.md`（新規）

### 次フェーズへの示唆

タスク5（実装フェーズ分割）：
- 13_api_spec の各エンドポイントを Phase 0〜6 に振り分け
- 11_screen_inventory の各画面を Phase に紐付け
- 依存関係を明確化（Auth が一番先、disputes が一番後 等）
- 各 Phase の完了基準・概算工数

これで Megrum の実装ロードマップが完成し、エンジニア募集・着手の準備が整う。

---

## イテレーション41：per-screen spec（USER_PLAYBOOK タスク3）— 主要5画面

### 背景

USER_PLAYBOOK タスク3。
画面インベントリ（11）で全89画面を一覧化したので、次は **重要画面の詳細仕様**を per-screen で書く。
- 「この画面はどう作る？」「state/props/振る舞い/エラーは？」が一発で引ける一次資料
- JSX コードに暗黙的になっていた仕様を文章化
- 未確定項目は「⚠️ 要確認」マークで保留

### 変更内容

#### `notes/12_screens/` ディレクトリ新規作成

##### `notes/12_screens/README.md`
- ディレクトリの位置付け・命名規約・章立てテンプレ
- 各 spec 共通の章立て：画面の目的／入力データ／表示要素／アクション／バリデーション・エラー／エッジケース／関連API（仮）／関連docs／未確定項目

##### `notes/12_screens/C-0_propose_select.md`
- 6 variant（mine/theirs perfect、forward、backward、meetup-scheduled/now）を1ファイルでカバー
- 3タブ構造（mine / theirs / meetup）の詳細
- meetup タブの2モード（即時・日時指定）
- ステッパー UI（iter29 の数量管理）
- canProceed の判定ロジック
- 関連API：proposals 作成・送信、AW交差判定 等
- 未確定項目：5件（draft 保存タイミング、既存ネゴある相手への新規打診の振る舞い 等）

##### `notes/12_screens/C-1_receive.md`
- 受信側の画面（`C1ReceiveScreen`）
- Sender card / 提案内容カード / メッセージ / 自動添付情報 / 3択CTA
- 承諾モーダル流用 vs 専用化の議論（⚠️）
- 期限切れ・撤回・重複表示・dispute中 のエッジケース
- 未確定項目：5件

##### `notes/12_screens/C-1.5_nego_chat.md`
- 5シナリオ + 3モーダル/画面（合意確認・取引成立・相手の譲）を1ファイル
- 「現在の提案」pin card の構造
- リマインダーバナー（normal/r3/r6/expired/mine-agreed）
- システムメッセージの種別と event_type 値リスト（⚠️）
- API：messages 取得・送信、提案修正、合意送信、期限延長 等
- 未確定項目：7件（提案修正で last_action_at リセット、双方同時合意のレースコンディション 等）

##### `notes/12_screens/C-2_trade_chat.md`
- iter34 の最新仕様（場所・時間調整UI削除、当日ライブ運用集約）
- Pin card / 服装写真CTA / 4種メッセージタイプ / クイックアクション3種 / 到着ステータス
- 服装写真アップロードのバリデーション（顔ブラー等は要確認 ⚠️）
- 現在地共有の OS 権限ハンドリング
- 30分遅刻時のキャンセル権 UI（⚠️）
- 未確定項目：8件

##### `notes/12_screens/C-3_complete.md`
- 3ステップ：CaptureStep / ApproveStep / RateStep
- iter4 の「左=相手 / 右=自分」固定設計
- 撮影 → 評価まで連続した状態遷移
- 細分化評価（時間厳守・実物状態・メッセージ対応）の MVP 採用可否（⚠️）
- 内容相違時の D-flow への遷移
- 未確定項目：8件

### 影響範囲

- 設計ドキュメント全体（00-11 の構造化が更にレベルアップ）
- 実装着手の準備（API spec / 実装フェーズ分割の前提が整う）

### Phase 2 進捗

USER_PLAYBOOK タスク：
- 🥇 タスク1（05 最新化） ✅ iter38
- 🎯 5論点擦り合わせ ✅ iter39
- 🥈 タスク2（11 画面マトリクス） ✅ iter40
- 🥈 **タスク3（12_screens/ per-screen spec） ✅ iter41 ← 今回（主要5画面）**
- 🥉 タスク4（13 API spec） → 次
- 🥉 タスク5（14 実装フェーズ分割）

### 確認方法

- `notes/12_screens/README.md` から各 spec へリンク
- GitHub: https://github.com/mashimabizz/Megrum_design/tree/main/notes/12_screens

### 関連ファイル

- `notes/12_screens/README.md`（新規）
- `notes/12_screens/C-0_propose_select.md`（新規）
- `notes/12_screens/C-1_receive.md`（新規）
- `notes/12_screens/C-1.5_nego_chat.md`（新規）
- `notes/12_screens/C-2_trade_chat.md`（新規）
- `notes/12_screens/C-3_complete.md`（新規）

### 次フェーズへの示唆

タスク4（API spec）は、これら spec の「関連 API（仮）」セクションを集約してREST設計に落とす作業。
未確定項目の多くは API spec 側で確定する：
- proposal 作成タイミング（C-0）
- 承諾確認モーダルの仕様（C-1）
- system message event_type 値リスト（C-1.5）
- 服装写真・現在地アップロードの API 形状（C-2）
- 評価の細分化採用可否（C-3）

**残りの主要画面** spec は次フェーズで追加（ホーム、AW、在庫、ウィッシュ、認証/オンボ、D-flow、検索）。
ただし API spec 完成のためには現状5画面で十分。

---

## イテレーション40：画面インベントリ作成（USER_PLAYBOOK タスク2）

### 背景

USER_PLAYBOOK タスク2。
データモデル（05）と状態遷移（09）の整備が一段落したので、次は「**画面のマップ**」を作る。
- 「どの画面はどの JSX ファイル？」「いつの iter で更新された？」「関連 docs はどれ？」を一発で引けるように
- mermaid フロー図でユーザー動線を可視化
- 廃止画面も削除せず履歴として保持

### 変更内容

#### `notes/11_screen_inventory.md`（新規作成）

Megrum/*.html の `<DCArtboard>` を全スキャン、Megrum/*.jsx の `function` 定義をクロスリファレンス。

**収録**：
- 最新画面 **89件**（5カテゴリ：認証/オンボ・主要フロー・ハブ・サポート設定・図鑑）
- 廃止画面 **12件**（J. セクションに保持）

**画面ID命名規約**：
- 3-4文字 prefix ＋ kebab-case 名（`AUTH-welcome`, `C0-mine-perfect`, `D-5a` 等）
- 実装でも同じ識別子を使うため、命名で揺れない

**マトリクスの列**：画面ID / 名称 / 関連JSX関数 / 関連iter / 関連docs

**収録した mermaid フロー図 4種**：
1. **F. メイン動線フロー図** — ユーザー全体ジャーニー（auth → onb → home → 各タブ → C-flow → C-3 → 図鑑）
2. **G. 取引フロー詳細図** — C-0 → C-1 → C-1.5 → 合意 → C-2 → C-3 の細かい状態遷移付き
3. **H. Dispute フロー詳細図** — D-flow（D-1〜D-6d、再審査含む）
4. **I. 認証・オンボフロー図** — Welcome → Sign-up/Login → Email認証 → オンボ5段階 → Home

### 影響範囲

- 設計ドキュメント全体（5種類が揃った：00-04 戦略・要件 / 05 データ / 09 状態 / 10 用語 / **11 画面**）
- 実装着手の準備（per-screen spec 作成のための土台）

### Phase 2 進捗

USER_PLAYBOOK タスク：
- 🥇 タスク1（05 最新化） ✅ iter38
- 🎯 5論点擦り合わせ ✅ iter39
- 🥈 **タスク2（11 画面マトリクス） ✅ iter40 ← 今回**
- 🥈 タスク3（12_screens/ per-screen spec）→ 次
- 🥉 タスク4（13 API spec）
- 🥉 タスク5（14 実装フェーズ分割）

### 確認方法

- `notes/11_screen_inventory.md`
- mermaid 図は GitHub 上で自動レンダリング：https://github.com/mashimabizz/Megrum_design/blob/main/notes/11_screen_inventory.md

### 関連ファイル

- `notes/11_screen_inventory.md`（新規）

### 次フェーズへの示唆

`12_screens/` 着手時：
- まず重要画面（C-0 / C-1 / C-1.5 / C-2 / C-3）から per-screen spec を作る
- 各画面ファイル名は `notes/12_screens/[画面ID].md`（例：`C0-mine-perfect.md`）
- 各 spec は state / props / 入出力 / バリデーション / エラー / 関連API / 関連docs を網羅
- 89画面全部書くのは重いので、**重要15-20画面に絞ってから**残りは実装着手と並行で

---

## イテレーション39：データモデル擦り合わせ・5論点確定

### 背景

iter38 で `05_data_model.md` を v2 化し、未確定項目30件を整理した。
そのうち**実装着手前に最重要の5項目**を擦り合わせる必要があり、ユーザーと対話で決定。

### 確定内容

| # | 論点 | 確定 |
|---|---|---|
| 1 | Item の `kind=keep` は `in_negotiation` になりうるか | **🅰️ 完全分離**：ならない。譲りたくなったら `kind` を `for_trade` に変更してから |
| 2 | `meetup_scheduled_custom` を JSONB か別テーブルか | **🅰️ JSONB**（MVP段階）。将来検索性が必要なら別テーブル `proposal_meetups` に切り出し可 |
| 3 | `outfit_photo` を messages 内 vs 専用テーブル | **🅲️ 両方**：`deal_outfit_photos` で最新版管理＋`messages.message_type='system'` で「共有しました」を流す |
| 4 | 到着検知の仕組み | **🅰️ 手動のみ（MVP）**：「会場到着」ボタン。QR連動・GPS自動は Post-MVP |
| 5 | `disputes.resolution.decision` 値リスト | **推奨全部**：5値（sender_fault/receiver_fault/mutual_fault/no_fault/cant_determine）+ penalty 4段階（none/warning/temp_suspend/permanent_suspend）+ reason/next_steps |

### 変更ファイル

#### `notes/05_data_model.md`
- 5論点それぞれの該当セクションに `🔒 確定（iter39）` ブロック追加
- `user_haves` セクション：kind と status の組合せ制約を明示（`keep` × `in_negotiation` 禁止）
- `proposals.meetup_scheduled_custom`：JSONB 確定の注釈
- `deal_outfit_photos`：2層構成の運用説明（専用テーブル＋system message）
- `deal_arrivals`：MVPは `manual` のみ、Post-MVP で QR/GPS 検討
- `disputes.resolution`：JSONB 構造を完全定義（5+4 値表＋テンプレ）
- 末尾「⚠️ 未確定項目」表：5件を「✅ iter39 で確定済」に分離

#### `notes/09_state_machines.md`
- 末尾「未確定・要確認項目」表：該当する5件を「✅ iter39 で確定済」セクションへ移動

#### `notes/10_glossary.md`
- セクション H（ステータス・状態）に enum 値の正式リスト追加：
  - **Dispute resolution**：decision 5値、penalty 4値（iter39 確定）
  - **Message types**：text / image / outfit_photo / location_share / system
  - **Item kind**：for_trade / keep（制約付き）
  - **Match types**：perfect / forward / backward
  - **Meetup type**：now / scheduled

### 影響範囲

- データモデル全体（5箇所の確定 → 実装ブレ防止）
- 用語集（enum 値が辞書化され、実装で勝手に値追加するのを防止）

### 確認方法

- `notes/05_data_model.md` の 🔒 ブロックを検索
- `notes/10_glossary.md` セクション H の追加部分を確認

### 関連ファイル

- `notes/05_data_model.md`
- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### 残未確定項目

25件。次フェーズ（USER_PLAYBOOK タスク2-7）で詳細化される過程で順次解決される予定。
特にPhase 2 タスク3（per-screen spec）でいくつか自然に決まる：
- `proposal_revisions` の履歴粒度（実装してみると粒度が見える）
- system message の `event_type` 値リスト（メッセージ画面の実装で確定）
- `cancelled_reason` の値リスト（C-2 キャンセルUI設計で確定）

---

## イテレーション38：データモデル v2 — iter24/29/33/34 反映

### 背景・問題意識

`notes/05_data_model.md` は v1（2026-04-27時点）のままで、**iter24（推し2階層）/ iter29（数量管理）/ iter33（meetup）/ iter34（服装写真・現在地）の更新が一切反映されていなかった**。

USER_PLAYBOOK のタスク1。実装着手の最終整備として、最新仕様をDBスキーマレベルに落とし込む。

### 変更内容

#### `notes/05_data_model.md` — 全面書き直し（v2.0）

旧版（232行）→ 新版（複数セクション、テーブル定義15+、未確定項目30件）

主な変更：

1. **状態名を 09_state_machines.md と完全整合**
   - 旧 `proposals.status: 'sent' / 'accepted' / 'rejected' / 'cancelled'`
   - 新 `proposals.status: 'draft' / 'sent' / 'negotiating' / 'agreement_one_side' / 'agreed' / 'rejected' / 'expired'`
   - 旧 `user_haves.status: 'active' / 'reserved' / 'traded'`
   - 新 `user_haves.status: 'available' / 'in_negotiation' / 'in_deal' / 'traded'` ＋ `kind: 'for_trade' / 'keep'` 分離（iter19.5）

2. **テーブル名を 10_glossary.md と整合**
   - 旧 `exchanges` → 新 `deals`（用語集が `deal` 推奨）

3. **iter28（match_type）対応**
   - `proposals.match_type: 'perfect' / 'forward' / 'backward'`

4. **iter29（数量管理）反映**
   - `proposals.sender_have_qtys: int[]` / `receiver_have_qtys: int[]` を追加
   - 1行=1個 の方針を本文で明示、UI集約と数量選択の関係を整理

5. **iter30（7日期限）反映**
   - `proposals.last_action_at` / `expires_at` / `extension_count` カラム追加
   - `proposal_revisions` テーブル新規（提案修正履歴）

6. **iter32（合意フロー）反映**
   - `proposals.agreed_by_sender` / `agreed_by_receiver` カラム追加（agreement_one_side 判定用）

7. **iter33（meetup）反映 — 最大の変更**
   - `proposals.meetup_type`（`now` / `scheduled`）必須化
   - `proposals.meetup_now_minutes`（5/10/15/30）
   - `proposals.meetup_scheduled_aw_id` → `availability_windows`
   - `proposals.meetup_scheduled_custom` JSONB（カスタム日時の date/time/lat/lng/place_name/register_as_aw）
   - `availability_windows.created_via`（`manual` / `auto_from_proposal`）
   - `availability_windows.created_from_proposal_id`（auto AW のトレース）

8. **iter34（C-2 ライブ運用）反映**
   - `messages.message_type` 拡張（`text` / `image` / `outfit_photo` / `location_share` / `system`）
   - `messages.metadata` JSONB（位置情報・systemイベント等）
   - `deals.status` 細分化（`agreed` / `on_the_way` / `arrived_one` / `arrived_both` / `evidence_captured` / `approved` / `rated` / `disputed` / `cancelled`）
   - `deal_arrivals` テーブル新規（到着ステータス追跡）
   - `deal_outfit_photos` テーブル新規（服装写真、専用化案）

9. **iter24（推し2階層）反映**
   - `user_oshi` テーブル新規（DD/箱推し対応）
   - `groups_master.kind`（'group' / 'work' / 'solo'、ソロアーティスト対応）

10. **D-flow（iter12-18）対応**
    - `disputes` テーブル新規（旧版未定義だった）
    - `dispute_replies` テーブル新規
    - `reports` テーブル新規（通報用）

11. **users 拡張**
    - `account_status`（09 Account Lifecycle と一致）
    - OAuth対応カラム（oauth_provider/subject）
    - `deletion_requested_at`（30日猶予の起点）

12. **付録：状態名の対応表**
    - 09 のすべての状態名と、05 のどのカラム値に対応するかをテーブルで明示
    - 命名変更時の同期忘れ防止

#### `notes/09_state_machines.md` — 未確定項目を拡張

5項目 → 18項目に拡張。3カテゴリに分類：
- 状態遷移ルール関連（11項目）
- 検知・トリガー関連（3項目）
- データ構造関連（4項目）

これらは `05_data_model.md` の30項目「⚠️ 未確定項目」とクロスリファレンス。

### 影響範囲

- データモデル全体（テーブル定義15+件、未確定項目30件）
- 状態名の整合性（09 ↔ 05）
- 用語整合性（10 ↔ 05、`deal` / `exchange` 問題）

### 確認方法

- `notes/05_data_model.md` を読む
- `notes/09_state_machines.md` 末尾の未確定項目表を確認
- 付録「状態名の対応表」で 09 と 05 の整合確認

### 関連ファイル

- `notes/05_data_model.md`（全面書き直し）
- `notes/09_state_machines.md`（未確定項目拡張）

### 次フェーズへの示唆（実装着手前の擦り合わせ項目）

特に重要な擦り合わせポイント：
1. **Item の `kind` と `status` の関係**（keep が in_negotiation になりうるか）
2. **proposals.meetup_scheduled_custom** を JSONB か別テーブルか（性能と正規化のバランス）
3. **outfit_photo を messages 内 vs 専用テーブル** どちらが運用しやすいか
4. **到着検知の仕組み**（プライバシー観点で慎重判断）
5. **disputes の resolution.decision 値リスト** 確定（仲裁ルール）

これら30項目を整理した次のタスクとして「USER_PLAYBOOK タスク2: 11_screen_inventory.md」 → タスク3: per-screen spec を進めれば、未確定項目が画面別に分解されてさらに具体化される。

---

## イテレーション37：USER_PLAYBOOK 作成（オーナー向け作業手順書）

### 背景・問題意識

iter36 でGitHub移行・スマホClaude ワークフロー基盤が整ったが、ユーザーから：
- **「Phase 2 の準備を進めるなら、スマホから何を指示して何をチェックすればいい？」**

という実務的な疑問。CLAUDE.md は Claude 向け、README.md は一般向け、で「**オーナーが次に何をすべきか分かるドキュメント**」が無かった。

### 変更内容

#### `notes/USER_PLAYBOOK.md` 新規作成
- Phase 2 タスク一覧（優先順 + 依存関係）
- 各タスクのスマホ指示テンプレート（コピペ可）
- 各タスクのチェックポイント
- 共通チェックポイント（用語整合・状態整合・⚠️要確認の正直さ・iter記録）
- スマホ vs PC 使い分けガイド
- スマホ指示のコツ（3原則、良い例・悪い例）
- トラブルシューティング
- 次にやること判断フロー

タスクは7件：
1. 🥇 05_data_model.md 最新化（iter24-34反映）
2. 🥈 11_screen_inventory.md 新規（画面マトリクス）
3. 🥈 12_screens/ 新規（per-screen spec、主要5画面から）
4. 🥉 13_api_spec.md 新規（API仕様）
5. 🥉 14_implementation_phases.md 新規（フェーズ分割）
6. 🟡 15_non_functional.md 新規（非機能要件）
7. 🟡 02_system_requirements.md 更新（iter24-34反映）

#### `CLAUDE.md` 更新
- 「⚠️ Claude が動作する前に必ずすること」に **5. オーナーがタスク的指示をした場合は USER_PLAYBOOK.md を確認**を追加
- ファイル構造マップに `USER_PLAYBOOK.md` を追加

#### `index.html` 更新
- ヘッダー導線に「📘 USER PLAYBOOK」ボタン追加
- 設計ドキュメントセクションに USER_PLAYBOOK.md カード追加

### 影響範囲

- ドキュメンテーション体系（用途別の3層化が完成）
  - `README.md`：一般来訪者向け
  - `CLAUDE.md`：Claudeセッション向け
  - `USER_PLAYBOOK.md`：オーナー向け
- スマホからの作業効率（テンプレ化で立ち上がりが早い）

### 確認方法

- リポジトリ：https://github.com/mashimabizz/Megrum_design/blob/main/notes/USER_PLAYBOOK.md
- ランディングページからもアクセス可：https://mashimabizz.github.io/Megrum_design/

### 関連ファイル

- `notes/USER_PLAYBOOK.md`（新規）
- `CLAUDE.md`
- `index.html`

### 次の Claude セッションへの示唆

- オーナーから「タスク◯◯を進めて」と言われたら、**USER_PLAYBOOK.md の該当セクションをまず読む**
- そこに書かれた指示テンプレ・チェックポイントに従って動作すれば品質が安定する

---

## イテレーション36：GitHub移行・CLAUDE.md強化・スマホ Claude ワークフロー整備

### 背景・問題意識

iPhoneからもClaudeに指示出ししたい、というユーザー要望。
当初は GitHub Issue 経由のワークフローを想定したが、claude.ai mobile が GitHub 直結できることが判明。
→ ワークフローの重心を「スマホ Claude が CLAUDE.md だけ読んで動ける」状態にシフト。

### 変更内容

#### GitHub 移行
- `mashimabizz/Megrum_design` リポジトリ新設（既存の `Megrum_renewal` とは分離）
- ローカル git 初期化、初期コミット 56ファイル push
- `gh` CLI を `~/.local/bin/gh` に直接インストール（Homebrew不要）
- `gh auth login` で認証完了
- credential helper 設定で次回以降の push 自動化

#### `CLAUDE.md` 強化（workflow-rich 化）
- **環境差分セクション**新設：PC（Claude Code）vs スマホ（claude.ai）でできること・できないことを明示
- **A. 設計・実装変更時のチェックリスト**を厳守事項として追加（07ステップ）
- **B. iteration エントリの形式**テンプレ追加
- **C-E. 用語追加・廃止・commit形式**のテンプレ追加
- **GitHub Pages URL** をスマホプレビュー用として記載
- **PC で便利なスラッシュコマンド**セクション追加

#### `/iter` スラッシュコマンド新設（PC専用）
- `.claude/commands/iter.md` 作成
- 設計変更を `notes/08` に記録 + `09`/`10` 更新診断 + commit までを自動化
- スマホ Claude では効かないので、CLAUDE.md のチェックリストを手動で踏む前提

#### `.gitignore` 修正
- 旧：`.claude/` 全体を ignore
- 新：`.claude/settings.local.json` と `.claude/cache/` のみ ignore
- → `commands/` `skills/` `agents/` は今後も含めて track できるように

#### PATH 設定
- `~/.zshrc` に `export PATH="$HOME/.local/bin:$PATH"` 追加
- 次回ターミナル起動から `gh` をフルパス指定不要

#### GitHub Pages 有効化
- `gh api repos/mashimabizz/Megrum_design/pages -X POST` で API 経由有効化
- URL: `https://mashimabizz.github.io/Megrum_design/`
- スマホ・他環境からプレビュー可能に

### 影響範囲

- リポジトリ全体（git管理化）
- 全 Claude セッション（PC/スマホ問わず CLAUDE.md を参照）
- ドキュメンテーション規律（チェックリスト厳守）

### 確認方法

- リポジトリ: https://github.com/mashimabizz/Megrum_design
- GitHub Pages: https://mashimabizz.github.io/Megrum_design/Megrum/Megrum%20MVP%20v1.html （ビルド完了まで数分かかる）
- ローカル: `python3 -m http.server 8000`

### 関連ファイル

- `CLAUDE.md`
- `README.md`
- `.gitignore`
- `.claude/commands/iter.md`
- `~/.zshrc`（ローカル、track外）

### 次フェーズへの示唆

- Phase 2 の `05_data_model.md` 更新を、スマホからでも Claude に依頼できるようになった
- 重要な workflow rule は CLAUDE.md にあるので、別環境でも同じ規律で動作する
- スマホで作業した内容も `[iter◯◯]` 形式で commit すれば履歴一元化される

---

## イテレーション35：再現可能性のための設計ドキュメント整備（state machines ＋ glossary）

### 背景・問題意識

実装フェーズ移行を前にした課題提起：
- **「これから実装に入るが、デザイン通りに作って欲しい」**
- **「環境が変わっても再現できるようにしたい」**
- **「デザインは手段の一つ。基本設計・詳細設計をちゃんと作っておきたい」**

JSX mockup が80画面以上あり完成度は高いが、それだけでは：
- 振る舞い・状態遷移・データ・ルールが暗黙的
- エッジケース・バリデーションが不明
- 別環境（別Claudeセッション・別エンジニア）で再現困難

### 不足層の特定

```
要件定義      ⭕ 既存 00, 01, 03, 06（ただし iter後の更新が必要）
基本設計 (HLD) ❌ 未整備（状態遷移・画面遷移・用語集・非機能）
詳細設計 (LLD) △ 部分的（05_data_model のみ、最新化必要）
実装計画      ❌ 未整備
```

### ROI 順での書く優先順位

1. 🥇 **状態遷移図** — 実装ブレを最も防ぐ
2. 🥈 **データモデル更新** — 全機能の土台（既存 05 を最新化）
3. 🥉 **用語集** — 一貫性の鍵
4. 画面遷移図
5. 画面仕様書（per-screen）
6. API 仕様
7. 実装計画

### 今回のスコープ（Phase 1 の最重要のみ）

🥇 と 🥉 だけ先行実装。これだけで再現可能性の80%確保が狙い。

#### `notes/09_state_machines.md` 新規作成
- 7つのライフサイクル（Proposal / Deal / Dispute / AW / Item / Wish / Account）
- 各エンティティに mermaid 状態図 + 状態定義 + 主要トリガー + ビジネスルール + 関連画面・ファイル
- エンティティ間の関係図
- 未確定・要確認項目を明記（ネゴ提案修正の期限カウンタ等5項目）

#### `notes/10_glossary.md` 新規作成
- 11カテゴリ（プラットフォーム概念／ユーザー・推し／グッズ／取引・プロセス／マッチング／場所・時間／画面識別子／ステータス／ルール・SLA／廃止用語／表記揺れ）
- 廃止用語セクション（コレクション在庫タブ／推し一致バッジ／QR の C-1.5 配置 等）を独立化、過去の判断を消さずに残す
- 表記揺れに迷う用語の使い分けルール（譲／求／待ち合わせ／ネゴ／打診／取引）

### 設計方針

- **markdown 中心** — 環境非依存、Claude が読み書きしやすい
- **mermaid 記法** — 状態図・ER図がコード化できる、GitHub でも描画される
- **Single source of truth** — 仕様 → デザイン → コード のリンクを張る（cross-reference）
- **更新ルールを明記** — 「デザイン変更したら該当 spec も更新」をプロセス化
- **新規Claudeセッションは最初にこのドキュメントを読む**ようプロンプトに含める想定

### 次フェーズの予定

Phase 2（後日）：
- `05_data_model.md` の最新化（iter24-34 の変更反映）
- `11_screen_inventory.md`（画面一覧＋遷移マトリクス）
- `12_screens/` ディレクトリ（per-screen spec）
- `13_api_spec.md`
- `14_implementation_phases.md`（フェーズ分割）

### 確認方法

- `notes/09_state_machines.md`
- `notes/10_glossary.md`

### ユーザー判断

- A 案（🥇🥉 のみ先行）を採用
- 「数日後に他もやる」前提で、今回は最小コスト最大効果に絞る

---

## イテレーション34：C-2 取引チャットの役割再定義（当日ライブ運用へ集約）

### 背景
イテレーション33で待ち合わせをC-0/C-1.5 に前倒ししたため、C-2 から場所提案カード・時刻チップ調整UIが不要になった。役割を「当日のライブ連絡＋合流＋証跡撮影への入口」に絞り込む。

### 削除した旧UI
- 場所提案カード（mini map ＋ OK/別を提案）— C-0で確定済
- 時刻チップ（18:50 / 19:00 / 19:10 / 19:20）— C-0で確定済

### 新C-2の構成

#### ① ヘッダー：到着ステータス表示
- アクティブ表示を「会場到着済（緑）／移動中（橙）」のステータスに置き換え
- 距離 169m を併記

#### ② Pinned card：取引内容＋確定済の待ち合わせ
- 上部固定（`borderBottom`）。取引アイテム両側＋日時＋場所＋mini map（92×60px 横並び）
- 「合意済」緑バッジで視覚的に確定状態を強調

#### ③ 服装写真をシェア CTA（強調）
- 紫→水色グラデの目立つカード（`linear-gradient(135deg, lavender, sky)`）
- 大きい 👕 アイコン＋装飾サークル
- あなた／相手の共有ステータスを2列で可視化（未シェア／✓ 共有済）
- 大きい白背景の「服装写真を撮影してシェア」ボタン
- 自分が共有済になると消える条件レンダリング（`!myOutfitShared && ...`）

#### ④ メッセージ領域
- 服装写真メッセージ（image bubble、紫ロンT＋トートバッグの SVGシルエット例）
- 現在地共有メッセージ（mini map付きbubble、自分位置・相手位置・待ち合わせ地点を3点表示）
- 「@lumi_sua が会場に到着しました」システムメッセージ（緑pillスタイル）
- 既存の「合流したら証跡を撮影」CTAチップは維持

#### ⑤ Composer 上部にクイックアクション行
- 📍 現在地を送る（lavender系ハイライト）
- 👕 服装写真（pink系ハイライト）
- 🖼️ 写真添付（subtle系）
- 横スクロール可能（`overflowX: 'auto'`）

### 新規追加ヘルパー
- `CF_MiniMap`: 俯瞰図 + 中央ピン + 任意で you/partner ピン3点表示

### 動線確認
```
合意 → C-2 開く
 ├ Pin card：取引内容＋待ち合わせ（常時参照）
 ├ 強調CTA：服装写真をシェア（合流支援）
 ├ Quick actions：現在地送信／服装写真／写真添付
 ├ Header：相手の到着ステータス
 └ 合流後：証跡撮影 → C-3
```

### 変更ファイル
- `Megrum/c-flow.jsx`：ChatScreen を完全書き換え、`CF_MiniMap` ヘルパー追加
- `Megrum/Megrum C Flow.html`：C-2 アートボードラベル更新

### 確認方法
http://localhost:8000/Megrum%20C%20Flow.html

### ユーザー要望（実装方針の決定）
- 遅刻通知は**実装しない**（ユーザー判断：「遅刻は別に大丈夫です」）
- 服装写真は**目立たせる**（ユーザー要望：「服装写真をアップする導線をもっと目立たせたい」）
- 現在地共有：**そのまま送れる**機能（ユーザー要望：「現在地をそのまま送れたらいい」）

---

## イテレーション33：待ち合わせ（meetup）を合意前にfix・AW連携・マップ表示

### 背景・問題意識
- 旧フロー：合意成立 → C-2 取引チャットで合流場所・時間を相談、というフロー
- 課題：合意したのに当日が合わない／場所がfixできず流れる、というリスクが残る
- ユーザー要望：「合流時刻も合意前にFixしておきたい。その場ですぐ、という場合もあれば、事前に何時くらい、という感じでFixしたい場合もあるでしょう」

### 解決方針：合意 = アイテム + 待ち合わせ（日時・場所） を一体で確定
1. **C-0 提示物選択画面に「📍 待ち合わせ」を3番目のタブとして追加**
2. **2モード切替**：
   - 🚀 **いますぐ**：5/10/15/30分以内チップ＋現在地周辺の合流場所＋マップ
   - 📅 **日時指定**：登録済AWから選択 OR カスタム日時＋AW自動登録チェックボックス
3. **AW連携**：
   - 自分のAWリスト（aw-edit.jsxと同概念）から候補選択
   - 相手と被るAWは「★ 相手と一致」バッジ
   - カスタム入力時は ☑ AW自動登録 で次回マッチングにも活用
4. **マップ表示**：「いつもなんちゃらドームとかで待ち合わせするわけではない」ので、mini map（俯瞰図 + 中央ピン）で場所を可視化

### 影響画面（変更ファイル）

#### `Megrum/propose-select.jsx`
- `ProposeSelectScreen` に `initialMeetupType` プロパティを追加
- タブを2 → 3個に拡張（私が出す / 受け取る / 待ち合わせ）
- 待ち合わせタブのカウントバッジは ✓（緑）or !（warn色）で表示
- 即時/日時指定で完全に分岐したUI
- 日時指定モード：登録済AW radio list ＋ OR ＋ カスタム日時カード
- カスタム日時：日付・時刻・場所 + 自動登録 checkbox（デフォルトON）
- 選択中AWのmap preview（場所変更が頻繁なため）
- ボトム summary に待ち合わせ行を追加（提示物summary + 待ち合わせsummary）
- canProceed = 提示物両側 ＋ 待ち合わせ設定済 をすべて満たす
- `PS_MiniMap` ヘルパーSVGコンポーネント新設（俯瞰図 + 中央ピン + ラベル）

#### `Megrum/Megrum Propose Select.html`
- ⑤「日時指定モード」⑥「即時モード」のアートボード追加（DCSection: meetup）

#### `Megrum/nego-flow.jsx`
- `NF_MiniMap` ヘルパーSVGコンポーネント新設
- **C-1受信**：「📩 提案内容」カード末尾に「📍 待ち合わせ」セクション追加（日時 + 場所 + AW一致バッジ + mini map）。「自動添付情報」から「推奨合流ポイント」を削除（提案に含まれるため）
- **C-1.5 ネゴチャット**：「現在の提案」カードに、提示物の下に dashed divider + 横並び（mini map ＋ 日時/場所テキスト）の待ち合わせブロック追加。常に視認できる
- **合意確認モーダル**：取引内容カードと別に「📍 待ち合わせ」カード（pinkグラデ背景）を追加。日時・場所・mini map を中央配置で大きく表示。注意文を「アイテム・日時・場所の変更不可」に拡張
- **取引成立画面**：「次のステップ」前に「📍 確定した待ち合わせ」カードを大きく配置（白bg + lavender border + box-shadow）。日時を 18px で大きく、mini map 100px、「カレンダーに追加」ボタン付き。次のステップは合流前提で簡潔化（旧「合流場所・時間を決める」→新「当日決まった場所・時間で合流」）

### 設計判断
- **デフォルトモードは「日時指定」**：MVPの主用途（事前計画した同担と現地で交換）に合わせる
- **AW自動登録checkboxはデフォルトON**：Megrumの中核データ（AW）を増やす導線として
- **マップは「いつも有名会場ではない」前提**：駅前・カフェなど任意の場所でも視覚的に確認可能なよう、SVG俯瞰図ベースで作成
- **map表示は全proposal cardで一貫**：C-1 / C-1.5 / 合意確認 / 取引成立 すべてで mini map を表示し、迷いをゼロに

### 動線（更新後）
```
C-0 提示物＋待ち合わせ選択（3タブ）
  → C-1 打診送信
    → C-1.5 ネゴチャット（待ち合わせも交渉対象）
      → 合意確認モーダル（最終確認）
        → 取引成立画面（待ち合わせ確定情報を強調）
          → C-2 取引チャット（最終調整・現地連絡）
            → C-3 物理交換 → 評価
```

### 確認方法
- http://localhost:8000/Megrum%20Propose%20Select.html （⑤⑥が新設）
- http://localhost:8000/Megrum%20Nego%20Flow.html （①C-1 / ②C-1.5 / ⑦合意確認 / ⑧取引成立 すべてに meetup 反映）

---

## イテレーション32.5：C-1.5 ネゴチャットからQRボタン削除

### 背景
ネゴ中（合流前）にQR本人確認は文脈的に不要。QRは合流時の本人確認用なので、C-2取引チャット（合流場所・時間確定後）にのみあるべき。

### 修正内容
- nego-flow.jsx の C15NegoChatScreen ヘッダーから QR ボタンを削除（全状態 ②〜⑥）
- C-2 ChatScreen の QR は維持

---

## イテレーション32：合意フロー追加（合意送信前モーダル / 合意済状態 / 取引成立画面）

### 追加内容
1. **合意送信前モーダル**（ボトムシート、誤タップ防止）
2. **「あなた合意済・相手の合意待ち」状態のC-1.5**（disable CTA + システムメッセージ + 状態バッジ）
3. **取引成立画面**（紙吹雪＋スパークル＋取引内容＋次のステップ3つ＋C-2へCTA）

### 動線
合意して受諾 → 確認モーダル → 合意送信
  ├ 相手未合意 → C-1.5「あなた合意済」状態で待機
  └ 双方合意 → 取引成立画面（リッチ演出）→ C-2

### 実装ファイル
- `Megrum/nego-flow.jsx`：C15AgreementConfirmModal / C15AgreementSuccess を追加、C15NegoChatScreen に 'mine-agreed' scenario 追加
- `Megrum/Megrum Nego Flow.html`：⑥⑦⑧アートボード追加

### 確認方法
http://localhost:8000/Megrum%20Nego%20Flow.html

---

## イテレーション31：C-1.5 ネゴチャットの整理

### 修正
- クイックアクション横スクロール（相手の譲 / 自分の譲 / 提案修正 / 写真添付）**全削除**
- 「現在の提案」カード右上に **「✏️ 編集」ボタン**追加（C-0 編集モードへ）
- 「+」ボタンに通常のチャット機能を集約（写真・提案修正）

### 結果
LINE等の標準的なチャットUIに近い構造、機能性を維持しつつ冗長要素を削除。

---

## イテレーション30：受諾前ネゴシエーションフロー（C-1受信 / C-1.5 / モーダル）

### 背景
打診送信 → 即受諾/拒否 の二択は柔軟性に欠けた。
「他のグッズと交換できないか」「相手の他の譲を見たい」というネゴ需要に対応。

### 実装ファイル
- `Megrum/nego-flow.jsx`：3コンポーネント（C1ReceiveScreen / C15NegoChatScreen / PartnerInventoryModal）
- `Megrum/Megrum Nego Flow.html`

### 画面構成
1. **C-1受信**：相手側の打診受信画面（承諾 / 反対提案 / 拒否 の3択）
2. **C-1.5 ネゴチャット**（4状態）：
   - 通常 / 3日目リマインド / 6日目リマインド / 期限切れ
   - 上部に「現在の提案」固定カード（変更箇所ハイライト）
   - クイックアクション（相手の譲 / 自分の譲 / 提案修正 / 写真添付）
   - 双方が「合意して受諾」で C-2 へ
3. **相手の譲モーダル**：ネゴ中に参照（wish一致＋提案中バッジ）

### 期限管理
- 総期限：7日
- リマインド：3日目・6日目
- 期限切れ：自動クローズ（拒否ではなく「期限切れ」状態）
- 延長：「+7日延長」ボタン（何回でも）

### 確認方法
http://localhost:8000/Megrum%20Nego%20Flow.html

---

## イテレーション29：C-0 提示物選択に数量ステッパー追加

### 背景
同じグッズを在庫×3持っていても「全部出すか / 1個だけ出すか」を選べなかった。
ヲタ実態：だぶり前提のグッズで、何個提示するかは細かく決めたい。

### 修正内容
- propose-select.jsx の各アイテムに数量ステッパー `[− N/max +]` 追加
- チェックON時：自動で最大数（在庫の qty）に設定
- 在庫×1 のアイテムはステッパー非表示（「選択中 ×1」表記のみ）
- 上限・下限に達したらボタンがdisabled
- 下部サマリ・タブバッジを「合計枚数」で表示
- アイテム数 → 枚数集計（複数枚提示が反映）

### 確認方法
http://localhost:8000/Megrum%20Propose%20Select.html

---

## イテレーション28：C-0 提示物選択を両側選択可能に拡張

### 背景
完全マッチ・片方向マッチ問わず、「ウィッシュリスト全部が自動で交換対象になる」のは柔軟性に欠ける。
ユーザーが具体的なアイテムを個別に選びたいニーズに対応。

### 修正内容
- propose-select.jsx を**両側選択可能**に再設計
- タブ切替（私が出す / 私が受け取る）で独立編集
- pre-check は「推奨」のみ、ユーザーが自由に追加・解除
- 下部にbothサマリ常時表示
- シナリオ別 pre-check ロジック（full / forward / backward）

### 4アートボードで全パターン表示
- ① 完全マッチ・私が出すタブ
- ② 完全マッチ・私が受け取るタブ
- ③ Forward 片方向
- ④ Backward 片方向

### 確認方法
http://localhost:8000/Megrum%20Propose%20Select.html

---

## イテレーション27：C-0 提示物選択画面（片方向マッチ用打診ステップ）

### 背景
打診フロー（C-1）は完全マッチ前提で「両者の交換物が予め確定」している前提だった。
片方向マッチ（私が欲しい譲を持つ人 / 私の譲が欲しい人）から打診する時、片側を自分で選ぶステップが欠けていた。

### 実装ファイル
- `Megrum/propose-select.jsx`：C-0 ProposeSelectScreen（forward/backward両対応）
- `Megrum/Megrum Propose Select.html`

### 画面構成
- **Forward**：「私が欲しい譲を持つ人」から打診 → 提示する譲を選ぶ
- **Backward**：「私の譲が欲しい人」から打診 → 相手から欲しいものを選ぶ
- 共通：固定カード（決定済の側）＋ 一覧（選ぶ側）＋ ★wish一致バッジ＋ 複数選択＋ 選択サマリ

### 動線（更新）
- 完全マッチ：[打診する] → C-1 → C-1' → 送信
- 片方向マッチ：[打診する] → **C-0 提示物選択** → C-1 → C-1' → 送信

### 確認方法
http://localhost:8000/Megrum%20Propose%20Select.html

---

## イテレーション26：マッチカードの「推し一致」バッジ削除

### 背景
マッチカードの「推し一致」バッジは、マッチングロジック（譲×求＋AW時空交差）に直結しない装飾的な情報だった。同担拒否派にとっては逆効果になる場面もあり、認知負荷の割にUX価値が薄いと判断。

### 修正内容
- `home-v2.jsx` の MatchCard から **「推し一致」バッジを削除**
- 未使用となった `oshiMatch` 変数も削除（クリーンアップ）
- 残るバッジ：`COMPLETE`（完全マッチ）、`同イベント`（AW一致）

### 結果
カードの認知負荷↓、マッチ判断に直結する情報だけが残る構成に。

---

## イテレーション25：フィルタ「推し」を未登録推しまで拡張

### 問題
フィルタ画面の「推し」セクションが、自分の登録済み推しのみで絞り込み可能だった。
未登録の推し（他のグループ・作品）でも検索したいニーズに対応できなかった。

### 修正内容
- `search-filter.jsx` の FilterScreen に追加：
  - 検索バー（グループ・作品・キャラ名で検索）
  - 「あなたの推し」セクション（ピンクバッジで強調）
  - **「他の推しから検索」セクション**（新規追加）
    - ジャンルタブ：K-POP / アニメ / ゲーム / 2.5次元 / VTuber / 邦アイ
    - 各ジャンルの人気グループ・作品リスト
    - 運営への追加リクエスト

---

## イテレーション24：推しの2階層構造をUIに明示

### 問題
データモデル（genres → groups → characters）は3階層だが、フィルタチップやマッチカードのUIで階層が見えない箇所があった。

### 修正内容
- **search-filter.jsx**：フィルタ画面「推し」セクションを**ジャンルバッジ＋グループ名＋インデントされたメンバー**の階層表示に
- **b-inventory.jsx**：フィルタチップを「推し」と「種別」の**2軸に分離**（譲るもの・求めるもの両方）
- マッチカードのバッジ詳細化（C案）は保留 ─ ホーム画面サンプル見て判断

### 確認方法
- http://localhost:8000/Megrum%20Search%20Filter.html （画面② フィルタ）
- http://localhost:8000/Megrum%20B%20Inventory.html

---

## イテレーション23：検索・フィルタ・保存検索（3画面）

### 背景
ホーム画面の🔍と⚙️アイコンの先が未実装、「探索」タブの中身も未定義。
ユーザーがマッチ条件をカスタマイズできるように検索・フィルタ機能を追加。

### 実装ファイル
- `Megrum/search-filter.jsx`：3画面
- `Megrum/Megrum Search Filter.html`

### 画面構成
1. **検索画面** ─ キーワード検索＋クイックフィルタ＋結果＋履歴＋人気
2. **フィルタ画面** ─ 距離/推し/種別/状態/★/取引実績/マッチ強度/並び替え＋保存CTA
3. **保存検索リスト** ─ ピン留め・ワンタップ適用・件数バッジ・件数0時の分岐

### 確認方法
http://localhost:8000/Megrum%20Search%20Filter.html

---

## イテレーション22：プロフ補助 Phase 2（8画面）

### 実装ファイル
- `Megrum/account-extras.jsx`：8画面
- `Megrum/Megrum Profile Extras.html`

### 画面構成
1. プロフィール編集（アイコン・ハンドル・自己紹介・性別・活動エリア・服装写真）
2. 推し設定編集（複数推し管理・メンバー追加削除）
3. ブロックリスト（理由表示・解除）
4. 在庫の公開設定（全部公開モデル＋休止モード）
5. 他人のプロフィール表示（マッチから遷移先・統計＋AW＋CTA）
6. 本人確認（メール認証バッジ＋追加オプション）
7. アプリ情報（バージョン・法的情報リンク・コピーライト）
8. アカウント削除完了（データ一覧＋7年保管注記＋再登録）

### 確認方法
http://localhost:8000/Megrum%20Profile%20Extras.html

---

## イテレーション21：法的画面 Phase 1（利用規約・プライバシーポリシー・特商法）

### 背景
設定メニューに「利用規約／プライバシーポリシー」のリンクはあったが、本文ページの実体がなかった。
法的に必須なので Phase 1 として3画面を実装。

### 実装ファイル
- `Megrum/legal-pages.jsx`：3画面（TermsOfService / PrivacyPolicy / LegalNotice）
- `Megrum/Megrum Legal Pages.html`：表示用 HTML

### 画面構成
1. **利用規約**：第1条〜第12条＋附則（全12条構成）
2. **プライバシーポリシー**：9セクション＋お問い合わせ窓口
3. **特定商取引法に基づく表記**：運営事業者情報＋サービス情報＋物々交換の補足

### 注意事項（実運用前 必須対応）
- 内容はすべてモック、法務/弁護士による内容レビュー必須
- 運営会社情報・連絡先は実情に差し替え
- 設定画面（SettingsTop）から遷移できるようリンク実装要
- 新規登録画面の「規約に同意する」チェックボックスからも遷移できるようにリンク実装要

### 確認方法
http://localhost:8000/Megrum%20Legal%20Pages.html

---

## イテレーション20：ターン3 認証＋オンボーディング 自前実装

Claude Design 利用制限のため、ハナ自身が JSX 直接実装。

### 実装ファイル
- `Megrum/auth-onboarding.jsx`（13画面分の React コンポーネント）
- `Megrum/Megrum Auth Onboarding.html`（表示用 HTML、Babel Standalone）

### 13画面の構成
1. ウェルカム（メアド/Google/ログインの3CTA）
2. 新規登録（メアド経由）
2'. Google経由同意（メール認証スキップ）
3. メール認証送信完了
4. メール認証完了
5. ログイン
6. パスワードリセット
7. アカウント削除（理由選択＋警告）
8〜12. オンボーディング（性別→推しグループ→メンバー→AWエリア→完了）

### 確認方法
ローカルサーバー起動：`python3 -m http.server 8000`（Megrum ディレクトリ内）
http://localhost:8000/Megrum%20Auth%20Onboarding.html

---

## イテレーション19.5：在庫タブの仕様修正（追加）

### 問題発覚
在庫タブに「譲るもの／求めるもの」の上タブがあるが、概念的に矛盾：
- 在庫 = 自分が持っているもの（譲る or 自分用キープ）
- 求めるもの = まだ持っていないもの（ウィッシュ）

### 修正方針

#### 在庫タブの構造（修正後）
- 上タブ「譲るもの／求めるもの」を **削除**
- 上部は「📋 リスト / 📚 コレクション」切替のみ
- リスト表示：サブビュー（譲る候補 / 自分用キープ / 過去に譲った）＋ フィルタチップ
- コレクション表示：wish基準シルエット表示＋進捗

#### ウィッシュタブ（独立）
- 求めるものの管理に専念（CRUD＋優先度＋flexibility＋探し中ステータス）

#### B-2 撮影フローの「譲る／求める／自分用キープ」3択トグル
- 譲る → 在庫の「譲る候補」へ
- 求める → ウィッシュタブへ（ウィッシュ追加）
- 自分用キープ → 在庫の「自分用キープ」へ

### 追加修正項目

1. 「達成記念をXに投稿」CTA はコンプ達成時のみ表示
2. コレクション表示の上部に「全wishの進捗バー」追加（例：9/14、69%）
3. プロフハブのメトリクス「5 SAVファ」の正体確認＋コレクションサマリ表記整理

### プロフハブ反映確認 ✅
- プロフィールカード（推し情報・エリア・取引マナー◎）
- メトリクス4つ並び
- コレクションサマリ縮小版（1行表示）
- アイデンティティ・活動・設定セクション分け
- ボトムナビ正しく5タブ

### ファイル構成方針

**新規 1ファイル統合**：`Megrum Core Surfaces.html`（仮名、命名は依頼者判断）
- ホーム再確認＋プロフハブ＋ウィッシュタブの 6〜7画面を1ファイル統合
- 関連性が強い3画面群、横断確認が効く

**既存ファイルのナビ一括修正**（5画面構成「ホーム／在庫／取引／ウィッシュ／プロフ」に統一）：
- Megrum B Inventory.html
- Megrum Account & Support.html
- Megrum Collection Pokedex.html
- Megrum Dispute Flow.html
- Megrum C Flow.html
- Megrum AW.html
