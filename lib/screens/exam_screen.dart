import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ExamMode { newAttempt, resume }

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
  static const int _examDurationSeconds = 60 * 60; // 60 mins for 50-question lesson pacing
  static const String _collectionName = 'questions';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> questions = [];
  bool loading = true;

  int currentIndex = 0;
  int score = 0;

  late int remainingSeconds;
  Timer? _timer;
  Timer? _autosaveTimer;

  bool _isFinishing = false;

  // Selected answer per question index (null if unanswered)
  List<int?> selected = [];

  String get _attemptKey => 'mcq::${widget.category}::${widget.lesson}';
  Box get _box => Hive.box('mcq_attempts');

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

    if (widget.mode == ExamMode.resume) {
      _restoreAttemptIfAny();
    } else {
      await _box.delete(_attemptKey); // ensure fresh
      _setupFreshState();
    }

    _recalculateScore();
    _startTimer();
    _startAutosaveTicker();
  }

  Future<void> _loadQuestions() async {
    try {
      // Try lesson as INT first (most common)
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('category', isEqualTo: widget.category)
          .where('lesson', isEqualTo: widget.lesson)
          .get();

      // Fallback: if lesson stored as STRING like "1"
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection(_collectionName)
            .where('category', isEqualTo: widget.category)
            .where('lesson', isEqualTo: widget.lesson.toString())
            .get();
      }

      // Stable, crash-proof ordering: sort by Firestore document id
      final docs = snapshot.docs.toList()..sort((a, b) => a.id.compareTo(b.id));

      if (!mounted) return;

      setState(() {
        questions = docs;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showError("Failed to load questions: $e");
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
        currentIndex = savedIndex.clamp(0, (questions.length - 1).clamp(0, questions.length));
      }
      if (savedSelected is List) {
        selected = savedSelected.map((e) => e == null ? null : e as int).toList();
      }
    }

    // If savedSelected length doesn't match, reset safely
    if (selected.length != questions.length) {
      selected = List<int?>.filled(questions.length, null);
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

    await _box.put(_attemptKey, {
      'category': widget.category,
      'lesson': widget.lesson,
      'remainingSeconds': remainingSeconds,
      'currentIndex': currentIndex,
      'selected': selected,
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
      final sel = selected.isNotEmpty ? selected[i] : null;
      if (sel == null) continue;

      final correct = _safeInt(questions[i].data()['correctIndex'], fallback: -1);
      if (sel == correct) s++;
    }
    score = s;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }

  Future<bool> _confirmExit() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit exam?'),
        content: const Text('Your progress is saved. You can resume later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    return res == true;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _selectAnswer(int index) async {
    if (_isFinishing) return;

    setState(() {
      selected[currentIndex] = index;
      _recalculateScore();
    });

    await _saveAttempt();
  }

  void _next() async {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
      await _saveAttempt();
    } else {
      await _finishExam(reason: _FinishReason.completed);
    }
  }

  void _prev() async {
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

    // Delete attempt after completion
    await _box.delete(_attemptKey);

    if (!mounted) return;

    final title = reason == _FinishReason.timeUp ? "Time's Up" : "Exam Finished";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text("Your score: $score / ${questions.length}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: Text("No questions found for this lesson.")));
    }

    final data = questions[currentIndex].data();
    final questionText = (data['question'] ?? '').toString();
    final options = _safeStringList(data['options']);
    final picked = selected[currentIndex];
    final answeredCount = selected.where((e) => e != null).length;

    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmExit();
        if (ok) await _saveAttempt();
        return ok;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Q ${currentIndex + 1}/${questions.length}"),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _formatTime(remainingSeconds),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(questionText, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),

              ...List.generate(options.length, (i) {
                final isSelected = picked == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: isSelected ? Colors.blueGrey : null,
                    ),
                    onPressed: () => _selectAnswer(i),
                    child: Text(options[i]),
                  ),
                );
              }),

              const Spacer(),
              Text(
                "Answered: $answeredCount / ${questions.length}   |   Score so far: $score",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: currentIndex == 0 ? null : _prev,
                      child: const Text("Back"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(currentIndex == questions.length - 1 ? "Finish" : "Next"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FinishReason { timeUp, completed }

