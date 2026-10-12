-- iter1226.368: 受け取り口座を最大3件（JSONB）で保持し、銀行名だけ相手可視面へ出す。
-- 口座詳細（支店・口座番号・名義）は user_payment_settings に留め、これまで通り本人限定。
-- 銀行名リストは users.payment_bank_names として認証ユーザーに見せ、
-- マッチング（同一銀行）と候補シート表示（例:「銀行振込（A銀行・B銀行）が可能」）に使う。

-- 1) 本人限定の詳細に、口座配列(JSONB)を追加
alter table public.user_payment_settings
  add column if not exists bank_accounts jsonb not null default '[]'::jsonb;

-- 既存の単一口座レコードを配列へバックフィル（銀行名が入っている行のみ）
update public.user_payment_settings
   set bank_accounts = jsonb_build_array(
     jsonb_build_object(
       'id', gen_random_uuid(),
       'bankName', coalesce(bank_name, ''),
       'branchName', coalesce(bank_branch_name, ''),
       'accountType', coalesce(bank_account_type, ''),
       'accountNumber', coalesce(bank_account_number, ''),
       'holder', coalesce(bank_account_holder, '')
     )
   )
 where coalesce(jsonb_array_length(bank_accounts), 0) = 0
   and coalesce(char_length(trim(bank_name)), 0) > 0;

alter table public.user_payment_settings
  drop constraint if exists user_payment_settings_bank_accounts_max;

alter table public.user_payment_settings
  add constraint user_payment_settings_bank_accounts_max
  check (jsonb_array_length(bank_accounts) <= 3);

comment on column public.user_payment_settings.bank_accounts is
  '受け取り口座（最大3件・JSONB配列）。支店/口座番号/名義を含む機微情報のため本人限定。相手には出さない。';

-- 2) 相手可視の銀行名リストを users に追加（機微情報は含めない）
alter table public.users
  add column if not exists payment_bank_names text[] not null default '{}';

alter table public.users
  drop constraint if exists users_payment_bank_names_max;

alter table public.users
  add constraint users_payment_bank_names_max
  check (coalesce(array_length(payment_bank_names, 1), 0) <= 3);

-- 既存の本人設定から銀行名を1件バックフィル（銀行振込を提供している人のみ）
update public.users u
   set payment_bank_names = array[trim(s.bank_name)]
  from public.user_payment_settings s
 where s.user_id = u.id
   and 'bank_transfer' = any(u.payment_methods)
   and coalesce(char_length(trim(s.bank_name)), 0) > 0
   and coalesce(array_length(u.payment_bank_names, 1), 0) = 0;

comment on column public.users.payment_bank_names is
  '相手可視の受け取り銀行名（正規化済み・最大3）。マッチング（同一銀行）と候補表示に使う。口座番号など機微情報は含めない。';
