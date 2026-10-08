import 'package:flutter/material.dart';

import '../../domain/prayer/prayer_composer.dart';

/// Texto diário e oração por tema. A narração será ligada quando houver uma
/// voz que possa ser usada para gerar os áudios de cada nova oração.
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
          ],
        ),
      ),
    );
  }
}
