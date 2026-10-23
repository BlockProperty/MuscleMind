import 'package:cloud_firestore/cloud_firestore.dart';

class OsceLesson {
  final String id;
  final String stationId;
  final String stationTitle;
  final String title;
  final int order;
  final String stem;
  final List<String> tasks;

  final int readTimeSeconds;
  final int stationTimeSeconds;
  final int warningTimeSeconds;

  final bool isActive;

  const OsceLesson({
    required this.id,
    required this.stationId,
    required this.stationTitle,
    required this.title,
    required this.order,
    required this.stem,
    required this.tasks,
    required this.readTimeSeconds,
    required this.stationTimeSeconds,
    required this.warningTimeSeconds,
    required this.isActive,
  });

  factory OsceLesson.fromDoc({
    required String stationId,
    required String stationTitle,
    required DocumentSnapshot<Map<String, dynamic>> doc,
  }) {
    final data = doc.data() ?? {};

    return OsceLesson(
      id: doc.id,
      stationId: stationId,
      stationTitle: stationTitle,
      title: (data['title'] ?? '').toString(),
      order: _asInt(data['order'], 0),
      stem: (data['stem'] ?? '').toString(),
      tasks: ((data['tasks'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      readTimeSeconds: _asInt(data['readTimeSeconds'], 120),
      stationTimeSeconds: _asInt(data['stationTimeSeconds'], 600),
      warningTimeSeconds: _asInt(data['warningTimeSeconds'], 180),
      isActive: (data['isActive'] ?? true) as bool,
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
