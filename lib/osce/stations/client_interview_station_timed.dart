import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';
import 'package:musclemind_app/osce/bell.dart';
import 'package:musclemind_app/osce/osce_models.dart';
import 'package:musclemind_app/osce/osce_result_screen.dart';
import 'package:musclemind_app/osce/rubrics/client_interview_rubric.dart';

class _TaskItem {
  final String id;
  final String label;
  const _TaskItem({required this.id, required this.label});
}

class ClientInterviewStationTimed extends StatefulWidget {
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

  const ClientInterviewStationTimed({
    super.key,
    this.examMode = false,
    this.onFinished,
    this.stationDocId = 'client_interview',
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
  State<ClientInterviewStationTimed> createState() => _ClientInterviewStationTimedState();
}

class _ClientInterviewStationTimedState extends State<ClientInterviewStationTimed> with TickerProviderStateMixin {
  static const _blue = LuxTheme.accentGlow;
  static const int criticalAt = 60;
  final ClientInterviewRubric rubric = ClientInterviewRubric();
  final Set<String> completedTaskIds = <String>{};

  Timer? _timer;
  int doorSeconds = 120;
  int stationSeconds = 600;
  int warningAt = 180;
  int remaining = 0;
  bool inDoorPhase = true;
  bool _loading = true;
  bool _warningBellPlayed = false;
  bool _isLocked = false;
  bool _tickBusy = false;
  bool _doorOpening = false;
  double _flashOpacity = 0;
  String? _loadError;
  String _stationTitle = 'Station 2 — Client Interview';
  String _lessonTitle = 'Lesson';
  String _stem = '';
  List<_TaskItem> _tasks = const [];

  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;
  late final AnimationController _doorCtrl;
  late final Animation<double> _doorAnim;

  bool get _hasData => _stationTitle.trim().isNotEmpty && _lessonTitle.trim().isNotEmpty && _stem.trim().isNotEmpty;
  String get _doorSectionTitle => widget.doorSectionTitleOverride ?? 'CLIENT HEALTH HISTORY INTERVIEW';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseAnim = Tween<double>(begin: 1, end: 1.07).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _doorCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1450));
    _doorAnim = CurvedAnimation(parent: _doorCtrl, curve: Curves.easeInOutCubic);
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant ClientInterviewStationTimed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId || oldWidget.stationDocId != widget.stationDocId || oldWidget.stemOverride != widget.stemOverride || oldWidget.tasksOverride != widget.tasksOverride) {
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _doorCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _timer?.cancel();
    if (_pulse.isAnimating) _pulse.stop();
    _doorCtrl.reset();
    for (final item in rubric.rubric.items) {
      item.completed = false;
    }
    setState(() {
      _loading = true;
      _loadError = null;
      inDoorPhase = true;
      remaining = 0;
      _warningBellPlayed = false;
      _isLocked = false;
      _doorOpening = false;
      completedTaskIds.clear();
    });
    try {
      await _loadData();
      if (!mounted) return;
      setState(() {
        remaining = doorSeconds;
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

  Future<void> _loadData() async {
    String stationTitle = (widget.stationTitleOverride ?? '').trim();
    if (stationTitle.isEmpty) {
      final doc = await FirebaseFirestore.instance.collection('osceStations').doc(widget.stationDocId).get();
      final data = doc.data() ?? <String, dynamic>{};
      stationTitle = (data['stationTitle'] ?? data['title'] ?? '').toString().trim();
    }

    String lessonTitle = (widget.lessonTitleOverride ?? '').trim();
    String stem = (widget.stemOverride ?? '').trim();
    int? readTime = widget.doorSecondsOverride;
    int? stationTime = widget.stationSecondsOverride;
    int? warningTime = widget.warningAtSecondsOverride;
    List<_TaskItem> tasks = _normalizeTasks(widget.tasksOverride ?? const []);

    if (lessonTitle.isEmpty || stem.isEmpty || readTime == null || stationTime == null || warningTime == null || tasks.isEmpty) {
      final doc = await FirebaseFirestore.instance.collection('osceStations').doc(widget.stationDocId).collection('lessons').doc(widget.lessonId).get();
      final data = doc.data() ?? <String, dynamic>{};
      if (lessonTitle.isEmpty) lessonTitle = (data['title'] ?? '').toString().trim();
      if (stem.isEmpty) stem = (data['stem'] ?? '').toString().trim();
      readTime ??= _safeInt(data['readTimeSeconds'], 120);
      stationTime ??= _safeInt(data['stationTimeSeconds'], 600);
      warningTime ??= _safeInt(data['warningTimeSeconds'], 180);
      if (tasks.isEmpty) tasks = _normalizeTasks(data['tasks']);
    }

    if (stationTitle.isEmpty) throw Exception('Missing station title.');
    if (lessonTitle.isEmpty) throw Exception('Missing lesson title.');
    if (stem.isEmpty) throw Exception('Missing station prompt.');

    _stationTitle = stationTitle;
    _lessonTitle = lessonTitle;
    _stem = stem;
    _tasks = tasks;
    doorSeconds = (readTime ?? 120).clamp(30, 600);
    stationSeconds = (stationTime ?? 600).clamp(60, 3600);
    warningAt = (warningTime ?? 180).clamp(30, stationSeconds - 1);
  }

  int _safeInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  List<_TaskItem> _normalizeTasks(dynamic raw) {
    if (raw is! List) return const [];
    final out = <_TaskItem>[];
    var auto = 1;
    for (final value in raw) {
      if (value is String && value.trim().isNotEmpty) {
        out.add(_TaskItem(id: 'task_${auto++}', label: value.trim()));
      } else if (value is Map) {
        final map = value.map((k, v) => MapEntry(k.toString(), v));
        final label = (map['label'] ?? map['task'] ?? map['text'] ?? map['name'] ?? '').toString().trim();
        if (label.isEmpty) continue;
        final id = (map['id'] ?? '').toString().trim();
        out.add(_TaskItem(id: id.isEmpty ? 'task_${auto++}' : id, label: label));
      }
    }
    return out;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _loading || _isLocked || _doorOpening || _tickBusy || !_hasData) return;
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
            if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
          } else if (_pulse.isAnimating) {
            _pulse.stop();
          }
          return;
        }
        timer.cancel();
        if (inDoorPhase) {
          await _enterStation();
        } else {
          await Bell.playEndBell();
          _flash(stronger: true);
          _finish();
        }
      } finally {
        _tickBusy = false;
      }
    });
  }

  Future<void> _enterStation() async {
    if (!mounted) return;
    setState(() => _doorOpening = true);
    await Bell.playStartBell();
    _flash();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await _doorCtrl.forward(from: 0);
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

  void _finish() {
    if (_isLocked) return;
    setState(() => _isLocked = true);
    _timer?.cancel();
    if (_pulse.isAnimating) _pulse.stop();
    final result = OsceResult(
      stationTitle: _stationTitle,
      lessonTitle: _lessonTitle,
      score: rubric.calculateScore(),
      total: rubric.totalPoints,
      domains: rubric.buildDomainScores(),
      feedback: rubric.buildFeedback(),
      completedAt: DateTime.now(),
    );
    if (widget.examMode) {
      Navigator.pop(context, result);
    } else if (widget.onFinished != null) {
      widget.onFinished!(result);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OsceResultScreen(result: result)));
    }
  }

  void _flash({bool stronger = false}) {
    setState(() => _flashOpacity = stronger ? .32 : .18);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _flashOpacity = 0);
    });
  }

  String _fmt(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  Color _timerColor() {
    if (!_hasData) return Colors.white54;
    if (inDoorPhase) return _blue;
    if (remaining <= criticalAt) return const Color(0xFFFF6B6B);
    if (remaining <= warningAt) return const Color(0xFFFFB547);
    return _blue;
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: LuxTheme.panel,
            title: const Text('Exit station?', style: TextStyle(color: Colors.white)),
            content: const Text('Exiting ends this practice attempt.', style: TextStyle(color: LuxTheme.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
            ],
          ),
        ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _timerColor();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) {
          _timer?.cancel();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: LuxTheme.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: ScaleTransition(
            scale: (!_loading && !inDoorPhase && remaining <= criticalAt) ? _pulseAnim : const AlwaysStoppedAnimation(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: timerColor.withValues(alpha: .75)), boxShadow: [BoxShadow(color: timerColor.withValues(alpha: .12), blurRadius: 18)]),
              child: Text(_loading ? '--:--' : _fmt(remaining), style: TextStyle(color: timerColor, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ),
        bottomNavigationBar: (_loading || inDoorPhase || _isLocked || !_hasData) ? null : SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 14), child: ElevatedButton.icon(onPressed: _finish, icon: const Icon(Icons.flag_rounded), label: const Text('SUBMIT & END STATION'), style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: const Color(0xFF06131E), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5))))),
        body: LuxBackground(child: Stack(children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: _blue))
          else
            SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), child: inDoorPhase ? _doorView() : _stationView()),
          IgnorePointer(child: AnimatedOpacity(opacity: _flashOpacity, duration: const Duration(milliseconds: 120), child: Container(color: timerColor))),
          if (_doorOpening && _hasData) Positioned.fill(child: _PhysicalDoorTransition(progress: _doorAnim)),
          if (_isLocked) Positioned.fill(child: Container(color: Colors.black.withValues(alpha: .70), child: const Center(child: Text('TIME — STOP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white))))),
        ])),
      ),
    );
  }

  Widget _doorView() {
    if (_loadError != null) return _errorCard();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _phaseBanner(icon: Icons.door_front_door_outlined, eyebrow: 'DOOR TIME', title: _doorSectionTitle, subtitle: 'Read the station prompt and candidate tasks before entering.', detail: '${doorSeconds ~/ 60} min preparation'),
      const SizedBox(height: 14),
      _sectionHeader('STATION PROMPT', Icons.description_outlined),
      _contentCard(Text(_stem, style: const TextStyle(color: Colors.white, height: 1.48, fontSize: 14, fontWeight: FontWeight.w600))),
      if (_tasks.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionHeader('TASKS (NOT SCORED)', Icons.checklist_rounded),
        _contentCard(Column(children: _tasks.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _blue.withValues(alpha: .7))), child: Text('${entry.key + 1}', style: const TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w900))), const SizedBox(width: 10), Expanded(child: Text(entry.value.label, style: const TextStyle(color: Colors.white, height: 1.38, fontWeight: FontWeight.w600)))]))).toList())),
      ],
    ]);
  }

  Widget _stationView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _phaseBanner(icon: Icons.record_voice_over_outlined, eyebrow: 'STATION IN PROGRESS', title: _stationTitle, subtitle: _lessonTitle, detail: '${stationSeconds ~/ 60} min station • ${warningAt ~/ 60} min warning'),
      if (_tasks.isNotEmpty) ...[
        const SizedBox(height: 16),
        _sectionHeader('CANDIDATE TASKS', Icons.checklist_rounded, trailing: '${completedTaskIds.length}/${_tasks.length}'),
        const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Practice checklist only — these items are not scored.', style: TextStyle(color: LuxTheme.textSecondary, fontSize: 11.5))),
        ..._tasks.map(_taskToggle),
      ],
      const SizedBox(height: 8),
      _sectionHeader('SCORING RUBRIC', Icons.fact_check_outlined),
      const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Mark each criterion you successfully demonstrated.', style: TextStyle(color: LuxTheme.textSecondary, fontSize: 11.5))),
      ..._buildRubric(),
    ]);
  }

  Widget _phaseBanner({required IconData icon, required String eyebrow, required String title, required String subtitle, required String detail}) {
    return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(21), border: Border.all(color: _blue.withValues(alpha: .62)), boxShadow: [BoxShadow(color: _blue.withValues(alpha: .08), blurRadius: 20, offset: const Offset(0, 8))]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: _blue.withValues(alpha: .09), border: Border.all(color: _blue.withValues(alpha: .55))), child: Icon(icon, color: _blue, size: 22)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow, style: const TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)), const SizedBox(height: 4), Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: LuxTheme.textSecondary, height: 1.3, fontSize: 12)), const SizedBox(height: 8), Text(detail, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w800))]))]));
  }

  Widget _sectionHeader(String title, IconData icon, {String? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 9, top: 2), child: Row(children: [Icon(icon, color: _blue, size: 18), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(color: _blue, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1))), if (trailing != null) Text(trailing, style: const TextStyle(color: _blue, fontWeight: FontWeight.w900, fontSize: 11.5))]));

  Widget _contentCard(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _blue.withValues(alpha: .35))), child: child);

  Widget _errorCard() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: .5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Couldn’t load this station.', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(_loadError ?? '', style: const TextStyle(color: LuxTheme.textSecondary))]));

  Widget _taskToggle(_TaskItem task) {
    final done = completedTaskIds.contains(task.id);
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(borderRadius: BorderRadius.circular(17), onTap: _isLocked ? null : () => setState(() => done ? completedTaskIds.remove(task.id) : completedTaskIds.add(task.id)), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: done ? _blue.withValues(alpha: .10) : LuxTheme.panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: done ? _blue : _blue.withValues(alpha: .30))), child: Row(children: [Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: _blue, size: 22), const SizedBox(width: 11), Expanded(child: Text(task.label, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600)))]))));
  }

  List<Widget> _buildRubric() {
    final grouped = <String, List<OsceRubricItem>>{};
    final order = <String>[];
    for (final item in rubric.rubric.items) {
      final section = item.section.trim().isEmpty ? 'General' : item.section.trim();
      if (!grouped.containsKey(section)) {
        grouped[section] = [];
        order.add(section);
      }
      grouped[section]!.add(item);
    }
    final widgets = <Widget>[];
    for (final section in order) {
      widgets.add(Padding(padding: const EdgeInsets.only(top: 9, bottom: 8), child: Text(section.toUpperCase(), style: const TextStyle(color: _blue, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .9))));
      for (final item in grouped[section]!) {
        widgets.add(_rubricAction(item));
      }
    }
    return widgets;
  }

  Widget _rubricAction(OsceRubricItem item) {
    final done = item.completed;
    return Padding(padding: const EdgeInsets.only(bottom: 9), child: InkWell(borderRadius: BorderRadius.circular(17), onTap: _isLocked ? null : () => setState(() => item.completed = !item.completed), child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: done ? _blue.withValues(alpha: .10) : LuxTheme.panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: done ? _blue : _blue.withValues(alpha: .34))), child: Row(children: [Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined, color: _blue, size: 21), const SizedBox(width: 10), Expanded(child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600))), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: _blue.withValues(alpha: .09), borderRadius: BorderRadius.circular(99), border: Border.all(color: _blue.withValues(alpha: .35))), child: Text('+${item.points}', style: const TextStyle(color: _blue, fontSize: 10.5, fontWeight: FontWeight.w900)))]))));
  }
}

