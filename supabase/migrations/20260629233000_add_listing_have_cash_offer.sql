-- iter1226.187: 個別募集の譲る側でも定価/金額指定を保存できるようにする。
-- 既存の実グッズ譲渡は従来通り have_ids 必須のまま維持し、
-- have_is_cash_offer=true の時だけ have_ids/have_qtys の空配列を許可する。

alter table public.listings
  add column if not exists have_is_cash_offer boolean not null default false,
  add column if not exists have_cash_amount integer
    check (have_cash_amount is null or (have_cash_amount >= 1 and have_cash_amount <= 9999999));

alter table public.listings
  drop constraint if exists listings_have_lengths_match,
  drop constraint if exists listings_have_cash_offer_consistency;

alter table public.listings
  add constraint listings_have_lengths_match
  check (
    (
      have_is_cash_offer = true
      and coalesce(array_length(have_ids, 1), 0) = 0
      and coalesce(array_length(have_qtys, 1), 0) = 0
    )
    or (
      have_is_cash_offer = false
      and array_length(have_ids, 1) >= 1
      and array_length(have_ids, 1) = array_length(have_qtys, 1)
    )
  ),
  add constraint listings_have_cash_offer_consistency
  check (
    (
      have_is_cash_offer = true
    )
    or (
      have_is_cash_offer = false
      and have_cash_amount is null
    )
  );

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

  -- have_ids: 必須・全件検証 + qty >= 1 + 同 group + 同 goods_type
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
        raise exception '譲るグッズは全て同じグループでなければなりません（have_ids[%]）', i;
      end if;
      if ref_type is distinct from first_type then
        raise exception '譲るグッズは全て同じ種別でなければなりません（have_ids[%]）', i;
      end if;
    end if;
  end loop;

  -- 自動算出
  new.have_group_id := first_group;
  new.have_goods_type_id := first_type;

  return new;
end;
$$;
