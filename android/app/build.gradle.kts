plugins {
    id("com.android.application")
    id("kotlin-android")
    // O plugin do Flutter precisa vir DEPOIS dos plugins Android/Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.versiculonatela.app"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.versiculonatela.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Chave fixa de assinatura. O GitHub Actions grava o arquivo a partir
    // dos "secrets" do repositório. Sem ela, usamos a chave de debug — mas
    // aí cada compilação sai com uma assinatura diferente e o celular não
    // aceita instalar a atualização por cima da versão anterior.
    val releaseKeystore = System.getenv("ANDROID_KEYSTORE_PATH")
    signingConfigs {
        if (releaseKeystore != null && file(releaseKeystore).exists()) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Agendamento da preferência de atualização do widget — seção 5
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
