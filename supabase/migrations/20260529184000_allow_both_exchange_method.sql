-- =====================================================================
-- iter168.82: 現地・郵送どちらもOKの打診
-- =====================================================================
-- 受け渡し方法を現地/郵送の二者択一にせず、どちらも対応可能な
-- 打診を保存できるようにする。

alter table public.proposals
  drop constraint if exists proposals_exchange_method_check;

alter table public.proposals
  add constraint proposals_exchange_method_check
  check (exchange_method in ('hand', 'mail', 'both'));

comment on column public.proposals.exchange_method is
  '提案単位の受け渡し方法。hand=現地交換 / mail=郵送交換 / both=現地・郵送どちらも対応可';

alter table public.proposals
  drop constraint if exists proposals_meetup_required;

alter table public.proposals
  add constraint proposals_meetup_required
  check (
    status = 'draft'
    or (
      exchange_method = 'mail'
      and true
    )
    or (
      exchange_method in ('hand', 'both')
      and meetup_start_at is not null
      and meetup_end_at is not null
      and meetup_end_at > meetup_start_at
      and meetup_place_name is not null
      and meetup_lat is not null
      and meetup_lng is not null
    )
  );
