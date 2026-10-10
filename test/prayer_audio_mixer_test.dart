import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/data/audio/prayer_audio_mixer.dart';

void main() {
  test('mistura fundo suave em WAV PCM e preserva a duração', () async {
    final directory = await Directory.systemTemp.createTemp('prayer_mix_');
    addTearDown(() => directory.delete(recursive: true));
    final voice = File('${directory.path}/voice.wav');
    final mixed = File('${directory.path}/mixed.wav');
    final bytes = Uint8List(44 + 8000 * 4);
    final data = ByteData.sublistView(bytes);
    void label(int at, String value) {
      bytes.setRange(at, at + value.length, value.codeUnits);
    }

    label(0, 'RIFF');
    data.setUint32(4, bytes.length - 8, Endian.little);
    label(8, 'WAVE');
    label(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 8000, Endian.little);
    data.setUint32(28, 16000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    label(36, 'data');
    data.setUint32(40, bytes.length - 44, Endian.little);
    await voice.writeAsBytes(bytes);

    expect(await const PrayerAudioMixer().mix(voice, mixed), isTrue);
    final result = await mixed.readAsBytes();
    expect(result.length, bytes.length);
    expect(result.sublist(0, 44), bytes.sublist(0, 44));
    expect(result.sublist(44), isNot(bytes.sublist(44)));
  });

  test('não altera formatos que não pode misturar', () async {
    final directory = await Directory.systemTemp.createTemp('prayer_mix_');
    addTearDown(() => directory.delete(recursive: true));
    final voice = File('${directory.path}/voice.mp3')
      ..writeAsBytesSync([1, 2, 3]);
    final mixed = File('${directory.path}/mixed.wav');
    expect(await const PrayerAudioMixer().mix(voice, mixed), isFalse);
    expect(await mixed.exists(), isFalse);
  });
}
