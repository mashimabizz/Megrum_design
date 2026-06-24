-- iter760: ホーム相互マッチ取得で users.is_test_account を読めるようにする。
--
-- 20260531002000 で public.users の列SELECTを絞った後、
-- 20260624013000 で追加した is_test_account への列権限が未付与だった。
-- Swift Native のホーム候補取得は通常ユーザーから検証アカウントを除外するため
-- users.is_test_account を読む必要がある。

grant select (is_test_account) on public.users to anon, authenticated;

comment on column public.users.is_test_account is
  '検証/運用確認アカウントを通常候補から除外するための内部フラグ。ホーム候補取得では読み取りのみ利用する。';
