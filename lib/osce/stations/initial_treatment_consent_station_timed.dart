import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';

import 'package:musclemind_app/osce/bell.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/osce_result_screen.dart';
import 'package:musclemind_app/osce/rubrics/initial_treatment_consent_rubric.dart';

class _TaskItem {
  final String id;
  final String label;

  const _TaskItem({
    required this.id,
    required this.label,
  });
}

class InitialTreatmentConsentStationTimed extends StatefulWidget {
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
  State<InitialTreatmentConsentStationTimed> createState() =>
      _InitialTreatmentConsentStationTimedState();
}

class _InitialTreatmentConsentStationTimedState
    extends State<InitialTreatmentConsentStationTimed>
    with TickerProviderStateMixin {
  static const int criticalAt = 60;

  final InitialTreatmentConsentRubric rubric = InitialTreatmentConsentRubric();

  Timer? _timer;

  int doorSeconds = 120;
  int stationSeconds = 600;
  int warningAt = 180;

  bool inDoorPhase = true;
  int remaining = 0;

  bool _warningBellPlayed = false;
  bool _isLocked = false;
  bool _tickBusy = false;
  bool _doorOpening = false;

  double _flashOpacity = 0.0;

  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  late final AnimationController _doorCtrl;
  late final Animation<double> _doorAnim;

  bool _loading = true;
  String? _loadError;

  String _stationTitle = 'Station title not loaded';
  String _lessonTitle = 'Lesson title not loaded';
  String _stem = '';
  List<_TaskItem> _tasks = const [];

  final Set<String> completedTaskIds = <String>{};

  bool get _hasData =>
      _stationTitle.trim().isNotEmpty &&
      _lessonTitle.trim().isNotEmpty &&
      _stem.trim().isNotEmpty;

  String get _doorSectionTitle =>
      widget.doorSectionTitleOverride ?? 'INITIAL TREATMENT AND CONSENT';

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _doorAnim = CurvedAnimation(
      parent: _doorCtrl,
      curve: Curves.easeInOutCubic,
    );

    _bootstrap();
  }

  @override
  void didUpdateWidget(
    covariant InitialTreatmentConsentStationTimed oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lessonId != widget.lessonId ||
        oldWidget.stationDocId != widget.stationDocId ||
        oldWidget.stemOverride != widget.stemOverride ||
        oldWidget.lessonTitleOverride != widget.lessonTitleOverride ||
        oldWidget.stationTitleOverride != widget.stationTitleOverride ||
        oldWidget.doorSecondsOverride != widget.doorSecondsOverride ||
        oldWidget.stationSecondsOverride != widget.stationSecondsOverride ||
        oldWidget.warningAtSecondsOverride != widget.warningAtSecondsOverride ||
        oldWidget.tasksOverride != widget.tasksOverride) {
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    _timer?.cancel();

    if (_pulse.isAnimating) {
      _pulse.stop();
    }

    for (final item in rubric.rubric.items) {
      item.completed = false;
    }

    setState(() {
      _loading = true;
      _loadError = null;

      inDoorPhase = true;
      _warningBellPlayed = false;
      _isLocked = false;
      _doorOpening = false;
      remaining = 0;

      completedTaskIds.clear();

      _stationTitle = 'Station title not loaded';
      _lessonTitle = 'Lesson title not loaded';
      _stem = '';
      _tasks = const [];
    });

    try {
      await _loadFromFirestoreOrOverrides();

      if (!mounted) return;

      remaining = doorSeconds;

      setState(() {
        _loading = false;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadFromFirestoreOrOverrides() async {
    String stationTitle = (widget.stationTitleOverride ?? '').trim();

    if (stationTitle.isEmpty) {
      final stationDoc = await FirebaseFirestore.instance
          .collection('osceStations')
          .doc(widget.stationDocId)
          .get();

      final data = stationDoc.data() ?? <String, dynamic>{};

      stationTitle =
          (data['stationTitle'] ?? data['title'] ?? '').toString().trim();
    }

    String lessonTitle = (widget.lessonTitleOverride ?? '').trim();
    String stem = (widget.stemOverride ?? '').trim();

    int? readTime = widget.doorSecondsOverride;
    int? stationTime = widget.stationSecondsOverride;
    int? warningTime = widget.warningAtSecondsOverride;

    List<_TaskItem> tasks = _normalizeTasks(widget.tasksOverride ?? const []);

    final needsLessonFetch = lessonTitle.isEmpty ||
        stem.isEmpty ||
        readTime == null ||
        stationTime == null ||
        warningTime == null ||
        tasks.isEmpty;

    if (needsLessonFetch) {
      final lessonDoc = await FirebaseFirestore.instance
          .collection('osceStations')
          .doc(widget.stationDocId)
          .collection('lessons')
          .doc(widget.lessonId)
          .get();

      final lessonData = lessonDoc.data() ?? <String, dynamic>{};

      if (lessonTitle.isEmpty) {
        lessonTitle = (lessonData['title'] ?? '').toString().trim();
      }

      if (stem.isEmpty) {
        stem = (lessonData['stem'] ?? '').toString().trim();
      }

      readTime ??= _safeInt(lessonData['readTimeSeconds'], fallback: 120);
      stationTime ??= _safeInt(lessonData['stationTimeSeconds'], fallback: 600);
      warningTime ??= _safeInt(lessonData['warningTimeSeconds'], fallback: 180);

      if (tasks.isEmpty) {
        tasks = _normalizeTasks(lessonData['tasks']);
      }
    }

    if (stationTitle.isEmpty) {
      throw Exception(
        'Missing Firestore field: osceStations/${widget.stationDocId}.stationTitle or title',
      );
    }

    if (lessonTitle.isEmpty) {
      throw Exception(
        'Missing Firestore field: lessons/${widget.lessonId}.title',
      );
    }

    if (stem.isEmpty) {
      throw Exception(
        'Missing Firestore field: lessons/${widget.lessonId}.stem',
      );
    }

    final resolvedReadTime = readTime;
    final resolvedStationTime = stationTime;
    final resolvedWarningTime = warningTime;

    doorSeconds = resolvedReadTime.clamp(30, 600);
    stationSeconds = resolvedStationTime.clamp(60, 3600);
    warningAt = resolvedWarningTime.clamp(30, stationSeconds - 1);

    _stationTitle = stationTitle;
    _lessonTitle = lessonTitle;
    _stem = stem;
    _tasks = tasks;
  }

  int _safeInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;

    return fallback;
  }

  List<_TaskItem> _normalizeTasks(dynamic raw) {
    if (raw is! List) return const [];

    final List<_TaskItem> out = [];
    int auto = 1;

    for (final e in raw) {
      if (e is String) {
        final label = e.trim();

        if (label.isEmpty) continue;

        out.add(_TaskItem(id: 'task_${auto++}', label: label));
        continue;
      }

      if (e is Map) {
        final m = e.map((k, v) => MapEntry(k.toString(), v));

        final id = (m['id'] ?? '').toString().trim();

        final label = (m['label'] ?? m['task'] ?? m['text'] ?? m['name'] ?? '')
            .toString()
            .trim();

        if (label.isEmpty) continue;

        out.add(
          _TaskItem(
            id: id.isEmpty ? 'task_${auto++}' : id,
            label: label,
          ),
        );
      }
    }

    return out;
  }

  @override
  void dispose() {
    _timer?.cancel();

    if (_pulse.isAnimating) {
      _pulse.stop();
    }

    _pulse.dispose();
    _doorCtrl.dispose();

    super.dispose();
  }

  void _toggleTask(String id) {
    if (_isLocked) return;

    setState(() {
      if (completedTaskIds.contains(id)) {
        completedTaskIds.remove(id);
      } else {
        completedTaskIds.add(id);
      }
    });
  }

  void _toggleScore(String id) {
    if (_isLocked) return;

    final item = rubric.rubric.items.firstWhere((e) => e.id == id);

    setState(() {
      item.completed = !item.completed;
    });
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      if (_isLocked) return;
      if (_doorOpening) return;
      if (_tickBusy) return;
      if (!_hasData) return;

      _tickBusy = true;

      try {
        if (remaining > 0) {
          setState(() => remaining--);

          if (!inDoorPhase && !_warningBellPlayed && remaining == warningAt) {
            _warningBellPlayed = true;
            await Bell.playWarningBell();
            _flash();
          }

          if (!inDoorPhase && remaining <= criticalAt) {
            if (!_pulse.isAnimating) {
              _pulse.repeat(reverse: true);
            }
          } else {
            if (_pulse.isAnimating) {
              _pulse.stop();
            }
          }

          return;
        }

        if (inDoorPhase) {
          t.cancel();
          await _beginDoorOpenAndEnterStation();
        } else {
          t.cancel();
          await Bell.playEndBell();
          _flash(stronger: true);
          _lockAndFinish();
        }
      } finally {
        _tickBusy = false;
      }
    });
  }

  Future<void> _beginDoorOpenAndEnterStation() async {
    if (!mounted) return;

    setState(() => _doorOpening = true);

    await Bell.playStartBell();
    _flash();

    await _doorCtrl.forward();

    if (!mounted) return;

    _doorCtrl.reset();

    setState(() {
      _doorOpening = false;
      inDoorPhase = false;
      remaining = stationSeconds;
      _warningBellPlayed = false;
    });

    _startTimer();
  }

  void _flash({bool stronger = false}) {
    setState(() => _flashOpacity = stronger ? 0.35 : 0.22);

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      setState(() => _flashOpacity = 0.0);
    });
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;

    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  int _min(int seconds) => (seconds / 60).ceil();

  Color _timerColor() {
    if (!_hasData) return Colors.white.withOpacity(0.55);
    if (inDoorPhase) return LuxTheme.gold.withOpacity(0.9);
    if (remaining <= criticalAt) return const Color(0xFFEF4444);
    if (remaining <= warningAt) return const Color(0xFFF59E0B);

    return LuxTheme.gold.withOpacity(0.9);
  }

  void _lockAndFinish() {
    if (_isLocked) return;

    setState(() => _isLocked = true);

    _timer?.cancel();

    if (_pulse.isAnimating) {
      _pulse.stop();
    }

    final OsceResult result = OsceResult(
      stationTitle: _stationTitle,
      lessonTitle: _lessonTitle,
      score: rubric.calculateScore(),
      total: rubric.totalPoints,
      domains: rubric.buildDomainScores(),
      feedback: rubric.buildFeedback(),
      completedAt: DateTime.now(),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      if (widget.examMode) {
        Navigator.pop(context, result);
        return;
      }

      if (widget.onFinished != null) {
        widget.onFinished!(result);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OsceResultScreen(result: result)),
      );
    });
  }

  Future<bool> _confirmExit() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: LuxTheme.panel,
        title: const Text(
          'Exit station?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'High-pressure mode: exiting ends the attempt.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _timerColor();
    final timerText = _hasData ? _fmt(remaining) : '--:--';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final ok = await _confirmExit();

        if (ok && context.mounted) {
          _timer?.cancel();

          if (_pulse.isAnimating) {
            _pulse.stop();
          }

          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: ScaleTransition(
            scale: (!inDoorPhase && _hasData && remaining <= criticalAt)
                ? _pulseAnim
                : const AlwaysStoppedAnimation<double>(1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LuxTheme.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: timerColor.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: timerColor.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Text(
                timerText,
                style: TextStyle(
                  color: timerColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: (inDoorPhase || _isLocked || !_hasData)
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: ElevatedButton(
                    onPressed: _lockAndFinish,
                    child: const Text('SUBMIT (END STATION)'),
                  ),
                ),
              ),
        body: LuxBackground(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: inDoorPhase ? _buildDoorStem(context) : _buildStation(),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _flashOpacity,
                  duration: const Duration(milliseconds: 120),
                  child: Container(color: timerColor),
                ),
              ),
              if (_doorOpening && _hasData)
                Positioned.fill(
                  child: _SwingDoorOverlay(
                    progress: _doorAnim,
                    gold: LuxTheme.gold,
                    panel: LuxTheme.panel,
                    stationTitle: _stationTitle,
                    sectionTitle: _doorSectionTitle,
                    readMinutes: _min(doorSeconds),
                    stationMinutes: _min(stationSeconds),
                    warningMinutes: _min(warningAt),
                  ),
                ),
              if (_isLocked)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: const Center(
                      child: Text(
                        'TIME — STOP',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoorStem(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          _doorSectionTitle,
          style: TextStyle(
            color: LuxTheme.gold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          Text(
            'Loading station from Firestore…',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        if (!_loading && _loadError != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LuxTheme.gold.withOpacity(0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Couldn’t load this station from Firestore.',
                  style: TextStyle(
                    color: LuxTheme.gold.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          )
        else if (_hasData) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LuxTheme.panel.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LuxTheme.gold.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              _stem,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          if (_tasks.isNotEmpty) ...[
            _sectionLabel('Lesson tasks (practice only — not scored)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LuxTheme.panel.withOpacity(0.82),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LuxTheme.gold.withOpacity(0.18)),
              ),
              child: Text(
                _tasks.map((e) => '• ${e.label}').join('\n'),
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Tip: Cover focus areas, goals, contraindications, draping, positioning, risks/benefits, alternatives, and right to stop.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildStation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LuxTheme.gold.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _stationTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _lessonTitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Station: ${stationSeconds ~/ 60} minutes (${warningAt ~/ 60}-minute warning bell). Discuss plan + obtain consent.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (_tasks.isNotEmpty) ...[
          _sectionLabel('Lesson tasks (not scored)'),
          ..._tasks.map((t) => _taskView(t.label, t.id)),
          const SizedBox(height: 10),
        ],
        _sectionLabel('Performance'),
        _action('Sanitize hands', 'sanitize_hands'),
        _action('Greet patient (and examiner if desired)', 'greet'),
        _action('Introduce yourself', 'introduce_self'),
        _action(
          'Explain station flow: plan, details, questions, consent',
          'explain_station_flow',
        ),
        _action(
          'Give opportunity for questions (throughout)',
          'questions_throughout',
        ),
        const SizedBox(height: 10),
        _sectionLabel('Treatment plan details'),
        _action(
          'Focus of treatment (primary focus areas)',
          'focus_of_treatment',
        ),
        _action(
          'Areas to be treated (secondary contact areas)',
          'areas_to_be_treated',
        ),
        _action(
          'Goals of treatment (short & long term)',
          'goals_short_long',
        ),
        _action(
          'Contraindications (identify/explain; or explain none)',
          'contraindications',
        ),
        _action(
          'Hydrotherapy/modalities (type, location, duration, sensitivities)',
          'hydro_modalities',
        ),
        _action('Client comfort check + open communication', 'comfort_check'),
        _action('Lotions/oils hypoallergenic', 'lotions_oils'),
        const SizedBox(height: 10),
        _sectionLabel('Privacy, draping, positioning'),
        _action(
          'Clothing/privacy explanation (no persuasion)',
          'clothing_privacy',
        ),
        _action(
          'Draping explanation + ask permission before undraping',
          'draping',
        ),
        _action(
          'Pillowing/positioning plan + start position',
          'positioning',
        ),
        _action(
          'Leaving to wash hands + knock before re-entering',
          'hand_washing_exit_knock',
        ),
        const SizedBox(height: 10),
        _sectionLabel('Session structure + plan'),
        _action(
          'Duration/frequency/cost (basic) + what happens in 1 hour',
          'duration_frequency_cost',
        ),
        _action('Reassessment plan + purpose', 'reassessment'),
        _action(
          'Home care/self-care/remedial exercise (specific to stem)',
          'home_care',
        ),
        _action('Benefits of massage treatment (general)', 'benefits'),
        _action(
          'Risks/side effects (use these words; give examples)',
          'risks_side_effects',
        ),
        _action(
          'Consequences of no treatment (better/worse/same)',
          'consequences_no_treatment',
        ),
        _action(
          'Alternatives to treatment (specific; referral offer)',
          'alternatives',
        ),
        const SizedBox(height: 10),
        _sectionLabel('Consent'),
        _action(
          'Right to stop/modify treatment at any time',
          'right_to_stop_modify',
        ),
        _action(
          'Discuss sensitive areas + obtain WRITTEN consent if needed',
          'written_consent_sensitive',
        ),
        _action(
          'Confirm client understands plan + invite final questions',
          'confirm_understanding',
        ),
        _action(
          'Ask permission / obtain consent to proceed with treatment',
          'obtain_consent_proceed',
        ),
        const SizedBox(height: 10),
        _sectionLabel('Patient question'),
        _action(
          'Field a patient question (definition / fix / safety)',
          'field_question',
        ),
        _action(
          'Close: leaving room to wash hands + privacy to disrobe',
          'closing_next_step',
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: LuxTheme.gold,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _taskView(String label, String id) {
    final done = completedTaskIds.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isLocked ? null : () => _toggleTask(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: done ? LuxTheme.gold : Colors.white.withOpacity(0.18),
            ),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: LuxTheme.gold.withOpacity(0.12),
                      blurRadius: 16,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: LuxTheme.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(String label, String id) {
    final item = rubric.rubric.items.firstWhere((e) => e.id == id);
    final done = item.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isLocked ? null : () => _toggleScore(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: done
                ? LuxTheme.gold.withOpacity(0.08)
                : LuxTheme.panel.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done ? LuxTheme.gold : LuxTheme.gold.withOpacity(0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.circle_outlined,
                color: LuxTheme.gold,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwingDoorOverlay extends StatelessWidget {
  final Animation<double> progress;
  final Color gold;
  final Color panel;

  final String stationTitle;
  final String sectionTitle;
  final int readMinutes;
  final int stationMinutes;
  final int warningMinutes;

  const _SwingDoorOverlay({
    required this.progress,
    required this.gold,
    required this.panel,
    required this.stationTitle,
    required this.sectionTitle,
    required this.readMinutes,
    required this.stationMinutes,
    required this.warningMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) {
        final t = progress.value;
        final angle = -t * (math.pi / 2.2);
        final shadowStrength = (1 - t).clamp(0.0, 1.0);

        return Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.15)),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016)
                  ..rotateY(angle),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.92,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B2A1A),
                        Color(0xFF2A1D12),
                        Color(0xFF1F160E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      right: BorderSide(
                        color: gold.withOpacity(0.28),
                        width: 2,
                      ),
                      top: BorderSide(
                        color: gold.withOpacity(0.10),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: gold.withOpacity(0.10),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: gold.withOpacity(0.20),
                        width: 3,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6 * shadowStrength),
                        blurRadius: 22,
                        offset: const Offset(10, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: gold.withOpacity(0.22)),
                            ),
                            child: Text(
                              stationTitle.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: gold.withOpacity(0.9),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF4F1E8).withOpacity(0.98),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFB7A98C),
                                  width: 1,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    height: 1.3,
                                    fontSize: 13,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sectionTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'TIMING',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '• $readMinutes minute(s) stem read\n'
                                        '• $stationMinutes minute(s) plan + consent ($warningMinutes-minute warning)\n\n'
                                        'Door opens automatically when time ends.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: gold.withOpacity(0.20)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: gold.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Read the stem. Door opens when time ends.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}