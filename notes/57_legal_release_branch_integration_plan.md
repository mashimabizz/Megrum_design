# 57. 法務リリース準備ブランチ統合手順

最終更新: 2026-05-31

ステータス: Draft v0.1（branch運用メモ）

## 目的

Swift Native開発セッションと、法務・App Store提出準備セッションの差分を混ぜないため、`codex/legal-release-prep` の扱い、PR化、merge、競合時の判断を明文化する。

この文書は運用メモであり、コード、DB、ビルド設定、App Store Connect設定は変更しない。

## 1. 現在のブランチ構成

| 用途 | worktree | branch | 状態 |
|---|---|---|---|
| Swift Native開発 | `/Users/michitaka/Desktop/Megrum` | `codex/rl-003-006-inventory-wish-listing` | 開発側が継続利用 |
| 法務・リリース準備 | `/Users/michitaka/Desktop/Megrum_release_prep` | `codex/legal-release-prep` | commit/push済み |

法務・リリース準備branchの最新commitは、作業継続中のため次で確認する:

```text
git log --oneline -1
```

リモート:

```text
origin/codex/legal-release-prep
```

Draft PR:

```text
https://github.com/mashimabizz/Megrum_design/pull/2
```

## 2. 絶対に混ぜないもの

開発側branchでstageしてよいもの:
- `ios-native/`
- `mobile/`
- `web/`
- `supabase/`
- 開発セッションが意図して更新した既存notes

開発側branchでstageしないもの:
- `notes/24_app_store_submission_pack.md` 〜 `notes/75_apple_developer_signing_capabilities_preflight.md`
- `notes/legal/`
- 法務・App Store提出準備だけを目的にした新規docs

理由:
- 法務docsは `codex/legal-release-prep` に正本がある。
- 開発側で `git add -A` すると、実装PRに法務docsが混ざる。
- 共有docsの `notes/08_design_iterations.md`, `notes/17_legal_alignment.md`, `notes/22_release_triage_tracker.csv` は両方のbranchで触る可能性があるため、merge時に確認する。

## 3. 開発側セッションへの短い指示

開発側でコミットするとき:

```bash
git add ios-native mobile web supabase
```

必要なnotesだけ追加する場合:

```bash
git add notes/08_design_iterations.md notes/10_glossary.md notes/22_swift_native_migration.md
```

避ける:

```bash
git add -A
```

## 4. 法務branchのPR化

PRを作るタイミング:
- 開発側のP0実装commitが一段落した後
- 又は、公開URL/法務レビュー作業に着手する前

現在のPR:
- Draft: https://github.com/mashimabizz/Megrum_design/pull/2

PRタイトル案:

```text
[iter378] 法務・App Store提出準備docsを分離
```

PR本文案:

```markdown
## 概要

コード変更なしで、Megrumの法務・App Store審査・リリース運用に必要な準備ドキュメントを追加しました。

## 主な追加

- 利用規約/プライバシーポリシードラフト
- 公開法務/サポートページ原稿
- App Store提出素材、App Privacy、質問票、Review Notes、Go/No-Go
- TestFlight、デモアカウント、スクショ、提出証跡
- Trust & Safety、アカウント削除、個人情報請求、事故初動
- 外部サービス台帳、Privacy Manifest/SDK監査、提出前セキュリティ監査
- 公開FAQ、アプリ内法務・安全コピー
- Release Candidateハンドオフ、提出証跡、公開ページレダクションQA
- 法務レビュー後の公開文面最終化手順
- サポート受信トリアージ手順
- 配信地域・EU DSA・IAP Availability判断
- App Reviewリジェクト/追加情報要求トリアージ手順
- App Store商品ページ素材QA
- App Store Connect最終入力差分QA
- 承認後の手動公開制御手順
- 公開停止・Availability変更手順
- App Store評価・レビュー返信運用
- Apple Developer署名・Capabilities事前確認

## 変更していないもの

- `ios-native/`
- `mobile/`
- `web/`
- `supabase/`
- App Store Connect設定
- 公開URL

## 確認

- CSV parse: `notes/22_release_triage_tracker.csv`
- 旧用語チェック
- `git diff --check -- notes`
```

## 5. merge前チェック

