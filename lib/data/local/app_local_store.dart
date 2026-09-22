import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/history_entry.dart';

/// Armazenamento local (seção 25: "o app deve funcionar offline"). Usa Hive
/// puro (sem geração de código) com três boxes simples:
///  - `settings`  : chave/valor com as preferências do usuário
///  - `favorites` : chave = verseId, valor = true (funciona como um Set)
///  - `history`   : lista de mapas {verseId, timestamp, source}, em ordem
///
/// Nenhuma dessas informações depende de rede — favoritos e histórico
/// continuam disponíveis 100% offline, como pede a seção 25 do briefing.
class AppLocalStore {
  static const _settingsBoxName = 'settings';
  static const _favoritesBoxName = 'favorites';
  static const _historyBoxName = 'history';

  late Box _settingsBox;
  late Box _favoritesBox;
  late Box _historyBox;

  static const int maxHistoryEntries = 500;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _favoritesBox = await Hive.openBox(_favoritesBoxName);
    _historyBox = await Hive.openBox(_historyBoxName);
  }

  // ---------------- Settings ----------------

  AppSettings readSettings() {
    return AppSettings(
      frequency:
          UpdateFrequencyX.fromName(_settingsBox.get('frequency') as String?),
      noRepeat: NoRepeatOptionX.fromCount(
          (_settingsBox.get('noRepeat') as int?) ?? 20),
      widgetTheme: WidgetVisualThemeX.fromName(
          _settingsBox.get('widgetTheme') as String?),
      widgetSize:
          WidgetSizeX.fromName(_settingsBox.get('widgetSize') as String?),
      dailyNotificationEnabled:
          (_settingsBox.get('dailyNotificationEnabled') as bool?) ?? true,
      dailyNotificationTime:
          (_settingsBox.get('dailyNotificationTime') as String?) ?? '07:00',
      onboarded: (_settingsBox.get('onboarded') as bool?) ?? false,
    );
  }

  Future<void> writeSettings(AppSettings settings) async {
    await _settingsBox.putAll({
      'frequency': settings.frequency.name,
      'noRepeat': settings.noRepeat.count,
      'widgetTheme': settings.widgetTheme.name,
      'widgetSize': settings.widgetSize.name,
      'dailyNotificationEnabled': settings.dailyNotificationEnabled,
      'dailyNotificationTime': settings.dailyNotificationTime,
      'onboarded': settings.onboarded,
    });
  }

  String? readCurrentVerseId() => _settingsBox.get('currentVerseId') as String?;

  Future<void> writeCurrentVerseId(String verseId) async {
    await _settingsBox.put('currentVerseId', verseId);
  }

  // ---------------- Favorites ----------------

  Set<String> readFavoriteIds() => _favoritesBox.keys.cast<String>().toSet();

  bool isFavorite(String verseId) => _favoritesBox.containsKey(verseId);

  Future<void> toggleFavorite(String verseId) async {
    if (_favoritesBox.containsKey(verseId)) {
      await _favoritesBox.delete(verseId);
    } else {
      await _favoritesBox.put(verseId, true);
    }
  }

  // ---------------- History ----------------

  /// Em ordem cronológica (mais antigo primeiro).
  List<HistoryEntry> readHistory() {
    return _historyBox.values
        .map((raw) =>
            HistoryEntry.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<void> appendHistory(HistoryEntry entry) async {
    await _historyBox.add(entry.toMap());
    // Evita crescimento ilimitado do armazenamento local.
    if (_historyBox.length > maxHistoryEntries) {
      final overflow = _historyBox.length - maxHistoryEntries;
      final oldestKeys = _historyBox.keys.take(overflow).toList();
      await _historyBox.deleteAll(oldestKeys);
    }
  }
}
