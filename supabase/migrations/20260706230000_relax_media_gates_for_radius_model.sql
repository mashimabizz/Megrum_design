-- 新規ユーザーがグルーム画像・チャットルーム画像を読み込めない問題の修正（iter1226.333）。
--
-- 現行プロダクトの閲覧モデルは「地図＋1km半径」（半径判定は位置情報を使って
-- クライアント／フィードRPCで行う）だが、画像（Storage署名URL）のゲート関数が
-- 旧モデルのままだった：
--   - グルーム: audience_user_ids への包含 or 登録エリア一致が必要
--   - チャットルーム: 閲覧者の登録エリア（users.primary_area）とルームの
--     都道府県の一致が必要
-- そのため、encounter履歴が無い新規ユーザーや、登録エリアと違う場所にいる
-- ユーザーは、フィードには出るのに画像だけ読めなかった。
--
-- フィードRPC（list_groom_feed_nearby / board系）と同じ基準に合わせ、
-- 「認証済み・公開中・未失効・非表示/ブロック除外」まで緩和する。
-- 距離ルール（1km開封）は従来どおりクライアント側で強制する。

create or replace function public.can_view_groom_post(post_id uuid, viewer_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.groom_posts gp
     where gp.id = post_id
       and viewer_id is not null
       and not exists (
         select 1 from public.groom_hidden_posts hidden
          where hidden.user_id = viewer_id
            and hidden.groom_post_id = gp.id
       )
       and not exists (
         select 1 from public.groom_user_blocks block
          where (
            block.blocker_id = viewer_id
            and block.blocked_id = gp.user_id
          )
          or (
            block.blocker_id = gp.user_id
            and block.blocked_id = viewer_id
          )
       )
       and (
         gp.user_id = viewer_id
         or (
           gp.status = 'published'
           and gp.expires_at > now()
         )
       )
  );
$$;

revoke all on function public.can_view_groom_post(uuid, uuid) from public;
grant execute on function public.can_view_groom_post(uuid, uuid) to authenticated;

create or replace function public.can_view_meguri_board_thread(
  target_thread_id uuid,
  viewer_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.meguri_board_threads thread
     where thread.id = target_thread_id
       and viewer_id is not null
       and thread.status in ('visible', 'locked')
       and thread.expires_at > now()
       and not exists (
         select 1 from public.groom_user_blocks block
          where (
            block.blocker_id = viewer_id
            and block.blocked_id = thread.author_id
          )
          or (
            block.blocker_id = thread.author_id
            and block.blocked_id = viewer_id
          )
       )
  );
$$;

revoke all on function public.can_view_meguri_board_thread(uuid, uuid) from public;
grant execute on function public.can_view_meguri_board_thread(uuid, uuid) to authenticated;
