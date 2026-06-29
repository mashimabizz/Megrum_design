# 75. Authメール送信元・Googleログイン設定ランブック

最終更新: 2026-06-29

ステータス: Draft v0.3（Keychain session・refresh token・logout確認を追加 / カスタムURL scheme・認証リダイレクト・ディープリンクの提出前No-Goを追加 / Supabase / Zoho / Google Cloud 管理画面設定待ち）

## 目的

新規登録とパスワード忘れの認証メールを `info@megrum.jp` から送信し、Swift Native iOS版でGoogleアカウント登録・ログインを使える状態にする。

この文書は、コードに含められないSMTPパスワードやGoogle OAuth Secretを管理画面へ入れるための手順である。秘密情報はgitへ保存しない。

## 1. 現在のコード側の前提

- Swift Native iOS版はメール/パスワード登録、パスワードリセット送信、Appleログイン、Google OAuth導線を持つ。
- Google OAuthは `ASWebAuthenticationSession` で `https://megrum.jp/auth/oauth/authorize?provider=google` を開き、Web側Route HandlerでSupabase `/auth/v1/authorize` へ転送する。iOS確認ダイアログにSupabase project refを直接出さず、戻り先は `megrum-preview://auth/callback` または `megrum://auth/callback` にする。
- メール認証で `https://megrum.jp/auth/callback?next=mobile&scheme=...` を経由した場合、Web callbackがSupabase sessionへ交換してからnative callbackへ返す。
- native callbackのfragmentにはaccess token、refresh token、expires情報、token type等が含まれ得る。これらをスクリーンショット、証跡、ログ、FAQ、問い合わせ返信へ不用意に残さない。
- live authでは `KeychainAuthSessionStore` がAuthSessionを端末内Keychainへ保存し、期限切れ又は期限間近のsessionはrefresh tokenで更新される。現行コード確認では `kSecAttrAccessible` / ThisDeviceOnly方針は未明示のため、公開前に方針確認が必要。
- ログアウト時は端末内sessionを先にclearし、その後Supabase logout APIを呼ぶ。リモートlogout失敗時も端末内画面はログアウトへ戻るが、他端末session、OSバックアップ、ブラウザ、メール、外部認証事業者側sessionの即時完全削除は保証しない。
- 新規登録でメール確認待ちになった場合、Swift側は「確認メールを送信しました」と表示し、未認証sessionを保存しない。

## 2. Zoho / DNS

Xserverで取得した `megrum.jp` のDNSに、Zoho Mailが指定するMX、SPF、DKIM、必要ならDMARCを設定する。

確認コマンド:

```bash
dig megrum.jp MX
dig megrum.jp TXT
dig _dmarc.megrum.jp TXT
```

Zoho側で確認:

- `info@megrum.jp` が送受信できる。
- SMTPが有効。
- 2FA有効時はアプリ固有パスワードを用意する。
- SMTP hostは契約種別で異なる可能性がある。Free Organization等は `smtp.zoho.com`、Paid Organizationの独自ドメインアドレスは `smtppro.zoho.com` を候補にする。
- portは `587` + TLS/STARTTLSを第一候補、接続不可なら `465` + SSLを検証する。

参考:

- Zoho SMTP設定: https://www.zoho.com/mail/help/zoho-smtp.html
- Zoho IMAP/SMTP設定: https://www.zoho.com/mail/help/imap-access.html

## 3. Supabase Auth Email / SMTP

Supabase Dashboardで対象projectを開き、Authentication設定を更新する。

### URL Configuration

Site URL:

```text
https://megrum.jp
```

Redirect URLs:

```text
https://megrum.jp/auth/callback
https://megrum.jp/auth/callback?next=mobile&scheme=megrum
https://megrum.jp/auth/callback?next=mobile&scheme=megrum-preview
https://megrum.jp/auth/password-reset-confirm
megrum://auth/callback
megrum-preview://auth/callback
http://localhost:3000/auth/callback
http://localhost:3000/auth/password-reset-confirm
```

### OAuth authorize relay

Swift Native iOSのGoogle OAuth開始URLは、既定で次を使う。

```text
https://megrum.jp/auth/oauth/authorize
```

