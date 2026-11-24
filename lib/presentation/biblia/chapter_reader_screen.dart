import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/audio/speech_service.dart';
import '../../domain/bible/bible_book.dart';
import '../shared/verse_actions.dart';
import '../state/app_state.dart';

/// Leitura de um capítulo. Toque num versículo para marcar, favoritar,
/// anotar, ouvir ou compartilhar.
class ChapterReaderScreen extends StatefulWidget {
  final String abbr;
  final int chapter;
  final int? highlightVerse;

  const ChapterReaderScreen({
    super.key,
    required this.abbr,
    required this.chapter,
    this.highlightVerse,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late String _abbr = widget.abbr;
  late int _chapter = widget.chapter;
  final _scroll = ScrollController();
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AppState>().openChapter(_abbr, _chapter));
      _scrollToFocused();
    });
  }

  /// Leva a leitura até o versículo vindo da busca.
  void _scrollToFocused() {
    final target = widget.highlightVerse;
    if (target == null || target <= 1 || !_scroll.hasClients) return;
    final estimate = (target - 1) * 70.0;
    _scroll.jumpTo(estimate.clamp(0, _scroll.position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _focusKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: .2, duration: const Duration(milliseconds: 250));
      }
    });
  }

  @override
  void dispose() {
    unawaited(SpeechService.instance.stop());
    _scroll.dispose();
    super.dispose();
  }

  String get _speechId => 'cap:$_abbr.$_chapter';

  void _go(String abbr, int chapter) {
    unawaited(SpeechService.instance.stop());
    setState(() {
      _abbr = abbr;
      _chapter = chapter;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    unawaited(context.read<AppState>().openChapter(abbr, chapter));
  }

  /// Próximo/anterior capítulo, passando para o livro seguinte no fim.
  (String, int)? _neighbor(AppState app, int delta) {
    final books = app.visibleBooks;
    final index = books.indexWhere((b) => b.abbr == _abbr);
    if (index < 0) return null;
    final book = books[index];
    final target = _chapter + delta;
    if (target >= 1 && target <= book.chapterCount) return (_abbr, target);
    final nextIndex = index + delta;
    if (nextIndex < 0 || nextIndex >= books.length) return null;
    final next = books[nextIndex];
    return (next.abbr, delta > 0 ? 1 : next.chapterCount);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;
    final book = app.bible.bookByAbbr(_abbr);
    final verses = app.bible.chapter(_abbr, _chapter);
    final scale = app.settings.readingTextSize.scale;
    final read = app.chaptersRead.contains(BibleIndex.keyFor(_abbr, _chapter));
    final prev = _neighbor(app, -1);
    final next = _neighbor(app, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('${book?.name ?? ''} $_chapter'),
        actions: [
          ValueListenableBuilder<String?>(
            valueListenable: SpeechService.instance.speaking,
            builder: (_, speaking, __) => IconButton(
              tooltip: speaking == _speechId ? 'Parar' : 'Ouvir capítulo',
              icon: Icon(speaking == _speechId
                  ? Icons.stop_circle_rounded
                  : Icons.headphones_rounded),
              onPressed: () => SpeechService.instance.toggleParts(_speechId, [
                '${book?.name ?? ''}, capítulo $_chapter.',
                for (final v in verses) v.text,
              ]),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        // Arrastar para o lado troca de capítulo.
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -500 && next != null) _go(next.$1, next.$2);
          if (v > 500 && prev != null) _go(prev.$1, prev.$2);
        },
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          itemCount: verses.length + 1,
          itemBuilder: (context, i) {
            if (i == verses.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: read
                          ? null
                          : () async {
                              await app.markChapterRead(_abbr, _chapter);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Capítulo concluído! Ofensiva: ${app.streak} dia${app.streak == 1 ? '' : 's'} 🔥'),
                                ),
                              );
                            },
                      icon: Icon(read
                          ? Icons.check_circle_rounded
                          : Icons.check_rounded),
                      label: Text(read ? 'Capítulo lido' : 'Concluí a leitura'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (prev != null)
                          TextButton.icon(
                            onPressed: () => _go(prev.$1, prev.$2),
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: const Text('Anterior'),
                          ),
                        const Spacer(),
                        if (next != null)
                          TextButton.icon(
                            onPressed: () => _go(next.$1, next.$2),
                            icon: const Icon(Icons.chevron_right_rounded),
                            label: const Text('Próximo'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }
            final v = verses[i];
            final color = app.highlights[v.id];
            final favorite = app.favoriteIds.contains(v.id);
            final focused = widget.highlightVerse == v.verseNumber &&
                _abbr == widget.abbr &&
                _chapter == widget.chapter;
            return InkWell(
              key: focused ? _focusKey : null,
              borderRadius: BorderRadius.circular(8),
              onTap: () => showVerseActions(context, v),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color != null
                      ? kHighlightColors[color].withOpacity(.28)
                      : focused
                          ? gold.withOpacity(.14)
                          : null,
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${v.verseNumber} ',
                      style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 13 * scale),
                    ),
                    TextSpan(text: v.text),
                    if (favorite)
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.favorite,
                              size: 14, color: Color(0xFFF4A3C4)),
                        ),
                      ),
                  ]),
                  style: TextStyle(fontSize: 18 * scale, height: 1.6),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
