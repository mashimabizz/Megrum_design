-- =====================================================================
-- iter168.13: SEVENTEEN メンバー seed
-- =====================================================================
-- SEVENTEEN Japan official site の PROFILE 掲載順に合わせ、
-- K-POP グループ master と 13 名の member master を登録する。
-- 既存環境に SEVENTEEN group がある場合は aliases/display_order を補強する。

do $$
declare
  v_kpop_genre_id uuid;
  v_seventeen_id uuid;
begin
  select id into v_kpop_genre_id
    from public.genres_master
   where name = 'K-POP';

  if v_kpop_genre_id is null then
    raise exception 'K-POP genre is required before seeding SEVENTEEN members';
  end if;

  insert into public.groups_master (genre_id, name, aliases, kind, display_order)
  values (
    v_kpop_genre_id,
    'SEVENTEEN',
    array['세븐틴', 'セブチ', 'SVT']::text[],
    'group',
    6
  )
  on conflict (genre_id, name) do update
    set aliases = excluded.aliases,
        kind = excluded.kind,
        display_order = excluded.display_order;

  select id into v_seventeen_id
    from public.groups_master
   where genre_id = v_kpop_genre_id
     and name = 'SEVENTEEN';

  insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
  select
    v_seventeen_id,
    v_kpop_genre_id,
    m.name,
    m.aliases,
    m.display_order
  from (
    values
      ('エスクプス', array['S.COUPS', 'S.Coups', '에스쿱스', 'スンチョル', '최승철']::text[], 1),
      ('ジョンハン', array['JEONGHAN', 'Jeonghan', '정한', '윤정한']::text[], 2),
      ('ジョシュア', array['JOSHUA', 'Joshua', '조슈아', 'ホンジス', '홍지수']::text[], 3),
      ('ジュン', array['JUN', 'Jun', '준', 'ムンジュンフィ', '문준휘', '文俊辉']::text[], 4),
      ('ホシ', array['HOSHI', 'Hoshi', '호시', 'クォンスニョン', '권순영']::text[], 5),
      ('ウォヌ', array['WONWOO', 'Wonwoo', '원우', '전원우']::text[], 6),
      ('ウジ', array['WOOZI', 'Woozi', '우지', 'イジフン', '이지훈']::text[], 7),
      ('ディエイト', array['THE 8', 'THE8', 'The8', 'The 8', '디에잇', 'ミンハオ', '서명호', '徐明浩']::text[], 8),
      ('ミンギュ', array['MINGYU', 'Mingyu', '민규', '김민규']::text[], 9),
      ('ドギョム', array['DK', 'DOKYEOM', 'Dokyeom', '도겸', 'ソクミン', '이석민']::text[], 10),
      ('スングァン', array['SEUNGKWAN', 'Seungkwan', '승관', '부승관']::text[], 11),
      ('バーノン', array['VERNON', 'Vernon', '버논', 'ハンソル', '최한솔']::text[], 12),
      ('ディノ', array['DINO', 'Dino', '디노', 'イチャン', '이찬']::text[], 13)
  ) as m(name, aliases, display_order)
  where not exists (
    select 1
      from public.characters_master c
     where c.group_id = v_seventeen_id
       and c.name = m.name
  );
end $$;

-- =====================================================================
-- 完了
-- =====================================================================
