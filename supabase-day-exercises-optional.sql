begin;

-- Idempotent: skip if column is already nullable.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'day_exercises'
      and column_name = 'exercise_id'
      and is_nullable = 'NO'
  ) then
    alter table public.day_exercises
      alter column exercise_id drop not null;
  else
    raise notice 'day_exercises.exercise_id is already nullable; skipping.';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'day_exercises'
      and column_name = 'exercise'
      and is_nullable = 'NO'
  ) then
    alter table public.day_exercises
      alter column exercise drop not null;
  else
    raise notice 'day_exercises.exercise is already nullable; skipping.';
  end if;
end $$;

commit;
