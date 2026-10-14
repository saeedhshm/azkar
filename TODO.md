# Remediation Roadmap

> **Status: complete.** All 12 tasks are implemented, with 204 tests passing and
> `flutter analyze` reporting no errors or warnings. The details below remain
> as the original task specification.

This file is a prioritized implementation backlog. Each task is written as a
standalone prompt that can be assigned to an AI agent. Keep changes scoped to
the task, add focused regression tests, and run `flutter analyze` and the
relevant `flutter test` targets before completing a task.

## Phase 1: Prayer-Time Correctness

### P0. Stop the post-Isha reload loop

**Files:** `lib/features/prayer_times/presentation/cubit/prayer_times_cubit.dart`

**Prompt for agent:**

> Fix the prayer-time ticker so it does not reload prayer data once per second
> between Isha and midnight. The next prayer after Isha is tomorrow's Fajr, so
> comparing `now.day` with `nextPrayerTime.day` is not a valid day-boundary
> check. Recalculate exactly when the next prayer is reached and once after an
> actual calendar-date transition. Avoid overlapping `_loadForCoordinates`
> calls while a reload is in progress. Preserve the countdown behavior and add
> deterministic tests covering Isha-to-Fajr, midnight, and an ordinary next
> prayer.

**Acceptance criteria:**

- No repeated reload, notification scheduling, or widget updates before
  midnight after Isha.
- Tomorrow's Fajr remains the displayed next prayer after Isha.
- A new day's timetable is calculated after the date changes.
- Tests prove the ticker behavior without relying on wall-clock time.

### P0. Make prayer notifications date-accurate and dismissible

**Files:** `lib/core/notifications/notification_service.dart`, relevant native
background scheduling code if needed

**Prompt for agent:**

> Replace repeating daily prayer notifications with a design that respects
> prayer times changing from day to day. Schedule each notification for its
> concrete next occurrence without `DateTimeComponents.time`, and ensure the
> next day's times are recalculated and scheduled reliably. Use an existing
> background mechanism only if it can execute reliably on supported platforms;
> otherwise document the platform limitation and refresh on every app launch
> and date rollover. Make normal prayer alerts dismissible rather than
> permanent notifications, unless an explicitly separate persistent mode is
> introduced. Preserve custom sounds and existing notification IDs.

**Acceptance criteria:**

- Tomorrow's notification uses tomorrow's calculated time, not today's clock
  time.
- Existing pending notifications are safely replaced when schedules change.
- Prayer alerts can be dismissed.
- Unit tests verify dates, passed times, and notification scheduling arguments.

### P1. Apply calculation settings immediately

**Files:** `lib/features/settings/presentation/pages/settings_screen.dart`,
`lib/features/prayer_times/presentation/cubit/prayer_times_cubit.dart`

**Prompt for agent:**

> Route prayer-calculation setting changes through `PrayerTimesCubit` instead
> of saving directly through `PrayerSettingsProvider`. Ensure the selected
> calculation method, madhab, and offsets recalculate visible prayer times,
> home-widget data, and pending notifications immediately. Do not duplicate
> persistence logic between the settings screen and cubit.

**Acceptance criteria:**

- Changing any calculation setting refreshes all dependent outputs once.
- Settings persist after restart.
- Add a cubit test for recalculation after updating settings.

### P1. Validate manually entered coordinates

**Files:** `lib/features/prayer_times/presentation/pages/prayer_times_tab.dart`,
optionally `lib/features/prayer_times/presentation/cubit/prayer_times_cubit.dart`

**Prompt for agent:**

> Validate manual latitude and longitude before persisting or calculating
> prayer times. Reject latitude outside [-90, 90] and longitude outside
> [-180, 180], show a localized actionable validation message, and retain the
> user's entered values for correction. Add defensive validation in the cubit
> if other callers can bypass the form.

**Acceptance criteria:**

- Invalid coordinates are neither saved nor used for calculations.
- Boundary values are accepted.
- Widget tests or unit tests cover invalid and valid values.

## Phase 2: Startup and Audio Reliability

### P0. Remove the global Quran-download startup gate

**Files:** `lib/app.dart`,
`lib/features/quran/data/datasources/quran_page_image_cache_service.dart`, Quran
reader loading UI

**Prompt for agent:**

> Make the application usable immediately without first downloading all 604
> Quran SVG pages. Start the normal router after essential local initialization,
> then download Quran pages lazily when read or optionally in a cancellable
> background process. Add bounded HTTP timeouts and retryable error states.
> Preserve offline access to pages already cached and do not delete a valid
> cache because a background download failed.

**Acceptance criteria:**

- The home screen opens offline on a fresh install.
- Opening an uncached Quran page shows a clear loading/error/retry state.
- Every remote request has a finite timeout.
- Cached pages remain readable offline.
- Tests cover timeout, partial cache, and first-run behavior.

### P0. Fix disposed singleton audio player reuse

**Files:** `lib/core/di/service_locator.dart`,
`lib/features/quran/audio/presentation/cubit/quran_audio_cubit.dart`, audio tests

