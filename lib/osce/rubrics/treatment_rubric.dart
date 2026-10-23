import '../osce_models.dart';

/// =====================================================
/// Treatment — Station 6 Rubric
/// =====================================================
/// Aligned with:
/// - TreatmentStationTimed
/// - Class-based rubric system
///
/// IMPORTANT:
/// - IDs MUST match the rubric toggle IDs exactly
/// - Lesson tasks from Firestore are NOT scored
/// =====================================================

class TreatmentRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: 'treatment',
    title: 'Treatment — Station 6',
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
        id: 'explain_treatment_flow',
        label: 'Explain what will happen in the station',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'open_communication',
        label: 'Instruct open communication (pain/uncomfortable)',
        points: 1,
        section: 'Performance',
      ),
      OsceRubricItem(
        id: 'questions_understanding',
        label: 'Offer questions and confirm understanding',
        points: 1,
        section: 'Performance',
      ),

      // =========================
      // General Client Care
      // =========================
      OsceRubricItem(
        id: 'draping',
        label: 'Appropriate draping maintained',
        points: 1,
        section: 'General Client Care',
      ),
      OsceRubricItem(
        id: 'pillowing_positioning',
        label: 'Pillowing/positioning appropriate',
        points: 1,
        section: 'General Client Care',
      ),
      OsceRubricItem(
        id: 'turning_repositioning',
        label: 'Turning/repositioning safely (if done)',
        points: 1,
        section: 'General Client Care',
      ),
      OsceRubricItem(
        id: 'comfort_checks',
        label: 'Comfort checked periodically',
        points: 1,
        section: 'General Client Care',
      ),
      OsceRubricItem(
        id: 'supplies_use',
        label: 'Oil/lotion/towels used appropriately',
        points: 1,
        section: 'General Client Care',
      ),

      // =========================
      // Massage Principles
      // =========================
      OsceRubricItem(
        id: 'principle_general_specific_general',
        label: 'General → specific → general',
        points: 1,
        section: 'Massage Principles',
      ),
      OsceRubricItem(
        id: 'principle_superficial_deep_superficial',
        label: 'Superficial → deep → superficial',
        points: 1,
        section: 'Massage Principles',
      ),
      OsceRubricItem(
        id: 'principle_proximal_distal_proximal',
        label: 'Proximal → distal → proximal (as applicable)',
        points: 1,
        section: 'Massage Principles',
      ),
      OsceRubricItem(
        id: 'principle_peripheral_central_peripheral',
        label: 'Peripheral → central → peripheral (as applicable)',
        points: 1,
        section: 'Massage Principles',
      ),

      // =========================
      // Treatment Effectiveness
      // =========================
      OsceRubricItem(
        id: 'techniques_appropriate',
        label: 'Appropriate techniques selected (within scope)',
        points: 1,
        section: 'Treatment Effectiveness',
      ),
      OsceRubricItem(
        id: 'addresses_symptoms',
        label: 'Addresses each presenting symptom area',
        points: 1,
        section: 'Treatment Effectiveness',
      ),
      OsceRubricItem(
        id: 'safe_pressure_body_mechanics',
        label: 'Safe pressure, control, and body mechanics',
        points: 1,
        section: 'Treatment Effectiveness',
      ),
      OsceRubricItem(
        id: 'technique_protocol',
        label: 'Proper technique protocol (intro before deeper work)',
        points: 1,
        section: 'Treatment Effectiveness',
      ),
      OsceRubricItem(
        id: 'adjusts_to_feedback',
        label: 'Monitors and adjusts to client feedback',
        points: 1,
        section: 'Treatment Effectiveness',
      ),

      // =========================
      // Closing
      // =========================
      OsceRubricItem(
        id: 'closing_general_finish',
        label: 'Return to general finishing strokes',
        points: 1,
        section: 'Closing',
      ),
      OsceRubricItem(
        id: 'closing_comfort_close',
        label: 'Final comfort check and brief close',
        points: 1,
        section: 'Closing',
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
