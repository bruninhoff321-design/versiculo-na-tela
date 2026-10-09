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
  static const _notesBoxName = 'notes';

  late Box _settingsBox;
  late Box _favoritesBox;
  late Box _historyBox;
  late Box _notesBox;

  static const int maxHistoryEntries = 500;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _favoritesBox = await Hive.openBox(_favoritesBoxName);
    _historyBox = await Hive.openBox(_historyBoxName);
    _notesBox = await Hive.openBox(_notesBoxName);
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
      readingTextSize: ReadingTextSizeX.fromName(
          _settingsBox.get('readingTextSize') as String?),
      dailyNotificationEnabled:
          // Versões antigas ativavam o lembrete sem escolha explícita.
          // Só mantemos ativo quando a pessoa o ligou nesta versão.
          (_settingsBox.get('dailyNotificationConsent') as bool?) == true &&
              (_settingsBox.get('dailyNotificationEnabled') as bool?) == true,
      prayerRemindersEnabled:
          (_settingsBox.get('prayerRemindersEnabled') as bool?) == true,
      lockScreenNotificationEnabled:
          (_settingsBox.get('lockScreenNotificationEnabled') as bool?) ?? false,
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
      'readingTextSize': settings.readingTextSize.name,
      'dailyNotificationEnabled': settings.dailyNotificationEnabled,
      'prayerRemindersEnabled': settings.prayerRemindersEnabled,
      'dailyNotificationConsent': settings.dailyNotificationEnabled,
      'lockScreenNotificationEnabled': settings.lockScreenNotificationEnabled,
      'dailyNotificationTime': settings.dailyNotificationTime,
      'onboarded': settings.onboarded,
    });
  }

  String? readCurrentVerseId() => _settingsBox.get('currentVerseId') as String?;

  Future<void> writeCurrentVerseId(String verseId) async {
    await _settingsBox.put('currentVerseId', verseId);
  }

  /// Somente os temas escolhidos são guardados. O relato livre permanece
  /// nesta tela e não é enviado nem salvo para os lembretes de oração.
  List<String> readPrayerThemeIds() =>
      (_settingsBox.get('prayerThemeIds') as List?)
          ?.whereType<String>()
          .toList(growable: false) ??
      const [];

  Future<void> writePrayerThemeIds(Iterable<String> ids) async {
    await _settingsBox.put('prayerThemeIds', ids.toSet().toList()..sort());
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

  Map<String, String> readNotes() => {
        for (final key in _notesBox.keys.cast<String>())
          key: _notesBox.get(key) as String,
      };

  Future<void> saveNote(String verseId, String note) async {
    if (note.trim().isEmpty) {
      await _notesBox.delete(verseId);
    } else {
      await _notesBox.put(verseId, note.trim());
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
