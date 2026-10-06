import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/verse.dart';
import '../state/app_state.dart';

Future<void> showVerseNoteEditor(BuildContext context, Verse verse) async {
  final app = context.read<AppState>();
  final controller = TextEditingController(text: app.notes[verse.id] ?? '');
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Minha reflexão · ${verse.reference}'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'O que esta palavra falou ao seu coração?',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await app.saveNote(verse.id, controller.text);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}
