-- iter787: 個別募集の「何個以上」ロジック
-- 既存の item ごとの qty は数量として維持し、選択アイテム群の最低成立数を別カラムに分離する。

alter table public.listings
  add column if not exists have_min_count integer not null default 1;

alter table public.listing_wish_options
  add column if not exists min_count integer not null default 1;

alter table public.listings
  drop constraint if exists listings_have_logic_check,
  drop constraint if exists listings_have_min_count_check;

alter table public.listings
  add constraint listings_have_logic_check
  check (have_logic in ('and', 'or', 'at_least')),
  add constraint listings_have_min_count_check
  check (
    (
      have_logic <> 'at_least'
      and have_min_count = 1
    )
    or (
      have_logic = 'at_least'
      and coalesce(array_length(have_ids, 1), 0) >= 2
      and have_min_count between 1 and array_length(have_ids, 1)
    )
  );

alter table public.listing_wish_options
  drop constraint if exists listing_wish_options_logic_check,
  drop constraint if exists listing_wish_options_min_count_check;

alter table public.listing_wish_options
  add constraint listing_wish_options_logic_check
  check (logic in ('and', 'or', 'at_least')),
  add constraint listing_wish_options_min_count_check
  check (
    (
      logic <> 'at_least'
      and min_count = 1
    )
    or (
      logic = 'at_least'
      and is_cash_offer is false
      and coalesce(array_length(wish_ids, 1), 0) >= 2
      and min_count between 1 and array_length(wish_ids, 1)
    )
  );
