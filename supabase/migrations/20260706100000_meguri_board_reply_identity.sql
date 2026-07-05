-- =====================================================================
-- iter1226.296: チャットルームの参加者にも部屋ごとの名前・アイコンを持たせる
-- =====================================================================
-- めぐりプロフィール廃止に伴い、チャットルーム（掲示板スレッド）は
-- 作成時（既存: threads.anonymous_*）に加えて参加時（返信）にも
-- 名前とアイコンを決められるようにする。返信行に anonymous_* を持たせ、
-- 表示側はスレッド内の各ユーザーの最新値を使う。

alter table public.meguri_board_replies
  add column if not exists anonymous_display_name text,
  add column if not exists anonymous_avatar_id text;

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_anonymous_name_check;

alter table public.meguri_board_replies
  add constraint meguri_board_replies_anonymous_name_check
  check (
    anonymous_display_name is null
    or char_length(btrim(anonymous_display_name)) between 1 and 24
  );

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_anonymous_avatar_check;

alter table public.meguri_board_replies
  add constraint meguri_board_replies_anonymous_avatar_check
  check (
    anonymous_avatar_id is null
    or char_length(btrim(anonymous_avatar_id)) between 1 and 64
  );

-- ---------------------------------------------------------------------
-- 返信追加RPC: p_anonymous_display_name / p_anonymous_avatar_id を追加
-- ---------------------------------------------------------------------
drop function if exists public.append_meguri_board_reply_for_viewer(
  uuid, text, double precision, double precision, text, text, uuid, text, text, text[]
);
create function public.append_meguri_board_reply_for_viewer(
  p_thread_id uuid,
  p_body text,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null,
  p_parent_reply_id uuid default null,
  p_quote_author_name text default null,
  p_quote_body text default null,
  p_image_paths text[] default '{}',
  p_anonymous_display_name text default null,
  p_anonymous_avatar_id text default null
)
returns table (
  id uuid,
  thread_id uuid,
  author_id uuid,
  body text,
  image_paths text[],
  parent_reply_id uuid,
  quote_author_name text,
  quote_body text,
  status text,
  reaction_count integer,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz,
  viewer_reacted boolean,
  viewer_reported boolean,
  author_display_name text,
  author_handle text,
  author_primary_area text,
  anonymous_display_name text,
  anonymous_avatar_id text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted public.meguri_board_replies%rowtype;
  safe_image_paths text[];
  safe_parent_reply_id uuid;
begin
  if auth.uid() is null then
    raise exception 'login required';
  end if;

  if not exists (
    select 1
    from public.meguri_board_threads thread
    where thread.id = p_thread_id
      and thread.status = 'visible'
  ) then
    raise exception 'thread is closed';
  end if;

  if not public.can_view_meguri_board_thread_with_context(
    p_thread_id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  ) then
    raise exception 'thread is not visible from this location';
  end if;

  if p_parent_reply_id is not null then
    select reply.id into safe_parent_reply_id
      from public.meguri_board_replies reply
     where reply.id = p_parent_reply_id
       and reply.thread_id = p_thread_id
       and reply.status = 'visible'
       and not exists (
         select 1 from public.groom_user_blocks block
         where (
           block.blocker_id = auth.uid()
           and block.blocked_id = reply.author_id
         )
         or (
           block.blocker_id = reply.author_id
           and block.blocked_id = auth.uid()
         )
       );
  end if;

  select coalesce(array_agg(clean_path), '{}')
    into safe_image_paths
  from (
    select nullif(btrim(path), '') as clean_path
    from unnest(coalesce(p_image_paths, '{}')) as path
    where nullif(btrim(path), '') is not null
    limit 4
  ) cleaned;

  insert into public.meguri_board_replies (
    thread_id,
    author_id,
    body,
    image_paths,
    parent_reply_id,
    quote_author_name,
    quote_body,
    anonymous_display_name,
    anonymous_avatar_id
  )
  values (
    p_thread_id,
    auth.uid(),
    btrim(p_body),
    coalesce(safe_image_paths, '{}'),
    safe_parent_reply_id,
    nullif(btrim(coalesce(p_quote_author_name, '')), ''),
    left(nullif(btrim(coalesce(p_quote_body, '')), ''), 160),
    left(nullif(btrim(coalesce(p_anonymous_display_name, '')), ''), 24),
    left(nullif(btrim(coalesce(p_anonymous_avatar_id, '')), ''), 64)
  )
  returning * into inserted;

  return query
  select
    inserted.id,
    inserted.thread_id,
    inserted.author_id,
    inserted.body,
    inserted.image_paths,
    inserted.parent_reply_id,
    inserted.quote_author_name,
    inserted.quote_body,
    inserted.status,
    inserted.reaction_count,
    inserted.created_at,
    inserted.updated_at,
    inserted.deleted_at,
    false as viewer_reacted,
    false as viewer_reported,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area,
    inserted.anonymous_display_name,
    inserted.anonymous_avatar_id
  from public.users author
  where author.id = inserted.author_id;
end;
$$;

revoke all on function public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text, uuid, text, text, text[], text, text) from public;
grant execute on function public.append_meguri_board_reply_for_viewer(uuid, text, double precision, double precision, text, text, uuid, text, text, text[], text, text) to authenticated;

