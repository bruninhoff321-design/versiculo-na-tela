import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/models/situation.dart';
import '../../domain/models/verse.dart';
import '../shared/share_image.dart';
import '../oracao/prayer_screen.dart';
import '../state/app_state.dart';

class DescubraScreen extends StatefulWidget {
  const DescubraScreen({super.key});

  @override
  State<DescubraScreen> createState() => _DescubraScreenState();
}

class _DescubraScreenState extends State<DescubraScreen> {
  static const _featured = <(int, String, IconData)>[
    (4, 'Paz', Icons.spa_outlined),
    (6, 'Força', Icons.bolt_outlined),
    (2, 'Proteção', Icons.shield_outlined),
    (9, 'Família', Icons.people_outline),
    (8, 'Finanças', Icons.savings_outlined),
    (15, 'Direção', Icons.explore_outlined),
    (14, 'Esperança', Icons.wb_sunny_outlined),
    (5, 'Fé', Icons.auto_stories_outlined),
  ];
  final Set<int> _selected = {};
  final _textController = TextEditingController();
  ({Verse verse, List<String> matchedThemes})? _result;
  List<String> _prayerThemeIds = const [];
  bool _showMore = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _find() async {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Escolha um tema ou escreva o que você precisa.'),
      ));
      return;
    }
    final prayerThemes = {...themeIds, ...result.matchedThemes}.toList();
    await app.setPrayerThemes(prayerThemes);
    if (!mounted) return;
    setState(() {
      _result = result;
      _prayerThemeIds = prayerThemes;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;
    final featuredIds = _featured.map((item) => item.$1).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Encontrar uma palavra')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text('O que você precisa hoje?',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Escolha um tema ou conte com suas palavras.'),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _featured.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, position) {
              final (index, label, icon) = _featured[position];
              final selected = _selected.contains(index);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() =>
                    selected ? _selected.remove(index) : _selected.add(index)),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: selected ? gold : gold.withOpacity(.25),
                        width: selected ? 2 : 1),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: selected
                          ? [const Color(0xFF4C3920), const Color(0xFF263243)]
                          : [const Color(0xFF253347), const Color(0xFF17212E)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: gold, size: 25),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _showMore = !_showMore),
            icon: Icon(_showMore ? Icons.remove : Icons.add),
            label: Text(_showMore ? 'Mostrar menos temas' : 'Ver mais temas'),
          ),
          if (_showMore) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < kSituations.length; i++)
                  if (!featuredIds.contains(i))
                    FilterChip(
                      label: Text(kSituations[i].label),
                      selected: _selected.contains(i),
                      onSelected: (value) => setState(
                          () => value ? _selected.add(i) : _selected.remove(i)),
                    ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _textController,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.edit_outlined),
              hintText: 'Ou escreva o que você está sentindo…',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (app.prayerThemeIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await app.setPrayerThemes(const []);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('As próximas orações terão temas variados.'),
                  ));
                }
              },
              icon: const Icon(Icons.shuffle),
              label: const Text('Usar temas variados nas próximas orações'),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: _find,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Encontrar versículo'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 26),
            Text(
              _prayerThemeIds.isEmpty
                  ? 'As próximas orações usarão um tema variado.'
                  : 'As próximas orações também vão considerar o tema que você escolheu.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: gold.withOpacity(.55)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UM VERSÍCULO PARA VOCÊ',
                      style: TextStyle(
                          color: gold,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  const SizedBox(height: 16),
                  Text('“${_result!.verse.text}”',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22 * app.settings.readingTextSize.scale,
                          )),
                  const SizedBox(height: 12),
                  Text(_result!.verse.reference,
                      style:
                          TextStyle(color: gold, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => app.toggleFavorite(_result!.verse.id),
                        icon: Icon(app.favoriteIds.contains(_result!.verse.id)
                            ? Icons.favorite
                            : Icons.favorite_border),
                        label: Text(app.favoriteIds.contains(_result!.verse.id)
                            ? 'Salvo'
                            : 'Favoritar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => shareVerseAsImage(
                          context: context,
                          text: _result!.verse.text,
                          reference: _result!.verse.reference,
                        ),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Compartilhar'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await app.putOnWidget(_result!.verse);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Versículo colocado na tela')),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone_android_outlined),
                        label: const Text('Mostrar na tela'),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PrayerScreen(
                              morning: DateTime.now().hour < 12,
                              themeIds: _prayerThemeIds,
                              verseReference: _result!.verse.reference,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.volunteer_activism_outlined),
                        label: const Text('Fazer uma oração'),
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
