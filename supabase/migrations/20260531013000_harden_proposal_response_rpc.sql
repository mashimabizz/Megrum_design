-- =====================================================================
-- iter365: 打診応答と証跡承認をRPCで直列化
-- =====================================================================
-- クライアント側の read -> PATCH では、双方が同時に承諾/承認したときに
-- 後続PATCHが相手の true を false に戻す可能性がある。
-- 行ロック付きRPCに寄せ、参加者確認・状態確認・flag merge・完了処理を
-- 1トランザクション内で行う。

drop function if exists public.respond_to_proposal_for_viewer(uuid, text, text);
create function public.respond_to_proposal_for_viewer(
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
           end
   where id = v_proposal.id
   returning * into v_proposal;

  return next v_proposal;
  return;
end;
$$;

drop function if exists public.approve_trade_evidence_for_viewer(uuid);
create function public.approve_trade_evidence_for_viewer(p_proposal_id uuid)
returns setof public.proposals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_proposal public.proposals%rowtype;
  v_sender_approved boolean;
  v_receiver_approved boolean;
  v_now timestamptz := now();
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

  if v_proposal.status = 'completed' then
    return next v_proposal;
    return;
  end if;

  if v_proposal.status <> 'agreed' then
    raise exception 'invalid proposal status' using errcode = 'P0001';
  end if;

  if v_proposal.evidence_photo_url is null then
    raise exception 'missing evidence' using errcode = 'P0001';
  end if;

  v_sender_approved :=
    case
      when v_user = v_proposal.sender_id then true
      else coalesce(v_proposal.approved_by_sender, false)
    end;
  v_receiver_approved :=
    case
      when v_user = v_proposal.receiver_id then true
      else coalesce(v_proposal.approved_by_receiver, false)
    end;

  update public.proposals
     set approved_by_sender = v_sender_approved,
         approved_by_receiver = v_receiver_approved,
         status =
           case
             when v_sender_approved and v_receiver_approved then 'completed'
             else status
           end,
         completed_at =
           case
             when v_sender_approved and v_receiver_approved then coalesce(completed_at, v_now)
             else completed_at
           end
   where id = v_proposal.id
   returning * into v_proposal;

  if v_proposal.status = 'completed' then
    update public.goods_inventory
       set status = 'traded'
     where user_id = v_proposal.sender_id
       and kind = 'for_trade'
       and id = any(v_proposal.sender_have_ids);

    update public.goods_inventory
       set status = 'traded'
     where user_id = v_proposal.receiver_id
       and kind = 'for_trade'
       and id = any(v_proposal.receiver_have_ids);

    update public.listings
       set status = 'matched'
     where id = v_proposal.listing_id
       and status in ('active', 'paused');
  end if;

  return next v_proposal;
  return;
end;
$$;

revoke all on function public.respond_to_proposal_for_viewer(uuid, text, text) from public;
revoke all on function public.approve_trade_evidence_for_viewer(uuid) from public;
grant execute on function public.respond_to_proposal_for_viewer(uuid, text, text) to authenticated;
grant execute on function public.approve_trade_evidence_for_viewer(uuid) to authenticated;

comment on function public.respond_to_proposal_for_viewer(uuid, text, text) is
  '打診の承諾/拒否を行ロック付きで処理し、同時操作による同意flagのlost updateを防ぐ。';
comment on function public.approve_trade_evidence_for_viewer(uuid) is
  '証跡承認を行ロック付きで処理し、双方承認時に取引完了・提示在庫traded・個別募集matchedを確定する。';
