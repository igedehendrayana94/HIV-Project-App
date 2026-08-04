# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository. Local to HIV-Project-App — history/settings specific to this Flutter mobile app. Cross-project context lives in `~/Documents/ClaudeCodeProject/HIV-Project/CLAUDE.md`; the shared backend is `HIV-Project-Web`.

## Project Overview

- **Name:** Medi-Care HIV (mobile)
- **Purpose:** Native Flutter client for all three roles (ADMIN, PROVIDER, PATIENT), backed by the same Postgres/Prisma data as `HIV-Project-Web` — not a WebView wrapper.
- **Backend:** `HIV-Project-Web`'s Next.js API routes (`https://hiv-project-web.vercel.app/api`), reused as-is. Auth is Bearer-token (vs. the web app's httpOnly cookie) — see "Mobile integration" in `HIV-Project-Web/CLAUDE.md`.
- **Package/org:** `com.medicarehiv.hiv_project_app`
- **Status:** All 5 original build phases done, plus a full UI/UX redesign (2026-07-31) — bold vibrant theme, persistent bottom-nav, real animation, EN/ID toggle, search/filter, confirm dialogs. Verified live on the iOS Simulator (see Environment note below — the "no CocoaPods" constraint no longer holds).
- **Owner:** igedehendrayana94
- **Full phased build plan:** `~/.claude/plans/typed-plotting-hearth.md`

## Environment constraints (this dev machine)

As of 2026-07-31: full Xcode + CocoaPods now available — `flutter run -d <simulator-udid>`
against a booted iOS Simulator works end-to-end (build, install, launch, hot restart), and
this is now the actual verification method used, not just `flutter analyze`/`flutter build
web`. (Earlier note below is now stale but kept for history: no Android SDK still applies —
Android builds/emulators remain unverified from this machine.) UI automation (scripted
tap/type into the simulator) is NOT reliably available — `osascript`/System Events clicks
get intercepted by the host IDE's own overlay window regardless of Accessibility permissions;
manual login/click-through by the user is required to test interactive flows beyond static
screens.

## Architecture

- **State:** Riverpod (`flutter_riverpod` ^3.4.1 — note the v3 API: `AsyncValue.value` is
  nullable, not `.valueOrNull` like v2).
- **HTTP:** `dio`, single shared instance in `lib/core/api_client.dart` with a Bearer-token
  interceptor (reads `lib/core/token_storage.dart`, a `flutter_secure_storage` wrapper) and a
  401 handler that clears the stored token.
- **Routing:** `go_router`, `lib/core/router.dart` — redirect rules reimplement
  `HIV-Project-Web/src/proxy.ts`'s role gating client-side (no middleware layer in Flutter).
- **i18n:** `lib/shared/i18n.dart` mirrors `HIV-Project-Web/src/lib/i18n.ts`'s
  `{ key: { en, id } }` dictionary shape by hand — no ARB/gen-l10n toolchain. `AppStrings.locale`
  (static, default `AppLocale.id`) is kept in sync with `lib/core/locale_state.dart`'s
  `localeProvider` (Riverpod `Notifier`, persisted via `shared_preferences`) — screens read
  `AppStrings.t('key')` directly, the provider exists for reactivity + persistence.
- **API base URL:** defaults to the production web app; override locally with
  `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api`.
- **Design system** (`lib/core/theme.dart`, redesigned 2026-07-31): `AppSpacing`
  (xs/sm/md/lg/xl = 4/8/16/24/32, 8pt grid) and `AppRadius` (card=20, button/chip=999) are the
  only sanctioned spacing/radius constants — never raw numbers. Bold vibrant palette
  (`kVibrantPrimary` = `#C2185B`, 5.87:1 contrast vs white, audited) drives every primary
  surface as a flat solid fill, not a tonal tint; `kBrandSoft`/`kBrandSoftAlt` (the original
  D68888/BF8080 pink pair) survive as decorative/secondary accents only.
  `ThemeData.pageTransitionsTheme` is overridden app-wide with a custom slide-up+fade
  transition — every `Navigator.push`/route change gets this automatically, no per-screen work.
