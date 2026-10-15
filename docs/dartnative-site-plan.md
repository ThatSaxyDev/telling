# DartNative launch — site & docs plan

Adding DartNative support (`telling_kit`) to telling.cv alongside Flutter
(`telling_logger`), without demoting either. Scope: landing page, in-site docs,
SEO metadata, and the surfaces that must move in lockstep.

Status: **plan for review.** Nothing implemented yet.

---

## 0. The one fact that shapes everything

The marketing site is **not a separate project**. It is the `/landing` route of
the dashboard app itself (`telling/`, a Flutter Web bundle, `initialLocation:
'/landing'`).

Two consequences:

- Every copy change ships as a full `flutter build web` → Netlify deploy, not a
  CMS edit.
- A regression in `/landing` breaks both the public marketing page **and** the
  pre-login flow for existing users.

**Mitigation:** test locally with `flutter run` (simulator or Chrome), then
build and drop. See §9 for the actual workflow.

---

## 0b. Testing & release workflow

There is no CLI deploy here. Nothing in this project uses `netlify deploy`, and
`make netdep` is unused.

**While developing:**

```sh
cd telling
flutter run -d chrome          # hot reload, the normal loop
```

**Before dropping** — build release and serve the *built output*, not the dev
compiler, because that is what Netlify will serve:

```sh
flutter build web
cd build/web && python3 -m http.server 8080
```

⚠️ **`http.server` will 404 on every deep link.** It does not read
`web/_redirects`, so `/landing`, `/docs` and `/privacy` all fail locally while
working perfectly on Netlify — a false alarm that wastes an hour. Use a server
that mirrors the rewrite:

```sh
cat > /tmp/spa.py <<'PY'
import http.server, os, functools
class SPA(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        p = self.path.split('?')[0].lstrip('/')
        if p and not os.path.exists(p):
            self.path = '/index.html'      # mirrors Netlify's /* /index.html 200
        return super().do_GET()
http.server.HTTPServer(('127.0.0.1', 8080),
    functools.partial(SPA, directory=os.getcwd())).serve_forever()
PY
cd build/web && python3 /tmp/spa.py
```

Two things a release build catches that `flutter run` will not:

- **Release-mode behaviour.** `dart2js` differs from the dev build. The landing
  page forces dark theme (`main.dart:235`) and derives breakpoints from
  `responsive_framework` (`main.dart:240-249`), so the mobile/desktop badge
  breakpoint is worth confirming in a real release build.
- **Lazy asset loading.** Docs pages load their markdown on click, so a missing
  asset entry only surfaces when you actually visit the page.

**Deploying:** drag `telling/build/web/` into Netlify Drop. That is the whole
release path, and it is fine.

**Consequently, `.netlify/netlify.toml` is dead config.** Its `publish` key is an
absolute macOS path to the repo root, and `flutter build web` never copies
`.netlify/` into `build/web`, so Netlify Drop never reads it. It is *not* a
broken deploy — an earlier draft of this plan called it one; that was wrong. It
can be deleted whenever convenient.

---

## 1. Brand tokens

DartNative's mark is a four-gradient spectrum, not a single colour. Sampled from
`dn-logo-transparent.svg`:

| Token | Hex | Role |
| --- | --- | --- |
| `dnPink` | `#fa60a6` | gradient head |
| `dnMagenta` | `#ef388b` | |
| `dnSalmon` | `#e99173` | mid-warm |
| `dnGold` | `#f9d126` | **primary** |
| `dnOlive` | `#b5c75e` | gradient end |
| `dnTeal` | `#17c4e0` | |
| `dnCyan` | `#03c3f0` | tail |

Sweep for the badge: `pink → gold → olive → cyan`.

Flutter's pair is currently **hardcoded** at `landing_screen.dart`
L1029/1030/1038/1046/1057 — the only brand-colour literals in the codebase, since
`AppColors` is strictly monochrome. Phase 1 promotes both sets into `AppColors`:

