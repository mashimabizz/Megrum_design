# CLAUDE.md — Claude セッション Bootstrap

> **このファイルは、Claudeがこのリポジトリに入った時に最初に読むべきファイル。**
> PC（Claude Code）でも スマホ（claude.ai mobile / GitHub連携）でも、ここに書かれたルールに従って動作してください。
>
> このファイルだけで、新規環境でも作業を再現できることを目的としています。

---

## ⚠️ Claude が動作する前に必ずすること

1. **このファイル全文を読む**
2. **`notes/10_glossary.md` を最低でも目次までスキャン**（「AW」「wish」等の用語を誤解しないため）
3. **`notes/09_state_machines.md` の目次を確認**（状態名を間違えないため）
4. **`notes/08_design_iterations.md` の最新 iter を 1〜2件読む**（直近のコンテキスト）
5. **オーナーがタスク的な指示をした場合は `notes/USER_PLAYBOOK.md` を確認**（Phase 2 タスク・指示テンプレ・チェックポイントが集約されている）
6. **法的文書（規約・プライバシー・特商法）に関わる作業は `notes/17_legal_alignment.md` を確認**（弁護士納品の規約原典との整合性管理）

これらを読まずに作業を始めない。

## 🛑 画面実装時の絶対ルール（厳守）

> **これを守らないとオーナーが激おこ。手抜き禁止。**

### 1. 着手前：デザインと仕様を必ず読む

画面を実装・変更する前に、以下を **end-to-end で精読** する：

- 該当する **モックアップ JSX**（`Megrum/*.jsx`）の関数全部
  - 主要 function だけでなく、内部の small components も
  - `style={{ ... }}` の数値（fontSize, padding, gap, borderRadius, fontWeight, letterSpacing, boxShadow, background のグラデ角度・色 stops）まで全部見る
- **GitHub Pages で目視確認**：`https://mashimabizz.github.io/Megrum_design/Megrum/[ファイル名].html`
- 関連する **仕様ドキュメント**：
  - `notes/02_system_requirements.md` — 機能要件
  - `notes/05_data_model.md` — データモデル
  - `notes/09_state_machines.md` — 状態遷移
  - `notes/10_glossary.md` — 用語
  - `notes/12_screens/` — per-screen spec（あれば）
  - `notes/13_api_spec.md` — API 仕様
- 既に決まっている **共通規約**：
  - ブランドカラー（後述）
  - 共通コンポーネント（後述）
  - ボタン規約（後述）

### 2. 実装中：共通規約に従う

既に整理したものを使い回す。新規実装は最後の手段。

