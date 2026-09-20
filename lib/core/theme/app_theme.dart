import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mesma linguagem visual do protótipo web validado antes desta etapa:
/// tons de pedra/pergaminho + um único acento âmbar, serifada Fraunces para
/// o versículo (o "momento principal" da tela) e Manrope para a interface.
/// Sem clichê de app "cristão" (nada de dourado brilhante, pomba, cruz).
class AppColors {
  static const claroBg = Color(0xFFEDE9E1);
  static const claroSurface = Color(0xFFFFFFFF);
  static const claroSurface2 = Color(0xFFF5F2EB);
  static const claroInk = Color(0xFF20242B);
  static const claroMuted = Color(0xFF6B6A62);

  static const escuroBg = Color(0xFF14161C);
  static const escuroSurface = Color(0xFF1D2027);
  static const escuroSurface2 = Color(0xFF22252D);
  static const escuroInk = Color(0xFFEDE6D8);
  static const escuroMuted = Color(0xFFA29E92);

  static const accentClaro = Color(0xFFA8763A);
  static const accentEscuro = Color(0xFFD9A857);
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
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fraunces(
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
        surface: AppColors.escuroSurface,
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fraunces(
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
    );
  }

  /// Cores de fundo/texto de cada tema VISUAL DO WIDGET (seção 20 — isto é
  /// diferente do tema claro/escuro do app; é a paleta que o usuário escolhe
  /// para o widget da tela inicial).
  static (Color bg, Color fg) widgetThemeColors(String widgetThemeName) {
    switch (widgetThemeName) {
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
