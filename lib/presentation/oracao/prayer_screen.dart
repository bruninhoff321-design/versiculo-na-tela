import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/audio/prayer_audio_player.dart';
import '../../domain/prayer/prayer_composer.dart';

/// Texto diário e oração por tema. A prévia de áudio é uma demonstração
/// separada; ainda não narra a oração pessoal exibida nesta tela.
class PrayerScreen extends StatelessWidget {
  final bool morning;
  final List<String> themeIds;
  final String? verseReference;

  const PrayerScreen({
    super.key,
    required this.morning,
    this.themeIds = const [],
    this.verseReference,
  });

  @override
  Widget build(BuildContext context) {
    final title = themeIds.isNotEmpty
        ? 'Uma oração para você'
        : morning
            ? 'Oração da manhã'
            : 'Oração da noite';
    final prayer = const PrayerComposer().compose(
      day: DateTime.now(),
      morning: morning,
      themeIds: themeIds,
      verseReference: verseReference,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(morning ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                color: Theme.of(context).colorScheme.primary, size: 44),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Uma palavra para este dia',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text(prayer,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.7)),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            Text('Ouça uma prévia',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Exemplo de oração de esperança com voz gerada por IA e música '
              'de fundo. O áudio diário personalizado ainda está em preparação.',
            ),
            const SizedBox(height: 12),
            StreamBuilder<PlayerState>(
              stream: PrayerAudioPlayer.instance.player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing == true;
                return FilledButton.icon(
                  onPressed: () async {
                    try {
                      await PrayerAudioPlayer.instance.toggleDemo();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Não foi possível reproduzir a prévia.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  label: Text(playing ? 'Pausar prévia' : 'Ouvir prévia'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
