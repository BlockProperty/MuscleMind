import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OsceExamStation {
  final String stationId;
  final String stationTitle;
  final String lessonId;
  final String lessonTitle;

  OsceExamStation({
    required this.stationId,
    required this.stationTitle,
    required this.lessonId,
    required this.lessonTitle,
  });
}

class OsceExamGenerator {
  static const List<String> stationIds = [
    "therapeutic_exercise",
    "client_interview",
    "assessment_1",
    "assessment_2",
    "initial_treatment_consent",
    "treatment",
    "techniques",
  ];

  static final Random _rand = Random();

  static Future<List<OsceExamStation>> generateExam() async {
    final List<OsceExamStation> result = [];

    for (final stationId in stationIds) {
      try {
        final stationRef = FirebaseFirestore.instance
            .collection('osceStations')
            .doc(stationId);

        final stationDoc = await stationRef.get();

        if (!stationDoc.exists) {
          continue;
        }

        final lessonsSnap = await stationRef
            .collection('lessons')
            .where('isActive', isEqualTo: true)
            .get();

        final lessons = lessonsSnap.docs;

        if (lessons.isEmpty) {
          continue;
        }

        final randomLesson = lessons[_rand.nextInt(lessons.length)];

        final stationTitle =
            (stationDoc.data()?['title'] ?? stationId).toString();

        final lessonData = randomLesson.data();
        final lessonTitle = (lessonData['title'] ?? randomLesson.id).toString();

        result.add(
          OsceExamStation(
            stationId: stationId,
            stationTitle: stationTitle,
            lessonId: randomLesson.id,
            lessonTitle: lessonTitle,
          ),
        );
      } catch (e) {
        continue;
      }
    }

    if (result.isEmpty) {
      throw Exception("No stations could be generated for exam.");
    }

    return result;
  }
}