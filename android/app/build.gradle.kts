plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hospital_management_app"
    compileSdk = 35 // Updated to latest stable
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.hospital_management_app"
        minSdk = 23  // Updated for better Firebase compatibility
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"

        // Enable multidex support for Firebase
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // Optional: Minify and obfuscate for production
            // minifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM - using stable version compatible with Flutter plugins
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // Firebase dependencies (versions managed by BOM)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")

    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}