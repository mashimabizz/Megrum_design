-- iter1004: 成立後の取引チャットで支払い情報を相手へ開示するため、
-- 本人専用 user_payment_settings から proposals へ合意時スナップショットを固定する。

alter table public.proposals
  add column if not exists sender_payment_settings jsonb,
  add column if not exists receiver_payment_settings jsonb;

comment on column public.proposals.sender_payment_settings is
  '支払いが必要な取引が合意した時点の送信者支払い設定スナップショット。';

comment on column public.proposals.receiver_payment_settings is
  '支払いが必要な取引が合意した時点の受信者支払い設定スナップショット。';

create or replace function public.respond_to_proposal_for_viewer(
  p_proposal_id uuid,
  p_action text,
  p_accepted_exchange_method text default null
)
returns setof public.proposals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_proposal public.proposals%rowtype;
  v_method text;
  v_sender_agreed boolean;
  v_receiver_agreed boolean;
  v_next_status text;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select *
    into v_proposal
    from public.proposals
   where id = p_proposal_id
   for update;

  if not found then
    raise exception 'proposal not found' using errcode = 'P0002';
  end if;

  if v_user <> v_proposal.sender_id and v_user <> v_proposal.receiver_id then
    raise exception 'not participant' using errcode = '42501';
  end if;

  if v_proposal.status not in ('sent', 'negotiating', 'agreement_one_side') then
    raise exception 'invalid proposal status' using errcode = 'P0001';
  end if;

  if p_action = 'reject' then
    update public.proposals
       set status = 'rejected',
           last_action_at = now()
     where id = v_proposal.id
     returning * into v_proposal;

    return next v_proposal;
    return;
  end if;

  if p_action <> 'agree' then
    raise exception 'invalid proposal action' using errcode = 'P0001';
  end if;

  v_method := v_proposal.exchange_method;
  if v_method = 'both' then
    if p_accepted_exchange_method not in ('hand', 'mail') then
      raise exception 'accepted exchange method required' using errcode = 'P0001';
    end if;
    v_method := p_accepted_exchange_method;
  elsif p_accepted_exchange_method is not null and p_accepted_exchange_method <> v_method then
    raise exception 'accepted exchange method mismatch' using errcode = 'P0001';
  end if;

  v_sender_agreed :=
    case
      when v_user = v_proposal.sender_id then true
      else coalesce(v_proposal.agreed_by_sender, false) or v_proposal.status = 'sent'
    end;
  v_receiver_agreed :=
    case
      when v_user = v_proposal.receiver_id then true
      else coalesce(v_proposal.agreed_by_receiver, false)
    end;
  v_next_status :=
    case
      when v_sender_agreed and v_receiver_agreed then 'agreed'
      else 'agreement_one_side'
    end;

  if v_next_status = 'agreed' then
    perform public.ensure_inventory_available_for_trade(
      v_proposal.sender_id,
      v_proposal.sender_have_ids,
      v_proposal.sender_have_qtys
    );
    perform public.ensure_inventory_available_for_trade(
      v_proposal.receiver_id,
      v_proposal.receiver_have_ids,
      v_proposal.receiver_have_qtys
    );
  end if;

  if v_next_status = 'agreed' and v_method = 'mail' then
    if (
      select count(*)
        from public.user_mailing_addresses a
       where a.user_id in (v_proposal.sender_id, v_proposal.receiver_id)
    ) < 2 then
      raise exception 'mailing address missing' using errcode = 'P0001';
    end if;
  end if;

  update public.proposals
     set agreed_by_sender = v_sender_agreed,
         agreed_by_receiver = v_receiver_agreed,
         exchange_method = v_method,
         status = v_next_status,
         last_action_at = now(),
         sender_mailing_address =
           case
             when v_next_status = 'agreed' and v_method = 'mail' then (
               select to_jsonb(a) - 'user_id' - 'created_at' - 'updated_at'
                 from public.user_mailing_addresses a
                where a.user_id = v_proposal.sender_id
             )
             else sender_mailing_address
           end,
         receiver_mailing_address =
           case
             when v_next_status = 'agreed' and v_method = 'mail' then (
               select to_jsonb(a) - 'user_id' - 'created_at' - 'updated_at'
                 from public.user_mailing_addresses a
                where a.user_id = v_proposal.receiver_id
             )
             else receiver_mailing_address
           end,
         sender_payment_settings =
           case
             when v_next_status = 'agreed' and coalesce(v_proposal.cash_offer, false) then (
               select to_jsonb(s) - 'user_id' - 'created_at' - 'updated_at'
                 from public.user_payment_settings s
                where s.user_id = v_proposal.sender_id
             )
             else sender_payment_settings
           end,
         receiver_payment_settings =
           case
             when v_next_status = 'agreed' and coalesce(v_proposal.cash_offer, false) then (
               select to_jsonb(s) - 'user_id' - 'created_at' - 'updated_at'
                 from public.user_payment_settings s
                where s.user_id = v_proposal.receiver_id
             )
             else receiver_payment_settings
           end
   where id = v_proposal.id
   returning * into v_proposal;

  return next v_proposal;
  return;
end;
$$;
