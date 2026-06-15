-- iter585: ホーム支払い条件判定用の自己申告支払い方法
-- アプリ内決済ではなく、定価交換や差額相談で相手と対応可能な方法が重なるかを見る。

alter table public.users
  add column if not exists payment_methods text[] not null default '{}';

alter table public.users
  drop constraint if exists users_payment_methods_allowed;

alter table public.users
  add constraint users_payment_methods_allowed
  check (
    payment_methods <@ array[
      'bank_transfer',
      'paypay',
      'cash_exchange',
      'other'
    ]::text[]
  );

comment on column public.users.payment_methods is
  '支払い条件の自己申告配列。ホーム判定対象は bank_transfer / paypay / cash_exchange。other は保存・表示用。';
