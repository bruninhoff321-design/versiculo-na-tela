import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/audio/speech_service.dart';
import '../biblia/biblia_screen.dart';
import '../feed/feed_screen.dart';
import '../home/home_screen.dart';
import '../mais/mais_screen.dart';
import '../oracao/orar_screen.dart';
import '../oracao/prayer_screen.dart';
import '../state/app_state.dart';

/// Casca com navegação inferior — Hoje / Bíblia / Palavra / Orar / Mais
/// (seção 2 do briefing). "O que você precisa ouvir?" não é uma aba fixa:
/// é acessado pelo cartão de destaque na Home, como no briefing original.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final ValueNotifier<String?> _openedPrayer;

  @override
  void initState() {
    super.initState();
    _openedPrayer = context.read<AppState>().notifications.openedPrayer;
    _openedPrayer.addListener(_openPrayerFromNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openPrayerFromNotification();
    });
  }

  void _openPrayerFromNotification() {
    final payload = _openedPrayer.value;
    if (payload != 'prayer:morning' && payload != 'prayer:evening') return;
    _openedPrayer.value = null;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PrayerScreen(
        morning: payload == 'prayer:morning',
        themeIds: context.read<AppState>().prayerThemeIds,
      ),
    ));
  }

  @override
  void dispose() {
    _openedPrayer.removeListener(_openPrayerFromNotification);
    super.dispose();
  }

  static const _titles = ['Bíblia e Oração', 'Bíblia', '', 'Orar', 'Mais'];
  static const _screens = [
    HomeScreen(),
    BibliaScreen(),
    FeedScreen(),
    OrarScreen(),
    MaisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final feed = _index == 2;
    return Scaffold(
      appBar: feed ? null : AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i != _index) unawaited(SpeechService.instance.stop());
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny_rounded),
              label: 'Hoje'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Bíblia'),
          NavigationDestination(
              icon: Icon(Icons.swipe_up_alt_outlined),
              selectedIcon: Icon(Icons.swipe_up_alt_rounded),
              label: 'Palavra'),
          NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism_rounded),
              label: 'Orar'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Mais'),
        ],
      ),
    );
  }
}
