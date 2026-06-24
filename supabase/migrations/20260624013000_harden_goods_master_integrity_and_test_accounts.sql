-- =====================================================================
-- iter756: ホーム候補のマスター整合と検証アカウント除外印
-- =====================================================================
-- goods_inventory.title は旧UIの自由入力名として残っているが、ホーム候補や
-- マッチング表示の主ソースには使わない。L1/L2/グッズ種別/タグは各マスタを正とする。

alter table public.users
  add column if not exists is_test_account boolean not null default false;

create index if not exists idx_users_is_test_account
  on public.users(is_test_account)
  where is_test_account = true;

comment on column public.users.is_test_account is
  '検証用アカウント。通常ユーザー向けのホーム候補・検索候補から除外する。';

update public.users
   set is_test_account = true,
       account_status = case
         when account_status in ('deleted', 'deletion_requested') then account_status
         else 'suspended'
       end
 where handle like 'codex_mm\_%' escape '\';

comment on column public.goods_inventory.title is
  'Deprecated: 旧UIの自由入力表示名。新規の候補表示・マッチング判定では groups_master / characters_master / goods_types_master / tags_master を正とする。';

create or replace function public.validate_goods_inventory_master_integrity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_character_group_id uuid;
begin
  if new.character_id is not null then
    select cm.group_id
      into v_character_group_id
      from public.characters_master cm
     where cm.id = new.character_id;

    if v_character_group_id is null then
      raise exception 'goods_inventory.character_id is not registered in characters_master: %', new.character_id
        using errcode = '23503';
    end if;

    if new.group_id is null then
      new.group_id := v_character_group_id;
    elsif new.group_id <> v_character_group_id then
      raise exception 'goods_inventory.character_id % does not belong to group_id %', new.character_id, new.group_id
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_goods_inventory_master_integrity on public.goods_inventory;
create trigger trg_goods_inventory_master_integrity
  before insert or update of group_id, character_id, goods_type_id
  on public.goods_inventory
  for each row execute function public.validate_goods_inventory_master_integrity();

revoke all on function public.validate_goods_inventory_master_integrity() from public;
grant execute on function public.validate_goods_inventory_master_integrity() to authenticated;
grant execute on function public.validate_goods_inventory_master_integrity() to service_role;
