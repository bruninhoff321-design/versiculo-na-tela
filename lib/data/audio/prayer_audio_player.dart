import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/prayer/prayer_composer.dart';
import '../../domain/prayer/prayer_slot.dart';
import 'prayer_audio_cache.dart';

/// Player único: permanece ativo quando a tela de oração é fechada, para que
/// a notificação de mídia continue oferecendo pausa e reprodução.
class PrayerAudioPlayer {
  PrayerAudioPlayer._();

  static final PrayerAudioPlayer instance = PrayerAudioPlayer._();
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<bool> preparing = ValueNotifier(false);
  final FlutterTts _tts = FlutterTts();
  final PrayerAudioCache _cache = const PrayerAudioCache();
  Future<void> _synthesisQueue = Future<void>.value();
  bool _demoLoaded = false;
  String? _loadedPrayerId;
  String? get currentPrayerId => _loadedPrayerId;

  String _fileName(String id) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(id)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return 'oracao_${hash.toRadixString(16).padLeft(8, '0')}.wav';
  }

  Future<File> _fileFor(String id) async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/${_fileName(id)}');
  }

  Future<File> _ensureAudio(String text, String id) async {
    final file = await _fileFor(id);
    final task = _synthesisQueue.then((_) async {
      if (await file.exists() && await file.length() > 0) return;
      final installed = await _tts.isLanguageInstalled('pt-BR');
      if (installed != true) {
        throw StateError(
            'Instale uma voz em português nas configurações de leitura do Android.');
      }
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.47);
      await _tts.awaitSynthCompletion(true);
      try {
        final result = await _tts
            .synthesizeToFile(text, file.path, true)
            .timeout(const Duration(seconds: 45));
        if (result != 1 || !await file.exists() || await file.length() == 0) {
          throw StateError(
              'A voz do aparelho não conseguiu preparar esta oração.');
        }
      } catch (_) {
        if (await file.exists()) await file.delete();
        rethrow;
      }
    });
    _synthesisQueue = task.catchError((Object error) {
      debugPrint('Não foi possível preparar uma oração: $error');
    });
    await task;
    return file;
  }

  /// Prepara só as próximas duas orações, sem bloquear a abertura do app.
  Future<void> prewarmNextTwo(List<String> themeIds) async {
    final directory = await getApplicationSupportDirectory();
    final keep = <String>{};
    const composer = PrayerComposer();
    for (final slot in nextTwoPrayerSlots(DateTime.now())) {
      final id = composer.idFor(
          day: slot.day, morning: slot.morning, themeIds: themeIds);
      final text = composer.compose(
          day: slot.day, morning: slot.morning, themeIds: themeIds);
      try {
        final file = await _ensureAudio(text, id);
        keep.add(file.path);
      } catch (error) {
        debugPrint('Áudio antecipado indisponível: $error');
      }
    }
    if (_loadedPrayerId != null) {
      keep.add((await _fileFor(_loadedPrayerId!)).path);
    }
    await _cache.prune(directory, now: DateTime.now(), keepPaths: keep);
  }

  Future<({int files, int bytes})> clearGeneratedAudio() async {
    await _synthesisQueue;
    if (_loadedPrayerId != null) {
      await player.stop();
      _loadedPrayerId = null;
    }
    final directory = await getApplicationSupportDirectory();
    return _cache.clear(directory);
  }

  Future<void> toggleDaily({required String text, required String id}) async {
    if (preparing.value) return;
    if (_loadedPrayerId == id && player.playing) {
      await player.pause();
      return;
    }
    if (_loadedPrayerId != id) {
      preparing.value = true;
      try {
        final file = await _ensureAudio(text, id);
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
