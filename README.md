# Kana Quest 🦊

Kana Quest is a Flutter mobile learning app for practicing Japanese scripts through guided lessons, spaced repetition reviews, stroke order tracing, vocabulary study, and quizzes.

It supports:
- Hiragana
- Katakana
- Introductory Kanji sets

The app is designed around short practice loops with immediate feedback (visual, haptic, and sound), persistent progress tracking, and review-focused repetition.

## Table of Contents
- 🌟 Overview
- 🚀 Core Features
- 🔄 App Flow
- 🛠️ Tech Stack
- 🗂️ Project Structure
- 💾 Data and Persistence
- ▶️ Running the App
- ✅ Testing and Quality
- 📚 Content Sources
- ⚙️ Configuration Notes
- 🧩 Troubleshooting

## 🌟 Overview
Kana Quest combines multiple learning modes:
- Learn tab for script progression by rows/sections
- Review arena with SRS-based ratings
- Stroke order guide and trace mode
- Vocabulary study by category
- Quiz mode with history and detailed answer review
- Profile (Dojo) with progress stats and quiz analytics

It aims to make script learning feel game-like while keeping practical learning metrics.

## 🚀 Core Features

### 1) 🧭 Onboarding
- Collects learner name and initializes preferences.
- Sets default daily goal and path.
- Redirects to app home after first-run setup.

### 2) 🗺️ Learn Map
- Displays section-based progression for the selected script.
- Supports Hiragana, Katakana, and Kanji script tabs.
- Unlocks progression based on completion state.
- Launches section practice/review directly from map cards.

### 3) ⛺ Base Camp / Lesson Discovery
- Introduces characters with mnemonic-style guidance.
- Shows pronunciation and script context.
- Provides entry point into stroke guide and practice.

### 4) ✍️ Stroke Order Guide and Trace
- Loads stroke paths per character.
- Supports sequence and trace behavior.
- Uses a custom stroke painter for incremental rendering.
- Includes path validation for tracing interactions.
- Persists stroke metadata with each card for consistency.

### 5) 🔁 Review Arena (SRS)
- Pulls due cards by script and section.
- Uses SM-2-like scheduling behavior (interval, ease, repetitions).
- Rating flow updates next review date and progress state.
- Includes combo, due count, and completion confetti feedback.
- Includes practice mode when no due cards are available.

### 6) 📖 Vocabulary
- Search by Japanese, furigana, romaji, or English.
- Filter by category chips.
- Grouped category sections in all-words mode.
- Built-in TTS pronunciation (with Linux fallback).
- Includes general daily vocabulary plus anime-relevant terms.

### 7) 🧠 Quiz
- Multi-type questions:
	- Kana to romaji
	- Japanese to English
	- English to Japanese
- Session scoring with per-question correctness tracking.
- Result screen with:
	- score percentage
	- correct/wrong counts
	- detailed answer review
- Persists quiz history sessions and aggregate stats.

### 8) 🥋 Profile (Dojo)
- Displays learner name, level, XP, streak, and progress bars.
- Shows script progress and quiz metrics.
- Shows recent quiz attempts with tap-to-review details.
- Supports theme mode switching (system/light/dark).

### 9) 🎧 Feedback UX
- Haptics and system sounds are integrated in key interactions:
	- tab changes
	- option selection
	- quiz answer correctness
	- profile interactions
	- vocabulary interactions

## 🔄 App Flow
1. App starts and initializes local database.
2. Seed service upserts script cards and stroke metadata.
3. Bootstrap route checks onboarding completion.
4. Home shell loads with bottom navigation:
	 - Learn
	 - Vocabulary
	 - Quiz
	 - Profile
5. User progresses via lessons/review and stats update in persistent storage.

## 🛠️ Tech Stack
- Flutter
- Dart (SDK ^3.11.3)
- Riverpod for state management
- Isar for local database
- SharedPreferences for lightweight settings/statistics
- flutter_tts for speech playback
- confetti for completion celebration
- path_drawing/path_parsing for stroke rendering and tracing

## 🗂️ Project Structure
Top-level feature modules under `lib/src/features`:
- `onboarding/`
- `home/`
- `base_camp/`
- `lessons/`
- `review/`
- `vocabulary/`
- `quiz/`
- `dojo/`

Core infrastructure:
- `lib/src/app/` for app bootstrap/routes/preferences keys
- `lib/src/core/storage/` for Isar setup
- `lib/src/core/services/` for streak and shared behavior
- `lib/src/core/theme/` for app theming

## 💾 Data and Persistence

### 🗃️ Isar
Primary persistent model:
- `KanaCard`

Important persisted fields include:
- character/script/row/mnemonic/romaji
- SRS fields (interval, repetitions, easeFactor, nextReviewDate)
- strokeCount and strokePaths for guide/trace rendering

Seed pipeline:
- Seed data for Hiragana, Katakana, and Kanji cards
- Stroke path repository integration during seed/upsert

### 🧠 SharedPreferences
Used for:
- onboarding completion and user profile basics
- theme mode
- daily goal
- quiz aggregate counters
- quiz session history (serialized)
- streak dates and recent review info

## ▶️ Running the App

### 📌 Prerequisites
- Flutter SDK installed
- Dart SDK (bundled with Flutter)
- Platform toolchain (Android Studio/Xcode/Linux desktop dependencies as needed)

### 📦 Install dependencies
```bash
flutter pub get
```

### ⚙️ Generate Isar code (if models changed)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### ▶️ Run
```bash
flutter run
```

Example desktop run:
```bash
flutter run -d linux
```

## ✅ Testing and Quality

Run tests:
```bash
flutter test
```

Static analysis:
```bash
flutter analyze
```

## 📚 Content Sources

### 🧾 Included assets
- `assets/hiragana_rows.json`
- `assets/katakana_rows.json`
- `assets/kanji_rows.json`

### 🗣️ Vocabulary content
Vocabulary currently includes:
- greetings, numbers, time, food, nature, people
- verbs, adjectives, places
- anime-relevant practical terms

## ⚙️ Configuration Notes

### 🎨 Theme
Theme mode is user-selectable and persisted.

### 🔊 Audio
- Primary playback: flutter_tts (Japanese)
- Linux fallback attempts platform speech commands when needed

### 📳 Haptics and sound
High-frequency interaction points include haptic and click/alert feedback.

## 🧩 Troubleshooting

### 🛠️ Build runner conflicts
If generated files conflict:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### ♻️ Stale local data after seed/content changes
If you changed seed rows/stroke data and do not see updates:
1. uninstall app or clear app storage
2. rerun the app so initial seed path executes cleanly

### 🗣️ TTS issues on desktop
If speech is unavailable, verify desktop speech tools and locale support.

---

If you are contributing, keep feature additions aligned with the existing modular structure in `lib/src/features`, and run format, analyze, and tests before opening a PR.
