# Which SDK?

Telling ships **two SDKs** for one dashboard. Pick by your framework, not by
feature set — they are the same product on different runtimes.

| | Flutter | DartNative |
| --- | --- | --- |
| Package | `telling_logger` | `telling_kit` |
| Registry | [pub.dev](https://pub.dev/packages/telling_logger) | [dartpub.dev](https://dartpub.dev/plugins/telling_kit) |
| Version | `^1.4.8` | `^1.0.0` |
| Platforms | iOS, Android, Web, macOS, Windows, Linux | iOS, Android |
| Native code | 4 Flutter plugins | none |
| Dashboard | same | same |

Both send to the same backend and appear in the same project, so you can mix
them — a Flutter admin app and a DartNative client, say — without any extra
setup.

## Is it really the same API?

Yes, for everything except three things:

1. **[Bootstrap order](dartnative/bootstrap.md)** — DartNative requires
   `armCrashCapture()` before `init()` and `run()` around the app body.
2. **[Screen tracking](dartnative/screen_tracking.md)** — Flutter gets
   observers; DartNative has no observer hook, so you call `screenView()`
   explicitly.
3. **Widgets** — Flutter's `MaterialApp` is DartNative's `App`, and
   `ElevatedButton` is `Button`. That is the framework, not Telling.

Everything else — `log`, `event`, `trackFunnel`, `captureException`, the
`setUser*` family, `flush`, `checkVersion`, `TellingTryCatch`, `LogLevel`,
`LogType`, `.nowTelling()` — is identical. The pages under **BOTH SDKs** apply
to either.

## Installing

**Flutter**

```yaml
dependencies:
  telling_logger: ^1.4.8
```

```sh
flutter pub get
```

**DartNative**

```yaml
dependencies:
  telling_kit:
    hosted: https://dartpub.dev
    version: ^1.0.0
```

```sh
dn pub get
```

Note the `hosted:` key. DartNative packages live on **dartpub.dev**, not
pub.dev, so the registry has to be named explicitly.

## Not sure which framework you are on?

If you build with `flutter pub get` and your pubspec has `flutter: sdk: flutter`,
you want `telling_logger`. If you build with `dn pub get` and your pubspec
depends on `dartnative`, you want `telling_kit`.