import 'package:flutter/material.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/rubrics/assessments_two_rubric.dart';
import 'package:musclemind_app/osce/stations/polished_osce_station.dart';

class AssessmentsTwoStationTimed extends StatelessWidget {
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

  const AssessmentsTwoStationTimed({
    super.key,
    this.examMode = false,
    this.stationDocId = 'assessment_2',
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
        defaultStationTitle: 'Station 4 — Assessment 2',
        doorSectionTitle: doorSectionTitleOverride ?? 'ASSESSMENT 2',
        stationIcon: Icons.monitor_heart_outlined,
        rubric: AssessmentTwoRubric(),
        tasksOverride: tasksOverride,
        stemOverride: stemOverride,
        lessonTitleOverride: lessonTitleOverride,
        stationTitleOverride: stationTitleOverride,
        doorSecondsOverride: doorSecondsOverride,
        stationSecondsOverride: stationSecondsOverride,
        warningAtSecondsOverride: warningAtSecondsOverride,
      );
}
