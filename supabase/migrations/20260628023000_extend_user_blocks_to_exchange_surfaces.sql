-- =====================================================================
-- iter1224: user blocks apply to exchange discovery surfaces
-- =====================================================================
-- 目的:
-- - 既存の groom_user_blocks をプロフィール/グッズ検索/マッチ候補でも使う。
-- - ブロックした側だけでなく、ブロックされた側も自分に関係する行を読めるようにする。
--   これにより、双方の検索結果・候補表示から相手のグッズを除外できる。

drop policy if exists "Users can read related groom blocks" on public.groom_user_blocks;
create policy "Users can read related groom blocks"
  on public.groom_user_blocks for select
  using (auth.uid() = blocker_id or auth.uid() = blocked_id);

comment on table public.groom_user_blocks is
  'ユーザー間ブロック。めぐり、プロフィール、グッズ検索、マッチ候補の相互非表示に使う。';

-- =====================================================================
-- 完了
-- =====================================================================
