import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/data/audio/prayer_audio_cache.dart';
import 'package:versiculo_na_tela/domain/prayer/prayer_slot.dart';

void main() {
  test('agenda as duas próximas orações locais, sem repetir horário passado',
      () {
    final beforeMorning = nextTwoPrayerSlots(DateTime(2026, 10, 9, 4, 30));
    expect(beforeMorning.map((slot) => slot.scheduledAt),
        [DateTime(2026, 10, 9, 5), DateTime(2026, 10, 9, 18)]);

    final afterEvening = nextTwoPrayerSlots(DateTime(2026, 10, 9, 18, 30));
    expect(afterEvening.map((slot) => slot.scheduledAt),
        [DateTime(2026, 10, 10, 5), DateTime(2026, 10, 10, 18)]);
  });

  test('limpeza remove só áudios gerados e preserva arquivo em uso', () async {
    final directory = await Directory.systemTemp.createTemp('prayer_cache_');
    addTearDown(() => directory.delete(recursive: true));
    final first = File('${directory.path}/oracao_1.wav')
      ..writeAsBytesSync([1, 2]);
    final current = File('${directory.path}/oracao_2.wav')
      ..writeAsBytesSync([3]);
    final unrelated = File('${directory.path}/notes.txt')
      ..writeAsStringSync('não apagar');

    final result = await const PrayerAudioCache()
        .clear(directory, keepPaths: {current.path});

    expect(result, (files: 1, bytes: 2));
    expect(await first.exists(), isFalse);
    expect(await current.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
  });

  test('limpeza automática descarta arquivos antigos e limita a quatro',
      () async {
    final directory = await Directory.systemTemp.createTemp('prayer_prune_');
    addTearDown(() => directory.delete(recursive: true));
    final now = DateTime(2026, 10, 9, 12);
    final files = <File>[];
    for (var i = 0; i < 6; i++) {
      final file = File('${directory.path}/oracao_$i.wav');
      await file.writeAsBytes([i]);
      await file.setLastModified(now.subtract(Duration(hours: i)));
      files.add(file);
    }
    await files.last.setLastModified(now.subtract(const Duration(days: 3)));

    final result = await const PrayerAudioCache().prune(directory, now: now);

    expect(result.files, 2);
    for (var i = 0; i < 4; i++) {
      expect(await files[i].exists(), isTrue);
    }
    expect(await files[4].exists(), isFalse);
    expect(await files[5].exists(), isFalse);
  });
}
