-- スケジュールにテキストの場所を持たせる
alter table public.schedules
  add column if not exists place_name text;

alter table public.schedules
  drop constraint if exists schedules_place_name_length;

alter table public.schedules
  add constraint schedules_place_name_length
  check (place_name is null or length(place_name) <= 200);
