-- =====================================================================
-- iter164: Groom backend persistence
-- =====================================================================
-- 目的:
-- - グルーム投稿を Supabase Storage + DB に保存する
-- - 24時間公開ライフサイクル、いいね、閲覧済み、返信を DB で管理する
-- - グルーム返信を通知・めぐりメッセージに接続する

-- ---------------------------------------------------------------------
-- 1. Storage bucket
-- ---------------------------------------------------------------------
insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'groom-posts',
  'groom-posts',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "Groom posts: users can upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'groom-posts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Groom posts: anyone can view"
  on storage.objects for select
  using (bucket_id = 'groom-posts');

create policy "Groom posts: users can update their own files"
  on storage.objects for update
  using (
    bucket_id = 'groom-posts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Groom posts: users can delete their own files"
  on storage.objects for delete
  using (
    bucket_id = 'groom-posts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------
-- 2. groom_posts
-- ---------------------------------------------------------------------
create table public.groom_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,

  image_url text not null,
  image_path text,
  caption text check (caption is null or length(caption) <= 180),

  status text not null default 'published' check (
    status in ('draft', 'published', 'expired', 'hidden', 'archived')
  ),
  audience_scope text not null default 'encountered_people' check (
    audience_scope in ('encountered_people', 'same_area', 'followers', 'private')
  ),
  audience_user_ids uuid[] not null default '{}',

  place_hint text check (place_hint is null or length(place_hint) <= 80),
  area_key text check (area_key is null or length(area_key) <= 80),

  image_transform jsonb not null default '{"rotation":0,"scale":1,"x":0,"y":0}'::jsonb,
  text_overlays jsonb not null default '[]'::jsonb,
  stickers jsonb not null default '[]'::jsonb,
  doodles jsonb not null default '[]'::jsonb,

  published_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint groom_posts_publish_window check (
    status = 'draft'
    or (
      published_at is not null
      and expires_at is not null
      and expires_at > published_at
    )
  )
);

comment on table public.groom_posts is
  'グルーム投稿。24時間だけ published として閲覧され、expired/hidden/archived で非表示になる。';

create index idx_groom_posts_feed
  on public.groom_posts(status, expires_at desc, published_at desc);
create index idx_groom_posts_user
  on public.groom_posts(user_id, published_at desc);
create index idx_groom_posts_area
  on public.groom_posts(area_key, published_at desc);

create trigger trg_groom_posts_updated_at
  before update on public.groom_posts
  for each row execute function public.set_updated_at();

create or replace function public.set_groom_post_publish_window()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'published' then
    new.published_at = coalesce(new.published_at, now());
    new.expires_at = coalesce(new.expires_at, new.published_at + interval '24 hours');
  end if;
  return new;
end;
$$;

create trigger trg_groom_posts_publish_window
  before insert or update on public.groom_posts
  for each row execute function public.set_groom_post_publish_window();

alter table public.groom_posts enable row level security;

create policy "Users can insert own groom posts"
  on public.groom_posts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own groom posts"
  on public.groom_posts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can read visible groom posts"
  on public.groom_posts for select
  using (
    auth.uid() = user_id
    or (
      status = 'published'
      and expires_at > now()
      and (
        cardinality(audience_user_ids) = 0
        or auth.uid() = any(audience_user_ids)
      )
    )
  );

create or replace function public.expire_groom_posts()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.groom_posts
    set status = 'expired'
    where status = 'published'
      and expires_at <= now();

  update public.groom_posts
    set status = 'archived'
    where status = 'expired'
      and expires_at <= now() - interval '7 days';
end;
$$;

revoke all on function public.expire_groom_posts() from public;
grant execute on function public.expire_groom_posts() to authenticated;

-- ---------------------------------------------------------------------
-- 3. groom_reactions / groom_views
-- ---------------------------------------------------------------------
create table public.groom_reactions (
  id uuid primary key default gen_random_uuid(),
  groom_post_id uuid not null references public.groom_posts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reaction_type text not null default 'like' check (reaction_type in ('like')),
  created_at timestamptz not null default now(),
  unique (groom_post_id, user_id, reaction_type)
);

create index idx_groom_reactions_post
  on public.groom_reactions(groom_post_id, reaction_type);

alter table public.groom_reactions enable row level security;

create policy "Users can read own groom reactions"
  on public.groom_reactions for select
  using (auth.uid() = user_id);

create policy "Users can insert own groom reactions"
  on public.groom_reactions for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.groom_posts gp
      where gp.id = groom_reactions.groom_post_id
        and (
          gp.user_id = auth.uid()
          or (
            gp.status = 'published'
            and gp.expires_at > now()
            and (
              cardinality(gp.audience_user_ids) = 0
              or auth.uid() = any(gp.audience_user_ids)
            )
          )
        )
    )
  );

create policy "Users can delete own groom reactions"
  on public.groom_reactions for delete
  using (auth.uid() = user_id);

create table public.groom_views (
  groom_post_id uuid not null references public.groom_posts(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (groom_post_id, user_id)
);

create index idx_groom_views_user
  on public.groom_views(user_id, viewed_at desc);

alter table public.groom_views enable row level security;

create policy "Users can read own groom views"
  on public.groom_views for select
  using (auth.uid() = user_id);

create policy "Users can upsert own groom views"
  on public.groom_views for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.groom_posts gp
      where gp.id = groom_views.groom_post_id
        and (
          gp.user_id = auth.uid()
          or (
            gp.status = 'published'
            and gp.expires_at > now()
            and (
              cardinality(gp.audience_user_ids) = 0
              or auth.uid() = any(gp.audience_user_ids)
            )
          )
        )
    )
  );

create policy "Users can update own groom views"
  on public.groom_views for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 4. groom_replies
-- ---------------------------------------------------------------------
create table public.groom_replies (
  id uuid primary key default gen_random_uuid(),
  groom_post_id uuid not null references public.groom_posts(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  recipient_id uuid not null references public.users(id) on delete cascade,
  body text not null check (length(body) between 1 and 500),
  groom_snapshot jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),

  constraint groom_replies_no_self check (sender_id <> recipient_id)
);

create index idx_groom_replies_sender
  on public.groom_replies(sender_id, created_at desc);
create index idx_groom_replies_recipient
  on public.groom_replies(recipient_id, read_at, created_at desc);
create index idx_groom_replies_post
  on public.groom_replies(groom_post_id, created_at desc);

alter table public.groom_replies enable row level security;

create policy "Participants can read groom replies"
  on public.groom_replies for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

create policy "Users can insert visible groom replies"
  on public.groom_replies for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.groom_posts gp
      where gp.id = groom_replies.groom_post_id
        and gp.user_id = groom_replies.recipient_id
        and gp.user_id <> auth.uid()
        and gp.status = 'published'
        and gp.expires_at > now()
        and (
          cardinality(gp.audience_user_ids) = 0
          or auth.uid() = any(gp.audience_user_ids)
        )
    )
  );

create policy "Recipients can mark groom replies read"
  on public.groom_replies for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

-- ---------------------------------------------------------------------
-- 5. notifications support
-- ---------------------------------------------------------------------
alter table public.notifications
  add column if not exists groom_reply_id uuid references public.groom_replies(id) on delete cascade;

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
      'groom_reply'
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
  );

-- =====================================================================
-- 完了
-- =====================================================================