- **Shared widgets** (`lib/shared/`): `AppCard` (soft rounded surface, wraps tappable content in
  `Bouncy` for spring-scale press feedback), `EmptyState` (icon+message+optional CTA, replaces
  bare "No X yet." text), `RiskPill` (one canonical risk-level chip, was duplicated 3 ways),
  `LiveDot` (pulsing indicator for actively-polling screens), `SkeletonList` (shimmer loading
  placeholder), `AmbientGlow` (slow animated radial-gradient blobs behind home-tab content,
  mirrors the web landing page's `HeroGlow`), `PasswordField` (show/hide eye toggle, mirrors
  web's `PasswordInput.tsx`), `confirm_dialog.dart`'s `confirmAction()` (shared
  are-you-sure dialog — logout and every destructive action route through this).
- **Navigation shell** (`lib/core/router.dart` + `lib/features/{patient,provider,admin}/*_shell.dart`):
  `StatefulShellRoute.indexedStack` per role gives each role a persistent bottom `NavigationBar`
  (replaced the old flat `/home` route + push-only hub pattern). Each role's home screen
  (`*_home_screen.dart`) is now just one tab among several, kept only for lower-frequency
  destinations; deeper screens still use plain `Navigator.push` inside a branch's own stack —
  no full conversion to named nested routes was needed.

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
- 2026-07-28: Phase 5 (polish). Added one shared `AsyncErrorView` widget (icon + message +
  Retry button, `ref.invalidate(...)` on tap) and swapped it into every `FutureProvider
  .when()` error branch across all three roles — previously each screen's error state was a
  bare `Center(Text(...))` with no recovery short of leaving and re-entering. Added
  `RefreshIndicator` to the handful of list screens that were still missing it (symptom
  rules, screening questions, the admin patient picker, the read-only reminder view, patient
  detail) so pull-to-refresh is now consistent everywhere there's a list or a single fetched
  record, including the empty-state case (previously a plain `Center` with no scrollable
  ancestor, so pulling did nothing). App naming/branding: every platform's scaffold-default
  name (`hiv_project_app` / "Hiv Project App") replaced with "Medi-Care HIV" — Android
  manifest label, iOS `CFBundleDisplayName`/`CFBundleName`, macOS `PRODUCT_NAME`, web
  manifest + `index.html` title/meta. Android's launch (splash) background recolored from
  the Flutter-default white to the app's teal (`#0D9488`, matches `lib/core/theme.dart`'s
  seed color) via a new `values/colors.xml`. Skipped a real custom app *icon* — every
  platform still ships Flutter's default icon — since there's no source logo asset to
  generate one from; add via `flutter_launcher_icons` once a design exists.
  `flutter analyze` clean (same two pre-existing infos), `flutter build web` succeeds, widget
  test passes.
