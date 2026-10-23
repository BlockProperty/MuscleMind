import 'package:flutter/material.dart';

import '../../theme/lux_theme.dart';
import '../../widgets/lux_background.dart';

import '../osce_models.dart';
import '../osce_exam_generator.dart';
import '../osce_exam_review_screen.dart';

// Station imports
import '../stations/client_interview_station_timed.dart';
import '../stations/therapeutic_exercise_station_timed.dart';
import '../stations/assessments_one_station_timed.dart';
import '../stations/assessments_two_station_timed.dart';
import '../stations/initial_treatment_consent_station_timed.dart';
import '../stations/treatment_station_timed.dart';
import '../stations/techniques_station_timed.dart';

class ExamRunnerScreen extends StatefulWidget {
  const ExamRunnerScreen({super.key});

  @override
  State<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends State<ExamRunnerScreen> {
  static const Color _blue = Color(0xFF39C2FF);

  bool _running = false;
  bool _preparing = false;
  int _currentIndex = -1;

  final List<OsceStationAttempt> _attempts = [];
  List<_ExamStation> _stations = [];

  Future<void> _startExam() async {
    if (_running || _preparing) return;

    setState(() {
      _preparing = true;
      _running = false;
      _currentIndex = -1;
      _attempts.clear();
      _stations = [];
    });

    try {
      final generated = await OsceExamGenerator.generateExam();

      if (!mounted) return;

      _stations = generated.map((g) {
        return _ExamStation(
          id: g.stationId,
          title: g.stationTitle,
          lessonId: g.lessonId,
          lessonTitle: g.lessonTitle,
          builder: (routeContext) {
            switch (g.stationId) {
              case 'client_interview':
                return ClientInterviewStationTimed(
                  examMode: true,
                  stationDocId: 'client_interview',
                  lessonId: g.lessonId,
                );

              case 'therapeutic_exercise':
                return TherapeuticExerciseStationTimed(
                  examMode: true,
                  stationDocId: 'therapeutic_exercise',
                  lessonId: g.lessonId,
                );

              case 'assessment_1':
                return AssessmentsOneStationTimed(
                  examMode: true,
                  stationDocId: 'assessment_1',
                  lessonId: g.lessonId,
                  onFinished: (result) => Navigator.pop(routeContext, result),
                );

              case 'assessment_2':
                return AssessmentsTwoStationTimed(
                  examMode: true,
                  stationDocId: 'assessment_2',
                  lessonId: g.lessonId,
                );

              case 'initial_treatment_consent':
                return InitialTreatmentConsentStationTimed(
                  examMode: true,
                  stationDocId: 'initial_treatment_consent',
                  lessonId: g.lessonId,
                  onFinished: (result) => Navigator.pop(routeContext, result),
                );

              case 'treatment':
                return TreatmentStation6Timed(
                  examMode: true,
                  stationDocId: 'treatment',
                  lessonId: g.lessonId,
                  onFinished: (result) => Navigator.pop(routeContext, result),
                );

              case 'techniques':
                return TechniquesStationTimed(
                  examMode: true,
                  stationDocId: 'techniques',
                  lessonId: g.lessonId,
                  onFinished: (result) => Navigator.pop(routeContext, result),
                );

              default:
                return Scaffold(
                  appBar: AppBar(title: const Text('Station Error')),
                  body: Center(
                    child: Text('Unknown station: ${g.stationId}'),
                  ),
                );
            }
          },
        );
      }).toList();

      setState(() {
        _preparing = false;
        _running = true;
        _currentIndex = -1;
      });

      for (int i = 0; i < _stations.length; i++) {
        if (!mounted) return;

        setState(() => _currentIndex = i);

        final station = _stations[i];
        final startedAt = DateTime.now();

        final OsceResult? stationResult = await Navigator.push<OsceResult>(
          context,
          MaterialPageRoute(
            builder: (routeContext) => station.builder(routeContext),
          ),
        );

        if (!mounted) return;

        if (stationResult == null) {
          setState(() {
            _running = false;
            _currentIndex = -1;
          });
          return;
        }

        final finishedAt = DateTime.now();

        _attempts.add(
          OsceStationAttempt(
            mode: OsceMode.exam,
            stationId: station.id,
            stationTitle: station.title,
            lessonId: station.lessonId,
            lessonTitle: station.lessonTitle,
            result: stationResult,
            startedAt: startedAt,
            finishedAt: finishedAt,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _running = false;
        _currentIndex = -1;
      });

      final exam = OsceExamResult(attempts: List.of(_attempts));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OsceExamReviewScreen(exam: exam),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _preparing = false;
        _running = false;
        _currentIndex = -1;
      });

      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Exam Setup Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _confirmAbort() async {
    if (!_running) return true;

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Abort exam?'),
        content: const Text(
          'This will end the exam run and return to the menu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abort'),
          ),
        ],
      ),
    );

    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    final progressText = _preparing
        ? 'Preparing exam stations...'
        : _currentIndex >= 0
            ? 'Running: ${_currentIndex + 1}/${_stations.length}'
            : 'Ready: ${_stations.isEmpty ? 7 : _stations.length} stations';

    return PopScope(
  canPop: !_running,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;

    final shouldLeave = await _confirmAbort();

    if (shouldLeave && context.mounted) {
      Navigator.of(context).pop();
    }
  },
  child: Scaffold(
        backgroundColor: LuxTheme.black,
        appBar: AppBar(
          title: const Text('EXAM MODE'),
          centerTitle: true,
        ),
        body: LuxBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: LuxTheme.panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _blue.withOpacity(0.30)),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withOpacity(0.10),
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withOpacity(0.22),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo/musclemind_icon.png',
                            width: 78,
                            height: 78,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'FULL OSCE EXAM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _blue,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Run all stations in sequence using randomly selected lessons, then review your full exam performance at the end.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _blue.withOpacity(0.24)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: _blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  progressText,
                                  style: const TextStyle(
                                    color: _blue,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Divider(color: _blue.withOpacity(0.18)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _stations.length,
                      itemBuilder: (_, i) {
                        final s = _stations[i];
                        final isCurrent = _running && i == _currentIndex;
                        final isDone = _attempts
                            .any((attempt) => attempt.stationId == s.id);

                        final subtitle = isDone
                            ? 'Completed • ${s.lessonTitle}'
                            : (isCurrent
                                ? 'In progress… • ${s.lessonTitle}'
                                : 'Pending • ${s.lessonTitle}');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ExamStationCard(
                            title: s.title,
                            subtitle: subtitle,
                            isCurrent: isCurrent,
                            isDone: isDone,
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_running || _preparing) ? null : _startExam,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _preparing
                              ? 'PREPARING EXAM…'
                              : _running
                                  ? 'EXAM RUNNING…'
                                  : 'START EXAM',
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
    );
  }
}

class _ExamStationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCurrent;
  final bool isDone;

  const _ExamStationCard({
    required this.title,
    required this.subtitle,
    required this.isCurrent,
    required this.isDone,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (isDone) {
      icon = Icons.check_circle;
    } else if (isCurrent) {
      icon = Icons.play_circle_fill;
    } else {
      icon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? _blue : _blue.withOpacity(0.36),
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: _blue.withOpacity(0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: _blue.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _blue),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.20),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: _blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCurrent ? _blue : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamStation {
  final String id;
  final String title;
  final String lessonId;
  final String lessonTitle;
  final Widget Function(BuildContext routeContext) builder;

  _ExamStation({
    required this.id,
    required this.title,
    required this.lessonId,
    required this.lessonTitle,
    required this.builder,
  });
}