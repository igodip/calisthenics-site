begin;

alter table public.day_exercises
  alter column exercise_id drop not null;

alter table public.day_exercises
  alter column exercise drop not null;

commit;
