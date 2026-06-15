-- =====================================================================
-- iter586: goods inventory market lock for home matching
-- =====================================================================
-- Home/search/proposal/listing surfaces should use market_available_qty,
-- not raw quantity, so inventory that is already committed to an agreed
-- trade does not keep appearing as tradeable stock.

alter table public.goods_inventory
  add column if not exists locked_qty integer not null default 0
    check (locked_qty >= 0);

alter table public.goods_inventory
  add column if not exists market_available_qty integer
    generated always as (greatest(quantity - locked_qty, 0)) stored;

comment on column public.goods_inventory.locked_qty is
  'agreed かつ未完了の打診で確保済みの数量。ホーム/検索/打診候補から除外するために使う。';
comment on column public.goods_inventory.market_available_qty is
  'マッチング市場に出せる残数。quantity - locked_qty を0下限で生成する。';

create index if not exists idx_goods_inventory_market_available
  on public.goods_inventory(kind, status, market_available_qty)
  where kind = 'for_trade' and status = 'active';

create or replace function public.recalculate_goods_inventory_locked_qty(p_goods_ids uuid[])
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(array_length(p_goods_ids, 1), 0) = 0 then
    return;
  end if;

  with target_ids as (
    select distinct id
      from unnest(p_goods_ids) as t(id)
     where id is not null
  ),
  proposal_locks as (
    select lock_rows.goods_id, sum(lock_rows.qty)::integer as locked_qty
      from public.proposals p
      cross join lateral (
        select goods_id, greatest(coalesce(qty, 1), 1) as qty
          from unnest(p.sender_have_ids, p.sender_have_qtys) as sender_goods(goods_id, qty)
        union all
        select goods_id, greatest(coalesce(qty, 1), 1) as qty
          from unnest(p.receiver_have_ids, p.receiver_have_qtys) as receiver_goods(goods_id, qty)
      ) lock_rows
      join target_ids target on target.id = lock_rows.goods_id
     where p.status = 'agreed'
     group by lock_rows.goods_id
  )
  update public.goods_inventory gi
     set locked_qty = least(gi.quantity, coalesce(pl.locked_qty, 0))
    from target_ids target
    left join proposal_locks pl on pl.goods_id = target.id
   where gi.id = target.id;
end;
$$;

create or replace function public.refresh_goods_inventory_locks_for_proposal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_goods_ids uuid[] := '{}';
begin
  if tg_op in ('UPDATE', 'DELETE') then
    v_goods_ids :=
      v_goods_ids
      || coalesce(old.sender_have_ids, '{}')
      || coalesce(old.receiver_have_ids, '{}');
  end if;

  if tg_op in ('INSERT', 'UPDATE') then
    v_goods_ids :=
      v_goods_ids
      || coalesce(new.sender_have_ids, '{}')
      || coalesce(new.receiver_have_ids, '{}');
  end if;

  select array_agg(distinct goods_id)
    into v_goods_ids
    from unnest(v_goods_ids) as changed(goods_id)
   where goods_id is not null;

  perform public.recalculate_goods_inventory_locked_qty(v_goods_ids);

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_proposals_refresh_inventory_locks on public.proposals;
drop trigger if exists trg_proposals_refresh_inventory_locks_delete on public.proposals;
create trigger trg_proposals_refresh_inventory_locks
  after insert or update of status, sender_have_ids, sender_have_qtys, receiver_have_ids, receiver_have_qtys
  on public.proposals
  for each row execute function public.refresh_goods_inventory_locks_for_proposal();

create trigger trg_proposals_refresh_inventory_locks_delete
  after delete on public.proposals
  for each row execute function public.refresh_goods_inventory_locks_for_proposal();

create or replace function public.ensure_inventory_available_for_trade(
  p_owner_id uuid,
  p_goods_ids uuid[],
  p_goods_qtys integer[]
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
  v_goods public.goods_inventory%rowtype;
  v_required integer;
  v_available integer;
begin
  if coalesce(array_length(p_goods_ids, 1), 0) = 0 then
    return;
  end if;

  for v_item in
    select goods_id, sum(qty)::integer as qty
      from (
        select goods_id, greatest(coalesce(qty, 1), 1) as qty
          from unnest(p_goods_ids, p_goods_qtys) as requested(goods_id, qty)
      ) requested_rows
     where goods_id is not null
     group by goods_id
  loop
    v_required := greatest(coalesce(v_item.qty, 1), 1);

    select *
      into v_goods
      from public.goods_inventory
     where id = v_item.goods_id
       and user_id = p_owner_id
       and kind = 'for_trade'
     for update;

    if not found then
      raise exception 'offered goods not found or not owned: %', v_item.goods_id
        using errcode = 'P0002';
    end if;

    if v_goods.status <> 'active' then
      raise exception 'offered goods is not active: %', v_item.goods_id
        using errcode = 'P0001';
    end if;

    v_available := greatest(coalesce(v_goods.quantity, 0) - coalesce(v_goods.locked_qty, 0), 0);
    if v_available < v_required then
      raise exception 'offered goods has no market stock: %', v_item.goods_id
        using errcode = 'P0001';
    end if;
  end loop;
end;
$$;

-- Backfill locks for already-agreed proposals.
select public.recalculate_goods_inventory_locked_qty(array_agg(id))
  from public.goods_inventory
 where kind = 'for_trade';

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
           locked_qty = greatest(locked_qty - v_transfer_qty, 0),
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

revoke all on function public.recalculate_goods_inventory_locked_qty(uuid[]) from public;
revoke all on function public.refresh_goods_inventory_locks_for_proposal() from public;
revoke all on function public.ensure_inventory_available_for_trade(uuid, uuid[], integer[]) from public;
revoke all on function public.respond_to_proposal_for_viewer(uuid, text, text) from public;
revoke all on function public.transfer_completed_trade_inventory(uuid, uuid, uuid, uuid[], integer[], timestamptz) from public;
grant execute on function public.respond_to_proposal_for_viewer(uuid, text, text) to authenticated;

comment on function public.ensure_inventory_available_for_trade(uuid, uuid[], integer[]) is
  '打診成立直前に提示在庫の market_available_qty が要求数量以上あることを行ロック付きで確認する。';
comment on function public.recalculate_goods_inventory_locked_qty(uuid[]) is
  'agreed かつ未完了の打診から goods_inventory.locked_qty を再計算する。';
comment on function public.transfer_completed_trade_inventory(uuid, uuid, uuid, uuid[], integer[], timestamptz) is
  '取引完了時の片方向在庫移動を行い、在庫ロックを解除しながら履歴行を残す内部関数。';
comment on function public.respond_to_proposal_for_viewer(uuid, text, text) is
  '打診の承諾/拒否を行ロック付きで処理し、agreed への遷移時に提示在庫を市場ロックする。';

-- =====================================================================
-- 完了
-- =====================================================================
