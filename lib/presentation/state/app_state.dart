import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import '../../data/local/app_local_store.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/purchases/purchase_service.dart';
import '../../data/widget_bridge/native_scheduler.dart';
import '../../data/widget_bridge/widget_sync_service.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/history_entry.dart';
import '../../domain/models/verse.dart';
import '../../domain/repositories/verse_repository.dart';
import '../../domain/usecases/match_verse_for_input.dart';
import '../../domain/usecases/pick_next_verse.dart';

/// Orquestrador central do app — é o único lugar que conhece todas as
/// camadas (dados locais, banco de versículos, widget nativo, notificações,
/// compras). As telas em presentation/ só leem daqui e chamam métodos daqui;
/// nenhuma tela acessa Hive, o widget nativo ou a loja diretamente.
class AppState extends ChangeNotifier {
  final VerseRepository verseRepository;
  final ThemeTaxonomyRepository taxonomyRepository;
  final AppLocalStore localStore;
  final WidgetSyncService widgetSync;
  final NotificationService notifications;
  final PurchaseService purchases;
  final PickNextVerseUseCase pickNextVerse;
  final MatchVerseForInputUseCase matchVerseForInput;
  final NativeWidgetScheduler scheduler;

  AppState({
    required this.verseRepository,
    required this.taxonomyRepository,
    required this.localStore,
    required this.widgetSync,
    required this.notifications,
    required this.purchases,
    NativeWidgetScheduler? scheduler,
    PickNextVerseUseCase? pickNextVerseUseCase,
    MatchVerseForInputUseCase? matchVerseForInputUseCase,
  })  : scheduler = scheduler ?? NativeWidgetScheduler(),
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

  Future<void> bootstrap() async {
    _allVerses = await verseRepository.loadAll();
    _byId = {for (final v in _allVerses) v.id: v};
    _synonyms = await taxonomyRepository.loadSynonyms();

    settings = localStore.readSettings();
    history = localStore.readHistory();
    favoriteIds = localStore.readFavoriteIds();

    final savedId = localStore.readCurrentVerseId();
    currentVerse = (savedId != null ? _byId[savedId] : null) ??
        (_allVerses.isNotEmpty ? _allVerses.first : null);

    await widgetSync.init();
    await notifications.init();
    await purchases.init(initiallyPremium: settings.premium);
    purchases.isPremium.addListener(_onPremiumChanged);
    await scheduler.apply(settings.frequency);

    if (currentVerse != null) {
      await _persistCurrentVerse(currentVerse!, HistorySource.widget,
          alreadyHappened: history.isNotEmpty);
    }
    if (settings.dailyNotificationEnabled) {
      await notifications.scheduleDaily(settings.dailyNotificationTime);
    }

    _loading = false;
    notifyListeners();
  }

  void _onPremiumChanged() {
    settings = settings.copyWith(premium: purchases.isPremium.value);
    unawaited(localStore.writeSettings(settings));
    notifyListeners();
  }

  Verse? verseById(String id) => _byId[id];

  /// Favoritos como objetos Verse completos (seção 15 do briefing).
  List<Verse> favoritesAsVerses() {
    return favoriteIds
        .map((id) => _byId[id])
        .whereType<Verse>()
        .toList();
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

    if (settings.frequency != previousFrequency) {
      await scheduler.apply(settings.frequency);
    }
    if (settings.dailyNotificationEnabled) {
      await notifications.scheduleDaily(settings.dailyNotificationTime);
    } else {
      await notifications.cancelDaily();
    }
    if (currentVerse != null) {
      await widgetSync.syncCurrentVerse(verse: currentVerse!, settings: settings);
    }
    notifyListeners();
  }

  Future<void> markOnboarded() async {
    await updateSettings((s) => s.copyWith(onboarded: true));
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
    await widgetSync.syncCurrentVerse(verse: verse, settings: settings);
    notifyListeners();
  }

  Future<void> _persistCurrentVerse(
    Verse verse,
    HistorySource source, {
    bool alreadyHappened = false,
  }) async {
    if (!alreadyHappened) {
      await _appendHistory(verse.id, source);
    }
    await widgetSync.syncCurrentVerse(verse: verse, settings: settings);
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

  @override
  void dispose() {
    purchases.isPremium.removeListener(_onPremiumChanged);
    purchases.dispose();
    super.dispose();
  }
}

