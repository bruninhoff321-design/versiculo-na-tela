/// Representa um único versículo já existente na base de dados local.
///
/// Este objeto é somente leitura em tempo de execução: o app nunca gera ou
/// modifica o texto de um versículo, apenas seleciona entre os que já
/// existem em assets/verses.json (ver LICENCIAMENTO-TRADUCAO.md na raiz do
/// projeto para a origem e a licença do texto).
class Verse {
  final String id; // ex: "sal.23.1"
  final String book; // ex: "Salmos"
  final String bookAbbr; // ex: "sal"
  final int chapter;
  final int verseNumber;
  final String text;
  final String translationId; // ex: "blivre-tr" — permite trocar de tradução no futuro
  final List<String> themes;
  final List<String> keywords;

  const Verse({
    required this.id,
    required this.book,
    required this.bookAbbr,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    required this.translationId,
    required this.themes,
    required this.keywords,
  });

  String get reference => '$book $chapter:$verseNumber';

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as String,
      book: json['book'] as String,
      bookAbbr: (json['bookAbbr'] as String?) ?? '',
      chapter: json['chapter'] as int,
      verseNumber: json['verse'] as int,
      text: json['text'] as String,
      translationId: (json['translationId'] as String?) ?? 'desconhecida',
      themes: (json['themes'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': book,
        'bookAbbr': bookAbbr,
        'chapter': chapter,
        'verse': verseNumber,
        'text': text,
        'translationId': translationId,
        'themes': themes,
        'keywords': keywords,
      };
}
