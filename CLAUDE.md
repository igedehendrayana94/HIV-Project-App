# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository. Local to HIV-Project-App — history/settings specific to this Flutter mobile app. Cross-project context lives in `~/Documents/ClaudeCodeProject/HIV-Project/CLAUDE.md`; the shared backend is `HIV-Project-Web`.

## Project Overview

- **Name:** Medi-Care HIV (mobile)
- **Purpose:** Native Flutter client for all three roles (ADMIN, PROVIDER, PATIENT), backed by the same Postgres/Prisma data as `HIV-Project-Web` — not a WebView wrapper.
- **Backend:** `HIV-Project-Web`'s Next.js API routes (`https://hiv-project-web.vercel.app/api`), reused as-is. Auth is Bearer-token (vs. the web app's httpOnly cookie) — see "Mobile integration" in `HIV-Project-Web/CLAUDE.md`.
- **Package/org:** `com.medicarehiv.hiv_project_app`
- **Status:** All 4 phases done — Patient, Provider, and Admin roles built, backed by the shared `HIV-Project-Web` backend. Phase 5 (polish) not started.
- **Owner:** igedehendrayana94
- **Full phased build plan:** `~/.claude/plans/typed-plotting-hearth.md`

## Environment constraints (this dev machine)

`flutter doctor`: no Android SDK, incomplete Xcode (no CocoaPods) — only macOS-desktop and
Chrome-web targets work here. `flutter analyze` + `flutter build web` are the practical
verification ceiling from this CLI; a real device/emulator walkthrough is a manual step for
the user once available.

## Architecture

- **State:** Riverpod (`flutter_riverpod` ^3.4.1 — note the v3 API: `AsyncValue.value` is
  nullable, not `.valueOrNull` like v2).
- **HTTP:** `dio`, single shared instance in `lib/core/api_client.dart` with a Bearer-token
  interceptor (reads `lib/core/token_storage.dart`, a `flutter_secure_storage` wrapper) and a
  401 handler that clears the stored token.
- **Routing:** `go_router`, `lib/core/router.dart` — redirect rules reimplement
  `HIV-Project-Web/src/proxy.ts`'s role gating client-side (no middleware layer in Flutter).
- **i18n:** `lib/shared/i18n.dart` mirrors `HIV-Project-Web/src/lib/i18n.ts`'s
  `{ key: { en, id } }` dictionary shape by hand — no ARB/gen-l10n toolchain.
- **API base URL:** defaults to the production web app; override locally with
  `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api`.

## Progress Log

- 2026-07-28: Phase 0 (backend) landed in `HIV-Project-Web`: `getSession()` accepts
  `Authorization: Bearer`, login returns the token in its JSON body, `/api/*` got CORS headers
  (safe — mobile auth is Bearer-only, never cookies), new `GET /api/screening/domains` serves
  the CDSS domain/symptom structure as JSON. Then scaffolded this Flutter app (Phase 1): auth
  flow (login/signup/pending-approval), Riverpod `AuthController`, secure token storage,
  role-based router redirect, placeholder post-login home screen. `flutter analyze` clean,
  `flutter build web` succeeds, one widget test passes. Repo created and pushed
  (`github.com/igedehendrayana94/HIV-Project-App`, SSH remote).
- 2026-07-28: Phase 2 (Patient role). Found three more backend gaps while wiring real screens
  (the original Phase 0 read was slightly optimistic that "every data shape already exists as
  an API") — all three were server-side-only logic living inside Next.js server components,
  which a Flutter client can't call into: `GET /api/patients/[id]/history` only returned
  `symptomReports`, not `screeningAssessments` (extended it, and let a PATIENT session resolve
  itself from the session and ignore the URL id entirely — the mobile client calls
  `/api/patients/me/history`); reminders had no `GET` at all (added one, patient reads only
  their own, provider/admin pass `?patientId=`); the AI chatbot's find-or-create-active-session
  logic lived only inline in `chat/page.tsx` (added `POST /api/chat/start` with the identical
  logic, left the web page untouched — no reason to add a round trip there). Also added `token`
  to `PATCH /api/account`'s response (same reasoning as login — the mobile app's stored JWT
  claims would otherwise go stale after a name/email edit until the next full login). All
  deployed to production individually as found.
  Built the actual screens: New Screening (fetches `GET /api/screening/domains`, renders the
  two-stage yes/no → 1-4 severity form as expandable domain sections, submits to
  `POST /api/screening`), a result screen (risk badge + the same `RECOMMENDATIONS` copy from
  `screeningModel.ts`, hand-mirrored into `lib/shared/risk.dart` since it's static clinical
  text, not admin-customizable like the questions), Screening History, a read-only Medication
  Reminder view, the AI Chatbot (start/send/escalate-confirm flow), and an Account screen
  (view/edit name+email+password via `PATCH /api/account`; photo upload explicitly skipped —
  add if requested). `RoleHomeScreen` now dispatches to a real `PatientHomeScreen` for
  role `PATIENT`; Provider/Admin still hit the Phase-1 placeholder. `flutter analyze` clean
  (two harmless `RadioListTile` deprecation infos left as-is — functional, not worth a
  `RadioGroup` refactor yet), `flutter build web` succeeds, widget test passes.
