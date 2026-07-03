-- Store enough groom context on Meguri messages to render an Instagram-story-like
-- reply card before the message body.

alter table public.meguri_messages
  add column if not exists source_groom_post_id uuid references public.groom_posts(id) on delete set null,
  add column if not exists source_groom_owner_id uuid references public.users(id) on delete set null,
  add column if not exists source_groom_image_url text;

update public.meguri_messages message
   set source_groom_post_id = coalesce(message.source_groom_post_id, reply.groom_post_id),
       source_groom_owner_id = coalesce(message.source_groom_owner_id, reply.recipient_id),
       source_groom_image_url = coalesce(
         message.source_groom_image_url,
         reply.groom_snapshot ->> 'image_url',
         reply.groom_snapshot ->> 'imageURL'
       )
  from public.groom_replies reply
 where message.source_groom_reply_id = reply.id
   and (
     message.source_groom_post_id is null
     or message.source_groom_owner_id is null
     or message.source_groom_image_url is null
   );

drop function if exists public.list_meguri_messages_for_viewer();

create or replace function public.list_meguri_messages_for_viewer()
returns table (
  id uuid,
  sender_id uuid,
  recipient_id uuid,
  source_groom_reply_id uuid,
  source_groom_post_id uuid,
  source_groom_owner_id uuid,
  source_groom_image_url text,
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
    coalesce(message.source_groom_post_id, source_reply.groom_post_id) as source_groom_post_id,
    coalesce(message.source_groom_owner_id, source_reply.recipient_id) as source_groom_owner_id,
    coalesce(
      message.source_groom_image_url,
      source_reply.groom_snapshot ->> 'image_url',
      source_reply.groom_snapshot ->> 'imageURL'
    ) as source_groom_image_url,
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
  left join public.groom_replies source_reply on source_reply.id = message.source_groom_reply_id
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
