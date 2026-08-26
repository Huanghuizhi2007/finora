import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.finora.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.finora.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = System.getenv("ANDROID_VERSION_CODE")?.toIntOrNull() ?: flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val localStoreFile = keystoreProperties["storeFile"] as String?
        val envKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
        val keystorePath = if (!localStoreFile.isNullOrBlank()) {
            localStoreFile
        } else {
            envKeystorePath
        }
        if (!keystorePath.isNullOrBlank()) {
            create("release") {
                storeFile = file(keystorePath)
                storePassword = keystoreProperties["storePassword"] as String?
                    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
                storeType = if (keystorePropertiesFile.exists()) "JKS" else "PKCS12"
                keyAlias = keystoreProperties["keyAlias"] as String?
                    ?: System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = keystoreProperties["keyPassword"] as String?
                    ?: System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingConfigs.findByName("release") != null) {
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