- 2026-07-31: **Real app icon + branding.** User supplied a real logo (`HIV-Project-Src/Medi-Care
  HIV.png`) — generated via `flutter_launcher_icons` for iOS (flattened to an opaque square,
  since iOS icons can't have transparency/pre-baked rounding — iOS masks the corners itself)
  and Android (adaptive icon, transparent foreground + `#F38181` background matching the
  logo's own bg color). Also added the logo as an in-app asset (`assets/branding/logo.png`,
  shown above the title on login/signup).
- 2026-07-31: **Security — old/new/confirm password flow.** Root-cause fix for a recurring
  production incident (`AccountScreen`'s "Change password" toggle sent whatever was in the
  password field on save, including autofill-populated-but-never-typed values). Toggle alone
  wasn't enough — a stolen/left-open session could still silently change the password with no
  proof of identity. `PATCH /api/account` (shared by this app and `HIV-Project-Web`'s
  Preferences page) now requires `oldPassword`, verified server-side via `bcrypt.compare`
  before any new password is accepted; both clients collect Current/New/Confirm-New instead
  of one field. See `HIV-Project-Web/CLAUDE.md` for the backend side.
- 2026-07-31: **Full UI/UX redesign — "calm health app" then "bold vibrant" (Duolingo/Cash
  App).** Client feedback (via the user) was that the app looked generic/old-school;
  first pass (soft pastel D68888 theme, subtle motion) still read as "too simple, low
  contrast" on real review, so the palette was pushed to a saturated, AA-audited primary
  (`#C2185B`) with solid fills and true black/white text instead of muted tonal containers —
  see the Architecture section above for the resulting design-system shape. Delivered in
  phases (plan file: `~/.claude/plans/reactive-mixing-cupcake.md`):
  - **Phase 0** — design system foundation (`theme.dart`, `AppSpacing`/`AppRadius`, the shared
    widget set, `flutter_animate` dependency added).
  - **Phase 1** — navigation shell rewrite (`StatefulShellRoute.indexedStack` per role,
    persistent bottom nav, old `role_home_screen.dart` dispatcher deleted as dead code).
  - **Phase 2** — visual reskin of all ~30 screens (parallelized across 3 background agents,
    one per role, after Phase 0/1 landed — zero merge conflicts since each agent owned a
    disjoint set of files and was instructed not to edit the shared `i18n.dart`).
  - **Phase 3** — form friction reduction: `new_screening_screen.dart` rebuilt from one long
    `ExpansionTile`-per-domain list into a `PageView` stepper (one domain per step, progress
    bar, Next/Back, last step submits directly — no separate review page, a deliberate scope
    cut). Scoring/submission logic untouched.
  - **Phase 4** — real-time feel: consultations inbox now polls every 8s (silent, matches the
    web app's own `ConsultationQueue.tsx` interval) with a `LiveDot` indicator, extending the
    `Timer.periodic(silent:true)` pattern that previously only existed on the consultation
    thread screen.
  - **Phase 5** — finished i18n wiring (the dictionary in `lib/shared/i18n.dart` grew from ~10
    keys to ~130 this session) into every screen touched during the reskin, in the same pass
    rather than a second sweep.
  - **Phase 6 + follow-ups** — `flutter analyze` clean throughout, verified live on the iOS
    Simulator after each phase. Follow-up fixes from real user review: `AppCard`'s default
    padding bumped from `AppSpacing.md` (16) to `lg` (24) after a real "text overlapping the
    card border" bug — the card's 20px corner radius was bigger than its padding, so content
    near the top-left corner visually clipped into the rounding; symptom-rules screen's raw
    internal `key` subtitle (e.g. `breathing_difficulty` under "Breathing Difficulty") was
    hidden per user request — a legitimate admin-debugging aid, not a translation bug, but
    the user wanted a cleaner look; added a password show/hide eye toggle
    (`lib/shared/password_field.dart`, mirrors web's `PasswordInput.tsx`) to all 4 password
    fields app-wide (login, signup, create-user, account — the gap was real: there was
    previously no way to check a typo'd password before submitting); added `confirmAction()`
    (`lib/shared/confirm_dialog.dart`) before logout and every destructive action
    (delete account, delete screening question, reject a consultation).
- 2026-07-31: **Front-end↔back-end connection audit.** Systematically inventoried every
  `dio.*` call in this app against the actual `HIV-Project-Web` route handlers (auth header
  format, response shapes, required params). Found the Bearer-token handshake, `patients/me`
  session-resolution, and every response shape already matched correctly — one real gap:
  `POST /consultations/[id]/reject` existed on the backend (an unclaimed-OPEN-only atomic
  guard) but had no Flutter caller at all, so a provider/admin on mobile could Claim but never
  Reject an unclaimed request. Added a Reject button (`Icons.close`, only shown when
  `assignedProviderName == null && status == 'OPEN'`, matching the backend's own guard) to
  `consultations_inbox_screen.dart`'s row widget.
- 2026-07-31: **Search/filter.** Added to the highest-traffic list screens (parallelized in a
  background agent alongside a matching pass on `HIV-Project-Web`, since the two repos share
  zero files): Admin Users (name/email search), Consultations inbox (urgency `ChoiceChip`
  filter — All/Emergency/Urgent/Routine, composes with the existing 8s poll and the new Reject
  action), both patient-picker screens (name search), Screening History (risk-level
  `ChoiceChip` filter). All client-side filtering of the already-fetched list — no new API
  calls, no pagination added.
- 2026-08-02: **Bug audit + fixes: dead back-to-home button, stale history after screening
  submit.** User reported the "Kembali ke Beranda" button on the screening result screen did
  nothing for a self-screening patient, and the dashboard/history only updated after a manual
  pull-to-refresh. Root cause for the button: `new_screening_screen.dart`'s `_submit()` reaches
  the result screen via `Navigator.pushReplacement` — for the patient's own screening flow
  (the Screening tab's `StatefulShellBranch` root), this makes the result screen the new root
  of that branch's nested Navigator, so `result_screen.dart`'s
  `Navigator.popUntil((r) => r.isFirst)` had nothing left to pop (already correctly a no-op
  bug, not intermittent — it only ever worked for the provider-initiated flow, which has extra
  stack depth). Fixed with a shell-aware `context.go('/home')`, which works regardless of
  branch/depth; `popUntil` can never cross `StatefulShellRoute` branch boundaries anyway, so it
  was the wrong tool even before this bug surfaced. Added
  `test/screening_back_to_home_test.dart`, a Flutter-test-framework regression test that
  reproduces the exact shell-branch-root scenario (submit → pushReplacement → tap button →
  assert Home renders) — used this to confirm the fix was correct at the code level before
  asking the user to verify on-device, after a first "still broken" report turned out to be a
  stale build (the added `go_router` import needed a hot **restart**, not reload).
  Root cause for the stale history: nothing in the submit → result → back-to-home path ever
  called `ref.invalidate()` on `screeningHistoryProvider` (patient) or the provider-side
  patient-detail history provider — Riverpod `FutureProvider`s cache until explicitly
  invalidated, and the only refresh trigger anywhere in the app was manual pull-to-refresh.
  `new_screening_screen.dart._submit()` now invalidates the correct one after a successful
  POST (self-screening vs. provider-initiated, keyed off `widget.patientId`);
  `patient_detail_screen.dart`'s previously-private `_patientHistoryProvider` was made public
  (`patientHistoryProvider`) so the screening screen can reach it. A broader "audit all
  buttons and communication" pass (background agent, full `onPressed`/`onTap` grep across
  `lib/`) found no other stub/dead handlers — every other `onPressed: null` site was a real
  loading-state gate, not a stub.
- 2026-08-02: **Admin screening-questions: red-flag toggle + Edit.** Follow-up admin-feature
  audit (web vs. Flutter, cross-checked dio calls against the real Next.js route handlers)
  found both platforms' existing Add/Delete were correctly wired (no stale-list bug there,
  unlike the screening-submit bug above) but flagged one real gap: the mobile add form had no
  way to set `redFlagAtScore` (web's checkbox always sends `4` or `null`) — added, same EN/ID
  copy as web. Then the user asked specifically for **Edit** on existing questions, which
  neither platform had (web: delete+recreate only; Flutter: same) — added on both:
  - **Web:** new `PATCH /api/admin/screening-questions/[id]` (mirrors `POST`'s validation
    exactly — `domainKey` against the 6 real domain keys, required fields, `stage2Options`
    shape, key-uniqueness check excluding the row's own id — `requireAdmin()`-gated,
    audit-logged as `screeningQuestion.updated`). `ScreeningQuestionRow.tsx` gained an inline
    edit mode (same `editing` boolean + Save/Cancel pattern as `PatientRow.tsx`), widened its
    `Question` type to carry `questionId`/`stage2Options`/`redFlagAtScore` (previously only had
    the 4 display fields) — `page.tsx` casts the Prisma row the same `as unknown as X` way
    `mergeCustomQuestions()`'s callers already do for the same JSON-field-typing reason.
    Verified against the local dev DB via curl, not just `tsc --noEmit`: created a real test
    question, PATCHed every field including flipping the red-flag, confirmed the change
    persisted on a fresh GET, confirmed a non-admin session gets 403, cleaned up the test row.
  - **Flutter:** `_AddQuestionScreen` generalized into `_QuestionFormScreen(existing:)` —
    prefills from an optional existing `ScreeningQuestion` and PATCHes instead of POSTs when
    editing; the `ScreeningQuestion` model gained `questionId`/`stage2Options`/`redFlagAtScore`
    fields (previously only carried the 4 list-display fields) so the form has something to
    prefill from. An edit icon button per row opens the form pre-filled.
  `flutter analyze` clean (same 2 pre-existing `RadioListTile` infos), web `tsc --noEmit`/
  `npm run lint` clean. Deployed to production (`vercel deploy --prod`).
- 2026-08-02: **Dynamic severity-options list, for the built-in-question migration.** The
  admin edit form's severity section was a hardcoded 4-slot 1-4 scale — fine for admin-added
  questions (always created that way) but broke the moment the 28 built-in CDSS symptoms
  moved into the same editable table (see `HIV-Project-Web/CLAUDE.md`'s matching entry): one
  of them, "seizures/decreased consciousness", only has 2 severity options (scores 3-4), and
  the old fixed-4 form's `stage2Options.firstWhere((o) => o.score == i + 1)` prefill logic
  threw (`StateError`, no element) the instant that question's edit screen opened. Replaced
  with a dynamic `_OptionRow` list (add/remove buttons, each row's score/labelEn/labelId all
  independently editable) in `screening_questions_screen.dart`'s `_QuestionFormScreen` —
  `stage2Options` prefills directly from whatever the existing question actually has, no
  assumed score sequence. The red-flag switch now derives `redFlagAtScore` from the option
  set's actual max score (`_maxOptionScore()`) instead of hardcoding `4`. Also fixed a small
  pre-existing bug noticed in the same file: the "Domain is required" validation message was
  a raw hardcoded English string with a comment noting no i18n key existed for it — one
  already did (`domainRequired`, unused until now), swapped in.
  Added `test/screening_questions_edit_test.dart`'s second case specifically reproducing the
  seizures shape (2 options, scores 3-4, non-sequential) against the *new* dynamic form —
  confirms no exception on open, exactly 2 rows render (no fabricated score-1/2 entries), and
  saving preserves the original 2 options untouched. `flutter analyze` clean, both tests in
  that file pass.
- 2026-08-02: **Removed Provider's on-behalf-of screening flow — patient-self-screening only
  now**, matching the same restriction added on the web backend the same day (see
  `HIV-Project-Web/CLAUDE.md`'s matching entry — `POST /api/screening` now 403s for any
  non-PATIENT session, which is the actual enforcement this app already relies on). Removed
  the "New Screening" card from `ProviderHomeScreen` (the only launch site for this flow —
  Admin never had one in the mobile app to begin with, unlike web), deleted the now-unreachable
  `ScreeningPatientPickerScreen` entirely, and stripped `NewScreeningScreen`'s optional
  `patientId`/`patientName` params (its one remaining call site,
  `patient_shell.dart`'s `/screening` tab, never supplied them anyway). Provider still views a
  patient's screening history read-only from their detail page (`patientHistoryProvider`
  untouched) — only *conducting* a new screening was removed. `flutter analyze` and the full
  test suite (`flutter test`) clean.
- 2026-08-02: **Search + pagination on admin Screening Questions.** Now that all 28 built-in
  symptoms plus any custom ones live in one editable list (see the migration entry above), a
  flat scroll was getting long. Added a `TextField` filtering by question text (EN/ID), key, or
  domain (client-side, same `_query`/`.where()` pattern as Admin Users and the patient pickers
  elsewhere in this app — no new endpoint), and simple 10-per-page pagination
  (Previous/"Page X of Y"/Next, `AppStrings.pageOf()` new locale-aware helper) — hidden
  entirely when everything already fits one page; searching resets to page 1. `ScreeningQuestionsScreen`
  went from `ConsumerWidget` to `ConsumerStatefulWidget` to hold the query/page state. Also
  fixed a small pre-existing bug noticed while touching the empty state: a `noScreeningQuestionsYet`
  i18n key already existed but was unused, with a stale comment claiming no key covered it —
  wired in.
  Hit a real Flutter-test gotcha writing the regression test (15-question fixture, forces a
  genuine second page): `ListView` slivers only mount elements within the viewport+cache
  extent regardless of `children:` vs `.builder` — the default 800x600 test surface silently
  truncated the list well before the assertions, with no error, just missing widgets. Not an
  offstage issue (`skipOffstage: false` didn't help, unlike the earlier edit-form test) — the
  later items and the pagination row genuinely aren't built yet. Fixed by enlarging the test
  viewport (`tester.view.physicalSize`) so a full page fits without scrolling, since the
  pagination *logic* was what needed verifying, not scroll behavior. `flutter analyze` and the
  full test suite clean.
- 2026-08-03: **Fixed the Add FAB covering the pagination controls, same screen.** Real bug
  from the feature above: the pagination Row was the last item inside the scrollable
  `ListView`, which put it in the same bottom-right screen region the floating Add button
  always occupies — could visually sit on top of Next. Moved pagination into the `Scaffold`'s
  `bottomNavigationBar` slot instead of the list content; Flutter automatically reserves space
  and lifts the FAB above whatever's in that slot, so the overlap is now structurally
  impossible rather than avoided by luck. Also swapped the text Previous/Next buttons for
  filled-tonal icon buttons (chevron_left/right + tooltip), added a search-icon prefix to the
  search field, and gave the list extra bottom padding so the last card can't end up under the
  FAB either. Updated the pagination test for the new control type — `IconButton`'s `Tooltip`
  is an internal *descendant*, not an ancestor, so the finder needed
  `find.ancestor(of: find.byTooltip(...), matching: find.byType(IconButton))`, the reverse of
  the first (wrong) attempt. `flutter analyze` and the full test suite clean.
- 2026-08-04: **Real FCM push notification for consultation chat — Android only this pass.**
  Firebase project created (console walkthrough, project id `medi-care-hiv`), Android app
  registered (package `com.medicarehiv.hiv_project_app`), `google-services.json` dropped into
  `android/app/`. Added `firebase_core`/`firebase_messaging` to `pubspec.yaml`, the
  `com.google.gms.google-services` Gradle plugin to `android/settings.gradle.kts` +
  `android/app/build.gradle.kts`. New `lib/core/push_notifications.dart` (same static-class
  shape as `local_notifications.dart`): `init()` calls `Firebase.initializeApp()` + requests
  notification permission, `FirebaseMessaging.onMessage` hands foreground messages to
  `LocalNotifications.showNow()` (new method — FCM doesn't auto-banner in the foreground on
  Android, so it reuses the existing local-notification plugin instance rather than standing
  up a second display pipeline), `onMessageOpenedApp`/`getInitialMessage` handle a
  background/cold-start tap. Token lifecycle: `AuthController.login()` calls
  `PushNotifications.registerCurrentToken()` right after saving the session token,
  `logout()` calls `unregisterCurrentToken()` *before* clearing it (needs the still-valid
  Bearer token to authenticate the unregister call) — both wrapped in try/catch, a network
  blip must never block an actual login/logout.
  Real gap found while wiring this: `ConsultationThreadScreen` had no `go_router` path at
  all, only reachable via imperative `Navigator.push` from inside the inbox/chat screens — a
  cold-started notification tap had nowhere to route into. Added a top-level
  `GoRoute(path: '/consultations/:id', ...)` in `router.dart` (outside the per-role shells,
  since it's reached by id regardless of active role) plus a module-level `rootNavigatorKey`
  (survives the router being torn down/recreated on every auth/locale change) so
  `push_notifications.dart`'s tap handler can call `context.go(...)` from outside the widget
  tree.
  Two real build/verification issues, unrelated to the Firebase work itself, surfaced because
  this was the **first real Android build this app has ever had** (Android SDK is now present
  on this machine — the "no Android SDK" note elsewhere in this file's history no longer
  holds): (1) `flutter_local_notifications` needs Android core library desugaring enabled,
  fixed with the standard `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs`
  dependency in `android/app/build.gradle.kts`; (2) `flutter analyze` picked up ~170 unrelated
  errors from `firebase_messaging`'s own bundled test suite, copied into
  `build/*/SourcePackages/` by Xcode's Swift Package Manager cache — added an
  `analyzer: exclude: [build/**]` block to `analysis_options.yaml` (default exclusion wasn't
  reaching this nested path).
  Verified live end-to-end on a real Android emulator (Pixel 9, driven via `adb shell input`
  — UI automation works fine here, unlike the iOS Simulator's host-IDE-overlay-interception
  problem noted elsewhere in this file, since ADB injects touch events at the OS level):
  logged in as a real patient, backgrounded the app, sent a message from the provider side via
  curl — a real system notification appeared (title "Dr. Provider", body matching the sent
  content exactly) with the app's actual FCM token round-tripped through the real backend.
  First tap attempt landed on the notification's collapse chevron and just reopened the app to
  its home tab with no deep-link — added temporary debug logging (`onMessageOpenedApp`
  fired?, `_handleTap`'s data, `context` non-null?) to confirm this was a mis-tap and not a
  real bug; a second precisely-placed tap confirmed the full chain — `onMessageOpenedApp`
  fired with `{type: consultation_message, consultationId: 12}`, `context.go()` was called,
  and the app landed on the exact right thread showing both real messages. Debug logging
  removed after confirming. `flutter analyze` clean (same 2 pre-existing `RadioListTile`
  infos). Test patient/consultation/device-token rows cleaned up from the local dev DB
  afterward.
  **iOS explicitly out of scope this pass** — `firebase_core`/`firebase_messaging` are
  already cross-platform in `pubspec.yaml`, but no iOS-native config (Firebase console app
  registration, `GoogleService-Info.plist`, Push Notifications capability, `UIBackgroundModes`
  entitlement, deployment-target bump from 13.0) has been done; real push also can't be
  fully verified on iOS Simulator regardless (no real APNs — only `xcrun simctl push`'s local
  simulation), so full iOS verification additionally needs a real device on a paid Apple
  Developer account. See `HIV-Project-Web/CLAUDE.md`'s matching entry for the backend half.
- 2026-08-04: **iOS push notification follow-up — native config wired, local-simulation
  verified.** Registered a second Firebase app (iOS, bundle `com.medicarehiv.hivProjectApp`,
  same `medi-care-hiv` project as Android) and added `GoogleService-Info.plist` to
  `ios/Runner/` — required manually wiring it into the Xcode project's `PBXBuildFile`/
  `PBXFileReference`/`PBXGroup`/`PBXResourcesBuildPhase` entries by hand (no Xcode GUI
  available in this environment), since a loose file in the folder isn't actually bundled
  into the app without that. Bumped `IPHONEOS_DEPLOYMENT_TARGET` 13.0→15.0 (all 3 build
  configs), added `Runner/Runner.entitlements` (`aps-environment: development`, wired via
  `CODE_SIGN_ENTITLEMENTS`) and `UIBackgroundModes: [remote-notification]` to `Info.plist`.
  First real iOS build for this app pulled Firebase via Swift Package Manager automatically
  (no `Podfile`/CocoaPods needed — modern Flutter iOS template default) — `flutter run` on a
  real iPhone 17 Simulator succeeded, app launched clean with zero crash (confirms
  `Firebase.initializeApp()` found valid config this time, unlike the very first attempt with
  no plist at all, which would have crashed immediately).
  **Real, hard environment constraint hit and worked through, not around:** iOS Simulator has
  no scriptable way to grant or reset notification permission — tried `xcrun simctl privacy
  grant notifications` (not a valid privacy service; only camera/contacts/location/etc. are),
  `xcrun simctl privacy reset all` (silently doesn't cover notification authorization either —
  confirmed empirically, app uninstall/reinstall doesn't re-prompt once decided, exactly
  matching real iOS device behavior where the OS remembers the decision independent of the
  app's own data), and `osascript`/System Events UI automation (two different failure modes:
  accessibility-tree element lookup fails since Simulator renders as one opaque surface to
  macOS Accessibility — same root cause as this file's existing "UI automation not reliably
  available" note — and a raw coordinate click failed separately with `-25211 osascript is
  not allowed assistive access`, meaning the CLI process itself has no Accessibility
  permission grantable without its own manual System Settings toggle). Net result: this class
  of interaction is not scriptable from this environment by any means tried, full stop — not
  a timing issue, an actual capability gap. Resolved by asking the user to grant the
  permission via Settings → Medi-Care HIV → Notifications directly (skips the transient
  system dialog entirely, which is also too short-lived to reliably catch turn-by-turn in a
  chat interface) and separately confirm the tap-to-deep-link result by eye, since a
  system-initiated cold-launch (from a fully-terminated state, via notification tap) doesn't
  reliably reattach `flutter run`'s own debug session — its `debugPrint` log capture is a
  real blind spot for exactly this scenario, discovered when a genuinely successful tap
  (user-confirmed: opened straight to "Konsultasi Langsung") left zero trace in the log
  despite the same debug-logging approach working perfectly on Android moments earlier in
  the same session. `xrun simctl push` itself (the actual mechanism being verified) worked
  correctly throughout — confirmed via a real payload (`type: consultation_message,
  consultationId: 999`) producing a banner with the exact title/body sent, and a
  user-confirmed tap landing on the exact right thread screen. Debug logging removed after.
  `flutter analyze` clean (same 2 pre-existing infos). `Package.resolved` (both the
  `.xcodeproj` and `.xcworkspace` copies SPM generates) committed alongside, same reasoning
  as `pubspec.lock`/`package-lock.json` — pins exact resolved SDK versions for reproducible
  builds. Still not done for real production iOS use: no Apple Developer Program enrollment,
  no real-device verification, `_registerToken()` still hardcodes `'platform': 'android'`
  (harmless for this local-simulation pass since no login/registration flow was exercised
  against a real backend on iOS this round, but would need a `Platform.isIOS` branch before
  iOS push is ever wired to the real backend send path).
