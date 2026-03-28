begin;

create table if not exists public.trainee_weight_logs (
  id uuid primary key default gen_random_uuid(),
  trainee_id uuid not null references public.trainees(id) on delete cascade,
  weight numeric not null check (weight > 0),
  recorded_at date not null default current_date,
  notes text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_trainee_weight_logs_trainee_recorded_at
  on public.trainee_weight_logs (trainee_id, recorded_at desc, created_at desc);

alter table public.trainee_weight_logs enable row level security;

drop policy if exists trainee_weight_logs_select_access on public.trainee_weight_logs;
drop policy if exists trainee_weight_logs_insert_admin on public.trainee_weight_logs;
drop policy if exists trainee_weight_logs_update_admin on public.trainee_weight_logs;
drop policy if exists trainee_weight_logs_delete_admin on public.trainee_weight_logs;

create policy trainee_weight_logs_select_access
on public.trainee_weight_logs
for select
to public
using (
  is_admin(auth.uid())
  or auth.uid() = trainee_id
  or is_assigned_trainer(auth.uid(), trainee_id)
);

create policy trainee_weight_logs_insert_admin
on public.trainee_weight_logs
for insert
to public
with check (is_admin(auth.uid()));

create policy trainee_weight_logs_update_admin
on public.trainee_weight_logs
for update
to public
using (is_admin(auth.uid()))
with check (is_admin(auth.uid()));

create policy trainee_weight_logs_delete_admin
on public.trainee_weight_logs
for delete
to public
using (is_admin(auth.uid()));

create or replace function public.sync_trainee_weight_from_logs()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_trainee_id uuid;
begin
  target_trainee_id := coalesce(new.trainee_id, old.trainee_id);

  update public.trainees t
  set weight = latest.weight
  from (
    select twl.trainee_id, twl.weight
    from public.trainee_weight_logs twl
    where twl.trainee_id = target_trainee_id
    order by twl.recorded_at desc, twl.created_at desc
    limit 1
  ) as latest
  where t.id = latest.trainee_id;

  if not exists (
    select 1
    from public.trainee_weight_logs twl
    where twl.trainee_id = target_trainee_id
  ) then
    update public.trainees
    set weight = null
    where id = target_trainee_id;
  end if;

  return null;
end;
$$;

drop trigger if exists trainee_weight_logs_sync_trainee_weight on public.trainee_weight_logs;

create trigger trainee_weight_logs_sync_trainee_weight
after insert or update or delete on public.trainee_weight_logs
for each row
execute function public.sync_trainee_weight_from_logs();

commit;
