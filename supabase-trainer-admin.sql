begin;

drop policy if exists trainers_admin_assigner_select on public.trainers;
drop policy if exists trainers_admin_assigner_insert on public.trainers;
drop policy if exists trainers_admin_assigner_update on public.trainers;
drop policy if exists trainers_admin_assigner_delete on public.trainers;

create policy trainers_admin_assigner_select
on public.trainers
for select
to authenticated
using (public.can_assign_trainers());

create policy trainers_admin_assigner_insert
on public.trainers
for insert
to authenticated
with check (public.can_assign_trainers());

create policy trainers_admin_assigner_update
on public.trainers
for update
to authenticated
using (public.can_assign_trainers())
with check (public.can_assign_trainers());

create policy trainers_admin_assigner_delete
on public.trainers
for delete
to authenticated
using (public.can_assign_trainers());

commit;