#### ブランドカラー（Tailwind theme 統合済）
```
bg-megrum-lavender / text-megrum-sky / border-megrum-pink / megrum-warn / megrum-ok
（`#a695d8` などの直書きは禁止。opacity 修飾子も /35, /55 等で使う）
```

#### 共通コンポーネント（`web/src/components/auth/`）
- `PrimaryButton` / `PrimaryLinkButton` — 主アクション（3色グラデ→2色版・rounded-[14px]）
- `secondaryBaseClass` — セカンダリボタン用 className（白＋紫透明枠）
- `HeaderBack` — 戻る + タイトル + サブ + 進捗
- `MegrumLogo` — 「Mg」テキスト + 角丸正方形 + Inter Tight
- `ProgressDots` — 4 セルの進捗バー
- `Spinner` / `useRipple` — ボタン挙動補助

新規ボタンを書く前に：「`PrimaryButton` で済まないか？」を必ず自問。

#### iOSネイティブ標準コンポーネント優先（最重要）
- iOSアプリ実装では、**できるだけiOS標準・ネイティブのコンポーネント / 挙動を採用する**。
  - 例：`NativeTabs` / iOS標準タブバー、`ActionSheetIOS`、iOS標準のシート、標準の戻る遷移、標準のスクロール連動、Apple Map など。
- iOS標準で実現できる見た目・操作感を、独自Viewや独自アニメーションで作り直さない。
- 既存のiOS標準コンポーネントを使っている箇所は、原則として維持する。置き換えが必要に見える場合は、まず標準コンポーネント側の設定・画面構造・制約を調査する。
- オーナーの指示がこのルールに背く可能性がある場合、実装前に「iOS標準を捨てることになるが本当に良いか」を明示して確認する。
- 例外は、iOS標準では明確に実現不能、またはWeb版との機能整合に重大な支障がある場合のみ。その場合も、理由と代替案を説明してから実装する。

#### レイアウト規約
- 背景：通常画面は `bg-[#fbf9fc]`、Welcome 系はグラデ
- ヘッダー：`HeaderBack` を使う（独自実装禁止）
- ボトムナビ：`<BottomNav />`（共通）
- max-width: `max-w-md`
- safe-area: `pb-[env(safe-area-inset-bottom)]` を BottomNav が処理

#### 数値は pixel-perfect
- モックアップから `fontSize, padding, gap, borderRadius, letterSpacing, lineHeight, boxShadow` を抽出
- `style={{ fontSize: 11.5 }}` → Tailwind `text-[11.5px]`
- `padding: '11px 14px'` → `px-3.5 pt-2.5 pb-2`（または `px-[14px] py-[11px]`）
- 「なんとなく似た値」で済まさない

### 3. 完成後：必ずセルフレビュー

実装完了 commit の前に、以下を check：

#### A. デザイン整合性チェック
- [ ] モックアップと**スクリーンショット並べて比較**（または記述レベルで突き合わせ）
- [ ] ブランドカラー：直書き `#a695d8` 等が無い（`bg-megrum-lavender` 等を使用）
- [ ] 共通コンポーネント：`PrimaryButton` 等を使い回している
- [ ] フォント：日本語 = Noto Sans JP / 英字主体 = Inter Tight + letterSpacing
- [ ] 余白・サイズ：モックアップの数値と一致
- [ ] 影 / グラデ角度 / opacity：完全一致

#### B. 仕様整合性チェック
- [ ] 状態名は `notes/09` の通りか（snake_case 統一）
- [ ] 用語は `notes/10` の通りか（廃止用語 = 「交換募集」「DM」「MyLog」「郵送」を使っていない）
- [ ] DB スキーマは `notes/05` と整合（必要なら migration 追記）
- [ ] 機能要件は `notes/02` の MVP 範囲内
- [ ] API 仕様は `notes/13` と整合（あれば）

#### C. レビュー結果の記述
- iter エントリの末尾に **「セルフレビュー結果」セクション**を入れる
- 「✅ ブランドカラー直書き なし」「✅ 共通 PrimaryButton 使用」「⚠️ Stat 統計のプレースホルダ値は次 iter でデータ連携」など具体的に
- レビューでズレが見つかったら **commit 前に修正**

### 4. 違反した場合

- オーナーから「全然デザイン通りじゃない」「整合取れてない」と指摘される → 全面作り直し
- 防止：最初から上記 1-3 を機械的に実行する

---

## 📜 重要な用語ルール（iter46 確定）

旧規約用語（`利用規約など/` 内docx）と現状 Megrum の用語マッピング：

| 旧規約 | 新（Megrum） | 備考 |
|---|---|---|
| ダイレクトメッセージ / DM | **取引チャット** | iter46 統一 |
| 交換依頼 | **打診（proposal）** | iter46 統一 |
| ~~交換募集 / 募集情報 / 募集登録~~ | （概念消滅） | 在庫登録（kind=for_trade）に吸収 |
| ~~MyLog / MyLog投稿 / 投稿コンテンツ~~ | （削除） | iter46 で MVP 対象外 |
| ~~郵送 / 本人確認（身分証）~~ | （削除） | iter46 で現地のみ |

**「交換募集」「交換依頼」「ダイレクトメッセージ」「MyLog」「郵送」を新規ドキュメントに書かない。**
詳細は `notes/10_glossary.md` §J 廃止用語、§M 規約原典マッピングを参照。

## 🔒 法的文書の方針

- **規約原典**：`利用規約など/` 配下の docx（弁護士納品、git管理外）
- **代表者情報**：**非公表**（請求があれば回答）— 規約原典通り、`legal-pages.jsx` でも非公表
- **規約改訂**：`notes/17_legal_alignment.md` で齟齬整理 → 弁護士再依頼
- **`legal-pages.jsx` の値を変更する時は必ず `notes/17_legal_alignment.md` を確認**（規約原典と整合させる）

---

## 30秒で理解する Megrum

- **何**: K-POP / アニメ等の推し活グッズを **現地で交換**するモバイルアプリ
- **誰のため**: メインペルソナはハナ（27歳・IT勤務・月3〜5万円グッズ予算）。詳細は `notes/00_persona.md`
- **MVP の範囲**: 現地交換（郵送は Yahoo フリマ等と棲み分け）、ランダム封入の小型グッズが主な交換対象
- **特徴**: AW（Activity Window = 「この時間ここにいる」予定）と wish のマッチング、受諾前ネゴ、合意前に待ち合わせfix

## 🎯 実装対象の優先方針（iter168.51）

- **ユーザー向けアプリの主対象は `mobile/`（React Native + Expo / iOS）**。新機能・UI修正・Preview反映は原則 mobile を更新する。
- **`web/` は通常のユーザー向け更新対象から外す**。同じ変更をWeb版へ横展開しない。ただし、管理者画面・運用画面・法務/サポート確認画面として必要な場合は `web/` を更新してよい。
- mobile のユーザー向け変更は、引き続き Preview channel / EAS build の反映要否を必ず確認する。web 管理画面だけの変更では iOS Preview 更新は不要。

---

## 🤖 環境ごとの動作差分（重要）

| 動作 | PC（Claude Code） | スマホ（claude.ai） |
|---|---|---|
| ファイル読み書き | ⭕ | ⭕ |
| git commit/push | ⭕ | ⭕（GitHub API経由） |
| Bash 実行 | ⭕ | ❌ |
| `python3 -m http.server` でプレビュー | ⭕ | ❌ |
| ブラウザでスクリーンショット | ⭕ | ❌ |
| スラッシュコマンド `/iter` 等 | ⭕ | ❌（CLAUDE.md の指示に従う） |

**スマホ Claude の場合**：
- localhost プレビューはできない → JSX のコードを読んで判断する
- スクショは取れない → 必要なら GitHub Pages のURL（[こちら](#-github-pages)）を案内する
- スラッシュコマンドは効かない → CLAUDE.md のワークフローセクションを読んで手動で同じ手順を踏む

---

## 📁 ファイル構造マップ

### `web/`（実装本体・Phase 0a〜）

**Next.js 16.2.4 + React 19.2.4 + TypeScript + Tailwind CSS + App Router**

⚠️ **重要**：Next.js 16 + React 19 は破壊的変更を含む新版。
作業前に **`web/AGENTS.md` と `web/node_modules/next/dist/docs/` を確認**すること（特にApp Router系の API変更）。

| パス | 内容 |
|---|---|
| `web/src/app/` | App Router 配下（page.tsx / layout.tsx 等） |
| `web/src/app/page.tsx` | トップページ（Hello Megrum） |
| `web/src/app/layout.tsx` | ルートレイアウト（Noto Sans JP フォント設定） |
| `web/src/app/globals.css` | Tailwind 設定 |
| `web/next.config.ts` | Next.js 設定（turbopack.root 固定済） |
| `web/.env.local.example` | Supabase 接続情報のテンプレート |
| `web/.env.local` | 実環境変数（gitignore） |
| `web/AGENTS.md` | Claude 向け Next.js 16 注意事項 |
| `vercel.json` | Vercel デプロイ設定（web/ をビルドルート） |

実装着手中の動作確認：

```bash
cd web
npm run dev      # 開発サーバ http://localhost:3000
npm run build    # 本番ビルド
npm run start    # 本番サーバ
npm run lint     # ESLint
```

### `supabase/`（DB マイグレーション・将来追加）

Phase 0a 完了後、Supabase CLI で初期化予定。

### `Megrum/`（mockup）

| ファイル | 担当範囲 |
|---|---|
| `home-v2.jsx`, `home-variations.jsx` | ホーム画面、マッチカード |
| `hub-screens.jsx` | プロフィールハブ、ウィッシュタブ |
| `b-inventory.jsx` | 在庫管理（B-1, B-2, B-3） |
| `aw-edit.jsx` | AW（活動予定）編集 |
| `search-filter.jsx` | 検索＋フィルタ＋保存検索 |
| `auth-onboarding.jsx` | 認証＋オンボーディング 13画面 |
| `account-extras.jsx` | プロフ補助 8画面 |
| `account-support.jsx` | 取引タブ／レポート／ヘルプ／設定 |
| `legal-pages.jsx` | 利用規約／プライバシーポリシー／特商法 |
| `propose-select.jsx` | C-0 提示物選択（譲・受け取る・**待ち合わせ**） |
| `c-flow.jsx` | C-1（打診）／**C-2（取引チャット）**／C-3（証跡＋評価） |
| `nego-flow.jsx` | C-1 受信／**C-1.5 ネゴチャット**／合意確認／取引成立 |
| `c-dispute.jsx` | D-flow（異議申し立て、10画面） |
| `design-canvas.jsx` | アートボードラッパー基盤 |
| `ios-frame.jsx` | iPhone 枠コンポーネント |
| `tweaks-panel.jsx` | ブランドカラー切替パネル（`useTweaks` フック含む） |

### `Megrum/Megrum *.html`（表示用 HTML）

各 HTML は `<DesignCanvas>` で複数アートボードを並べて表示する Figma 風キャンバス。
ファイル名 = フロー名。例：`Megrum Nego Flow.html` は受諾前ネゴ関連の全画面を一覧。

### `notes/`（ドキュメント）

| ファイル | 内容 | 更新頻度 |
|---|---|---|
| `00_persona.md` | ペルソナ（ハナ＋サブ3名） | 低 |
| `01_user_needs.md` | ユーザーニーズ | 低 |
| `02_system_requirements.md` | 機能要件 | 中（要更新） |
| `03_strategy.md` | 戦略 | 低 |
| `04_prototype_status.md` | 既存システム状況 | 低 |
| `05_data_model.md` | データモデル | 中（要更新） |
| `06_extended_needs.md` | 拡張要件 | 低 |
| `07_mvp_handoff.md` | MVP引き継ぎ | 低 |
| `08_design_iterations.md` | **設計判断の履歴** | **高（変更のたび）** |
| `09_state_machines.md` | **状態遷移図（mermaid）** | 中（状態追加・変更時） |
| `10_glossary.md` | **用語集＋廃止用語** | 中（用語追加時） |
| `11_screen_inventory.md` | 画面マトリクス（89画面） | 中（画面追加時） |
| `12_screens/` | per-screen spec（主要5画面） | 中（実装中） |
| `13_api_spec.md` | REST API仕様（70+ endpoints） | 中（API追加時） |
| `14_implementation_phases.md` | 実装フェーズ分割 Phase 0〜6 | 中（Phase 進行時） |
| `15_non_functional.md` | 非機能要件（プライバシー・セキュリティ等） | 低 |
| `16_monetization.md` | マネタイズ戦略（広告・ブースト・Premium） | 中（戦略変更時） |
| `17_legal_alignment.md` | **規約原典との整合性管理** | 中（規約改訂時） |
| `USER_PLAYBOOK.md` | **オーナー向け作業手順書** | 中（フェーズ進行時） |

### `.claude/`（Claude設定）

| ファイル | 用途 |
|---|---|
| `commands/iter.md` | `/iter` スラッシュコマンド（PC版Claude用） |
| `settings.local.json` | ユーザー個人設定（gitignore） |

---

## ✅ ワークフロー（厳守）

### A. 設計・実装変更時のチェックリスト

**何かしらの設計判断や実装変更をしたら、必ず以下の順で実行する：**

```
□ 1. 変更内容を実装（JSX編集等）
□ 2. notes/08_design_iterations.md に新しい iteration エントリを追加
□ 3. 状態遷移に影響あるか？ → あれば notes/09_state_machines.md を更新
□ 4. 新用語・廃止用語があるか？ → あれば notes/10_glossary.md を更新
□ 5. データモデルに影響あるか？ → あれば notes/05_data_model.md にメモ追加
□ 6. commit メッセージは [iter◯◯] [タイトル] 形式で
□ 7. push
□ 8. **iOS版 / mobile のユーザー向け変更は、必ず Preview channel にも反映**
   - JS/TSだけの変更：`npm --prefix mobile run export:ios:preview` → `EXPO_NO_GIT_STATUS=1 npm --prefix mobile run update:ios:preview -- --message "[iter◯◯] ..." --non-interactive`
   - Swift / Expo local module / native config / 依存追加を含む変更：EAS Updateだけでは反映されないため、Preview用のEAS buildが必要。必要ならオーナーにビルド手順を渡す
   - Preview更新した場合は、EAS Update ID / Update group を `notes/08_design_iterations.md` の確認方法へ記録
   - オーナーが iPhone / TestFlight で見ている前提の時は、mobile のJS変更を反映して終わりではなく **EAS Update 実行完了までを1セット** とみなす
□ 9. **ユーザー向け変更は原則 `mobile/` のみ更新**。`web/` は管理者画面・運用画面として必要な時だけ更新する
```

**省略禁止**：チェックリストの 2-5 を飛ばすと、別環境の Claude が同じ判断を再現できなくなる。

### B. iteration エントリの形式

`notes/08_design_iterations.md` への追記は、最新が**上**に来る形式：

```markdown
## イテレーション◯◯：[簡潔なタイトル]

### 背景・問題意識
[なぜこの変更が必要か。ユーザーからの指摘ならその引用も]

### 変更内容
[何を変えたか。bullet で具体的に]

#### `path/to/file1.jsx`
- 変更点1
- 変更点2

#### `path/to/file2.jsx`
- 変更点

### 影響範囲
[どの画面・どのフローに影響するか]

### 確認方法
- http://localhost:8000/Megrum%20XXX.html

### 関連ファイル
- `Megrum/xxx.jsx`
- `Megrum/Megrum XXX.html`
```

### C. 用語追加時

`notes/10_glossary.md` の正しいカテゴリ（A〜I）に追加。同義語・別名も併記。

### D. 廃止用語

**削除しない**。`notes/10_glossary.md` の `J. 廃止用語` セクションに移動し、後継用語と廃止理由を明記。

### E. commit メッセージのテンプレ

```
[iter◯◯] [タイトル30文字以内]

[変更概要を1-3行]

[詳細を bullet で]
- 変更点1
- 変更点2

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

例：
```
[iter34] C-2取引チャットを当日ライブ運用へ集約

合意前に待ち合わせfixしたので、C-2の場所/時間UIは不要になった。
代わりに服装写真CTA・現在地共有・到着ステータスを実装。

- 場所提案カード・時刻チップを削除
- 服装写真CTA をプロミネント配置
- 現在地共有メッセージ（mini map）追加
- ヘッダーに到着ステータス表示
```

---

## 🎨 デザイン規約

### ブランドカラー

```js
// 全画面で useTweaks フック経由
{
  primary:   '#a695d8',  // 紫（lavender）
  secondary: '#a8d4e6',  // 水色（sky）
  accent:    '#f3c5d4',  // ピンク（pink）
}
```

派生色は各 jsx ファイル先頭の `XX_C` 関数で定義（`PS_C`, `NF_C`, `CF_C` など）。

### 命名規約

- ファイル別 prefix を持つ helper：
  - `propose-select.jsx` → `PS_*`（PS_C, PS_MiniMap）
  - `nego-flow.jsx` → `NF_*`（NF_C, NF_MiniMap）
  - `c-flow.jsx` → `CF_*`（CF_MiniMap）
  - `home-variations.jsx` → グローバル（Avatar, Tcg, Ic）
- コンポーネント export は **末尾の `Object.assign(window, {...})`** で行う

### 状態識別子

`notes/09_state_machines.md` の `snake_case` を実装でも使う（例：`negotiating`, `agreed`, `for_trade`）。

### スタイリング

- インライン CSS-in-JS（外部 CSS ファイル不使用）
- カラーは tweaks 経由（ハードコード禁止、`c.lavender` 等を使う）
- アイコンは SVG インライン（外部画像不使用、`Ic.*` ヘルパー or インライン）

---

## 🔍 動作確認

### PC（Claude Code）

```bash
# プロジェクトルートで
python3 -m http.server 8000

# 主要URL
# http://localhost:8000/Megrum%20MVP%20v1.html       — 全画面統合
# http://localhost:8000/Megrum%20Nego%20Flow.html    — ネゴ
# http://localhost:8000/Megrum%20C%20Flow.html       — C-1〜C-3
# http://localhost:8000/Megrum%20Propose%20Select.html — C-0
# http://localhost:8000/Megrum%20Hub%20Screens.html  — ホーム/プロフ/ウィッシュ
# http://localhost:8000/Megrum%20B%20Inventory.html  — 在庫
# http://localhost:8000/Megrum%20Auth%20Onboarding.html — 認証＋オンボ
```

### 🌐 GitHub Pages

スマホ・他環境からプレビューしたい時：

```
https://mashimabizz.github.io/Megrum_design/Megrum/[ファイル名].html
```

例：
- `https://mashimabizz.github.io/Megrum_design/Megrum/Megrum%20MVP%20v1.html`
- `https://mashimabizz.github.io/Megrum_design/Megrum/Megrum%20Nego%20Flow.html`

---

## 📜 直近の主要設計判断（iter 30〜35）

実装着手前に必ず把握しておく：

| iter | 内容 | 影響範囲 |
|---|---|---|
| 30 | 受諾前ネゴ追加（7日期限・3/6日リマインド・延長可） | C-1.5 |
| 31 | ネゴチャットのクイックアクション削除、`+`ボタンに集約 | C-1.5 |
| 32 | 合意フロー（確認モーダル＋成立画面） | C-1.5 |
| 32.5 | C-1.5 から QR ボタン削除（合流前は不要） | C-1.5 |
| 33 | **待ち合わせを合意前にfix**（C-0 に「待ち合わせ」タブ追加） | C-0, C-1, C-1.5, 合意, C-2 |
| 34 | **C-2 取引チャット再定義**（当日ライブ運用へ集約・服装写真CTA強調・現在地共有） | C-2 |
| 35 | **state machines + glossary 整備**（再現可能性確保） | docs |

最新の iter は `notes/08_design_iterations.md` の冒頭を参照。

---

## 🚧 ステータス・次フェーズ

### ✅ 完了

- 80画面以上の mockup
- 主要設計ドキュメント（要件・状態遷移・用語集）
- ブランドカラー・命名規約
- GitHub 移行＋ Pages 有効化（iter36）

### 🎯 これから（Phase 2）

優先順：
1. `05_data_model.md` 最新化（iter 24-34 反映）
2. `11_screen_inventory.md` 新規（画面遷移マトリクス）
3. `12_screens/` 新規（per-screen spec）
4. `13_api_spec.md` 新規
5. `14_implementation_phases.md` 新規（フェーズ分割）

### 🤔 検討中

- 実装の技術スタック（React Native? Flutter? PWA?）
- BFF / バックエンド設計
- マスタ管理の運用

---

## 📲 iPhone ワークフロー

スマホからの典型的な使い方：

1. **claude.ai モバイルアプリ**を開く
2. Megrum_design リポジトリへの GitHub 連携が有効になっている前提
3. 「**Megrum_design リポを見て、〇〇画面の××を△△に変えて**」と依頼
4. Claude が以下を実行：
   - CLAUDE.md を読む（このファイル）
   - 関連 JSX を読む
   - 必要な変更を判断
   - **A. 設計・実装変更時のチェックリスト** を必ず実行
   - commit & push
5. 必要なら GitHub Pages の URL でスマホブラウザから確認

**iPhone Claude が困りそうな時の対処**：
- 「localhost プレビューしたい」 → GitHub Pages の URL を案内
- 「スクショ取りたい」 → スマホブラウザで GitHub Pages を開いてスクショを取ってもらう
- 「シェル使いたい」 → PC作業を案内

---

## 🛠 PC で便利なスラッシュコマンド

PC で Claude Code を使う場合、以下のスラッシュコマンドが使える：

| コマンド | 用途 |
|---|---|
| `/iter` | 設計変更を 08 に記録 + 09/10 の更新診断 |

スマホ Claude では効かないので、CLAUDE.md の **A. 設計・実装変更時のチェックリスト** を手動で実行する。

---

## ❓ Claude が判断に迷ったら

1. **用語が分からない** → `notes/10_glossary.md` を最初に検索
2. **状態が分からない** → `notes/09_state_machines.md` を確認
3. **過去の設計判断を知りたい** → `notes/08_design_iterations.md` を時系列で読む
4. **「これって意図的？」と思った** → 安易に変えず、ユーザーに確認 or 関連 iter を読む
5. **暗黙的な仮定に気付いた** → `notes/09_state_machines.md` 末尾の「未確定・要確認項目」表に追加して、ユーザーに知らせる

---

## 🤝 Claude へのお願い（まとめ）

1. このCLAUDE.md と `notes/08, 09, 10` を**最初に読む**
2. **A. 設計・実装変更時のチェックリスト**を厳守
3. **新用語・廃止用語**は `10` を都度更新
4. **暗黙的な仮定**に気付いたら `09` の「未確定項目」に追加
5. **「これって何？」**と思ったら `10_glossary.md` を最初に検索
6. **commit メッセージ**は `[iter◯◯] [タイトル]` 形式で
