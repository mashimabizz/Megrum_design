drop function if exists public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text);
create function public.list_meguri_board_threads_for_viewer(
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default 'nearby_3km'
)
returns table (
  id uuid,
  author_id uuid,
  title text,
  body text,
  image_paths text[],
  category text,
  status text,
  is_pinned boolean,
  audience_scope text,
  spot_key text,
  spot_label text,
  prefecture text,
  origin_lat double precision,
  origin_lng double precision,
  distance_m double precision,
  reply_count integer,
  reaction_count integer,
  bookmark_count integer,
  view_count integer,
  latest_reply_preview text,
  latest_activity_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  viewer_bookmarked boolean,
  viewer_reacted boolean,
  viewer_hidden boolean,
  viewer_reported boolean,
  viewer_subscribed boolean,
  viewer_participated boolean,
  viewer_read_at timestamptz,
  author_display_name text,
  author_handle text,
  author_primary_area text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    thread.id,
    thread.author_id,
    thread.title,
    thread.body,
    thread.image_paths,
    thread.category,
    thread.status,
    thread.is_pinned,
    thread.audience_scope,
    thread.spot_key,
    thread.spot_label,
    thread.prefecture,
    thread.origin_lat,
    thread.origin_lng,
    public.haversine_meters(p_viewer_lat, p_viewer_lng, thread.origin_lat, thread.origin_lng) as distance_m,
    thread.reply_count,
    thread.reaction_count,
    thread.bookmark_count,
    thread.view_count,
    thread.latest_reply_preview,
    thread.latest_activity_at,
    thread.created_at,
    thread.updated_at,
    exists (
      select 1 from public.meguri_board_thread_bookmarks bookmark
      where bookmark.thread_id = thread.id and bookmark.user_id = auth.uid()
    ) as viewer_bookmarked,
    exists (
      select 1 from public.meguri_board_thread_reactions reaction
      where reaction.thread_id = thread.id and reaction.user_id = auth.uid()
    ) as viewer_reacted,
    exists (
      select 1 from public.meguri_board_hidden_threads hidden
      where hidden.thread_id = thread.id and hidden.user_id = auth.uid()
    ) as viewer_hidden,
    exists (
      select 1 from public.meguri_board_reports report
      where report.thread_id = thread.id and report.reporter_id = auth.uid()
    ) as viewer_reported,
    exists (
      select 1 from public.meguri_board_thread_subscriptions subscription
      where subscription.thread_id = thread.id
        and subscription.user_id = auth.uid()
        and subscription.notification_enabled
    ) as viewer_subscribed,
    (
      thread.author_id = auth.uid()
      or exists (
        select 1 from public.meguri_board_replies reply
        where reply.thread_id = thread.id
          and reply.author_id = auth.uid()
          and reply.status = 'visible'
      )
    ) as viewer_participated,
    reads.read_at as viewer_read_at,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area
  from public.meguri_board_threads thread
  join public.users author on author.id = thread.author_id
  left join public.meguri_board_thread_reads reads
    on reads.thread_id = thread.id and reads.user_id = auth.uid()
  where public.can_view_meguri_board_thread_with_context(
    thread.id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  )
    and not exists (
      select 1 from public.meguri_board_hidden_threads hidden
      where hidden.thread_id = thread.id and hidden.user_id = auth.uid()
    )
  order by thread.is_pinned desc, thread.latest_activity_at desc
  limit 120;
end;
$$;

revoke all on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) from public;
grant execute on function public.list_meguri_board_threads_for_viewer(double precision, double precision, text, text) to authenticated;
