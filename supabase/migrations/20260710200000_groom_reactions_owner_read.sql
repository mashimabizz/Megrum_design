-- iter1226.428: 投稿オーナーが自分の投稿に付いたリアクションを読めるようにする。
--
-- groom_reactions の SELECT ポリシーは「自分の行のみ」（auth.uid() = user_id）
-- だけだったため、投稿オーナーは他ユーザーのいいね行を1行も読めず、
-- 自分のグルームのいいね数・いいねした人一覧・いいね演出が
-- 「自分が押した分（0か1）」で固定されていた。
-- （通知はサーバー側 security definer で生成されるため「通知は来るのに
--   数は増えない」という非対称が起きていた）
--
-- permissive ポリシーはORで合成されるため既存ポリシーはそのまま。
-- いいねした人一覧・likerアバター演出は元々オーナーへの開示を前提とした
-- UI設計であり、20260706150000 の「他人のプロフィール統計では誰が押したか
-- 開示しない」方針とは矛盾しない。

create policy "Post owners can read reactions on own grooms"
  on public.groom_reactions for select
  using (
    exists (
      select 1
      from public.groom_posts gp
      where gp.id = groom_reactions.groom_post_id
        and gp.user_id = auth.uid()
    )
  );
