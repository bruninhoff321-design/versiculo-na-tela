import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../descubra/descubra_screen.dart';
import '../shared/share_image.dart';
import '../state/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final verse = app.currentVerse;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verse != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '“${verse.text}”',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    verse.reference,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: app.requestNewVerse,
                child: const Text('Novo versículo'),
              ),
              OutlinedButton.icon(
                onPressed: verse == null
                    ? null
                    : () => app.toggleFavorite(verse.id),
                icon: Icon(app.isFavoriteCurrent
                    ? Icons.favorite
                    : Icons.favorite_border),
                label: Text(app.isFavoriteCurrent ? 'Favoritado' : 'Favoritar'),
              ),
              OutlinedButton.icon(
                onPressed: verse == null
                    ? null
                    : () => shareVerseAsImage(
                          context: context,
                          text: verse.text,
                          reference: verse.reference,
                        ),
                icon: const Icon(Icons.ios_share),
                label: const Text('Compartilhar'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('O que você precisa ouvir hoje?',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Conte o que você está vivendo ou escolha o que está sentindo.',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DescubraScreen()),
                    ),
                    child: const Text('Abrir'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
