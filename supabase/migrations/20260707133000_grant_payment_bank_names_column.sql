-- iter1226.369: payment_bank_names のカラムレベル権限補正。
-- users は列単位GRANT運用（20260531002000 で table-level select を revoke し、必要列だけ grant）。
-- 20260707120000 で payment_bank_names 列を追加した際に GRANT を付け忘れたため、
-- authenticated が payment_bank_names を select できず、users を読む全クエリ（初期スナップショット等）が
-- 403「permission denied for table users」で失敗していた。payment_methods と同形で付与する。

grant select (payment_bank_names) on public.users to authenticated;
grant update (payment_bank_names) on public.users to authenticated;
