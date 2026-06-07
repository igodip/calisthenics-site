-- Idempotent patch: unique constraint for trainee_monthly_payments upsert,
-- RLS policies for trainee_feedbacks and trainee_monthly_payments,
-- and guard for day_exercises optional columns.
-- Safe to apply multiple times.

begin;

-- 1. Unique constraint for trainee_monthly_payments upsert (required by app.js upsert).
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'trainee_monthly_payments_trainee_month_unique'
      and conrelid = 'public.trainee_monthly_payments'::regclass
  ) then
    alter table public.trainee_monthly_payments
      add constraint trainee_monthly_payments_trainee_month_unique
      unique (trainee_id, month_start);
  end if;
end $$;

-- 2. RLS policies for trainee_feedbacks.
alter table public.trainee_feedbacks enable row level security;

drop policy if exists trainee_feedbacks_select on public.trainee_feedbacks;
drop policy if exists trainee_feedbacks_insert on public.trainee_feedbacks;
drop policy if exists trainee_feedbacks_update on public.trainee_feedbacks;
drop policy if exists trainee_feedbacks_delete on public.trainee_feedbacks;

create policy trainee_feedbacks_select
on public.trainee_feedbacks
for select
to authenticated
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy trainee_feedbacks_insert
on public.trainee_feedbacks
for insert
to authenticated
with check (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy trainee_feedbacks_update
on public.trainee_feedbacks
for update
to authenticated
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

create policy trainee_feedbacks_delete
on public.trainee_feedbacks
for delete
to authenticated
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

-- 3. RLS policies for trainee_monthly_payments.
alter table public.trainee_monthly_payments enable row level security;

drop policy if exists trainee_monthly_payments_select on public.trainee_monthly_payments;
drop policy if exists trainee_monthly_payments_insert on public.trainee_monthly_payments;
drop policy if exists trainee_monthly_payments_update on public.trainee_monthly_payments;
drop policy if exists trainee_monthly_payments_delete on public.trainee_monthly_payments;

create policy trainee_monthly_payments_select
on public.trainee_monthly_payments
for select
to authenticated
using (
  public.is_admin(auth.uid())
  or trainee_id = auth.uid()
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy trainee_monthly_payments_insert
on public.trainee_monthly_payments
for insert
to authenticated
with check (
  public.is_admin(auth.uid())
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy trainee_monthly_payments_update
on public.trainee_monthly_payments
for update
to authenticated
using (
  public.is_admin(auth.uid())
  or public.is_assigned_trainer(auth.uid(), trainee_id)
)
with check (
  public.is_admin(auth.uid())
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

create policy trainee_monthly_payments_delete
on public.trainee_monthly_payments
for delete
to authenticated
using (
  public.is_admin(auth.uid())
  or public.is_assigned_trainer(auth.uid(), trainee_id)
);

commit;

-- 4. Guard for day_exercises optional columns (idempotent: skip if NOT NULL already enforced).
-- This patch is an alternative to the audit fix which enforces NOT NULL.
-- Apply only if you need nullable exercise_id/exercise columns.
do $$
begin
  -- Check if exercise_id is already NOT NULL; skip if so.
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'day_exercises'
      and column_name = 'exercise_id'
      and is_nullable = 'NO'
  ) then
    raise notice 'day_exercises.exercise_id is already NOT NULL; skipping optional patch.';
  else
    alter table public.day_exercises
      alter column exercise_id drop not null;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'day_exercises'
      and column_name = 'exercise'
      and is_nullable = 'NO'
  ) then
    raise notice 'day_exercises.exercise is already NOT NULL; skipping optional patch.';
  else
    alter table public.day_exercises
      alter column exercise drop not null;
  end if;
end $$;