```dart
// AppColors
static const flutterBlue      = Color(0xFF02569B);
static const flutterBlueLight = Color(0xFF54C5F8);

static const dnGold  = Color(0xFFF9D126);   // primary
static const dnPink  = Color(0xFFFA60A6);
static const dnCyan  = Color(0xFF03C3F0);
static const dnOlive = Color(0xFFB5C75E);

// Badge border sweep
static const dnSpectrum = LinearGradient(colors: [
  dnPink, dnGold, dnOlive, dnCyan,
]);
```

**Open:** the DartNative mark itself. Flutter uses `Icons.flutter_dash`. Options
in §6.

---

## 2. Revised information architecture — the core change

First pass of this plan proposed per-snippet toggles everywhere. That is wrong,
and here is why.

`telling_kit` is a **port of `telling_logger`**, so the API is ~90% identical.
Verified identical in both: `log`, `event`, `captureException`, `setUser`,
`clearUser`, `setUserName`, `setUserProperty(s)`, `getUserProperty`,
`clearUserProperty(ies)`, `trackFunnel`, `flush`, `checkVersion`,
`snoozeUpdate`, `acceptUpdate`, `TellingTryCatch`, `LogLevel`, `LogType`. Even
`.nowTelling()` is the same, because the widget extension was ported across.

Toggling every snippet would triple the docs to communicate almost nothing.
Instead:

- **Dedicated sections** where the content genuinely diverges.
- **Per-snippet toggles** only inside shared pages, for the handful of snippets
  that differ.

### Proposed sidebar

`docs_screen.dart:36-83` hardcodes a flat `_sections` list. It becomes grouped:

```
OVERVIEW
  Overview                    overview.md
  Which SDK do I need?        choosing_an_sdk.md      NEW

FLUTTER  · telling_logger · pub.dev
  Getting Started             getting_started.md
  Screen Tracking             flutter_screen_tracking.md   NEW (extracted)
  Widget Tracking             widget_tracking.md
  App Config & Updates        app_config.md

DARTNATIVE  · telling_kit · dartpub.dev
  Getting Started             dartnative/getting_started.md   NEW
  Bootstrap & Crash Capture   dartnative/bootstrap.md         NEW
  Screen Tracking             dartnative/screen_tracking.md   NEW
  Device Metadata             dartnative/device_metadata.md   NEW

SHARED  · identical in both SDKs
  Core Concepts               core_concepts.md
  Analytics & Funnels         funnel_tracking.md
  Error Handling              advanced_features.md
  Configuration               configuration.md
  Best Practices              best_practices.md
```

`advanced_features.md:85-102` currently mixes a `MaterialApp`/`GoRouter` observer
snippet with framework-agnostic error-handling. It gets **split**: the observer
snippet moves to `flutter_screen_tracking.md`; the rest stays shared.

### Why a dedicated Bootstrap section earns its place

This is the highest-value content in the whole effort, and it does not exist yet.

Flutter is one linear sequence. DartNative is **not** — two requirements a
developer copying from the Flutter docs will get wrong:

1. `armCrashCapture()` must run **before** `init()`, or crashes thrown during
   startup are lost.
2. `run()` must **wrap the app body** — it installs the zone that catches async
   gaps. Omitting it loses every unhandled async error.

Getting either wrong fails silently — the app just reports less. That silent
failure mode is worth a dedicated page.

---

## 3. New DartNative sections — draft content

Files land in `telling/assets/docs/sections/dartnative/`. Drafts below for review.

### 3a. `dartnative/getting_started.md`

````markdown
# Getting Started with DartNative

`telling_kit` is the DartNative edition of `telling_logger`. Same API, same wire
format, same dashboard — code written against the Flutter SDK ports by changing
one import.

## Install

```yaml
dependencies:
  telling_kit:
    hosted: https://dartpub.dev
    version: ^1.0.0
```

