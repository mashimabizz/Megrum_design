-- =====================================================================
-- iter168.90: 検索実績ログと人気検索RPC
-- =====================================================================
-- ホーム右下の検索画面で、固定サンプルではなく実際に検索された
-- キーワードだけを「人気の検索」として表示する。

create table if not exists public.search_query_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  term text not null check (char_length(term) between 1 and 80),
  normalized_term text not null check (char_length(normalized_term) between 1 and 80),
  result_count integer not null default 0 check (result_count >= 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_search_query_logs_created_at
  on public.search_query_logs(created_at desc);

create index if not exists idx_search_query_logs_normalized
  on public.search_query_logs(normalized_term);

create index if not exists idx_search_query_logs_user
  on public.search_query_logs(user_id);

comment on table public.search_query_logs is
  '検索画面の実検索ログ。人気検索候補はこの実績から集計する。';

alter table public.search_query_logs enable row level security;

drop policy if exists "Users can insert own search logs" on public.search_query_logs;
create policy "Users can insert own search logs"
  on public.search_query_logs for insert
  with check (auth.uid() = user_id);

create or replace function public.normalize_search_query(p_query text)
returns text
language sql
immutable
parallel safe
as $$
  select regexp_replace(
    btrim(lower(normalize(coalesce(p_query, ''), NFKC))),
    '\s+',
    ' ',
    'g'
  );
$$;

create or replace function public.record_search_query(
  p_query text,
  p_result_count integer default 0
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_term text;
  v_normalized text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return;
  end if;

  v_term := btrim(coalesce(p_query, ''));
  v_normalized := public.normalize_search_query(v_term);
  if char_length(v_term) = 0 or char_length(v_normalized) = 0 then
    return;
  end if;

  insert into public.search_query_logs (
    user_id,
    term,
    normalized_term,
    result_count
  )
  values (
    v_user_id,
    left(v_term, 80),
    left(v_normalized, 80),
    greatest(0, coalesce(p_result_count, 0))
  );
end;
$$;

create or replace function public.get_popular_search_terms(
  p_limit integer default 10
)
returns table (
  term text,
  search_count bigint,
  last_searched_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with recent as (
    select *
      from public.search_query_logs
     where created_at >= now() - interval '30 days'
  ),
  aggregate_terms as (
    select
      normalized_term,
      count(*)::bigint as search_count,
      max(created_at) as last_searched_at
    from recent
    group by normalized_term
  ),
  latest_labels as (
    select distinct on (normalized_term)
      normalized_term,
      term
    from recent
    order by normalized_term, created_at desc
  )
  select
    latest_labels.term,
    aggregate_terms.search_count,
    aggregate_terms.last_searched_at
  from aggregate_terms
  join latest_labels using (normalized_term)
  order by
    aggregate_terms.search_count desc,
    aggregate_terms.last_searched_at desc,
    latest_labels.term asc
  limit greatest(1, least(coalesce(p_limit, 10), 20));
$$;

grant execute on function public.normalize_search_query(text) to authenticated, anon;
grant execute on function public.record_search_query(text, integer) to authenticated;
grant execute on function public.get_popular_search_terms(integer) to authenticated;
