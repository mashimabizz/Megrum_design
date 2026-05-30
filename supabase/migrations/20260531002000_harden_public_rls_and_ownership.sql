-- =====================================================================
-- Megrum: security hardening for public profile reads and ownership checks
-- Date: 2026-05-31
--
-- Fixes:
-- - Avoid exposing non-public profile columns through table-level SELECT.
-- - Keep deleted/suspended users out of public profile reads.
-- - Restrict activity window public reads to authenticated users.
-- - Add WITH CHECK to legacy owner-update policies so owner ids cannot be
--   moved to another account through direct API calls.
-- =====================================================================

-- ---------------------------------------------------------------------
-- users: public profile columns only
-- ---------------------------------------------------------------------
revoke select on table public.users from anon, authenticated;

grant select (
  id,
  handle,
  display_name,
  avatar_url,
  gender,
  primary_area,
  account_status,
  created_at
) on public.users to anon, authenticated;

drop policy if exists "Anyone can read user profiles" on public.users;
drop policy if exists "Anyone can read visible user profiles" on public.users;
drop policy if exists "Users can read own profile" on public.users;
drop policy if exists "Users can update their own profile" on public.users;

create policy "Anyone can read visible user profiles"
  on public.users for select
  using (account_status not in ('deleted', 'suspended'));

create policy "Users can read own profile"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.users for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------
-- user_oshi: keep ownership on all writes
-- ---------------------------------------------------------------------
drop policy if exists "Users can manage their own oshi" on public.user_oshi;

create policy "Users can manage their own oshi"
  on public.user_oshi for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- activity_windows: do not expose live location/time to anonymous clients
-- ---------------------------------------------------------------------
drop policy if exists "Anyone can read enabled aw" on public.activity_windows;
drop policy if exists "Authenticated users can read enabled aw" on public.activity_windows;
drop policy if exists "Users can update their own aw" on public.activity_windows;

create policy "Authenticated users can read enabled aw"
  on public.activity_windows for select
  to authenticated
  using (status = 'enabled');

create policy "Users can update their own aw"
  on public.activity_windows for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- goods_inventory: keep ownership on updates
-- ---------------------------------------------------------------------
drop policy if exists "Users can update their own inventory" on public.goods_inventory;

create policy "Users can update their own inventory"
  on public.goods_inventory for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- proposals: participants can update only while remaining participants
-- ---------------------------------------------------------------------
drop policy if exists "Users can update own proposals" on public.proposals;

create policy "Users can update own proposals"
  on public.proposals for update
  using (auth.uid() = sender_id or auth.uid() = receiver_id)
  with check (auth.uid() = sender_id or auth.uid() = receiver_id);

-- ---------------------------------------------------------------------
-- notifications / disputes: prevent owner/participant transfer on update
-- ---------------------------------------------------------------------
drop policy if exists "Users update own notifications" on public.notifications;

create policy "Users update own notifications"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Participants update own disputes" on public.disputes;

create policy "Participants update own disputes"
  on public.disputes for update
  using (auth.uid() = reporter_id or auth.uid() = respondent_id)
  with check (auth.uid() = reporter_id or auth.uid() = respondent_id);

-- ---------------------------------------------------------------------
-- Groom/Meguri message read-state updates: keep recipient ownership
-- ---------------------------------------------------------------------
drop policy if exists "Users can update own groom views" on public.groom_views;

create policy "Users can update own groom views"
  on public.groom_views for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Recipients can mark groom replies read" on public.groom_replies;

create policy "Recipients can mark groom replies read"
  on public.groom_replies for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

drop policy if exists "Recipients can mark meguri messages read" on public.meguri_messages;

create policy "Recipients can mark meguri messages read"
  on public.meguri_messages for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);
