import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';
import 'package:musclemind_app/osce/bell.dart';

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

      final String lessonTitle =
          (data['title'] ?? widget.lessonId).toString().trim();

      final String stem = (data['stem'] ?? '').toString().trim();

      final List<String> tasks = _safeStringList(data['tasks']);

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
    if (value is List) {
      return value
          .map((item) {
            if (item is String) return item.trim();

            if (item is Map) {
              final dynamic label = item['label'] ?? item['title'] ?? item['text'];
              return label?.toString().trim() ?? '';
            }

            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _navigated) return;
      if (_doorOpening || _tickBusy) return;

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

  String _fmt(int s) {
    final int m = s ~/ 60;
    final int sec = s % 60;

    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (remaining <= 10) return const Color(0xFFDC2626);
    if (remaining <= 30) return const Color(0xFFEF4444);
    if (remaining <= 60) return const Color(0xFFF59E0B);

    return _brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    final String timerText = _fmt(remaining);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _timerColor().withOpacity(0.65)),
                  boxShadow: [
                    BoxShadow(
                      color: _timerColor().withOpacity(0.14),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Text(
                  timerText,
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
        child: Stack(
          children: [
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_loadFailed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: LuxTheme.panel,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _brandBlue.withOpacity(0.28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: _brandBlue,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _lessonTitle.isEmpty
                              ? 'Lesson unavailable'
                              : _lessonTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _stem,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: LuxTheme.panel.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _brandBlue.withOpacity(0.24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.stationTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _brandBlue.withOpacity(0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lessonTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _SwingDoorOverlay(
                        progress: _doorOpening
                            ? _doorAnim
                            : const AlwaysStoppedAnimation<double>(0.0),
                        accent: _brandBlue,
                        stationLabel: widget.stationTitle,
                        stemTitle: _lessonTitle,
                        stemBody: _stem.isEmpty ? '(No stem found.)' : _stem,
                        footer: 'Read the stem. Door opens when time ends.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwingDoorOverlay extends StatelessWidget {
  final Animation<double> progress;
  final Color accent;

  final String stationLabel;
  final String stemTitle;
  final String stemBody;
  final String footer;

  const _SwingDoorOverlay({
    required this.progress,
    required this.accent,
    required this.stationLabel,
    required this.stemTitle,
    required this.stemBody,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) {
        final double t = progress.value;
        final double angle = -t * (math.pi / 2.2);
        final double shadowStrength = (1 - t).clamp(0.0, 1.0);

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF08111F),
                    Color(0xFF0D1A2E),
                    Color(0xFF08111F),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
                        Color(0xFF0E1726),
                        Color(0xFF122033),
                        Color(0xFF09111D),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      right: BorderSide(
                        color: accent.withOpacity(0.35),
                        width: 2,
                      ),
                      top: BorderSide(
                        color: accent.withOpacity(0.12),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: accent.withOpacity(0.12),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: accent.withOpacity(0.28),
                        width: 3,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.65 * shadowStrength),
                        blurRadius: 24,
                        offset: const Offset(10, 0),
                      ),
                      BoxShadow(
                        color: accent.withOpacity(0.08 * shadowStrength),
                        blurRadius: 30,
                        spreadRadius: 1,
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
                              vertical: 12,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withOpacity(0.24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.08),
                                  blurRadius: 16,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            child: Text(
                              stationLabel.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFEEF6FF).withOpacity(0.98),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFF9FCBFF),
                                  width: 1,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    color: Color(0xFF102033),
                                    height: 1.5,
                                    fontSize: 13.5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stemTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          letterSpacing: 0.4,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(stemBody),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withOpacity(0.20),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withOpacity(0.28),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    footer,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.88),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
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