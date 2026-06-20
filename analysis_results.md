# 📊 English AI Study App — Project Analysis

## 1. Project Overview

| Attribute | Value |
|---|---|
| **App Name** | English AI Study App |
| **Framework** | Flutter (Dart SDK ≥3.0.0 <4.0.0) |
| **Backend** | Node.js (Gemini API proxy) — deployed on Render |
| **Auth & Database** | Firebase Auth + Cloud Firestore |
| **Local Storage** | Hive (`vocabulary_box`) |
| **Design System** | Material 3, Google Fonts (Inter + Outfit) |
| **Primary Color** | `#4F46E5` (Indigo) |
| **Target Platforms** | Android, iOS, Web, Windows, macOS, Linux |
| **Figma Design** | [Figma Link](https://www.figma.com/design/L1ax1bXPQZMpmH2q2jAKhG/English-AI-Study-App) |

---

## 2. Architecture & File Structure

```
lib/
├── main.dart                          (15.6 KB — 453 lines) ← App entry, routing, session, usage tracking
├── screens/
│   ├── splash_screen.dart             ( 7.8 KB — 243 lines) ← Animated splash
│   ├── auth_screen.dart               (29.9 KB — 776 lines) ← Login/Register with Firebase Auth
│   ├── home_screen.dart               (49.5 KB — 1162 lines) ← Dashboard, translator, stats
│   ├── vocabulary_screen.dart         (66.3 KB — 1622 lines) ← Words, Tenses, Numbers, Topics, Favorites
│   ├── chat_screen.dart               (23.1 KB — 635 lines) ← AI Tutor chat (Gemini backend)
│   ├── notifications_screen.dart      (14.0 KB — 403 lines) ← Notification list
│   ├── profile_screen.dart            (44.8 KB — 1141 lines) ← Profile, settings, progress
│   ├── edit_profile_screen.dart       (37.3 KB — 924 lines) ← Edit profile, photo upload
│   └── custom_snackbar.dart           ( 2.0 KB — 63 lines) ← Reusable styled snackbar
└── utils/
    └── notification_helper.dart       ( 1.2 KB — 43 lines) ← In-app notification writer
```

```
assets/data/                           (~910 KB total vocabulary data)
├── api_vocabulary.json                (303 KB) ← Beginner/Intermediate/Advanced words
├── api_vocabulary_nouns.json          (177 KB)
├── api_vocabulary_verbs.json          (224 KB)
├── api_vocabulary_adjective.json      (89 KB)
├── api_vocabulary_pronoun.json        (14 KB)
├── api_vocabulary_number.json         (29 KB)
├── api_english_tenses.json            (37 KB)
└── api_english_topics.json            (36 KB)
```

```
backend/
├── .env                               ← Gemini API Key
└── English-ai-study-backend/          ← (empty locally — deployed to Render)
```

---

## 3. Features Inventory

| Feature | Screen | Status |
|---|---|---|
| Animated Splash Screen | `splash_screen.dart` | ✅ Working |
| Email/Password Auth (Firebase) | `auth_screen.dart` | ✅ Working |
| Offline/Local Fallback Auth | `auth_screen.dart` | ✅ Working |
| Google Sign-In | `auth_screen.dart` | ❌ Stub (not implemented) |
| Forgot Password | `auth_screen.dart` | ❌ Stub (not implemented) |
| Dashboard with Greeting | `home_screen.dart` | ✅ Working |
| Real-time EN↔KH Translator | `home_screen.dart` | ✅ Working |
| Audio Pronunciation | `home_screen.dart` | ✅ Working |
| Favorite Words (Hive + Firestore) | `home_screen.dart`, `vocabulary_screen.dart` | ✅ Working |
| Daily 25-word Vocabulary | `vocabulary_screen.dart` | ✅ Working |
| Category tabs (Nouns, Verbs, etc.) | `vocabulary_screen.dart` | ✅ Working |
| English Tenses reference | `vocabulary_screen.dart` | ✅ Working |
| Numbers reference | `vocabulary_screen.dart` | ✅ Working |
| Topics with example sentences | `vocabulary_screen.dart` | ✅ Working |
| Vocabulary search + translation | `vocabulary_screen.dart` | ✅ Working |
| AI Chat (Gemini via backend) | `chat_screen.dart` | ✅ Working |
| In-app Notifications | `notifications_screen.dart` | ✅ Working |
| User Profile with Progress | `profile_screen.dart` | ✅ Working |
| Edit Profile (name, email, password) | `edit_profile_screen.dart` | ✅ Working |
| Profile Photo Upload | `edit_profile_screen.dart` | ✅ Working |
| Daily Study Goal (30 min tracker) | `main.dart` | ✅ Working |
| Active Days Tracking | `main.dart` | ✅ Working |
| Achievement Milestones | `main.dart`, `profile_screen.dart` | ✅ Working |
| Dark Mode | `profile_screen.dart` | ❌ UI toggle only (not wired) |
| Push Notifications | `utils/notification_helper.dart` | ✅ Working (Local OS Notifications) |
| Notification Badge on Bottom Nav | `main.dart` | ✅ Working |

---

## 4. Dependencies Analysis

| Package | Version | Purpose | Status |
|---|---|---|---|
| `flutter` (SDK) | ≥3.0.0 | Core framework | ✅ |
| `google_fonts` | ^6.2.0 | Inter & Outfit typography | ✅ |
| `lucide_icons` | ^0.257.0 | Icon set | ⚠️ **Imported but never used** |
| `http` | ^1.2.0 | Network requests | ✅ |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | Local key-value storage | ✅ |
| `audioplayers` | ^6.0.0 | Audio pronunciation playback | ✅ |
| `firebase_core` | ^2.32.0 | Firebase initialization | ✅ |
| `firebase_auth` | ^4.19.7 | Email/Password auth | ✅ |
| `cloud_firestore` | ^4.17.5 | User data, favorites, chat history | ✅ |
| `firebase_storage` | ^11.7.7 | File storage | ⚠️ **Imported but not used** (uploads go to backend) |
| `image_picker` | ^1.2.2 | Photo selection for profile | ✅ |
| `flutter_local_notifications` | ^18.0.1 | OS-level push notifications | ✅ |
| `http_parser` | (transitive) | Used in edit_profile_screen | ⚠️ **Imported but never used** |

---

## 5. Code Quality Issues

### 🔴 Critical

| # | Issue | Location | Details |
|---|---|---|---|
| 1 | **Hardcoded Firebase API keys** | [main.dart:29-34](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/main.dart#L29-L34) | Web Firebase config is hardcoded with API key, project ID, etc. Should use environment variables or `firebase_options.dart` generated by FlutterFire CLI. |
| 2 | **Gemini API key exposed in `.env` file** | [backend/.env](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/backend/.env) | The Gemini API key is committed to the repo. This should be in `.gitignore`. |
| 3 | **Unused `GEMINI_API_KEY` constant** | [chat_screen.dart:39](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/screens/chat_screen.dart#L39) | A placeholder `GEMINI_API_KEY` constant exists but the app calls the backend, not the Gemini API directly. Dead code that could mislead. |
| 4 | **Global mutable state** | [main.dart:19](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/main.dart#L19) | `isFirebaseInitialized` is a global `bool` accessed across files. Should use a proper state management solution or at minimum a service class. |

### 🟡 Moderate

| # | Issue | Location | Details |
|---|---|---|---|
| 5 | **Giant screen files** | `vocabulary_screen.dart` (1622 lines), `home_screen.dart` (1162 lines), `profile_screen.dart` (1141 lines) | These files are far too large. UI components, data logic, and API calls should be separated into widgets, models, and services. |
| 6 | **User data as `Map<String, String>`** | Throughout | User profile is passed as a raw `Map<String, String>` everywhere. Should be a typed `User` model class with proper serialization. |
| 7 | **Duplicated photo URL normalization** | [home_screen.dart:320-328](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/screens/home_screen.dart#L320-L328), [profile_screen.dart:357-366](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/screens/profile_screen.dart#L357-L366), [edit_profile_screen.dart:434-443](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/screens/edit_profile_screen.dart#L434-L443) | The same `localhost → render.com` URL rewriting logic is copy-pasted in 3 files. Should be a utility function. |
| 8 | **Duplicated avatar widget** | `home_screen.dart`, `profile_screen.dart`, `edit_profile_screen.dart` | The avatar rendering logic (network/file/fallback initial) is duplicated across 3 screens. Should be a shared `UserAvatar` widget. |
| 9 | **Duplicated level selection dialog** | `profile_screen.dart`, `edit_profile_screen.dart` | Identical dialog code appears in both files. Should be extracted to a shared widget. |
| 10 | **No state management** | Entire project | Uses raw `setState` + passing data through constructor props. For this app size, consider using Provider, Riverpod, or BLoC. |
| 11 | **Empty catch blocks swallowing errors** | Throughout (Fixed!) | `catch (_) {}` blocks were replaced with `debugPrint` for better visibility. |
| 12 | **No loading/error states for many operations** | Favorites sync, Firestore writes | Many Firestore operations have no user-facing feedback on failure. |
| 13 | **Hardcoded default word "anime"** | [home_screen.dart:53-58](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/screens/home_screen.dart#L53-L58) and [home_screen.dart:192-195](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/screens/home_screen.dart#L192-L195) | The translator starts with "anime" and has a hardcoded phonetic/example fallback for it. Should be random or configurable. |

### 🟢 Minor

| # | Issue | Location | Details |
|---|---|---|---|
| 14 | **No `const` constructors where possible** | Various widgets | Some widgets that could be `const` are not declared as such. |
| 15 | **Deprecated `background` in `ColorScheme`** | [main.dart:60](file:///c:/Users/Daro/Documents/mobile-app-flutter-project/lib/main.dart#L60) | `background` is deprecated in Material 3, use `surface` or `surfaceContainerHighest`. |
| 16 | **Deprecated `withOpacity`** | Throughout | `Color.withOpacity()` is deprecated in newer Flutter; use `Color.withValues()`. |
| 17 | **Unused import: `dart:io`** on web | `home_screen.dart`, `profile_screen.dart` | `dart:io` is imported and used conditionally, but could cause web compilation warnings. |
| 18 | **No unit tests** | `test/widget_test.dart` | Only the default generated widget test exists. No actual test coverage. |
| 19 | **Unused dependency: `lucide_icons`** | `pubspec.yaml` | Declared but never imported/used in any Dart file. |
| 20 | **Unused dependency: `firebase_storage`** | `pubspec.yaml` | Declared but not used (uploads go to the Render backend). |

---

## 6. Security Vulnerabilities

> [!CAUTION]
> The following security issues should be addressed before production deployment.

| Priority | Issue | Risk | Recommendation |
|---|---|---|---|
| 🔴 **HIGH** | Firebase Web config (API key, project ID) hardcoded in source | Exposed in version control; can be used for unauthorized API calls | Use `firebase_options.dart` from FlutterFire CLI; add to `.gitignore` |
| 🔴 **HIGH** | Gemini API key committed in `backend/.env` | Anyone with repo access can use/abuse the key | Add `backend/.env` to `.gitignore`; rotate the key |
| 🟡 **MEDIUM** | No input sanitization on chat messages | Prompt injection possible via AI chat | Sanitize user input before sending to Gemini |
| 🟡 **MEDIUM** | `updateEmail()` without re-authentication | Firebase requires recent auth for email changes; will fail silently | Implement re-authentication flow before sensitive operations |
| 🟢 **LOW** | No rate limiting on translation API calls | Could trigger Google Translate abuse limits | Add local rate limiting or use a proper API key |

---

## 7. Performance Observations

| Area | Observation | Impact |
|---|---|---|
| **IndexedStack** | All 5 main tabs are built at once | Higher initial memory; but preserves state across tab switches — acceptable trade-off |
| **Vocabulary data** | ~910 KB of JSON assets loaded from bundle | Fine for mobile; consider lazy loading for web |
| **Translation debounce** | 600ms debounce on typing | ✅ Good practice |
| **Hive caching** | Daily words cached by date key | ✅ Good — avoids re-shuffling within same day |
| **No image caching** | Network images (avatars, Google logo) have no explicit cache | Consider `cached_network_image` package |
| **Google Fonts** | Downloaded at runtime | May cause initial text flash; consider bundling fonts in assets |

---

## 8. Improvement Recommendations

### 🏗️ Architecture (High Impact)

1. **Introduce a state management solution** (Provider or Riverpod) to replace prop drilling of `user` map and callbacks
2. **Create a `User` model class** with proper serialization instead of `Map<String, String>`
3. **Extract a service layer** — `AuthService`, `VocabularyService`, `TranslationService`, `UserService` — to decouple business logic from UI
4. **Break up large screens** into smaller, focused widgets (e.g., `TranslatorCard`, `StatsRow`, `WordCard`, `UserAvatar`)

### 🔐 Security (Must Fix)

5. **Rotate and secure API keys** — use environment variables, not hardcoded values
6. **Add `.env` to `.gitignore`** immediately
7. **Generate `firebase_options.dart`** via FlutterFire CLI instead of hardcoding config

### 🧪 Testing (Needed)

8. **Add widget tests** for each screen
9. **Add unit tests** for business logic (level calculation, active day tracking, favorites sync)
10. **Add integration tests** for auth flows

### 🎨 Polish (Nice to Have)

11. **Implement Dark Mode** — the toggle exists but does nothing
12. **Implement Google Sign-In** — the button exists but does nothing
13. **Implement Forgot Password** — the link exists but does nothing
14. **Remove unused dependencies** (`lucide_icons`, `firebase_storage`)
15. **Add proper error logging** instead of `catch (_) {}`

---

## 9. Lines of Code Summary

| Component | Lines | Percentage |
|---|---|---|
| `vocabulary_screen.dart` | 1,622 | 24.4% |
| `home_screen.dart` | 1,162 | 17.5% |
| `profile_screen.dart` | 1,141 | 17.2% |
| `edit_profile_screen.dart` | 924 | 13.9% |
| `auth_screen.dart` | 776 | 11.7% |
| `chat_screen.dart` | 635 | 9.5% |
| `main.dart` | 453 | 6.8% |
| `notifications_screen.dart` | 403 | 6.1% |
| `splash_screen.dart` | 243 | 3.7% |
| `custom_snackbar.dart` | 63 | 0.9% |
| `notification_helper.dart` | 43 | 0.6% |
| **Total** | **~6,640** | **100%** |

---

## 10. Overall Assessment

> [!IMPORTANT]
> **The app is functional and feature-rich** with a solid UI design system, offline fallback, and Firebase integration. The Khmer-English translation focus and AI chat tutor make it a compelling learning tool.

**Strengths:**
- ✅ Clean, consistent visual design with a premium feel
- ✅ Good offline/fallback handling when Firebase is unavailable
- ✅ Rich feature set — translator, vocabulary, tenses, topics, AI chat
- ✅ Smart caching strategy (daily word caching, Hive persistence)
- ✅ Working notification system with milestones

**Areas for Improvement:**
- ⚠️ Code organization needs refactoring (files too large, duplicated code)
- ⚠️ Security vulnerabilities with exposed API keys
- ⚠️ No test coverage
- ⚠️ Several stubbed features (Google Sign-In, Forgot Password, Dark Mode)
- ⚠️ Missing proper state management

**Overall Grade: B** — A solid MVP with good UX, but needs architectural refactoring and security fixes before production deployment.
