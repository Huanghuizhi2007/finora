# Add project specific ProGuard rules here.

# Google ML Kit text recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-dontwarn com.google.mlkit.vision.text.**
