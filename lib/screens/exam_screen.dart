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

  const ExamScreen({super.key, required this.category, required this.lesson, required this.mode});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  static const int _examDurationSeconds = 60 * 60;
  static const String _collectionName = 'questions';
  static const Color _brandBlue = LuxTheme.accentGlow;

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
    currentIndex = questions.isEmpty ? 0 : currentIndex.clamp(0, questions.length - 1);
    _recalculateScore();
    _startTimer();
    _startAutosaveTicker();
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _loadQuestions() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
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
      questions = snapshot.docs.toList()..sort((a, b) => a.id.compareTo(b.id));
    } catch (e) {
      questions = [];
      if (!mounted) return;
      setState(() => loading = false);
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
      if (savedRemaining is int) remainingSeconds = savedRemaining.clamp(0, _examDurationSeconds);
      if (savedIndex is int) currentIndex = savedIndex;
      if (savedSelected is List) {
        final restored = savedSelected.map<int?>((e) {
          if (e == null) return null;
          if (e is int) return e;
          if (e is num) return e.toInt();
          if (e is String) return int.tryParse(e);
          return null;
        }).toList();
        if (restored.length == questions.length) selected = restored;
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
    _autosaveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveAttempt());
  }

  Future<void> _saveAttempt() async {
    if (loading || questions.isEmpty || _isFinishing) return;
    await _box.put(_attemptKey, {
      'category': widget.category,
      'lesson': widget.lesson,
      'remainingSeconds': remainingSeconds,
      'currentIndex': currentIndex,
      'selected': selected.map((e) => e).toList(),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  int _safeInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  List<String> _safeStringList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : const <String>[];

  void _recalculateScore() {
    var s = 0;
    for (var i = 0; i < questions.length; i++) {
      final sel = i < selected.length ? selected[i] : null;
      if (sel == null) continue;
      if (sel == _safeInt(questions[i].data()['correctIndex'], fallback: -1)) s++;
    }
    score = s;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Attention'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
      _showError('Select an answer before continuing.');
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
    if (questions.isEmpty || currentIndex == 0) return;
    setState(() => currentIndex--);
    await _saveAttempt();
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
      final topic = (data['topic'] ?? data['subcategory'] ?? data['section'] ?? widget.category).toString().trim();
      topicTotal[topic] = (topicTotal[topic] ?? 0) + 1;
      final correct = _safeInt(data['correctIndex'], fallback: -1);
      if (selected[i] != null && selected[i] == correct) topicCorrect[topic] = (topicCorrect[topic] ?? 0) + 1;
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
    if (remainingSeconds <= 300) return const Color(0xFFFFB547);
    return _brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: LuxTheme.black,
        body: LuxBackground(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: LuxTheme.black,
        body: LuxBackground(child: Center(child: Text('No questions found for this lesson.', style: TextStyle(color: Colors.white, fontSize: 15)))),
      );
    }
    if (selected.length != questions.length) {
      return const Scaffold(
        backgroundColor: LuxTheme.black,
        body: LuxBackground(child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Exam data mismatch. Please restart this lesson exam.', style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center)))),
      );
    }

    final data = questions[currentIndex].data();
    final questionText = (data['question'] ?? '').toString();
    final options = _safeStringList(data['options']);
    final picked = selected[currentIndex];
    final answeredCount = selected.where((e) => e != null).length;
    final progress = (currentIndex + 1) / questions.length;

    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmExit();
        if (ok) await _saveAttempt();
        return ok;
      },
      child: Scaffold(
        backgroundColor: LuxTheme.black,
        appBar: AppBar(
          title: Text('Lesson ${widget.lesson}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _timerColor().withValues(alpha: 0.75)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, color: _timerColor(), size: 16),
                      const SizedBox(width: 5),
                      Text(_formatTime(remainingSeconds), style: TextStyle(color: _timerColor(), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: LuxBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
                    decoration: BoxDecoration(
                      color: LuxTheme.panel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _brandBlue.withValues(alpha: 0.62)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.category.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _brandBlue, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                  const SizedBox(height: 4),
                                  Text('Question ${currentIndex + 1} of ${questions.length}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                              child: Text('$answeredCount answered', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(_brandBlue)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: LuxTheme.panel,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _brandBlue.withValues(alpha: 0.52)),
                            ),
                            child: Text(questionText, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.45, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 14),
                          const Text('SELECT ONE ANSWER', style: TextStyle(color: _brandBlue, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.25)),
                          const SizedBox(height: 9),
                          ...List.generate(options.length, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AnswerOption(label: options[i], index: i, isSelected: picked == i, onTap: () => _selectAnswer(i)),
                          )),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: currentIndex == 0 ? null : _prev,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('BACK'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white30,
                            side: BorderSide(color: currentIndex == 0 ? Colors.white12 : _brandBlue.withValues(alpha: 0.55)),
                            backgroundColor: LuxTheme.panel,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _next,
                          icon: Icon(currentIndex == questions.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 19),
                          label: Text(currentIndex == questions.length - 1 ? 'FINISH' : 'NEXT'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: _brandBlue,
                            foregroundColor: const Color(0xFF06131E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
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

  const _AnswerOption({required this.label, required this.index, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const brandBlue = LuxTheme.accentGlow;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? brandBlue.withValues(alpha: 0.13) : LuxTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? brandBlue : brandBlue.withValues(alpha: 0.38), width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: brandBlue.withValues(alpha: 0.16), blurRadius: 16)] : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? brandBlue : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: brandBlue, width: isSelected ? 2 : 1),
                ),
                child: Center(
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Color(0xFF06131E), size: 21)
                      : Text(String.fromCharCode(65 + index), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: TextStyle(color: Colors.white, height: 1.42, fontSize: 15.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
