# R8 / ProGuard rules for release builds.

# pusher_channels_flutter and its transitive deps reference SLF4J's binding
# class reflectively. There is no SLF4J implementation on the runtime classpath,
# so R8 flags it as missing and fails the release build. The reference is never
# actually executed on Android, so suppress the warning rather than shipping a
# stub binding.
-dontwarn org.slf4j.impl.StaticLoggerBinder