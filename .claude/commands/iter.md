---
description: 直近の設計・実装変更を notes/08_design_iterations.md に記録し、09/10 の更新が必要か診断する
---

# /iter — 設計変更の記録

直近の変更を `notes/08_design_iterations.md` に新しい iteration として記録します。
あわせて `09_state_machines.md` と `10_glossary.md` の更新が必要か診断し、必要なら更新案を提示します。

## 実行手順

### Step 1: 直近の変更内容を把握する

以下を実行して、変更されたファイルを確認：

```bash
git status
git diff HEAD --stat
```

ユーザーに「**何を変更しましたか？1〜3行で教えてください**」と聞く（変更内容が自明でない場合）。

### Step 2: iteration 番号を採番

`notes/08_design_iterations.md` の最新 iter 番号 +1 を決める。
- 大きな機能変更 → 整数（例：iter35 → iter36）
- 小修正・bug fix → 小数（例：iter35 → iter35.1）

```bash
grep -E "^## イテレーション" notes/08_design_iterations.md | head -3
```

### Step 3: iteration エントリのドラフトを生成

以下のテンプレに沿って、`notes/08_design_iterations.md` の**先頭付近**（最新 iter の上）に挿入する：

```markdown
## イテレーション◯◯：[簡潔なタイトル30字以内]

### 背景・問題意識

[なぜこの変更が必要か。ユーザーからの指摘ならその引用も]

### 変更内容

[何を変えたか。bullet で具体的に]

#### `Megrum/path/to/file.jsx`
- 変更点1
- 変更点2

### 影響範囲

[どの画面・どのフローに影響するか]

### 確認方法

- http://localhost:8000/Megrum%20XXX.html

### 関連ファイル

- `Megrum/xxx.jsx`
- `Megrum/Megrum XXX.html`

---

```

### Step 4: 09 / 10 の更新診断

ユーザーの変更内容について、以下を判定し、該当すれば**追加でファイルを更新する**：

| 判定項目 | 該当する場合 | 更新先 |
|---|---|---|
| 状態（state）が**追加・削除・改名**された | 例：`negotiating` という状態が増えた、`expired` が `closed` に変わった | `notes/09_state_machines.md` |
| **新しい用語**が登場した | 例：「待ち合わせ」「服装写真」「現在地共有」 | `notes/10_glossary.md` のカテゴリへ追加 |
| **既存用語が廃止**になった | 例：「推し一致バッジ」「24時間自動拒否」 | `notes/10_glossary.md` の `J. 廃止用語` へ移動 |
| **データモデル**が変更される（フィールド追加等） | 例：meetup テーブル追加 | `notes/05_data_model.md` にメモ追加（要更新フラグ） |

判定の例：
- 「C-0 に待ち合わせタブを追加」 → 新用語「待ち合わせ／meetup」「即時モード／日時指定モード」 → `10` 更新
- 「ネゴ7日期限を 14日に変更」 → 状態定義は同じだが「ネゴ期限」ルールが変わる → `09` の `1. Proposal Lifecycle` の「ビジネスルール」欄を更新
- 「QR ボタン削除」 → 用語自体は廃止しないが、配置が変わるので廃止メモ不要

### Step 5: ユーザー確認

すべての更新ファイル一覧をユーザーに見せて、確認を取る：

```
更新するファイル：
- notes/08_design_iterations.md（iter◯◯ 追加）
- notes/09_state_machines.md（[該当箇所]）  ← ある場合のみ
- notes/10_glossary.md（[該当箇所]）  ← ある場合のみ

このまま commit して push しますか？
```

### Step 6: commit & push

確認が取れたら：

```bash
git add notes/
git commit -m "$(cat <<'EOF'
[iter◯◯] [タイトル]

[変更概要を1-3行]

- 変更点1
- 変更点2

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push
```

## 重要な注意事項

- **省略するな**：09/10 の更新判定は**毎回行う**。「該当しない」と判断した場合もその根拠をユーザーに伝える
- **iter 番号の重複に注意**：必ず最新を確認してから採番
- **ユーザーが急いでいる場合**でも、Step 5 の確認は省略しない（事故防止）
- **JSX の変更があってもコミットしない**：このコマンドは notes/ の更新だけ。JSX commit は別途行う
