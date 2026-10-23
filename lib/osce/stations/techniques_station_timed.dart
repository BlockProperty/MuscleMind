import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:musclemind_app/osce/bell.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/osce_result_screen.dart';
import 'package:musclemind_app/osce/rubrics/techniques_rubric.dart';
import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';

class TechniquesStationTimed extends StatefulWidget {
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
  State<TechniquesStationTimed> createState() => _TechniquesStationTimedState();
}

class _TechniquesStationTimedState extends State<TechniquesStationTimed>
    with TickerProviderStateMixin {
  static const int criticalAt = 60;

  final TechniquesRubric rubric = TechniquesRubric();

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

  final Set<int> _tasksDone = <int>{};

  bool _loading = true;
  String? _loadError;

  String _stationTitle = '';
  String _lessonTitle = '';
  String _stem = '';

  List<String> _tasks = const [];

  bool get _hasData =>
      _stationTitle.trim().isNotEmpty &&
      _lessonTitle.trim().isNotEmpty &&
      _stem.trim().isNotEmpty;

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
  void didUpdateWidget(covariant TechniquesStationTimed oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tasksOverride != widget.tasksOverride ||
        oldWidget.lessonId != widget.lessonId ||
        oldWidget.stationDocId != widget.stationDocId ||
        oldWidget.stemOverride != widget.stemOverride ||
        oldWidget.lessonTitleOverride != widget.lessonTitleOverride ||
        oldWidget.stationTitleOverride != widget.stationTitleOverride ||
        oldWidget.doorSecondsOverride != widget.doorSecondsOverride ||
        oldWidget.stationSecondsOverride != widget.stationSecondsOverride ||
        oldWidget.warningAtSecondsOverride != widget.warningAtSecondsOverride) {
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

      _tasksDone.clear();

      _stationTitle = '';
      _lessonTitle = '';
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

  List<String> _normalizeTasks(List<dynamic> raw) {
    final out = <String>[];

    for (final t in raw) {
      if (t is String) {
        final s = t.trim();

        if (s.isNotEmpty) {
          out.add(s);
        }
      } else if (t is Map) {
        final m = Map<String, dynamic>.from(t);

        final String s;
        if (m.containsKey('label')) {
          s = m['label'].toString().trim();
        } else if (m.containsKey('task')) {
          s = m['task'].toString().trim();
        } else {
          s = '';
        }

        if (s.isNotEmpty) {
          out.add(s);
        }
      }
    }

    return out;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _getStationDocWithFallback() async {
    final col = FirebaseFirestore.instance.collection('osceStations');

    final primary = await col.doc(widget.stationDocId).get();
    if (primary.exists) return primary;

    final fallback = await col.doc('station_7').get();
    if (fallback.exists) return fallback;

    return primary;
  }

  Future<void> _loadFromFirestoreOrOverrides() async {
    final stationDoc = await _getStationDocWithFallback();
    final stationData = stationDoc.data() ?? <String, dynamic>{};

    String stationTitle = (widget.stationTitleOverride ?? '').trim();

    if (stationTitle.isEmpty) {
      stationTitle = (stationData['title'] ?? stationData['stationTitle'] ?? '')
          .toString()
          .trim();
    }

    final lessonDoc = await FirebaseFirestore.instance
        .collection('osceStations')
        .doc(stationDoc.id)
        .collection('lessons')
        .doc(widget.lessonId)
        .get();

    final lessonData = lessonDoc.data() ?? <String, dynamic>{};

    String lessonTitle = (widget.lessonTitleOverride ?? '').trim();

    if (lessonTitle.isEmpty) {
      lessonTitle = (lessonData['title'] ?? '').toString().trim();
    }

    String stem = (widget.stemOverride ?? '').trim();

    if (stem.isEmpty) {
      stem = (lessonData['stem'] ?? '').toString().trim();
    }

    final rawTasks = (lessonData['tasks'] as List?) ?? const [];

    List<String> tasks = const [];

    if (widget.tasksOverride != null && widget.tasksOverride!.isNotEmpty) {
      tasks = _normalizeTasks(widget.tasksOverride!.cast<dynamic>());
    } else {
      tasks = _normalizeTasks(rawTasks.cast<dynamic>());
    }

    final readTime =
        widget.doorSecondsOverride ?? lessonData['readTimeSeconds'];
    final stationTime =
        widget.stationSecondsOverride ?? lessonData['stationTimeSeconds'];
    final warningTime =
        widget.warningAtSecondsOverride ?? lessonData['warningTimeSeconds'];

    if (stationTitle.isEmpty) {
      throw Exception(
        'Missing Firestore field: osceStations/${stationDoc.id}.title (or stationTitle)',
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

    if (tasks.isEmpty) {
      throw Exception(
        'Missing/empty Firestore field: lessons/${widget.lessonId}.tasks',
      );
    }

    doorSeconds = _safeInt(readTime, fallback: 120).clamp(30, 600);
    stationSeconds = _safeInt(stationTime, fallback: 600).clamp(60, 3600);
    warningAt =
        _safeInt(warningTime, fallback: 180).clamp(30, stationSeconds - 1);

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

    return "${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

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
    if (!_hasData) return true;

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit station?'),
        content: const Text('High-pressure mode: exiting ends the attempt.'),
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

  int _min(int seconds) => (seconds / 60).ceil();

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
              if (_doorOpening)
                Positioned.fill(
                  child: _SwingDoorOverlay(
                    progress: _doorAnim,
                    gold: LuxTheme.gold,
                    panel: LuxTheme.panel,
                    stationTitle: _stationTitle,
                    readMinutes: _min(doorSeconds),
                    stationMinutes: _min(stationSeconds),
                    warningMinutes: _min(warningAt),
                    tasks: _tasks,
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
    const doorTitle = 'TECHNIQUES';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          doorTitle,
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
          _sectionLabel('Tasks (not scored)'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuxTheme.panel.withOpacity(0.82),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LuxTheme.gold.withOpacity(0.18)),
            ),
            child: Text(
              _tasks
                  .asMap()
                  .entries
                  .map((e) => '${e.key + 1}) ${e.value}')
                  .join('\n'),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: Perform ONLY the listed techniques. State technique + area before you do it, and do comfort checks.',
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
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              const SizedBox(height: 8),
              Text(
                'Station: ${stationSeconds ~/ 60} minutes (${warningAt ~/ 60}-minute warning). Complete the tasks and rubric items.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        _sectionLabel('Tasks (not scored)'),
        ...List.generate(
          _tasks.length,
          (i) => _taskToggle('${i + 1}) ${_tasks[i]}', i),
        ),
        const SizedBox(height: 10),
        _sectionLabel('Entrance (scored)'),
        _rubricAction('Sanitize hands', 'sanitize_hands'),
        _rubricAction('Greet patient (and examiner if desired)', 'greet'),
        _rubricAction('Introduce yourself', 'introduce_self'),
        const SizedBox(height: 10),
        _sectionLabel('Framing (scored)'),
        _rubricAction('Explain station flow', 'explain_flow'),
        _rubricAction(
          'Inform technique + area before each technique',
          'announce_technique_area',
        ),
        _rubricAction(
          'Obtain permission prior to each technique',
          'permission_before_technique',
        ),
        _rubricAction('Instruct open communication', 'open_communication'),
        _rubricAction(
          'Offer questions + confirm understanding',
          'questions_understanding',
        ),
        const SizedBox(height: 10),
        _sectionLabel('Core: general client care (scored)'),
        _rubricAction('Appropriate draping', 'draping'),
        _rubricAction('Pillowing/positioning', 'pillowing_positioning'),
        _rubricAction(
          'Turning/repositioning safely (if done)',
          'turning_repositioning',
        ),
        _rubricAction('Client comfort checks', 'comfort_checks'),
        _rubricAction('Oil/lotion/towels used appropriately', 'supplies_use'),
        const SizedBox(height: 10),
        _sectionLabel('Core: massage principles (scored)'),
        _rubricAction(
          'General → specific → general',
          'principle_general_specific_general',
        ),
        _rubricAction(
          'Superficial → deep → superficial',
          'principle_superficial_deep_superficial',
        ),
        _rubricAction(
          'Proximal → distal → proximal',
          'principle_proximal_distal_proximal',
        ),
        _rubricAction(
          'Peripheral → central → peripheral',
          'principle_peripheral_central_peripheral',
        ),
        const SizedBox(height: 10),
        _sectionLabel('Core: technique protocols (scored)'),
        _rubricAction('Trigger point protocol followed', 'tp_protocol'),
        _rubricAction('Cross-fibre friction protocol followed', 'cff_protocol'),
        _rubricAction('Fascial technique protocol followed', 'fascial_protocol'),
        _rubricAction(
          'GTO / O&I / approximation protocol followed',
          'gto_oi_approx_protocol',
        ),
        _rubricAction('Vibrations protocol followed', 'vibration_protocol'),
        _rubricAction('Tapotement protocol followed', 'tapotement_protocol'),
        _rubricAction('Stroking protocol followed', 'stroking_protocol'),
        _rubricAction(
          'Joint mobilization protocol followed',
          'joint_mob_protocol',
        ),
        _rubricAction('Effleurage protocol followed', 'effleurage_protocol'),
        _rubricAction('Petrissage protocol followed', 'petrissage_protocol'),
        _rubricAction(
          'Manual lymphatic drainage protocol followed',
          'mld_protocol',
        ),
        _rubricAction('Stretching protocol followed', 'stretching_protocol'),
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

  Widget _taskToggle(String label, int index) {
    final done = _tasksDone.contains(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isLocked
            ? null
            : () {
                setState(() {
                  if (done) {
                    _tasksDone.remove(index);
                  } else {
                    _tasksDone.add(index);
                  }
                });
              },
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

  Widget _rubricAction(String label, String id) {
    final item = rubric.rubric.items.firstWhere((e) => e.id == id);
    final done = item.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isLocked
            ? null
            : () {
                setState(() {
                  item.completed = !item.completed;
                });
              },
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
  final int readMinutes;
  final int stationMinutes;
  final int warningMinutes;
  final List<String> tasks;

  const _SwingDoorOverlay({
    required this.progress,
    required this.gold,
    required this.panel,
    required this.stationTitle,
    required this.readMinutes,
    required this.stationMinutes,
    required this.warningMinutes,
    required this.tasks,
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
                                        'TASKS (${tasks.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        tasks
                                            .asMap()
                                            .entries
                                            .map(
                                              (e) => '${e.key + 1}) ${e.value}',
                                            )
                                            .join('\n'),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'TIMING',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '• $readMinutes minute(s) stem read\n'
                                        '• $stationMinutes minute(s) techniques ($warningMinutes-minute warning)\n\n'
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