import 'package:flutter/services.dart';

import '../../domain/models/app_settings.dart';

/// Chama o lado nativo para (re)agendar a atualização periódica do widget:
///  - Android: WorkManager (ver MainActivity.kt + widget/WidgetUpdateWorker.kt)
///  - iOS: não precisa de chamada explícita — o WidgetKit Timeline já lê a
///    preferência salva e decide sozinho quando pedir a próxima entrada
///    (ver ios/VersiculoWidget/Provider.swift). O SO iOS não expõe uma API
///    para "forçar" um intervalo exato, então não há nada de nativo para
///    chamar daqui nesse lado.
class NativeWidgetScheduler {
  static const _channel = MethodChannel('com.versiculonatela.app/widget_scheduler');

  Future<void> apply(UpdateFrequency frequency) async {
    try {
      await _channel.invokeMethod('schedule', {
        'minutes': frequency.approxMinutes,
      });
    } on MissingPluginException {
      // Esperado ao rodar em plataformas sem essa implementação (ex.: iOS,
      // ou testes de widget/unitários sem plugins nativos registrados).
    }
  }
}
