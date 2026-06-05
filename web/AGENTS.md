<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

## Megrum Web Scope

- `web/` は管理者コンソール専用です。通常ユーザー向けWebアプリは実装しません。
- 残す対象は `/admin`、管理者ログイン、パスワードリセット、認証callback、Stripe webhook など運営に必要なものだけです。
- ユーザー向け画面や導線は `ios-native/` のSwift Native iOSを正とします。Webで再実装しないでください。
