-- =====================================================================
-- iter168.20 follow-up: L2 が明確なグループ/作品の補完
-- =====================================================================

create temporary table _ihub_seed_characters (
  genre_name text not null,
  group_name text not null,
  name text not null,
  aliases text[] not null default '{}',
  display_order integer not null
) on commit drop;

insert into _ihub_seed_characters (genre_name, group_name, name, aliases, display_order) values
  ('キャラクターIP','ミッフィー','ミッフィー',array['Miffy']::text[],1),
  ('キャラクターIP','ミッフィー','メラニー',array['Melanie']::text[],2),
  ('キャラクターIP','ミッフィー','ボリス',array['Boris']::text[],3),
  ('キャラクターIP','ミッフィー','バーバラ',array['Barbara']::text[],4),
  ('キャラクターIP','おぱんちゅうさぎ','おぱんちゅうさぎ',array[]::text[],1),
  ('キャラクターIP','パペットスンスン','スンスン',array['SUNSUN']::text[],1),
  ('キャラクターIP','パペットスンスン','ノンノン',array['NONNON']::text[],2),
  ('キャラクターIP','パペットスンスン','ゾンゾン',array['ZONZON']::text[],3),
  ('VTuber・配信者','Fischer''s','シルクロード',array[]::text[],1),
  ('VTuber・配信者','Fischer''s','マサイ',array[]::text[],2),
  ('VTuber・配信者','Fischer''s','ンダホ',array[]::text[],3),
  ('VTuber・配信者','Fischer''s','モトキ',array[]::text[],4),
  ('VTuber・配信者','Fischer''s','ダーマ',array[]::text[],5),
  ('VTuber・配信者','Fischer''s','ザカオ',array[]::text[],6),
  ('お笑い','ジョックロック','ゆうじろー',array[]::text[],1),
  ('お笑い','ジョックロック','福本ユウショウ',array[]::text[],2),
  ('お笑い','ダイタク','吉本大',array[]::text[],1),
  ('お笑い','ダイタク','吉本拓',array[]::text[],2),
  ('お笑い','ニューヨーク','嶋佐和也',array[]::text[],1),
  ('お笑い','ニューヨーク','屋敷裕政',array[]::text[],2),
  ('お笑い','男性ブランコ','浦井のりひろ',array[]::text[],1),
  ('お笑い','男性ブランコ','平井まさあき',array[]::text[],2);

insert into public.characters_master (group_id, genre_id, name, aliases, display_order)
select
  gm.id,
  ge.id,
  sc.name,
  sc.aliases,
  sc.display_order
from _ihub_seed_characters sc
join public.genres_master ge on ge.name = sc.genre_name
join public.groups_master gm on gm.genre_id = ge.id and gm.name = sc.group_name
where not exists (
  select 1
  from public.characters_master c
  where c.group_id = gm.id
    and c.name = sc.name
);
