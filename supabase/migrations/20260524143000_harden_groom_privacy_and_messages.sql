-- =====================================================================
-- iter165: Groom privacy, moderation, and Meguri message persistence
-- =====================================================================
-- 目的:
-- - グルームの「めぐりあった人」公開をDB/RLS/Storageまで閉じる
-- - 自分の投稿削除、他人の投稿非表示、通報、ブロックをDBで管理する
-- - グルーム返信後のめぐりあい会話を永続化する

-- ---------------------------------------------------------------------
-- 1. Groom visibility helpers
-- ---------------------------------------------------------------------
create or replace function public.groom_audience_for_user(author_id uuid)
returns uuid[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(candidate.id order by candidate.updated_at desc), '{}'::uuid[])
  from (
    select u.id, u.updated_at
      from public.users author
      join public.users u
        on author.primary_area is not null
       and u.primary_area = author.primary_area
       and u.id <> author.id
       and u.account_status = 'active'
     where author.id = author_id
     order by u.updated_at desc
     limit 200
  ) candidate;
$$;

revoke all on function public.groom_audience_for_user(uuid) from public;
grant execute on function public.groom_audience_for_user(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 2. Groom moderation tables
-- ---------------------------------------------------------------------
create table if not exists public.groom_hidden_posts (
  user_id uuid not null references public.users(id) on delete cascade,
  groom_post_id uuid not null references public.groom_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, groom_post_id)
);

alter table public.groom_hidden_posts enable row level security;

drop policy if exists "Users manage own groom hidden posts" on public.groom_hidden_posts;
create policy "Users manage own groom hidden posts"
  on public.groom_hidden_posts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.groom_user_blocks (
  blocker_id uuid not null references public.users(id) on delete cascade,
  blocked_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint groom_user_blocks_no_self check (blocker_id <> blocked_id)
);

create index if not exists idx_groom_user_blocks_blocked
  on public.groom_user_blocks(blocked_id);

alter table public.groom_user_blocks enable row level security;

drop policy if exists "Users manage own groom blocks" on public.groom_user_blocks;
create policy "Users manage own groom blocks"
  on public.groom_user_blocks for all
  using (auth.uid() = blocker_id)
  with check (auth.uid() = blocker_id);

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
      left join public.users viewer on viewer.id = viewer_id
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
           and (
             (
               gp.audience_scope in ('encountered_people', 'followers')
               and viewer_id = any(gp.audience_user_ids)
             )
             or (
               gp.audience_scope = 'same_area'
               and gp.area_key is not null
               and viewer.primary_area = gp.area_key
             )
           )
         )
       )
  );
$$;

revoke all on function public.can_view_groom_post(uuid, uuid) from public;
grant execute on function public.can_view_groom_post(uuid, uuid) to authenticated;

create table if not exists public.groom_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  groom_post_id uuid not null references public.groom_posts(id) on delete cascade,
  reported_user_id uuid not null references public.users(id) on delete cascade,
  reason text not null default 'other' check (
    reason in ('spam', 'harassment', 'privacy', 'other')
  ),
  note text check (note is null or length(note) <= 500),
  status text not null default 'open' check (
    status in ('open', 'reviewing', 'resolved', 'dismissed')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (reporter_id, groom_post_id)
);

create index if not exists idx_groom_reports_status
  on public.groom_reports(status, created_at desc);

drop trigger if exists trg_groom_reports_updated_at on public.groom_reports;
create trigger trg_groom_reports_updated_at
  before update on public.groom_reports
  for each row execute function public.set_updated_at();

alter table public.groom_reports enable row level security;

drop policy if exists "Users insert own groom reports" on public.groom_reports;
create policy "Users insert own groom reports"
  on public.groom_reports for insert
  with check (
    auth.uid() = reporter_id
    and reporter_id <> reported_user_id
    and public.can_view_groom_post(groom_post_id, auth.uid())
  );

drop policy if exists "Users read own groom reports" on public.groom_reports;
create policy "Users read own groom reports"
  on public.groom_reports for select
  using (auth.uid() = reporter_id);

-- ---------------------------------------------------------------------
-- 3. Harden groom_posts and related RLS
-- ---------------------------------------------------------------------
update public.groom_posts gp
   set area_key = coalesce(gp.area_key, author.primary_area),
       audience_user_ids = case
         when cardinality(gp.audience_user_ids) = 0
           then public.groom_audience_for_user(gp.user_id)
         else gp.audience_user_ids
       end
  from public.users author
 where gp.user_id = author.id
   and gp.audience_scope = 'encountered_people';

drop policy if exists "Users can read visible groom posts" on public.groom_posts;
create policy "Users can read visible groom posts"
  on public.groom_posts for select
  using (public.can_view_groom_post(id, auth.uid()));

drop policy if exists "Users can insert own groom reactions" on public.groom_reactions;
create policy "Users can insert own groom reactions"
  on public.groom_reactions for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.groom_posts gp
      where gp.id = groom_reactions.groom_post_id
        and gp.user_id <> auth.uid()
        and public.can_view_groom_post(gp.id, auth.uid())
    )
  );

drop policy if exists "Users can upsert own groom views" on public.groom_views;
create policy "Users can upsert own groom views"
  on public.groom_views for insert
  with check (
    auth.uid() = user_id
    and public.can_view_groom_post(groom_views.groom_post_id, auth.uid())
  );

drop policy if exists "Users can insert visible groom replies" on public.groom_replies;
create policy "Users can insert visible groom replies"
  on public.groom_replies for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.groom_posts gp
      where gp.id = groom_replies.groom_post_id
        and gp.user_id = groom_replies.recipient_id
        and gp.user_id <> auth.uid()
        and public.can_view_groom_post(gp.id, auth.uid())
    )
  );

