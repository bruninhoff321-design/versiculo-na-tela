enum HistorySource { widget, manual, descubra, diario }

extension HistorySourceLabel on HistorySource {
  /// Rótulo exibido na tela de Histórico (seção 16 do briefing).
  String get label {
    switch (this) {
      case HistorySource.widget:
        return 'Widget';
      case HistorySource.manual:
        return 'Manual';
      case HistorySource.descubra:
        return 'O que você precisa ouvir';
      case HistorySource.diario:
        return 'Versículo automático';
    }
  }

  static HistorySource fromName(String name) {
    return HistorySource.values.firstWhere(
      (s) => s.name == name,
      orElse: () => HistorySource.manual,
    );
  }
}

class HistoryEntry {
  final String verseId;
  final DateTime timestamp;
  final HistorySource source;

  const HistoryEntry({
    required this.verseId,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
        'verseId': verseId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'source': source.name,
      };

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) => HistoryEntry(
        verseId: map['verseId'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        source: HistorySourceLabel.fromName(map['source'] as String),
      );
}
