import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

/// Adiciona um fundo instrumental original e discreto ao WAV da voz local.
/// Quando o mecanismo de voz entrega outro formato, preserva a voz intacta.
class PrayerAudioMixer {
  const PrayerAudioMixer();

  Future<bool> mix(File voice, File destination) =>
      Isolate.run(() => _mixInBackground(voice.path, destination.path));

  static Future<bool> _mixInBackground(
      String voicePath, String destinationPath) async {
    final voice = File(voicePath);
    final destination = File(destinationPath);
    final bytes = await voice.readAsBytes();
    if (bytes.length < 44 ||
        _fourCC(bytes, 0) != 'RIFF' ||
        _fourCC(bytes, 8) != 'WAVE') {
      return false;
    }

    final data = ByteData.sublistView(bytes);
    int? channels;
    int? sampleRate;
    int? dataOffset;
    int? dataLength;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final name = _fourCC(bytes, offset);
      final length = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8;
      if (length > bytes.length - start) return false;
      if (name == 'fmt ' && length >= 16) {
        final format = data.getUint16(start, Endian.little);
        final bits = data.getUint16(start + 14, Endian.little);
        if (format != 1 || bits != 16) return false;
        channels = data.getUint16(start + 2, Endian.little);
        sampleRate = data.getUint32(start + 4, Endian.little);
      } else if (name == 'data') {
        dataOffset = start;
        dataLength = length;
      }
      offset = start + length + (length.isOdd ? 1 : 0);
    }
    if (channels == null ||
        (channels != 1 && channels != 2) ||
        sampleRate == null ||
        sampleRate < 8000 ||
        dataOffset == null ||
        dataLength == null ||
        dataLength < channels * 2) {
      return false;
    }

    final mixed = Uint8List.fromList(bytes);
    final out = ByteData.sublistView(mixed);
    final frames = dataLength ~/ (channels * 2);
    const roots = [196.00, 174.61, 164.81, 174.61];
    for (var frame = 0; frame < frames; frame++) {
      final seconds = frame / sampleRate;
      final root = roots[(seconds ~/ 12) % roots.length];
      final fadeIn = (seconds / 2).clamp(0.0, 1.0);
      final fadeOut = ((frames - frame) / (sampleRate * 2)).clamp(0.0, 1.0);
      final pulse = 0.9 + 0.1 * math.sin(seconds * 0.35);
      final pad = (math.sin(2 * math.pi * root * seconds) +
              math.sin(2 * math.pi * root * 1.259921 * seconds) +
              math.sin(2 * math.pi * root * 1.498307 * seconds)) /
          3;
      final background = (pad * 950 * fadeIn * fadeOut * pulse).round();
      for (var channel = 0; channel < channels; channel++) {
        final position = dataOffset + (frame * channels + channel) * 2;
        final sample = out.getInt16(position, Endian.little);
        out.setInt16(position, (sample + background).clamp(-32768, 32767),
            Endian.little);
      }
    }
    await destination.writeAsBytes(mixed, flush: true);
    return true;
  }

  static String _fourCC(Uint8List bytes, int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));
}
