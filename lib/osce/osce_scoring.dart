import 'osce_models.dart';

/// Legacy compatibility event model.
///
/// Some older station flows may still build a list of events before scoring.
/// Keeping this here prevents analyzer failures while the app finishes
/// migrating to the direct rubric-based scoring flow.
class OsceEvent {
  final String id;

  const OsceEvent({required this.id});
}

OsceResult scoreStation({
  required List<OsceEvent> events,

  /// Accept either:
  /// - OsceRubric
  /// - List<OsceRubricItem>
  required Object rubric,

  /// Optional metadata for newer result model
  String stationTitle = 'OSCE Station',
  String lessonTitle = 'Lesson',
}) {
  final List<OsceRubricItem> rubricItems = _normalizeRubric(rubric);

  final Set<String> performed = <String>{};
  for (final OsceEvent event in events) {
    final String id = _normId(event.id);
    if (id.isNotEmpty) {
      performed.add(id);
    }
  }

  int score = 0;
  int total = 0;

  final Map<String, int> domains = <String, int>{};
  final List<String> feedback = <String>[];

  for (final OsceRubricItem item in rubricItems) {
    final String section = _normSection(item.section);
    final String id = _normId(item.id);
    final int points = item.points < 0 ? 0 : item.points;

    total += points;
    domains.putIfAbsent(section, () => 0);

    if (id.isNotEmpty && performed.contains(id)) {
      score += points;
      domains[section] = (domains[section] ?? 0) + points;
    } else {
      feedback.add('Missed: ${item.label}');
    }
  }

  if (feedback.isEmpty) {
    feedback.add('Excellent performance. No missed items.');
  }

  return OsceResult(
    stationTitle: stationTitle,
    lessonTitle: lessonTitle,
    score: score,
    total: total,
    domains: domains,
    feedback: feedback,
    completedAt: DateTime.now(),
  );
}

List<OsceRubricItem> _normalizeRubric(Object rubric) {
  if (rubric is OsceRubric) {
    return rubric.items;
  }

  if (rubric is List<OsceRubricItem>) {
    return rubric;
  }

  if (rubric is List) {
    final List<OsceRubricItem> out = <OsceRubricItem>[];

    for (final Object? item in rubric) {
      if (item is OsceRubricItem) {
        out.add(item);
      }
    }

    if (out.length == rubric.length) {
      return out;
    }
  }

  throw ArgumentError(
    'rubric must be an OsceRubric or List<OsceRubricItem>; got ${rubric.runtimeType}',
  );
}

String _normSection(String s) {
  final String trimmed = s.trim();
  return trimmed.isEmpty ? 'General' : trimmed;
}

String _normId(String s) {
  return s.trim();
}