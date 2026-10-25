import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
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

  static const Color _blue = LuxTheme.accentGlow;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('mcq_attempts');
    final bool hasAttempt = box.containsKey(_attemptKey);

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(title: Text('Lesson $lesson')),
      body: LuxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _blue.withValues(alpha: 0.72)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: _blue),
                            ),
                            child: const Icon(
                              Icons.quiz_outlined,
                              color: _blue,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _blue,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lesson $lesson Practice Exam',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Practice under realistic pacing while your answers and progress are saved automatically.',
                        style: TextStyle(
                          color: LuxTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.quiz_outlined,
                        title: '50',
                        subtitle: 'Questions',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.timer_outlined,
                        title: '60 min',
                        subtitle: 'Time limit',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.save_outlined,
                        title: 'Auto',
                        subtitle: 'Progress save',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _blue.withValues(alpha: 0.32)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: _blue, size: 21),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Answer each question before moving forward. You can go back to review earlier answers before finishing.',
                          style: TextStyle(
                            color: LuxTheme.textSecondary,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!hasAttempt)
                  _PrimaryAction(
                    title: 'START PRACTICE EXAM',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => _start(context),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _blue.withValues(alpha: 0.32)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.history_rounded, color: _blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Saved attempt found. Continue where you left off.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryAction(
                    title: 'RESUME PRACTICE EXAM',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => _resume(context),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _restart(context, box),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('RESTART EXAM'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: BorderSide(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.65),
                      ),
                      backgroundColor: LuxTheme.panel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
              style: TextStyle(color: Color(0xFFFF6B6B)),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: LuxTheme.accentGlow.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: LuxTheme.accentGlow, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: LuxTheme.textSecondary,
              fontSize: 10.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: LuxTheme.accentGlow,
        foregroundColor: LuxTheme.black,
        side: const BorderSide(color: LuxTheme.accentGlow),
        padding: const EdgeInsets.symmetric(vertical: 17),
      ),
    );
  }
}
