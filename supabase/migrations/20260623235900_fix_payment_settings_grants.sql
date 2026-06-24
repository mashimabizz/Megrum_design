-- iter749: 支払条件設定をSwift Nativeから読み書きできるようにする権限補正
-- RLSは本人行のみ許可するため、authenticated roleには必要な列/テーブル権限だけを付与する。

grant select (
  age,
  payment_methods,
  payment_note
) on public.users to authenticated;

grant update (
  payment_methods,
  payment_note
) on public.users to authenticated;

grant select, insert, update, delete
  on public.user_payment_settings
  to authenticated;
