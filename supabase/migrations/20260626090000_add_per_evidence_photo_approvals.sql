-- =====================================================================
-- iter1205: per evidence photo approvals
-- =====================================================================
-- Each evidence photo keeps sender/receiver approval state. The uploader's
-- side is approved by default, and the trade completes only when all evidence
-- photos are approved by both participants.

alter table public.proposal_evidence_photos
  add column if not exists approved_by_sender boolean not null default false,
  add column if not exists approved_by_receiver boolean not null default false;

update public.proposal_evidence_photos e
   set approved_by_sender =
         case
           when e.taken_by = p.sender_id then true
           else coalesce(p.approved_by_sender, false)
         end,
       approved_by_receiver =
         case
           when e.taken_by = p.receiver_id then true
           else coalesce(p.approved_by_receiver, false)
         end
  from public.proposals p
 where p.id = e.proposal_id;

drop function if exists public.approve_trade_evidence_for_viewer(uuid);

create or replace function public.approve_trade_evidence_for_viewer(
  p_proposal_id uuid,
  p_photo_id uuid default null
)
returns setof public.proposals
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_proposal public.proposals%rowtype;
  v_now timestamptz := now();
  v_has_evidence boolean := false;
  v_sender_approved boolean := false;
  v_receiver_approved boolean := false;
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

  select exists (
    select 1
      from public.proposal_evidence_photos
     where proposal_id = p_proposal_id
  )
    into v_has_evidence;

  if not v_has_evidence then
    raise exception 'missing evidence' using errcode = 'P0001';
  end if;

  if p_photo_id is not null and not exists (
    select 1
      from public.proposal_evidence_photos
     where id = p_photo_id
       and proposal_id = p_proposal_id
  ) then
    raise exception 'evidence photo not found' using errcode = 'P0002';
  end if;

  update public.proposal_evidence_photos e
     set approved_by_sender = true
   where e.proposal_id = p_proposal_id
     and e.taken_by = v_proposal.sender_id;

  update public.proposal_evidence_photos e
     set approved_by_receiver = true
   where e.proposal_id = p_proposal_id
     and e.taken_by = v_proposal.receiver_id;

  if v_user = v_proposal.sender_id then
    update public.proposal_evidence_photos
       set approved_by_sender = true
     where proposal_id = p_proposal_id
       and (p_photo_id is null or id = p_photo_id);
  else
    update public.proposal_evidence_photos
       set approved_by_receiver = true
     where proposal_id = p_proposal_id
       and (p_photo_id is null or id = p_photo_id);
  end if;

  select coalesce(bool_and(coalesce(approved_by_sender, false)), false),
         coalesce(bool_and(coalesce(approved_by_receiver, false)), false)
    into v_sender_approved, v_receiver_approved
    from public.proposal_evidence_photos
   where proposal_id = p_proposal_id;

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

revoke all on function public.approve_trade_evidence_for_viewer(uuid, uuid) from public;
grant execute on function public.approve_trade_evidence_for_viewer(uuid, uuid) to authenticated;

comment on function public.approve_trade_evidence_for_viewer(uuid, uuid) is
  'Approves one evidence photo, or all photos when p_photo_id is omitted; completes the trade when every evidence photo is approved by both participants.';
