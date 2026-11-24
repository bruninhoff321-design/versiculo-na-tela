import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/domain/bible/bible_book.dart';
import 'package:versiculo_na_tela/domain/models/verse.dart';

Verse _v(String abbr, String book, int c, int n, String text) => Verse(
      id: '$abbr.$c.$n',
      book: book,
      bookAbbr: abbr,
      chapter: c,
      verseNumber: n,
      text: text,
      translationId: 'teste',
      themes: const [],
      keywords: const [],
    );

void main() {
  final verses = [
    _v('sal', 'Salmos', 23, 1, 'O Senhor é o meu pastor; nada me faltará.'),
    _v('sal', 'Salmos', 23, 2, 'Deitar-me faz em pastos verdejantes.'),
    _v('sal', 'Salmos', 91, 1, 'Aquele que habita no esconderijo do Altíssimo.'),
    _v('tob', 'Tobias', 1, 1, 'Livro das palavras de Tobias.'),
    _v('mat', 'Mateus', 11, 28, 'Vinde a mim, todos os que estais cansados.'),
  ];
  final index = BibleIndex.build(verses);

  test('monta livros na ordem com testamento e quantidade de capítulos', () {
    expect(index.books.map((b) => b.abbr), ['sal', 'tob', 'mat']);
    expect(index.bookByAbbr('sal')!.chapterCount, 91);
    expect(index.bookByAbbr('sal')!.oldTestament, isTrue);
    expect(index.bookByAbbr('mat')!.oldTestament, isFalse);
    expect(index.bookByAbbr('tob')!.deuterocanonical, isTrue);
  });

  test('devolve os versículos de um capítulo', () {
    expect(index.chapter('sal', 23).length, 2);
    expect(index.chapter('sal', 5), isEmpty);
  });

  test('busca ignora acentos e maiúsculas e esconde livros pedidos', () {
    expect(index.search('ALTISSIMO').single.id, 'sal.91.1');
    expect(index.search('cansados').single.id, 'mat.11.28');
    expect(index.search('tobias'), hasLength(1));
    expect(index.search('tobias',
        hiddenBooks: BibleIndex.deuterocanonicalAbbrs), isEmpty);
    expect(index.search('a'), isEmpty);
  });
}
