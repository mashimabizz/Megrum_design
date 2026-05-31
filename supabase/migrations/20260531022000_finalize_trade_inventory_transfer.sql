-- =====================================================================
-- iter366: finalize trade inventory transfer in completion RPC
-- =====================================================================
-- The previous hardened completion RPC marked both offered inventory rows
-- as traded, but did not create the receiver-side keep records or the
-- giver-side traded history records added in iter69/70.

create or replace function public.approve_trade_evidence_for_viewer(p_proposal_id uuid)
returns setof public.proposals
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_proposal public.proposals%rowtype;
  v_now timestamptz := now();
  v_sender_approved boolean;
  v_receiver_approved boolean;
  v_completed_now boolean := false;
begin
  if v_user is null then
    raise exception 'auth required' using errcode = '42501';
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
  v_completed_now := v_sender_approved and v_receiver_approved;

  update public.proposals
     set approved_by_sender = v_sender_approved,
         approved_by_receiver = v_receiver_approved,
         status =
           case
             when v_completed_now then 'completed'
             else status
           end,
         completed_at =
           case
             when v_completed_now then coalesce(completed_at, v_now)
             else completed_at
           end
   where id = v_proposal.id
   returning * into v_proposal;

  if v_completed_now then
    perform public.transfer_completed_trade_inventory(
      v_proposal.id,
      v_proposal.sender_id,
      v_proposal.receiver_id,
      v_proposal.sender_have_ids,
      v_proposal.sender_have_qtys,
      v_now
    );

    perform public.transfer_completed_trade_inventory(
      v_proposal.id,
      v_proposal.receiver_id,
      v_proposal.sender_id,
      v_proposal.receiver_have_ids,
      v_proposal.receiver_have_qtys,
      v_now
    );

    update public.listings
       set status = 'closed'
     where id = v_proposal.listing_id
       and status in ('active', 'paused', 'matched');
  end if;

  return next v_proposal;
  return;
end;
$$;

create or replace function public.transfer_completed_trade_inventory(
  p_proposal_id uuid,
  p_giver_id uuid,
  p_receiver_id uuid,
  p_goods_ids uuid[],
  p_goods_qtys integer[],
  p_completed_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_index integer;
  v_goods public.goods_inventory%rowtype;
  v_qty integer;
  v_transfer_qty integer;
begin
  if coalesce(array_length(p_goods_ids, 1), 0) = 0 then
    return;
  end if;

  for v_index in 1..array_length(p_goods_ids, 1) loop
    v_qty := greatest(coalesce(p_goods_qtys[v_index], 1), 1);

    select *
      into v_goods
      from public.goods_inventory
     where id = p_goods_ids[v_index]
       and user_id = p_giver_id
       and kind = 'for_trade'
     for update;

    if not found then
      raise exception 'offered goods not found or not owned by giver: %', p_goods_ids[v_index]
        using errcode = 'P0002';
    end if;

    v_transfer_qty := least(v_qty, greatest(v_goods.quantity, 1));

    insert into public.goods_inventory (
      user_id,
      kind,
      group_id,
      character_id,
      goods_type_id,
      title,
      description,
      condition,
      quantity,
      photo_urls,
      status,
      series,
      carrying,
      hue,
      character_request_id,
      exchange_type,
      acquired_from_proposal_id,
      acquired_at
    ) values (
      p_receiver_id,
      'for_trade',
      v_goods.group_id,
      v_goods.character_id,
      v_goods.goods_type_id,
      v_goods.title,
      v_goods.description,
      v_goods.condition,
      v_transfer_qty,
      v_goods.photo_urls,
      'keep',
      v_goods.series,
      false,
      v_goods.hue,
      v_goods.character_request_id,
      v_goods.exchange_type,
      p_proposal_id,
      p_completed_at
    );

    insert into public.goods_inventory (
      user_id,
      kind,
      group_id,
      character_id,
      goods_type_id,
      title,
      description,
      condition,
      quantity,
      photo_urls,
      status,
      series,
      carrying,
      hue,
      character_request_id,
      exchange_type,
      traded_via_proposal_id,
      traded_at
    ) values (
      p_giver_id,
      'for_trade',
      v_goods.group_id,
      v_goods.character_id,
      v_goods.goods_type_id,
      v_goods.title,
      v_goods.description,
      v_goods.condition,
      v_transfer_qty,
      v_goods.photo_urls,
      'traded',
      v_goods.series,
      false,
      v_goods.hue,
      v_goods.character_request_id,
      v_goods.exchange_type,
      p_proposal_id,
      p_completed_at
    );

    update public.goods_inventory
       set quantity =
             case
               when quantity > v_transfer_qty then quantity - v_transfer_qty
               else quantity
             end,
           status =
             case
               when quantity > v_transfer_qty then status
               else 'archived'
             end,
           carrying = false
     where id = v_goods.id;
  end loop;
end;
$$;

revoke all on function public.approve_trade_evidence_for_viewer(uuid) from public;
revoke all on function public.transfer_completed_trade_inventory(uuid, uuid, uuid, uuid[], integer[], timestamptz) from public;
grant execute on function public.approve_trade_evidence_for_viewer(uuid) to authenticated;

comment on function public.approve_trade_evidence_for_viewer(uuid) is
  '証跡承認を行ロック付きで処理し、双方承認時に数量減算・受け取りkeep・譲渡履歴・個別募集closedを同一トランザクションで確定する。';
comment on function public.transfer_completed_trade_inventory(uuid, uuid, uuid, uuid[], integer[], timestamptz) is
  '取引完了時の片方向在庫移動を行う内部関数。';

-- =====================================================================
-- 完了
-- =====================================================================
