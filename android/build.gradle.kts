// Top-level build file for Flutter Android project

plugins {
    // Note: Do NOT apply the google-services plugin here at the top-level
    // We just declare the version for subprojects
    id("com.google.gms.google-services") version "4.3.15" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
        // Google Services classpath is optional now if using plugins block
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: standard Flutter build directories
rootProject.buildDir = File(rootProject.projectDir, "../build")
subprojects {
    project.buildDir = File(rootProject.buildDir, project.name)
}

// Standard clean task
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
