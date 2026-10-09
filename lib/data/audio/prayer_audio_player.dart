import 'dart:async' show unawaited;

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Player único: permanece ativo quando a tela de oração é fechada, para que
/// a notificação de mídia continue oferecendo pausa e reprodução.
class PrayerAudioPlayer {
  PrayerAudioPlayer._();

  static final PrayerAudioPlayer instance = PrayerAudioPlayer._();
  final AudioPlayer player = AudioPlayer();
  bool _demoLoaded = false;

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
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }
}
