import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/audio/prayer_audio_player.dart';
import '../../domain/prayer/prayer_composer.dart';

/// Texto diário e oração por tema, narrada pela voz offline do aparelho.
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
    const composer = PrayerComposer();
    final title = themeIds.isNotEmpty
        ? 'Oração: ${composer.labelFor(themeIds.first) ?? 'para você'}'
        : morning
            ? 'Oração da manhã'
            : 'Oração da noite';
    final today = DateTime.now();
    final prayer = composer.compose(
      day: today,
      morning: morning,
      themeIds: themeIds,
      verseReference: verseReference,
    );
    final prayerId = composer.idFor(
      day: today,
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
            Text('Ouvir esta oração',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Usa a voz em português instalada no seu celular, sem conta nem cobrança. '
              'Toca com música suave ao fundo. A primeira reprodução pode levar '
              'alguns segundos para preparar o áudio.',
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: PrayerAudioPlayer.instance.preparing,
              builder: (context, preparing, _) => StreamBuilder<PlayerState>(
                stream: PrayerAudioPlayer.instance.player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing == true &&
                      PrayerAudioPlayer.instance.currentPrayerId == prayerId;
                  return FilledButton.icon(
                    onPressed: preparing
                        ? null
                        : () async {
                            try {
                              await PrayerAudioPlayer.instance.toggleDaily(
                                text: prayer,
                                id: prayerId,
                              );
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(error is StateError
                                      ? error.message.toString()
                                      : 'Não foi possível preparar a leitura. Verifique a voz em português do aparelho.'),
                                ));
                              }
                            }
                          },
                    icon: Icon(preparing
                        ? Icons.hourglass_top
                        : playing
                            ? Icons.pause
                            : Icons.play_arrow),
                    label: Text(preparing
                        ? 'Preparando áudio...'
                        : playing
                            ? 'Pausar oração'
                            : 'Ouvir oração'),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text('Prévia da voz Onyx',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text(
              'Exemplo fixo de esperança com voz Onyx e música de fundo. '
              'A prévia não muda com o tema. A oração personalizada acima '
              'usa a voz gratuita do aparelho.',
            ),
            const SizedBox(height: 12),
            StreamBuilder<PlayerState>(
              stream: PrayerAudioPlayer.instance.player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing == true &&
                    PrayerAudioPlayer.instance.currentPrayerId == null;
                return FilledButton.icon(
                  onPressed: () async {
                    try {
                      await PrayerAudioPlayer.instance.toggleDemo();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Não foi possível reproduzir a prévia.'),
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
