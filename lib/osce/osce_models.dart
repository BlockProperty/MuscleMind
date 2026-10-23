import 'dart:math' as math;

enum OsceMode { exam, practice }

/// =====================================================
/// RUBRIC
/// =====================================================

class OsceRubric {
  final String stationId;
  final String title;
  final List<OsceRubricItem> items;

  const OsceRubric({
    required this.stationId,
    required this.title,
    required this.items,
  });

  int get maxScore => items.fold(0, (sum, i) => sum + i.points);
}

class OsceRubricItem {
  final String id;
  final String label;
  final int points;
  final String section;

  bool completed;

  OsceRubricItem({
    required String id,
    required String label,
    required this.points,
    String? section,
    this.completed = false,
  })  : id = id.trim(),
        label = label.trim(),
        section = (section == null || section.trim().isEmpty)
            ? 'General'
            : section.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'points': points,
        'section': section,
        'completed': completed,
      };

  factory OsceRubricItem.fromJson(Map<String, dynamic> json) {
    return OsceRubricItem(
      id: _asString(json['id']),
      label: _asString(json['label']),
      points: _asInt(json['points'], fallback: 0),
      section: _asString(json['section'], fallback: 'General'),
      completed: json['completed'] == true,
    );
  }
}

/// =====================================================
/// RESULT (UPDATED STRUCTURE)
/// =====================================================

class OsceResult {
  final String stationTitle;
  final String lessonTitle;

  final int score;
  final int total;

  final Map<String, int> domains;
  final List<String> feedback;

  final DateTime completedAt;

  const OsceResult({
    required this.stationTitle,
    required this.lessonTitle,
    required this.score,
    required this.total,
    required this.domains,
    required this.feedback,
    required this.completedAt,
  });

  double get percent => total == 0 ? 0 : (score / total) * 100;

  int get missedPoints => math.max(0, total - score);

  Map<String, dynamic> toJson() => {
        'stationTitle': stationTitle,
        'lessonTitle': lessonTitle,
        'score': score,
        'total': total,
        'domains': domains,
        'feedback': feedback,
        'completedAt': completedAt.toIso8601String(),
      };

  factory OsceResult.fromJson(Map<String, dynamic> json) {
    return OsceResult(
      stationTitle: _asString(json['stationTitle']),
      lessonTitle: _asString(json['lessonTitle']),
      score: _asInt(json['score'], fallback: 0),
      total: _asInt(json['total'], fallback: 0),
      domains: _readIntMap(json['domains']),
      feedback: _readStringList(json['feedback']),
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
    );
  }

  static Map<String, int> _readIntMap(dynamic raw) {
    final out = <String, int>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        out[e.key.toString()] = _asInt(e.value, fallback: 0);
      }
    }
    return out;
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// =====================================================
/// STATION ATTEMPT
/// =====================================================

class OsceStationAttempt {
  final OsceMode mode;
  final String stationId;
  final String stationTitle;
  final String lessonId;
  final String lessonTitle;

  final OsceResult result;

  final DateTime startedAt;
  final DateTime finishedAt;

  const OsceStationAttempt({
    required this.mode,
    required this.stationId,
    required this.stationTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.result,
    required this.startedAt,
    required this.finishedAt,
  });

  Duration get duration => finishedAt.isBefore(startedAt)
      ? Duration.zero
      : finishedAt.difference(startedAt);

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'stationId': stationId,
        'stationTitle': stationTitle,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'result': result.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
      };

  factory OsceStationAttempt.fromJson(Map<String, dynamic> json) {
    final result = OsceResult.fromJson(
      Map<String, dynamic>.from(json['result'] ?? {}),
    );

    return OsceStationAttempt(
      mode: OsceMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => OsceMode.practice,
      ),
      stationId: _asString(json['stationId']),
      stationTitle: _asString(
        json['stationTitle'],
        fallback: result.stationTitle,
      ),
      lessonId: _asString(json['lessonId']),
      lessonTitle: _asString(
        json['lessonTitle'],
        fallback: result.lessonTitle,
      ),
      result: result,
      startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
      finishedAt: DateTime.tryParse(json['finishedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// =====================================================
/// FULL EXAM RESULT
/// =====================================================

class OsceExamResult {
  final List<OsceStationAttempt> attempts;

  const OsceExamResult({required this.attempts});

  int get totalScore => attempts.fold(0, (sum, a) => sum + a.result.score);

  int get maxScore => attempts.fold(0, (sum, a) => sum + a.result.total);

  double get percent => maxScore == 0 ? 0 : (totalScore / maxScore) * 100;

  Duration get totalDuration =>
      attempts.fold(Duration.zero, (sum, a) => sum + a.duration);

  Map<String, int> get domainTotals {
    final out = <String, int>{};

    for (final a in attempts) {
      a.result.domains.forEach((k, v) {
        out[k] = (out[k] ?? 0) + v;
      });
    }

    return out;
  }

  Map<String, dynamic> toJson() => {
        'attempts': attempts.map((a) => a.toJson()).toList(),
      };

  factory OsceExamResult.fromJson(Map<String, dynamic> json) {
    final raw = json['attempts'];
    final attempts = <OsceStationAttempt>[];

    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          attempts.add(
            OsceStationAttempt.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
    }

    return OsceExamResult(attempts: attempts);
  }
}

/// =====================================================
/// HELPERS
/// =====================================================

int _asInt(dynamic v, {required int fallback}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _asString(dynamic v, {String fallback = ''}) {
  return (v ?? fallback).toString().trim();
}