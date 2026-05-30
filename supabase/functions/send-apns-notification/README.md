# send-apns-notification

Swift Native iOS版のAPNs端末通知を配送するSupabase Edge Function。

## Input

```json
{
  "notification_id": "00000000-0000-0000-0000-000000000000"
}
```

`notifications` の1行を読み、対象ユーザーの `notification_devices.push_provider='apns'` の有効端末へAPNs alertを送る。

## Required secrets

Set these with `supabase secrets set` before deploy:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `MEGRUM_APNS_TEAM_ID`
- `MEGRUM_APNS_KEY_ID`
- `MEGRUM_APNS_PRIVATE_KEY`
- `MEGRUM_APNS_BUNDLE_ID`

Optional:

- `MEGRUM_APNS_ENVIRONMENT=production|development` default: `production`
- `MEGRUM_APNS_DISPATCH_SECRET`

`MEGRUM_APNS_PRIVATE_KEY` can be stored with escaped newlines.

## Authorization

The function accepts either:

- `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`
- `x-megrum-dispatch-secret: <MEGRUM_APNS_DISPATCH_SECRET>` when the secret is configured

Do not expose this function to client apps. It is for trusted server-side dispatch only.

## Database trigger integration

Migration `20260531005000_dispatch_apns_notifications.sql` calls this function after a `notifications` insert only when both database settings exist:

- `app.settings.apns_dispatch_url`
- `app.settings.apns_dispatch_secret`

Example:

```sql
alter database postgres
  set app.settings.apns_dispatch_url =
    'https://<project-ref>.supabase.co/functions/v1/send-apns-notification';

alter database postgres
  set app.settings.apns_dispatch_secret = '<same value as MEGRUM_APNS_DISPATCH_SECRET>';
```

Keep the dispatch secret out of migrations and source control.

## Local syntax check

This repository does not require Deno to be installed locally. A TypeScript syntax check can be run with:

```bash
npx tsc --noEmit --target es2022 --lib es2022,dom --module nodenext --moduleResolution nodenext --skipLibCheck supabase/functions/send-apns-notification/index.ts
```
