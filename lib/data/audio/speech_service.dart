import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Leitura em voz alta de versículos e capítulos com a voz do próprio
/// celular (funciona sem internet). Só uma leitura toca por vez.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// Identificador do que está tocando agora (ex: id do versículo ou
  /// "cap:sal.23"). Nulo quando nada está tocando.
  final ValueNotifier<String?> speaking = ValueNotifier<String?>(null);

  Future<void> _init() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCancelHandler(() => speaking.value = null);
      _tts.setErrorHandler((_) => speaking.value = null);
    } catch (error) {
      debugPrint('Voz do aparelho indisponível: $error');
    }
    _ready = true;
  }

  /// Lê [text]. Se [id] já estiver tocando, para (funciona como botão
  /// liga/desliga).
  Future<void> toggle(String id, String text) => toggleParts(id, [text]);

  /// Lê vários trechos em sequência (o Android limita o tamanho de cada
  /// fala, então capítulos longos são lidos versículo a versículo).
  Future<void> toggleParts(String id, List<String> parts) async {
    if (speaking.value == id) {
      await stop();
      return;
    }
    await _init();
    await stop();
    speaking.value = id;
    try {
      for (final part in parts) {
        if (speaking.value != id) break;
        await _tts.speak(part);
      }
    } catch (error) {
      debugPrint('Não foi possível ler em voz alta: $error');
    } finally {
      if (speaking.value == id) speaking.value = null;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    speaking.value = null;
  }
}
