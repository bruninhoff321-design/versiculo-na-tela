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
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  Image.asset('assets/brand_icon.png', width: 56, height: 56),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Uma palavra para hoje',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ))),
          ]),
          const SizedBox(height: 6),
          const Text('Que a Palavra de Deus acompanhe o seu dia.'),
          const SizedBox(height: 20),
          if (verse != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.primary.withOpacity(0.13),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_stories_rounded,
                      size: 34, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 20),
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
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: app.requestNewVerse,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Mostrar outro versículo'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await app.setLockWallpaperEnabled(!app.lockWallpaperEnabled);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(app.lockWallpaperEnabled
                          ? 'Versículo ativado na tela de bloqueio'
                          : 'Atualização da tela de bloqueio desativada'),
                    ));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Este celular não permitiu alterar a tela de bloqueio.'),
                    ));
                  }
                }
              },
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(app.lockWallpaperEnabled
                  ? 'Parar atualização da tela de bloqueio'
                  : 'Mostrar na tela de bloqueio'),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed:
                    verse == null ? null : () => app.toggleFavorite(verse.id),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_outline,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Precisa de uma palavra?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Conte o que está vivendo. Vamos encontrar um versículo para refletir.',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color),
                          ),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DescubraScreen()),
                        ),
                        child: const Text('Encontrar uma palavra'),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
