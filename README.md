# Megrum Design

K-POP / アニメ等の推し活グッズを **現地で交換**するプラットフォーム「Megrum」の **設計・mockup・Web実装・iOS実装** リポジトリ。

> Web版は Next.js、iOS版は Expo / React Native で同一 Supabase 基盤に接続する monorepo として運用。

## このリポジトリで扱うもの

- 🎨 **画面 mockup**（React + Babel Standalone でブラウザ即プレビュー可能、80画面以上）
- 🌐 **Webアプリ版**（Next.js / `web/`）
- 📱 **iOSアプリ版**（Expo / React Native / `mobile/`）
- 📦 **共通パッケージ**（`packages/core`, `packages/design`, `packages/supabase`）
- 📋 **仕様書／設計ドキュメント**（要件定義・データモデル・状態遷移・用語集）
- 📝 **設計判断の履歴**（イテレーション記録）

## ディレクトリ構造

```
.
├── README.md              # このファイル
├── CLAUDE.md              # Claude セッション用 bootstrap doc
├── package.json           # npm workspaces
├── web/                   # Next.js Webアプリ
├── mobile/                # Expo / React Native iOSアプリ
├── packages/              # Web/iOS共通ロジック・デザイン・Supabase補助
├── Megrum/                  # 画面 mockup（JSX + HTML）
│   ├── *.jsx              # 各画面のコンポーネント
│   ├── Megrum *.html        # フロー単位の表示用 HTML
│   ├── design-canvas.jsx  # Figmaライクなアートボード基盤
│   ├── ios-frame.jsx      # iPhone 枠
│   └── tweaks-panel.jsx   # ブランドカラー切替パネル
└── notes/                 # 設計ドキュメント
    ├── 00_persona.md          # ペルソナ
    ├── 01_user_needs.md       # ユーザーニーズ
    ├── 02_system_requirements.md  # 機能要件
    ├── 03_strategy.md         # 戦略
    ├── 04_prototype_status.md # 既存システム
    ├── 05_data_model.md       # データモデル
    ├── 06_extended_needs.md   # 拡張要件
    ├── 07_mvp_handoff.md      # MVP引き継ぎ
    ├── 08_design_iterations.md # 設計判断の履歴（イテレーション35件）
    ├── 09_state_machines.md   # 状態遷移図（mermaid）
    ├── 10_glossary.md         # 用語集
    ├── 20_ios_app_roadmap.md  # iOSアプリ化ロードマップ
    └── 21_ios_review_guide.md # iOS画面レビュー手順
```

## クイックスタート

### mockup を見る

```bash
# プロジェクトルートで
python3 -m http.server 8000

# ブラウザで開く
# http://localhost:8000/Megrum%20MVP%20v1.html       — 全画面統合
# http://localhost:8000/Megrum%20Nego%20Flow.html    — 受諾前ネゴ
# http://localhost:8000/Megrum%20Propose%20Select.html — C-0 提示物選択
# http://localhost:8000/Megrum%20C%20Flow.html       — C-1〜C-3
# http://localhost:8000/Megrum%20Hub%20Screens.html  — ホーム/プロフ/ウィッシュ
# http://localhost:8000/Megrum%20B%20Inventory.html  — 在庫
# http://localhost:8000/Megrum%20Auth%20Onboarding.html — 認証＋オンボ
# (他にもあり、Megrum/ ディレクトリ参照)
```

Megrum フォルダ内 HTML を開けば即動作（依存は CDN から取得）。

### Webアプリを起動

```bash
npm run web:dev
```

### iOSアプリを起動

Node.js は `.nvmrc` の `20.19.4` を使用。

```bash
npm run mobile:ios
```

実機レビューの手順は [`notes/21_ios_review_guide.md`](notes/21_ios_review_guide.md) を参照。

## 主要フロー

```
ホーム
  → 検索／マッチカード
  → C-0 提示物選択（譲・受け取る・待ち合わせ の3タブ）
  → C-1 打診送信／受信
  → C-1.5 ネゴチャット（7日期限・3/6日リマインド）
  → 合意確認モーダル
  → 取引成立画面
  → C-2 取引チャット（当日のライブ運用）
  → C-3 証跡撮影＋両者承認＋評価
  → 完了

異常時 → D-flow（dispute）
```

詳細は [`notes/09_state_machines.md`](notes/09_state_machines.md) と [`notes/08_design_iterations.md`](notes/08_design_iterations.md) を参照。

## 技術スタック

- **Web**: Next.js + React + TypeScript + Tailwind CSS
- **iOS**: Expo + React Native + TypeScript + Expo Router
- **Backend**: Supabase Auth / DB / Storage
- **共通ロジック**: npm workspaces (`packages/*`)
- **mockup**: React 18 + Babel Standalone（in-browser JSX 変換、ビルド不要）
- **ドキュメント**: Markdown + Mermaid
- **静的サーバ**: 何でも（`python3 -m http.server` で十分）

## ステータス

- ✅ 80画面以上の mockup 完了（Auth〜オンボ〜ホーム〜検索〜在庫〜ウィッシュ〜C-flow〜D-flow〜法的画面）
- ✅ 設計ドキュメント整備中（要件・データモデル・状態遷移・用語集まで）
- 🚧 Webアプリ版 実装中
- 🚧 iOSアプリ版 scaffold 開始（`notes/20_ios_app_roadmap.md`）

## 開発・更新のルール

1. **デザイン変更**したら必ず `notes/08_design_iterations.md` に iteration として記録
2. **状態の追加・変更**は `notes/09_state_machines.md` を更新
3. **新用語**を作ったら `notes/10_glossary.md` に登録
4. **廃止用語**は削除せず `10_glossary.md` の J. 廃止用語 セクションへ移動

## 関連

- 関連リポジトリ: [Megrum_renewal](https://github.com/mashimabizz/Megrum_renewal)（要確認）