```sh
dn pub get
```

`dn pub get` picks up the plugin and generates the registrant for you. Nothing
to link: no `.xcframework`, no `.aar`, no podspec, no gradle module.

## Bootstrap

Read [Bootstrap & Crash Capture](bootstrap.md) before wiring this up — the
ordering matters and is not optional.

```dart
import 'package:dartnative/dartnative.dart';
import 'dartnative_plugin_registrant.dart';
import 'package:telling_kit/telling_kit.dart';

void main() {
  // FIRST line: platform bindings + plugin FFI symbols.
  DartNativePluginRegistrant.registerAll();

  // Before anything else can throw.
  Telling.instance.armCrashCapture();

  // Wraps the app body so async errors keep their user context.
  Telling.instance.run(() => runApp(const MyApp()));
}

Future<void> startTelling(String apiKey) async {
  await Telling.instance.init(apiKey, enableDebugLogs: true);

  // Only now that the SDK can receive them.
  Telling.instance.enableCrashReporting();
}
```

## First events

```dart
Telling.instance.event('button_clicked', properties: {
  'button_name': 'Sign Up',
  'screen': 'Landing Page',
});

try {
  await processPayment();
} catch (error, stackTrace) {
  Telling.instance.captureException(
    error: error,
    stackTrace: stackTrace,
    context: 'payment_processing',
    metadata: {'amount': 29.99},
  );
}
```
````

### 3b. `dartnative/bootstrap.md` — the dedicated section that matters

````markdown
# Bootstrap & Crash Capture

How DartNative reports uncaught errors, and why the order is different from
Flutter.

## Why this is not the same as Flutter

`telling_logger` installs its handlers in `enableCrashReporting()` and you call
it after `init()`:

```dart
// Flutter — telling_logger
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Telling.instance.init('YOUR_API_KEY');
  Telling.instance.enableCrashReporting();
  runApp(const MyApp());
}
```

```dart
// DartNative — telling_kit
void main() {
  DartNativePluginRegistrant.registerAll();
  Telling.instance.armCrashCapture();
  Telling.instance.run(() => runApp(const MyApp()));
}
```

Two differences, and **both fail silently if you get them wrong** — the app
simply reports less, with no error to tell you.

## 1. Arm before you initialise

`armCrashCapture()` installs an `Isolate.addErrorListener` over a
`RawReceivePort`. It must run before `init()` so that anything thrown during
startup is buffered rather than lost.

This is *stronger* than Flutter's `PlatformDispatcher.instance.onError`, which
only sees errors raised inside a zone — the isolate listener also catches a
synchronous throw inside `main()` itself.

```dart
// Wrong: a throw here reaches nobody.
Future<void> main() async {
  await Telling.instance.init(apiKey);   // awaits…
  throw StateError('boom');              // …lost
}

// Right: armed first, buffered, flushed once init completes.
Future<void> main() async {
  Telling.instance.armCrashCapture();
  await Telling.instance.init(apiKey);
  Telling.instance.enableCrashReporting();
}
```

## 2. Wrap the app body

`run()` installs a `runZonedGuarded` zone. It catches the async gaps the isolate
reports with no user context — a `Future` with no `errorHandler`, a bare `await`
that throws.

```dart
// Wrong: async errors reach no handler.
void main() {
  DartNativePluginRegistrant.registerAll();
  Telling.instance.armCrashCapture();
  runApp(const MyApp());
}

// Right
void main() {
  DartNativePluginRegistrant.registerAll();
  Telling.instance.armCrashCapture();
  Telling.instance.run(() => runApp(const MyApp()));
}
```

`run()` is a **no-op passthrough** when crash reporting was never enabled, so
calling it unconditionally is safe.

If your app already owns a zone, forward into
`TellingCrashReporter.handleZoneError` rather than nesting a second zone.

## One crash, one report

