import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/verse.dart';
import '../../domain/repositories/verse_repository.dart';

/// Carrega o banco de versículos embarcado em assets/verses.json.
///
/// Esse arquivo é gerado por scripts/converter_blivre_tsv.py a partir do
/// texto-fonte da Bíblia Livre (BLIVRE) — ver LICENCIAMENTO-TRADUCAO.md.
/// O arquivo incluído neste projeto por padrão é um conjunto inicial
/// curado (não a Bíblia completa) para manter o app leve; ele pode ser
/// substituído por uma base maior sem tocar em nenhuma linha de código
/// desta classe.
class AssetVerseRepository implements VerseRepository {
  final String assetPath;
  const AssetVerseRepository({this.assetPath = 'assets/verses.json'});

  List<Verse>? _cache;

  @override
  Future<List<Verse>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((e) => Verse.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
