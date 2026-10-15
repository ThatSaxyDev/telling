# Device Metadata (DartNative)

`telling_kit` ships **no native code**. No `.xcframework`, no `.aar`, no
podspec, no gradle module — adding it costs nothing at build time, and there is
no binary to compile when your team pulls the dependency.

## Where the data comes from

Both platforms expose what `device_info_plus` reports through **libc**, which
`DynamicLibrary.process()` resolves directly:

| Platform | Call | Yields |
| --- | --- | --- |
| Apple | `sysctlbyname("hw.machine")` | `iPhone17,1` |
| Android | `__system_property_get("ro.product.model")` + `ro.product.manufacturer` | joined as `AndroidInfo` formats them |

The Apple string is byte-identical to what `IosInfo.utsname.machine` returns, so
devices group the same way in the dashboard whether they reported from a Flutter
or a DartNative build.

## Dependency substitution

| `telling_logger` (Flutter) | `telling_kit` (DartNative) |
| --- | --- |
| `shared_preferences` | `dartnative_shared_preferences` |
| `package_info_plus` | `dartnative_system` → `PackageInfo` |
| `device_info_plus` | *(none — libc via `dart:ffi`)* |
| `url_launcher` | *(not used)* |

If you are porting an app, this table is the whole dependency migration.

## Failure behaviour

Every lookup degrades to `null` on failure. Observability must never be the thing
that takes an app down — a device probe that throws would turn your error
reporting into the crash.

## Platforms

`telling_kit` targets **iOS and Android**. That is the platform ceiling of the
DartNative SDK, and it is why there is no desktop or web story on this page.
`telling_logger` remains the choice for Flutter web, macOS, Windows and Linux —
see [Which SDK?](../choosing_an_sdk.md).