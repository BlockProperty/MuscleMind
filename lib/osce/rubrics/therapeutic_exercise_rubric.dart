import '../osce_models.dart';

/// =====================================================
/// Therapeutic Exercise — Station 1 Rubric
/// =====================================================
/// Aligned with:
/// - TherapeuticExerciseStationTimed
/// - Class-based rubric system
///
/// IMPORTANT:
/// - IDs MUST match the rubric toggle IDs exactly
/// - Lesson tasks from Firestore are NOT scored
/// =====================================================

class TherapeuticExerciseRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: 'therapeutic_exercise',
    title: 'Therapeutic Exercise — Station 1',
    items: [
      // =========================
      // Entrance
      // =========================
      OsceRubricItem(
        id: 'sanitize_hands',
        label: 'Sanitize hands',
        points: 1,
        section: 'Entrance',
      ),
      OsceRubricItem(
        id: 'greet',
        label: 'Greet patient',
        points: 1,
        section: 'Entrance',
      ),
      OsceRubricItem(
        id: 'introduce_self',
        label: 'Introduce yourself',
        points: 1,
        section: 'Entrance',
      ),

      // =========================
      // Framing
      // =========================
      OsceRubricItem(
        id: 'explain_station_flow',
        label: 'Explain what will happen in the station',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'hands_on_consent',
        label: 'Mention hands-on guidance and obtain consent when needed',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'confirm_understanding',
        label: 'Confirm patient understands instructions',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'offer_questions',
        label: 'Offer opportunity for questions',
        points: 1,
        section: 'Framing',
      ),

      // =========================
      // Core
      // =========================
      OsceRubricItem(
        id: 'explain_purpose',
        label: 'Explain exercise purpose (stretch / strength / ROM)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'muscle_location_action',
        label: 'Identify muscle location and primary action',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'warmup_breathing',
        label: 'Discuss warm-up and breathing guidance',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'negative_reactions',
        label:
            'Explain possible negative reactions (discomfort vs pain vs DOMS)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'position_setup',
        label: 'Explain correct position / setup',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'movement_cues',
        label: 'Explain movement cues',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'demo_correctly',
        label: 'Demonstrate exercise correctly (form, control, range)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'guide_patient',
        label: 'Guide patient through exercise',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'correct_errors',
        label: 'Correct patient errors when needed',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'felt_in_target',
        label: 'Ensure exercise is felt in correct target area',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'breathing_reminders',
        label: 'Remind breathing during movement',
        points: 1,
        section: 'Core',
      ),

      // =========================
      // Home Exercise Prescription
      // =========================
      OsceRubricItem(
        id: 'rx_isometric',
        label: 'Isometric prescription (hold 8–10s, 5–10 reps)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'rx_isotonic',
        label: 'Isotonic prescription (8–12 reps, 2s up / 2s down)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'rx_stretching',
        label: 'Stretch prescription (≥30s hold, 3–5 reps)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'rx_rom',
        label: 'ROM prescription (10–15 reps)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'progression',
        label: 'Explain progression of exercise',
        points: 1,
        section: 'Core',
      ),

      // =========================
      // Observation / Safety
      // =========================
      OsceRubricItem(
        id: 'observe_full_set',
        label: 'Observe patient complete full set',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'palpate_target',
        label: 'Palpate / confirm target muscles if appropriate',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'check_negative_reactions',
        label: 'Check for negative reactions during exercise',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'modify_or_stop',
        label: 'Modify or stop if adverse response occurs',
        points: 1,
        section: 'Core',
      ),

      // =========================
      // Closing
      // =========================
      OsceRubricItem(
        id: 'close_confirm',
        label: 'Close professionally and confirm understanding',
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
