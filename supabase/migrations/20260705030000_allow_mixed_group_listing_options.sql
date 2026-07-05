-- 1つの選択肢に異なるグループ/種別のほしいものを混在できるようにする。
-- 従来は「選択肢内の wish は全て同じグループ/種別」を強制していたため、
-- 2つ以上のほしいものを自由に選ぶと保存エラーになっていた。
-- wish_group_id / wish_goods_type_id は全アイテムで揃っている場合のみ
-- 自動設定し、混在時は NULL にする（wish_ids があるオプションのマッチングは
-- アイテム単位で行われるため NULL で問題ない）。

create or replace function public.validate_listing_wish_option()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  parent_user uuid;
  parent_have_logic text;
  ref_user uuid;
  ref_kind text;
  ref_group uuid;
  ref_type uuid;
  wid uuid;
  q integer;
  i integer;
  cnt integer;
  first_group uuid;
  first_type uuid;
  groups_uniform boolean := true;
  types_uniform boolean := true;
begin
  -- 親 listing の user_id / have_logic 取得
  select user_id, have_logic into parent_user, parent_have_logic
    from public.listings where id = new.listing_id;
  if parent_user is null then
    raise exception 'parent listing not found';
  end if;

  if new.is_cash_offer then
    -- 定価交換選択肢：wish_ids/qtys は空、cash_amount 必須
    if array_length(new.wish_ids, 1) is not null then
      raise exception '定価交換選択肢では wish_ids は空にしてください';
    end if;
    if new.cash_amount is null then
      raise exception '定価交換選択肢では cash_amount（金額）が必須です';
    end if;
    -- group/goods_type は無視可
  elsif new.wish_ids is null or array_length(new.wish_ids, 1) is null then
    -- 条件指定型（グループ×種別のみ）の選択肢
    if new.cash_amount is not null then
      raise exception 'cash_amount は定価交換選択肢でのみ設定可能です';
    end if;
    if new.wish_group_id is null or new.wish_goods_type_id is null then
      raise exception 'wish_ids must contain at least one item';
    end if;
    if new.wish_qtys is not null and array_length(new.wish_qtys, 1) is not null then
      raise exception '条件指定の選択肢では wish_qtys は空にしてください';
    end if;
  else
    -- 通常選択肢
    if new.cash_amount is not null then
      raise exception 'cash_amount は定価交換選択肢でのみ設定可能です';
    end if;
    if array_length(new.wish_ids, 1) <> array_length(new.wish_qtys, 1) then
      raise exception 'wish_ids と wish_qtys の長さが一致しません';
    end if;

    for i in 1..array_length(new.wish_ids, 1) loop
      wid := new.wish_ids[i];
      q := new.wish_qtys[i];
      if q is null or q < 1 then
        raise exception 'wish_qtys[%] must be >= 1 (got %)', i, q;
      end if;
      select user_id, kind, group_id, goods_type_id
        into ref_user, ref_kind, ref_group, ref_type
        from public.goods_inventory where id = wid;
      if ref_user is null then
        raise exception 'wish_ids[%] not found', i;
      end if;
      if ref_user <> parent_user then
        raise exception 'wish_ids[%] must belong to listing owner', i;
      end if;
      if ref_kind <> 'wanted' then
        raise exception 'wish_ids[%] must be kind=wanted', i;
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

    -- 選択肢内 OR×OR ガード（譲 OR & このオプション OR で両側 ≥2 アイテム）
    if parent_have_logic = 'or'
       and new.logic = 'or'
       and (select array_length(have_ids, 1) from public.listings where id = new.listing_id) > 1
       and array_length(new.wish_ids, 1) > 1 then
      raise exception '譲側 OR × 求側選択肢 OR × 両側 ≥2 アイテムは曖昧なため指定できません';
    end if;

    -- group/goods_type は全アイテムで揃っている場合のみ自動設定（混在は NULL）
    new.wish_group_id := case when groups_uniform then first_group else null end;
    new.wish_goods_type_id := case when types_uniform then first_type else null end;
  end if;

  -- 1 listing あたり最大 5 選択肢
  select count(*) into cnt from public.listing_wish_options
    where listing_id = new.listing_id
      and (TG_OP = 'INSERT' or id <> new.id);
  if cnt >= 5 then
    raise exception '1 listing につき選択肢は最大 5 件までです';
  end if;

  return new;
end;
$$;
