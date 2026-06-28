# suggest-goods-series

Swift Native iOS版のグッズ登録・Wish登録で、画像からシリーズ名称候補を返すSupabase Edge Function。

## Input

```json
{
  "images": [
    {
      "base64": "...",
      "content_type": "image/jpeg"
    }
  ],
  "group_name": "BTS",
  "member_name": "RM",
  "goods_type_name": "トレカ",
  "existing_candidate_names": ["会場限定", "ラキドロ"]
}
```

`images` は最大3件。保存済み画像を使う場合は `url` でも送れます。

## Output

```json
{
  "suggestions": ["会場限定", "ラキドロ"]
}
```

## Required secrets

Set these with `supabase secrets set` before deploy:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`

Optional:

- `MEGRUM_SERIES_SUGGESTION_MODEL` default: `gpt-4.1-mini`

## Authorization

Client apps may call this function with their normal Supabase authenticated JWT.
The function validates the `Authorization: Bearer <access_token>` header against
`/auth/v1/user` before calling OpenAI.

## Local syntax check

```bash
npx tsc --noEmit --target es2022 --lib es2022,dom --module nodenext --moduleResolution nodenext --skipLibCheck supabase/functions/suggest-goods-series/index.ts
```
