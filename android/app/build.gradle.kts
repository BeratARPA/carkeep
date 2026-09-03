plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.beratarpa.carkeep"
    // CLAUDE.md: compileSdk/targetSdk = kurulu en yüksek stable (android-36).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.beratarpa.carkeep"
        // K-14: bildirim kanalları API 26+.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // T18'de kendi imzalama yapılandırması gelir.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // 07-android-notlar §1: başka bağımlılık yok.
    // core 1.19.0 `minCompileSdk=37` istiyor; kurulu en yüksek stable platform
    // android-36 (AGP 9.1.0 için de tavsiye edilen üst sınır 36). 1.18.0 = son
    // compileSdk 36 uyumlu sürüm.
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.work:work-runtime-ktx:2.11.2")

    // 07-android-notlar §9: JVM testleri Android sınıfı kullanmaz; `org.json`
    // Android'e gömülü olduğu için host JVM'de ayrıca gerekir. Robolectric yok.
    testImplementation("org.json:json:20260814")
    testImplementation(kotlin("test"))
}

flutter {
    source = "../.."
}
