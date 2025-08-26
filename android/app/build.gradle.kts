plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Firebase dependencies without versions
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}

android {
    namespace = "com.example.we_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    
    // ...existing code...
    defaultConfig {
        applicationId = "com.example.we_chat"
        minSdkVersion(flutter.minSdkVersion)
        targetSdkVersion(flutter.targetSdkVersion)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
// ...existing code...


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
