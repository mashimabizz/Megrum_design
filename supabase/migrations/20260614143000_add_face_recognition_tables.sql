-- =====================================================================
-- iter613: 顔検出・メンバー候補付けの保存基盤
-- =====================================================================
-- アップロード画像から顔を検出し、characters_master のメンバー候補へ
-- 照合するための最小スキーマ。特徴量モデルはアプリ/サーバ側で差し替え可能
-- とし、DB はベクトル値・候補・ユーザー補正を保持する。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. member_face_profiles: 運営管理の顔特徴量プロフィール
-- ---------------------------------------------------------------------
create table public.member_face_profiles (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters_master(id) on delete cascade,
  profile_type text not null default 'real_face' check (
    profile_type in ('real_face', 'anime_face', 'anime_character', 'illustration_embedding')
  ),
  embedding double precision[] not null check (array_length(embedding, 1) > 0),
  embedding_model text not null check (length(btrim(embedding_model)) between 1 and 120),
  source_image_url text,
  consent_recorded_at timestamptz not null,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index idx_member_face_profiles_character
  on public.member_face_profiles(character_id)
  where deleted_at is null;
create index idx_member_face_profiles_model
  on public.member_face_profiles(embedding_model)
  where deleted_at is null;
create index idx_member_face_profiles_profile_type
  on public.member_face_profiles(profile_type, character_id)
  where deleted_at is null;

comment on table public.member_face_profiles is
  'メンバー/キャラごとの顔特徴量プロフィール。登録は同意確認済みの運営操作に限定する。';

create trigger trg_member_face_profiles_updated_at
  before update on public.member_face_profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- 2. face_uploaded_images: 顔解析対象になったアップロード画像
-- ---------------------------------------------------------------------
create table public.face_uploaded_images (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  inventory_id uuid references public.goods_inventory(id) on delete set null,
  storage_bucket text,
  storage_path text,
  image_url text,
  image_hash text,
  content_type text not null default 'image/jpeg',
  image_type text not null default 'unknown' check (
    image_type in ('real_photo', 'anime', 'illustration', 'manga', 'unknown')
  ),
  analysis_status text check (
    analysis_status is null
    or analysis_status in ('auto_matched', 'needs_review', 'unknown', 'no_face', 'no_subject', 'low_quality')
  ),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  check (storage_path is not null or image_url is not null or image_hash is not null)
);

create index idx_face_uploaded_images_user
  on public.face_uploaded_images(user_id, created_at desc)
  where deleted_at is null;
create index idx_face_uploaded_images_inventory
  on public.face_uploaded_images(inventory_id)
  where inventory_id is not null and deleted_at is null;
create unique index idx_face_uploaded_images_hash_user
  on public.face_uploaded_images(user_id, image_hash)
  where image_hash is not null and deleted_at is null;

comment on table public.face_uploaded_images is
  '顔解析対象として登録されたアップロード画像。画像本体ではなく保存先/ハッシュを保持する。';

-- ---------------------------------------------------------------------
-- 3. detected_faces: 画像内の検出顔と最終ステータス
-- ---------------------------------------------------------------------
create table public.detected_faces (
  id uuid primary key default gen_random_uuid(),
  uploaded_image_id uuid not null references public.face_uploaded_images(id) on delete cascade,
  bounding_box jsonb not null,
  detection_confidence double precision not null default 0 check (detection_confidence between 0 and 1),
  quality_score double precision not null default 0 check (quality_score between 0 and 1),
  image_type text not null default 'unknown' check (
    image_type in ('real_photo', 'anime', 'illustration', 'manga', 'unknown')
  ),
  subject_type text not null default 'real_face' check (
    subject_type in ('real_face', 'anime_face', 'character', 'unknown')
  ),
  recognition_method text not null default 'vision_face' check (
    recognition_method in (
      'vision_face',
      'coreml_real_face',
      'real_face_embedding',
      'anime_face_detector',
      'anime_character_classifier',
      'anime_embedding_similarity',
      'manual',
      'unknown'
    )
  ),
  legacy_quality_status text not null default 'usable' check (
    legacy_quality_status in ('usable', 'too_small', 'low_confidence', 'low_quality')
  ),
  quality_status text not null check (
    quality_status in ('ok', 'low_quality', 'too_small', 'occluded', 'side_face', 'stylized', 'unknown')
  ),
  model_version text,
  profile_type text check (
    profile_type is null
    or profile_type in ('real_face', 'anime_face', 'anime_character', 'illustration_embedding')
  ),
  match_status text not null check (
    match_status in ('auto_matched', 'needs_review', 'unknown', 'no_face', 'no_subject', 'low_quality')
  ),
  matched_character_id uuid references public.characters_master(id) on delete set null,
  matched_confidence double precision check (matched_confidence is null or matched_confidence between 0 and 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    jsonb_typeof(bounding_box) = 'object'
    and bounding_box ? 'x'
    and bounding_box ? 'y'
    and bounding_box ? 'width'
    and bounding_box ? 'height'
  )
);

create index idx_detected_faces_image
  on public.detected_faces(uploaded_image_id, created_at asc);
create index idx_detected_faces_character
  on public.detected_faces(matched_character_id)
  where matched_character_id is not null;
create index idx_detected_faces_status
  on public.detected_faces(match_status);
create index idx_detected_faces_image_type
  on public.detected_faces(image_type, subject_type);

comment on table public.detected_faces is
  'アップロード画像から検出された顔またはキャラクター候補。bounding_box は画像内の正規化 top-left 座標。';

create trigger trg_detected_faces_updated_at
  before update on public.detected_faces
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- 4. face_match_candidates: 照合候補の上位リスト
-- ---------------------------------------------------------------------
create table public.face_match_candidates (
  id uuid primary key default gen_random_uuid(),
  detected_face_id uuid not null references public.detected_faces(id) on delete cascade,
  character_id uuid not null references public.characters_master(id) on delete cascade,
  confidence double precision not null check (confidence between 0 and 1),
  rank integer not null check (rank >= 1),
  profile_count integer not null default 1 check (profile_count >= 1),
  created_at timestamptz not null default now(),
  unique (detected_face_id, character_id)
);

create index idx_face_match_candidates_face
  on public.face_match_candidates(detected_face_id, rank asc);
create index idx_face_match_candidates_character
  on public.face_match_candidates(character_id);

comment on table public.face_match_candidates is
  '検出顔ごとのメンバー候補。confidence はアプリ/サーバが正規化した 0〜1 値。';

-- ---------------------------------------------------------------------
-- 5. face_match_corrections: ユーザー確認・補正履歴
-- ---------------------------------------------------------------------
create table public.face_match_corrections (
  id uuid primary key default gen_random_uuid(),
  detected_face_id uuid not null references public.detected_faces(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  original_match_status text not null check (
    original_match_status in ('auto_matched', 'needs_review', 'unknown', 'no_face', 'no_subject', 'low_quality')
  ),
  selected_character_id uuid references public.characters_master(id) on delete set null,
  selected_member_name text,
  image_type text not null default 'unknown' check (
    image_type in ('real_photo', 'anime', 'illustration', 'manga', 'unknown')
  ),
  subject_type text not null default 'unknown' check (
    subject_type in ('real_face', 'anime_face', 'character', 'unknown')
  ),
  recognition_method text not null default 'manual' check (
    recognition_method in (
      'vision_face',
      'coreml_real_face',
      'real_face_embedding',
      'anime_face_detector',
      'anime_character_classifier',
      'anime_embedding_similarity',
      'manual',
      'unknown'
    )
  ),
  selected_profile_type text check (
    selected_profile_type is null
    or selected_profile_type in ('real_face', 'anime_face', 'anime_character', 'illustration_embedding')
  ),
  should_add_training_data boolean not null default true,
  created_at timestamptz not null default now()
);

create index idx_face_match_corrections_face
  on public.face_match_corrections(detected_face_id, created_at desc);
create index idx_face_match_corrections_user
  on public.face_match_corrections(user_id, created_at desc);

comment on table public.face_match_corrections is
  '顔候補に対するユーザー補正。学習データ追加の可否は should_add_training_data で保持する。';

-- ---------------------------------------------------------------------
-- 6. RLS
-- ---------------------------------------------------------------------
alter table public.member_face_profiles enable row level security;
alter table public.face_uploaded_images enable row level security;
alter table public.detected_faces enable row level security;
alter table public.face_match_candidates enable row level security;
alter table public.face_match_corrections enable row level security;

create policy "authenticated can read active member face profiles"
  on public.member_face_profiles for select
  to authenticated
  using (deleted_at is null);

-- member_face_profiles の作成/更新/削除は service_role / 運営バックエンドに限定。

create policy "Users can read their own face uploaded images"
  on public.face_uploaded_images for select
  using (auth.uid() = user_id and deleted_at is null);

create policy "Users can insert their own face uploaded images"
  on public.face_uploaded_images for insert
  with check (auth.uid() = user_id);

create policy "Users can soft delete their own face uploaded images"
  on public.face_uploaded_images for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can read detected faces for their images"
  on public.detected_faces for select
  using (
    exists (
      select 1
        from public.face_uploaded_images i
       where i.id = detected_faces.uploaded_image_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  );

create policy "Users can insert detected faces for their images"
  on public.detected_faces for insert
  with check (
    exists (
      select 1
        from public.face_uploaded_images i
       where i.id = detected_faces.uploaded_image_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  );

create policy "Users can update detected faces for their images"
  on public.detected_faces for update
  using (
    exists (
      select 1
        from public.face_uploaded_images i
       where i.id = detected_faces.uploaded_image_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  )
  with check (
    exists (
      select 1
        from public.face_uploaded_images i
       where i.id = detected_faces.uploaded_image_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  );

create policy "Users can read face candidates for their images"
  on public.face_match_candidates for select
  using (
    exists (
      select 1
        from public.detected_faces f
        join public.face_uploaded_images i on i.id = f.uploaded_image_id
       where f.id = face_match_candidates.detected_face_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  );

create policy "Users can insert face candidates for their images"
  on public.face_match_candidates for insert
  with check (
    exists (
      select 1
        from public.detected_faces f
        join public.face_uploaded_images i on i.id = f.uploaded_image_id
       where f.id = face_match_candidates.detected_face_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  );

create policy "Users can read their own face corrections"
  on public.face_match_corrections for select
  using (auth.uid() = user_id);

create policy "Users can insert their own face corrections"
  on public.face_match_corrections for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1
        from public.detected_faces f
        join public.face_uploaded_images i on i.id = f.uploaded_image_id
       where f.id = face_match_corrections.detected_face_id
         and i.user_id = auth.uid()
         and i.deleted_at is null
    )
  );

-- =====================================================================
-- 完了
-- =====================================================================
