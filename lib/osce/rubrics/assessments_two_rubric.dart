import '../osce_models.dart';

/// =====================================================
/// Assessment 2 — Station 4 Rubric
/// =====================================================
/// Aligned with:
/// - AssessmentsTwoStationTimed
/// - class-based rubric usage
/// - stationDocId: assessment_2
///
/// IMPORTANT:
/// - IDs must match the score button IDs exactly
/// =====================================================

class AssessmentTwoRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: 'assessment_2',
    title: 'Assessment 2 — Station 4',
    items: [
      // =========================
      // Performance
      // =========================
      OsceRubricItem(
        id: 'sanitize_hands',
        label: 'Sanitize hands',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'greet',
        label: 'Greet patient (and examiner if desired)',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'introduce_self',
        label: 'Introduce yourself',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'explain_flow',
        label: 'Explain station flow (explain before performing)',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'hands_on_consent',
        label: 'Hands-on guidance + consent as needed',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'warn_recreate_symptoms',
        label: 'Warn assessments may recreate symptoms',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'bilateral_unaffected_first',
        label: 'If bilateral: start unaffected side first',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'questions_understanding',
        label: 'Offer questions + confirm understanding',
        points: 1,
        section: 'Performance',
      ),

      // =========================
      // OSCE Preparation
      // =========================
      OsceRubricItem(
        id: 'rule_out_tests',
        label: 'Perform appropriate medical rule-out tests (region/stem)',
        points: 1,
        section: 'OSCE Preparation',
      ),
      OsceRubricItem(
        id: 'observation_local_posture',
        label: 'Observation (local/posture) as appropriate',
        points: 1,
        section: 'OSCE Preparation',
      ),
      OsceRubricItem(
        id: 'local_palpation',
        label: 'Local palpation as appropriate',
        points: 1,
        section: 'OSCE Preparation',
      ),

      // =========================
      // ROM
      // =========================
      OsceRubricItem(
        id: 'rom_active',
        label: 'AROM performed + interpreted (muscle/joint)',
        points: 1,
        section: 'ROM',
      ),
      OsceRubricItem(
        id: 'rom_passive',
        label: 'PROM performed + interpreted (tendon/ligament/overpressure)',
        points: 1,
        section: 'ROM',
      ),
      OsceRubricItem(
        id: 'rom_resisted',
        label: 'RROM performed + interpreted (strength/pain/weakness)',
        points: 1,
        section: 'ROM',
      ),

      // =========================
      // Special Tests
      // =========================
      OsceRubricItem(
        id: 'special_tests_selected',
        label: 'Select appropriate special tests',
        points: 1,
        section: 'Special Tests',
      ),
      OsceRubricItem(
        id: 'special_tests_performed',
        label: 'Perform special tests correctly (procedure + safety)',
        points: 1,
        section: 'Special Tests',
      ),
      OsceRubricItem(
        id: 'symptom_response_questions',
        label: 'Ask about symptom response during tests',
        points: 1,
        section: 'Special Tests',
      ),
      OsceRubricItem(
        id: 'differential_diagnosis',
        label: 'Consider differential diagnosis (exclude other causes)',
        points: 1,
        section: 'Special Tests',
      ),

      // =========================
      // Clinical Impression
      // =========================
      OsceRubricItem(
        id: 'clinical_impression_determine',
        label: 'Determine suspected clinical impression',
        points: 1,
        section: 'Clinical Impression',
      ),
      OsceRubricItem(
        id: 'clinical_impression_explain',
        label: 'Explain impression in lay terms',
        points: 1,
        section: 'Clinical Impression',
      ),
      OsceRubricItem(
        id: 'clinical_impression_plan',
        label: 'Provide brief plan / next steps (within scope)',
        points: 1,
        section: 'Clinical Impression',
      ),
      OsceRubricItem(
        id: 'close_confirm_questions',
        label: 'Confirm understanding + invite questions',
        points: 1,
        section: 'Clinical Impression',
      ),
    ],
  );

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
      scores.putIfAbsent(item.section, () => 0);
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
      return ['Excellent performance. All key criteria met.'];
    }

    return [
      'Review the following areas:',
      ...missing,
    ];
  }

  OsceRubric get rubric => _rubric;
}
