# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Firebase specific rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Play Core (ignore missing classes for now)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager**

# Keep model classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flame engine rules
-keep class com.flame.** { *; }

# General Android rules
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**