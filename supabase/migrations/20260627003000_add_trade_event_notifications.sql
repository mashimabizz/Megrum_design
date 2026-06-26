-- =====================================================================
-- iter1219: trade event notifications
-- =====================================================================
-- Exchange events create in-app notification rows. Mobile push delivery
-- remains centralized in send_mobile_push_for_notification(), so
-- user_notification_settings.push_enabled only controls OS push delivery.

alter table public.notifications
  add column if not exists message_id uuid references public.messages(id) on delete cascade,
  add column if not exists evidence_photo_id uuid references public.proposal_evidence_photos(id) on delete cascade,
  add column if not exists evaluation_id uuid references public.user_evaluations(id) on delete cascade;

create index if not exists idx_notifications_message
  on public.notifications(message_id)
  where message_id is not null;

create index if not exists idx_notifications_evidence_photo
  on public.notifications(evidence_photo_id)
  where evidence_photo_id is not null;

create index if not exists idx_notifications_evaluation
  on public.notifications(evaluation_id)
  where evaluation_id is not null;

alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'proposal_received',
      'proposal_accepted',
      'proposal_rejected',
      'proposal_revised',
      'message_received',
      'evidence_added',
      'trade_completed',
      'evaluation_received',
      'dispute_received',
      'dispute_responded',
      'dispute_closed',
      'cancel_requested',
      'expires_soon',
      'groom_reply',
      'meguri_message',
      'meguri_board_reply',
      'meguri_board_mention'
    )
  );

create or replace function public.megrum_notification_actor_name(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    nullif(btrim(profile.display_name), ''),
    nullif(btrim(profile.handle), ''),
    '相手'
  )
  from public.users profile
  where profile.id = p_user_id
$$;

create or replace function public.megrum_notification_text_body(
  p_body text,
  p_limit integer default 100
)
returns text
language sql
immutable
as $$
  with normalized as (
    select btrim(regexp_replace(coalesce(p_body, ''), '\s+', ' ', 'g')) as body
  )
  select case
    when body = '' then null
    when length(body) > greatest(p_limit, 1) then left(body, greatest(p_limit - 1, 1)) || '…'
    else body
  end
  from normalized
$$;

