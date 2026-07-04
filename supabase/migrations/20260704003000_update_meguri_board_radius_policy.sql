-- Align Meguri board visibility with the current product rule:
-- creation stays within 1km, while paid members can view chat rooms outside 1km.

create or replace function public.can_view_meguri_board_thread_with_context(
  target_thread_id uuid,
  viewer_id uuid,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null
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
       and (
         thread.author_id = viewer_id
         or (
           coalesce(p_scope, thread.audience_scope) = 'nearby_3km'
           and thread.audience_scope in ('nearby_3km', 'same_spot')
           and (
             public.has_active_entitlement(viewer_id, 'megrum_plus')
             or public.has_active_entitlement(viewer_id, 'meguri_plus')
             or public.has_active_entitlement(viewer_id, 'premium')
             or (
               p_viewer_lat is not null
               and p_viewer_lng is not null
               and thread.origin_lat is not null
               and thread.origin_lng is not null
               and public.haversine_meters(
                 p_viewer_lat,
                 p_viewer_lng,
                 thread.origin_lat,
                 thread.origin_lng
               ) <= 1000
             )
           )
         )
         or (
           coalesce(p_scope, thread.audience_scope) = 'same_prefecture'
           and thread.audience_scope in ('same_prefecture', 'global')
           and thread.prefecture is not null
           and p_prefecture is not null
           and replace(thread.prefecture, ' ', '') = replace(p_prefecture, ' ', '')
         )
         or (
           coalesce(p_scope, thread.audience_scope) = 'global'
           and thread.audience_scope = 'global'
         )
       )
  );
$$;

revoke all on function public.can_view_meguri_board_thread_with_context(
  uuid,
  uuid,
  double precision,
  double precision,
  text,
  text
) from public;
grant execute on function public.can_view_meguri_board_thread_with_context(
  uuid,
  uuid,
  double precision,
  double precision,
  text,
  text
) to authenticated;