-- ---------------------------------------------------------------------
-- 返信一覧RPC: anonymous_display_name / anonymous_avatar_id を返す
-- ---------------------------------------------------------------------
drop function if exists public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text);
create function public.list_meguri_board_replies_for_viewer(
  p_thread_id uuid,
  p_viewer_lat double precision,
  p_viewer_lng double precision,
  p_prefecture text,
  p_scope text default null
)
returns table (
  id uuid,
  thread_id uuid,
  author_id uuid,
  body text,
  image_paths text[],
  parent_reply_id uuid,
  quote_author_name text,
  quote_body text,
  status text,
  reaction_count integer,
  good_reaction_count integer,
  bad_reaction_count integer,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz,
  viewer_reacted boolean,
  viewer_reaction_type text,
  viewer_reported boolean,
  author_display_name text,
  author_handle text,
  author_primary_area text,
  anonymous_display_name text,
  anonymous_avatar_id text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_view_meguri_board_thread_with_context(
    p_thread_id,
    auth.uid(),
    p_viewer_lat,
    p_viewer_lng,
    p_prefecture,
    p_scope
  ) then
    return;
  end if;

  return query
  select
    reply.id,
    reply.thread_id,
    reply.author_id,
    reply.body,
    reply.image_paths,
    reply.parent_reply_id,
    reply.quote_author_name,
    reply.quote_body,
    reply.status,
    reply.reaction_count,
    (
      select count(*)::integer
      from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id
        and reaction.reaction_type in ('useful', 'good')
    ) as good_reaction_count,
    (
      select count(*)::integer
      from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id
        and reaction.reaction_type = 'bad'
    ) as bad_reaction_count,
    reply.created_at,
    reply.updated_at,
    reply.deleted_at,
    exists (
      select 1 from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id and reaction.user_id = auth.uid()
    ) as viewer_reacted,
    (
      select case
        when reaction.reaction_type = 'useful' then 'good'
        else reaction.reaction_type
      end
      from public.meguri_board_reply_reactions reaction
      where reaction.reply_id = reply.id and reaction.user_id = auth.uid()
      order by reaction.created_at desc
      limit 1
    ) as viewer_reaction_type,
    exists (
      select 1 from public.meguri_board_reports report
      where report.reply_id = reply.id and report.reporter_id = auth.uid()
    ) as viewer_reported,
    author.display_name as author_display_name,
    author.handle as author_handle,
    author.primary_area as author_primary_area,
    reply.anonymous_display_name,
    reply.anonymous_avatar_id
  from public.meguri_board_replies reply
  join public.users author on author.id = reply.author_id
  where reply.thread_id = p_thread_id
    and reply.status in ('visible', 'deleted')
    and not exists (
      select 1 from public.groom_user_blocks block
      where (
        block.blocker_id = auth.uid()
        and block.blocked_id = reply.author_id
      )
      or (
        block.blocker_id = reply.author_id
        and block.blocked_id = auth.uid()
      )
    )
  order by reply.created_at asc
  limit 300;
end;
$$;

revoke all on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) from public;
grant execute on function public.list_meguri_board_replies_for_viewer(uuid, double precision, double precision, text, text) to authenticated;

-- =====================================================================
-- 完了
-- =====================================================================
