# Azkar App — Complete Documentation

> A comprehensive Islamic companion app built with Flutter featuring daily Adhkar, Quran reader with interactive Mushaf, prayer times with Qibla compass, Tasbeeh counter, and full localization support.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Project Structure](#3-project-structure)
4. [Entry Point & Initialization](#4-entry-point--initialization)
5. [Dependency Injection](#5-dependency-injection)
6. [Routing](#6-routing)
7. [Theme System](#7-theme-system)
8. [Localization](#8-localization)
9. [Storage System](#9-storage-system)
10. [Notification System](#10-notification-system)
11. [Features](#11-features)
    - [11.1 Adhkar](#111-adhkar)
    - [11.2 Quran](#112-quran)
    - [11.3 Prayer Times](#113-prayer-times)
    - [11.4 Tasbeeh](#114-tasbeeh)
    - [11.5 Settings](#115-settings)
    - [11.6 Navigation](#116-navigation)
12. [Shared Widgets](#12-shared-widgets)
13. [Utilities](#13-utilities)
14. [Assets & Data](#14-assets--data)
15. [Third-Party Packages](#15-third-party-packages)
16. [Testing](#16-testing)
17. [Build & Run](#17-build--run)

---

## 1. Overview

**Azkar** is a full-featured Islamic companion app designed for daily spiritual practice. It provides:

- **Daily Adhkar**: 1500+ authenticated supplications organized into 20 categories across 5 sections (Daily, Prayer, General, Quran, Life Situations)
- **Quran Reader**: Interactive SVG-based Mushaf with 604 pages, ayah tap detection, bookmarks, search, audio playback from 5 reciters, and tafsir
- **Prayer Times**: Accurate prayer calculations using the Adhan package with GPS/manual location, 12 calculation methods, 2 madhabs, Qibla compass, and Hijri dates
- **Tasbeeh Counter**: Beautiful animated counter with preset phrases and session tracking
- **Settings**: Theme switching, language selection, notification scheduling, prayer calculation configuration
- **Home Widget**: Native iOS/Android widget showing next prayer time and countdown

**Supported Languages**: English, Arabic, Turkish, Indonesian

**Platforms**: Android, iOS (with potential for Web/Desktop)

---

## 2. Architecture

### 2.1 Pattern: Clean Architecture + Cubit State Management + Service Locator DI

The app follows **Clean Architecture** principles with three distinct layers per feature:

```
Feature/
├── domain/           # Business logic (pure Dart, no Flutter dependencies)
│   ├── entities/     # Plain Dart classes representing business objects
│   ├── repositories/ # Abstract interfaces defining contracts
│   └── usecases/     # Single-responsibility use case classes
├── data/             # Data handling and external integrations
│   ├── models/       # Data classes extending entities with serialization
│   ├── datasources/  # Local/remote data sources
│   └── repositories/ # Concrete implementations of domain interfaces
└── presentation/     # UI layer
    ├── cubits/       # State management (BLoC pattern simplified)
    ├── pages/        # Full screens
    └── widgets/      # Reusable UI components
```

### 2.2 State Management: Cubits (flutter_bloc)

- Uses **Cubits** (not full BLoCs) — no event classes, just methods that emit states
- States are **Equatable** for efficient rebuild comparison
- Each feature has its own Cubit(s) managed via `BlocProvider`
- Global Cubits (`ThemeCubit`, `TimeFormatCubit`) provided at app level via `MultiBlocProvider`

### 2.3 Dependency Injection: GetIt Service Locator

- Single `setupLocator()` function registers all dependencies
- Three registration types:
  - **Singleton**: Created once at startup (services, data sources)
  - **LazySingleton**: Created on first use (repositories, use cases)
  - **Factory**: New instance each time (all Cubits)

### 2.4 Routing: go_router

- Declarative route definitions with path parameters
- Deep linking support
- Navigation handled via `context.push()` and `context.pop()`

---

## 3. Project Structure

```
azkar/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp configuration & initialization gate
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart   # All app-wide constants & keys
│   │   ├── di/
│   │   │   └── service_locator.dart # GetIt DI setup
│   │   ├── notifications/
│   │   │   └── notification_service.dart # Notification scheduling
│   │   ├── routing/
│   │   │   └── app_router.dart      # go_router route definitions
│   │   ├── storage/
│   │   │   └── local_storage_service.dart # Hive-based storage
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # Light/dark theme definitions
│   │   │   ├── app_theme_colors.dart # Custom color extension
│   │   │   ├── app_radius.dart      # Border radius constants
│   │   │   └── app_spacing.dart     # Spacing constants
│   │   ├── utils/
│   │   │   ├── locale_resolver.dart # Smart locale detection
│   │   │   ├── time_formatter.dart  # Time formatting utilities
│   │   │   ├── time_of_day_converter.dart # Time serialization
│   │   │   └── app_categories.dart  # Adhkar category definitions
│   │   └── widgets/
│   │       ├── app_loading.dart     # Shimmer loading skeletons
│   │       ├── app_scaffold.dart    # Gradient background
│   │       ├── app_badge.dart       # Label badges
│   │       ├── app_bottom_sheet.dart # Unified bottom sheets
│   │       ├── app_glass_card.dart  # Glass-morphism cards
│   │       ├── app_hero_card.dart   # Premium gradient cards
│   │       ├── app_glow_button.dart # Glowing action buttons
│   │       └── prayer_widget_service.dart # Home widget updater
│   └── features/
│       ├── adhkar/                  # Adhkar feature
│       ├── quran/                   # Quran feature (largest)
│       ├── prayer_times/            # Prayer times & Qibla
│       ├── tasbeeh/                 # Tasbeeh counter
│       ├── settings/                # Settings screen
│       └── navigation/              # Main navigation shell
├── assets/
│   ├── data/
│   │   ├── adhkar_1500.json         # 1500+ adhkar entries
│   │   ├── quran_uthmani.json       # Full Quran text
│   │   ├── cities_min.json.gz       # Compressed city database
│   │   └── timings/                 # Recitation timing data
│   ├── translations/
│   │   ├── en.json                  # English
│   │   ├── ar.json                  # Arabic
│   │   ├── tr.json                  # Turkish
│   │   └── id.json                  # Indonesian
│   ├── fonts/                       # Cairo font family
│   └── icons/                       # App launcher icon
├── test/                            # Unit & widget tests
├── tool/                            # Build utilities
├── android/                         # Android platform code
├── ios/                             # iOS platform code
└── pubspec.yaml                     # Dependencies & assets config
```

---

## 4. Entry Point & Initialization

### 4.1 `main.dart` — Startup Sequence

```
1. WidgetsFlutterBinding.ensureInitialized()
2. EasyLocalization.ensureInitialized()
3. HomeWidget.setAppGroupId('group.com.example.azkar')  // iOS widget sharing
4. setupLocator()                                       // Initialize DI
5. Resolve initial locale via LocaleResolver:
   - Check saved locale in SharedPreferences
   - Detect device country (26 Arabic countries → ar, TR → tr, ID → id)
   - Fallback to English
6. Wrap app in EasyLocalization with supported locales: en, ar, tr, id
```

### 4.2 `app.dart` — Initialization Gate

Before showing the main app, all **604 Quran SVG pages** are downloaded and cached:

- Shows `QuranInitialDownloadScreen` with circular progress indicator
- Uses `QuranPageImageCacheService` to download from GitHub
- Cache version tracking (v3) for invalidation
- Legacy JPG cleanup on first run
- Only after completion does the app transition to `MaterialApp.router`

**Global Providers**:
- `ThemeCubit`: Manages light/dark/system theme
- `TimeFormatCubit`: Manages 12h/24h time format

---

## 5. Dependency Injection

### Registration Types

| Type | When Created | Examples |
|------|-------------|----------|
| Singleton | At startup | `LocalStorageService`, `NotificationService`, `QuranLocalDataSource`, `PrayerSettingsProvider` |
| LazySingleton | On first access | All repositories, use cases, data sources, services, caches, search index |
| Factory | Each time requested | All Cubits (ThemeCubit, AdhkarCubit, QuranCubit, etc.) |

### Key Services Registered

- **Storage**: `LocalStorageService` (Hive), `PrayerSettingsProvider` (SharedPreferences)
- **Quran**: `QuranSvgPageService`, `QuranSvgMemoryCache`, `QuranPageImageCacheService`, `QuranPolygonHitTestEngine`, `QuranSearchIndex`
- **Audio**: `QuranAudioPlayerService` (just_audio wrapper), `RecitationTimingDataSource`
- **Tafsir**: `TafsirRemoteDataSource`, `TafsirLocalDataSource`, `TafsirRepository`, `GetTafsirUseCase`
- **Prayer**: `PrayerService` (adhan package), `LocationService` (geolocator), `CityDatabaseService`, `NetworkService`
- **Notifications**: `NotificationService` (flutter_local_notifications)

---

## 6. Routing

| Route | Screen | Parameters |
|-------|--------|------------|
| `/` | `MainNavigationScreen` | — |
| `/quran` | `QuranReaderScreen` | `?page=<int>` |
| `/adhkar/:category` | `AdhkarListScreen` | `category` (path param) |
| `/reader/:category` | `DhikrReaderScreen` | `category`, `?index=<int>`, `?id=<int>` |
| `/tasbeeh` | `TasbeehCounterScreen` | — |
| `/favorites` | `FavoritesScreen` | — |
| `/settings` | `SettingsScreen` | — |

---

## 7. Theme System

### 7.1 Color Palette

**Light Theme**:
| Token | Color | Usage |
|-------|-------|-------|
| Background | `#F5F0E6` | Warm cream app background |
| Surface | `#FFFFFF` | Card surfaces |
| Primary | `#4A5D23` | Olive green — buttons, accents |
| Primary Container | `#D4DBC4` | Light green backgrounds |
| Secondary | `#5D4E37` | Warm brown — secondary text |
| Accent | `#D4AF37` | Gold — highlights, icons |
| Countdown | `#B8860B` | Prayer countdown text |

**Dark Theme**:
| Token | Color | Usage |
|-------|-------|-------|
| Background | `#1A1F15` | Dark olive app background |
| Surface | `#1A1A1A` | Card surfaces |
| Primary | `#8FBC8F` | Light green — buttons, accents |
| Primary Container | `#2D3B1F` | Dark green backgrounds |
| Secondary | `#D4C4B0` | Warm beige — secondary text |
| Accent | `#DAA520` | Dark gold — highlights |

### 7.2 Custom Theme Extension (`AppThemeColors`)

17 custom colors beyond Material 3:
- `heroCardBackground`, `cardSurface`, `cardSurfaceTint`, `inputSurface`, `navBarBg`, `pillBg`
- `shimmerBase`, `shimmerHighlight`
- `secondaryText`, `mutedText`, `countdownText`
- `softBorder`, `prayerIcon`
- `accentColor`, `successColor`
- `currentPrayerBg`, `currentPrayerFg`
- `cardRadius` (double)

### 7.3 Design Tokens

**Spacing** (`app_spacing.dart`): `xs=4`, `sm=8`, `md=16`, `lg=24`, `xl=32`, `xxl=48`

**Radius** (`app_radius.dart`): `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=20`, `xxl=28`, `pill=100`

**Typography**: Cairo font family (400, 500, 600, 700 weights)

---

## 8. Localization

### 8.1 Supported Languages

| Code | Language | Detection |
|------|----------|-----------|
| `en` | English | Default fallback |
| `ar` | Arabic | 26 Arabic-speaking countries |
| `tr` | Turkish | Device country = TR |
| `id` | Indonesian | Device country = ID |

### 8.2 Locale Resolution Algorithm

1. Check if user previously saved a locale → use it
2. Check device country code:
   - Arabic countries (SA, EG, AE, etc.) → Arabic
   - Turkey → Turkish
   - Indonesia → Indonesian
3. Check device language code → use if supported
4. Fallback → English

### 8.3 Translation Key Structure

```
app.name                          // App name
common.*                          // Shared UI strings (25 keys)
home.sections.*                   // Section titles/subtitles
home.tabs.*                       // Tab labels
home.greetings.*                  // Time-based greetings
categories.*                      // 20 adhkar category titles
reader.*                          // Dhikr reader UI (12 keys)
prayer_times.*                    // Prayer times UI (40+ keys)
settings.*                        // Settings screen (30+ keys)
tasbeeh.*                         // Tasbeeh counter
notifications.*                   // Notification titles/messages
quran.*                           // Quran reader (35+ keys)
favorites.*                       // Favorites screen
```

---

## 9. Storage System

### 9.1 Hive Storage (`LocalStorageService`)

Box name: `adhkar_app_box`

| Key | Type | Purpose |
|-----|------|---------|
| `favorites` | `List<int>` | Favorite adhkar IDs |
| `adhkar_progress` | `Map<String, int>` | Per-adhkar remaining count |
| `tasbeeh_count` | `int` | Current tasbeeh count |
| `theme_mode` | `String` | "light" / "dark" / "system" |
| `locale_code` | `String` | Selected language code |
| `notifications_enabled` | `bool` | Global notification toggle |
| `morning_reminder` | `String` | "HH:mm" format |
| `evening_reminder` | `String` | "HH:mm" format |
| `sleep_reminder` | `String` | "HH:mm" format |
| `waking_reminder` | `String` | "HH:mm" format |
| `friday_reminder` | `String` | "HH:mm" format |
| `time_format_24h` | `bool` | 24-hour vs 12-hour format |
| `quran_pages_cache_version` | `int` | SVG cache version (current: 3) |
| `quran_polygon_cache_version` | `int` | Polygon data cache version |
| `quran_last_page` | `int` | Last read Quran page number |
| `quran_last_ayah_surah` | `int` | Last read ayah surah number |
| `quran_last_ayah_number` | `int` | Last read ayah number |
| `quran_bookmarks` | `List<Map>` | Quran bookmarks (surah, ayah, page) |
| `quran_favorite_reciter` | `String` | Favorite reciter ID |
| `quran_reading_mode` | `bool` | Immersive reading mode toggle |
| `quran_dim_mode` | `bool` | Screen dimming toggle |
| `quran_dim_intensity` | `double` | Dim intensity (0.0–1.0) |
| `quran_continuous_scroll` | `bool` | Continuous scroll mode |
| `quran_scroll_direction` | `String` | "horizontal" / "vertical" |
| `reader_progress_<category>` | `Map` | Per-category reader progress |

### 9.2 SharedPreferences (`PrayerSettingsProvider`)

Stores prayer calculation settings:
- Calculation method (12 methods)
- Madhab (Shafi/Hanafi)
- Prayer time offsets (per prayer)
- Location settings (use device GPS vs manual)
- Manual latitude/longitude
- Custom adhan sound preference

---

## 10. Notification System

### 10.1 Setup

- Uses `flutter_local_notifications` + `timezone` package
- Initializes timezone from device via `flutter_timezone`
- Requests permissions:
  - Android: notifications + exact alarms
  - iOS: alerts + badges + sound

### 10.2 Adhkar Reminders (Scheduled Daily/Weekly)

| ID | Name | Default Time | Frequency |
|----|------|-------------|-----------|
| 1001 | Morning | 06:00 | Daily |
| 1002 | Evening | 18:00 | Daily |
| 1003 | Sleep | 22:00 | Daily |
| 1004 | Waking | 07:00 | Daily |
| 1005 | Friday | 10:00 | Weekly (Friday) |

### 10.3 Prayer Time Notifications

| ID | Prayer |
|----|--------|
| 2001 | Fajr |
| 2002 | Dhuhr |
| 2003 | Asr |
| 2004 | Maghrib |
| 2005 | Isha |

- Uses `AndroidScheduleMode.exactAllowWhileIdle`
- Supports custom adhan sound (Android raw resource)

---

## 11. Features

### 11.1 Adhkar

#### Data Layer
- **Source**: `assets/data/adhkar_1500.json` (~1500 entries)
- **`AdhkarLocalDataSource`**: Loads JSON, caches in memory, flattens nested category structure
- **`AdhkarModel`**: Extends `Adhkar` entity with `fromJson`/`toJson`
- **`AdhkarRepositoryImpl`**: Combines local data source + `LocalStorageService` for favorites/progress

#### Domain Layer
- **`Adhkar` entity**: `id`, `category`, `text`, `count`, `reference`, `description`, `audioPath`
- **`ReaderProgress` entity**: `index`, `remainingCount`
- **`AdhkarRepository` interface**: 9 methods (getAll, getByCategory, search, favorites, progress, reader progress)
- **UseCases**: `GetAdhkarByCategoryUseCase`, `SearchAdhkarUseCase`

#### Presentation Layer

**Cubits**:
- **`AdhkarCubit`**: `loadCategory()`, `search()`, `toggleFavorite()`, `resetProgress()`
- **`FavoritesCubit`**: `loadFavorites()`, `toggleFavorite()`
- **`ReaderCubit`**: `initialize()`, `decrementCounter()`, `next()`, `previous()`, `toggleFavorite()` — includes haptic feedback and auto-advance

**Screens**:

| Screen | Description |
|--------|-------------|
| `HomeScreen` | App bar with time-based greeting, shortcuts to favorites/tasbeeh, embeds `PrayerTimesTab` |
| `AdhkarCategoriesScreen` | 5 sections (Daily/Prayer/General/Quran/Life) with grid layout, shimmer loading, category counts |
| `AdhkarListScreen` | Searchable list with progress bars, favorite toggles, reset progress button |
| `DhikrReaderScreen` | Full-screen reader with glass card, glow button counter, bounce animation, progress bar, prev/next navigation, copy/share actions |
| `FavoritesScreen` | Dismissible tiles, category labels, navigation to reader |

**Widgets**: `CategoryCard` (gradient cards with icons), `AdhkarTile` (list items with progress)

#### Category Structure

| Section | Categories |
|---------|-----------|
| **Daily** | Morning Adhkar, Evening Adhkar, Sleep Adhkar, Waking Up |
| **Prayer** | After Prayer, After Wudu, After Adhan |
| **General** | Tasbeeh, Istighfar, Salawat on Prophet |
| **Quran** | Duas from Quran |
| **Life** | Entering Home, Leaving Home, Entering Mosque, Leaving Mosque, Travel, Rain, Illness, Distress, Gratitude |

---

### 11.2 Quran

The most complex feature — a full interactive Mushaf reader.

#### Data Layer

| Component | Purpose |
|-----------|---------|
| `QuranLocalDataSource` | Loads `quran_uthmani.json` (114 surahs, 6236 ayahs) |
| `QuranPageImageCacheService` | Downloads 604 SVG pages from GitHub, caches to documents, version-based invalidation (v3), legacy JPG cleanup |
| `QuranPolygonLocalDataSource` | Loads ayah polygon data for tap interaction |
| `QuranSearchIndex` | In-memory search index for Quran text |
| `QuranRecentlyReadService` | Tracks recently read entries |
| `QuranRepositoryImpl` | Main repository combining all data sources |
| `QuranBookmarkRepositoryImpl` | Bookmark CRUD operations |
| `QuranLastReadRepositoryImpl` | Last read position tracking |

#### Audio Sub-feature

| Component | Purpose |
|-----------|---------|
| `QuranAudioPlayerService` | just_audio wrapper for streaming |
| `RecitationTimingDataSource` | Ayah-level timing data |
| `RecitationRepositoryImpl` | Reciter + timing data management |
| `Reciter` entity | 5 default reciters from `cdn.islamic.network` |
| `SurahTiming` / `AyahTiming` | Timing entities for sync |
| `QuranAudioCubit` | playSurah, resume, pause, stop, seekToAyah, seekToPosition, setReciter, favorite management, ayah tracking via 100ms timer |

**Available Reciters**:
1. Abdul Rahman Al-Sudais
2. Mishary Rashid Alafasy
3. Maher Al-Muaiqly
4. Abdul Basit Abdul Samad
5. Mahmoud Khalil Al-Husary

#### Tafsir Sub-feature

| Component | Purpose |
|-----------|---------|
| `TafsirRemoteDataSource` | Fetches tafsir from API |
| `TafsirLocalDataSource` | Local tafsir cache |
| `TafsirRepositoryImpl` | Remote + local fallback |
| `TafsirEntry` entity | `id`, `surahNumber`, `ayahNumber`, `sourceName`, `sourceLanguage`, `text` |
| `GetTafsirUseCase` | Fetch tafsir for specific ayah |
| `AyahActionsCubit` | Manages tafsir loading state |
| `AyahActionsSheet` | Bottom sheet with bookmark, play, tafsir, favorite reciter actions |

#### Services

| Service | Purpose |
|---------|---------|
| `QuranSvgPageService` | Page loading, preloading window (±3 pages), page clamping |
| `QuranSvgMemoryCache` | In-memory SVG cache |
| `QuranPolygonFileCacheService` | Polygon file caching |
| `QuranPolygonHitTestEngine` | Hit testing for ayah tap detection on SVG pages |
| `QuranJuzData` | Juz-to-page mapping (30 juz) |
| `QuranSearchTextUtils` | Text normalization for Arabic search (alef variants, taa marbouta, etc.) |

#### Presentation Layer

**Cubits**:
- `QuranCubit`: Surah selection, page selection, search
- `QuranPolygonCubit`: Polygon data loading per page
- `QuranAyahSelectionCubit`: Ayah tap/long-press selection
- `QuranHighlightCubit`: Tap highlights, reading highlights, search highlights
- `QuranAudioCubit`: Audio playback control
- `AyahActionsCubit`: Tafsir loading state

**`QuranReaderScreen` — Full Feature List**:

| Feature | Description |
|---------|-------------|
| SVG Page Rendering | 604 pixel-perfect Mushaf pages via flutter_svg |
| Pinch-to-Zoom | PhotoView with double-tap zoom (1x → 2.8x) |
| Ayah Tap Detection | Polygon hit-testing on SVG coordinates |
| Long Press Actions | Bottom sheet: bookmark, play, tafsir, share, copy |
| Search Overlay | Full-text search with result navigation |
| Chrome Overlay | Auto-hide after 4s, swipe up/down to toggle |
| Reading Mode | Immersive sticky UI mode |
| Fullscreen Mode | Hide system UI |
| Screen Dimming | Adjustable intensity overlay (0.0–1.0) |
| Warmth Filter | Adjustable warm color overlay |
| Scroll Direction | Horizontal (RTL) / Vertical toggle |
| Continuous Scroll | Non-snapping scroll mode |
| Dark Mode SVG | Color filter matrix to invert SVG text for readability |
| Surah Index Sheet | Full surah list with grid/list view, jump to ayah |
| Juz Sheet | 30 juz quick navigation |
| Bookmarks Sheet | Saved bookmarks with navigation |
| Recently Read Sheet | History of recent pages |
| Ayah Jump Dialog | Enter surah + ayah number to jump |
| Audio Controls | Playback controls overlay with reciter selection |
| Quick Nav Bar | Current surah, juz, page info |
| Page Indicator | Current page number display |
| Scroll Direction FAB | Floating button to toggle scroll direction |
| Zoom Hint | Shows on first launch |

---

### 11.3 Prayer Times

#### Data Layer

| Component | Purpose |
|-----------|---------|
| `PrayerService` | Uses `adhan` package for prayer time calculations |
| `LocationService` | GPS via `geolocator`, reverse geocoding via `geocoding`, open settings |
| `NetworkService` | Connectivity checking |
| `CityDatabaseService` | Downloads/decompresses `cities_min.json.gz`, city search |
| `PrayerSettingsProvider` | SharedPreferences-backed settings |

#### Domain Layer

- **`PrayerSettings`**: `method`, `madhab`, `offsets`, `useDeviceLocation`, `manualLatitude`, `manualLongitude`, `manualLabel`, `customAdhanSound`
- **`PrayerTimeSummary`**: Prayer times, current/next prayer, countdown, Gregorian/Hijri dates

#### Presentation Layer

**`PrayerTimesCubit`**:
- `load()`: Calculate prayer times, update widget, schedule notifications
- `setManualLocation()`: Use manual city coordinates
- `useDeviceLocation()`: Switch to GPS
- `updateSettings()`: Change method/madhab/offsets/sound
- `refresh()`: Recalculate
- `searchCities()`: Search city database
- `ensureCityDatabaseAvailable()`: Download if needed
- `isOnline()`: Check connectivity
- 1-second ticker for countdown updates
- Auto-refreshes when day changes or next prayer passes

**Screens**:

| Screen | Description |
|--------|-------------|
| `PrayerTimesTab` | Embedded on home screen — hero card + grid, loading skeleton, permission card, city search sheet |
| `QiblaScreen` | Qibla compass using device magnetometer via `flutter_qiblah` |

**Calculation Methods** (12 available):
- Muslim World League, ISNA, Egyptian General Authority, Umm Al-Qura, Dubai, Qatar, Kuwait, Jafari, Singapore, Turkey, Tehran, Dianet

---

### 11.4 Tasbeeh

#### Domain Layer
- **`TasbeehRepository` interface**: `getCount()`, `saveCount()`, `reset()`

#### Presentation Layer

**`TasbeehCubit`**: `load()`, `increment()` (with haptic feedback), `reset()`

**`TasbeehCounterScreen`**:

| Element | Description |
|---------|-------------|
| Circular Ring Counter | Custom `_RingPainter` for progress arc with glow animation |
| Bounce Animation | Scale animation on each tap |
| Preset Phrases | SubhanAllah (×33), Alhamdulillah (×33), Allahu Akbar (×33), La ilaha illa Allah (×100), Salawat (×10) |
| Stats Row | Total count, sessions count, remaining count |
| Chip Selector | Horizontal scrollable preset chips |
| Reset Button | Resets current session |

---

### 11.5 Settings

**Presentation Layer Only** (directly uses services, no domain/data layers):

**Cubits**:
- **`ThemeCubit`**: `loadTheme()`, `setMode()` (light/dark/system)
- **`TimeFormatCubit`**: `load()`, `setUse24h()`
- **`NotificationSettingsCubit`**: `load()` (5 reminder times), `setEnabled()`, individual setters, `save()` (persists + schedules notifications)

**Settings Sections**:

| Section | Controls |
|---------|----------|
| Prayer Calculation | Method dropdown (12 methods), Madhab dropdown (Shafi/Hanafi) |
| Appearance | Theme mode segmented button (Light/Dark/System) |
| Time Format | 24-hour format toggle |
| Language | Dropdown (en/ar/tr/id) |
| Reminders | Enable toggle, 5 time pickers (Morning/Evening/Sleep/Waking/Friday), Save button |
| Footer | App name + version |

---

### 11.6 Navigation

**`MainNavigationScreen`**:

| Tab | Icon | Route |
|-----|------|-------|
| Home | `Icons.home_rounded` | `/` |
| Qibla | `Icons.explore_rounded` | Qibla screen |
| Quran | `Icons.menu_book_rounded` (center elevated) | `/quran` |
| Adhkar | `Icons.auto_stories_rounded` | `/adhkar` categories |
| Settings | `Icons.settings_rounded` | `/settings` |

**Features**:
- `IndexedStack` preserves tab state
- Icon bounce animation on selection
- Haptic feedback on tab change
- Center Quran button elevated above nav bar with gradient + glow
- Rounded pill shape with shadow

---

## 12. Shared Widgets

| Widget | File | Purpose |
|--------|------|---------|
| `AppLoadingShimmer` | `app_loading.dart` | Shimmer animation wrapper with gradient shader |
| `ShimmerBox` | `app_loading.dart` | Placeholder box for shimmer effect |
| `AppGridShimmer` | `app_loading.dart` | Grid loading skeleton (configurable count, columns, aspect ratio) |
| `AppListShimmer` | `app_loading.dart` | List loading skeleton |
| `AppScaffoldBackground` | `app_scaffold.dart` | Gradient background for all screens |
| `AppBadge` | `app_badge.dart` | Label badge with colored background |
| `AppCountBadge` | `app_badge.dart` | Circular count badge |
| `AppBottomSheet` | `app_bottom_sheet.dart` | Unified bottom sheet with handle, title, shadow |
| `AppSheetActionButton` | `app_bottom_sheet.dart` | Action button inside bottom sheets |
| `AppEmptyState` | `app_empty_state.dart` | Empty state with icon, title, subtitle, optional action |
| `AppErrorState` | `app_error_state.dart` | Error state with retry button |
| `AppGlassCard` | `app_glass_card.dart` | Modern card with border, shadow, optional tap |
| `AppHeroCard` | `app_hero_card.dart` | Premium card with gradient + glow effect |
| `AppGlowButton` | `app_glow_button.dart` | Primary button with glow, gradient, inner border |
| `AppOutlineGlowButton` | `app_glow_button.dart` | Outline variant with glow |
| `AppActionCircle` | `app_action_circle.dart` | Circular action icon button with glow |
| `PrayerWidgetService` | `prayer_widget_service.dart` | Home widget data updater (next prayer, countdown, date, hijri, location) |

---

## 13. Utilities

| Utility | File | Purpose |
|---------|------|---------|
| `LocaleResolver` | `locale_resolver.dart` | Resolves initial locale from device country/language + saved preferences |
| `TimeFormatter` | `time_formatter.dart` | Formats TimeOfDay/DateTime with 12h/24h and locale awareness |
| `TimeOfDayConverter` | `time_of_day_converter.dart` | Converts TimeOfDay to/from "HH:mm" string for storage |
| `AppCategories` | `app_categories.dart` | 20 adhkar categories with icons, gradient colors, section grouping |

---

## 14. Assets & Data

| Asset | Size/Count | Purpose |
|-------|-----------|---------|
| `adhkar_1500.json` | ~1500 entries | All adhkar with text, count, reference, category |
| `quran_uthmani.json` | 114 surahs, 6236 ayahs | Full Quran text in Uthmani script |
| `cities_min.json.gz` | Compressed | City database for prayer time calculations |
| `timings/` | Multiple files | Recitation timing data for audio sync |
| `translations/*.json` | 4 files | en, ar, tr, id |
| `fonts/Cairo-*.ttf` | 4 weights | Regular(400), Medium(500), SemiBold(600), Bold(700) |
| `icons/azkar_2.png` | 1 file | App launcher icon |

**Quran SVG Pages**:
- Source: `https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/hafs/svg/`
- Files: `001.svg` to `604.svg`
- Cache location: `documents/quran_pages/quran_svg/`
- Cache version: 3 (invalidates on version change)

---

## 15. Third-Party Packages

| Package | Version | Usage |
|---------|---------|-------|
| `flutter_bloc` | ^9.1.1 | State management (Cubits) |
| `get_it` | ^8.2.0 | Dependency injection (service locator) |
| `go_router` | ^16.2.0 | Declarative routing with deep linking |
| `easy_localization` | ^3.0.8 | i18n/l10n with JSON files |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | Local NoSQL storage |
| `shared_preferences` | ^2.3.2 | Prayer settings storage |
| `flutter_local_notifications` | ^19.4.2 | Scheduled notifications (adhkar + prayer) |
| `adhan` | ^2.0.0 | Prayer time calculations |
| `geolocator` | ^14.0.2 | GPS location services |
| `geocoding` | ^3.0.0 | Reverse geocoding (coordinates → city name) |
| `flutter_qiblah` | ^3.2.0 | Qibla direction via magnetometer |
| `hijri` | ^3.0.0 | Hijri calendar conversion |
| `just_audio` | ^0.9.42 | Quran audio streaming |
| `http` | ^1.2.2 | Network requests (tafsir, SVG download) |
| `path_provider` | ^2.1.4 | File system paths (cache directory) |
| `home_widget` | ^0.6.0 | iOS/Android home widget support |
| `share_plus` | ^12.0.0 | Share dhikr text |
| `photo_view` | ^0.15.0 | Image zoom (Quran pages) |
| `flutter_svg` | ^2.2.0 | SVG rendering |
| `google_fonts` | ^6.3.2 | Font loading |
| `timezone` / `flutter_timezone` | ^0.10.1 / ^5.0.2 | Timezone handling for notifications |
| `intl` | ^0.20.2 | Date/time formatting |
| `equatable` | ^2.0.7 | Value equality for states |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

---

## 16. Testing

### Test Files (14 total)

| File | Coverage |
|------|----------|
| `quran_search_index_test.dart` | Search index building, exact/prefix matching, multi-word queries, scoring |
| `quran_search_text_utils_test.dart` | Text normalization (alef, taa marbouta, whitespace), tokenization, matching |
| `quran_repository_impl_search_test.dart` | Repository search integration |
| `quran_highlight_cubit_test.dart` | Highlight state management |
| `quran_bookmark_repository_mock.dart` | Mock for bookmark repository |
| `tafsir_local_data_source_test.dart` | Tafsir caching, retrieval, clearing |
| `tafsir_entry_test.dart` | Tafsir entity, source defaults |
| `ayah_actions_state_test.dart` | Ayah actions cubit state |
| `quran_audio_state_test.dart` | Audio playback state |
| `reciter_test.dart` | Reciter entity, defaults, URL templates |
| `surah_timing_test.dart` | Surah timing calculations |
| `ayah_timing_test.dart` | Ayah timing calculations |
| `quran_audio_player_service_test.dart` | Audio player state enum |
| `widget_test.dart` | Basic app rendering smoke test |
| `local_storage_service_mock.dart` | Mock for storage service |

### Testing Approach
- **Unit tests**: Domain entities, data sources, repositories, cubit states
- **Mock-based**: `local_storage_service_mock.dart`, `quran_bookmark_repository_mock.dart`
- **Widget tests**: Basic app rendering verification
- **Total**: 102 passing tests

---

## 17. Build & Run

### Prerequisites
- Flutter SDK 3.11.0+
- Dart SDK 3.11.0+
- Android Studio / Xcode
- Android SDK / iOS Simulator

### Commands

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Run with specific device
flutter run -d <device_id>

# Hot reload
r (while running)

# Hot restart
R (while running)

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Generate launcher icons
flutter pub run flutter_launcher_icons
```

### Environment
- **SDK**: Dart 3.11.0+
- **Min Android SDK**: 21 (Android 5.0)
- **Min iOS**: 12.0
- **Package Name**: `com.example.azkar`
- **iOS Bundle ID**: `com.example.azkar`
- **iOS Group ID**: `group.com.example.azkar` (for home widget)
