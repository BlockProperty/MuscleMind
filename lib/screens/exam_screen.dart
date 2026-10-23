import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import 'mcq_exam_review_screen.dart';

enum ExamMode { newAttempt, resume }

enum _FinishReason { timeUp, completed }

class ExamScreen extends StatefulWidget {
  final String category;
  final int lesson;
  final ExamMode mode;

  const ExamScreen({
    super.key,
    required this.category,
    required this.lesson,
    required this.mode,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  static const int _examDurationSeconds = 60 * 60;
  static const String _collectionName = 'questions';
  static const Color _brandBlue = Color(0xFF39C2FF);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> questions = [];
  bool loading = true;

  int currentIndex = 0;
  int score = 0;

  late int remainingSeconds;
  Timer? _timer;
  Timer? _autosaveTimer;

  bool _isFinishing = false;

  List<int?> selected = const [];

  String get _attemptKey => 'mcq::${widget.category}::${widget.lesson}';
  Box<dynamic> get _box => Hive.box<dynamic>('mcq_attempts');

  @override
  void initState() {
    super.initState();
    remainingSeconds = _examDurationSeconds;
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadQuestions();
    if (!mounted) return;

    selected = List<int?>.filled(questions.length, null);

    if (widget.mode == ExamMode.resume) {
      _restoreAttemptIfAny();
    } else {
      await _box.delete(_attemptKey);
      _setupFreshState();
    }

    if (questions.isEmpty) {
      currentIndex = 0;
    } else {
      currentIndex = currentIndex.clamp(0, questions.length - 1);
    }

    _recalculateScore();
    _startTimer();
    _startAutosaveTicker();

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  Future<void> _loadQuestions() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection(_collectionName)
          .where('category', isEqualTo: widget.category)
          .where('lesson', isEqualTo: widget.lesson)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection(_collectionName)
            .where('category', isEqualTo: widget.category)
            .where('lesson', isEqualTo: widget.lesson.toString())
            .get();
      }

      final docs = snapshot.docs.toList()..sort((a, b) => a.id.compareTo(b.id));

      questions = docs;
    } catch (e) {
      questions = [];
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      _showError('Failed to load questions: $e');
    }
  }

  void _setupFreshState() {
    currentIndex = 0;
    remainingSeconds = _examDurationSeconds;
    selected = List<int?>.filled(questions.length, null);
  }

  void _restoreAttemptIfAny() {
    final data = _box.get(_attemptKey);

    if (data is Map) {
      final savedRemaining = data['remainingSeconds'];
      final savedIndex = data['currentIndex'];
      final savedSelected = data['selected'];

      if (savedRemaining is int) {
        remainingSeconds = savedRemaining.clamp(0, _examDurationSeconds);
      }

      if (savedIndex is int) {
        currentIndex = savedIndex;
      }

      if (savedSelected is List) {
        final restored = savedSelected.map<int?>((e) {
          if (e == null) return null;
          if (e is int) return e;
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e);
          return null;
        }).toList();

        if (restored.length == questions.length) {
          selected = restored;
        }
      }
    }

