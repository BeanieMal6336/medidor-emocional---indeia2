import 'dart:convert';

import 'package:flutter/services.dart';

/// Entrada da base de conhecimento em psicologia (extraída dos PDFs).
class MindoKnowledgeEntry {
  final String id;
  final String source;
  final String sourceFile;
  final List<String> topics;
  final List<String> keywords;
  final String content;

  const MindoKnowledgeEntry({
    required this.id,
    required this.source,
    required this.sourceFile,
    required this.topics,
    required this.keywords,
    required this.content,
  });

  factory MindoKnowledgeEntry.fromJson(Map<String, dynamic> json) =>
      MindoKnowledgeEntry(
        id: json['id'] as String,
        source: json['source'] as String,
        sourceFile: json['sourceFile'] as String,
        topics: (json['topics'] as List<dynamic>).map((e) => e.toString()).toList(),
        keywords: (json['keywords'] as List<dynamic>).map((e) => e.toString()).toList(),
        content: json['content'] as String,
      );
}

/// Busca local na memória de conhecimento psicológico do Mindo.
class MindoKnowledgeBase {
  MindoKnowledgeBase._();

  static final MindoKnowledgeBase instance = MindoKnowledgeBase._();

  static const _assetPath = 'assets/data/mindo_psychology_knowledge.json';

  List<MindoKnowledgeEntry> _entries = [];
  bool _loaded = false;

  /// Mapeia tópicos internos do motor para tópicos da base.
  static const Map<String, List<String>> topicMap = {
    'ansiedade': ['ansiedade', 'cognitivo', 'neurociencia', 'clinica'],
    'tristeza': ['tristeza', 'psicanalise', 'clinica', 'trauma'],
    'raiva': ['comportamento', 'clinica', 'relacionamento'],
    'solidão': ['relacionamento', 'psicanalise', 'clinica'],
    'estresse': ['ansiedade', 'organizacional', 'neurociencia', 'clinica'],
    'medo': ['ansiedade', 'trauma', 'clinica'],
    'sono': ['sono', 'neurociencia', 'comportamento'],
    'relacionamento': ['relacionamento', 'psicanalise', 'clinica'],
    'família': ['relacionamento', 'psicanalise', 'clinica'],
    'familia': ['relacionamento', 'psicanalise', 'clinica'],
    'trabalho': ['organizacional', 'ansiedade', 'comportamento'],
    'reframe': ['cognitivo', 'comportamento', 'clinica'],
    'meditação': ['meditacao', 'neurociencia', 'comportamento'],
    'respiração': ['meditacao', 'ansiedade', 'comportamento'],
    'crise': ['clinica', 'trauma', 'ansiedade'],
    'positivo': ['comportamento', 'cognitivo', 'educacao'],
    'psicanalise': ['psicanalise', 'clinica'],
  };

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _entries = (map['entries'] as List<dynamic>)
          .map((e) => MindoKnowledgeEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _loaded = true;
    } catch (_) {
      _entries = [];
      _loaded = true;
    }
  }

  /// Retorna as entradas mais relevantes para a consulta.
  List<MindoKnowledgeEntry> search({
    required String query,
    String? topic,
    int limit = 2,
  }) {
    if (_entries.isEmpty || limit <= 0) return [];

    final normalizedQuery = _normalize(query);
    final queryWords = _tokenize(normalizedQuery);
    final topicHints = topic != null ? (topicMap[topic] ?? [topic]) : <String>[];

    final scored = <({MindoKnowledgeEntry entry, int score})>[];

    for (final entry in _entries) {
      var score = 0;

      for (final hint in topicHints) {
        if (entry.topics.contains(hint)) score += 8;
      }

      for (final kw in entry.keywords) {
        if (normalizedQuery.contains(kw)) score += 5;
      }

      for (final t in entry.topics) {
        if (normalizedQuery.contains(t)) score += 4;
      }

      for (final word in queryWords) {
        if (word.length < 4) continue;
        if (entry.keywords.contains(word)) score += 3;
        if (_normalize(entry.content).contains(word)) score += 1;
      }

      if (score > 0) {
        scored.add((entry: entry, score: score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final seen = <String>{};
    final results = <MindoKnowledgeEntry>[];
    for (final item in scored) {
      if (seen.add(item.entry.id)) {
        results.add(item.entry);
        if (results.length >= limit) break;
      }
    }

    // Fallback por tópico quando não há match textual
    if (results.isEmpty && topicHints.isNotEmpty) {
      for (final entry in _entries) {
        if (entry.topics.any(topicHints.contains)) {
          if (seen.add(entry.id)) {
            results.add(entry);
            if (results.length >= limit) break;
          }
        }
      }
    }

    return results;
  }

  /// Formata um trecho de conhecimento para anexar à resposta do Mindo.
  String formatInsight(MindoKnowledgeEntry entry, {int maxLength = 220}) {
    var text = entry.content.trim();
    if (text.length > maxLength) {
      final cut = text.lastIndexOf(' ', maxLength - 1);
      text = '${text.substring(0, cut > 80 ? cut : maxLength).trim()}…';
    }
    return '📚 **Perspectiva psicológica** (*${entry.source}*):\n"${text.replaceAll('"', "'")}"';
  }

  String enrichResponse({
    required String baseResponse,
    required String query,
    String? topic,
    int maxInsights = 1,
  }) {
    final hits = search(query: query, topic: topic, limit: maxInsights);
    if (hits.isEmpty) return baseResponse;

    final insight = formatInsight(hits.first);
    return '$baseResponse\n\n$insight';
  }

  int get entryCount => _entries.length;

  static String _normalize(String text) {
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u',
      'ç': 'c',
    };
    var result = text.toLowerCase();
    accents.forEach((from, to) {
      result = result.replaceAll(from, to);
    });
    return result;
  }

  static List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length >= 4)
        .toList();
  }
}
