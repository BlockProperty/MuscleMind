import 'package:flutter/material.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/rubrics/assessments_one_rubric.dart';
import 'package:musclemind_app/osce/stations/polished_osce_station.dart';

class AssessmentsOneStationTimed extends StatelessWidget {
  final bool examMode;
  final String stationDocId;
  final String lessonId;
  final String? stemOverride;
  final String? lessonTitleOverride;
  final String? stationTitleOverride;
  final List<String>? tasksOverride;
  final int? doorSecondsOverride;
  final int? stationSecondsOverride;
  final int? warningAtSecondsOverride;
  final String? doorSectionTitleOverride;
  final void Function(OsceResult result)? onFinished;

  const AssessmentsOneStationTimed({
    super.key,
    this.examMode = false,
    this.stationDocId = 'assessment_1',
    this.lessonId = 'lesson_01',
    this.stemOverride,
    this.lessonTitleOverride,
    this.stationTitleOverride,
    this.tasksOverride,
    this.doorSecondsOverride,
    this.stationSecondsOverride,
    this.warningAtSecondsOverride,
    this.doorSectionTitleOverride,
    this.onFinished,
  });

  @override
  Widget build(BuildContext context) => PolishedOsceStation(
        examMode: examMode,
        onFinished: onFinished,
        stationDocId: stationDocId,
        lessonId: lessonId,
        defaultStationTitle: 'Station 3 — Assessment 1',
        doorSectionTitle: doorSectionTitleOverride ?? 'ASSESSMENT 1',
        stationIcon: Icons.accessibility_new_rounded,
        rubric: AssessmentOneRubric(),
        tasksOverride: tasksOverride,
        stemOverride: stemOverride,
        lessonTitleOverride: lessonTitleOverride,
        stationTitleOverride: stationTitleOverride,
        doorSecondsOverride: doorSecondsOverride,
        stationSecondsOverride: stationSecondsOverride,
        warningAtSecondsOverride: warningAtSecondsOverride,
      );
}
