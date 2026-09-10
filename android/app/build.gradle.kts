plugins {
    id("com.android.application")
    id("kotlin-android")
    // id("com.google.gms.google-services") // Temporarily disabled for local dev (no google-services.json)
    // Flutter Gradle Plugin (must be last)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.business_card_app"
    compileSdk = 36 // Updated to 36 as required by mobile_scanner

    // ✅ Force correct NDK version (fix plugin error)
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.business_card_app"
        // 23 for mobile_scanner; google_mlkit_text_recognition needs at least 21,
        // so pin it rather than inheriting whatever flutter.minSdkVersion becomes.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        // On this Flutter version these two are methods on FlutterExtension,
        // not fields like minSdkVersion/targetSdkVersion above.
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
    }

    buildTypes {
        release {
            // Debug signing for now (ok for development)
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Enable core library desugaring
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}

flutter {
    source = "../.."
}
