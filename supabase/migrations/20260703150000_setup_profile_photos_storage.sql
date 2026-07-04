-- =====================================================================
-- iter1226.273: profile-photos Storage bucket setup
-- =====================================================================
-- Purpose:
-- - Store user-uploaded profile icons used by the exchange profile and
--   meguri profile custom avatar URL flow.
-- - Allow each authenticated user to manage only files under their own
--   user_id folder while keeping the bucket public for profile display.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-photos',
  'profile-photos',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Profile photos: users can upload to their own folder" on storage.objects;
create policy "Profile photos: users can upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Profile photos: anyone can view" on storage.objects;
create policy "Profile photos: anyone can view"
  on storage.objects for select
  using (bucket_id = 'profile-photos');

drop policy if exists "Profile photos: users can update their own files" on storage.objects;
create policy "Profile photos: users can update their own files"
  on storage.objects for update
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Profile photos: users can delete their own files" on storage.objects;
create policy "Profile photos: users can delete their own files"
  on storage.objects for delete
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
