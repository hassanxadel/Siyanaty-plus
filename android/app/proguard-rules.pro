# Add project specific ProGuard rules here.

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Ignore deprecated FirebaseInstanceId (replaced by FirebaseMessaging)
-dontwarn com.google.firebase.iid.FirebaseInstanceId
-dontnote com.google.firebase.iid.FirebaseInstanceId

# ML Kit Text Recognition - ignore optional language-specific recognizers
# These are optional language packs that aren't included by default
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontnote com.google.mlkit.vision.text.chinese.**
-dontnote com.google.mlkit.vision.text.devanagari.**
-dontnote com.google.mlkit.vision.text.japanese.**
-dontnote com.google.mlkit.vision.text.korean.**

# Specific classes mentioned in R8 errors
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder

# Keep ML Kit classes that are actually used
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin classes and metadata
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotation default values
-keepattributes AnnotationDefault

# Keep line numbers for stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep plugin classes that use Kotlin
-keep class dev.flcommunity.** { *; }
-keep class io.flutter.plugins.deviceinfo.** { *; }
-keep class io.flutter.plugins.share.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class be.tramckrijte.workmanager.** { *; }

# Allow R8 to continue with missing optional classes
# These are optional ML Kit language packs and deprecated Firebase classes
-ignorewarnings
