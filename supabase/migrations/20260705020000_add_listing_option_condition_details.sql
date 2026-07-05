-- 個別募集「条件から選ぶ」の詳細条件（メンバー指定/除外・シリーズ・数量）を
-- 選択肢に保存できるようにする。従来はグループ×グッズ種別しか保存されず、
-- メンバーやシリーズ、数量の指定が保存時に失われていた。

alter table public.listing_wish_options
  add column if not exists wish_member_ids uuid[] not null default '{}',
  add column if not exists excludes_wish_members boolean not null default false,
  add column if not exists wish_series_names text[] not null default '{}',
  add column if not exists wish_quantity integer not null default 1;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'listing_wish_options_wish_quantity_range'
  ) then
    alter table public.listing_wish_options
      add constraint listing_wish_options_wish_quantity_range
      check (wish_quantity between 1 and 99);
  end if;
end $$;

comment on column public.listing_wish_options.wish_member_ids is
  '条件指定型の選択肢で対象にするメンバー（characters_master.id）。空なら全メンバー。';
comment on column public.listing_wish_options.excludes_wish_members is
  'true の場合、wish_member_ids は「これらのメンバー以外」を意味する。';
comment on column public.listing_wish_options.wish_series_names is
  '条件指定型の選択肢で対象にするシリーズ名（タグ）。空なら指定なし。';
comment on column public.listing_wish_options.wish_quantity is
  '条件指定型の選択肢で求める数量。';
