plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.example.mindflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    defaultConfig {
        applicationId = "com.example.mindflow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    val releaseStorePassword = System.getenv("KEYSTORE_PASSWORD")
    val releaseKeyPassword = System.getenv("KEY_PASSWORD")
    val releaseSigningReady = !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank() &&
        file(System.getenv("KEYSTORE_PATH") ?: "keystore.jks").exists()
    if (releaseSigningReady) {
        signingConfigs {
            create("release") {
                keyAlias = System.getenv("KEY_ALIAS") ?: "mindflow_release_key"
                keyPassword = releaseKeyPassword
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "keystore.jks")
                storePassword = releaseStorePassword
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (releaseSigningReady) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
flutter {
    source = "../.."
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
