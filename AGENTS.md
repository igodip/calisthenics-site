# AGENTS

## Product Scope
- Static admin portal for a calisthenics coaching workflow backed by Supabase.
- Main roles in the current system: `admin`, `trainer`, `trainee`.
- The frontend is plain HTML/CSS/JS with Vue 3 loaded from CDN and Supabase JS in the browser.
- No build step — direct file edits, hot-reload via browser refresh.

## Current Requirements
- Admins can authenticate with Supabase email/password.
- Admins can manage trainees (CRUD), plans, workout days, prescribed workout entries, feedback, payments, max tests, weight logs, and dashboard views.
- The exercise catalogue and terminology are not exposed as portal sections or editable browser data. They remain developer-managed directly in the database; frontend exercise reads are limited to internal plan/import reference resolution.
- Trainers can access trainer-specific workflow such as coach tips, trainer notes, assigned trainees, and trainee feedback constrained by RLS.
- Admins with `admins.can_assign_trainers = true` can assign and unassign trainers from trainees.
- Admins with `admins.can_assign_trainers = true` also need a dedicated trainer-management area to:
  - list trainer accounts
  - create a trainer from an existing Supabase Auth user UUID plus display name
  - rename a trainer
  - delete a trainer and remove its trainee assignments
- Trainer management depends on Supabase RLS permitting assigner-admin CRUD on `public.trainers`.
- All errors are surfaced via non-blocking toast notifications (`showToast()`) — never `alert()`.

## Data / Backend Notes
- `public.trainers.id` references `auth.users.id`; trainer creation in admin does not create an Auth user by itself.
- `public.trainee_trainers` is the join table for trainer assignments.
- `public.trainee_monthly_payments` requires a unique constraint on `(trainee_id, month_start)` for upsert to work — defined in `supabase-policies-constraints.sql`.
- The DB already received an audit fix patch for functions, RLS cleanup, indexes, and FK hardening.
- Migration tracking is intentionally still missing for now. SQL patches are idempotent where possible.

## Local Config Notes
- Runtime Supabase config is read from `app-config.local.js` and ignored by git.
- `.env` exists locally for project metadata, but the static frontend does not read it directly.

## Files Added For DB Operations
- `supabase-audit-fix.sql`: applied audit remediation patch.
- `supabase-trainer-admin.sql`: policy patch required for admin trainer CRUD from the browser client.
- `supabase-day-exercises-optional.sql`: optional patch to make exercise_id/exercise columns nullable (idempotent, skips if NOT NULL already enforced).
- `supabase-policies-constraints.sql`: new patch with unique constraint for payments upsert, RLS policies for `trainee_feedbacks` and `trainee_monthly_payments`.

## Architecture Notes
- **Zero-build**: Vue 3, Supabase, and PDF.js loaded via CDN/ESM.
- **Security**: Relies entirely on Supabase Row Level Security (RLS). No backend API.
- **Data visualization**: Custom SVG rendering for charts (no charting libraries).
- **i18n**: English and Italian via `translations.js`. All user-facing strings must have both `en` and `it` entries.
- **Toast notifications**: `showToast(message, type, duration)` in `app.js` — use instead of `alert()`. Type is `'error'` or `'success'`, default duration 5000ms.
- **Page detection**: `isTraineeDetailPage` uses `pageUrl.pathname.includes('/trainee.html')` for subdirectory resilience.
- **PDF.js**: Worker URL loaded from CDN with fallback validation in `showToast` if unavailable.

## Recent UI / Styling Work
- `styles.css` received a broad visual cleanup for the admin portal:
  - reduced oversized radii and decorative effects
  - normalized page/card padding and section gaps with shared CSS variables
  - added a `--content-max` constraint for the main content area
  - improved desktop dashboard/payment grid behavior
  - improved mobile sidebar, toolbar, and card stacking behavior
  - hid the mobile horizontal nav scrollbar while preserving scroll
- Fixed an active-section layout bug: `.section-panel.active` now uses grid spacing, while `.row.section-panel.active` explicitly remains flex so row/column pages render correctly.
- Reduced nested-card visual clutter by styling cards inside list/payment containers as flatter row items.
- Added missing component styles for `.summary-item`, `.summary-label`, `.payment-amount-row`, `.data-row`, `.data-chips`, `.data-block`, `.history-card`, and `.history-card-head`.
- Added `button.ghost` styling because some existing template buttons use `class="small ghost"` without the `.btn` class.
- `trainee.html` received a deeper interface rework:
  - trainee-specific shell/topbar classes
  - profile hero with progress, weight, payment, and trainer metrics
  - sticky segmented tabs with ARIA tab metadata
  - clearer overview card placement for trainee data, feedback, calendar, payments, and weight history
  - denser plan-builder workspace using a single framed editor surface
  - compact row styling for weight logs and max-test entries
- Visual verification was done with a local static server (`python3 -m http.server 3000`) and Chromium screenshots for:
  - unauthenticated login on desktop and mobile
  - a temporary mocked authenticated dashboard/payment layout under `/tmp`
- Additional trainee-page verification used `/tmp/calisync-trainee-fixture.html` for desktop/mobile screenshots of overview, plan builder, and max-test sections.
- Temporary fixtures were created outside the repo under `/tmp`; they are not part of the project.

## Known Technical Debt
- No pagination for large datasets (all queries load everything into memory).
- No offline or retry handling — Supabase calls fail hard on network blips.
- No migration tracking table — SQL patches applied manually.
- Supabase anon key has a hardcoded fallback in `supabase-client.js` if `app-config.local.js` is missing.
- `deleteDay` cleans up `workout_plan_days` but not `trainee_exercise_completions` for that day's exercises (orphaned completions remain).
