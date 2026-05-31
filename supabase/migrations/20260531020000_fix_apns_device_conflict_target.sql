-- =====================================================================
-- iter366: APNs device registration conflict target
-- =====================================================================
-- Swift Native iOS registers APNs device tokens through PostgREST upsert
-- with on_conflict=user_id,push_provider,native_device_token.
-- The earlier APNs migration added a partial unique index on
-- (user_id, native_device_token), which is not a clean PostgREST conflict
-- target for the Swift request shape. Add a non-partial unique index that
-- matches the APNs upsert while leaving the existing Expo token constraint
-- and delivery path untouched.
-- =====================================================================

with ranked_native_devices as (
  select
    id,
    row_number() over (
      partition by user_id, push_provider, native_device_token
      order by
        (revoked_at is null) desc,
        last_seen_at desc nulls last,
        updated_at desc nulls last,
        created_at desc nulls last,
        id
    ) as rank
  from public.notification_devices
  where native_device_token is not null
)
delete from public.notification_devices device
using ranked_native_devices ranked
where device.id = ranked.id
  and ranked.rank > 1;

create unique index if not exists idx_notification_devices_user_provider_native_token
  on public.notification_devices(user_id, push_provider, native_device_token);

comment on index public.idx_notification_devices_user_provider_native_token is
  'PostgREST upsert conflict target for Swift Native APNs device token registration.';

notify pgrst, 'reload schema';

-- =====================================================================
-- 完了
-- =====================================================================
