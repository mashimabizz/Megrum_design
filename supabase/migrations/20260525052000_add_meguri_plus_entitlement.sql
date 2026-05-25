-- Add a dedicated めぐりPlus entitlement and prevent free recipients from
-- reading locked meguri message bodies through direct table SELECT.

alter table public.subscriptions
  drop constraint if exists subscriptions_plan_type_check;

alter table public.subscriptions
  add constraint subscriptions_plan_type_check check (
    plan_type in (
      'premium_monthly',
      'premium_yearly',
      'meguri_plus_monthly',
      'monthly',
      'yearly'
    )
  );

create or replace function public.has_active_entitlement(
  viewer_id uuid,
  requested_feature_key text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.user_entitlements entitlement
     where entitlement.user_id = viewer_id
       and entitlement.feature_key = requested_feature_key
       and entitlement.active = true
       and (
         entitlement.expires_at is null
         or entitlement.expires_at > now()
       )
  );
$$;

revoke all on function public.has_active_entitlement(uuid, text) from public;
grant execute on function public.has_active_entitlement(uuid, text) to authenticated;

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
  select
    message.id,
    message.sender_id,
    message.recipient_id,
    message.source_groom_reply_id,
    message.message_type,
    case
      when message.sender_id = auth.uid()
        or public.has_active_entitlement(auth.uid(), 'meguri_plus')
      then message.body
      else null
    end as body,
    case
      when message.sender_id = auth.uid()
        or public.has_active_entitlement(auth.uid(), 'meguri_plus')
      then message.image_url
      else null
    end as image_url,
    case
      when message.sender_id = auth.uid()
        or public.has_active_entitlement(auth.uid(), 'meguri_plus')
      then message.image_path
      else null
    end as image_path,
    message.read_at,
    message.created_at,
    not (
      message.sender_id = auth.uid()
      or public.has_active_entitlement(auth.uid(), 'meguri_plus')
    ) as locked,
    sender.display_name as sender_display_name,
    sender.handle as sender_handle,
    recipient.display_name as recipient_display_name,
    recipient.handle as recipient_handle
  from public.meguri_messages message
  join public.users sender on sender.id = message.sender_id
  join public.users recipient on recipient.id = message.recipient_id
  where auth.uid() is not null
    and (message.sender_id = auth.uid() or message.recipient_id = auth.uid())
  order by message.created_at asc
  limit 240;
$$;

revoke all on function public.list_meguri_messages_for_viewer() from public;
grant execute on function public.list_meguri_messages_for_viewer() to authenticated;

drop policy if exists "Participants can read meguri messages" on public.meguri_messages;
drop policy if exists "Participants can read unlocked meguri messages" on public.meguri_messages;
create policy "Participants can read unlocked meguri messages"
  on public.meguri_messages for select
  using (
    auth.uid() = sender_id
    or (
      auth.uid() = recipient_id
      and public.has_active_entitlement(auth.uid(), 'meguri_plus')
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
           and public.has_active_entitlement(auth.uid(), 'meguri_plus')
         )
       )
  );
$$;

revoke all on function public.can_view_meguri_message_object(text) from public;
grant execute on function public.can_view_meguri_message_object(text) to authenticated;
