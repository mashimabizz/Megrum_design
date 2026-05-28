# USER_PLAYBOOK — オーナー向け作業手順書

> **目的**：プロジェクトオーナーが、スマホ・PCどちらからでも Claude に効率的に指示を出せるようにするための実用ガイド。
>
> 「次に何をすればいいか」「どう指示すればいいか」「何をチェックすればいいか」が一冊で分かる。
>
> Claudeセッションでも参照する：「USER_PLAYBOOK.md を見て、タスク◯◯を進めて」と言えば、このドキュメント通りに動作する。

最終更新: 2026-05-28
ステータス: Active（iOSアプリ集中方針 / iter168.63）

---

## 目次

1. [現在のフェーズ](#1-現在のフェーズ)
2. [Phase 2 タスク一覧](#2-phase-2-タスク一覧)
3. [スマホからの指示テンプレ（コピペ用）](#3-スマホからの指示テンプレコピペ用)
4. [共通チェックポイント](#4-共通チェックポイント)
5. [スマホ vs PC の使い分け](#5-スマホ-vs-pc-の使い分け)
6. [スマホ指示のコツ](#6-スマホ指示のコツ)
7. [トラブルシューティング](#7-トラブルシューティング)

---

## 1. 現在のフェーズ

### 🎯 現在の実装方針（最重要）

- ユーザー向けMegrumは `mobile/` の iOSアプリに一点特化する。
- `web/` は通常ユーザー向けWeb版としては使わず、管理者画面・運用画面・サポート確認画面が必要な時だけ触る。
- 「画面を直して」「ユーザー体験を作って」という依頼は、原則 iOS / `mobile/` の実装対象として扱う。
- mobile のユーザー向け変更は、完了前に Preview channel / EAS build 反映要否を必ず確認する。

### ✅ 完了（Phase 0-1）

- 80以上の画面 mockup 完了（Auth〜オンボ〜ホーム〜検索〜在庫〜ウィッシュ〜C-flow〜D-flow〜法的画面）
- 主要設計ドキュメント整備（要件・状態遷移・用語集まで）
- GitHub 移行・CLAUDE.md 整備・GitHub Pages 有効化

### 🚧 進行中（Phase 2 — 実装着手前の最終整備）

- データモデル最新化
- 画面マトリクス
- per-screen spec
- API仕様
- 実装フェーズ分割
- 非機能要件

### 🎯 これから（Phase 3 — 実装着手）

- 技術スタック確定
- バックエンド実装
- iOSアプリ実装（主対象）
- Web管理者・運用画面実装（必要最小限）
- ベータ版リリース

---

## 2. Phase 2 タスク一覧

優先順 + 依存関係：

```
🥇 タスク1：05_data_model.md 最新化
   ↓（このアウトプットが2-4の前提）
🥈 タスク2：11_screen_inventory.md（画面マトリクス）
   ↓
🥈 タスク3：12_screens/（per-screen spec）
   ↓
🥉 タスク4：13_api_spec.md（API仕様）
   ↓
🥉 タスク5：14_implementation_phases.md（フェーズ分割）

🟡 並行可能：
🟡 タスク6：15_non_functional.md（非機能要件）
🟡 タスク7：02_system_requirements.md 更新（iter24-34反映）
```

各タスクの所要見積もり（Claude側）：
- タスク1: 30〜60分
- タスク2: 30〜60分
- タスク3: 1〜2時間（5画面ぶん）
- タスク4: 1〜2時間
- タスク5: 30〜60分

スマホで指示出して、Claudeが裏で書き上げて、後でレビューするスタイルで進める。

---

## 3. スマホからの指示テンプレ（コピペ用）

### 🥇 タスク1：データモデル更新

```
Megrum_design リポを見て、CLAUDE.md と notes/09_state_machines.md と
notes/08_design_iterations.md を読んで。

notes/05_data_model.md を以下の観点で最新化して：
- iter24（推し2階層構造：L1グループ→L2メンバー）
- iter29（数量管理：qty / selectedQty）
- iter33（meetup＋AW自動登録）
- iter34（服装写真・現在地共有）

新テーブル候補は draft として明記し、確定済か未確定かタグを付けて。
未確定項目は notes/09_state_machines.md の末尾「未確定項目」表に追加。

完了後、変更点を箇条書きで報告して、commit & push して。
```

**チェックポイント**：
- [ ] meetup テーブル（or proposals.meetup_xxx カラム）の追加案が入っている
- [ ] outfit_photos / location_shares の新テーブル提案あり
- [ ] 既存テーブルの変更（user_haves に qty カラム明示等）が反映
- [ ] 「未確定」マーク `⚠️` が正直に付いている
- [ ] 用語が `notes/10_glossary.md` と一致

---

### 🥈 タスク2：画面マトリクス

```
Megrum_design リポを見て。

notes/11_screen_inventory.md を新規作成。
Megrum/*.html と Megrum/*.jsx をすべてスキャンして、
以下のカラムでマトリクス化して：

| 画面ID | 名称 | 所属フロー | 関連JSX | 関連HTML | 関連 iter | 関連 docs |

mermaid で簡易フロー図も末尾に追加（ホーム→検索→C-0→C-1→...の主要動線）。
最新仕様だけでOK（廃止画面は J. 廃止画面 セクションへ）。

完了後、画面総数を報告して commit & push して。
```

**チェックポイント**：
- [ ] 80画面くらい網羅されている（アートボード単位ではなく画面単位）
- [ ] 全フローが mermaid 図で繋がっている
- [ ] 廃止画面が分離されている
- [ ] 各画面に 関連 iter が付いている

---

### 🥈 タスク3：per-screen spec（重要画面5つから）

```
Megrum_design リポを見て、CLAUDE.md と notes/09_state_machines.md と 10_glossary.md を読んで。

notes/12_screens/ ディレクトリ作って、以下5つの spec を1ファイルずつ作って：
1. C-0_propose_select.md
2. C-1_receive.md
3. C-1.5_nego_chat.md
4. C-2_trade_chat.md
5. C-3_complete.md

各ファイルの章立て：
## 画面の目的
## 入力データ（state, props, route params）
## 表示要素
## アクション（ユーザー操作と遷移先）
## バリデーション・エラー
## エッジケース
## 関連 API（仮）
## 関連 docs

JSXコード（Megrum/propose-select.jsx, c-flow.jsx, nego-flow.jsx）を実際に読んで、
暗黙的になってる仕様を文章化して。
未確定項目は「⚠️ 要確認」マークを付けて。

完了後、commit & push して。
```

**チェックポイント**：
- [ ] 5ファイル × 上記章立て が揃っている
- [ ] 状態名が `09_state_machines.md` と一致（`negotiating`, `agreed` 等）
- [ ] 用語が `10_glossary.md` と一致（譲・wish・AW等）
- [ ] 「⚠️ 要確認」が複数あって正直
- [ ] JSX に書いてあった内容と矛盾しない

---

### 🥉 タスク4：API仕様 draft

```
Megrum_design リポを見て、notes/05_data_model.md と 09_state_machines.md と 12_screens/* を参照して。

notes/13_api_spec.md を draft で作成。

REST 形式で、以下を最小限カバー：
- 認証（auth/register, auth/login, auth/verify, auth/oauth/google）
- アカウント（accounts/me CRUD, accounts/delete）
- AW（aws CRUD）
- 在庫（items CRUD, items/upload-image）
- ウィッシュ（wishes CRUD）
- マッチング（matches/list, matches/feed）
- 提案（proposals CRUD + agree + reject + counter）
- ネゴ（negotiations/{id}/messages, negotiations/{id}/modify）
- 取引（deals/{id}, deals/{id}/evidence, deals/{id}/approve, deals/{id}/rate）
- dispute（disputes CRUD + reply）
- 通報（reports CRUD）

各エンドポイントは [METHOD /path] [入力] [出力] [認証要否] [備考] の構造で。
未確定の認証スキームや細かい振る舞いは「⚠️ 要確認」で明記。

完了後、commit & push して。
```

**チェックポイント**：
- [ ] 状態遷移と整合（例: agree エンドポイントで Proposal が `agreed` になる）
- [ ] データモデルと整合（カラム名一致）
- [ ] 認証要否が全部書かれている
- [ ] エラーレスポンス形式が決まっている
- [ ] ファイルアップロード（画像）の扱いが書かれている

---

### 🥉 タスク5：実装フェーズ分割

```
Megrum_design リポ見て、CLAUDE.md と notes/07_mvp_handoff.md と
直近の docs（11_screen_inventory.md, 12_screens/*, 13_api_spec.md）を読んで。

notes/14_implementation_phases.md を新規作成。
MVP に向けたフェーズ分割を提案。

構成：
## Phase 0：基盤（インフラ・認証）
## Phase 1：在庫＋AW（土台）
## Phase 2：マッチング＋提案
## Phase 3：ネゴ＋合意
## Phase 4：取引チャット＋証跡＋評価
## Phase 5：dispute
## Phase 6：法的画面・サポート

各 Phase で：
- ゴール
- 含む機能（F1, F2 等の機能要件IDと紐付け）
- 含む画面（11_screen_inventory.md と紐付け）
- 含む API（13_api_spec.md と紐付け）
- 完了基準
- 概算工数（粗くてOK、エンジニア工数で人月）

完了後、commit & push して。
```

**チェックポイント**：
- [ ] 全画面が何かしらの Phase に属している
- [ ] 全 API が何かしらの Phase に属している
- [ ] 依存関係が明示されている（Phase 1 完了が Phase 2 の前提、等）

---

### 🟡 タスク6：非機能要件

```
Megrum_design リポ見て、CLAUDE.md と notes/03_strategy.md と
notes/12_screens/* を参照して。

notes/15_non_functional.md を新規作成。

カテゴリ別に書く：
## プライバシー・個人情報保護
## セキュリティ（認証・認可・通信・保管）
## パフォーマンス（応答時間・スループット）
## 可用性・スケーラビリティ
## アクセシビリティ
## ローカリゼーション
## ログ・監視・分析
## 災害復旧・バックアップ

各カテゴリで、MVP 必須 vs Post-MVP を区別。
未確定項目は「⚠️ 要確認」マーク。

完了後、commit & push して。
```

**チェックポイント**：
- [ ] 個人情報の取り扱いが法令準拠で書かれている（プライバシーポリシーと整合）
- [ ] パスワードのハッシュ・通信HTTPS等の最低ライン
- [ ] 「現地で会う」設計のため、位置情報の取り扱いが慎重
- [ ] MVP/Post-MVP の区別がある

---

### 🟡 タスク7：機能要件の更新

```
Megrum_design リポ見て、notes/02_system_requirements.md と
notes/08_design_iterations.md（特に iter24-34）と CLAUDE.md を読んで。

notes/02_system_requirements.md を最新化：
- iter25（ジャンル横断検索）
- iter26（推し一致バッジ廃止）
- iter30（ネゴ7日期限）
- iter32（合意フロー）
- iter33（合意前 meetup fix）
- iter34（C-2 ライブ運用）
- iter35（再現可能性 docs 整備）

機能要件 ID（F1, F2…）の体系を維持しつつ、廃止された要件は「廃止」マーク付きで残す。

完了後、commit & push して。
```

**チェックポイント**：
- [ ] iter24-34 の意思決定が反映されている
- [ ] 廃止要件が削除されず残っている
- [ ] F-ID の体系が崩れていない

---

## 4. 共通チェックポイント

どのタスクでも、Claudeが完了したら以下を確認：

### 🔴 必須5つ

1. **用語整合**：`notes/10_glossary.md` の用語が使われているか（揺れがあれば指摘）
2. **状態整合**：`notes/09_state_machines.md` の状態名が使われているか
3. **「⚠️ 要確認」が正直**：Claudeが勝手に決めつけていないか
4. **既存 iter記録と矛盾なし**：古い仕様を引きずっていないか
5. **iter記録あり**：このタスク自体も `notes/08_design_iterations.md` に iter として追加されたか

### 🟡 推奨

- commit メッセージが `[iter◯◯]` 形式
- 9/10 のクロスリファレンス（更新が必要だったか診断されている）
- スコープが守られている（依頼以外の余計な変更をしていない）

---

## 5. スマホ vs PC の使い分け

### 📱 スマホで完結できる
- 設計判断・議論
- docs 編集（00-15 番台すべて）
- iter記録
- 用語追加・廃止
- 文言修正
- ロジック変更（JSX編集）

### 💻 PC のほうが快適
- mockup の視覚調整（色・余白・配置）— `python3 -m http.server` で即プレビュー
- 大規模リファクタリング（複数ファイル一括）
- `/iter` スラッシュコマンド使用

### 💻 PC 必須
- ターミナル操作
- 実装フェーズ（npm install, build, test）
- ローカル試験

---

## 6. スマホ指示のコツ

### ✅ 良い指示

```
Megrum_design リポを見て、CLAUDE.md を最初に読んで。

notes/05_data_model.md を iter33-34 反映で更新して。
完了後、変更点を3行で報告して commit & push。
```

→ スコープ明確、参照docs指定、出力形式指定、commit指示まで。

### ❌ 悪い指示

```
データモデルいい感じに更新しといて
```

→ スコープ不明、参照docs不明、出力不明。Claudeが何を更新したか分からない。

### 💡 テンプレの3原則

1. **「リポを見て、CLAUDE.md を読んで」を必ず先頭に**
2. **タスクは1つに絞る**（Phase 2 全部やってはNG）
3. **完了後の出力形式を指定する**（報告フォーマット、commitの指示）

### ✅ 完了後の確認パターン

```
ありがとう。あと2つ確認したい：
1. notes/09 の未確定項目に新しいの追加した？
2. commit メッセージは [iter◯◯] 形式になってる？
```

---

## 7. トラブルシューティング

### 「Claudeが repo にアクセスできない」と言われた
- スマホの場合：claude.ai mobile で GitHub 連携が有効か確認
- 「Megrum_design リポを見て」を明示的に書く

### 「CLAUDE.md にこう書いてあるけど、実際の JSX と違う」
- まず JSX を正として、CLAUDE.md を更新するのが基本
- CLAUDE.md が間違ってる場合は、その場で修正してもらう

### 「commit が空でエラーになる」
- 既に同じ内容が反映されてる可能性
- `git status` で確認 → 何も変わってなければ OK

### 「⚠️ 要確認」が多すぎて困る
- 多くて困る = 仕様が決まってない、ということ
- 一個ずつ会話で詰める or PCでまとめて整理

### 「過去の iter記録と矛盾する判断をしてしまった」
- まず iter記録を読み直す
- 過去の判断を覆す場合は新しい iter として記録（`「iter◯◯ の判断を改訂」` と背景に書く）

### 「Pages のビルドが errored」
- ファイル名に問題がある場合あり（特殊文字など）
- リポジトリ Settings → Pages から再ビルドトリガー
- それでもダメなら GitHub Actions のログを確認

---

## 8. 次にやることの判断フロー

```
今、何をすべきか分からない時：

  ↓

A. このプレイブックの「2. Phase 2 タスク一覧」を見る
   ↓
   未着手のタスクで一番上を選ぶ

  ↓

B. 「3. スマホからの指示テンプレ」のコピペで Claude に指示

  ↓

C. Claude が完了したら「4. 共通チェックポイント」で検証

  ↓

D. OK なら次のタスクへ、NG なら修正依頼
```

迷ったら **タスク1（データモデル更新）から**。これが他タスクの前提になる。

---

## 9. 更新ルール

- このプレイブック自体も Phase が変わったら更新
- Phase 3（実装着手）に入ったら、新しい Playbook セクションを追加
- 各タスクが完了したら「✅ 完了」マークを付ける（チェックリスト的に使う）
