import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/osce_lesson.dart';

class OsceLessonsRepo {
  final FirebaseFirestore _db;

  OsceLessonsRepo(this._db);

  Future<List<OsceLesson>> fetchLessons(String stationId) async {
    try {
      final stationSnap =
          await _db.collection('osceStations').doc(stationId).get();

      final stationData = stationSnap.data() ?? {};

      final String stationTitle =
          (stationData['title'] ??
                  stationData['stationTitle'] ??
                  _fallbackStationTitle(stationId))
              .toString()
              .trim();

      final QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection('osceStations')
          .doc(stationId)
          .collection('lessons')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(10)
          .get();

      return snap.docs.map((doc) {
        return OsceLesson.fromDoc(
          stationId: stationId,
          stationTitle: stationTitle.isEmpty
              ? _fallbackStationTitle(stationId)
              : stationTitle,
          doc: doc,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _fallbackStationTitle(String stationId) {
    switch (stationId) {
      case 'therapeutic_exercise':
        return 'Station 1 — Therapeutic Exercise';
      case 'client_interview':
        return 'Station 2 — Client Interview';
      case 'assessment_1':
        return 'Station 3 — Assessment 1';
      case 'assessment_2':
        return 'Station 4 — Assessment 2';
      case 'initial_treatment_consent':
        return 'Station 5 — Initial Treatment & Consent';
      case 'treatment':
        return 'Station 6 — Treatment';
      case 'techniques':
        return 'Station 7 — Techniques';
      default:
        return 'OSCE Station';
    }
  }
}