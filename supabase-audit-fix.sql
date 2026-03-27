-- Patch SQL per correggere i finding 1,2,3,6,7 dell'audit Supabase.
-- Non applica migration tracking; prepara solo uno script eseguibile.

begin;

-- 1,3. Funzioni corrette e con search_path esplicito.

create or replace function public.can_assign_trainers()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admins a
    where a.id = auth.uid()
      and a.can_assign_trainers = true
  );
$$;

create or replace function public.current_trainer_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select t.id
  from public.trainers t
  where t.id = auth.uid()
  limit 1;
$$;

create or replace function public.current_trainee_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select tr.id
  from public.trainees tr
  where tr.id = auth.uid()
  limit 1;
$$;

create or replace function public.is_owner(p_owner uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() = p_owner;
$$;

create or replace function public.is_admin_assigner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admins a
    where a.id = auth.uid()
      and a.can_assign_trainers = true
  );
$$;

create or replace function public.is_admin_any()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admins a
    where a.id = auth.uid()
  );
$$;

create or replace function public.is_shared_with_me(
  p_owner uuid,
  min_role share_role default 'viewer'::share_role
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  -- Feature legacy: evita errori runtime finché `public.shares` non viene ripristinata o rimossa del tutto.
  select false;
$$;

create or replace function public.tg_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- 2. Consolidamento policy RLS duplicate / sovrapposte.

drop policy if exists de_all_admin on public.day_exercises;
drop policy if exists day_exercises_select_access on public.day_exercises;
drop policy if exists day_exercises_insert_access on public.day_exercises;
drop policy if exists day_exercises_update_access on public.day_exercises;
drop policy if exists day_exercises_delete_access on public.day_exercises;

create policy day_exercises_select_access
on public.day_exercises
for select
to public
using (public.can_access_day(day_id));

create policy day_exercises_insert_access
on public.day_exercises
for insert
to public
with check (public.can_access_day(day_id));

create policy day_exercises_update_access
on public.day_exercises
for update
to public
using (public.can_access_day(day_id))
with check (public.can_access_day(day_id));

create policy day_exercises_delete_access
on public.day_exercises
for delete
to public
using (public.can_access_day(day_id));

drop policy if exists days_all_admin on public.days;
drop policy if exists days_delete on public.days;
drop policy if exists days_delete_trainer_or_admin on public.days;
drop policy if exists days_delete_trainers on public.days;
drop policy if exists days_insert_trainers on public.days;
drop policy if exists days_select on public.days;
drop policy if exists days_select_access on public.days;
drop policy if exists days_select_trainers on public.days;
drop policy if exists days_update_trainers on public.days;

create policy days_select_access
on public.days
for select
to public
using (public.can_access_day(id) or public.is_trainer());

create policy days_insert_access
on public.days
for insert
to public
with check (public.is_admin(auth.uid()) or public.is_trainer());

create policy days_update_access
on public.days
for update
to public
using (public.is_admin(auth.uid()) or public.is_trainer())
with check (public.is_admin(auth.uid()) or public.is_trainer());

create policy days_delete_access
on public.days
for delete
to public
using (public.is_admin(auth.uid()) or public.is_trainer());

drop policy if exists workout_plans_delete on public.workout_plans;
drop policy if exists workout_plans_delete_own on public.workout_plans;
drop policy if exists workout_plans_insert on public.workout_plans;
drop policy if exists workout_plans_insert_own on public.workout_plans;
drop policy if exists workout_plans_insert_trainee_self_or_admin on public.workout_plans;
drop policy if exists workout_plans_select on public.workout_plans;
drop policy if exists workout_plans_select_access on public.workout_plans;
drop policy if exists workout_plans_select_own on public.workout_plans;
drop policy if exists workout_plans_update on public.workout_plans;
drop policy if exists workout_plans_update_access on public.workout_plans;
drop policy if exists workout_plans_update_own on public.workout_plans;

create policy workout_plans_select_access
on public.workout_plans
for select
to public
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy workout_plans_insert_access
on public.workout_plans
for insert
to public
with check (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy workout_plans_update_access
on public.workout_plans
for update
to public
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
)
with check (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy workout_plans_delete_access
on public.workout_plans
for delete
to public
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
);

drop policy if exists insert_own on public.max_tests;
drop policy if exists max_tests_modify_access on public.max_tests;
drop policy if exists max_tests_select_access on public.max_tests;
drop policy if exists select_own on public.max_tests;

create policy max_tests_select_access
on public.max_tests
for select
to public
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy max_tests_modify_access
on public.max_tests
for all
to public
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
)
with check (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

-- 7. Rinforzo integrità dati.

update public.day_exercises de
set exercise_id = e.id
from public.exercises e
where de.exercise_id is null
  and (
    lower(btrim(de.exercise)) = lower(btrim(e.name))
    or lower(btrim(de.exercise)) = lower(btrim(e.slug))
  );

update public.day_exercises de
set exercise = e.name
from public.exercises e
where de.exercise_id = e.id
  and (de.exercise is null or btrim(de.exercise) = '');

do $$
begin
  if exists (
    select 1
    from public.day_exercises
    where exercise_id is null
  ) then
    raise exception
      'Cannot enforce day_exercises.exercise_id NOT NULL: unresolved rows still exist.';
  end if;
end $$;

alter table public.day_exercises
  alter column exercise_id set not null;

alter table public.day_exercises
  alter column exercise set not null;

do $$
begin
  if exists (
    select 1
    from public.max_tests
    where trainee_id is null
  ) then
    raise exception
      'Cannot enforce max_tests.trainee_id NOT NULL: rows with NULL trainee_id exist.';
  end if;
end $$;

alter table public.max_tests
  alter column trainee_id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'max_tests_trainee_id_fkey'
      and conrelid = 'public.max_tests'::regclass
  ) then
    alter table public.max_tests
      add constraint max_tests_trainee_id_fkey
      foreign key (trainee_id)
      references public.trainees(id)
      on update cascade
      on delete cascade;
  end if;
end $$;

commit;

-- 6. Indici mancanti e indice duplicato.
create index if not exists idx_day_exercises_exercise_id
  on public.day_exercises (exercise_id);

create index if not exists idx_exercise_translations_exercise_id
  on public.exercise_translations (exercise_id);

create index if not exists idx_trainee_exercise_unlocks_exercise_id
  on public.trainee_exercise_unlocks (exercise_id);

create index if not exists idx_max_tests_trainee_id
  on public.max_tests (trainee_id);

drop index if exists public.workout_plans_trainee_id_idx;
