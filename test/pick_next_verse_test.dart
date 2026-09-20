import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:versiculo_na_tela/domain/models/history_entry.dart';
import 'package:versiculo_na_tela/domain/models/verse.dart';
import 'package:versiculo_na_tela/domain/usecases/pick_next_verse.dart';

Verse _v(String id, {String book = 'Livro'}) => Verse(
      id: id,
      book: book,
      bookAbbr: book.substring(0, 3).toLowerCase(),
      chapter: 1,
      verseNumber: 1,
      text: 'texto $id',
      translationId: 'teste',
      themes: const [],
      keywords: const [],
    );

void main() {
  group('PickNextVerseUseCase — seção 7 do briefing (não repetir)', () {
    test('nunca repete um versículo dentro da janela de não-repetição', () {
      final verses = List.generate(20, (i) => _v('v$i'));
      final useCase = PickNextVerseUseCase(random: Random(42));

      final history = <HistoryEntry>[];
      String? currentId;

      for (var i = 0; i < 15; i++) {
        final picked = useCase(
          allVerses: verses,
          history: history,
          noRepeatCount: 10,
          currentVerseId: currentId,
        );
        // Não pode estar entre os últimos 10 mostrados.
        final recentIds =
            history.length <= 10 ? history : history.sublist(history.length - 10);
        expect(recentIds.map((h) => h.verseId), isNot(contains(picked.id)));

        history.add(HistoryEntry(
            verseId: picked.id, timestamp: DateTime.now(), source: HistorySource.manual));
        currentId = picked.id;
      }
    });

    test('com base pequena, relaxa a regra em vez de travar (nunca fica sem conteúdo)', () {
      final verses = [_v('a'), _v('b'), _v('c')]; // só 3 versículos
      final useCase = PickNextVerseUseCase(random: Random(1));
      final history = [
        HistoryEntry(verseId: 'a', timestamp: DateTime.now(), source: HistorySource.manual),
        HistoryEntry(verseId: 'b', timestamp: DateTime.now(), source: HistorySource.manual),
        HistoryEntry(verseId: 'c', timestamp: DateTime.now(), source: HistorySource.manual),
      ];

      // noRepeatCount = 50, mas só existem 3 versículos no total: tem que
      // devolver ALGUMA coisa, nunca lançar exceção nem travar.
      final picked = useCase(
        allVerses: verses,
        history: history,
        noRepeatCount: 50,
        currentVerseId: 'c',
      );
      expect(verses.map((v) => v.id), contains(picked.id));
    });

    test('desativado (noRepeatCount = 0) pode repetir imediatamente, exceto o atual', () {
      final verses = [_v('a'), _v('b')];
      final useCase = PickNextVerseUseCase(random: Random(7));
      final picked = useCase(
        allVerses: verses,
        history: const [],
        noRepeatCount: 0,
        currentVerseId: 'a',
      );
      expect(picked.id, 'b'); // só sobra 'b' ao excluir o atual
    });
  });
}