create or replace function public.create_trade_notification(
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_link_path text,
  p_proposal_id uuid default null,
  p_actor_id uuid default null,
  p_message_id uuid default null,
  p_evidence_photo_id uuid default null,
  p_evaluation_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_notification_id uuid;
begin
  if p_user_id is null then
    return null;
  end if;

  if p_actor_id is not null and p_user_id = p_actor_id then
    return null;
  end if;

  insert into public.notifications (
    user_id,
    kind,
    title,
    body,
    link_path,
    proposal_id,
    message_id,
    evidence_photo_id,
    evaluation_id
  )
  select
    p_user_id,
    p_kind,
    left(coalesce(nullif(btrim(p_title), ''), '通知'), 100),
    case
      when p_body is null then null
      else left(p_body, 500)
    end,
    coalesce(nullif(btrim(p_link_path), ''), '/notifications'),
    p_proposal_id,
    p_message_id,
    p_evidence_photo_id,
    p_evaluation_id
  where not exists (
    select 1
    from public.notifications existing
    where existing.user_id = p_user_id
      and existing.kind = p_kind
      and (
        (p_message_id is not null and existing.message_id = p_message_id)
        or (p_evidence_photo_id is not null and existing.evidence_photo_id = p_evidence_photo_id)
        or (p_evaluation_id is not null and existing.evaluation_id = p_evaluation_id)
        or (
          p_message_id is null
          and p_evidence_photo_id is null
          and p_evaluation_id is null
          and p_proposal_id is not null
          and existing.proposal_id = p_proposal_id
        )
      )
  )
  returning id into v_notification_id;

  return v_notification_id;
end;
$$;

create or replace function public.notify_trade_proposal_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_name text;
begin
  if new.sender_id = new.receiver_id then
    return new;
  end if;

  v_actor_name := coalesce(public.megrum_notification_actor_name(new.sender_id), '相手');

  if new.status = 'sent' then
    perform public.create_trade_notification(
      new.receiver_id,
      'proposal_received',
      '打診が届きました',
      v_actor_name || 'さんから打診が届きました',
      '/proposals/' || new.id::text,
      new.id,
      new.sender_id
    );
  elsif new.status in ('negotiating', 'agreement_one_side') then
    perform public.create_trade_notification(
      new.receiver_id,
      'proposal_revised',
      '再打診が届きました',
      v_actor_name || 'さんから再打診が届きました',
      '/proposals/' || new.id::text,
      new.id,
      new.sender_id
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_trade_proposal_insert_notify
  on public.proposals;
create trigger trg_trade_proposal_insert_notify
  after insert on public.proposals
  for each row execute function public.notify_trade_proposal_insert();

create or replace function public.notify_trade_message_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proposal public.proposals%rowtype;
  v_recipient_id uuid;
  v_actor_name text;
  v_kind text := 'message_received';
  v_title text;
  v_body text;
  v_link_path text;
  v_action text;
begin
  select *
    into v_proposal
    from public.proposals
   where id = new.proposal_id;

  if not found then
    return new;
  end if;

  if new.sender_id = v_proposal.sender_id then
    v_recipient_id := v_proposal.receiver_id;
  elsif new.sender_id = v_proposal.receiver_id then
    v_recipient_id := v_proposal.sender_id;
  else
    return new;
  end if;

  v_actor_name := coalesce(public.megrum_notification_actor_name(new.sender_id), '相手');
  v_title := v_actor_name || 'さんからメッセージ';
  v_link_path := '/trades/' || new.proposal_id::text;

  case new.message_type
    when 'text' then
      v_body := public.megrum_notification_text_body(new.body, 100);
      if v_body is null then
        return new;
      end if;
    when 'photo' then
      v_body := '写真が届きました';
    when 'outfit_photo' then
      v_body := '服装写真が共有されました';
    when 'location' then
      v_body := '現在地が共有されました';
    when 'arrival_status' then
      v_body := '到着ステータスが更新されました';
    when 'system' then
      v_action := new.meta ->> 'action';
      if v_action = 'cancel_requested' then
        v_kind := 'cancel_requested';
        v_title := 'キャンセル要請が届きました';
        v_body := v_actor_name || 'さんからキャンセル要請が届きました';
        v_link_path := '/trades/' || new.proposal_id::text || '/cancel-or-late?kind=cancel';
      else
        return new;
      end if;
    else
      return new;
  end case;

  perform public.create_trade_notification(
    v_recipient_id,
    v_kind,
    v_title,
    v_body,
    v_link_path,
    new.proposal_id,
    new.sender_id,
    new.id
  );

  return new;
end;
$$;

drop trigger if exists trg_trade_message_insert_notify
  on public.messages;
create trigger trg_trade_message_insert_notify
  after insert on public.messages
  for each row execute function public.notify_trade_message_insert();

create or replace function public.notify_trade_evidence_photo_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_proposal public.proposals%rowtype;
  v_recipient_id uuid;
begin
  select *
    into v_proposal
    from public.proposals
   where id = new.proposal_id;

  if not found then
    return new;
  end if;

  if new.taken_by = v_proposal.sender_id then
    v_recipient_id := v_proposal.receiver_id;
  elsif new.taken_by = v_proposal.receiver_id then
    v_recipient_id := v_proposal.sender_id;
  else
    return new;
  end if;

  perform public.create_trade_notification(
    v_recipient_id,
    'evidence_added',
    '証跡写真が届きました',
    '内容を確認しましょう',
    '/trades/' || new.proposal_id::text || '/approve',
    new.proposal_id,
    new.taken_by,
    null,
    new.id
  );

  return new;
end;
$$;

drop trigger if exists trg_trade_evidence_photo_insert_notify
  on public.proposal_evidence_photos;
create trigger trg_trade_evidence_photo_insert_notify
  after insert on public.proposal_evidence_photos
  for each row execute function public.notify_trade_evidence_photo_insert();

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
  v_actor_name text;
  v_recipient_id uuid;
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

  v_actor_name := coalesce(public.megrum_notification_actor_name(v_user), '相手');
  v_recipient_id := case
    when v_user = v_proposal.sender_id then v_proposal.receiver_id
    else v_proposal.sender_id
  end;

  if p_action = 'reject' then
    update public.proposals
       set status = 'rejected',
           last_action_at = now()
     where id = v_proposal.id
     returning * into v_proposal;

    perform public.create_trade_notification(
      v_recipient_id,
      'proposal_rejected',
      '打診が見送られました',
      v_actor_name || 'さんが打診を見送りました',
      '/proposals/' || v_proposal.id::text,
      v_proposal.id,
      v_user
    );

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
           end
   where id = v_proposal.id
   returning * into v_proposal;

  if v_next_status = 'agreed' then
    perform public.create_trade_notification(
      v_recipient_id,
      'proposal_accepted',
      '打診が成立しました',
      '取引チャットで詳細を確認しましょう',
      '/trades/' || v_proposal.id::text,
      v_proposal.id,
      v_user
    );
  end if;

  return next v_proposal;
  return;
end;
$$;

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
  v_recipient_id uuid;
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

    v_recipient_id := case
      when v_user = v_proposal.sender_id then v_proposal.receiver_id
      else v_proposal.sender_id
    end;

    perform public.create_trade_notification(
      v_recipient_id,
      'trade_completed',
      '取引が完了しました',
      '評価を完了しましょう',
      '/trades/' || v_proposal.id::text || '/rate',
      v_proposal.id,
      v_user
    );
  end if;

  return next v_proposal;
  return;
end;
$$;

create or replace function public.notify_trade_evaluation_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prior_rater_id uuid;
begin
  perform pg_advisory_xact_lock(hashtext(new.proposal_id::text));

  select evaluation.rater_id
    into v_prior_rater_id
    from public.user_evaluations evaluation
   where evaluation.proposal_id = new.proposal_id
     and evaluation.rater_id <> new.rater_id
   order by evaluation.created_at asc
   limit 1;

  if v_prior_rater_id is null then
    return new;
  end if;

  perform public.create_trade_notification(
    v_prior_rater_id,
    'evaluation_received',
    '評価が完了しました',
    '相手の評価が完了しました',
    '/trades/' || new.proposal_id::text || '/rate',
    new.proposal_id,
    new.rater_id,
    null,
    null,
    new.id
  );

  return new;
end;
$$;

drop trigger if exists trg_trade_evaluation_insert_notify
  on public.user_evaluations;
create trigger trg_trade_evaluation_insert_notify
  after insert on public.user_evaluations
  for each row execute function public.notify_trade_evaluation_insert();

revoke all on function public.megrum_notification_actor_name(uuid) from public;
revoke all on function public.megrum_notification_text_body(text, integer) from public;
revoke all on function public.create_trade_notification(uuid, text, text, text, text, uuid, uuid, uuid, uuid, uuid) from public;
revoke all on function public.notify_trade_proposal_insert() from public;
revoke all on function public.notify_trade_message_insert() from public;
revoke all on function public.notify_trade_evidence_photo_insert() from public;
revoke all on function public.notify_trade_evaluation_insert() from public;
revoke all on function public.respond_to_proposal_for_viewer(uuid, text, text) from public;
revoke all on function public.approve_trade_evidence_for_viewer(uuid, uuid) from public;
grant execute on function public.respond_to_proposal_for_viewer(uuid, text, text) to authenticated;
grant execute on function public.approve_trade_evidence_for_viewer(uuid, uuid) to authenticated;

comment on function public.create_trade_notification(uuid, text, text, text, text, uuid, uuid, uuid, uuid, uuid) is
  '交換関連イベントからnotifications行を作成する内部関数。OSプッシュ配送は既存triggerに委譲する。';
comment on function public.respond_to_proposal_for_viewer(uuid, text, text) is
  '打診の承諾/拒否を行ロック付きで処理し、agreedへの遷移時に提示在庫を市場ロックし通知を作成する。';
comment on function public.approve_trade_evidence_for_viewer(uuid, uuid) is
  '証跡写真を承認し、全写真が双方承認済みになった時に取引完了・在庫移動・通知作成を同一トランザクションで行う。';

-- =====================================================================
-- 完了
-- =====================================================================
