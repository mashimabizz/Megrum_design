-- =====================================================================
-- Megrum: profile evaluation list visibility
-- Date: 2026-05-31
--
-- Other-user profiles need to show the public evaluation list. Existing RLS
-- allowed only proposal participants to read evaluation rows, so profile
-- rating details could be empty even when the target user had evaluations.
-- =====================================================================

create index if not exists idx_user_evaluations_ratee_created_at
  on public.user_evaluations(ratee_id, created_at desc);

create policy "Authenticated users can read profile evaluations"
  on public.user_evaluations for select
  to authenticated
  using (
    exists (
      select 1
      from public.users ratee
      where ratee.id = user_evaluations.ratee_id
        and coalesce(ratee.account_status, 'active') not in ('deleted', 'suspended')
    )
  );

