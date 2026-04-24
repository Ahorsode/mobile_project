plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project_part1_v1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.project_part1_v1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    

    packaging {
        jniLibs {
            // This replaces 'doNotStrip' and fixes the binary corruption error
            keepDebugSymbols.add("**/*.so")
        }
    }

    buildTypes {
        getByName("release") {
            // ... release settings
        }
        getByName("debug") {
            // ... debug settings
        }
    }
}


flutter {
    source = "../.."
}

// Copy prebuilt serious_python native libs from pub cache into the app jniLibs
// This ensures valid libpythonbundle.so is packaged with the APK and avoids
// repeated download/corruption issues during the plugin's build step.
val localAppData = System.getenv("LOCALAPPDATA") ?: System.getenv("HOME")
if (localAppData != null) {
    val pubCachePath = file("$localAppData/Pub/Cache/hosted/pub.dev/serious_python_android-0.9.9/android/src/main/jniLibs")
    if (pubCachePath.exists()) {
        tasks.register<Copy>("copySeriousPythonJniLibs") {
            from(pubCachePath)
            into(file("src/main/jniLibs"))
            rename { fileName ->
                if (fileName == "libserious_python.so") "libpyjni.so" else fileName
            }
        }
        tasks.named("preBuild") {
            dependsOn("copySeriousPythonJniLibs")
        }
    }
}
