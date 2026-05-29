alter table public.proposals
  add column if not exists option_tags text[] not null default '{}';

comment on column public.proposals.option_tags is
  '打診時に選択された交換条件タグ。例: 即日発送、同日発送、終演後OK。';
