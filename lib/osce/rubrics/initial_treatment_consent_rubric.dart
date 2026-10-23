import '../osce_models.dart';

/// =====================================================
/// Initial Treatment & Consent — Station 5 Rubric
/// =====================================================
/// Aligned with:
/// - InitialTreatmentConsentStationTimed
/// - Class-based rubric system
///
/// IMPORTANT:
/// - IDs MUST match the station button IDs exactly
/// =====================================================

class InitialTreatmentConsentRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: 'initial_treatment_consent',
    title: 'Initial Treatment & Consent — Station 5',
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
        label: 'Greet patient (and examiner if desired)',
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
        label: 'Explain station flow (plan → details → questions → consent)',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'questions_throughout',
        label: 'Invite questions throughout',
        points: 1,
        section: 'Framing',
      ),

      // =========================
      // Core — Treatment plan details
      // =========================
      OsceRubricItem(
        id: 'focus_of_treatment',
        label: 'Focus of treatment (primary focus areas)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'areas_to_be_treated',
        label: 'Areas to be treated (secondary contact areas)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'goals_short_long',
        label: 'Goals (short- and long-term)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'contraindications',
        label: 'Contraindications explained (or state none)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'hydro_modalities',
        label:
            'Hydrotherapy/modalities (type, location, duration, sensitivities)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'comfort_check',
        label: 'Comfort checks and open communication',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'lotions_oils',
        label: 'Lotions/oils discussed (including hypoallergenic option)',
        points: 1,
        section: 'Core',
      ),

      // =========================
      // Core — Privacy, draping, positioning
      // =========================
      OsceRubricItem(
        id: 'clothing_privacy',
        label: 'Explain clothing/privacy (no persuasion)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'draping',
        label: 'Explain draping and ask permission prior to undraping',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'positioning',
        label: 'Pillowing/positioning plan and start position',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'hand_washing_exit_knock',
        label: 'Leave to wash hands and knock/notify before re-entry',
        points: 1,
        section: 'Core',
      ),

      // =========================
      // Core — Session structure + plan
      // =========================
      OsceRubricItem(
        id: 'duration_frequency_cost',
        label: 'Duration/frequency/cost and what happens in session',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'reassessment',
        label: 'Reassessment plan and purpose',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'home_care',
        label: 'Home care/self-care/remedial exercise',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'benefits',
        label: 'Benefits of massage therapy',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'risks_side_effects',
        label: 'Risks/side effects explained (terms + examples)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'consequences_no_treatment',
        label: 'Consequences of no treatment (better/worse/same)',
        points: 1,
        section: 'Core',
      ),
      OsceRubricItem(
        id: 'alternatives',
        label: 'Alternatives to treatment (specific; offer referral)',
        points: 1,
        section: 'Core',
      ),

      // =========================
      // Closing — Consent + wrap-up
      // =========================
      OsceRubricItem(
        id: 'right_to_stop_modify',
        label: 'Right to stop/modify at any time',
        points: 1,
        section: 'Closing',
      ),
      OsceRubricItem(
        id: 'written_consent_sensitive',
        label: 'Written consent for sensitive areas (if applicable)',
        points: 1,
        section: 'Closing',
      ),
      OsceRubricItem(
        id: 'confirm_understanding',
        label: 'Confirm understanding and invite final questions',
        points: 1,
        section: 'Closing',
      ),
      OsceRubricItem(
        id: 'obtain_consent_proceed',
        label: 'Obtain consent to proceed with treatment',
        points: 1,
        section: 'Closing',
      ),
      OsceRubricItem(
        id: 'field_question',
        label: 'Field a patient question (definition/fix/safety)',
        points: 1,
        section: 'Closing',
      ),
      OsceRubricItem(
        id: 'closing_next_step',
        label: 'Close: leave room for privacy to undress (wash hands first)',
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
