# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Gson rules (often needed for JSON serialization/deserialization)
-keep class com.google.gson.** { *; }

# Prevent warnings for GMS
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }
