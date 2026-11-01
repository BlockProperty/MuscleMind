import 'package:flutter/material.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/rubrics/initial_treatment_consent_rubric.dart';
import 'package:musclemind_app/osce/stations/polished_osce_station.dart';

class InitialTreatmentConsentStationTimed extends StatelessWidget {
  final bool examMode;
  final void Function(OsceResult result)? onFinished;
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

  const InitialTreatmentConsentStationTimed({
    super.key,
    this.examMode = false,
    this.onFinished,
    this.stationDocId = 'initial_treatment_consent',
    this.lessonId = 'lesson_01',
    this.stemOverride,
    this.lessonTitleOverride,
    this.stationTitleOverride,
    this.tasksOverride,
    this.doorSecondsOverride,
    this.stationSecondsOverride,
    this.warningAtSecondsOverride,
    this.doorSectionTitleOverride,
  });

  @override
  Widget build(BuildContext context) => PolishedOsceStation(
        examMode: examMode,
        onFinished: onFinished,
        stationDocId: stationDocId,
        lessonId: lessonId,
        defaultStationTitle: 'Station 5 — Initial Treatment & Consent',
        doorSectionTitle: doorSectionTitleOverride ?? 'INITIAL TREATMENT & CONSENT',
        stationIcon: Icons.handshake_outlined,
        rubric: InitialTreatmentConsentRubric(),
        tasksOverride: tasksOverride,
        stemOverride: stemOverride,
        lessonTitleOverride: lessonTitleOverride,
        stationTitleOverride: stationTitleOverride,
        doorSecondsOverride: doorSecondsOverride,
        stationSecondsOverride: stationSecondsOverride,
        warningAtSecondsOverride: warningAtSecondsOverride,
      );
}
