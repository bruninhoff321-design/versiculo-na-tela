import 'package:flutter/material.dart';

/// Azul quase preto e dourado quente para uma leitura calma e acessível.
class AppColors {
  static const claroBg = Color(0xFFEDE9E1);
  static const claroSurface = Color(0xFFFFFFFF);
  static const claroSurface2 = Color(0xFFF5F2EB);
  static const claroInk = Color(0xFF20242B);
  static const claroMuted = Color(0xFF6B6A62);

  static const escuroBg = Color(0xFF0D141E);
  static const escuroSurface = Color(0xFF17212E);
  static const escuroSurface2 = Color(0xFF202D3B);
  static const escuroInk = Color(0xFFFFF8EA);
  static const escuroMuted = Color(0xFFB8C0C8);

  static const accentClaro = Color(0xFFA8763A);
  static const accentEscuro = Color(0xFFF3C55E);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.claroBg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentClaro,
        surface: AppColors.claroSurface,
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Manrope').copyWith(
            bodyMedium: const TextStyle(
                fontFamily: 'Manrope', fontSize: 16, height: 1.4),
            bodyLarge: const TextStyle(
                fontFamily: 'Manrope', fontSize: 18, height: 1.4),
            labelLarge: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700),
            displayLarge: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: AppColors.claroInk,
              height: 1.4,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.claroBg,
        foregroundColor: AppColors.claroInk,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.escuroBg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentEscuro,
        onPrimary: const Color(0xFF1C1A15),
        surface: AppColors.escuroSurface,
        surfaceContainerHighest: AppColors.escuroSurface2,
        onSurface: AppColors.escuroInk,
      ),
      textTheme: base.textTheme.apply(fontFamily: 'Manrope').copyWith(
            bodyMedium: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                height: 1.5,
                color: AppColors.escuroInk),
            bodyLarge: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                height: 1.5,
                color: AppColors.escuroInk),
            labelLarge: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700),
            displayLarge: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 28,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: AppColors.escuroInk,
              height: 1.4,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.escuroBg,
        foregroundColor: AppColors.escuroInk,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.escuroBg,
        indicatorColor: AppColors.accentEscuro.withOpacity(.17),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
              fontFamily: 'Manrope', fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentEscuro,
          foregroundColor: const Color(0xFF1C1A15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
              fontFamily: 'Manrope', fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  /// Cores de fundo/texto de cada tema VISUAL DO WIDGET (seção 20 — isto é
  /// diferente do tema claro/escuro do app; é a paleta que o usuário escolhe
  /// para o widget da tela inicial).
  static (Color bg, Color fg) widgetThemeColors(String widgetThemeName) {
    switch (widgetThemeName) {
      case 'transparente':
        return (Colors.transparent, const Color(0xFFFFFFFF));
      case 'escuro':
        return (const Color(0xFF1B1D22), const Color(0xFFF3EFE4));
      case 'papel':
        return (const Color(0xFFEDE3CC), const Color(0xFF3A3120));
      case 'gradiente':
        return (const Color(0xFF3A2E55), const Color(0xFFFBF3E7));
      case 'elegante':
        return (const Color(0xFF12141A), const Color(0xFFD9A857));
      case 'ceu':
        return (const Color(0xFF2B3A55), const Color(0xFFFBFAF6));
      case 'claro':
      default:
        return (const Color(0xFFF7F4EC), const Color(0xFF20242B));
    }
  }
}