| 確認 | 内容 |
|---|---|
| 開発側の未コミット確認 | `/Users/michitaka/Desktop/Megrum` で `git status --short` を見る |
| 法務branchの最新化 | `git fetch origin` して `origin/codex/legal-release-prep` を確認 |
| 共有docs競合 | `notes/08`, `notes/17`, `notes/22` の競合を手動確認 |
| コード差分なし | PRに `ios-native/`, `mobile/`, `web/`, `supabase/` が入っていないことを確認 |
| 実装との整合 | 完成ビルドで出さない有料機能/外部AI/未完成機能の文言を公開前に削る |

## 6. 競合時の判断

### `notes/08_design_iterations.md`

両方の最新iterを残す。

方針:
- 開発側iterは実装履歴として残す。
- 法務側iterはリリース準備履歴として残す。
- 番号が衝突した場合は、merge時点で上から新しい順に並べ直し、必要なら法務側番号を後続番号へ振り直す。

### `notes/17_legal_alignment.md`

法務branch側の初回提出スコープと、開発側の実装範囲を照合する。

No-Go:
- 初回提出で見える機能が、規約/Privacy/App Privacyから抜ける。
- 初回提出で見えない機能を、公開ページで断定的に説明する。

### `notes/22_release_triage_tracker.csv`

CSV列数を崩さない。

merge後に必ず実行:

```bash
python3 - <<'PY'
import csv
from pathlib import Path
p=Path('notes/22_release_triage_tracker.csv')
rows=list(csv.reader(p.open()))
width=len(rows[0])
bad=[(i+1,len(r),r[:2]) for i,r in enumerate(rows) if len(r)!=width]
if bad:
    raise SystemExit(f'bad rows: {bad[:5]}')
print(f'ok csv rows={len(rows)-1} cols={width} last={rows[-1][0]}')
PY
```

## 7. 元ツリーの掃除方針

すでに実施済み:
- 元ツリーに残っていた未追跡の `notes/24` 〜 `notes/54` と `notes/legal/` は、法務branchへcommit済みのため削除した。

まだ触らない:
- `notes/08_design_iterations.md`
- `notes/10_glossary.md`
- `notes/17_legal_alignment.md`
- `notes/22_release_triage_tracker.csv`
- `notes/22_swift_native_migration.md`
- `notes/21_oshi_encounter_strategy.md`

理由:
- 開発側セッションが更新している可能性があり、法務側の判断だけで戻さない。

## 8. 推奨順序

1. 開発側が現在の実装差分を必要な単位でcommitする。
2. 開発側がRelease Candidate情報を `notes/65_release_candidate_handoff.md` の項目で渡す。
3. 法務branchでPRを作る。
4. PR上でコード差分がないことを確認する。
5. 共有docsの競合だけ手動で解く。
6. 完成ビルドに合わせて、FAQ、アプリ内コピー、App Privacy、Review Notesから未露出機能を削る。
7. 法務レビュー後、公開ページへ流し込む。

## 9. 関連文書

- リリースコントロールボード: `notes/39_release_command_center.md`
- オーナー向けアクションシート: `notes/30_owner_release_action_sheet.md`
- Release Candidateハンドオフ: `notes/65_release_candidate_handoff.md`
- 法務レビュー後公開文面最終化: `notes/66_legal_review_publication_runbook.md`
- サポート受信トリアージ: `notes/67_support_inbox_triage_runbook.md`
- 配信地域・EU DSA・IAP Availability: `notes/68_app_store_territory_dsa_iap_availability.md`
- App Reviewリジェクト/追加情報要求: `notes/69_app_review_rejection_triage_runbook.md`
- App Store商品ページ素材QA: `notes/70_app_store_product_page_asset_qa.md`
- App Store Connect最終入力差分QA: `notes/71_app_store_connect_final_input_reconciliation.md`
- 承認後・手動公開制御: `notes/72_app_store_approval_release_control_runbook.md`
- 公開停止・Availability変更: `notes/73_app_store_availability_emergency_stop_runbook.md`
- App Store評価・レビュー返信: `notes/74_app_store_ratings_reviews_response_runbook.md`
- Apple Developer署名・Capabilities事前確認: `notes/75_apple_developer_signing_capabilities_preflight.md`
- 公開FAQ下書き: `notes/55_public_help_faq_draft.md`
- アプリ内法務・安全コピー: `notes/56_in_app_legal_safety_copy_deck.md`
- リリーストリアージ: `notes/22_release_triage_tracker.csv`
