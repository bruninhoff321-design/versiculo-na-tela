plugins {
    id("com.android.application")
    id("kotlin-android")
    // O plugin do Flutter precisa vir DEPOIS dos plugins Android/Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.versiculonatela.app"
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
        applicationId = "com.versiculonatela.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Assina o build de release com a chave de DEBUG por enquanto.
            // Isso é o que permite `flutter build apk --release` gerar um
            // .apk instalável sem configurar nada extra — ótimo para testar
            // no seu próprio aparelho. ANTES de publicar na Play Store,
            // troque isto por uma signing config de verdade (keystore
            // própria) — a Play Store não aceita um app assinado com a
            // chave de debug.
            signingConfig = signingConfigs.getByName("debug")
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
