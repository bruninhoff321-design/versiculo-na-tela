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
        // Jetpack Glance (widget) exige minSdk 21+; 26 dá uma base mais
        // moderna e tranquila para Play Billing/notificações também.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        compose = true
    }
    composeOptions {
        // Se o Gradle reclamar de incompatibilidade de versão aqui, troque
        // por a versão do compilador Compose recomendada para a versão do
        // Kotlin que o `flutter create` instalou neste projeto.
        kotlinCompilerExtensionVersion = "1.5.14"
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
    // Widget nativo (Jetpack Glance) — seções 3, 4, 27 do briefing
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance-material3:1.1.1")

    // Agendamento da preferência de atualização do widget — seção 5
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
