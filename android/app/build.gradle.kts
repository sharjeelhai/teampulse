/*
 Module-level Gradle (Kotlin DSL) for the Android app module.
 Configured for Flutter + Firebase compatibility.
*/

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Apply Google services plugin here
}

android {
    namespace = "com.example.teampulse"
    compileSdk = 36 // Replace with your Flutter compileSdkVersion if needed

    defaultConfig {
        applicationId = "com.example.teampulse"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // Replace with your Flutter targetSdkVersion
        versionCode = 1
        versionName = "1.0"

        vectorDrawables {
            useSupportLibrary = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase dependencies with specific versions
    implementation("com.google.firebase:firebase-analytics-ktx:21.6.2")
    implementation("com.google.firebase:firebase-auth-ktx:22.3.1")
    implementation("com.google.firebase:firebase-firestore-ktx:24.11.1")
    implementation("com.google.firebase:firebase-messaging-ktx:23.4.1")

    // Example: Add other dependencies here
    // implementation("com.google.firebase:firebase-storage-ktx")
}
