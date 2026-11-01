import 'package:flutter/material.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/rubrics/treatment_rubric.dart';
import 'package:musclemind_app/osce/stations/polished_osce_station.dart';

class TreatmentStation6Timed extends TreatmentStationTimed {
  const TreatmentStation6Timed({
    super.key,
    super.examMode = false,
    super.onFinished,
    super.stationDocId = 'treatment',
    super.lessonId = 'lesson_01',
    super.stemOverride,
    super.lessonTitleOverride,
    super.stationTitleOverride,
    super.doorSecondsOverride,
    super.stationSecondsOverride,
    super.warningAtSecondsOverride,
    super.doorSectionTitleOverride,
    super.tasksOverride,
  });
}

class TreatmentStationTimed extends StatelessWidget {
  final bool examMode;
  final void Function(OsceResult result)? onFinished;
  final String stationDocId;
  final String lessonId;
  final String? stemOverride;
  final String? lessonTitleOverride;
  final String? stationTitleOverride;
  final int? doorSecondsOverride;
  final int? stationSecondsOverride;
  final int? warningAtSecondsOverride;
  final String? doorSectionTitleOverride;
  final dynamic tasksOverride;

  const TreatmentStationTimed({
    super.key,
    this.examMode = false,
    this.onFinished,
    this.stationDocId = 'treatment',
    this.lessonId = 'lesson_01',
    this.stemOverride,
    this.lessonTitleOverride,
    this.stationTitleOverride,
    this.doorSecondsOverride,
    this.stationSecondsOverride,
    this.warningAtSecondsOverride,
    this.doorSectionTitleOverride,
    this.tasksOverride,
  });

  @override
  Widget build(BuildContext context) => PolishedOsceStation(
        examMode: examMode,
        onFinished: onFinished,
        stationDocId: stationDocId,
        lessonId: lessonId,
        defaultStationTitle: 'Station 6 — Treatment',
        doorSectionTitle: doorSectionTitleOverride ?? 'TREATMENT',
        stationIcon: Icons.spa_outlined,
        rubric: TreatmentRubric(),
        tasksOverride: tasksOverride,
        stemOverride: stemOverride,
        lessonTitleOverride: lessonTitleOverride,
        stationTitleOverride: stationTitleOverride,
        doorSecondsOverride: doorSecondsOverride,
        stationSecondsOverride: stationSecondsOverride,
        warningAtSecondsOverride: warningAtSecondsOverride,
      );
}
