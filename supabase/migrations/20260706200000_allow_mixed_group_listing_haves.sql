-- 個別募集の譲るグッズ（have_ids）の「全て同じグループ／同じ種別」制約を撤廃する（iter1226.310）。
-- 所有者・kind=for_trade・数量の検証は維持。
-- have_group_id / have_goods_type_id は全件で揃っている場合のみ自動設定し、混在時は null。
create or replace function public.validate_listing_haves()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  ref_user uuid;
  ref_kind text;
  ref_group uuid;
  ref_type uuid;
  hid uuid;
  q integer;
  i integer;
  first_group uuid;
  first_type uuid;
  groups_uniform boolean := true;
  types_uniform boolean := true;
begin
  if coalesce(new.have_is_cash_offer, false) then
    new.have_ids := coalesce(new.have_ids, '{}'::uuid[]);
    new.have_qtys := coalesce(new.have_qtys, '{}'::integer[]);

    if coalesce(array_length(new.have_ids, 1), 0) <> 0
       or coalesce(array_length(new.have_qtys, 1), 0) <> 0 then
      raise exception '譲る金額の個別募集では have_ids / have_qtys は空にしてください';
    end if;

    new.have_group_id := null;
    new.have_goods_type_id := null;
    return new;
  end if;

  if new.have_cash_amount is not null then
    raise exception 'have_cash_amount は譲る金額の個別募集でのみ設定可能です';
  end if;

  -- have_ids: 必須・全件検証 + qty >= 1（グループ/種別の混在は許可）
  if new.have_ids is null or array_length(new.have_ids, 1) is null then
    raise exception 'have_ids must contain at least one item';
  end if;

  for i in 1..array_length(new.have_ids, 1) loop
    hid := new.have_ids[i];
    q := new.have_qtys[i];
    if q is null or q < 1 then
      raise exception 'have_qtys[%] must be >= 1 (got %)', i, q;
    end if;
    select user_id, kind, group_id, goods_type_id
      into ref_user, ref_kind, ref_group, ref_type
      from public.goods_inventory where id = hid;
    if ref_user is null then
      raise exception 'have_ids[%]=% not found', i, hid;
    end if;
    if ref_user <> new.user_id then
      raise exception 'have_ids[%] must belong to listing owner', i;
    end if;
    if ref_kind <> 'for_trade' then
      raise exception 'have_ids[%] must be kind=for_trade', i;
    end if;
    if i = 1 then
      first_group := ref_group;
      first_type := ref_type;
    else
      if ref_group is distinct from first_group then
        groups_uniform := false;
      end if;
      if ref_type is distinct from first_type then
        types_uniform := false;
      end if;
    end if;
  end loop;

  -- 揃っている時だけ自動設定（混在時は null＝検索マッチはアイテム単位のロジックに委ねる）
  new.have_group_id := case when groups_uniform then first_group else null end;
  new.have_goods_type_id := case when types_uniform then first_type else null end;

  return new;
end;
$$;
