import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import '../widgets/shimmer.dart';
import 'exam_screen.dart';

class ExamGateScreen extends StatelessWidget {
  final String category;
  final int lesson;

  const ExamGateScreen({
    super.key,
    required this.category,
    required this.lesson,
  });

  String get _attemptKey => 'mcq::$category::$lesson';

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('mcq_attempts');
    final bool hasAttempt = box.containsKey(_attemptKey);

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: Text('Lesson $lesson'),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 22),
                Divider(color: _blue.withOpacity(0.18)),
                const SizedBox(height: 18),
                const _InfoCard(
                  icon: Icons.quiz_outlined,
                  title: "50 Questions",
                  subtitle: "Current lesson format",
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  icon: Icons.timer_outlined,
                  title: "60 Minutes",
                  subtitle: "Board pacing: 150 questions / 3 hours",
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  icon: Icons.save_outlined,
                  title: "Auto Save",
                  subtitle: "Your progress is saved automatically",
                ),
                const SizedBox(height: 26),
                if (!hasAttempt) ...[
                  _PrimaryAction(
                    title: "START EXAM",
                    onTap: () => _start(context),
                  ),
                ] else ...[
                  _PrimaryAction(
                    title: "RESUME EXAM",
                    onTap: () => _resume(context),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryAction(
                    title: "RESTART EXAM",
                    onTap: () => _restart(context, box),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _blue.withOpacity(0.28)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.18),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo/musclemind_icon.png',
              width: 78,
              height: 78,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            category.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _blue,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Lesson $lesson Exam",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Build speed, confidence, and exam discipline with focused practice.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _start(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamScreen(
          category: category,
          lesson: lesson,
          mode: ExamMode.newAttempt,
        ),
      ),
    );
  }

  void _resume(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamScreen(
          category: category,
          lesson: lesson,
          mode: ExamMode.resume,
        ),
      ),
    );
  }

  Future<void> _restart(BuildContext context, Box box) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restart exam?'),
        content: const Text(
          'This will delete your saved progress for this lesson.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restart',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await box.delete(_attemptKey);
      if (!context.mounted) return;
      _start(context);
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _blue),
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
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
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

class _PrimaryAction extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.title,
    required this.onTap,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Shimmer(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _blue.withOpacity(0.55)),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SecondaryAction({
    required this.title,
    required this.onTap,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.red.withOpacity(0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: LuxTheme.panel,
      ),
      child: const Text(
        "RESTART EXAM",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
