import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.0"
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
android {
    namespace = "net.brings2you.aqim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "net.brings2you.aqim"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        compose = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // ✅ Updated to latest Material Design library with edge-to-edge support
    implementation("com.google.android.material:material:1.14.0-alpha07")
    implementation("androidx.glance:glance:1.2.0-beta01")
    implementation("androidx.glance:glance-appwidget:1.2.0-beta01")
    // ✅ Updated AndroidX Core to latest version for edge-to-edge APIs
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("androidx.work:work-runtime-ktx:2.8.1")

 //implementation("com.google.mediapipe:tasks-vision:0.10.29")
    // implementation("androidx.camera:camera-core:1.5.1")
    // implementation("androidx.camera:camera-camera:1.5.1")
    // implementation("androidx.camera:camera-lifecycle:1.5.1")
    // implementation("androidx.camera:camera-view:1.5.1")
    // implementation("androidx.constraintlayout:constraintlayout:2.2.1")

    // If you want to use the accurate sdk
//    implementation("com.google.mediapipe:tasks-vision:0.10.29")
//    implementation("com.google.mlkit:pose-detection:18.0.0-beta5")
//    implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta5")
}