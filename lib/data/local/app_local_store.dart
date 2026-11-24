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
  static const _highlightsBoxName = 'highlights';

  late Box _settingsBox;
  late Box _favoritesBox;
  late Box _historyBox;
  late Box _notesBox;
  late Box _highlightsBox;

  static const int maxHistoryEntries = 500;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _favoritesBox = await Hive.openBox(_favoritesBoxName);
    _historyBox = await Hive.openBox(_historyBoxName);
    _notesBox = await Hive.openBox(_notesBoxName);
    _highlightsBox = await Hive.openBox(_highlightsBoxName);
  }

  // ---------------- Marca-texto ----------------

  /// versículo -> índice da cor do marca-texto.
  Map<String, int> readHighlights() => {
        for (final key in _highlightsBox.keys.cast<String>())
          key: _highlightsBox.get(key) as int,
      };

  Future<void> setHighlight(String verseId, int? colorIndex) async {
    if (colorIndex == null) {
      await _highlightsBox.delete(verseId);
    } else {
      await _highlightsBox.put(verseId, colorIndex);
    }
  }

  // ---------------- Ofensiva (dias seguidos) ----------------

  /// Dias em que a pessoa abriu e usou o app, no formato AAAA-MM-DD.
  List<String> readActivityDays() =>
      (_settingsBox.get('activityDays') as List?)
          ?.whereType<String>()
          .toList() ??
      <String>[];

  Future<void> writeActivityDays(List<String> days) async {
    // Guardamos só o último ano: é o bastante para a ofensiva e o calendário.
    final trimmed = days.length > 400 ? days.sublist(days.length - 400) : days;
    await _settingsBox.put('activityDays', trimmed);
  }

  int readBestStreak() => (_settingsBox.get('bestStreak') as int?) ?? 0;

  Future<void> writeBestStreak(int value) async {
    await _settingsBox.put('bestStreak', value);
  }

  // ---------------- Leitura da Bíblia ----------------

  /// Último capítulo aberto, no formato "livro.capítulo" (ex: "sal.23").
  String? readLastRead() => _settingsBox.get('lastRead') as String?;

  Future<void> writeLastRead(String value) async {
    await _settingsBox.put('lastRead', value);
  }

  Set<String> readChaptersRead() =>
      ((_settingsBox.get('chaptersRead') as List?)?.whereType<String>() ??
              const <String>[])
          .toSet();

  Future<void> markChapterRead(String key) async {
    final set = readChaptersRead()..add(key);
    await _settingsBox.put('chaptersRead', set.toList());
  }

  // ---------------- Tradição ----------------

  /// "evangelico" ou "catolico". Nulo enquanto a pessoa não escolheu.
  String? readTradition() => _settingsBox.get('tradition') as String?;

  Future<void> writeTradition(String value) async {
    await _settingsBox.put('tradition', value);
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
    await _settingsBox.put('prayerThemeIds', ids.toSet().toList());
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
