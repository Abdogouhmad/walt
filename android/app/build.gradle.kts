import java.util.Properties
import java.io.FileInputStream
import com.android.build.gradle.internal.api.BaseVariantOutputImpl


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kotlin DSL syntax for loading keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// ── Versioning (spec §2) ──────────────────────────────────────────────────
// The versionCode is derived deterministically from the SemVer `versionName`
// (e.g. "0.5.1" → 501, "1.2.43" → 10243) with the formula
// `major*10000 + minor*100 + patch`, so `pubspec.yaml` stays the single source
// of truth and every build of a given tag gets the identical versionCode that
// the OTA manifest and release automation expect.
val pubspecVersionName = flutter.versionName ?: "0.0.0"
val versionParts = pubspecVersionName.split('.').map { it.toIntOrNull() ?: 0 }
val derivedVersionCode =
    versionParts.getOrElse(0) { 0 } * 10000 +
    versionParts.getOrElse(1) { 0 } * 100 +
    versionParts.getOrElse(2) { 0 }

android {
    namespace = "com.example.walt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.example.walt"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = derivedVersionCode
        versionName = pubspecVersionName
        multiDexEnabled = true
    }

    // Stable release keystore. Every release APK must be signed with the SAME
    // key forever — a changed signature forces Android to uninstall before it
    // will "update", and an unsigned release APK fails to install outright
    // (`INSTALL_FAILED_INVALID_APK`). Only defined when `android/key.properties`
    // actually names a storeFile so a broken/missing config never yields a
    // half-initialised signingConfig.
    signingConfigs {
        if (keystoreProperties.getProperty("storeFile") != null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            // Sign with the stable release keystore when provisioned (CI);
            // otherwise fall back to the debug key so `flutter run --release`
            // on a fresh clone still produces an installable APK. The release
            // pipeline (build.sh) REQUIRES the real keystore, so published
            // APKs are never debug- or unsigned.
            val releaseSigning = signingConfigs.findByName("release")
            signingConfig = releaseSigning ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
