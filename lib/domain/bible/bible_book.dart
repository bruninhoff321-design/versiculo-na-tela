import '../models/verse.dart';

/// Um livro da Bíblia montado a partir da lista de versículos embarcada.
class BibleBook {
  final String abbr; // ex: "sal"
  final String name; // ex: "Salmos"
  final int order; // posição na Bíblia, começando em 0
  final bool oldTestament;
  final bool deuterocanonical;
  final int chapterCount;

  const BibleBook({
    required this.abbr,
    required this.name,
    required this.order,
    required this.oldTestament,
    required this.chapterCount,
    this.deuterocanonical = false,
  });
}

/// Índice da Bíblia: livros na ordem, capítulos e busca por palavra.
class BibleIndex {
  final List<BibleBook> books;
  final Map<String, List<Verse>> _chapters;
  final List<Verse> _all;
  List<String>? _normalized;

  BibleIndex._(this.books, this._chapters, this._all);

  /// Livros que existem só no cânon católico. Ficam escondidos para quem
  /// escolheu a tradição evangélica.
  static const deuterocanonicalAbbrs = {
    'tob', 'jdt', 'sab', 'eclo', 'bar', '1mac', '2mac',
  };

  /// Os 39 livros do Antigo Testamento protestante + os deuterocanônicos.
  static const _newTestamentStart = 'mat';

  factory BibleIndex.build(List<Verse> verses) {
    final books = <BibleBook>[];
    final chapters = <String, List<Verse>>{};
    final chapterCounts = <String, int>{};
    final names = <String, String>{};
    final order = <String>[];
    for (final v in verses) {
      if (!names.containsKey(v.bookAbbr)) {
        names[v.bookAbbr] = v.book;
        order.add(v.bookAbbr);
      }
      chapters.putIfAbsent(keyFor(v.bookAbbr, v.chapter), () => []).add(v);
      final current = chapterCounts[v.bookAbbr] ?? 0;
      if (v.chapter > current) chapterCounts[v.bookAbbr] = v.chapter;
    }
    var inOld = true;
    for (var i = 0; i < order.length; i++) {
      final abbr = order[i];
      if (abbr == _newTestamentStart) inOld = false;
      books.add(BibleBook(
        abbr: abbr,
        name: names[abbr]!,
        order: i,
        oldTestament: inOld,
        chapterCount: chapterCounts[abbr] ?? 1,
        deuterocanonical: deuterocanonicalAbbrs.contains(abbr),
      ));
    }
    return BibleIndex._(books, chapters, verses);
  }

  static String keyFor(String abbr, int chapter) => '$abbr.$chapter';

  BibleBook? bookByAbbr(String abbr) {
    for (final b in books) {
      if (b.abbr == abbr) return b;
    }
    return null;
  }

  List<Verse> chapter(String abbr, int chapter) =>
      _chapters[keyFor(abbr, chapter)] ?? const [];

  /// Busca simples por palavras (sem acento, sem diferenciar maiúsculas).
  /// Todas as palavras digitadas precisam aparecer no versículo.
  List<Verse> search(String query,
      {int limit = 200, Set<String> hiddenBooks = const {}}) {
    final words = normalize(query)
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
    if (words.isEmpty) return const [];
    final normalized = _normalized ??= [for (final v in _all) normalize(v.text)];
    final results = <Verse>[];
    for (var i = 0; i < _all.length; i++) {
      final text = normalized[i];
      if (words.every(text.contains) &&
          !hiddenBooks.contains(_all[i].bookAbbr)) {
        results.add(_all[i]);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  static String normalize(String input) {
    const withDiacritics = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const withoutDiacritics = 'aaaaaeeeeiiiiooooouuuucn';
    var out = input.toLowerCase();
    for (var i = 0; i < withDiacritics.length; i++) {
      out = out.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return out;
  }
}
