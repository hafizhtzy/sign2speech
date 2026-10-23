# Flutter Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# TensorFlow Lite & MediaPipe Native Interop
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.mediapipe.framework.** { *; }
-keep class com.google.mediapipe.tasks.** { *; }

# CameraX Rules
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# App Native Helpers & Channels
-keep class com.example.speech2sign.** { *; }
-keep class com.speech2sign.** { *; }

# FlutterTTS
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# Generic Optimization Attributes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions
-dontwarn java.lang.invoke.**

