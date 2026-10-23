import '../osce_models.dart';

/// =====================================================
/// Client Interview — Station 2 Rubric (Production Ready)
/// =====================================================
/// Aligned with:
/// - ClientInterviewStationTimed (NEW standardized version)
/// - Class-based rubric system (same as Assessment 1 & 2)
///
/// IMPORTANT:
/// - IDs MUST match the station button IDs exactly
/// =====================================================

class ClientInterviewRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: "client_interview",
    title: "Client Interview — Station 2",
    items: [
      // =========================
      // PROFESSIONALISM
      // =========================
      OsceRubricItem(
        id: "sanitize_hands",
        label: "Sanitizes hands",
        points: 1,
        section: "Professionalism",
      ),
      OsceRubricItem(
        id: "greet_patient",
        label: "Greets patient (and examiner if desired)",
        points: 1,
        section: "Professionalism",
      ),
      OsceRubricItem(
        id: "intro",
        label: "Introduces self to patient",
        points: 1,
        section: "Professionalism",
      ),

      // =========================
      // ORIENTATION & LEGAL
      // =========================
      OsceRubricItem(
        id: "explain_station_flow",
        label: "Explains what will happen (review form + interview goal)",
        points: 2,
        section: "Orientation & Legal",
      ),
      OsceRubricItem(
        id: "legal_form_required",
        label: "Explains form is required by law",
        points: 1,
        section: "Orientation & Legal",
      ),
      OsceRubricItem(
        id: "confidentiality",
        label: "Explains confidentiality",
        points: 1,
        section: "Orientation & Legal",
      ),
      OsceRubricItem(
        id: "update_responsibility",
        label: "Explains updates responsibility",
        points: 1,
        section: "Orientation & Legal",
      ),
      OsceRubricItem(
        id: "record_retention",
        label: "Explains record retention",
        points: 1,
        section: "Orientation & Legal",
      ),

      // =========================
      // REVIEW FORM
      // =========================
      OsceRubricItem(
        id: "review_conditions",
        label: "Reviews conditions",
        points: 1,
        section: "Review Form",
      ),
      OsceRubricItem(
        id: "other_care",
        label: "Clarifies other healthcare involvement",
        points: 1,
        section: "Review Form",
      ),
      OsceRubricItem(
        id: "link_form_to_complaint",
        label: "Links form info to complaint",
        points: 1,
        section: "Review Form",
      ),

      // =========================
      // LORD
      // =========================
      OsceRubricItem(
          id: "lord_location",
          label: "LORD: Location",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "lord_onset", label: "LORD: Onset", points: 1, section: "LORD"),
      OsceRubricItem(
          id: "lord_radiate",
          label: "LORD: Radiate",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "lord_duration",
          label: "LORD: Duration",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "lord_frequency",
          label: "LORD: Frequency",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "lord_intensity",
          label: "LORD: Intensity",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "lord_cause", label: "LORD: Cause", points: 1, section: "LORD"),
      OsceRubricItem(
          id: "lord_characteristics",
          label: "LORD: Characteristics",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "aggravating_relieving",
          label: "Aggravating factors",
          points: 1,
          section: "LORD"),
      OsceRubricItem(
          id: "relieving_factors",
          label: "Relieving factors",
          points: 1,
          section: "LORD"),

      // =========================
      // ADDITIONAL
      // =========================
      OsceRubricItem(
          id: "associated_conditions",
          label: "Associated conditions",
          points: 1,
          section: "Additional"),
      OsceRubricItem(
          id: "other_symptoms",
          label: "Other symptoms",
          points: 1,
          section: "Additional"),
      OsceRubricItem(
          id: "sleep", label: "Sleep impact", points: 1, section: "Additional"),
      OsceRubricItem(
          id: "adl", label: "ADLs impact", points: 1, section: "Additional"),
      OsceRubricItem(
          id: "meds_allergies",
          label: "Medication details",
          points: 1,
          section: "Additional"),

      // =========================
      // PATIENT QUESTION
      // =========================
      OsceRubricItem(
        id: "patient_question_handled",
        label: "Handles patient question appropriately",
        points: 2,
        section: "Patient Question",
      ),

      // =========================
      // CLOSING
      // =========================
      OsceRubricItem(
          id: "thank_patient",
          label: "Thanks patient",
          points: 1,
          section: "Closing"),
      OsceRubricItem(
          id: "next_step_assessment",
          label: "Suggests next step",
          points: 1,
          section: "Closing"),
      OsceRubricItem(
          id: "invite_questions",
          label: "Invites questions",
          points: 1,
          section: "Closing"),
    ],
  );

  // =========================
  // LOGIC
  // =========================

  int calculateScore() {
    return _rubric.items
        .where((i) => i.completed)
        .fold(0, (sum, i) => sum + i.points);
  }

  int get totalPoints {
    return _rubric.items.fold(0, (sum, i) => sum + i.points);
  }

  Map<String, int> buildDomainScores() {
    final map = <String, int>{};

    for (final i in _rubric.items) {
      map.putIfAbsent(i.section, () => 0);
      if (i.completed) {
        map[i.section] = map[i.section]! + i.points;
      }
    }

    return map;
  }

  List<String> buildFeedback() {
    final missing =
        _rubric.items.where((i) => !i.completed).map((i) => i.label).toList();

    if (missing.isEmpty) {
      return ["Excellent performance. All criteria met."];
    }

    return ["Review:", ...missing];
  }

  OsceRubric get rubric => _rubric;
}