A fatal error is commonly caught by **both** paths — an error propagating out of
`runZonedGuarded` still reaches the isolate. Crashes are fingerprinted by type +
message + top stack frame, and repeats inside a 2-second window collapse, so a
single crash produces a single report.

## Layout failures are warnings

`RenderFlex overflowed`, `constraints`, `disposed` and friends are classified as
**warnings**, not fatal — the same heuristic the Flutter SDK uses, so a dashboard
keeps separating layout noise from real crashes.

## Verification

Confirm it works without waiting for a crash:

```dart
// In debug builds
Telling.instance.log('crash pipeline armed', level: LogLevel.info);
Telling.instance.captureException(
  error: StateError('test'),
  context: 'manual_verification',
);
await Telling.instance.flush();
```

Both should appear in the dashboard immediately.
````

### 3c. `dartnative/screen_tracking.md`

````markdown
# Screen Tracking

Flutter's `telling_logger` ships observers. DartNative has **no observer hook**,
so screens are reported explicitly.

## Flutter

```dart
// MaterialApp
MaterialApp(
  navigatorObservers: [Telling.instance.screenTracker],
  home: HomeScreen(),
);

// go_router
final router = GoRouter(
  observers: [Telling.instance.goRouterScreenTracker],
  routes: [...],
);
MaterialApp.router(routerConfig: router);
```

## DartNative

DartNative's `NavigatorObserver` is an empty class and `App.navigatorObserver`
is never invoked, so there is nothing to subclass. The Flutter-compatible name
still exists so imported code compiles — it just is never called.

```dart
Telling.instance.screenView('race_detail');
```

Call it when your route pushes.

## Behaviour

Identical once reported: re-entering the current screen is ignored, and time on
the previous screen is logged automatically.
````

### 3d. `dartnative/device_metadata.md`

````markdown
# Device Metadata

`telling_kit` ships **no native code**. No `.xcframework`, no `.aar`, no podspec,
no gradle module — adding it costs nothing at build time.

## Where the data comes from

Both platforms expose what `device_info_plus` reports through **libc**, which
`DynamicLibrary.process()` resolves directly:

| Platform | Call | Yields |
| --- | --- | --- |
| Apple | `sysctlbyname("hw.machine")` | `iPhone17,1` — the same string `IosInfo.utsname.machine` returns |
| Android | `__system_property_get("ro.product.model")` + `ro.product.manufacturer` | joined as `AndroidInfo` formats them |

Because the Apple string matches `IosInfo.utsname.machine` exactly, devices
group identically across Flutter and DartNative apps in the same dashboard.

## Dependency substitution

| `telling_logger` | `telling_kit` |
| --- | --- |
| `shared_preferences` | `dartnative_shared_preferences` |
| `package_info_plus` | `dartnative_system` (`PackageInfo`) |
| `device_info_plus` | *(none — libc over `dart:ffi`)* |

## Failure behaviour

Every lookup degrades to `null`. Observability must never be the thing that takes
an app down.
````

---

## 4. Revisions to existing Flutter sections

These stay Flutter-specific but should acknowledge the DartNative alternative.

| File | Change |
| --- | --- |
| `overview.md:3` | "SDK for Flutter applications" → name both SDKs |
| `overview.md:13` | "unhandled **Flutter** framework and platform errors" → describe both capture mechanisms |
| `overview.md:23` | ⚠️ **"Cross-Platform – iOS, Android, Web, macOS, Windows, Linux"** — `telling_kit` is **iOS + Android only**. Do not overclaim. Rewrite as a per-SDK table. |
| `getting_started.md` | Add a link to the DartNative counterpart; keep Flutter install as-is |
| `advanced_features.md:85-102` | **Split out** the observer snippet to `flutter_screen_tracking.md` |
| `widget_tracking.md` | `.nowTelling()` is identical in both — add a one-line note, no changes |
| `app_config.md:11-18` | iOS/Android store min-version fields assume an app-store binary; clarify Flutter-only |
| `core_concepts.md` | Tables reference Flutter terminology; add "same in both" markers |
| `funnel_tracking.md`, `configuration.md`, `best_practices.md` | No Flutter assumptions — leave alone |

