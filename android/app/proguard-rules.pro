# App-specific R8 rules for release builds.
# The Flutter Gradle plugin already applies proguard-android-optimize.txt and
# its own Flutter embedding rules; Firebase, Play Services and AndroidX ship
# consumer rules inside their AARs. Only add what those do not cover.

# The Flutter embedding references Play Core (deferred components) classes
# that this app does not bundle.
-dontwarn com.google.android.play.core.**
