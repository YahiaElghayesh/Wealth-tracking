plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yahiaelghayesh.wealth_tracker"
    // flutter.compileSdkVersion (36, this Flutter SDK's own default) is one
    // version behind what flutter_secure_storage's Android plugin requires
    // to compile against -- overridden explicitly rather than left at the
    // Flutter tooling default. compileSdk only affects which API surface is
    // compiled against (backward compatible); targetSdk below is untouched,
    // so runtime behavior on installed devices doesn't change.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications requires this even when scheduled
        // (not just immediate) notifications aren't used — see
        // https://developer.android.com/studio/write/java8-support#library-desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yahiaelghayesh.wealth_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            // A committed, stable debug key rather than the machine-local
            // ~/.android/debug.keystore the Android Gradle Plugin otherwise
            // auto-generates — on CI that file doesn't persist between
            // runs, so every build got a different signature and each new
            // APK required uninstalling the previous one (wiping local
            // data) before it could install. Same key every time means
            // updates install in place instead.
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // WorkManager's own API isn't exposed to this module by the workmanager
    // plugin (it depends on work-runtime as `implementation`, not `api`),
    // but SmsQuickAddActionReceiver needs to enqueue a WorkManager task of
    // its own -- same version the plugin itself pins, for compatibility.
    implementation("androidx.work:work-runtime-ktx:2.11.2")
}

flutter {
    source = "../.."
}