このRouteは `provider=google` と `megrum://auth/callback` / `megrum-preview://auth/callback` だけを許可し、Supabase `/auth/v1/authorize` へリダイレクトする。`megrum.jp` のWeb環境には `NEXT_PUBLIC_SUPABASE_URL` を設定しておく。

Supabase Custom Domainを別途設定する場合は、`MEGRUM_SUPABASE_URL` をその公式ドメインへ差し替えることで、Google側やSupabase側で見えるcallbackホストもさらにMegrum名義へ寄せられる。

No-Go:
- `MEGRUM_URL_SCHEME`、`MEGRUM_AUTH_EMAIL_REDIRECT_URL`、`MEGRUM_AUTH_OAUTH_AUTHORIZE_URL`、Supabase Redirect URLs、Google Cloud OAuth redirect、Web中継Route、App Store Review Notesが一致していない。
- 本番提出buildで `megrum-preview://auth/callback` だけに戻る、又はpreview buildで `megrum://auth/callback` だけに戻る。
- 認証callbackのaccess token、refresh token、認証code、password reset token、SMTP password、Google OAuth secretを証跡、公開ページ、スクショ、問い合わせテンプレート又はリポジトリに残す。
- Keychain保存session JSON、refresh token、access tokenをログ、サポート証跡、スクショ、CI出力、公開FAQ又はPRへ残す。
- `kSecAttrAccessible`方針、ThisDeviceOnly要否、バックアップ/復元/端末紛失時案内、他端末session失効、logout時clearの確認なしに、logout又は退会で全session/tokenが即時完全削除されると説明する。
- カスタムURL schemeをUniversal Linksや本人確認済みリンクと同等に安全保証する説明をする。

### Email

- Confirm email: ON
- Confirm signup template: `notes/19_email_templates.md` のHTMLを設定
- Reset password template: `notes/19_email_templates.md` のHTMLを設定

### SMTP Settings

- Enable Custom SMTP: ON
- Sender email / Admin email: `info@megrum.jp`
- Sender name: `Megrum`
- Host: Zohoのアカウント種別に合わせて `smtp.zoho.com` または `smtppro.zoho.com`
- Port: `587`
- Username: `info@megrum.jp`
- Password: ZohoのSMTPパスワードまたはアプリ固有パスワード

参考:

- Supabase Custom SMTP: https://supabase.com/docs/guides/auth/auth-smtp
- Supabase Production Checklist: https://supabase.com/docs/guides/deployment/going-into-prod

## 4. Google OAuth

Google Cloud ConsoleでOAuth clientを作成する。

- Application type: Web application
- Authorized JavaScript origins:
  - `https://megrum.jp`
  - 開発時だけ `http://localhost:3000`
- Authorized redirect URI:
  - `https://kwpnlcojzseicqbxefih.supabase.co/auth/v1/callback`
  - local Supabaseを使う時だけ `http://127.0.0.1:54321/auth/v1/callback`

作成したClient ID / Client SecretをSupabase Dashboard → Authentication → Providers → Googleへ入れて有効化する。

参考:

- Supabase Google login: https://supabase.com/docs/guides/auth/social-login/auth-google

## 5. 検証

1. Zoho Web Mailから `info@megrum.jp` の送受信を確認する。
2. Supabase DashboardのSMTP testで外部メールに届くか確認する。
3. Swift Native iOSでメール新規登録し、Fromが `info@megrum.jp` の確認メールが届くことを確認する。
4. 確認メールをタップし、アプリへ戻ってオンボーディングへ進むことを確認する。
5. Swift Native iOSで「パスワードを忘れた場合」から再設定メールが届くことを確認する。
6. Swift Native iOSで「Googleで登録」「Googleでログイン」を試し、Google認証後にアプリへ戻りオンボーディングまたはホームへ進むことを確認する。

## 6. No-Go

- FromがSupabase標準送信元のまま。
- Zoho側でDKIM/SPF/DMARCが未設定、または迷惑メール入りが再現する。
- Supabase Redirect URLにnative callbackがなく、Google認証後にアプリへ戻らない。
- Google CloudのAuthorized redirect URIがSupabase callback URLと一致していない。
- SMTPパスワード、Google Client Secretをgit管理ファイルに書いている。
