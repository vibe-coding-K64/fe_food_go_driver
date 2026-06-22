# AutoValue classes needed by Mapbox SDK
-keep class com.google.auto.value.** { *; }
-keep class * extends com.google.auto.value.AutoValue { *; }
-keep class * implements com.google.auto.value.AutoValue$Builder { *; }

# Mapbox SDK
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**
