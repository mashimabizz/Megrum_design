-- 取引成立前の打診取り下げを「物理削除」にする。
-- 取り下げられた打診はデータとして残さない（完了済み一覧にも出さない）。
-- messages / proposal_read_states / evidence 等は FK の on delete cascade で
-- 連鎖削除される。成立後（agreed/completed）の取引は対象外。

create or replace function public.withdraw_proposal_before_agreement(
  p_proposal_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid;
  v_status text;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select sender_id, status into v_sender, v_status
    from public.proposals
   where id = p_proposal_id
   for update;

  if v_sender is null then
    -- 既に存在しない場合は成功扱い（冪等）
    return;
  end if;
  if v_sender <> auth.uid() then
    raise exception '自分が送った打診のみ取り下げできます';
  end if;
  if v_status not in ('draft', 'sent', 'negotiating', 'agreement_one_side') then
    raise exception '成立後の取引は取り下げできません';
  end if;

  delete from public.proposals where id = p_proposal_id;
end;
$$;

revoke all on function public.withdraw_proposal_before_agreement(uuid) from public;
grant execute on function public.withdraw_proposal_before_agreement(uuid) to authenticated;
