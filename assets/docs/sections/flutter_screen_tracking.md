# Screen Tracking (Flutter)

`telling_logger` reports screens automatically through a `NavigatorObserver`.
Add the tracker to your root widget and every push is recorded — screen name,
previous screen, and time spent on the screen you just left.

> DartNative has no observer hook. If you are on `telling_kit`, see
> [Screen Tracking (DartNative)](dartnative/screen_tracking.md).

## With MaterialApp

```dart
MaterialApp(
  navigatorObservers: [
    Telling.instance.screenTracker,
  ],
  home: HomeScreen(),
);
```

## With go_router

```dart
final router = GoRouter(
  observers: [
    Telling.instance.goRouterScreenTracker,
  ],
  routes: [...],
);

MaterialApp.router(
  routerConfig: router,
);
```

## What gets recorded

- **Screen name** — the route's name
- **Previous screen** — so time-on-screen can be attributed correctly
- **Time spent on the previous screen**
- **Session context** — tied to the session, so funnels and retention line up

Re-entering the current screen is ignored rather than double-counted.

## Manual reporting

If you need to report a screen the router cannot see — a modal, a tab inside a
page, a deep link resolved before the router mounts — report it directly:

```dart
Telling.instance.screenView('payment_sheet');
```

Manual and automatic tracking compose; there is no conflict if you report a
route yourself as well.

## Widget-level tracking

For visibility of individual widgets rather than whole screens, see
[Widget Tracking](widget_tracking.md).