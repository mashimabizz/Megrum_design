-- =====================================================================
-- iter168.19: 推しジャンル分類の再整理
-- =====================================================================
-- アイドル・音楽だけを細分化し、それ以外は大分類のまま扱う。
-- groups_master.kind = group / work / solo は対象の形として維持し、
-- genres_master はユーザーが探す文化圏・入口として使う。

do $$
declare
  v_kpop_male_id uuid;
  v_kpop_female_id uuid;
  v_domestic_male_id uuid;
  v_domestic_female_id uuid;
  v_utaites_id uuid;
  v_voice_actor_id uuid;
begin
  -- 既存IDを活かして、参照中の推し・グッズ・追加リクエストを壊さない。
  select id into v_kpop_male_id
    from public.genres_master
    where name = 'K-POP男性';

  if v_kpop_male_id is null then
    update public.genres_master
      set name = 'K-POP男性',
          kind = 'idol',
          display_order = 1
      where name = 'K-POP'
      returning id into v_kpop_male_id;
  end if;

  if v_kpop_male_id is null then
    insert into public.genres_master (name, kind, display_order)
    values ('K-POP男性', 'idol', 1)
    returning id into v_kpop_male_id;
  else
    update public.genres_master
      set kind = 'idol',
          display_order = 1
      where id = v_kpop_male_id;
  end if;

  insert into public.genres_master (name, kind, display_order)
  values ('K-POP女性', 'idol', 2)
  on conflict (name) do update
    set kind = excluded.kind,
        display_order = excluded.display_order
  returning id into v_kpop_female_id;

  select id into v_domestic_male_id
    from public.genres_master
    where name = '国内男性';

  if v_domestic_male_id is null then
    update public.genres_master
      set name = '国内男性',
          kind = 'idol',
          display_order = 3
      where name = '邦アイ'
      returning id into v_domestic_male_id;
  end if;

  if v_domestic_male_id is null then
    insert into public.genres_master (name, kind, display_order)
    values ('国内男性', 'idol', 3)
    returning id into v_domestic_male_id;
  else
    update public.genres_master
      set kind = 'idol',
          display_order = 3
      where id = v_domestic_male_id;
  end if;

  insert into public.genres_master (name, kind, display_order)
  values ('国内女性', 'idol', 4)
  on conflict (name) do update
    set kind = excluded.kind,
        display_order = excluded.display_order
  returning id into v_domestic_female_id;

  insert into public.genres_master (name, kind, display_order)
  values ('歌い手', 'other', 5)
  on conflict (name) do update
    set kind = excluded.kind,
        display_order = excluded.display_order
  returning id into v_utaites_id;

  insert into public.genres_master (name, kind, display_order)
  values ('声優', 'other', 6)
  on conflict (name) do update
    set kind = excluded.kind,
        display_order = excluded.display_order
  returning id into v_voice_actor_id;

  update public.genres_master
    set name = '2.5次元・舞台',
        kind = 'other',
        display_order = 7
    where name = '2.5次元';

  update public.genres_master
    set kind = 'other',
        display_order = 7
    where name = '2.5次元・舞台';

  update public.genres_master
    set name = 'アニメ・マンガ',
        kind = 'anime',
        display_order = 8
    where name = 'アニメ';

  update public.genres_master
    set kind = 'anime',
        display_order = 8
    where name = 'アニメ・マンガ';

  update public.genres_master
    set kind = 'game',
        display_order = 9
    where name = 'ゲーム';

  insert into public.genres_master (name, kind, display_order)
  values
    ('キャラクターIP', 'other', 10),
    ('VTuber・配信者', 'other', 11),
    ('お笑い', 'other', 12),
    ('スポーツ', 'other', 13),
    ('俳優・タレント', 'other', 14),
    ('海外エンタメ', 'other', 15)
  on conflict (name) do update
    set kind = excluded.kind,
        display_order = excluded.display_order;

  -- K-POP女性グループを新分類へ移す。
  update public.groups_master
    set genre_id = v_kpop_female_id
    where genre_id in (v_kpop_male_id, v_kpop_female_id)
      and name = any(array[
        'TWICE',
        'NewJeans',
        'IVE',
        'aespa',
        'LE SSERAFIM',
        'NMIXX',
        'BABYMONSTER',
        'ITZY',
        '(G)I-DLE'
      ]);

  -- 国内女性グループを新分類へ移す。
  update public.groups_master
    set genre_id = v_domestic_female_id
    where genre_id in (v_domestic_male_id, v_domestic_female_id)
      and name = any(array[
        'ME:I',
        'FRUITS ZIPPER',
        '=LOVE',
        '≠ME',
        '乃木坂46',
        '櫻坂46',
        '日向坂46'
      ]);

  -- L2側の genre_id を所属L1に同期する。
  update public.characters_master c
    set genre_id = g.genre_id
    from public.groups_master g
    where c.group_id = g.id
      and c.genre_id <> g.genre_id;

  -- 旧K-POPで受けていた pending request のうち、明らかな女性/国内女性を寄せる。
  update public.oshi_requests
    set requested_genre_id = v_kpop_female_id
    where requested_genre_id = v_kpop_male_id
      and status = 'pending'
      and lower(requested_name) in ('babymonster', 'asepa', 'aespa');

  update public.oshi_requests
    set requested_genre_id = v_domestic_female_id
    where requested_genre_id = v_kpop_male_id
      and status = 'pending'
      and requested_name = 'ME:I';
