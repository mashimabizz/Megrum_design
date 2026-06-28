-- =====================================================================
-- iter1226.102: unlock Meguri messages with current Megrum Premium
-- =====================================================================
-- The legacy Meguri message gate used feature_key='meguri_plus'. Current
-- subscription UI and StoreKit sync grant feature_key='megrum_plus', so
-- locked Meguri messages must treat either entitlement as paid access.

create or replace function public.list_meguri_messages_for_viewer()
returns table (
  id uuid,
  sender_id uuid,
  recipient_id uuid,
  source_groom_reply_id uuid,
  message_type text,
  body text,
  image_url text,
  image_path text,
  read_at timestamptz,
  created_at timestamptz,
  locked boolean,
  sender_display_name text,
  sender_handle text,
  recipient_display_name text,
  recipient_handle text
)
language sql
stable
security definer
set search_path = public
as $$
  with viewer_access as (
    select
      auth.uid() as viewer_id,
      (
        public.has_active_entitlement(auth.uid(), 'megrum_plus')
        or public.has_active_entitlement(auth.uid(), 'meguri_plus')
        or public.has_active_entitlement(auth.uid(), 'premium')
      ) as can_unlock
  )
  select
    message.id,
    message.sender_id,
    message.recipient_id,
    message.source_groom_reply_id,
    message.message_type,
    case
      when message.sender_id = viewer_access.viewer_id
        or viewer_access.can_unlock
      then message.body
      else null
    end as body,
    case
      when message.sender_id = viewer_access.viewer_id
        or viewer_access.can_unlock
      then message.image_url
      else null
    end as image_url,
    case
      when message.sender_id = viewer_access.viewer_id
        or viewer_access.can_unlock
      then message.image_path
      else null
    end as image_path,
    message.read_at,
    message.created_at,
    not (
      message.sender_id = viewer_access.viewer_id
      or viewer_access.can_unlock
    ) as locked,
    sender.display_name as sender_display_name,
    sender.handle as sender_handle,
    recipient.display_name as recipient_display_name,
    recipient.handle as recipient_handle
  from public.meguri_messages message
  cross join viewer_access
  join public.users sender on sender.id = message.sender_id
  join public.users recipient on recipient.id = message.recipient_id
  where viewer_access.viewer_id is not null
    and (
      message.sender_id = viewer_access.viewer_id
      or message.recipient_id = viewer_access.viewer_id
    )
  order by message.created_at asc
  limit 240;
$$;

revoke all on function public.list_meguri_messages_for_viewer() from public;
grant execute on function public.list_meguri_messages_for_viewer() to authenticated;

drop policy if exists "Participants can read unlocked meguri messages"
  on public.meguri_messages;
create policy "Participants can read unlocked meguri messages"
  on public.meguri_messages for select
  using (
    auth.uid() = sender_id
    or (
      auth.uid() = recipient_id
      and (
        public.has_active_entitlement(auth.uid(), 'megrum_plus')
        or public.has_active_entitlement(auth.uid(), 'meguri_plus')
        or public.has_active_entitlement(auth.uid(), 'premium')
      )
    )
  );

create or replace function public.can_view_meguri_message_object(object_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.meguri_messages message
     where message.image_path = object_name
       and (
         message.sender_id = auth.uid()
         or (
           message.recipient_id = auth.uid()
           and (
             public.has_active_entitlement(auth.uid(), 'megrum_plus')
             or public.has_active_entitlement(auth.uid(), 'meguri_plus')
             or public.has_active_entitlement(auth.uid(), 'premium')
           )
         )
       )
  );
$$;

revoke all on function public.can_view_meguri_message_object(text) from public;
grant execute on function public.can_view_meguri_message_object(text) to authenticated;
