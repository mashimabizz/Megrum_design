-- Allow proposal cash amount to represent either side of the exchange.
-- cash_offer=true means one side is a cash amount and the other side is goods.
alter table public.proposals
  drop constraint if exists proposals_cash_offer_consistency;

alter table public.proposals
  add constraint proposals_cash_offer_consistency
  check (
    (
      cash_offer = true
      and cash_amount is not null
      and cash_amount >= 1
      and cash_amount <= 9999999
      and (
        (
          (array_length(sender_have_ids, 1) is null or array_length(sender_have_ids, 1) = 0)
          and array_length(receiver_have_ids, 1) >= 1
        )
        or
        (
          array_length(sender_have_ids, 1) >= 1
          and (array_length(receiver_have_ids, 1) is null or array_length(receiver_have_ids, 1) = 0)
        )
      )
    )
    or
    (
      cash_offer = false
      and cash_amount is null
      and array_length(sender_have_ids, 1) >= 1
      and array_length(receiver_have_ids, 1) >= 1
    )
  );
