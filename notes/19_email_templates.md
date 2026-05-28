# Supabase Auth メールテンプレート（Megrum 日本語版）

> Supabase Dashboard → **Authentication → Email Templates** で各テンプレを設定する。
> 反映：保存後すぐ次回送信から有効。

## 設定するテンプレート

| 種類 | 用途 | Megrum での使用 | 優先度 |
|---|---|---|---|
| **Confirm signup** | 新規登録時のメール認証 | ⭕ 必須 | ★★★ |
| **Reset Password** | パスワードリセット | ⭕ 実装済 | ★★★ |
| **Magic Link** | パスワードレス認証 | △ 後で | ☆ |
| **Change Email** | メアド変更時の確認 | △ Phase 1+ | ☆ |
| **Invite User** | 運営からの招待 | △ Phase 2+ | ☆ |
| **Reauthentication** | センシティブ操作再認証 | △ Phase 1+ | ☆ |

このドキュメントでは ★★★ の 2 つを記載。残りは必要時に追加。

---

## ブランド設定

```
ロゴ:        Mg（角丸正方形 + 紫→水色グラデ）
プライマリ:  #a695d8 (lavender)
セカンダリ:  #a8d4e6 (sky)
アクセント:  #f3c5d4 (pink)
背景:        #fbf9fc
本文色:      #1a1a26
muted:       #6b6478
フォント:    Noto Sans JP
```

---

## 1. Confirm signup（新規登録メール認証）

### Subject

```
【Megrum】メールアドレスを認証してください
```

### Body（HTML）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 40px 20px; font-family: 'Noto Sans JP', -apple-system, BlinkMacSystemFont, 'Hiragino Sans', sans-serif; background: #fbf9fc; color: #1a1a26;">

