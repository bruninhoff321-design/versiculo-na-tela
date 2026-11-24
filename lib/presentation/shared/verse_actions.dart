import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/audio/speech_service.dart';
import '../../domain/models/verse.dart';
import '../state/app_state.dart';
import 'share_image.dart';
import 'verse_note_editor.dart';

/// Cores do marca-texto (o índice é o que fica salvo).
const kHighlightColors = <Color>[
  Color(0xFFF7D27A), // dourado
  Color(0xFF8FD3A8), // verde
  Color(0xFF8EC5FF), // azul
  Color(0xFFF4A3C4), // rosa
  Color(0xFFC9A7F5), // lilás
];

/// Menu que abre ao tocar num versículo: marcar, favoritar, anotar,
/// compartilhar no status, ouvir e colocar no widget.
Future<void> showVerseActions(BuildContext context, Verse verse) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final app = sheetContext.watch<AppState>();
      final gold = Theme.of(sheetContext).colorScheme.primary;
      final favorite = app.favoriteIds.contains(verse.id);
      final current = app.highlights[verse.id];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(verse.reference,
                  style: TextStyle(
                      color: gold, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Text(verse.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, height: 1.45)),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < kHighlightColors.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => app.setHighlight(
                            verse.id, current == i ? null : i),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: kHighlightColors[i],
                            shape: BoxShape.circle,
                            border: current == i
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: current == i
                              ? const Icon(Icons.check,
                                  size: 20, color: Color(0xFF1C1A15))
                              : null,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (current != null)
                    TextButton(
                      onPressed: () => app.setHighlight(verse.id, null),
                      child: const Text('Limpar'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionChip(
                    icon: favorite ? Icons.favorite : Icons.favorite_border,
                    label: favorite ? 'Favoritado' : 'Favoritar',
                    onTap: () => app.toggleFavorite(verse.id),
                  ),
                  _ActionChip(
                    icon: Icons.edit_note_rounded,
                    label: 'Anotar',
                    onTap: () => showVerseNoteEditor(sheetContext, verse),
                  ),
                  _ActionChip(
                    icon: Icons.ios_share_rounded,
                    label: 'Status / compartilhar',
                    onTap: () => shareVerseAsImage(
                      context: sheetContext,
                      text: verse.text,
                      reference: verse.reference,
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: SpeechService.instance.speaking,
                    builder: (_, speaking, __) => _ActionChip(
                      icon: speaking == verse.id
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      label: speaking == verse.id ? 'Parar' : 'Ouvir',
                      onTap: () => SpeechService.instance.toggle(
                          verse.id, '${verse.text}. ${verse.reference}.'),
                    ),
                  ),
                  _ActionChip(
                    icon: Icons.widgets_outlined,
                    label: 'Pôr no widget',
                    onTap: () async {
                      await app.putOnWidget(verse);
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content: Text('Versículo colocado no widget.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
