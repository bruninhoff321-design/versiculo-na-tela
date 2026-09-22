import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:versiculo_na_tela/data/local/app_local_store.dart';
import 'package:versiculo_na_tela/data/notifications/notification_service.dart';
import 'package:versiculo_na_tela/data/widget_bridge/native_scheduler.dart';
import 'package:versiculo_na_tela/data/widget_bridge/widget_sync_service.dart';
import 'package:versiculo_na_tela/domain/models/app_settings.dart';
import 'package:versiculo_na_tela/domain/models/history_entry.dart';
import 'package:versiculo_na_tela/domain/models/verse.dart';
import 'package:versiculo_na_tela/domain/repositories/verse_repository.dart';
import 'package:versiculo_na_tela/presentation/ajustes/ajustes_screen.dart';
import 'package:versiculo_na_tela/presentation/state/app_state.dart';

final _verse = Verse(
  id: 'v1',
  book: 'Salmos',
  bookAbbr: 'sl',
  chapter: 23,
  verseNumber: 1,
  text: 'O Senhor é meu pastor.',
  translationId: 'teste',
  themes: const [],
  keywords: const [],
);

class _Verses implements VerseRepository {
  @override
  Future<List<Verse>> loadAll() async => [_verse];
}

class _Taxonomy implements ThemeTaxonomyRepository {
  @override
  Future<Map<String, List<String>>> loadSynonyms() async => {};
}

class _Store extends AppLocalStore {
  AppSettings saved = const AppSettings();
  final entries = <HistoryEntry>[];
  @override
  AppSettings readSettings() => saved;
  @override
  Future<void> writeSettings(AppSettings settings) async {
    saved = settings;
  }

  @override
  List<HistoryEntry> readHistory() => List.of(entries);
  @override
  Set<String> readFavoriteIds() => {};
  @override
  String? readCurrentVerseId() => null;
  @override
  Future<void> writeCurrentVerseId(String verseId) async {}
  @override
  Future<void> appendHistory(HistoryEntry entry) async {
    entries.add(entry);
  }
}

class _Widget extends WidgetSyncService {
  final Future<void> Function() initialize;
  _Widget(this.initialize);
  int syncs = 0;
  @override
  Future<void> init() => initialize();
  @override
  Future<void> syncCurrentVerse(
      {required Verse verse, required AppSettings settings}) async {
    syncs++;
  }
}

class _Notifications extends NotificationService {
  final Future<void> Function() initialize;
  _Notifications(this.initialize);
  @override
  Future<void> init() => initialize();
  @override
  Future<void> scheduleDaily(String timeOfDay) async {}
  @override
  Future<void> cancelDaily() async {}
}

class _Scheduler extends NativeWidgetScheduler {
  final Future<void> Function() schedule;
  _Scheduler(this.schedule);
  @override
  Future<void> apply(UpdateFrequency frequency) => schedule();
}

AppState _app(_Store store, _Widget widget, _Notifications notifications,
        _Scheduler scheduler) =>
    AppState(
      verseRepository: _Verses(),
      taxonomyRepository: _Taxonomy(),
      localStore: store,
      widgetSync: widget,
      notifications: notifications,
      scheduler: scheduler,
    );

void main() {
  test('abre e conclui onboarding enquanto serviços nativos estão pendentes',
      () async {
    final pending = Completer<void>();
    final store = _Store();
    final app = _app(store, _Widget(() => pending.future),
        _Notifications(() => pending.future), _Scheduler(() => pending.future));
    try {
      await app.bootstrap().timeout(const Duration(seconds: 1));
      expect(app.loading, isFalse);
      expect(app.currentVerse, _verse);
      await app.markOnboarded().timeout(const Duration(seconds: 1));
      expect(store.saved.onboarded, isTrue);
      await app.putOnWidget(_verse).timeout(const Duration(seconds: 1));
    } finally {
      pending.complete();
      await Future<void>.delayed(Duration.zero);
      app.dispose();
    }
  });

  test('falhas das notificações e agendamento não impedem o widget ou o app',
      () async {
    Future<void> fail() async => throw StateError('Serviço indisponível');
    final widget = _Widget(() async {});
    final app = _app(_Store(), widget, _Notifications(fail), _Scheduler(fail));
    await app.bootstrap();
    await Future<void>.delayed(Duration.zero);
    expect(app.loading, isFalse);
    expect(widget.syncs, 1);
    await app.markOnboarded();
    await Future<void>.delayed(Duration.zero);
    expect(app.settings.onboarded, isTrue);
    app.dispose();
  });

  testWidgets('serviços sem resposta expiram sem bloquear o aplicativo',
      (tester) async {
    final pending = Completer<void>();
    final app = _app(_Store(), _Widget(() => pending.future),
        _Notifications(() => pending.future), _Scheduler(() => pending.future));
    final boot = app.bootstrap();
    await tester.pump();
    await boot;
    expect(app.loading, isFalse);
    await tester.pump(const Duration(seconds: 11));
    expect(app.loading, isFalse);
    expect(tester.takeException(), isNull);
    pending.complete();
    await tester.pump();
    app.dispose();
  });

  testWidgets('todos os temas são selecionáveis e não há controles de compra',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = _app(_Store(), _Widget(() async {}),
        _Notifications(() async {}), _Scheduler(() async {}));
    final boot = app.bootstrap();
    await tester.pump();
    await boot;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: app,
      child: const MaterialApp(home: Scaffold(body: AjustesScreen())),
    ));
    for (final theme in WidgetVisualTheme.values) {
      await tester.tap(find.text(theme.label));
      await tester.pump();
      expect(app.settings.widgetTheme, theme);
    }
    expect(find.text('Comprar Premium'), findsNothing);
    expect(find.text('Restaurar compra'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}
