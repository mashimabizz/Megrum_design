-- ユーザーID（handle）は初回登録後に変更できない（iter1226.304）。
-- 未設定（null/空）→設定の1回だけ許可し、以後の変更はDBレベルで拒否する。
create or replace function public.prevent_user_handle_change()
returns trigger
language plpgsql
as $$
begin
  if old.handle is not null
     and btrim(old.handle) <> ''
     and new.handle is distinct from old.handle then
    raise exception 'ユーザーIDは登録後に変更できません';
  end if;
  return new;
end;
$$;

drop trigger if exists users_prevent_handle_change on public.users;
create trigger users_prevent_handle_change
  before update of handle on public.users
  for each row
  execute function public.prevent_user_handle_change();
