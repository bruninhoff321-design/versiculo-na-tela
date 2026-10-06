import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/share_image.dart';
import '../shared/verse_note_editor.dart';
import '../state/app_state.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  String? _selectedTheme;

  String _themeLabel(String id) {
    const labels = <String, String>{
      'paz': 'Paz',
      'forca': 'Força',
      'medo': 'Proteção',
      'familia': 'Família',
      'dinheiro': 'Finanças',
      'esperanca': 'Esperança',
      'fe': 'Fé',
      'decisao': 'Direção',
      'tristeza': 'Consolo',
      'ansiedade': 'Ansiedade',
      'gratidao': 'Gratidão',
      'recomeco': 'Recomeço',
    };
    return labels[id] ?? id.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final verses = app.favoritesAsVerses();
    final themeIds = verses.expand((v) => v.themes).toSet().toList()
      ..sort((a, b) => _themeLabel(a).compareTo(_themeLabel(b)));
    final hasUntagged = verses.any((v) => v.themes.isEmpty);
    final selected = _selectedTheme;
    final visible = selected == null
        ? verses
        : verses
            .where((v) => selected == '_sem_tema'
                ? v.themes.isEmpty
                : v.themes.contains(selected))
            .toList();
    final gold = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (verses.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _chip('Todos', null),
                for (final id in themeIds) _chip(_themeLabel(id), id),
                if (hasUntagged) _chip('Outros', '_sem_tema'),
              ],
            ),
          ),
        Expanded(
          child: verses.isEmpty
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Seus versículos salvos aparecerão aqui. Toque no coração de um versículo para guardar.',
                    textAlign: TextAlign.center,
                  ),
                ))
              : visible.isEmpty
                  ? const Center(child: Text('Nenhum favorito neste tema.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final v = visible[i];
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(color: gold.withOpacity(.25)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.reference,
                                  style: TextStyle(
                                      color: gold,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text('“${v.text}”',
                                  style: Theme.of(context).textTheme.bodyLarge),
                              if (v.themes.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(v.themes.map(_themeLabel).join(' · '),
                                    style:
                                        TextStyle(color: gold, fontSize: 13)),
                              ],
                              if (app.notes[v.id]?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 10),
                                Text(app.notes[v.id]!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Escrever reflexão',
                                    icon: const Icon(Icons.edit_note_rounded),
                                    onPressed: () =>
                                        showVerseNoteEditor(context, v),
                                  ),
                                  IconButton(
                                    tooltip: 'Compartilhar',
                                    icon: const Icon(Icons.ios_share),
                                    onPressed: () => shareVerseAsImage(
                                      context: context,
                                      text: v.text,
                                      reference: v.reference,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remover dos favoritos',
                                    icon: Icon(Icons.favorite, color: gold),
                                    onPressed: () => app.toggleFavorite(v.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedTheme == theme,
        onSelected: (_) => setState(() => _selectedTheme = theme),
      ),
    );
  }
}
