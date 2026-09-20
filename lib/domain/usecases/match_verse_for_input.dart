import 'dart:math';

import '../models/history_entry.dart';
import '../models/verse.dart';

class MatchResult {
  final Verse verse;
  final List<String> matchedThemes;
  const MatchResult({required this.verse, required this.matchedThemes});
}

/// Implementa as seções 9, 11 e 12 do briefing: a função
/// "O que você precisa ouvir?".
///
/// IMPORTANTE (seção 12 do briefing): isto NÃO é geração de texto por IA.
/// É uma correspondência determinística entre (a) os temas dos cartões
/// selecionados + (b) palavras-chave encontradas no texto livre do usuário,
/// contra os temas/palavras-chave já cadastrados em cada versículo real do
/// banco de dados. Nenhum versículo é inventado ou reescrito — a única
/// saída possível é um Verse que já existe em assets/verses.json.
///
/// Se, no futuro, uma etapa de IA for adicionada para interpretar textos
/// mais livres, ela deve ficar restrita a: identificar temas -> chamar este
/// use case com esses temas. Ela nunca deve ter permissão de gerar o campo
/// `text` de um Verse.
class MatchVerseForInputUseCase {
  final Random _random;
  MatchVerseForInputUseCase({Random? random}) : _random = random ?? Random();

  static String normalize(String input) {
    const withDiacritics = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const withoutDiacritics = 'aaaaaeeeeiiiiooooouuuucn';
    var out = input.toLowerCase();
    for (var i = 0; i < withDiacritics.length; i++) {
      out = out.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return out;
  }

  /// [synonyms] é o mapa tema -> palavras-chave normalizadas (ver
  /// ThemeTaxonomyRepository / assets/taxonomia_temas.json).
  MatchResult? call({
    required List<Verse> allVerses,
    required Set<String> selectedThemeIds,
    required String freeText,
    required Map<String, List<String>> synonyms,
    required List<HistoryEntry> recentHistory,
    int recentWindow = 20,
  }) {
    final themes = {...selectedThemeIds};
    final normalizedText = normalize(freeText);
    if (normalizedText.trim().isNotEmpty) {
      synonyms.forEach((theme, keywords) {
        if (keywords.any((kw) => normalizedText.contains(kw))) {
          themes.add(theme);
        }
      });
    }

    if (themes.isEmpty || allVerses.isEmpty) return null;

    final recentIds = recentHistory.length <= recentWindow
        ? recentHistory.map((h) => h.verseId).toSet()
        : recentHistory
            .sublist(recentHistory.length - recentWindow)
            .map((h) => h.verseId)
            .toSet();

    Verse? best;
    var bestScore = -1.0;
    final bestMatchedThemes = <String>{};

    for (final verse in allVerses) {
      final matched = verse.themes.where(themes.contains).toSet();
      if (matched.isEmpty) continue;
      var score = matched.length.toDouble();
      if (recentIds.contains(verse.id)) score -= 0.4; // prioriza não repetidos
      score += _random.nextDouble() * 0.01; // desempata sem viés fixo
      if (score > bestScore) {
        bestScore = score;
        best = verse;
        bestMatchedThemes
          ..clear()
          ..addAll(matched);
      }
    }

    if (best == null) return null;
    return MatchResult(verse: best, matchedThemes: bestMatchedThemes.toList());
  }
}
