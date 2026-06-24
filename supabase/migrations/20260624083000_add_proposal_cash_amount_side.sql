-- Track which side of a proposal contains a cash amount.
-- This allows a proposal side to include both selected goods and a cash amount.
alter table public.proposals
  add column if not exists cash_amount_side text;

alter table public.proposals
  drop constraint if exists proposals_cash_amount_side_check;

alter table public.proposals
  add constraint proposals_cash_amount_side_check
  check (cash_amount_side is null or cash_amount_side in ('sender', 'receiver'));

update public.proposals
set cash_amount_side = case
  when cash_offer = true
    and cash_amount is not null
    and (array_length(sender_have_ids, 1) is null or array_length(sender_have_ids, 1) = 0)
    and array_length(receiver_have_ids, 1) >= 1
    then 'sender'
  when cash_offer = true
    and cash_amount is not null
    and array_length(sender_have_ids, 1) >= 1
    and (array_length(receiver_have_ids, 1) is null or array_length(receiver_have_ids, 1) = 0)
    then 'receiver'
  else cash_amount_side
end
where cash_offer = true
  and cash_amount is not null
  and cash_amount_side is null;

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
      and cash_amount_side in ('sender', 'receiver')
      and (
        (cash_amount_side = 'sender' and array_length(receiver_have_ids, 1) >= 1)
        or
        (cash_amount_side = 'receiver' and array_length(sender_have_ids, 1) >= 1)
      )
    )
    or
    (
      cash_offer = false
      and cash_amount is null
      and cash_amount_side is null
      and array_length(sender_have_ids, 1) >= 1
      and array_length(receiver_have_ids, 1) >= 1
    )
  );

comment on column public.proposals.cash_amount_side is
  'sender=出す側に金額指定を含む、receiver=受け取る側に金額指定を含む';
