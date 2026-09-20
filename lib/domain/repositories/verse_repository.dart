import '../models/verse.dart';

/// Contrato da fonte de versículos. A implementação real
/// (data/repositories/verse_repository_impl.dart) carrega de
/// assets/verses.json — ver LICENCIAMENTO-TRADUCAO.md para a origem do
/// texto. Trocar de tradução no futuro = trocar essa implementação, sem
/// tocar no domínio nem na UI.
abstract class VerseRepository {
  Future<List<Verse>> loadAll();
}

/// Contrato da taxonomia de temas/palavras-chave usada pelo matcher de
/// "O que você precisa ouvir?" — ver assets/taxonomia_temas.json.
abstract class ThemeTaxonomyRepository {
  /// Mapa tema -> lista de palavras-chave já normalizadas (minúsculas, sem
  /// acento) usada para casar o texto livre digitado pelo usuário.
  Future<Map<String, List<String>>> loadSynonyms();
}
