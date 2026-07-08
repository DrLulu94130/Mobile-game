# Inkognito 🕵️‍♂️

**Hide. Camouflage. Challenge.**

Inkognito lets players create hide-and-seek puzzles from their own photos.
Drop original little creatures — **Inklings** — into a picture, paint the colours
of the scene onto them so they vanish, then dare friends to find them against
the clock.

> Inklings are entirely original designs: round, simple, white-bodied creatures
> with large curious eyes. Every character pack (ghosts, robots, dragons,
> aliens, animals, monsters) is original artwork drawn procedurally in Flutter.

---

## ✨ Features

| Area | What's included |
| --- | --- |
| **Creation** | Pick from gallery or camera, place multiple Inklings |
| **Transform** | Move, resize, rotate, duplicate, delete |
| **Camouflage** | Draw *inside* each Inkling (clipped/masked), brush, eraser, brush sizes, undo/redo, zoom |
| **Smart colour** | Pipette (sample from the photo) + one-tap auto-colour (averages the scene behind the creature) |
| **Export** | Generates a camouflaged image **and** a revealed solution image |
| **Sharing** | Instagram Story, Snapchat, TikTok, WhatsApp, Messages, Copy link — the shared media contains only the camouflaged photo; the link deep-links into the app or the store |
| **Play / detection** | Recipients tap to find Inklings; scored on finds, time and accuracy |
| **Discover** | TikTok-style vertical scroll of everyone's drawings: 10 seconds to find every Inkling; wins/losses feed each drawing's note |
| **Tokens** | Scrolling Discover earns tokens (+1 per drawing, +2 per win); publishing a drawing costs 15 tokens (free for Premium) |
| **Ratings** | Every drawing gets a note out of 5 — the share of seekers it fooled — shown on feed cards and ranked in a dedicated leaderboard tab |
| **Community** | Feed, likes, comments, trending, daily challenges, popular creators |
| **Progression** | XP, levels, achievements, badges, daily streaks |
| **Packs** | Six original creature families; premium packs gated |
| **Monetisation** | Free with **AdMob** ads (banner + frequency-capped interstitial, auto-hidden for Premium); Premium (ad-free, all packs, HD export, unlimited challenges, more Inklings) via RevenueCat |
| **Deep links** | Shared links (`inkognito://challenge/<id>` and `https://<host>/c/<id>`) open the exact challenge in-app via `app_links`; store fallback for non-users |
| **Editor zoom** | Pinch/pan inspection mode (`InteractiveViewer`) — zoom in, then draw with precision |
| **Localisation** | Full English + French (`gen-l10n`), with an in-app language switch |
| **Polish** | Clean Architecture, Riverpod, GoRouter, responsive, fluid animations, full Dark Mode |

## 🏗 Architecture

Feature-first **Clean Architecture**:

```
lib/
├── core/                 # config, theme, router, errors, utils, DI providers
├── shared/               # cross-feature widgets (shell, buttons, avatars)
└── features/
    ├── auth/             # data · domain · presentation
    ├── onboarding/
    ├── editor/           # the Inkling canvas, painters, tools  ← the heart
    ├── challenge/        # entities, repository, image export, storage
    ├── play/             # detection engine, attempts, result UI
    ├── community/        # feed, likes, comments
    ├── daily/
    ├── leaderboard/
    ├── progression/      # XP, levels, badges, streaks
    ├── packs/
    ├── premium/          # RevenueCat paywall
    ├── profile/
    ├── settings/
    └── share/            # share service + landing deep links
```

Each feature is split into:

- **domain** — pure entities & business logic (no Flutter/Firebase), fully unit-testable
  (`DetectionEngine`, `ProgressionService`, `BadgeCatalog`, the editor state machine).
- **data** — repositories wrapping Firebase, mapping exceptions to typed `Failure`s
  and returning a functional `Result<T>`.
- **presentation** — Riverpod controllers + widgets.

**State management:** Riverpod (`StateNotifier` / `AsyncNotifier` + providers).
**Navigation:** GoRouter with a `StatefulShellRoute` bottom-nav shell and
auth-driven redirect guards.

## 🔧 Tech stack

Flutter · Firebase Auth · Cloud Firestore · Storage · Cloud Functions ·
RevenueCat · Crashlytics · Analytics.

## 🚀 Getting started

```bash
# 1. Install dependencies (also runs gen-l10n for EN/FR localisation)
flutter pub get

# 2. Generate the native platform folders (android/ ios/ …)
flutter create .

# 3. Connect Firebase (overwrites lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Run
flutter run \
  --dart-define=RC_ANDROID_KEY=your_key \
  --dart-define=RC_IOS_KEY=your_key
```

See [`docs/native_setup.md`](docs/native_setup.md) for the required
`AndroidManifest.xml` / `Info.plist` entries (camera, photos, deep links,
share targets) and [`docs/backend_setup.md`](docs/backend_setup.md) for
deploying rules and functions.

## 🧪 Tests

```bash
flutter test
```

Covers the detection engine, scoring, levelling curve, badge unlocks,
model serialisation and the editor state machine (add/duplicate/delete/undo/redo/draw).

## 🔐 Backend

- `firestore.rules` / `storage.rules` — least-privilege security rules.
- `firestore.indexes.json` — composite indexes for the feed/daily/leaderboard queries.
- `functions/` — creator stats, the public share landing page (open-in-app +
  store fallback + OpenGraph preview), a RevenueCat entitlement webhook and a
  scheduled daily-challenge rotation.

```bash
firebase deploy --only firestore:rules,storage,firestore:indexes,functions
```

## 📄 License

Original artwork and code. All Inkling designs are original to Inkognito.
