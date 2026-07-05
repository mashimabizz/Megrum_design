alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_body_check;

alter table public.meguri_board_replies
  drop constraint if exists meguri_board_replies_body_or_image_check;

alter table public.meguri_board_replies
  add constraint meguri_board_replies_body_or_image_check
  check (
    char_length(btrim(body)) <= 1000
    and (
      char_length(btrim(body)) >= 1
      or coalesce(array_length(image_paths, 1), 0) >= 1
    )
  );
