-- =====================================================================
-- iter168.36: L2名検索の代表例としてアンジュルム / 笠原桃奈を補完
-- =====================================================================
-- 「笠原桃奈」で検索したとき、同名メンバーを含むL1として ME:I と
-- アンジュルムが返るよう、アンジュルム側のL2を補完する。

insert into public.characters_master (
  group_id,
  genre_id,
  name,
  aliases,
  display_order,
  entity_id
)
select
  gm.id,
  gm.genre_id,
  '笠原桃奈',
  array['Momona Kasahara']::text[],
  coalesce(
    (
      select max(cm.display_order) + 1
      from public.characters_master cm
      where cm.group_id = gm.id
    ),
    1
  ),
  (
    select cm.entity_id
    from public.characters_master cm
    where cm.name = '笠原桃奈'
      and cm.entity_id is not null
    order by cm.created_at
    limit 1
  )
from public.groups_master gm
where gm.name = 'アンジュルム'
  and not exists (
    select 1
    from public.characters_master existing
    where existing.group_id = gm.id
      and existing.name = '笠原桃奈'
  );
