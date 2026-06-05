# Megrum Web

`web/` は通常ユーザー向けアプリではなく、管理者コンソール専用です。

- ユーザー向けアプリの主線は `ios-native/` のSwift Native iOSです。
- `mobile/` はlegacy Expo / React Native版の移行元・rollback線です。
- `web/` では今後、管理者機能・運用確認・Webhookなど運営側に必要なものだけを扱います。

## Getting Started

```bash
npm run dev
```

Open [http://localhost:3000/admin](http://localhost:3000/admin) with your browser.

The root route redirects to `/admin`.

## Scope

- Keep: `/admin`, `/login`, `/password-reset`, `/auth/*`, `/api/stripe/webhook`.
- Do not rebuild ordinary user-facing Web app screens here.
