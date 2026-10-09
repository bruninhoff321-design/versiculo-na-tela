import 'dart:async' show unawaited;
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Player único: permanece ativo quando a tela de oração é fechada, para que
/// a notificação de mídia continue oferecendo pausa e reprodução.
class PrayerAudioPlayer {
  PrayerAudioPlayer._();

  static final PrayerAudioPlayer instance = PrayerAudioPlayer._();
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<bool> preparing = ValueNotifier(false);
  final FlutterTts _tts = FlutterTts();
  bool _demoLoaded = false;
  String? _loadedPrayerId;
  String? get currentPrayerId => _loadedPrayerId;

  Future<void> toggleDaily({required String text, required String id}) async {
    if (preparing.value) return;
    if (_loadedPrayerId == id && player.playing) {
      await player.pause();
      return;
    }
    if (_loadedPrayerId != id) {
      preparing.value = true;
      try {
        final directory = await getApplicationSupportDirectory();
        final file = File('${directory.path}/oracao_${id.hashCode}.wav');
        if (!await file.exists() || await file.length() == 0) {
          final installed = await _tts.isLanguageInstalled('pt-BR');
          if (installed != true) {
            throw StateError(
                'Instale uma voz em português nas configurações de leitura do Android.');
          }
          await _tts.setLanguage('pt-BR');
          await _tts.setSpeechRate(0.47);
          await _tts.awaitSynthCompletion(true);
          final result = await _tts
              .synthesizeToFile(text, file.path, true)
              .timeout(const Duration(seconds: 45));
          if (result != 1 || !await file.exists() || await file.length() == 0) {
            throw StateError(
                'A voz do aparelho não conseguiu preparar esta oração.');
          }
        }
        await player.setAudioSource(AudioSource.uri(
          file.uri,
          tag: MediaItem(
            id: id,
            album: 'Versículo na Tela',
            title: 'Oração do dia',
            artist: 'Voz do aparelho',
          ),
        ));
        _loadedPrayerId = id;
        _demoLoaded = false;
      } finally {
        preparing.value = false;
      }
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }

  Future<void> toggleDemo() async {
    if (player.playing) {
      await player.pause();
      return;
    }
    if (!_demoLoaded) {
      await player.setAudioSource(AudioSource.asset(
        'assets/prayer_demo.mp3',
        tag: const MediaItem(
          id: 'prayer-demo-hope',
          album: 'Versículo na Tela',
          title: 'Prévia da oração de esperança',
          artist: 'Voz gerada por IA',
        ),
      ));
      _demoLoaded = true;
      _loadedPrayerId = null;
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }
}
