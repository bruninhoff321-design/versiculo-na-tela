import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/verse.dart';
import '../../domain/repositories/verse_repository.dart';

/// Carrega o banco de versículos embarcado em assets/verses.json.
///
/// Esse arquivo é gerado por scripts/importar_biblia_livre.py a partir da
/// Bíblia Livre (BLIVRE) 2018.2.0 — ver LICENCIAMENTO-TRADUCAO.md.
class AssetVerseRepository implements VerseRepository {
  final String assetPath;
  AssetVerseRepository({this.assetPath = 'assets/verses.json'});

  List<Verse>? _cache;

  @override
  Future<List<Verse>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache =
        decoded.map((e) => Verse.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }
}
