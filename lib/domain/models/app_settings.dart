/// Preferência de frequência de atualização (seção 5 do briefing).
///
/// IMPORTANTE: isto é só a PREFERÊNCIA do usuário. Nem Android nem iOS
/// garantem que o widget atualize exatamente nesse intervalo — os dois
/// sistemas ajustam o momento real por bateria/desempenho. Ver
/// data/widget_bridge/widget_sync_service.dart e o código nativo em
/// android/.../widget/WidgetUpdateWorker.kt e ios/VersiculoWidget/Provider.swift.
enum UpdateFrequency { min30, min60, daily, manual }

extension UpdateFrequencyX on UpdateFrequency {
  String get label {
    switch (this) {
      case UpdateFrequency.min30:
        return 'A cada 30 minutos';
      case UpdateFrequency.min60:
        return 'A cada 60 minutos';
      case UpdateFrequency.daily:
        return '1 vez por dia';
      case UpdateFrequency.manual:
        return 'Somente manual';
    }
  }

  /// Minutos aproximados usados para agendar o WorkManager (Android) e
  /// como sugestão de intervalo mínimo de timeline no WidgetKit (iOS).
  int? get approxMinutes {
    switch (this) {
      case UpdateFrequency.min30:
        return 30;
      case UpdateFrequency.min60:
        return 60;
      case UpdateFrequency.daily:
        return 24 * 60;
      case UpdateFrequency.manual:
        return null;
    }
  }

  static UpdateFrequency fromName(String? name) {
    return UpdateFrequency.values.firstWhere(
      (f) => f.name == name,
      orElse: () => UpdateFrequency.min60,
    );
  }
}

/// Opções de "não repetir versículos" (seção 7 do briefing).
/// O valor é o número de outros versículos que precisam aparecer antes de
/// um versículo poder se repetir. 0 = desativado.
enum NoRepeatOption { off, next10, next20, next50, next100 }

extension NoRepeatOptionX on NoRepeatOption {
  int get count {
    switch (this) {
      case NoRepeatOption.off:
        return 0;
      case NoRepeatOption.next10:
        return 10;
      case NoRepeatOption.next20:
        return 20;
      case NoRepeatOption.next50:
        return 50;
      case NoRepeatOption.next100:
        return 100;
    }
  }

  String get label {
    switch (this) {
      case NoRepeatOption.off:
        return 'Desativado';
      case NoRepeatOption.next10:
        return 'Próximos 10 versículos';
      case NoRepeatOption.next20:
        return 'Próximos 20 versículos';
      case NoRepeatOption.next50:
        return 'Próximos 50 versículos';
      case NoRepeatOption.next100:
        return 'Próximos 100 versículos';
    }
  }

  static NoRepeatOption fromCount(int count) {
    return NoRepeatOption.values.firstWhere(
      (o) => o.count == count,
      orElse: () => NoRepeatOption.next20,
    );
  }
}

/// Todos os temas visuais estão disponíveis nesta versão.
enum WidgetVisualTheme { claro, escuro, papel, gradiente, elegante, ceu }

extension WidgetVisualThemeX on WidgetVisualTheme {
  String get label {
    switch (this) {
      case WidgetVisualTheme.claro:
        return 'Claro';
      case WidgetVisualTheme.escuro:
        return 'Escuro';
      case WidgetVisualTheme.papel:
        return 'Papel';
      case WidgetVisualTheme.gradiente:
        return 'Gradiente';
      case WidgetVisualTheme.elegante:
        return 'Elegante';
      case WidgetVisualTheme.ceu:
        return 'Céu';
    }
  }

  static WidgetVisualTheme fromName(String? name) {
    return WidgetVisualTheme.values.firstWhere(
      (t) => t.name == name,
      orElse: () => WidgetVisualTheme.claro,
    );
  }
}

enum WidgetSize { small, medium, large }

extension WidgetSizeX on WidgetSize {
  static WidgetSize fromName(String? name) {
    return WidgetSize.values.firstWhere(
      (s) => s.name == name,
      orElse: () => WidgetSize.medium,
    );
  }
}

/// Todas as preferências do usuário (seções 5, 7, 19, 20, 22 do briefing).
/// Persistidas em uma Hive box simples de chave/valor — ver
/// data/local/settings_store.dart.
class AppSettings {
  final UpdateFrequency frequency;
  final NoRepeatOption noRepeat;
  final WidgetVisualTheme widgetTheme;
  final WidgetSize widgetSize;
  final bool dailyNotificationEnabled;
  final String dailyNotificationTime; // "HH:mm"
  final bool onboarded;

  const AppSettings({
    this.frequency = UpdateFrequency.min60,
    this.noRepeat = NoRepeatOption.next20,
    this.widgetTheme = WidgetVisualTheme.claro,
    this.widgetSize = WidgetSize.medium,
    this.dailyNotificationEnabled = true,
    this.dailyNotificationTime = '07:00',
    this.onboarded = false,
  });

  AppSettings copyWith({
    UpdateFrequency? frequency,
    NoRepeatOption? noRepeat,
    WidgetVisualTheme? widgetTheme,
    WidgetSize? widgetSize,
    bool? dailyNotificationEnabled,
    String? dailyNotificationTime,
    bool? onboarded,
  }) {
    return AppSettings(
      frequency: frequency ?? this.frequency,
      noRepeat: noRepeat ?? this.noRepeat,
      widgetTheme: widgetTheme ?? this.widgetTheme,
      widgetSize: widgetSize ?? this.widgetSize,
      dailyNotificationEnabled:
          dailyNotificationEnabled ?? this.dailyNotificationEnabled,
      dailyNotificationTime:
          dailyNotificationTime ?? this.dailyNotificationTime,
      onboarded: onboarded ?? this.onboarded,
    );
  }
}
