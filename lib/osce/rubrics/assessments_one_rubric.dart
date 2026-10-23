import '../osce_models.dart';

/// =====================================================
/// Assessment 1 — Station 3 Rubric (Production Ready)
/// =====================================================
/// ⚠️ IMPORTANT:
/// - IDs MUST match checklist usage in timed station
/// - This file is now fully compatible with:
///   AssessmentOneStationTimed
/// =====================================================

class AssessmentOneRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: "assessment_1",
    title: "Assessment 1 — Station 3",
    items: [
      // =========================
      // Performance / Entry
      // =========================
      OsceRubricItem(
        id: "sanitize_hands",
        label: "Sanitize hands",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "greet",
        label: "Greet patient (and examiner if desired)",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "introduce_self",
        label: "Introduce yourself",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "explain_flow",
        label: "Explain station flow (purpose / procedure / interpretation)",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "hands_on_consent",
        label: "Mention hands-on guidance + consent",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "warn_recreate_symptoms",
        label: "Warn that assessments may recreate symptoms",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "bilateral_unaffected_first",
        label: "If bilateral: test unaffected side first",
        points: 1,
        section: "Performance",
      ),
      OsceRubricItem(
        id: "questions_understanding",
        label: "Offer questions + confirm understanding",
        points: 1,
        section: "Performance",
      ),

      // =========================
      // Purpose / Procedure
      // =========================
      OsceRubricItem(
        id: "purpose_condition_structure",
        label: "Explain purpose (condition / injury / structure)",
        points: 1,
        section: "Purpose / Procedure",
      ),
      OsceRubricItem(
        id: "explain_structure_condition",
        label: "Explain structure / condition in lay terms",
        points: 1,
        section: "Purpose / Procedure",
      ),
      OsceRubricItem(
        id: "procedure_position_hand_action",
        label: "Explain procedure (position / hand placement / action)",
        points: 1,
        section: "Purpose / Procedure",
      ),
      OsceRubricItem(
        id: "permission_right_to_stop",
        label: "Ask permission + explain right to stop",
        points: 1,
        section: "Purpose / Procedure",
      ),
      OsceRubricItem(
        id: "painful_rom_last",
        label: "Perform painful ROM last when appropriate",
        points: 1,
        section: "Purpose / Procedure",
      ),

      // =========================
      // Palpation
      // =========================
      OsceRubricItem(
        id: "palpation_definition",
        label: "Explain definition of palpation",
        points: 1,
        section: "Palpation",
      ),
      OsceRubricItem(
        id: "palpation_structure_education",
        label: "Educate structure (origin / insertion / action)",
        points: 1,
        section: "Palpation",
      ),
      OsceRubricItem(
        id: "palpate_entire_structure",
        label: "Palpate entire structure",
        points: 1,
        section: "Palpation",
      ),
      OsceRubricItem(
        id: "confirm_palpation_correct",
        label: "Confirm palpation using movement or resisted contraction",
        points: 1,
        section: "Palpation",
      ),
      OsceRubricItem(
        id: "palpation_inquire_pain",
        label: "Ask about pain during palpation",
        points: 1,
        section: "Palpation",
      ),

      // =========================
      // ROM
      // =========================
      OsceRubricItem(
        id: "arom_observation",
        label: "AROM: observe pain / compensation / rhythm",
        points: 1,
        section: "ROM",
      ),
      OsceRubricItem(
        id: "arom_degree_compare",
        label: "AROM: determine range + compare to normal",
        points: 1,
        section: "ROM",
      ),
      OsceRubricItem(
        id: "arom_inquire_pain",
        label: "AROM: ask about pain",
        points: 1,
        section: "ROM",
      ),
      OsceRubricItem(
        id: "prom_observation",
        label: "PROM: observe pain / compensation / rhythm",
        points: 1,
        section: "ROM",
      ),
      OsceRubricItem(
        id: "prom_end_feel",
        label: "PROM: determine end feel",
        points: 1,
        section: "ROM",
      ),
      OsceRubricItem(
        id: "prom_inquire_pain",
        label: "PROM: ask about pain",
        points: 1,
        section: "ROM",
      ),
      OsceRubricItem(
        id: "rrom_strength_grade",
        label: "RROM: assess strength, pain/weakness, and grade",
        points: 1,
        section: "ROM",
      ),

      // =========================
      // Interpretation
      // =========================
      OsceRubricItem(
        id: "determine_pos_neg",
        label: "Determine positive vs negative findings",
        points: 1,
        section: "Interpretation",
      ),
      OsceRubricItem(
        id: "inform_results",
        label: "Inform patient of results",
        points: 1,
        section: "Interpretation",
      ),
      OsceRubricItem(
        id: "explain_pos_neg_indicates",
        label: "Explain what positive / negative findings indicate",
        points: 1,
        section: "Interpretation",
      ),
      OsceRubricItem(
        id: "clinical_impression",
        label: "Provide brief clinical impression",
        points: 1,
        section: "Interpretation",
      ),
    ],
  );

  // =====================================================
  // Helpers (REQUIRED for timed station)
  // =====================================================

  int calculateScore() {
    return _rubric.items
        .where((item) => item.completed)
        .fold(0, (sum, item) => sum + item.points);
  }

  int get totalPoints {
    return _rubric.items.fold(0, (sum, item) => sum + item.points);
  }

  Map<String, int> buildDomainScores() {
    final Map<String, int> scores = {};

    for (final item in _rubric.items) {
      if (!scores.containsKey(item.section)) {
        scores[item.section] = 0;
      }

      if (item.completed) {
        scores[item.section] = (scores[item.section] ?? 0) + item.points;
      }
    }

    return scores;
  }

  List<String> buildFeedback() {
    final missing = _rubric.items
        .where((item) => !item.completed)
        .map((item) => item.label)
        .toList();

    if (missing.isEmpty) {
      return ["Excellent performance. All key criteria met."];
    }

    return [
      "Review the following areas:",
      ...missing,
    ];
  }

  OsceRubric get rubric => _rubric;
}
