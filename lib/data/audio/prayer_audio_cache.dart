import 'dart:io';

/// Áudios gerados pela voz do aparelho são temporários e podem ser refeitos.
class PrayerAudioCache {
  const PrayerAudioCache();

  Future<({int files, int bytes})> clear(
    Directory directory, {
    Set<String> keepPaths = const {},
  }) async {
    final files = await _generatedFiles(directory);
    final kept = keepPaths.map((path) => File(path).absolute.uri).toSet();
    return _delete(files.where((file) => !kept.contains(file.absolute.uri)));
  }

  Future<({int files, int bytes})> prune(
    Directory directory, {
    required DateTime now,
    Set<String> keepPaths = const {},
  }) async {
    final files = await _generatedFiles(directory);
    final kept = keepPaths.map((path) => File(path).absolute.uri).toSet();
    files
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    final cutoff = now.subtract(const Duration(days: 2));
    final removable = <File>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (kept.contains(file.absolute.uri)) continue;
      if (i >= 4 || (await file.lastModified()).isBefore(cutoff)) {
        removable.add(file);
      }
    }
    return _delete(removable);
  }

  Future<List<File>> _generatedFiles(Directory directory) async {
    if (!await directory.exists()) return [];
    return directory
        .list()
        .where((entry) => entry is File)
        .cast<File>()
        .where((file) {
      final name = file.uri.pathSegments.last;
      return name.startsWith('oracao_') && name.endsWith('.wav');
    }).toList();
  }

  Future<({int files, int bytes})> _delete(Iterable<File> files) async {
    var count = 0;
    var bytes = 0;
    for (final file in files) {
      try {
        bytes += await file.length();
        await file.delete();
        count++;
      } on FileSystemException {
        // Um player ou o sistema pode estar usando este arquivo agora.
      }
    }
    return (files: count, bytes: bytes);
  }
}