**Prompt for agent:**

> Fix the lifecycle mismatch where `QuranAudioPlayerService` is registered as a
> lazy singleton but disposed by every `QuranAudioCubit`. Choose one coherent
> ownership model: either make the service cubit-scoped/factory-created and
> dispose it with the cubit, or retain it as an application singleton and do
> not dispose it from the cubit. Verify that opening, closing, and reopening
> the Quran reader can load and play audio each time without leaked listeners.

**Acceptance criteria:**

- Reopening the reader uses a live player service.
- Service disposal occurs exactly once under the selected ownership model.
- Regression test creates two sequential cubits/readers and verifies playback
  initialization in both.

## Phase 3: Quran Reader and Tafsir

### P1. Repair Tafsir retry context

**Files:** `lib/features/quran/tafsir/presentation/widgets/tafsir_reader_sheet.dart`

**Prompt for agent:**

> Fix the Tafsir error retry action. It currently requests source `''`, surah
> 0, and ayah 0. Pass the current sheet's surah number, ayah number, and the
> selected source ID into the retry UI. Keep source selection state consistent
> across loading, error, and retry states.

**Acceptance criteria:**

- Retry requests the displayed ayah and selected source.
- A failed remote request can succeed on retry.
- Add a widget or cubit interaction test validating request arguments.

### P1. Make double-tap zoom actually animate

**Files:** `lib/features/quran/presentation/widgets/quran_mushaf_image_page.dart`

**Prompt for agent:**

> Repair double-tap zoom in the Mushaf page. The animation changes
> `_currentScale`, but the UI and `PhotoViewController` never receive the
> updated scale. Drive `PhotoViewController.scale` during animation or rebuild
> safely with the animated scale. Preserve panning, pinch zoom, reset-on-page
> change, and single-tap ayah selection behavior.

**Acceptance criteria:**

- Double tap visibly zooms in and a subsequent double tap resets the zoom.
- Single-tap selection is not accidentally triggered by a double tap.
- Page changes reset scale and position.

### P1. Restore system UI when leaving Quran reader

**Files:** `lib/features/quran/presentation/pages/quran_reader_screen.dart`

**Prompt for agent:**

> Ensure the Quran reader always restores edge-to-edge system UI and the
> appropriate overlay style when it is disposed, including navigation away
> while reading mode or fullscreen mode is active. Do not call `setState` from
> disposal. Keep existing explicit mode-toggle behavior intact.

**Acceptance criteria:**

- Leaving the reader from fullscreen restores system bars for the next route.
- Leaving while reading mode is active also restores system bars.
- Add a widget-level lifecycle test where practical.

### P2. Deserialize recently read entries from Hive safely

**Files:** `lib/features/quran/data/datasources/quran_recently_read_service.dart`

**Prompt for agent:**

> Make recently-read deserialization accept Hive's `Map<dynamic, dynamic>`
> values by converting valid maps to `Map<String, dynamic>` before parsing.
> Treat malformed stored entries as ignorable rather than crashing the reader.
> Preserve ordering and the 20-entry limit.

**Acceptance criteria:**

- Entries survive an actual storage round trip.
- Dynamically typed maps are read correctly.
- Corrupt entries do not prevent valid entries from loading.
- Add regression tests for all three cases.

## Phase 4: Shared Settings and Hardening

### P1. Use one source of truth for time format

**Files:** `lib/features/settings/presentation/cubit/time_format_cubit.dart`,
`lib/features/prayer_times/data/services/prayer_settings_provider.dart`,
`lib/core/storage/local_storage_service.dart`

**Prompt for agent:**

> Unify 12/24-hour-format persistence. The settings cubit writes through
> `LocalStorageService`, while the prayer widget reads the unrelated
> SharedPreferences key `use_24_hour_format`. Remove the split source of truth
> and make widget updates consume the same persisted setting as the UI. Include
> a one-time migration only if released users already have the old key.

**Acceptance criteria:**

- Changing the setting updates app UI and the next widget refresh.
- The selected format persists after restart.
- Tests verify both components read the same saved value.

### P2. Bound all Quran network requests

**Files:** `lib/features/quran/data/datasources/quran_page_image_cache_service.dart`,
`lib/features/quran/services/quran_polygon_file_cache_service.dart`, and other
Quran remote data sources

**Prompt for agent:**

> Audit Quran-related HTTP calls and apply a consistent finite timeout, clear
> domain-specific error, and retry path where user-facing. Close owned HTTP
> clients if their lifecycle permits it. Do not swallow failed downloads as
> successful cache hits.

**Acceptance criteria:**

- A stalled request fails within the configured timeout.
- UI presents a retryable state rather than hanging indefinitely.
- Tests simulate timeout and non-200 responses.

## Final Verification

**Prompt for agent:**

> Run the full test suite and static analysis after all tasks are integrated.
> Add tests for every regression fixed above, review all notification and
> startup behavior on Android and iOS where platform APIs differ, and document
> any background-execution limitations in the README or developer docs.

**Required commands:**

```sh
flutter analyze
flutter test
```