- 2026-07-28: Phase 3 (Provider role). Same pattern as Phase 2 — found the backend gaps by
  reading actual page code, not by guessing: `GET /api/patients/[id]` didn't exist at all
  (`patients/[id]/page.tsx` reads it server-side; added a route with the same access rule
  proxy.ts already enforces — any logged-in role can view a single patient by id, only the
  raw `/patients` *list* is Admin-only, so Provider mobile has no patient-browse screen, same
  as the web app — reached only via a consultation), and `GET /api/consultations/[id]/messages`
  didn't expose `patientId`/`patientName` (added both so the thread screen can link to that
  patient's history without a second lookup). Built Live Consultations inbox (urgency-colored
  list, matches the existing GET /api/consultations ordering), a consultation thread screen
  (10s `Timer.periodic` polling, claim/mark-resolved actions, patient-history link), and a
  read-only patient detail screen (basic info + screening history, reusing the same
  `ScreeningAssessment` model and `riskInfo` map from Phase 2). `RoleHomeScreen` now routes
  PROVIDER to a real home; Admin still hits the Phase-1 placeholder. `flutter analyze` clean
  (same two pre-existing infos), `flutter build web` succeeds, widget test passes.
- 2026-07-28: Phase 4 (Admin role), plus one real gap noticed along the way: Phase 2 never
  gave a Patient a way to actually create their own `Patient` record (the web app's
  `/patients/register` self-registration page, which `POST /api/patients` already supports
  for a PATIENT session) — a freshly-approved signup would 404 on every screening/chat call
  with "No patient record linked to this account" and have no in-app way out. Added
  `RegisterPatientScreen` (name/email/phone/DOB/timezone, timezone defaults to
  `Asia/Jakarta` — no IANA-timezone-detection package added for one text field) and a nav
  entry on the Patient home.
  Backend gaps found for Admin, same pattern as every phase before it: `GET /api/admin/users`
  was missing `status` (added it — needed to tell PENDING/REJECTED apart for approve/reject
  actions), and there was no `GET /api/patients` at all (`patients/page.tsx`, Admin-only on
  the web, reads it server-side) — added one gated to PROVIDER/ADMIN, not just Admin, since
  Provider needs a patient picker for reminders too, matching `POST /api/reminders`'s own role
  check.
  Built: Users (approve/reject/edit/delete, create-account form — skips the web form's
  optional "link an existing unlinked patient" convenience, since a patient can now
  self-register instead), Screening Questions (add/delete; the add form always creates the
  standard 1-4 severity scale rather than a fully dynamic option-list editor — matches every
  built-in symptom except one), Symptom Rules (add, toggle highRisk — no delete endpoint
  exists, matches the web app), Medication Reminders (patient picker + set form, reusing
  `GET/POST /api/reminders`), and Reports (CSV export). The export needed a real design
  change from the original plan: `GET /api/reports/export` needs the Bearer token like every
  other route, so a bare external-browser link (`url_launcher`, the original plan's
  assumption) can't authenticate — swapped `url_launcher` (added in Phase 1, never used) for
  `share_plus`: download the CSV via the already-authenticated `dio` client, hand the bytes
  straight to the OS share sheet. `RoleHomeScreen` now dispatches all three roles to their
  real home (Admin reuses Provider's Live-Consultations screen directly, not a copy).
  `flutter analyze` clean (same two pre-existing infos), `flutter build web` succeeds, widget
  test passes.
