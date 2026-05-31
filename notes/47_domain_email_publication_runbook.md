# 47. ドメイン・メール・公開URL運用ランブック

最終更新: 2026-05-31

ステータス: Draft v0.1（公開作業前）

## 目的

App Store提出前に必要な `megrum.jp` の公開URL、`support@megrum.jp` の受信/送信、DNS、HTTPS、公開証跡を、コード変更なしで確認できる手順へ落とす。

この文書は運用ランブックであり、DNS、ホスティング、メールサービス、公開ページそのものは変更しない。
ドメイン、DNS、メール、サポート担当の権限棚卸しは `notes/61_release_access_owner_registry.md` を使う。
`support@megrum.jp` の受信後の分類、受付番号、優先度、エスカレーションは `notes/67_support_inbox_triage_runbook.md` を使う。

## 1. 公開前に決めること

| 項目 | 候補 | 決定 |
|---|---|---|
| 公開ホスト | Vercel / Cloudflare Pages / GitHub Pages / 既存サーバー | TODO |
| ドメイン管理 | レジストラ / Cloudflare / Route 53等 | TODO |
| DNS管理者 | オーナー / 運用担当 | TODO |
| メール受信 | Google Workspace / iCloud Custom Email / Forward Email等 | TODO |
| メール送信 | 同上、又はサポートツール | TODO |
| サポートツール | Gmail / HelpScout / Zendesk / Notion+メール等 | TODO |
| 証跡保存先 | `notes/36` の証跡台帳、ローカルスクショ | TODO |

## 2. 必須公開URL

| URL | 役割 | 公開条件 |
|---|---|---|
| `https://megrum.jp/support` | App Store Support URL | ログイン不要、200、問い合わせ先あり |
| `https://megrum.jp/legal/privacy` | Privacy Policy URL | ログイン不要、200、最終更新日あり |
| `https://megrum.jp/legal/terms` | 利用規約 | ログイン不要、200、アプリ内リンクと一致 |
| `https://megrum.jp/legal/commerce` | 特商法表示 | 有料機能を出すなら必須 |
| `https://megrum.jp/support/account-deletion` | アカウント削除ヘルプ | ログイン不要、アプリ内削除案内あり |
| `https://megrum.jp/support/privacy-request` | 個人情報請求 | ログイン不要、受付先あり |
| `https://megrum.jp/support/report` | 通報・安全 | UGCを出すなら必須 |
| `https://megrum.jp/support/ai` | AI機能説明 | AI機能を出すなら必須 |

## 3. DNSチェック

### 3.1 Web

確認コマンド案:

```bash
dig megrum.jp A
dig megrum.jp AAAA
dig www.megrum.jp CNAME
dig megrum.jp CAA
```

合格:
- `megrum.jp` が公開ホストへ向いている。
- `www.megrum.jp` の扱いを決めている。
- HTTPS証明書の発行に必要なDNSが整っている。
- 不要な古いレコードが公開ページを別環境へ向けていない。

### 3.2 メール

確認コマンド案:

```bash
dig megrum.jp MX
dig megrum.jp TXT
dig _dmarc.megrum.jp TXT
```

合格:
- MXが受信サービスへ向いている。
- SPFが送信元サービスと一致している。
- DKIMが送信サービス側で有効になっている。
- DMARCが設定されている。

初回は、少なくとも受信確認をP0とし、SPF/DKIM/DMARCは公開前にP0相当に上げる。

## 4. HTTPS / URLチェック

公開後にPCで確認:

```bash
curl -I https://megrum.jp/support
curl -I https://megrum.jp/legal/privacy
curl -I https://megrum.jp/legal/terms
curl -I https://megrum.jp/legal/commerce
curl -I https://megrum.jp/support/account-deletion
curl -I https://megrum.jp/support/privacy-request
curl -I https://megrum.jp/support/report
curl -I https://megrum.jp/support/ai
```

合格:
- 最終的に `200` へ到達する。
- `https://` で証明書エラーがない。
- Basic認証、工事中、404、500ではない。
- App Store Connectへ入力するURLと完全一致している。
- モバイルブラウザで横スクロールや重なりがない。

## 5. メール受信チェック

### 5.1 受信

手順:
1. 外部メールアドレスから `support@megrum.jp` へ送る。
2. 件名に `Megrum support receive test YYYY-MM-DD` を入れる。
3. 受信時刻、差出人、迷惑メール判定を記録する。
4. 添付あり/なしの両方を必要に応じて試す。

合格:
- 5分以内を目安に受信できる。
- 迷惑メールに入らない。
- サポート担当が返信できる。
- 返信先がユーザーから見て自然。

### 5.2 送信

手順:
1. `support@megrum.jp` から外部メールへ返信する。
2. From、Reply-To、署名、フッターを確認する。
3. Gmail、iCloud、キャリアメール相当で到達確認する。

合格:
- 返信が届く。
- Fromが `support@megrum.jp` 又は許容できるサポート名義。
- DKIM/SPF/DMARCが大きく破綻していない。
- 実住所、内部ID、秘密情報が署名やヘッダー表示に出ない。

## 6. 公開ページ本文チェック

| ページ | 確認 |
|---|---|
| Support | 問い合わせ先、カテゴリ、緊急時案内、法務リンク |
| Privacy | App Privacy回答、AI、位置情報、写真、問い合わせ窓口 |
| Terms | 現地交換MVP、禁止事項、通報、AI、IAP候補 |
| Commerce | 有料機能を出す場合の価格、支払、解約、返金、代表者情報方針 |
| Account Deletion | アプリ内削除入口、削除対象、保持対象、IAP解約 |
| Privacy Request | 開示等請求、本人確認、受付先 |
| Report | 通報対象、ブロック、緊急時案内 |
| AI | 外部AIを出す場合の送信情報、目的、学習利用 |

## 7. 証跡保存

`notes/36_submission_evidence_checklist.md` に残すもの:
- `curl -I` の結果
- モバイル表示スクショ
- App Store Connectへ入力したSupport URL / Privacy Policy URL
- `support@megrum.jp` の受信スクショ
- 返信到達スクショ
- DNSレコード確認結果

秘密情報、実メール本文、個人情報が写る場合は、証跡化前にマスクする。

## 8. No-Go

- Support URL又はPrivacy Policy URLが404、500、Basic認証、工事中。
- `support@megrum.jp` が受信できない。
- メール返信が届かない。
- 公開ページの内容が初回ビルドと矛盾している。
- アカウント削除又は個人情報請求ページへログインなしで辿れない。
- 有料機能を出すのに特商法表示が未公開。
- 公開ページに実住所、実パスワード、秘密鍵、内部IDが出ている。

## 9. 関連文書

- 公開ページ文面: `notes/25_public_legal_support_pages.md`
- 公開URLチェックリスト: `notes/37_public_url_publication_checklist.md`
- 提出証跡: `notes/36_submission_evidence_checklist.md`
- アカウント削除・個人情報請求: `notes/45_account_deletion_privacy_request_runbook.md`
- App Store提出司令塔: `notes/39_release_command_center.md`
- リリース権限・運用アカウント台帳: `notes/61_release_access_owner_registry.md`
