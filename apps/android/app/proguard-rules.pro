# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Play Core (referenced by Flutter for deferred components)
-dontwarn com.google.android.play.core.**

# Keep Sentry classes
-keep class io.sentry.** { *; }
-keep class io.sentry.android.** { *; }
-dontwarn io.sentry.**

# Keep SharedPreferences
-keep class androidx.datastore.** { *; }

# Keep http client
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
