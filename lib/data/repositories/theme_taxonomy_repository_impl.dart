import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/repositories/verse_repository.dart';
import '../../domain/usecases/match_verse_for_input.dart';

/// Carrega assets/taxonomia_temas.json e normaliza as palavras-chave
/// (mesma normalização usada em MatchVerseForInputUseCase) para casar
/// contra o texto livre digitado pelo usuário.
class AssetThemeTaxonomyRepository implements ThemeTaxonomyRepository {
  final String assetPath;
  const AssetThemeTaxonomyRepository(
      {this.assetPath = 'assets/taxonomia_temas.json'});

  Map<String, List<String>>? _cache;

  @override
  Future<Map<String, List<String>>> loadSynonyms() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final temas = decoded['temas'] as List<dynamic>;
    final map = <String, List<String>>{};
    for (final tema in temas) {
      final id = tema['id'] as String;
      final keywords = (tema['keywords'] as List<dynamic>)
          .map((k) => MatchVerseForInputUseCase.normalize(k as String))
          .toList();
      map[id] = keywords;
    }
    _cache = map;
    return map;
  }
}
