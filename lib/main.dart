import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/app_local_store.dart';
import 'data/notifications/notification_service.dart';
import 'data/purchases/purchase_service.dart';
import 'data/repositories/theme_taxonomy_repository_impl.dart';
import 'data/repositories/verse_repository_impl.dart';
import 'data/widget_bridge/widget_sync_service.dart';
import 'presentation/state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = AppLocalStore();
  await localStore.init();

  final appState = AppState(
    verseRepository: AssetVerseRepository(),
    taxonomyRepository: AssetThemeTaxonomyRepository(),
    localStore: localStore,
    widgetSync: WidgetSyncService(),
    notifications: NotificationService(),
    purchases: PurchaseService(),
  );
  // bootstrap() é assíncrono; a UI mostra um loading (ver app.dart) até
  // terminar, então não precisamos aguardar aqui antes do runApp.
  unawaited(appState.bootstrap());

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const VersiculoNaTelaApp(),
    ),
  );
}
