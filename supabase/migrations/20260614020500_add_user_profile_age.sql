alter table public.users
    add column if not exists age integer;

alter table public.users
    drop constraint if exists users_age_range_check;

alter table public.users
    add constraint users_age_range_check
    check (age is null or (age between 1 and 120));

comment on column public.users.age is 'プロフィールに表示する年齢。未設定の場合は表示しない。';
