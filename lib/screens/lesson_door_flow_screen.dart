import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:musclemind_app/osce/bell.dart';
import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';

import 'station_runner_screen.dart';

class LessonDoorFlowScreen extends StatefulWidget {
  final String stationId;
  final String stationTitle;
  final String lessonId;

  const LessonDoorFlowScreen({
    super.key,
    required this.stationId,
    required this.stationTitle,
    required this.lessonId,
  });

  @override
  State<LessonDoorFlowScreen> createState() => _LessonDoorFlowScreenState();
}

class _LessonDoorFlowScreenState extends State<LessonDoorFlowScreen>
    with TickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF39C2FF);

  Timer? _timer;
  bool _loading = true;
  bool _loadFailed = false;

  String _lessonTitle = '';
  String _stem = '';
  List<String> _tasks = [];

  int _doorSeconds = 120;
  int _stationSeconds = 600;
  int _warningSeconds = 180;

  bool inDoorPhase = true;
  int remaining = 120;
  bool _doorOpening = false;
  bool _tickBusy = false;
  bool _navigated = false;

  late final AnimationController _doorCtrl;
  late final Animation<double> _doorAnim;

  @override
  void initState() {
    super.initState();
    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _doorAnim = CurvedAnimation(
      parent: _doorCtrl,
      curve: Curves.easeInOutCubic,
    );
    _loadLesson();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _doorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLesson() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('osceStations')
          .doc(widget.stationId)
          .collection('lessons')
          .doc(widget.lessonId);
      final snap = await ref.get();
      final data = snap.data();
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _loading = false;
          _loadFailed = true;
          _lessonTitle = widget.lessonId;
          _stem = 'Lesson not found.';
          _tasks = const [];
        });
        return;
      }

      final lessonTitle = (data['title'] ?? widget.lessonId).toString().trim();
      final stem = (data['stem'] ?? '').toString().trim();
      final tasks = _safeStringList(data['tasks']);

      int doorSeconds = _safeInt(data['readTimeSeconds'], fallback: 120);
      int stationSeconds = _safeInt(data['stationTimeSeconds'], fallback: 600);
      int warningSeconds = _safeInt(data['warningTimeSeconds'], fallback: 180);
      if (doorSeconds <= 0) doorSeconds = 120;
      if (stationSeconds <= 0) stationSeconds = 600;
      if (warningSeconds <= 0) warningSeconds = 180;

      setState(() {
        _lessonTitle = lessonTitle;
        _stem = stem;
        _tasks = tasks;
        _doorSeconds = doorSeconds;
        _stationSeconds = stationSeconds;
        _warningSeconds = warningSeconds;
        _loading = false;
        _loadFailed = false;
        inDoorPhase = true;
        remaining = _doorSeconds;
      });
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _lessonTitle = widget.lessonId;
        _stem = 'Unable to load this lesson right now.';
        _tasks = const [];
      });
    }
  }

  int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  List<String> _safeStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      if (item is String) return item.trim();
      if (item is Map) {
        final label = item['label'] ?? item['title'] ?? item['text'];
        return label?.toString().trim() ?? '';
      }
      return item.toString().trim();
    }).where((item) => item.isNotEmpty).toList();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _navigated || _doorOpening || _tickBusy) return;
      _tickBusy = true;
      try {
        if (remaining > 0) {
          setState(() => remaining--);
          return;
        }
        if (inDoorPhase) {
          t.cancel();
          await _openDoorAndEnterRunner();
        }
      } finally {
        _tickBusy = false;
      }
    });
  }

  Future<void> _openDoorAndEnterRunner() async {
    if (!mounted || _navigated) return;
    setState(() => _doorOpening = true);
    try {
      await Bell.ringStart();
    } catch (_) {}
    await _doorCtrl.forward();
    if (!mounted || _navigated) return;

    _navigated = true;
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StationRunnerScreen(
          stationId: widget.stationId,
          stationTitle: widget.stationTitle,
          lessonTitle: _lessonTitle,
          stem: _stem,
          tasks: _tasks,
          stationSeconds: _stationSeconds,
          warningSeconds: _warningSeconds,
        ),
      ),
    );
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (remaining <= 10) return const Color(0xFFDC2626);
    if (remaining <= 30) return const Color(0xFFEF4444);
    if (remaining <= 60) return const Color(0xFFF59E0B);
    return _brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text('DOOR CARD'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _timerColor().withValues(alpha: 0.65)),
                ),
                child: Text(
                  _fmt(remaining),
                  style: TextStyle(
                    color: _timerColor(),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LuxBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
                ? _ErrorCard(title: _lessonTitle, message: _stem)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: LuxTheme.panel.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _brandBlue.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.stationTitle.toUpperCase(),
                                style: const TextStyle(
                                  color: _brandBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _lessonTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_stem.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _stem,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _PhysicalDoor(
                          progress: _doorOpening
                              ? _doorAnim
                              : const AlwaysStoppedAnimation<double>(0),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;

  const _ErrorCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF39C2FF).withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF39C2FF), size: 42),
              const SizedBox(height: 12),
              Text(
                title.isEmpty ? 'Lesson unavailable' : title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhysicalDoor extends StatelessWidget {
  final Animation<double> progress;

  const _PhysicalDoor({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) {
        final t = progress.value;
        final angle = -t * (math.pi / 2.15);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF07101C), Color(0xFF101D2A), Color(0xFF050A10)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 24,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF18212B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF39C2FF).withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF39C2FF), size: 24),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.78,
                height: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF24160F),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: const Color(0xFF513421), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  color: const Color(0xFF050708),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0016)
                        ..rotateY(angle),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B3E22), Color(0xFF8A5330), Color(0xFF4A2A18)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5 * (1 - t)),
                              blurRadius: 18,
                              offset: const Offset(10, 0),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  children: [
                                    Expanded(child: _DoorPanel()),
                                    const SizedBox(height: 18),
                                    Expanded(child: _DoorPanel()),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 22,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [Color(0xFFFFE08A), Color(0xFFB77A22), Color(0xFF6D430E)],
                                    ),
                                    border: Border.all(color: const Color(0xFFFFE5A0).withValues(alpha: 0.7)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.45),
                                        blurRadius: 7,
                                        offset: const Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _DoorPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF754526).withValues(alpha: 0.52),
        border: Border.all(color: const Color(0xFF3D2112), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x5530180C), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}