**Delete** `assets/docs/README.md` — 711 lines bundled as an asset but never
rendered (`docs_screen.dart:36-83` only lists `sections/*.md`). Pure bundle
weight.

---

## 5. Landing page

`lib/features/auth/landing_screen.dart`

### Badge — `_buildFlutterBadge` (L1018-1075) → `_buildSdkBadges`

Current: one `Container` wrapping a `Row` → Flutter icon, label, divider,
`VIEW_ON_PUB.DEV`. Two call sites: **L242** (mobile app layout), **L305** (web).

New: **`Row` on desktop, `Column` on mobile.** Two separate tap targets because
they link to different registries.

| Badge | Label | Target | Style |
| --- | --- | --- | --- |
| Flutter | `BUILT_FOR_FLUTTER` | `pub.dev/packages/telling_logger` | existing `#02569B` / `#54C5F8` |
| DartNative | `BUILT_FOR_DARTNATIVE` | `dartpub.dev/plugins/telling_kit` | `dnSpectrum` border, gold label |

Mobile collapses each to `PUB.DEV` / `DARTPUB.DEV`.

The spectrum border needs a `ShaderMask` or a custom `Paint` with a
`GradientBorder`; Flutter has no built-in gradient border.

### Copy

| Line | Current | Change |
| --- | --- | --- |
| L1043 | `BUILT_FOR_FLUTTER` | → two badges |
| L1086 | `Made with Flutter & 💙 by ` | → `Made with Flutter, DartNative & 💙 by ` |
| L531-532, L544-546, L609, L872 | body copy | Flutter is never named; no change required |
| L347-365 | feature cards (`REAL-TIME_SURVEILLANCE`, `DATA_INTELLIGENCE`, `SECURE_DEPLOYMENT`, `RAPID_RESPONSE`) | framework-neutral; no change |

The site's aerospace/tactical voice is framework-neutral and survives this
change intact — that is the main reason the landing page is cheap to update and
the docs are the expensive part.

---

## 6. The DartNative mark — open decision

Flutter uses `Icons.flutter_dash`. DartNative has no Material equivalent.

| Option | Notes |
| --- | --- |
| **A. Rasterize `dn-logo-transparent.svg` to PNGs** in `assets/images/` at web + iOS + Android densities | **Recommended.** No new dependency, safest for the route everyone lands on. |
| B. Add `flutter_svg` | Cleanest, but a new dependency in the app that boots `/landing`. |
| C. Text-only badge | Cheapest, but the two badges then differ in more than colour. |

Not yet applied to any mockup — §1 is the palette only.

---

## 7. Compliance & mirror surfaces

### Privacy policy — **needs a real read, not find-and-replace**

`lib/features/auth/privacy_policy_screen.dart`

- L86 — *"**telling_logger SDK**: A Flutter package that developers integrate…"*
- L108 — *"The telling_logger SDK (integrated into your Flutter apps) collects:"*

A second SDK posting to the same backend is a **data-processing change**, not
wording. `telling_kit` transmits the same categories, but the named processor
changes, and the policy should say both SDKs by name.

### Must move in lockstep

| Surface | Why |
| --- | --- |
| `telling_logger/README.md` | the pub.dev page. Currently Flutter-only throughout (L5, 7, 13, 43, 61, 65, 507, 511, 516, 620, 658) |
| `telling_logger/pubspec.yaml:2-4` | pub.dev description says "…SDK for Flutter applications." |
| `telling/ios_release_metadata.md:10` | App Store promo text: "…Built for Flutter." |
| `telling/README.md` L3, 20, 44 | developer-facing |

