-- =====================================================================
-- iter168.15: groom_posts INSERT ... RETURNING RLS fix
-- =====================================================================
-- Problem:
-- - The groom_posts SELECT policy used only can_view_groom_post(id, auth.uid()).
-- - During PostgREST insert().select() / INSERT ... RETURNING, that helper
--   self-selects groom_posts and can fail to see the just-inserted row.
-- - Plain INSERT succeeds, and SELECT after commit succeeds, but the mobile
--   createGroomPost() path uses insert().select(), so posting fails with 42501.
--
-- Fix:
-- - Allow the owner to SELECT their own groom_posts directly in the policy.
-- - Keep can_view_groom_post() for audience/moderation visibility.

drop policy if exists "Users can read visible groom posts" on public.groom_posts;

create policy "Users can read visible groom posts"
  on public.groom_posts for select
  using (
    auth.uid() = user_id
    or public.can_view_groom_post(id, auth.uid())
  );

-- =====================================================================
-- 完了
-- =====================================================================