end;
$$;

create temporary table _ihub_music_seed_groups (
  genre_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  kind text not null,
  display_order integer not null
) on commit drop;

insert into _ihub_music_seed_groups (genre_name, name, aliases, kind, display_order) values
  ('歌い手', 'すとぷり', array['Strawberry Prince', 'STPR']::text[], 'group', 1),
  ('歌い手', 'いれいす', array['IREISU']::text[], 'group', 2),
  ('歌い手', 'Knight A - 騎士A -', array['Knight A', '騎士A']::text[], 'group', 3),
  ('歌い手', '浦島坂田船', array['USSS']::text[], 'group', 4),
  ('歌い手', 'After the Rain', array['AtR']::text[], 'group', 5),
  ('歌い手', 'まふまふ', array['Mafumafu']::text[], 'solo', 6),
  ('歌い手', 'そらる', array['Soraru']::text[], 'solo', 7),
  ('歌い手', 'Ado', array[]::text[], 'solo', 8),
  ('歌い手', 'Eve', array[]::text[], 'solo', 9),
  ('歌い手', 'Sou', array[]::text[], 'solo', 10),
  ('声優', '宮野真守', array['Mamoru Miyano']::text[], 'solo', 1),
  ('声優', '水樹奈々', array['Nana Mizuki']::text[], 'solo', 2),
  ('声優', '花澤香菜', array['Kana Hanazawa']::text[], 'solo', 3),
  ('声優', '内田雄馬', array['Yuma Uchida']::text[], 'solo', 4),
  ('声優', '内田真礼', array['Maaya Uchida']::text[], 'solo', 5),
  ('声優', '蒼井翔太', array['Shouta Aoi']::text[], 'solo', 6),
  ('声優', '小倉唯', array['Yui Ogura']::text[], 'solo', 7),
  ('声優', '江口拓也', array['Takuya Eguchi']::text[], 'solo', 8),
  ('声優', '梅原裕一郎', array['Yuichiro Umehara']::text[], 'solo', 9),
  ('声優', '西山宏太朗', array['Koutaro Nishiyama']::text[], 'solo', 10);

insert into public.groups_master (genre_id, name, aliases, kind, display_order)
select
  ge.id,
  sg.name,
  sg.aliases,
  sg.kind,
  sg.display_order
from _ihub_music_seed_groups sg
join public.genres_master ge on ge.name = sg.genre_name
on conflict (genre_id, name) do update
  set aliases = excluded.aliases,
      kind = excluded.kind,
      display_order = excluded.display_order;
