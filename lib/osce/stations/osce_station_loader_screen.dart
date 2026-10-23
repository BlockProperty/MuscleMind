import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'client_interview_station_timed.dart';
import 'therapeutic_exercise_station_timed.dart';
import 'assessments_one_station_timed.dart';
import 'assessments_two_station_timed.dart';
import 'initial_treatment_consent_station_timed.dart';
import 'treatment_station_timed.dart';
import 'techniques_station_timed.dart';

class OsceStationLoaderScreen extends StatelessWidget {
  final String stationId;
  final String lessonId;

  const OsceStationLoaderScreen({
    super.key,
    required this.stationId,
    required this.lessonId,
  });

  Future<Map<String, dynamic>> _load() async {
    final stationDoc = await FirebaseFirestore.instance
        .collection('osceStations')
        .doc(stationId)
        .get();

    final lessonDoc = await FirebaseFirestore.instance
        .collection('osceStations')
        .doc(stationId)
        .collection('lessons')
        .doc(lessonId)
        .get();

    final stationData = stationDoc.data() ?? <String, dynamic>{};
    final lessonData = lessonDoc.data() ?? <String, dynamic>{};

    final dynamic rawTasks = lessonData['tasks'];

    List<dynamic> normalizedTasks = <dynamic>[];
    if (rawTasks is List) {
      normalizedTasks = rawTasks.map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }
        return e;
      }).toList();
    }

    return {
      'stationTitle':
          (stationData['stationTitle'] ?? stationData['title'] ?? '')
              .toString(),
      'lessonTitle': (lessonData['title'] ?? '').toString(),
      'stem': (lessonData['stem'] ?? '').toString(),
      'tasks': normalizedTasks,
      'readTimeSeconds': lessonData['readTimeSeconds'] ?? 120,
      'stationTimeSeconds': lessonData['stationTimeSeconds'] ?? 600,
      'warningTimeSeconds': lessonData['warningTimeSeconds'] ?? 180,
    };
  }

  List<String> _stringTasks(dynamic tasks) {
    if (tasks is! List) return const <String>[];
    return tasks.map((e) {
      if (e is Map) {
        final map = Map<String, dynamic>.from(e);
        return (map['label'] ?? map['task'] ?? '').toString();
      }
      return e.toString();
    }).where((e) => e.trim().isNotEmpty).toList();
  }

  List<dynamic> _dynamicTasks(dynamic tasks) {
    if (tasks is! List) return const <dynamic>[];
    return List<dynamic>.from(tasks);
  }

  Widget _buildStation(BuildContext context, Map<String, dynamic> data) {
    final dynamic tasks = data['tasks'] ?? <dynamic>[];

    switch (stationId) {
      case 'client_interview':
        return ClientInterviewStationTimed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          tasksOverride: _stringTasks(tasks),
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      case 'therapeutic_exercise':
        return TherapeuticExerciseStationTimed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          tasksOverride: _dynamicTasks(tasks),
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      case 'assessment_1':
        return AssessmentsOneStationTimed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      case 'assessment_2':
        return AssessmentsTwoStationTimed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          tasksOverride: _stringTasks(tasks),
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      case 'initial_treatment_consent':
        return InitialTreatmentConsentStationTimed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          tasksOverride: _stringTasks(tasks),
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      case 'treatment':
        return TreatmentStation6Timed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          tasksOverride: _dynamicTasks(tasks),
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      case 'techniques':
        return TechniquesStationTimed(
          stationDocId: stationId,
          lessonId: lessonId,
          stemOverride: data['stem'] as String?,
          lessonTitleOverride: data['lessonTitle'] as String?,
          stationTitleOverride: data['stationTitle'] as String?,
          tasksOverride: _stringTasks(tasks),
          doorSecondsOverride: data['readTimeSeconds'] as int?,
          stationSecondsOverride: data['stationTimeSeconds'] as int?,
          warningAtSecondsOverride: data['warningTimeSeconds'] as int?,
        );

      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Station Error')),
          body: Center(
            child: Text('Unknown stationId: $stationId'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _LoaderUI(stationId: stationId);
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Load Error')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load station: ${snapshot.error}'),
            ),
          );
        }

        final data = snapshot.data ?? <String, dynamic>{};

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _buildStation(context, data),
            ),
          );
        });

        return _LoaderUI(stationId: stationId);
      },
    );
  }
}

class _LoaderUI extends StatelessWidget {
  final String stationId;

  const _LoaderUI({required this.stationId});

  static const Color _blue = Color(0xFF39C2FF);

  String _title() {
    switch (stationId) {
      case 'client_interview':
        return 'CLIENT INTERVIEW';
      case 'therapeutic_exercise':
        return 'THERAPEUTIC EXERCISE';
      case 'assessment_1':
        return 'ASSESSMENT 1';
      case 'assessment_2':
        return 'ASSESSMENT 2';
      case 'initial_treatment_consent':
        return 'INITIAL TREATMENT';
      case 'treatment':
        return 'TREATMENT';
      case 'techniques':
        return 'TECHNIQUES';
      default:
        return 'OSCE STATION';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _blue.withOpacity(0.35),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/musclemind_icon.png',
                width: 90,
                height: 90,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _title(),
              style: const TextStyle(
                color: _blue,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Preparing simulation...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(_blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}