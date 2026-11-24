import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../data/ativacao/activation_service.dart';
import '../../data/local/app_local_store.dart';
import '../../data/audio/prayer_audio_player.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/widget_bridge/native_scheduler.dart';
import '../../data/widget_bridge/lock_wallpaper_service.dart';
import '../../data/widget_bridge/widget_sync_service.dart';
import '../../domain/bible/bible_book.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/history_entry.dart';
import '../../domain/models/verse.dart';
import '../../domain/repositories/verse_repository.dart';
import '../../domain/usecases/match_verse_for_input.dart';
import '../../domain/usecases/pick_next_verse.dart';

/// Orquestrador central do app — é o único lugar que conhece todas as
/// camadas (dados locais, banco de versículos, widget nativo, notificações,
/// agendamento). As telas em presentation/ só leem daqui e chamam métodos daqui;
/// nenhuma tela acessa Hive, o widget nativo ou a loja diretamente.
class AppState extends ChangeNotifier {
  final VerseRepository verseRepository;
  final ThemeTaxonomyRepository taxonomyRepository;
  final AppLocalStore localStore;
  final WidgetSyncService widgetSync;
  final NotificationService notifications;
  final PickNextVerseUseCase pickNextVerse;
  final MatchVerseForInputUseCase matchVerseForInput;
  final NativeWidgetScheduler scheduler;

  /// Liberação do app para quem comprou na Cakto.
  final ActivationService activation;

  /// Carrega os versículos por tema. Nos testes é trocado por um mapa fixo.
  final Future<Map<String, List<String>>> Function()? themeVersesLoader;

  AppState({
    this.themeVersesLoader,
    ActivationService? activation,
    required this.verseRepository,
    required this.taxonomyRepository,
    required this.localStore,
    required this.widgetSync,
    required this.notifications,
    NativeWidgetScheduler? scheduler,
    PickNextVerseUseCase? pickNextVerseUseCase,
    MatchVerseForInputUseCase? matchVerseForInputUseCase,
  })  : activation = activation ?? ActivationService(),
        scheduler = scheduler ?? NativeWidgetScheduler(),
        pickNextVerse = pickNextVerseUseCase ?? PickNextVerseUseCase(),
        matchVerseForInput =
            matchVerseForInputUseCase ?? MatchVerseForInputUseCase();

  bool _loading = true;
  bool get loading => _loading;

  List<Verse> _allVerses = [];
  Map<String, Verse> _byId = {};
  Map<String, List<String>> _synonyms = {};

  late AppSettings settings;
  Verse? currentVerse;
  List<HistoryEntry> history = [];
  Set<String> favoriteIds = {};
  Map<String, String> notes = {};
  List<String> prayerThemeIds = const [];
  bool lockWallpaperEnabled = false;

  // ---------------- Bíblia, ofensiva e tradição ----------------
  late BibleIndex bible;
  Map<String, int> highlights = {};
  Set<String> chaptersRead = {};
  String? lastRead;
  String? tradition; // "evangelico" | "catolico"
  int streak = 0;
  int bestStreak = 0;
  bool activeToday = false;
  Map<String, List<String>> themeVerseIds = {};

  bool get isCatholic => tradition == 'catolico';

  /// Livros que não aparecem para quem escolheu a tradição evangélica.
  Set<String> get hiddenBooks =>
      isCatholic ? const {} : BibleIndex.deuterocanonicalAbbrs;

  List<BibleBook> get visibleBooks =>
      bible.books.where((b) => !hiddenBooks.contains(b.abbr)).toList();

  Future<void> bootstrap() async {
    _allVerses = await verseRepository.loadAll();
    _byId = {for (final v in _allVerses) v.id: v};
    _synonyms = await taxonomyRepository.loadSynonyms();
    bible = BibleIndex.build(_allVerses);
    themeVerseIds = await (themeVersesLoader ?? _loadThemeVerses)();
    highlights = localStore.readHighlights();
    chaptersRead = localStore.readChaptersRead();
    lastRead = localStore.readLastRead();
    tradition = localStore.readTradition();
    bestStreak = localStore.readBestStreak();
    try {
      await activation.init();
    } catch (error) {
      debugPrint('Não foi possível ler a ativação: $error');
    }
    await _registerActivity();

    settings = localStore.readSettings();
    history = localStore.readHistory();
    favoriteIds = localStore.readFavoriteIds();
    notes = localStore.readNotes();
    prayerThemeIds = localStore.readPrayerThemeIds();

    final savedId = localStore.readCurrentVerseId();
    currentVerse = (savedId != null ? _byId[savedId] : null) ??
        _byId['sal.23.1'] ??
        (_allVerses.isNotEmpty ? _allVerses.first : null);

    if (currentVerse != null && history.isEmpty) {
      await _appendHistory(currentVerse!.id, HistorySource.widget);
    }

    _loading = false;
    notifyListeners();
    // Serviços nativos nunca impedem a abertura ou o uso offline do app.
    unawaited(_restoreWidgetVerseAndSync());
    unawaited(_loadLockWallpaperPreference());
    unawaited(_syncNotifications());
    if (settings.prayerRemindersEnabled) {
      unawaited(_prewarmPrayerAudio());
    }
    unawaited(_runOptional(
        'agendamento do widget', () => scheduler.apply(settings.frequency)));
  }

