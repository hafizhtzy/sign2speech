# Flutter Rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# TensorFlow Lite & GPU Delegate
-keep class org.tensorflow.lite.** { *; }
-keepnames class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# MediaPipe Native Interop & Tasks Vision
-keep class com.google.mediapipe.** { *; }
-keepclassmembers class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.mediapipe.framework.** { *; }
-keep class com.google.mediapipe.tasks.** { *; }
-keepclassmembers class com.google.mediapipe.tasks.** {
    native <methods>;
    *;
}

# Protocol Buffers (Crucial: MediaPipe C++ engine accesses message fields via reflection)
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
    <methods>;
}
-keep class com.google.mediapipe.proto.** { *; }
-keepclassmembers class com.google.mediapipe.proto.** {
    <fields>;
    <methods>;
}

# Google Flogger (used internally by MediaPipe for diagnostics)
-keep class com.google.common.flogger.** { *; }
-dontwarn com.google.common.flogger.**

# Native methods retention across all JNI-backed components
-keepclasseswithmembernames class * {
    native <methods>;
}

# CameraX Rules
-keep class androidx.camera.** { *; }
-keepclassmembers class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# App Native Helpers & Channels
-keep class com.example.speech2sign.** { *; }
-keepclassmembers class com.example.speech2sign.** { *; }
-keep class com.speech2sign.** { *; }
-keepclassmembers class com.speech2sign.** { *; }

# FlutterTTS
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# Models and Domain DTOs
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.example.speech2sign.models.** { *; }
-keep class com.speech2sign.models.** { *; }
-keep class speech2sign.** { *; }

# Generic Optimization Attributes
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions
-dontwarn java.lang.invoke.**

# AutoValue, JavaPoet & Annotation Processors (MediaPipe Tasks Vision)
-dontwarn autovalue.shaded.**
-dontwarn autovalue.shaded.com.squareup.javapoet.**
-dontwarn com.google.auto.**
-dontwarn com.google.auto.value.**
-dontwarn com.google.auto.value.processor.**
-dontwarn com.squareup.javapoet.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.processing.**
-dontwarn javax.lang.model.**
-dontwarn javax.tools.**

-keep class autovalue.shaded.** { *; }
-keep class com.google.auto.value.** { *; }
-keep class com.squareup.javapoet.** { *; }

-ignorewarnings


