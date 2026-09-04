import java.util.Properties

// T18: imzalama anahtari repo disinda; `key.properties` .gitignore'da.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

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

    // `debugSimulate` yalniz debug derlemede calisir (02-mimari §6); AGP 8+'da
    // BuildConfig ureticisi acikca istenmeli.
    buildFeatures {
        buildConfig = true
    }

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

    signingConfigs {
        create("release") {
            val storePath = keystoreProperties.getProperty("storeFile")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // `key.properties` yoksa (temiz klon) debug imzasiyla derlenir.
            signingConfig = if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
