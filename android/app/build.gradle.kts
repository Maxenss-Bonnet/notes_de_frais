import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
// Le chemin est relatif à la racine du projet Android
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.example.notes_de_frais"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storePassword = keyProperties.getProperty("storePassword")
                storeFile = if (keyProperties.getProperty("storeFile") != null) {
                    // Le chemin du keystore est relatif au dossier 'android/app'
                    file(keyProperties.getProperty("storeFile"))
                } else {
                    null
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.notes_de_frais"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Activation du MultiDex
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Utiliser la configuration de signature pour la version "release"
            signingConfig = signingConfigs.getByName("release")

            // Activer R8 pour la réduction de code et lier les règles
            isMinifyEnabled = true
            // Voici la correction :
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}