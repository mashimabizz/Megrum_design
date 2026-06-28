-- 支払い方法設定画面のチェック状態を本人専用の詳細行にも保持する。
-- users.payment_methods は検索・候補向けの要約として維持する。

alter table public.user_payment_settings
  add column if not exists payment_methods text[] default '{}';

update public.user_payment_settings
   set payment_methods = '{}'::text[]
 where payment_methods is null;

update public.user_payment_settings s
   set payment_methods = u.payment_methods
  from public.users u
 where u.id = s.user_id
   and coalesce(array_length(s.payment_methods, 1), 0) = 0
   and coalesce(array_length(u.payment_methods, 1), 0) > 0;

alter table public.user_payment_settings
  alter column payment_methods set default '{}',
  alter column payment_methods set not null;

alter table public.user_payment_settings
  drop constraint if exists user_payment_settings_methods_allowed;

alter table public.user_payment_settings
  add constraint user_payment_settings_methods_allowed
  check (
    payment_methods <@ array[
      'bank_transfer',
      'paypay',
      'cash_exchange',
      'other'
    ]::text[]
  );

comment on column public.user_payment_settings.payment_methods is
  '支払い方法設定画面のチェック状態。users.payment_methods と同期し、本人専用設定の再読込にも使う。';