class _PhysicalDoorTransition extends StatelessWidget {
  final Animation<double> progress;
  const _PhysicalDoorTransition({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final t = progress.value;
        final angle = -t * (math.pi / 2.15);
        return Material(
          color: const Color(0xFF080A0D),
          child: Stack(fit: StackFit.expand, children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF142332), Color(0xFF08111A)])), child: const Center(child: Icon(Icons.record_voice_over_outlined, color: _blue, size: 44))),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFF2B1A10), borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xFF5C3A24), width: 10), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 4)]),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()..setEntry(3, 2, 0.0017)..rotateY(angle),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8A5832), Color(0xFF6B3F22), Color(0xFF4B2A18)], stops: [0, .55, 1]), border: Border.all(color: const Color(0xFF321A0D), width: 3), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)]),
                        child: Stack(children: [
                          const Positioned(left: 28, right: 28, top: 42, height: 150, child: _DoorPanel()),
                          const Positioned(left: 28, right: 28, bottom: 42, height: 210, child: _DoorPanel()),
                          Positioned(right: 28, top: MediaQuery.of(context).size.height * .43, child: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFFFFE6A6), Color(0xFFC99538), Color(0xFF6D4714)]), border: Border.all(color: const Color(0xFF4B300F), width: 2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 7, offset: Offset(2, 3))]), child: Center(child: Container(width: 13, height: 5, decoration: BoxDecoration(color: const Color(0xFF5A3A12), borderRadius: BorderRadius.circular(3)))))),
                          Positioned(left: 0, right: 0, top: 18, child: Column(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: Colors.black.withValues(alpha: .36), borderRadius: BorderRadius.circular(99)), child: const Text('DOOR TIME COMPLETE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.3))), const SizedBox(height: 8), const Text('Enter station', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black87, blurRadius: 8)]))])),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _DoorPanel extends StatelessWidget {
  const _DoorPanel();
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFF3B2112), width: 5), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B4B2A), Color(0xFF59331C)]), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 7, offset: Offset(0, 4), blurStyle: BlurStyle.inner)]));
}
