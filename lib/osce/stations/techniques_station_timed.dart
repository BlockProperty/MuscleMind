import 'package:flutter/material.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/rubrics/techniques_rubric.dart';
import 'package:musclemind_app/osce/stations/polished_osce_station.dart';

class TechniquesStationTimed extends StatelessWidget {
  final bool examMode;
  final List<dynamic>? tasksOverride;
  final String lessonId;
  final String stationDocId;
  final void Function(OsceResult result)? onFinished;
  final String? stemOverride;
  final String? lessonTitleOverride;
  final String? stationTitleOverride;
  final int? doorSecondsOverride;
  final int? stationSecondsOverride;
  final int? warningAtSecondsOverride;

  const TechniquesStationTimed({
    super.key,
    this.examMode = false,
    this.tasksOverride,
    this.onFinished,
    this.lessonId = 'lesson_01',
    this.stationDocId = 'techniques',
    this.stemOverride,
    this.lessonTitleOverride,
    this.stationTitleOverride,
    this.doorSecondsOverride,
    this.stationSecondsOverride,
    this.warningAtSecondsOverride,
  });

  @override
  Widget build(BuildContext context) => PolishedOsceStation(
        examMode: examMode,
        onFinished: onFinished,
        stationDocId: stationDocId,
        fallbackStationDocId: 'station_7',
        lessonId: lessonId,
        defaultStationTitle: 'Station 7 — Techniques',
        doorSectionTitle: 'TECHNIQUES',
        stationIcon: Icons.pan_tool_alt_outlined,
        rubric: TechniquesRubric(),
        tasksOverride: tasksOverride,
        stemOverride: stemOverride,
        lessonTitleOverride: lessonTitleOverride,
        stationTitleOverride: stationTitleOverride,
        doorSecondsOverride: doorSecondsOverride,
        stationSecondsOverride: stationSecondsOverride,
        warningAtSecondsOverride: warningAtSecondsOverride,
      );
}
