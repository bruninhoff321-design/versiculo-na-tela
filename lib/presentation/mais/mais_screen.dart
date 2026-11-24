import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ajustes/ajustes_screen.dart';
import '../descubra/descubra_screen.dart';
import '../favoritos/favoritos_screen.dart';
import '../historico/historico_screen.dart';
import '../shared/widget_setup.dart';
import '../state/app_state.dart';

/// Aba "Mais": progresso, favoritos, histórico, widget e ajustes.
class MaisScreen extends StatelessWidget {
  const MaisScreen({super.key});

  void _push(BuildContext context, String title, Widget body) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: body),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(value: '🔥 ${app.streak}', label: 'dias seguidos'),
                _Stat(value: '🏆 ${app.bestStreak}', label: 'recorde'),
                _Stat(
                    value: '📖 ${app.chaptersRead.length}', label: 'capítulos'),
                _Stat(value: '❤️ ${app.favoriteIds.length}', label: 'favoritos'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: Icon(Icons.favorite_rounded, color: gold),
          title: const Text('Favoritos'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _push(context, 'Favoritos', const FavoritosScreen()),
        ),
        ListTile(
          leading: Icon(Icons.history_rounded, color: gold),
          title: const Text('Histórico'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _push(context, 'Histórico', const HistoricoScreen()),
        ),
        ListTile(
          leading: Icon(Icons.search_rounded, color: gold),
          title: const Text('Encontrar uma palavra para mim'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DescubraScreen())),
        ),
        ListTile(
          leading: Icon(Icons.widgets_rounded, color: gold),
          title: const Text('Versículo na tela do celular (widget)'),
          subtitle: Text(app.currentVerse?.reference ?? ''),
          trailing: IconButton(
            tooltip: 'Trocar o versículo do widget',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: app.requestNewVerse,
          ),
          onTap: () => addWidgetToHome(context),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.church_rounded, color: gold),
          title: const Text('Minha tradição'),
          subtitle: Text(app.isCatholic
              ? 'Católica'
              : 'Evangélica'),
          trailing: const Icon(Icons.swap_horiz_rounded),
          onTap: () => app.setTradition(app.isCatholic ? 'evangelico' : 'catolico'),
        ),
        ListTile(
          leading: Icon(Icons.settings_rounded, color: gold),
          title: const Text('Ajustes'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _push(context, 'Ajustes', const AjustesScreen()),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
