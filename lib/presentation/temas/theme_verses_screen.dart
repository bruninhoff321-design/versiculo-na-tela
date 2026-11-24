import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/audio/speech_service.dart';
import '../../domain/models/situation.dart';
import '../oracao/prayer_screen.dart';
import '../shared/verse_actions.dart';
import '../sos/breathing_screen.dart';
import '../state/app_state.dart';

/// "Como você está?" → versículos para esse momento e uma oração.
class ThemeVersesScreen extends StatelessWidget {
  final Situation situation;
  const ThemeVersesScreen({super.key, required this.situation});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;
    final verses = [
      for (final id in situation.themeIds) ...app.versesForTheme(id),
    ];
    final hour = DateTime.now().hour;
    final anxious = situation.themeIds
        .any((t) => t == 'ansiedade' || t == 'medo' || t == 'fase_dificil');

    return Scaffold(
      appBar: AppBar(title: Text('${situation.emoji} ${situation.label}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const Text(
            'Deus tem uma palavra para este momento. Leia com calma, '
            'ouça e guarde no coração.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PrayerScreen(
                morning: hour >= 3 && hour < 15,
                themeIds: situation.themeIds,
              ),
            )),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Ouvir uma oração por isso'),
          ),
          if (anxious) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BreathingScreen())),
              icon: const Icon(Icons.spa_rounded),
              label: const Text('Respirar com Deus (1 minuto)'),
            ),
          ],
          const SizedBox(height: 20),
          if (verses.isEmpty)
            const Text('Ainda não temos versículos separados para este tema.'),
          for (final v in verses)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showVerseActions(context, v),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('“${v.text}”',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 20)),
                      Row(
                        children: [
                          Expanded(
                            child: Text(v.reference,
                                style: TextStyle(
                                    color: gold,
                                    fontWeight: FontWeight.w800)),
                          ),
                          ValueListenableBuilder<String?>(
                            valueListenable: SpeechService.instance.speaking,
                            builder: (_, speaking, __) => IconButton(
                              icon: Icon(speaking == v.id
                                  ? Icons.stop_rounded
                                  : Icons.volume_up_rounded),
                              onPressed: () => SpeechService.instance
                                  .toggle(v.id, '${v.text}. ${v.reference}.'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(app.favoriteIds.contains(v.id)
                                ? Icons.favorite
                                : Icons.favorite_border),
                            onPressed: () => app.toggleFavorite(v.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