  Future<bool>? _widgetReady;
  Future<bool>? _notificationsReady;
  Future<void> _notificationSync = Future<void>.value();

  Future<bool> _runOptional(
      String service, Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 10));
      return true;
    } catch (error) {
      debugPrint('Não foi possível atualizar $service: $error');
      return false;
    }
  }

  Future<void> _restoreWidgetVerseAndSync() async {
    final initialVerseId = currentVerse?.id;
    try {
      final ready =
          await (_widgetReady ??= _runOptional('widget', widgetSync.init));
      if (ready) {
        final widgetId = await widgetSync
            .readCurrentVerseId()
            .timeout(const Duration(seconds: 10));
        final verse = widgetId == null ? null : _byId[widgetId];
        if (verse != null &&
            currentVerse?.id == initialVerseId &&
            verse.id != currentVerse?.id) {
          currentVerse = verse;
          await localStore.writeCurrentVerseId(verse.id);
          await _appendHistory(verse.id, HistorySource.widget);
          notifyListeners();
          unawaited(_syncNotifications());
        }
      }
    } catch (error) {
      debugPrint('Não foi possível ler o versículo do widget: $error');
    }
    await _syncWidget();
  }

  Future<void> _loadLockWallpaperPreference() async {
    try {
      lockWallpaperEnabled = await LockWallpaperService().isEnabled();
      notifyListeners();
    } catch (_) {
      // O papel de parede é um recurso opcional do Android.
    }
  }

  Future<void> setLockWallpaperEnabled(bool enabled) async {
    await LockWallpaperService().setEnabled(enabled);
    lockWallpaperEnabled = enabled;
    notifyListeners();
  }

  Future<void> _syncWidget() async {
    final ready =
        await (_widgetReady ??= _runOptional('widget', widgetSync.init));
    if (!ready) {
      _widgetReady = null;
      return;
    }
    final verse = currentVerse;
    if (verse != null) {
      await _runOptional('widget',
          () => widgetSync.syncCurrentVerse(verse: verse, settings: settings));
    }
  }

  Future<void> _syncNotifications() {
    _notificationSync = _notificationSync.then((_) => _applyNotifications());
    return _notificationSync;
  }

  Future<void> _applyNotifications() async {
    final ready = await (_notificationsReady ??=
        _runOptional('notificações', notifications.init));
    if (!ready) {
      _notificationsReady = null;
      return;
    }
    await _runOptional('notificações', () async {
      if (settings.dailyNotificationEnabled) {
        await notifications.scheduleDaily(settings.dailyNotificationTime);
      } else {
        await notifications.cancelDaily();
      }
      if (settings.prayerRemindersEnabled) {
        await notifications.schedulePrayerReminders();
      } else {
        await notifications.cancelPrayerReminders();
      }
      final verse = currentVerse;
      if (settings.lockScreenNotificationEnabled && verse != null) {
        await notifications.showLockScreenVerse(verse.text, verse.reference);
      } else {
        await notifications.cancelLockScreenVerse();
      }
    });
  }

  Future<bool> setLockScreenNotificationEnabled(bool enabled) async {
    if (enabled && !await _prepareNotifications()) return false;
    await updateSettings(
        (s) => s.copyWith(lockScreenNotificationEnabled: enabled));
    return true;
  }

  Future<bool> setDailyNotificationEnabled(bool enabled) async {
    if (enabled && !await _prepareNotifications()) return false;
    await updateSettings((s) => s.copyWith(dailyNotificationEnabled: enabled));
    return true;
  }

  Future<bool> setPrayerRemindersEnabled(bool enabled) async {
    if (enabled && !await _prepareNotifications()) return false;
    await updateSettings((s) => s.copyWith(prayerRemindersEnabled: enabled));
    if (enabled) {
      unawaited(_prewarmPrayerAudio());
    }
    return true;
  }

  Future<void> _prewarmPrayerAudio() async {
    try {
      await PrayerAudioPlayer.instance.prewarmNextTwo(prayerThemeIds);
    } catch (error) {
      // A voz instalada no aparelho é opcional; nunca bloqueia o app.
      debugPrint('Não foi possível preparar o áudio antecipado: $error');
    }
  }

  Future<bool> _prepareNotifications() async {
    final ready = await (_notificationsReady ??=
        _runOptional('notificações', notifications.init));
    if (!ready) {
      _notificationsReady = null;
      return false;
    }
    try {
      return await notifications.requestPermission();
    } catch (error) {
      debugPrint('Não foi possível pedir permissão de notificações: $error');
      return false;
    }
  }

  Verse? verseById(String id) => _byId[id];

  /// Favoritos como objetos Verse completos (seção 15 do briefing).
  List<Verse> favoritesAsVerses() {
    return favoriteIds.map((id) => _byId[id]).whereType<Verse>().toList();
  }

  /// Histórico como pares (versículo, registro), do mais recente para o
  /// mais antigo, já pronto para a tela de Histórico (seção 16).
  List<({Verse verse, HistoryEntry entry})> recentHistoryWithVerses(
      {int limit = 60}) {
    final reversed = history.reversed.take(limit);
    final result = <({Verse verse, HistoryEntry entry})>[];
    for (final entry in reversed) {
      final v = _byId[entry.verseId];
      if (v != null) result.add((verse: v, entry: entry));
    }
    return result;
  }

  bool get isFavoriteCurrent =>
      currentVerse != null && favoriteIds.contains(currentVerse!.id);

  // ---------------- Ações da Home ----------------

  Future<void> requestNewVerse() async {
    final next = pickNextVerse(
      allVerses: _allVerses,
      history: history,
      noRepeatCount: settings.noRepeat.count,
      currentVerseId: currentVerse?.id,
    );
    await _setCurrentVerse(next, HistorySource.manual);
  }

  Future<void> toggleFavorite(String verseId) async {
    await localStore.toggleFavorite(verseId);
    favoriteIds = localStore.readFavoriteIds();
    notifyListeners();
  }

  Future<void> saveNote(String verseId, String text) async {
    await localStore.saveNote(verseId, text);
    notes = localStore.readNotes();
    notifyListeners();
  }

  Future<void> setPrayerThemes(Iterable<String> ids) async {
    prayerThemeIds = ids.toSet().toList();
    await localStore.writePrayerThemeIds(prayerThemeIds);
    if (settings.prayerRemindersEnabled) {
      unawaited(_prewarmPrayerAudio());
    }
    notifyListeners();
  }

  Set<String> detectPrayerThemes(String freeText) =>
      MatchVerseForInputUseCase.detectThemes(freeText, _synonyms);

  // ---------------- "O que você precisa ouvir?" ----------------

  ({Verse verse, List<String> matchedThemes})? findForSituation({
    required Set<String> selectedThemeIds,
    required String freeText,
  }) {
    final result = matchVerseForInput(
      allVerses: _allVerses,
      selectedThemeIds: selectedThemeIds,
      freeText: freeText,
      synonyms: _synonyms,
      recentHistory: history,
    );
    if (result == null) return null;
    unawaited(_appendHistory(result.verse.id, HistorySource.descubra));
    return (verse: result.verse, matchedThemes: result.matchedThemes);
  }

  Future<void> putOnWidget(Verse verse) async {
    await _setCurrentVerse(verse, HistorySource.manual, alreadyInHistory: true);
  }

  // ---------------- Configurações ----------------

  Future<void> updateSettings(AppSettings Function(AppSettings) update) async {
    final previousFrequency = settings.frequency;
    settings = update(settings);
    await localStore.writeSettings(settings);

    notifyListeners();
    if (settings.frequency != previousFrequency) {
      unawaited(_runOptional(
          'agendamento do widget', () => scheduler.apply(settings.frequency)));
    }
    unawaited(_syncNotifications());
    unawaited(_syncWidget());
  }

  Future<void> markOnboarded() async {
    await updateSettings((s) => s.copyWith(onboarded: true));
  }

  // ---------------- Ativação (compra na Cakto) ----------------

  bool get activated => activation.isActivated;

  Future<ActivationResult> activate(String email) async {
    final result = await activation.activate(email);
    if (result == ActivationResult.ok) notifyListeners();
    return result;
  }

  // ---------------- Bíblia ----------------

  Future<Map<String, List<String>>> _loadThemeVerses() async {
    try {
      final raw = await rootBundle.loadString('assets/temas_versiculos.json');
      final temas = (jsonDecode(raw) as Map<String, dynamic>)['temas']
          as Map<String, dynamic>;
      return {
        for (final e in temas.entries)
          e.key: (e.value as List).whereType<String>().toList(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> setHighlight(String verseId, int? colorIndex) async {
    await localStore.setHighlight(verseId, colorIndex);
    highlights = localStore.readHighlights();
    notifyListeners();
  }

  Future<void> openChapter(String abbr, int chapter) async {
    lastRead = BibleIndex.keyFor(abbr, chapter);
    await localStore.writeLastRead(lastRead!);
    notifyListeners();
  }

  Future<void> markChapterRead(String abbr, int chapter) async {
    final key = BibleIndex.keyFor(abbr, chapter);
    if (chaptersRead.contains(key)) return;
    await localStore.markChapterRead(key);
    chaptersRead = localStore.readChaptersRead();
    await _registerActivity();
    notifyListeners();
  }

  List<Verse> searchBible(String query) =>
      bible.search(query, hiddenBooks: hiddenBooks);

  Future<void> setTradition(String value) async {
    tradition = value;
    _feedPool = null;
    await localStore.writeTradition(value);
    notifyListeners();
  }

  /// Versículos conhecidos de um tema ("Como você está?").
  List<Verse> versesForTheme(String themeId) => [
        for (final id in themeVerseIds[themeId] ?? const <String>[])
          if (_byId[id] != null) _byId[id]!,
      ];

  List<Verse>? _feedPool;

  /// Versículos curtos e fortes para o feed: os conhecidos de cada tema e
  /// versículos curtos dos livros mais devocionais.
  List<Verse> get feedPool {
    if (_feedPool != null) return _feedPool!;
    const devotional = {
      'sal', 'pro', 'isa', 'mat', 'mar', 'luc', 'joa', 'rom', '1co', '2co',
      'gal', 'efe', 'fil', 'col', '1te', '2te', '1ti', '2ti', 'heb', 'tia',
      '1pe', '1jo', 'jos', 'deu', 'lam', 'jer', 'sab', 'eclo',
    };
    final known = <String>{for (final l in themeVerseIds.values) ...l};
    final pool = <Verse>[];
    for (final v in _allVerses) {
      if (hiddenBooks.contains(v.bookAbbr)) continue;
      final short = v.text.length >= 50 && v.text.length <= 190;
      if (known.contains(v.id) ||
          (short && devotional.contains(v.bookAbbr) && v.verseNumber > 0)) {
        pool.add(v);
      }
    }
    return _feedPool = pool;
  }

  /// Sorteia versículos para o feed, com os conhecidos aparecendo mais.
  List<Verse> nextFeedBatch(int count, {int seed = 0}) {
    final pool = feedPool;
    if (pool.isEmpty) return const [];
    final known = <String>{for (final l in themeVerseIds.values) ...l};
    final rnd = Random(DateTime.now().microsecondsSinceEpoch + seed);
    final out = <Verse>[];
    for (var i = 0; i < count; i++) {
      if (known.isNotEmpty && rnd.nextInt(3) == 0) {
        final list = themeVerseIds.values.elementAt(
            rnd.nextInt(themeVerseIds.length));
        if (list.isNotEmpty) {
          final v = _byId[list[rnd.nextInt(list.length)]];
          if (v != null) {
            out.add(v);
            continue;
          }
        }
      }
      out.add(pool[rnd.nextInt(pool.length)]);
    }
    return out;
  }

  /// Versículo do dia: o mesmo para todo mundo no mesmo dia.
  Verse? get verseOfTheDay {
    final known = <String>[for (final l in themeVerseIds.values) ...l];
    if (known.isEmpty) return currentVerse;
    final now = DateTime.now();
    final dayNumber =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    return _byId[known[dayNumber % known.length]] ?? currentVerse;
  }

  // ---------------- Ofensiva ----------------

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Conta o dia de hoje e recalcula a ofensiva (dias seguidos).
  Future<void> registerActivity() async {
    await _registerActivity();
    notifyListeners();
  }

  Future<void> _registerActivity() async {
    try {
      final days = localStore.readActivityDays();
      final today = _dayKey(DateTime.now());
      if (!days.contains(today)) {
        days.add(today);
        await localStore.writeActivityDays(days);
      }
      final set = days.toSet();
      var count = 0;
      var cursor = DateTime.now();
      while (set.contains(_dayKey(cursor))) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      streak = count;
      activeToday = true;
      if (streak > bestStreak) {
        bestStreak = streak;
        await localStore.writeBestStreak(bestStreak);
      }
    } catch (error) {
      debugPrint('Não foi possível atualizar a ofensiva: $error');
    }
  }

  // ---------------- Internos ----------------

  Future<void> _setCurrentVerse(
    Verse verse,
    HistorySource source, {
    bool alreadyInHistory = false,
  }) async {
    currentVerse = verse;
    await localStore.writeCurrentVerseId(verse.id);
    if (!alreadyInHistory) {
      await _appendHistory(verse.id, source);
    }
    notifyListeners();
    unawaited(_syncWidget());
    unawaited(_syncNotifications());
  }

  Future<void> _appendHistory(String verseId, HistorySource source) async {
    final entry = HistoryEntry(
      verseId: verseId,
      timestamp: DateTime.now(),
      source: source,
    );
    await localStore.appendHistory(entry);
    history = localStore.readHistory();
  }
}
