import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/bible/bible_book.dart';
import '../state/app_state.dart';
import 'bible_search_screen.dart';
import 'chapter_reader_screen.dart';

/// Aba "Bíblia": continuar lendo, busca e os livros do Antigo e do Novo
/// Testamento.
class BibliaScreen extends StatelessWidget {
  const BibliaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final gold = Theme.of(context).colorScheme.primary;
    final books = app.visibleBooks;
    final oldT = books.where((b) => b.oldTestament).toList();
    final newT = books.where((b) => !b.oldTestament).toList();
    final last = app.lastRead;
    BibleBook? lastBook;
    int? lastChapter;
    if (last != null) {
      final i = last.lastIndexOf('.');
      lastBook = app.bible.bookByAbbr(last.substring(0, i));
      lastChapter = int.tryParse(last.substring(i + 1));
    }

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BibleSearchScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(children: [
                        Icon(Icons.search_rounded),
                        SizedBox(width: 12),
                        Text('Buscar na Bíblia (ex: "não temas")'),
                      ]),
                    ),
                  ),
                  if (lastBook != null && lastChapter != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(Icons.bookmark_rounded, color: gold),
                        title: const Text('Continuar lendo'),
                        subtitle: Text('${lastBook.name} $lastChapter'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChapterReaderScreen(
                                abbr: lastBook!.abbr, chapter: lastChapter!),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${app.chaptersRead.length} capítulos lidos',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: TabBar(tabs: [
              Tab(text: 'Antigo Testamento'),
              Tab(text: 'Novo Testamento'),
            ]),
          ),
        ],
        body: TabBarView(children: [
          _BookList(books: oldT),
          _BookList(books: newT),
        ]),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BibleBook> books;
  const _BookList({required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final b = books[i];
        return ListTile(
          title: Text(b.name),
          subtitle: Text(
              '${b.chapterCount} capítulo${b.chapterCount == 1 ? '' : 's'}'
              '${b.deuterocanonical ? ' · católico' : ''}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openChapters(context, b),
        );
      },
    );
  }

  void _openChapters(BuildContext context, BibleBook book) {
    if (book.chapterCount == 1) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChapterReaderScreen(abbr: book.abbr, chapter: 1)));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final app = sheetContext.watch<AppState>();
        final gold = Theme.of(sheetContext).colorScheme.primary;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .6,
          maxChildSize: .92,
          builder: (_, controller) => Column(
            children: [
              Text(book.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: book.chapterCount,
                  itemBuilder: (_, i) {
                    final chapter = i + 1;
                    final read = app.chaptersRead
                        .contains(BibleIndex.keyFor(book.abbr, chapter));
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChapterReaderScreen(
                              abbr: book.abbr, chapter: chapter),
                        ));
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: read
                              ? gold.withOpacity(.22)
                              : Theme.of(sheetContext)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        ),
                        child: Text('$chapter',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
