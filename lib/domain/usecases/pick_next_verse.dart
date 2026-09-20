import 'dart:math';

import '../models/history_entry.dart';
import '../models/verse.dart';

/// Implementa as seções 7 e 8 do briefing: seleção "inteligente" com
/// controle de não-repetição.
///
/// Regra: um versículo só pode ser sorteado novamente depois que
/// [noRepeatCount] OUTROS versículos diferentes tiverem sido mostrados.
/// Se não houver versículos elegíveis suficientes (base pequena demais para
/// a regra escolhida), a regra é relaxada automaticamente para nunca deixar
/// o widget sem conteúdo — exatamente como pedido no briefing ("liberar
/// gradualmente os mais antigos; nunca deixar o widget sem conteúdo").
class PickNextVerseUseCase {
  final Random _random;

  PickNextVerseUseCase({Random? random}) : _random = random ?? Random();

  /// [history] deve estar em ordem cronológica (mais antigo primeiro).
  Verse call({
    required List<Verse> allVerses,
    required List<HistoryEntry> history,
    required int noRepeatCount,
    String? currentVerseId,
    bool excludeCurrent = true,
  }) {
    if (allVerses.isEmpty) {
      throw StateError('Banco de versículos vazio — verifique assets/verses.json');
    }

    final recentIds = _recentIds(history, noRepeatCount);
    final exclude = <String>{...recentIds};
    if (excludeCurrent && currentVerseId != null) {
      exclude.add(currentVerseId);
    }

    var pool = allVerses.where((v) => !exclude.contains(v.id)).toList();

    // Base insuficiente para a regra atual: libera gradualmente (primeiro
    // tenta sem excluir o atual, depois usa a base inteira). O widget nunca
    // fica sem conteúdo.
    if (pool.isEmpty && currentVerseId != null) {
      pool = allVerses.where((v) => v.id != currentVerseId).toList();
    }
    if (pool.isEmpty) {
      pool = allVerses;
    }

    return _distributedPick(pool);
  }

  List<String> _recentIds(List<HistoryEntry> history, int noRepeatCount) {
    if (noRepeatCount <= 0) return const [];
    final tail = history.length <= noRepeatCount
        ? history
        : history.sublist(history.length - noRepeatCount);
    return tail.map((h) => h.verseId).toList();
  }

  /// Distribuição levemente ponderada para variar entre livros diferentes
  /// (seção 8: "não escolher sempre os mais famosos" / "distribuir entre
  /// diferentes livros"). Agrupa o pool por livro e sorteia primeiro um
  /// livro, depois um versículo dentro dele — isso evita que livros com
  /// muito mais versículos cadastrados (ex.: Salmos) dominem o sorteio.
  Verse _distributedPick(List<Verse> pool) {
    final byBook = <String, List<Verse>>{};
    for (final v in pool) {
      byBook.putIfAbsent(v.book, () => []).add(v);
    }
    final books = byBook.keys.toList();
    final chosenBook = books[_random.nextInt(books.length)];
    final versesInBook = byBook[chosenBook]!;
    return versesInBook[_random.nextInt(versesInBook.length)];
  }
}