do $$
begin
  begin
    create extension if not exists pg_cron with schema extensions;
  exception when others then
    null;
  end;

  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      perform cron.unschedule('expire-groom-posts');
    exception when others then
      null;
    end;

    begin
      perform cron.schedule(
        'expire-groom-posts',
        '*/15 * * * *',
        'select public.expire_groom_posts();'
      );
    exception when others then
      null;
    end;
  end if;
end
$$;

-- ---------------------------------------------------------------------
-- 4. Private Storage policies for groom posts
-- ---------------------------------------------------------------------
update storage.buckets
   set public = false
 where id = 'groom-posts';

create or replace function public.can_view_groom_object(object_name text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.groom_posts gp
     where gp.image_path = object_name
       and public.can_view_groom_post(gp.id, auth.uid())
  );
$$;

revoke all on function public.can_view_groom_object(text) from public;
grant execute on function public.can_view_groom_object(text) to authenticated;

drop policy if exists "Groom posts: anyone can view" on storage.objects;
drop policy if exists "Groom posts: audience can view" on storage.objects;
create policy "Groom posts: audience can view"
  on storage.objects for select
  using (
    bucket_id = 'groom-posts'
    and public.can_view_groom_object(name)
  );

-- ---------------------------------------------------------------------
-- 5. Meguri message persistence
-- ---------------------------------------------------------------------
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'meguri-message-media',
  'meguri-message-media',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set public = false;

create table if not exists public.meguri_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.users(id) on delete cascade,
  recipient_id uuid not null references public.users(id) on delete cascade,
  source_groom_reply_id uuid references public.groom_replies(id) on delete set null,
  message_type text not null default 'text' check (message_type in ('text', 'image')),
  body text check (body is null or length(body) <= 2000),
  image_url text,
  image_path text,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint meguri_messages_no_self check (sender_id <> recipient_id),
  constraint meguri_messages_type_consistency check (
    case message_type
      when 'text' then body is not null
      when 'image' then image_path is not null
      else true
    end
  )
);

create index if not exists idx_meguri_messages_sender
  on public.meguri_messages(sender_id, created_at desc);
create index if not exists idx_meguri_messages_recipient
  on public.meguri_messages(recipient_id, read_at, created_at desc);
create index if not exists idx_meguri_messages_pair
  on public.meguri_messages(sender_id, recipient_id, created_at desc);

alter table public.meguri_messages enable row level security;

drop policy if exists "Participants can read meguri messages" on public.meguri_messages;
create policy "Participants can read meguri messages"
  on public.meguri_messages for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

drop policy if exists "Participants can insert own meguri messages" on public.meguri_messages;
create policy "Participants can insert own meguri messages"
  on public.meguri_messages for insert
  with check (
    auth.uid() = sender_id
    and sender_id <> recipient_id
    and not exists (
      select 1 from public.groom_user_blocks block
       where (
         block.blocker_id = sender_id
         and block.blocked_id = recipient_id
       )
       or (
         block.blocker_id = recipient_id
         and block.blocked_id = sender_id
       )
    )
  );

drop policy if exists "Recipients can mark meguri messages read" on public.meguri_messages;
create policy "Recipients can mark meguri messages read"
  on public.meguri_messages for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

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
       and (message.sender_id = auth.uid() or message.recipient_id = auth.uid())
  );
$$;

revoke all on function public.can_view_meguri_message_object(text) from public;
grant execute on function public.can_view_meguri_message_object(text) to authenticated;

drop policy if exists "Meguri message media: users can upload to own folder" on storage.objects;
create policy "Meguri message media: users can upload to own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'meguri-message-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Meguri message media: participants can view" on storage.objects;
create policy "Meguri message media: participants can view"
  on storage.objects for select
  using (
    bucket_id = 'meguri-message-media'
    and public.can_view_meguri_message_object(name)
  );

drop policy if exists "Meguri message media: users can delete own files" on storage.objects;
create policy "Meguri message media: users can delete own files"
  on storage.objects for delete
  using (
    bucket_id = 'meguri-message-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

alter table public.notifications
  add column if not exists meguri_message_id uuid references public.meguri_messages(id) on delete cascade;

alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'proposal_received',
      'proposal_accepted',
      'proposal_rejected',
      'proposal_revised',
      'evidence_added',
      'trade_completed',
      'evaluation_received',
      'dispute_received',
      'dispute_responded',
      'dispute_closed',
      'cancel_requested',
      'expires_soon',
      'groom_reply',
      'meguri_message'
    )
  );

drop policy if exists "Participants insert notifications"
  on public.notifications;

create policy "Participants insert notifications"
  on public.notifications for insert
  with check (
    (
      proposal_id is not null
      and exists (
        select 1 from public.proposals p
        where p.id = proposal_id
          and (p.sender_id = auth.uid() or p.receiver_id = auth.uid())
          and (p.sender_id = user_id or p.receiver_id = user_id)
      )
    )
    or
    (
      dispute_id is not null
      and exists (
        select 1 from public.disputes d
        where d.id = dispute_id
          and (d.reporter_id = auth.uid() or d.respondent_id = auth.uid())
          and (d.reporter_id = user_id or d.respondent_id = user_id)
      )
    )
    or
    (
      groom_reply_id is not null
      and exists (
        select 1 from public.groom_replies gr
        where gr.id = groom_reply_id
          and gr.sender_id = auth.uid()
          and gr.recipient_id = user_id
      )
    )
    or
    (
      meguri_message_id is not null
      and exists (
        select 1 from public.meguri_messages message
        where message.id = meguri_message_id
          and message.sender_id = auth.uid()
          and message.recipient_id = user_id
      )
    )
  );

-- =====================================================================
-- 完了
-- =====================================================================
