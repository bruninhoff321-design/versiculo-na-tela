import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/situation.dart';
import '../../domain/models/verse.dart';
import '../shared/share_image.dart';
import '../state/app_state.dart';

class DescubraScreen extends StatefulWidget {
  const DescubraScreen({super.key});

  @override
  State<DescubraScreen> createState() => _DescubraScreenState();
}

class _DescubraScreenState extends State<DescubraScreen> {
  final Set<int> _selected = {};
  final _textController = TextEditingController();
  ({Verse verse, List<String> matchedThemes})? _result;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _find() {
    final app = context.read<AppState>();
    final themeIds = <String>{};
    for (final i in _selected) {
      themeIds.addAll(kSituations[i].themeIds);
    }
    final result = app.findForSituation(
      selectedThemeIds: themeIds,
      freeText: _textController.text,
    );
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma situação ou escreva algo primeiro')),
      );
      return;
    }
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('O que você precisa ouvir?')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Escolha uma ou mais situações',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(kSituations.length, (i) {
              final s = kSituations[i];
              final selected = _selected.contains(i);
              return FilterChip(
                label: Text('${s.emoji} ${s.label}'),
                selected: selected,
                onSelected: (v) => setState(() {
                  v ? _selected.add(i) : _selected.remove(i);
                }),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text('Ou escreva o que você está vivendo',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'Ex: Estou preocupado com meu futuro, estou cheio de contas e não sei o que fazer.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _find,
            child: const Text('Encontrar um versículo'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Talvez você precise ouvir isso hoje.',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  Text('“${_result!.verse.text}”',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(_result!.verse.reference,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Text(
                    // Seção 13: linguagem acolhedora, nunca "Deus está te dizendo isso".
                    'Este versículo pode falar sobre '
                    '${_result!.matchedThemes.take(3).join(", ")}. '
                    'Não é uma mensagem exclusiva para você — é uma reflexão '
                    'para este momento.',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            app.toggleFavorite(_result!.verse.id),
                        child: const Text('Favoritar'),
                      ),
                      OutlinedButton(
                        onPressed: () => shareVerseAsImage(
                          context: context,
                          text: _result!.verse.text,
                          reference: _result!.verse.reference,
                        ),
                        child: const Text('Compartilhar'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await app.putOnWidget(_result!.verse);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Colocado no widget')),
                            );
                          }
                        },
                        child: const Text('Colocar no widget'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