<div style="max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 14px; padding: 40px 32px; box-shadow: 0 4px 14px rgba(166,149,216,0.15);">

  <!-- ロゴ -->
  <div style="text-align: center; margin-bottom: 24px;">
    <div style="display: inline-block; width: 72px; height: 72px; border-radius: 23px; background: linear-gradient(135deg, #a695d8, #a8d4e6); color: #ffffff; font-size: 30px; font-weight: 800; line-height: 72px; letter-spacing: -1px; font-family: -apple-system, sans-serif;">Mg</div>
  </div>

  <!-- タイトル -->
  <h1 style="font-size: 22px; font-weight: 800; color: #1a1a26; text-align: center; margin: 0 0 12px;">
    Megrum へようこそ！
  </h1>

  <p style="font-size: 14px; line-height: 1.7; color: #6b6478; text-align: center; margin: 0 0 32px;">
    ご登録ありがとうございます。<br>
    下のボタンをクリックして、メールアドレスの認証を完了してください。
  </p>

  <!-- CTA ボタン -->
  <div style="text-align: center; margin: 0 0 24px;">
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 14px 36px; background: linear-gradient(135deg, #a695d8, #a8d4e6); color: #ffffff; font-weight: 700; font-size: 14px; text-decoration: none; border-radius: 14px; letter-spacing: 0.3px; box-shadow: 0 4px 14px rgba(166,149,216,0.33);">
      メールアドレスを認証する
    </a>
  </div>

  <!-- 補足リンク -->
  <p style="font-size: 11px; line-height: 1.7; color: #999; text-align: center; margin: 0 0 24px;">
    ボタンが動作しない場合は、以下の URL をブラウザに貼り付けてアクセスしてください：<br>
    <a href="{{ .ConfirmationURL }}" style="color: #a695d8; word-break: break-all;">{{ .ConfirmationURL }}</a>
  </p>

  <!-- 注意書き -->
  <div style="background: #f3c5d422; border-radius: 12px; padding: 14px 16px; font-size: 11px; color: #6b6478; line-height: 1.7;">
    <strong style="color: #1a1a26;">📧 このメールは送信専用です</strong><br>
    ご返信いただいてもお答えできません。お問い合わせは下記までお願いいたします。
  </div>

  <!-- フッター -->
  <div style="margin-top: 28px; padding-top: 20px; border-top: 1px solid #eee; text-align: center; font-size: 11px; color: #999; line-height: 1.7;">
    Megrum - 推し活グッズ交換プラットフォーム<br>
    <a href="https://megrum.jp" style="color: #a695d8; text-decoration: none;">https://megrum.jp</a><br>
    お問い合わせ：<a href="mailto:support@megrum.jp" style="color: #a695d8; text-decoration: none;">support@megrum.jp</a>
  </div>

</div>

<p style="text-align: center; font-size: 10px; color: #aaa; margin: 16px 0 0;">
  このメールに心当たりがない場合は、お手数ですが破棄してください。
</p>

</body>
</html>
```

### 利用変数
- `{{ .ConfirmationURL }}` — Supabase が自動生成する認証 URL（`/auth/callback?code=xxx`）

---

## 2. Reset Password（パスワードリセット）

### Subject

```
【Megrum】パスワードリセットのご案内
```

### Body（HTML）

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 40px 20px; font-family: 'Noto Sans JP', -apple-system, BlinkMacSystemFont, 'Hiragino Sans', sans-serif; background: #fbf9fc; color: #1a1a26;">

<div style="max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 14px; padding: 40px 32px; box-shadow: 0 4px 14px rgba(166,149,216,0.15);">

  <!-- ロゴ -->
  <div style="text-align: center; margin-bottom: 24px;">
    <div style="display: inline-block; width: 72px; height: 72px; border-radius: 23px; background: linear-gradient(135deg, #a695d8, #a8d4e6); color: #ffffff; font-size: 30px; font-weight: 800; line-height: 72px; letter-spacing: -1px; font-family: -apple-system, sans-serif;">Mg</div>
  </div>

  <!-- タイトル -->
  <h1 style="font-size: 22px; font-weight: 800; color: #1a1a26; text-align: center; margin: 0 0 12px;">
    パスワードを再設定する
  </h1>

  <p style="font-size: 14px; line-height: 1.7; color: #6b6478; text-align: center; margin: 0 0 32px;">
    パスワードリセットのリクエストを受け付けました。<br>
    下のボタンから新しいパスワードを設定してください。
  </p>

  <!-- CTA ボタン -->
  <div style="text-align: center; margin: 0 0 24px;">
    <a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 14px 36px; background: linear-gradient(135deg, #a695d8, #a8d4e6); color: #ffffff; font-weight: 700; font-size: 14px; text-decoration: none; border-radius: 14px; letter-spacing: 0.3px; box-shadow: 0 4px 14px rgba(166,149,216,0.33);">
      パスワードを再設定する
    </a>
  </div>

  <!-- 補足リンク -->
  <p style="font-size: 11px; line-height: 1.7; color: #999; text-align: center; margin: 0 0 24px;">
    ボタンが動作しない場合は、以下の URL をブラウザに貼り付けてアクセスしてください：<br>
    <a href="{{ .ConfirmationURL }}" style="color: #a695d8; word-break: break-all;">{{ .ConfirmationURL }}</a>
  </p>

  <!-- 注意書き -->
  <div style="background: #f3c5d422; border-radius: 12px; padding: 14px 16px; font-size: 11px; color: #6b6478; line-height: 1.7;">
    <strong style="color: #1a1a26;">⏱ このリンクは 1 時間で期限切れになります</strong><br>
    心当たりがない場合は、お手数ですがこのメールを破棄してください。第三者による不正なリクエストの可能性があります。
  </div>

  <!-- フッター -->
  <div style="margin-top: 28px; padding-top: 20px; border-top: 1px solid #eee; text-align: center; font-size: 11px; color: #999; line-height: 1.7;">
    Megrum - 推し活グッズ交換プラットフォーム<br>
    <a href="https://megrum.jp" style="color: #a695d8; text-decoration: none;">https://megrum.jp</a><br>
    お問い合わせ：<a href="mailto:support@megrum.jp" style="color: #a695d8; text-decoration: none;">support@megrum.jp</a>
  </div>

</div>

</body>
</html>
```

### 利用変数
- `{{ .ConfirmationURL }}` — `/auth/password-reset-confirm?code=xxx`（後の iter で実装する画面）

---

## 3. 設定手順（Supabase Dashboard）

1. https://supabase.com/dashboard/project/kwpnlcojzseicqbxefih/auth/templates を開く
2. **Confirm signup** タブ
   - **Subject heading** に上記の件名をペースト
   - **Message body** に上記 HTML 全文をペースト
   - **Save changes**
3. **Reset password** タブ
   - 同様に件名と本文をペースト
   - **Save changes**
4. テスト送信
   - signup を試して、新しいテンプレが届くか確認
   - パスワードリセットも同様

> 💡 Supabase 組み込み SMTP からではなく、Brevo SMTP（iter55 で設定済）から送信されるため、この HTML がそのまま届きます。

---

## 4. 将来追加するテンプレ（メモ）

### Magic Link（パスワードレス）
- Subject: `【Megrum】ログイン用のリンクです`
- Confirm signup と同じデザインで、CTA は「ログインする」

### Change Email（メアド変更）
- Subject: `【Megrum】メールアドレス変更の確認`
- 「新しいメールアドレスを認証する」CTA

### Invite User（運営招待）
- Phase 2+ で運営からモデレーター招待時に使用
