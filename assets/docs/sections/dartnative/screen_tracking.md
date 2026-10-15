# Screen Tracking (DartNative)

Flutter's `telling_logger` ships observers. DartNative has **no observer hook**,
so screens are reported explicitly.

## Flutter

```dart
// MaterialApp
MaterialApp(
  navigatorObservers: [Telling.instance.screenTracker],
  home: HomeScreen(),
);
```

```dart
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
still exists so imported code **compiles** — it is simply never called. Do not
wire it up expecting it to work.

Report screens yourself:

```dart
Telling.instance.screenView('race_detail');
```

Call it when the route is pushed.

```dart
void openDetail(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const RaceDetail(),
    ),
  );
  Telling.instance.screenView('race_detail');
}
```

## Behaviour

Once reported, both SDKs behave identically:

- Re-entering the current screen is ignored.
- Time spent on the previous screen is logged automatically.
- Screen name, previous screen and session context are all captured.

## Widget-level tracking still works

`.nowTelling()` was ported across unchanged, so per-widget visibility tracking is
available on DartNative exactly as in Flutter — see
[Widget Tracking](../widget_tracking.md).