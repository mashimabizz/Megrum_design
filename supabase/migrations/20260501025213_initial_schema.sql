-- =====================================================================
-- Megrum: 初回マイグレーション
-- Phase 0 範囲（基盤・認証・マスタデータ）
-- 関連 docs:
--   - notes/05_data_model.md §1 マスタ / §2 ユーザー
--   - notes/09_state_machines.md §7 Account Lifecycle
--   - notes/10_glossary.md §G/§H ステータス
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. マスタテーブル（運営管理、誰でも読み取り可）
-- ---------------------------------------------------------------------

-- ジャンル: K-POP / 邦アイ / 2.5次元 / アニメ / ゲーム 等
create table public.genres_master (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  kind text not null check (kind in ('idol', 'anime', 'game', 'other')),
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.genres_master is 'ジャンルマスタ（K-POP / 邦アイ / 2.5次元 等）';

-- グループ／作品: TWICE / 呪術廻戦 等（kind: group / work / solo）
create table public.groups_master (
  id uuid primary key default gen_random_uuid(),
  genre_id uuid not null references public.genres_master(id) on delete restrict,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null default 'group' check (kind in ('group', 'work', 'solo')),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique (genre_id, name)
);

create index idx_groups_master_genre on public.groups_master(genre_id);
create index idx_groups_master_aliases on public.groups_master using gin(aliases);
comment on table public.groups_master is 'グループ/作品マスタ（TWICE、呪術廻戦 等）';

-- メンバー／キャラ: スア / 虎杖悠仁 等
create table public.characters_master (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.groups_master(id) on delete cascade,
  genre_id uuid not null references public.genres_master(id) on delete restrict,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index idx_characters_master_group on public.characters_master(group_id);
create index idx_characters_master_genre on public.characters_master(genre_id);
create index idx_characters_master_aliases on public.characters_master using gin(aliases);
comment on table public.characters_master is 'メンバー/キャラマスタ（スア、虎杖悠仁 等）';

-- グッズ種別: トレカ / 生写真 / 缶バッジ 等
create table public.goods_types_master (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null check (category in ('card', 'photo', 'pin', 'figure', 'other')),
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

comment on table public.goods_types_master is 'グッズ種別マスタ（トレカ・生写真・缶バッジ・アクスタ 等）';

-- マスタは全員に読み取り公開
alter table public.genres_master enable row level security;
alter table public.groups_master enable row level security;
alter table public.characters_master enable row level security;
alter table public.goods_types_master enable row level security;

create policy "Anyone can read genres_master" on public.genres_master for select using (true);
create policy "Anyone can read groups_master" on public.groups_master for select using (true);
create policy "Anyone can read characters_master" on public.characters_master for select using (true);
create policy "Anyone can read goods_types_master" on public.goods_types_master for select using (true);

-- ---------------------------------------------------------------------
-- 2. ユーザー拡張: auth.users を補完する public.users
-- ---------------------------------------------------------------------
-- Supabase Auth が auth.users を自動管理。
-- Megrum 固有の属性（ハンドル名・推し・エリア等）は public.users に保持。

create table public.users (
  -- auth.users.id とそのまま 1:1
  id uuid primary key references auth.users(id) on delete cascade,
  -- ハンドル名（@hana_lumi 形式、システム内一意）
  handle text not null unique check (handle ~ '^[a-z0-9_]{3,20}$'),
  display_name text not null,
  avatar_url text,
  gender text check (gender in ('female', 'male', 'other', 'no_answer')),
  primary_area text, -- "東京都" 等の粗い検索用エリア
  -- アカウント状態（09_state_machines.md §7 と一致）
  account_status text not null default 'verified' check (
    account_status in (
      'registered', 'verified', 'onboarding', 'active',
      'suspended', 'deletion_requested', 'deleted'
    )
  ),
  email_verified_at timestamptz,
  deletion_requested_at timestamptz,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_users_handle on public.users(handle);
create index idx_users_account_status on public.users(account_status);
comment on table public.users is 'Megrum ユーザー拡張情報（auth.users と 1:1）';

-- ユーザー更新時に updated_at を自動更新
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

-- RLS: 自分のレコードのみ更新可、誰でも読み取り可（公開プロフィール）
alter table public.users enable row level security;

create policy "Anyone can read user profiles" on public.users
  for select using (true);

create policy "Users can insert their own profile" on public.users
  for insert with check (auth.uid() = id);

create policy "Users can update their own profile" on public.users
  for update using (auth.uid() = id);

-- ---------------------------------------------------------------------
-- 3. user_oshi: 推し登録（DD/箱推し対応）
-- ---------------------------------------------------------------------

create table public.user_oshi (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  group_id uuid references public.groups_master(id) on delete restrict,
  character_id uuid references public.characters_master(id) on delete restrict,
  -- 'box': 箱推し（メンバー特定なし）, 'specific': 特定メンバー, 'multi': 複数メンバー
  kind text not null check (kind in ('box', 'specific', 'multi')),
  -- 1=メイン推し、2以降=サブ
  priority integer not null default 1 check (priority >= 1),
  created_at timestamptz not null default now(),
  -- 推し設定はグループ or キャラの少なくとも片方が必須
  check (group_id is not null or character_id is not null)
);

create index idx_user_oshi_user on public.user_oshi(user_id);
create index idx_user_oshi_group on public.user_oshi(group_id);
create index idx_user_oshi_character on public.user_oshi(character_id);
comment on table public.user_oshi is '推し登録（複数推し対応、kind=box/specific/multi）';

alter table public.user_oshi enable row level security;

create policy "Anyone can read user_oshi" on public.user_oshi
  for select using (true);

create policy "Users can manage their own oshi" on public.user_oshi
  for all using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 4. ユーザー作成時の自動 public.users INSERT トリガー
-- ---------------------------------------------------------------------
-- auth.users にレコードができたら、public.users にも対応行を作る。
-- ハンドル名や表示名はサインアップ時の metadata から取得。

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public, auth
as $$
begin
  insert into public.users (id, handle, display_name, account_status)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'handle',
      'user_' || substr(replace(new.id::text, '-', ''), 1, 8)
    ),
    coalesce(
      new.raw_user_meta_data->>'display_name',
      'User'
    ),
    case
      when new.email_confirmed_at is not null then 'verified'
      else 'registered'
    end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- 5. シードデータ: 主要マスタの初期値（K-POP からスタート、戦略 03 通り）
-- ---------------------------------------------------------------------

insert into public.genres_master (name, kind, display_order) values
  ('K-POP', 'idol', 1),
  ('邦アイ', 'idol', 2),
  ('2.5次元', 'other', 3),
  ('アニメ', 'anime', 4),
  ('ゲーム', 'game', 5);

insert into public.goods_types_master (name, category, display_order) values
  ('トレカ', 'card', 1),
  ('生写真', 'photo', 2),
  ('缶バッジ', 'pin', 3),
  ('アクスタ', 'figure', 4),
  ('スマホリング', 'other', 5),
  ('ぬいぐるみ', 'figure', 6),
  ('ペンライト', 'other', 7),
  ('ポスター', 'photo', 8),
  ('クリアファイル', 'other', 9),
  ('シール', 'other', 10),
  ('その他', 'other', 99);

-- 主要 K-POP グループ（戦略 03 のスタート用 5〜10グループ）
do $$
declare
  v_kpop_id uuid;
begin
  select id into v_kpop_id from public.genres_master where name = 'K-POP';

  insert into public.groups_master (genre_id, name, aliases, kind, display_order) values
    (v_kpop_id, 'BTS', array['防弾少年団', '방탄소년단'], 'group', 1),
    (v_kpop_id, 'TWICE', array['트와이스'], 'group', 2),
    (v_kpop_id, 'NewJeans', array['뉴진스'], 'group', 3),
    (v_kpop_id, 'IVE', array['아이브'], 'group', 4),
    (v_kpop_id, 'Stray Kids', array['스트레이 키즈', 'スキズ'], 'group', 5),
    (v_kpop_id, 'SEVENTEEN', array['세븐틴', 'セブチ'], 'group', 6),
    (v_kpop_id, 'aespa', array['에스파'], 'group', 7),
    (v_kpop_id, 'LE SSERAFIM', array['르세라핌'], 'group', 8),
    (v_kpop_id, 'ENHYPEN', array['엔하이픈'], 'group', 9),
    (v_kpop_id, 'TXT', array['투모로우바이투게더', 'TOMORROW X TOGETHER'], 'group', 10);
end $$;

-- =====================================================================
-- 完了
-- =====================================================================