`telling_logger` is at **1.4.8** with 35 published versions; changes land on the
next release, not retroactively.

---

## 8. Phases

| # | Phase | Risk | Notes |
| --- | --- | --- | --- |
| 0 | ~~Branch; baseline~~ | — | Done — branch `feat/dartnative-site` off `feat/ai` |
| 1 | **Foundations** — `AppColors` tokens; `manifest.json`; `index.html` meta/OG | Low | **Done** |
| 2 | **Badge** — dual SDK badges, spectrum border, rasterised mark | Medium | **Done** — Option A (rasterise) taken |
| 3 | **Docs IA** — grouped sidebar; split screen tracking; delete dead README | Medium | **Done** — see note below |
| 4 | **New DartNative sections** — four files | Low | **Done** |
| 5 | **Revise Flutter sections** — `overview.md` platform claim | Low | **Done** |
| 6 | **Privacy + mirror** — §7 | **High** | **Not done — needs your legal read** |
| 7 | `flutter build web` → serve `build/web` → Netlify Drop | Low | Per §9 |

### Correction: grouping did not require reworking PREVIOUS/NEXT

This plan predicted that grouping the sidebar would break
`_buildFooterNavigation` (`docs_screen.dart:527-621`) because it walks a flat
section list. **That was wrong, and the outcome is better than planned.**

Everything positional reads a single flat `_sections` list. Making that list a
derived view over `_groups` means markdown loading, the breadcrumb and
PREVIOUS/NEXT all keep the same index arithmetic unchanged. Grouping became a
*presentation* concern only — the sidebar renders group headers while iterating
the flat list. PREVIOUS/NEXT still walks linearly across group boundaries, which
is both predictable and correct.

### Assets are declared non-recursively — twice

`flutter build web` treats a directory asset entry as **the files directly
inside it**, not a recursive walk. Two entries exist only because of this, and a
third was needed for the new work:

```yaml
- assets/docs/
- assets/docs/sections/        # not covered by assets/docs/
- assets/docs/sections/dartnative/   # not covered by assets/docs/sections/
```

The DartNative pages would have 404'd at runtime without the third line — and
because they load lazily, that failure would only appear when a visitor clicked
into the group. `flutter analyze` does not catch it.

Phase 3 carries a real trap: `_buildFooterNavigation` (L527-621) walks the flat
section list for PREVIOUS/NEXT. Grouping breaks that and needs rewriting, not
patching.

---

## 9. Pre-launch checklist

Checked against a **release build served from `build/web`**, not `flutter run` —
the dev compiler and `dart2js` disagree often enough to matter for a landing page.

- [ ] `build/web/_redirects` present (else every non-root route 404s)
- [ ] Badge tested at the ~420px stack breakpoint
- [ ] `/landing`, `/docs`, `/privacy` deep-linked directly — not just via nav
- [ ] Docs sidebar scrolls correctly with 3 groups / 14 sections
- [ ] PREVIOUS/NEXT correct across group boundaries
- [ ] `overview.md` platform claims accurate for **each** SDK (iOS+Android vs 6 platforms)
- [ ] Privacy policy names both SDKs
- [ ] `manifest.json` description + theme colours off defaults
- [ ] Every DartNative snippet compiles against `telling_kit@1.0.0`
- [ ] OG/social card re-crawled after deploy
- [ ] Drop `build/web/` into Netlify Drop

---

## 10. Open decisions

1. **DartNative mark** — §6. Blocks Phase 2.
2. **`overview.md:23` framing** — does the landing page lead with Flutter and
   mention DartNative, or present them as equals from the top? Affects hero,
   overview, and first impression of the launch.
3. **Phase 6 timing** — privacy policy is a legal review and may need to land
   before the announcement rather than with it.
4. **DartNative channel** — is DartNative announced publicly at launch, or
   documented quietly for `telling_kit` adopters first?