import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/verse.dart';
import '../state/app_state.dart';
import 'chapter_reader_screen.dart';

/// Busca por palavras em toda a Bíblia.
class BibleSearchScreen extends StatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Verse> _results = const [];
  String _query = '';

  static const _suggestions = [
    'não temas', 'paz', 'ansiosos', 'força', 'esperança', 'amor',
    'perdão', 'refúgio', 'descanso', 'luz',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _results = _query.length < 2
            ? const []
            : context.read<AppState>().searchBible(_query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _search,
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'Buscar palavras na Bíblia',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _query.length < 2
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () {
                        _controller.text = s;
                        _search(s);
                      },
                    ),
                ],
              ),
            )
          : _results.isEmpty
              ? const Center(child: Text('Nada encontrado.'))
              : ListView.separated(
                  itemCount: _results.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          _results.length >= 200
                              ? 'Mostrando os primeiros 200 resultados'
                              : '${_results.length} resultado${_results.length == 1 ? '' : 's'}',
                        ),
                      );
                    }
                    final v = _results[i - 1];
                    return ListTile(
                      title: Text(v.reference,
                          style: TextStyle(
                              color: gold, fontWeight: FontWeight.w700)),
                      subtitle: Text(v.text),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterReaderScreen(
                            abbr: v.bookAbbr,
                            chapter: v.chapter,
                            highlightVerse: v.verseNumber,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
