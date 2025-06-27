plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    kotlin("android")
}

android {
    namespace = "com.example.ubicacionmx_nueva"
    compileSdk = 35 // Actualizado para compatibilidad con plugins
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.ubicacionmx_nueva"
        minSdk = 21
        targetSdk = 35 // Actualizado por consistencia
        versionCode = 1
        versionName = "1.0"
    }
    
    // Configuración para usar nuestra firma de depuración personalizada
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("release") {
            // Cuando estés listo para publicar, aquí configurarás tu firma de release
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
           signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {}