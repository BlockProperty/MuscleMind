import 'package:flutter/material.dart';

import '../core/subscription_guard.dart';
import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import 'exam_gate_screen.dart';
import 'paywall_screen.dart';

class LessonScreen extends StatefulWidget {
  final String category;
  final int lessonCount;

  const LessonScreen({
    super.key,
    required this.category,
    this.lessonCount = 10,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  static const Color _blue = LuxTheme.accentGlow;
  static const Color _premium = Color(0xFFFFB547);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
    });
  }

  bool _isLessonUnlocked(int lessonNumber) =>
      lessonNumber == 1 || SubscriptionGuard.isPremium;

  @override
  Widget build(BuildContext context) {
    final hasPremium = SubscriptionGuard.isPremium;

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(title: const Text('MCQ Lessons')),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _blue.withValues(alpha: 0.72)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.10),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECT A LESSON',
                      style: TextStyle(
                        color: _blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasPremium
                          ? 'Premium is active. All ${widget.lessonCount} lessons are ready to practice.'
                          : 'Lesson 1 is free. Premium unlocks all ${widget.lessonCount} lessons in this category.',
                      style: const TextStyle(
                        color: LuxTheme.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const _StatChip(
                          icon: Icons.quiz_outlined,
                          label: '50 questions',
                        ),
                        const SizedBox(width: 8),
                        const _StatChip(
                          icon: Icons.timer_outlined,
                          label: '60 minutes',
                        ),
                        const Spacer(),
                        if (hasPremium)
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: _premium,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (hasPremium) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: _premium.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _premium.withValues(alpha: 0.40)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: _premium, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Premium Active • All lessons unlocked',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...List.generate(widget.lessonCount, (index) {
                final lessonNumber = index + 1;
                final isUnlocked = _isLessonUnlocked(lessonNumber);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LessonCard(
                    lessonNumber: lessonNumber,
                    category: widget.category,
                    isUnlocked: isUnlocked,
                    isFreeLesson: lessonNumber == 1,
                    isPremiumUnlocked:
                        isUnlocked && lessonNumber != 1 && hasPremium,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LuxTheme.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: LuxTheme.accentGlow, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final int lessonNumber;
  final String category;
  final bool isUnlocked;
  final bool isFreeLesson;
  final bool isPremiumUnlocked;

  const _LessonCard({
    required this.lessonNumber,
    required this.category,
    required this.isUnlocked,
    required this.isFreeLesson,
    required this.isPremiumUnlocked,
  });

  static const Color _blue = LuxTheme.accentGlow;
  static const Color _premium = Color(0xFFFFB547);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (!isUnlocked) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExamGateScreen(
                category: category,
                lesson: lessonNumber,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked
                  ? _blue.withValues(alpha: 0.70)
                  : Colors.white.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _blue.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isUnlocked ? _blue : Colors.white38,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$lessonNumber',
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white60,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Lesson $lessonNumber',
                            style: TextStyle(
                              color: isUnlocked ? Colors.white : Colors.white60,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isFreeLesson)
                          _badge('FREE', _blue)
                        else if (isPremiumUnlocked)
                          _badge('PREMIUM', _premium)
                        else if (!isUnlocked)
                          _badge('LOCKED', Colors.white54),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isUnlocked
                          ? '50 exam-style questions • Timed practice'
                          : 'Premium required to open this lesson',
                      style: TextStyle(
                        color: isUnlocked
                            ? LuxTheme.textSecondary
                            : Colors.white54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isUnlocked
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                color: isUnlocked ? _blue : Colors.white54,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
