import '../osce_models.dart';

/// =====================================================
/// Techniques — Station 7 Rubric
/// =====================================================
/// Aligned with:
/// - TechniquesStationTimed
/// - Class-based rubric system
///
/// IMPORTANT:
/// - Assigned lesson tasks from Firestore are NOT scored
/// - IDs below MUST match the rubric toggle IDs exactly
/// =====================================================

class TechniquesRubric {
  final OsceRubric _rubric = OsceRubric(
    stationId: 'techniques',
    title: 'Techniques — Station 7',
    items: [
      // Entrance
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

      // Framing
      OsceRubricItem(
        id: 'explain_flow',
        label: 'Explain station flow',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'announce_technique_area',
        label: 'Inform patient of technique and area before performing each technique',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'permission_before_technique',
        label: 'Obtain permission prior to performing technique',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'open_communication',
        label: 'Encourage open communication during treatment',
        points: 1,
        section: 'Framing',
      ),
      OsceRubricItem(
        id: 'questions_understanding',
        label: 'Offer questions and confirm understanding',
        points: 1,
        section: 'Framing',
      ),

      // Client care
      OsceRubricItem(
        id: 'draping',
        label: 'Appropriate draping',
        points: 1,
        section: 'Client Care',
      ),
      OsceRubricItem(
        id: 'pillowing_positioning',
        label: 'Proper pillowing / positioning',
        points: 1,
        section: 'Client Care',
      ),
      OsceRubricItem(
        id: 'turning_repositioning',
        label: 'Turning / repositioning performed safely',
        points: 1,
        section: 'Client Care',
      ),
      OsceRubricItem(
        id: 'comfort_checks',
        label: 'Client comfort checks',
        points: 1,
        section: 'Client Care',
      ),
      OsceRubricItem(
        id: 'supplies_use',
        label: 'Oil / lotion / towels used appropriately',
        points: 1,
        section: 'Client Care',
      ),

      // Massage principles
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
        label: 'Proximal → distal → proximal',
        points: 1,
        section: 'Massage Principles',
      ),
      OsceRubricItem(
        id: 'principle_peripheral_central_peripheral',
        label: 'Peripheral → central → peripheral',
        points: 1,
        section: 'Massage Principles',
      ),

      // Technique protocols
      OsceRubricItem(
        id: 'tp_protocol',
        label: 'Trigger point protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'cff_protocol',
        label: 'Cross-fibre friction protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'fascial_protocol',
        label: 'Fascial technique protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'gto_oi_approx_protocol',
        label: 'GTO / O&I / approximation protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'vibration_protocol',
        label: 'Vibration protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'tapotement_protocol',
        label: 'Tapotement protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'stroking_protocol',
        label: 'Stroking protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'joint_mob_protocol',
        label: 'Joint mobilization protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'effleurage_protocol',
        label: 'Effleurage protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'petrissage_protocol',
        label: 'Petrissage protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'mld_protocol',
        label: 'Manual lymphatic drainage protocol followed',
        points: 1,
        section: 'Technique Protocols',
      ),
      OsceRubricItem(
        id: 'stretching_protocol',
        label: 'Stretching protocol followed',
        points: 1,
        section: 'Technique Protocols',
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