    if (selected.length != questions.length) {
      selected = List<int?>.filled(questions.length, null);
      currentIndex = 0;
      remainingSeconds = _examDurationSeconds;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _isFinishing) return;

      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        t.cancel();
        await _finishExam(reason: _FinishReason.timeUp);
      }
    });
  }

  void _startAutosaveTicker() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveAttempt();
    });
  }

  Future<void> _saveAttempt() async {
    if (loading || questions.isEmpty || _isFinishing) return;

    final List<dynamic> selectedForStorage = selected.map((e) => e).toList();

    await _box.put(_attemptKey, {
      'category': widget.category,
      'lesson': widget.lesson,
      'remainingSeconds': remainingSeconds,
      'currentIndex': currentIndex,
      'selected': selectedForStorage,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  int _safeInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  List<String> _safeStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const <String>[];
  }

  void _recalculateScore() {
    var s = 0;
    for (var i = 0; i < questions.length; i++) {
      final sel = (i < selected.length) ? selected[i] : null;
      if (sel == null) continue;

      final correct =
          _safeInt(questions[i].data()['correctIndex'], fallback: -1);
      if (sel == correct) s++;
    }
    score = s;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit exam?'),
        content: const Text('Your progress is saved. You can resume later.'),
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

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectAnswer(int index) async {
    if (_isFinishing || questions.isEmpty) return;

    setState(() {
      selected[currentIndex] = index;
      _recalculateScore();
    });

    await _saveAttempt();
  }

  Future<void> _next() async {
    if (questions.isEmpty) return;

    if (selected[currentIndex] == null) {
      _showError('Please select an answer before continuing.');
      return;
    }

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
      await _saveAttempt();
    } else {
      await _finishExam(reason: _FinishReason.completed);
    }
  }

  Future<void> _prev() async {
    if (questions.isEmpty) return;

    if (currentIndex > 0) {
      setState(() => currentIndex--);
      await _saveAttempt();
    }
  }

  Future<void> _finishExam({required _FinishReason reason}) async {
    if (_isFinishing) return;
    _isFinishing = true;

    _timer?.cancel();
    _autosaveTimer?.cancel();

    await _box.delete(_attemptKey);

    if (!mounted) return;

    final Map<String, int> topicCorrect = {};
    final Map<String, int> topicTotal = {};

    for (var i = 0; i < questions.length; i++) {
      final data = questions[i].data();

      final topic = (data['topic'] ??
              data['subcategory'] ??
              data['section'] ??
              widget.category)
          .toString()
          .trim();

      topicTotal[topic] = (topicTotal[topic] ?? 0) + 1;

      final sel = selected[i];
      final correct = _safeInt(data['correctIndex'], fallback: -1);

      if (sel != null && sel == correct) {
        topicCorrect[topic] = (topicCorrect[topic] ?? 0) + 1;
      }
    }

    final answeredCount = selected.where((e) => e != null).length;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => McqExamReviewScreen(
          category: widget.category,
          lesson: widget.lesson,
          score: score,
          totalQuestions: questions.length,
          answeredCount: answeredCount,
          topicCorrect: topicCorrect,
          topicTotal: topicTotal,
        ),
      ),
    );
  }

  Color _timerColor() {
    if (remainingSeconds <= 30) return const Color(0xFFDC2626);
    if (remainingSeconds <= 60) return const Color(0xFFEF4444);
    if (remainingSeconds <= 300) return const Color(0xFFF59E0B);
    return _brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: LuxTheme.black,
        body: LuxBackground(
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: LuxTheme.black,
        body: LuxBackground(
          child: Center(
            child: Text(
              'No questions found for this lesson.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    if (selected.length != questions.length) {
      return Scaffold(
        backgroundColor: LuxTheme.black,
        body: LuxBackground(
          child: Center(
            child: Text(
              'Exam data mismatch. Please restart this lesson exam.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final data = questions[currentIndex].data();
    final questionText = (data['question'] ?? '').toString();
    final options = _safeStringList(data['options']);
    final picked = selected[currentIndex];
    final answeredCount = selected.where((e) => e != null).length;
    final progress =
        questions.isEmpty ? 0.0 : (currentIndex + 1) / questions.length;

    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmExit();
        if (ok) await _saveAttempt();
        return ok;
      },
      child: Scaffold(
        backgroundColor: LuxTheme.black,
        appBar: AppBar(
          title: Text('Lesson ${widget.lesson} Exam'),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _timerColor().withOpacity(0.65)),
                    boxShadow: [
                      BoxShadow(
                        color: _timerColor().withOpacity(0.16),
                        blurRadius: 14,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Text(
                    _formatTime(remainingSeconds),
                    style: TextStyle(
                      color: _timerColor(),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: LuxBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LuxTheme.panel,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _brandBlue.withOpacity(0.30)),
                      boxShadow: [
                        BoxShadow(
                          color: _brandBlue.withOpacity(0.08),
                          blurRadius: 18,
                          spreadRadius: 0.8,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.category.toUpperCase(),
                          style: const TextStyle(
                            color: _brandBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Question ${currentIndex + 1} of ${questions.length}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_brandBlue),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Answered: $answeredCount / ${questions.length}   •   Score so far: $score',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: LuxTheme.panel,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: _brandBlue.withOpacity(0.28)),
                            ),
                            child: Text(
                              questionText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ...List.generate(options.length, (i) {
                            final isSelected = picked == i;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AnswerOption(
                                label: options[i],
                                index: i,
                                isSelected: isSelected,
                                onTap: () => _selectAnswer(i),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: currentIndex == 0 ? null : _prev,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side:
                                BorderSide(color: _brandBlue.withOpacity(0.45)),
                            backgroundColor: LuxTheme.panel,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'BACK',
                            style: TextStyle(
                              color: _brandBlue,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _brandBlue.withOpacity(0.14),
                            foregroundColor: _brandBlue,
                            elevation: 0,
                            side:
                                BorderSide(color: _brandBlue.withOpacity(0.55)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            currentIndex == questions.length - 1
                                ? 'FINISH'
                                : 'NEXT',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _AnswerOption extends StatelessWidget {
  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF39C2FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? brandBlue : brandBlue.withOpacity(0.30),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: brandBlue.withOpacity(0.18),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? brandBlue : brandBlue.withOpacity(0.45),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: brandBlue.withOpacity(0.20),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: isSelected ? brandBlue : Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.85),
                    height: 1.45,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
