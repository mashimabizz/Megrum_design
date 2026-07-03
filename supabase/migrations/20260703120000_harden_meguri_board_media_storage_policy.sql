-- =====================================================================
-- iter1226.266: Harden Meguri board media Storage read policy
-- =====================================================================
-- Keep the bucket private and allow signing only for objects that are linked
-- from board content the viewer is allowed to read. The previous policy only
-- checked that the user was authenticated, which made path guessing too broad.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'meguri-board-media',
  'meguri-board-media',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
   set public = false,
       file_size_limit = excluded.file_size_limit,
       allowed_mime_types = excluded.allowed_mime_types;

create index if not exists meguri_board_threads_image_paths_gin_idx
  on public.meguri_board_threads using gin (image_paths);

create index if not exists meguri_board_replies_image_paths_gin_idx
  on public.meguri_board_replies using gin (image_paths);

create or replace function public.can_view_meguri_board_media_object(
  target_name text,
  viewer_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select viewer_id is not null
    and target_name is not null
    and (
      exists (
        select 1
          from public.meguri_board_threads thread
         where coalesce(thread.image_paths, '{}'::text[]) @> array[target_name]
           and public.can_view_meguri_board_thread(thread.id, viewer_id)
      )
      or exists (
        select 1
          from public.meguri_board_replies reply
         where coalesce(reply.image_paths, '{}'::text[]) @> array[target_name]
           and reply.status = 'visible'
           and public.can_view_meguri_board_thread(reply.thread_id, viewer_id)
      )
    );
$$;

revoke all on function public.can_view_meguri_board_media_object(text, uuid) from public;
grant execute on function public.can_view_meguri_board_media_object(text, uuid) to authenticated;

drop policy if exists "Meguri board media readable by authenticated"
  on storage.objects;

drop policy if exists "Meguri board media readable when linked to visible board content"
  on storage.objects;
create policy "Meguri board media readable when linked to visible board content"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'meguri-board-media'
    and public.can_view_meguri_board_media_object(name, auth.uid())
  );
