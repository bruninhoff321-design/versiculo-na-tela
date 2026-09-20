import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/share_image.dart';
import '../state/app_state.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final verses = app.favoritesAsVerses();

    if (verses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Você ainda não salvou nenhum versículo.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: verses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = verses[i];
        return ListTile(
          title: Text('“${v.text}”',
              style: const TextStyle(fontStyle: FontStyle.italic)),
          subtitle: Text(v.reference),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                icon: const Icon(Icons.ios_share, size: 20),
                onPressed: () => shareVerseAsImage(
                  context: context,
                  text: v.text,
                  reference: v.reference,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => app.toggleFavorite(v.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
