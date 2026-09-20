import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/domain/models/verse.dart';
import 'package:versiculo_na_tela/domain/usecases/match_verse_for_input.dart';

Verse _v(String id, List<String> themes) => Verse(
      id: id,
      book: 'Livro',
      bookAbbr: 'liv',
      chapter: 1,
      verseNumber: 1,
      text: 'texto $id',
      translationId: 'teste',
      themes: themes,
      keywords: const [],
    );

void main() {
  group('MatchVerseForInputUseCase — seções 9, 11 e 12 do briefing', () {
    final verses = [
      _v('dinheiro1', ['dinheiro']),
      _v('medo1', ['medo']),
      _v('dinheiro_medo', ['dinheiro', 'medo']),
      _v('paz1', ['paz']),
    ];
    final synonyms = {
      'dinheiro': ['dinheiro', 'contas', 'financeiro'],
      'medo': ['medo', 'temo'],
    };

    test('nunca inventa versículo: resultado é sempre um dos já existentes', () {
      final useCase = MatchVerseForInputUseCase();
      final result = useCase(
        allVerses: verses,
        selectedThemeIds: {},
        freeText: 'Estou com medo de não pagar minhas contas',
        synonyms: synonyms,
        recentHistory: const [],
      );
      expect(result, isNotNull);
      expect(verses.map((v) => v.id), contains(result!.verse.id));
    });

    test('prioriza o versículo que casa com MAIS temas simultâneos', () {
      final useCase = MatchVerseForInputUseCase();
      final result = useCase(
        allVerses: verses,
        selectedThemeIds: {},
        freeText: 'estou com medo por causa do dinheiro e das contas',
        synonyms: synonyms,
        recentHistory: const [],
      );
      expect(result!.verse.id, 'dinheiro_medo');
    });

    test('sem nenhum tema identificado, não retorna nada (a UI deve pedir mais informação)', () {
      final useCase = MatchVerseForInputUseCase();
      final result = useCase(
        allVerses: verses,
        selectedThemeIds: {},
        freeText: 'algo completamente fora da taxonomia',
        synonyms: synonyms,
        recentHistory: const [],
      );
      expect(result, isNull);
    });

    test('normalize() ignora acentuação e caixa', () {
      expect(MatchVerseForInputUseCase.normalize('AnsIEDADE'), 'ansiedade');
      expect(MatchVerseForInputUseCase.normalize('Solidão'), 'solidao');
    });
  });
}
