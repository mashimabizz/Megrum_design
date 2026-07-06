-- 新規登録が完了できないバグの修正（iter1226.331）。
-- サインアップ時の handle_new_user トリガーは自動生成ハンドル
-- （user_xxxxxxxx）で users 行を作るため、オンボーディング最終保存で
-- ユーザーが選んだIDに変える操作が 20260706180000 のロックに拒否され、
-- 「プロフィールを保存できませんでした」で全新規ユーザーが詰まっていた。
--
-- ルールを「アカウントセットアップ完了（account_status = 'active'）後のみ
-- 変更不可」に修正する。セットアップ前（registered / verified /
-- onboarding）は自動生成ハンドルから本ハンドルへの設定を許可する。
create or replace function public.prevent_user_handle_change()
returns trigger
language plpgsql
as $$
begin
  if old.account_status = 'active'
     and old.handle is not null
     and btrim(old.handle) <> ''
     and new.handle is distinct from old.handle then
    raise exception 'ユーザーIDは登録後に変更できません';
  end if;
  return new;
end;
$$;
