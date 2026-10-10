# =========================================================
# ProGuard / R8 rules for Rojo Camp (Flutter release build)
# =========================================================

# ── Flutter Engine & Plugins ─────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── Google ML Kit (Barcode Scanning) ─────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }
-keep class com.google.mlkit.common.** { *; }
-dontwarn com.google.mlkit.**

# ── mobile_scanner plugin ────────────────────────────────
-keep class dev.steenbakker.mobile_scanner.** { *; }

# ── Google Play Services (dibutuhkan ML Kit) ─────────────
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── AndroidX ─────────────────────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**

# ── AndroidX Camera (CameraX, dipakai mobile_scanner) ────
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# ── AndroidX Lifecycle ───────────────────────────────────
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# ── Kotlin ───────────────────────────────────────────────
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**

# ── General: Keep annotations ────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ── Prevent stripping of native methods ──────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── Keep Parcelable implementations ──────────────────────
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# ── Keep Serializable classes ────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ── Keep R (resource) classes ────────────────────────────
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ── Suppress common warnings ────────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.**
-dontwarn com.google.errorprone.annotations.**

# ── share_plus plugin ────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ── FileProvider (dibutuhkan share_plus untuk share file) ─
-keep class androidx.core.content.FileProvider { *; }
-keep class dev.fluttercommunity.plus.share.ShareFileProvider { *; }
-keep class dev.fluttercommunity.plus.share.SharePlusPendingIntent { *; }