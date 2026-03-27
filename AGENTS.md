# AGENTS

## Product Scope
- Static admin portal for a calisthenics coaching workflow backed by Supabase.
- Main roles in the current system: `admin`, `trainer`, `trainee`.
- The frontend is plain HTML/CSS/JS with Vue loaded from CDN and Supabase JS in the browser.

## Current Requirements
- Admins can authenticate with Supabase email/password.
- Admins can manage trainees, plans, workout days, exercises, terminology, feedback, payments, max tests, and dashboard views.
- Trainers can access trainer-specific workflow such as coach tips, trainer notes, assigned trainees, and trainee feedback constrained by RLS.
- Admins with `admins.can_assign_trainers = true` can assign and unassign trainers from trainees.
- Admins with `admins.can_assign_trainers = true` also need a dedicated trainer-management area to:
  - list trainer accounts
  - create a trainer from an existing Supabase Auth user UUID plus display name
  - rename a trainer
  - delete a trainer and remove its trainee assignments
- Trainer management depends on Supabase RLS permitting assigner-admin CRUD on `public.trainers`.

## Data / Backend Notes
- `public.trainers.id` references `auth.users.id`; trainer creation in admin does not create an Auth user by itself.
- `public.trainee_trainers` is the join table for trainer assignments.
- The DB already received an audit fix patch for functions, RLS cleanup, indexes, and FK hardening.
- Migration tracking is intentionally still missing for now.

## Local Config Notes
- Runtime Supabase config is read from `app-config.local.js` and ignored by git.
- `.env` exists locally for project metadata, but the static frontend does not read it directly.

## Files Added For DB Operations
- `supabase-audit-fix.sql`: applied audit remediation patch.
- `supabase-trainer-admin.sql`: policy patch required for admin trainer CRUD from the browser client.
