import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final entries = app.recentHistoryWithVerses();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum versículo exibido ainda.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = entries[i];
        final preview = item.verse.text.length > 90
            ? '${item.verse.text.substring(0, 90)}…'
            : item.verse.text;
        return ListTile(
          title: Text('“$preview”',
              style: const TextStyle(fontStyle: FontStyle.italic)),
          subtitle: Text(
            '${item.verse.reference} · '
            '${formatter.format(item.entry.timestamp)} · '
            '${item.entry.source.label}',
          ),
        );
      },
    );
  }
}
