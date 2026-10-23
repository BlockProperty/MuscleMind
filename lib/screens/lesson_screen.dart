import 'package:flutter/material.dart';

import '../core/subscription_guard.dart';
import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import '../widgets/shimmer.dart';
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
  static const Color _blue = Color(0xFF39C2FF);
  static const Color _premium = Colors.orange;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() {});
    });
  }

  bool _isLessonUnlocked(int lessonNumber) {
    if (lessonNumber == 1) return true;
    if (SubscriptionGuard.isPremium) return true;
    return false;
  }

  bool _isFreeLesson(int lessonNumber) {
    return lessonNumber == 1;
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = SubscriptionGuard.isPremium;

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (hasPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _premium.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _premium.withOpacity(0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _premium.withOpacity(0.08),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: _premium,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Premium Active • All lessons unlocked',
                          style: TextStyle(
                            color: _premium,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _blue.withOpacity(0.28)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.category.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasPremium
                          ? 'Premium active. All lessons in this category are unlocked.'
                          : 'Start with Lesson 1 for free, then unlock full access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Divider(color: _blue.withOpacity(0.18)),
              const SizedBox(height: 16),
              ...List.generate(widget.lessonCount, (index) {
                final lessonNumber = index + 1;
                final isUnlocked = _isLessonUnlocked(lessonNumber);
                final isFreeLesson = _isFreeLesson(lessonNumber);
                final isPremiumUnlocked =
                    isUnlocked && !isFreeLesson && hasPremium;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LessonCard(
                    lessonNumber: lessonNumber,
                    category: widget.category,
                    isUnlocked: isUnlocked,
                    isFreeLesson: isFreeLesson,
                    isPremiumUnlocked: isPremiumUnlocked,
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

  static const Color _blue = Color(0xFF39C2FF);
  static const Color _premium = Colors.orange;

  @override
  Widget build(BuildContext context) {
    final showLockedBadge = !isUnlocked && !isFreeLesson;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (!isUnlocked) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PaywallScreen(),
              ),
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
        child: Shimmer(
          enabled: isUnlocked,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked
                    ? _blue.withOpacity(0.5)
                    : Colors.white.withOpacity(0.18),
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: _blue.withOpacity(0.08),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked ? _blue : Colors.white30,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$lessonNumber',
                      style: TextStyle(
                        color: isUnlocked ? _blue : Colors.white70,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                                color: isUnlocked ? _blue : Colors.white,
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
                          else if (showLockedBadge)
                            _badge('LOCKED', Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUnlocked
                            ? 'Practice questions • Timed • Exam-style'
                            : 'Unlock all lessons with Premium',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUnlocked ? Icons.arrow_forward : Icons.lock,
                  color: isUnlocked ? _blue : Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}