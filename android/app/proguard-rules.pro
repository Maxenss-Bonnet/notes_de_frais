# Flutter-specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Rules for Google ML Kit Text Recognition
-keep public class com.google.mlkit.** {
    public *;
}
-dontwarn com.google.mlkit.**

-keep public class com.google.android.gms.internal.mlkit_vision_text_common.** {
    public *;
}
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**