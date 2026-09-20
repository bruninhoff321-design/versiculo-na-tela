import 'package:home_widget/home_widget.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/verse.dart';

/// Ponte entre o app Flutter e os widgets NATIVOS de tela inicial/bloqueio.
///
/// Isto é o ponto mais importante de toda a arquitetura: um widget de tela
/// inicial/bloqueio NÃO roda o motor Flutter. Ele é código nativo puro
/// (Kotlin + Jetpack Glance no Android, Swift + WidgetKit no iOS) que lê um
/// pequeno pedaço de dado compartilhado:
///   - Android: SharedPreferences do grupo "HomeWidgetPreferences"
///   - iOS: UserDefaults de um App Group (ver ios/VersiculoWidget)
///
/// O plugin `home_widget` escreve nesse local compartilhado e pede ao SO
/// para redesenhar o widget. Todo o texto do versículo, a referência e o
/// tema visual escolhido passam por aqui — o widget nativo nunca decide
/// qual versículo mostrar, ele só exibe o que o app já decidiu e gravou.
class WidgetSyncService {
  /// Precisa bater com o App Group configurado no Xcode (ver
  /// ios/VersiculoWidget/README dentro da pasta do target).
  static const String iosAppGroupId = 'group.com.versiculonatela.app';

  static const String androidWidgetReceiver =
      'com.versiculonatela.app.widget.VersiculoWidgetReceiver';
  static const String iosWidgetKind = 'VersiculoWidget';

  Future<void> init() async {
    await HomeWidget.setAppGroupId(iosAppGroupId);
  }

  Future<void> syncCurrentVerse({
    required Verse verse,
    required AppSettings settings,
  }) async {
    await HomeWidget.saveWidgetData<String>('verse_text', verse.text);
    await HomeWidget.saveWidgetData<String>('verse_reference', verse.reference);
    await HomeWidget.saveWidgetData<String>('widget_theme', settings.widgetTheme.name);
    await HomeWidget.saveWidgetData<String>('widget_size', settings.widgetSize.name);
    await HomeWidget.saveWidgetData<String>(
        'updated_at', DateTime.now().toIso8601String());

    await _requestNativeRefresh();
  }

  Future<void> _requestNativeRefresh() async {
    await HomeWidget.updateWidget(
      // qualifiedAndroidName usa o nome de classe JÁ COMPLETO — diferente
      // de `androidName`, que o plugin prefixa automaticamente com o
      // packageName (isso duplicaria o pacote se usássemos aqui).
      qualifiedAndroidName: androidWidgetReceiver,
      iOSName: iosWidgetKind,
    );
  }
}
