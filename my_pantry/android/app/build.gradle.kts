plugins {
    id("com.android.application")
<<<<<<< Updated upstream
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
=======
    kotlin("android")
    id("com.google.gms.google-services") // Firebase plugin
>>>>>>> Stashed changes
}

android {
    namespace = "com.example.my_pantry" // Replace with your actual package
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.my_pantry"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        ndk {
            version = "27.0.12077973"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

<<<<<<< Updated upstream
flutter {
    source = "../.."
=======
dependencies {
    // Android core libraries
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // Firebase Firestore
    implementation("com.google.firebase:firebase-firestore-ktx:24.11.1")

    // Optional Firebase Analytics (for example)
    implementation("com.google.firebase:firebase-analytics-ktx")

    // Testing libraries
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
>>>>>>> Stashed changes
}
