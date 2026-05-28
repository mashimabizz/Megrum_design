-- =====================================================================
-- iter168.39: K-POP男性L2を旧メンバー文脈まで補完
-- =====================================================================
-- グッズ交換では現役メンバーだけでなく、旧譜・旧トレカ・過去ツアー
-- グッズの検索が発生するため、K-POP男性L1のL2候補を厚くする。

create temporary table _megrum_seed_kpop_male_characters (
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _megrum_seed_kpop_male_characters (group_name, name, aliases, display_order) values
  ('Stray Kids', 'ウジン', array['Woojin','Kim Woojin','キム・ウジン']::text[], 9),
  ('RIIZE', 'スンハン', array['Seunghan','Hong Seunghan','ホン・スンハン']::text[], 7),
  ('TREASURE', 'マシホ', array['Mashiho','高田真史帆','Takata Mashiho']::text[], 11),
  ('TREASURE', 'バン・イェダム', array['Bang Yedam','Yedam','イェダム']::text[], 12),
  ('THE BOYZ', 'ファル', array['Hwall','Hur Hyunjun','ヒョンジュン']::text[], 12),
  ('NCT 127', 'テイル', array['Taeil','Moon Taeil','ムン・テイル']::text[], 9),
  ('NCT 127', 'ウィンウィン', array['Winwin','Dong Sicheng','董思成']::text[], 10),
  ('EXO', 'レイ', array['Lay','Zhang Yixing','チャン・イーシン']::text[], 9),
  ('EXO', 'ルハン', array['Luhan']::text[], 10),
  ('EXO', 'クリス', array['Kris','Kris Wu','Wu Yifan']::text[], 11),
  ('EXO', 'タオ', array['Tao','Z.Tao','Huang Zitao']::text[], 12),
  ('SHINee', 'ジョンヒョン', array['Jonghyun','Kim Jonghyun','キム・ジョンヒョン']::text[], 5),
  ('MONSTA X', 'ウォノ', array['Wonho','Lee Hoseok','イ・ホソク']::text[], 7),
  ('BTOB', 'イルフン', array['Ilhoon','Jung Ilhoon','チョン・イルフン']::text[], 7),
  ('SUPER JUNIOR', 'ソンミン', array['Sungmin','Lee Sungmin']::text[], 10),
  ('SUPER JUNIOR', 'カンイン', array['Kangin','Kim Youngwoon']::text[], 11),
  ('SUPER JUNIOR', 'キボム', array['Kibum','Kim Kibum']::text[], 12),
  ('SUPER JUNIOR', 'ハンギョン', array['Hangeng','Han Geng','Hankyung']::text[], 13),
  ('SUPER JUNIOR', 'ヘンリー', array['Henry','Henry Lau','Super Junior-M']::text[], 14),
  ('SUPER JUNIOR', 'チョウミ', array['Zhou Mi','Zhoumi','Super Junior-M']::text[], 15),
  ('WayV', 'ルーカス', array['Lucas','Wong Yukhei','黄旭熙']::text[], 7),
  ('ONEUS', 'レイブン', array['Ravn','Kim Youngjo','キム・ヨンジョ']::text[], 6),
  ('BIGBANG', 'T.O.P', array['TOP','タプ','Choi Seunghyun']::text[], 4),
  ('BIGBANG', 'V.I', array['Seungri','スンリ','Lee Seunghyun']::text[], 5);

insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
select
  gm.id,
  ge.id,
  sc.name,
  sc.aliases,
  sc.display_order
from _megrum_seed_kpop_male_characters sc
join public.genres_master ge on ge.name = 'K-POP男性'
join public.groups_master gm on gm.genre_id = ge.id and gm.name = sc.group_name
where not exists (
  select 1
  from public.characters_master c
  where c.group_id = gm.id
    and c.name = sc.name
);

with selectable_members as (
  select
    'person'::text as entity_type,
    'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name as identity_key,
    cm.name as canonical_name,
    cm.aliases,
    cm.display_order
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
  where ge.name = 'K-POP男性'
),
entity_seed as (
  select identity_key, canonical_name, entity_type, aliases, display_order
  from selectable_members
)
insert into public.oshi_entities_master (
  identity_key,
  canonical_name,
  entity_type,
  aliases,
  display_order
)
select
  identity_key,
  canonical_name,
  entity_type,
  array(
    select distinct alias
    from unnest(coalesce(aliases, '{}'::text[])) as a(alias)
    where btrim(alias) <> ''
    order by alias
  ) as aliases,
  min(display_order) as display_order
from entity_seed
where btrim(identity_key) <> ''
  and btrim(canonical_name) <> ''
group by identity_key, canonical_name, entity_type, aliases
on conflict (identity_key) do update
  set canonical_name = excluded.canonical_name,
      entity_type = excluded.entity_type,
      aliases = array(
        select distinct alias
        from unnest(
          coalesce(public.oshi_entities_master.aliases, '{}'::text[])
          || coalesce(excluded.aliases, '{}'::text[])
        ) as a(alias)
        where btrim(alias) <> ''
        order by alias
      );

with member_entities as (
  select
    cm.id as character_id,
    'person:member:' || ge.name || ':' || coalesce(gm.name, '_none') || ':' || cm.name as identity_key
  from public.characters_master cm
  join public.groups_master gm on gm.id = cm.group_id
  join public.genres_master ge on ge.id = cm.genre_id
  where ge.name = 'K-POP男性'
)
update public.characters_master cm
set entity_id = e.id
from member_entities me
join public.oshi_entities_master e on e.identity_key = me.identity_key
where cm.id = me.character_id
  and cm.entity_id is distinct from e.id;

-- 同一人物がNCT内の複数L1に出る場合は、選択文脈だけ分けてentityは束ねる。
with nct_entity_links as (
  select source.id as source_character_id, target.entity_id
  from public.characters_master target
  join public.groups_master target_group on target_group.id = target.group_id
  join public.genres_master ge on ge.id = target.genre_id
  join public.characters_master source on source.genre_id = ge.id
  join public.groups_master source_group on source_group.id = source.group_id
  where ge.name = 'K-POP男性'
    and (
      (source_group.name = 'NCT 127' and source.name = 'マーク' and target_group.name = 'NCT DREAM' and target.name = 'マーク') or
      (source_group.name = 'NCT 127' and source.name = 'ヘチャン' and target_group.name = 'NCT DREAM' and target.name = 'ヘチャン') or
      (source_group.name = 'NCT 127' and source.name = 'ウィンウィン' and target_group.name = 'WayV' and target.name = 'ウィンウィン')
    )
)
update public.characters_master cm
set entity_id = nel.entity_id
from nct_entity_links nel
where cm.id = nel.source_character_id
  and cm.entity_id is distinct from nel.entity_id;
