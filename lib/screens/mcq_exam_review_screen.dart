import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';

class McqExamReviewScreen extends StatelessWidget {
  final String category;
  final int lesson;
  final int score;
  final int totalQuestions;
  final int answeredCount;
  final Map<String, int> topicCorrect;
  final Map<String, int> topicTotal;

  const McqExamReviewScreen({
    super.key,
    required this.category,
    required this.lesson,
    required this.score,
    required this.totalQuestions,
    required this.answeredCount,
    required this.topicCorrect,
    required this.topicTotal,
  });

  static const Color _blue = Color(0xFF39C2FF);

  Color _scoreColor(double percent) {
    if (percent >= 85) return Colors.greenAccent;
    if (percent >= 70) return _blue;
    if (percent >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final percent =
        totalQuestions <= 0 ? 0.0 : (score / totalQuestions) * 100.0;
    final percentLabel = percent.toStringAsFixed(1);
    final unanswered = math.max(0, totalQuestions - answeredCount);

    final topicPercent = <String, double>{};
    final topicKeys =
        <String>{...topicCorrect.keys, ...topicTotal.keys}.toList()..sort();

    for (final key in topicKeys) {
      final got = topicCorrect[key] ?? 0;
      final max = topicTotal[key] ?? 0;
      if (max > 0) {
        topicPercent[key] = (got / max) * 100.0;
      }
    }

    final sortedTopics = topicPercent.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final weakest = sortedTopics.take(3).toList();
    final strongest = sortedTopics.reversed.take(3).toList();

    final insight = _buildInsight(
      percent: percent,
      unanswered: unanswered,
      weakest: weakest,
    );

    final actions = _buildActionPlan(
      unanswered: unanswered,
      weakest: weakest,
    );

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text('MCQ Review'),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _McqHeroCard(
                category: category,
                lesson: lesson,
                score: score,
                totalQuestions: totalQuestions,
                percentLabel: percentLabel,
                percent: percent,
                scoreColor: _scoreColor(percent),
              ),
              const SizedBox(height: 18),
              _McqInsightsCard(
                percent: percent,
                unanswered: unanswered,
                insight: insight,
                actions: actions,
              ),
              const SizedBox(height: 18),
              _McqTopicBreakdownCard(
                weakest: weakest,
                strongest: strongest,
              ),
              const SizedBox(height: 18),
              _McqTotalsCard(
                answeredCount: answeredCount,
                totalQuestions: totalQuestions,
                unanswered: unanswered,
              ),
              const SizedBox(height: 18),
              _McqTopicTotalsCard(
                topicKeys: topicKeys,
                topicCorrect: topicCorrect,
                topicTotal: topicTotal,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('RETRY LESSON'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInsight({
    required double percent,
    required int unanswered,
    required List<MapEntry<String, double>> weakest,
  }) {
    final weakTopic = weakest.isNotEmpty ? weakest.first.key : null;

    if (percent >= 85) {
      return 'Strong MCQ performance. You are showing good recall and decision-making speed. Keep refining precision and consistency.';
    }
    if (percent >= 70) {
      if (weakTopic != null) {
        return 'Good progress overall. Your lowest area is $weakTopic, and improving it should raise your exam readiness quickly.';
      }
      return 'Good progress overall. Tighten weak spots and keep building consistency.';
    }
    if (percent >= 50) {
      if (weakTopic != null) {
        return 'Developing performance. $weakTopic appears to be limiting your score. Focused lesson review is recommended.';
      }
      return 'Developing performance. Review key concepts and repeat this lesson under timed conditions.';
    }

    if (unanswered > 0) {
      return 'Low score with unanswered questions suggests pacing and confidence are both affecting performance. Review fundamentals and practice timing.';
    }

    return 'Low score suggests core knowledge gaps in this lesson. Slow down, rebuild fundamentals, then retest.';
  }

  List<String> _buildActionPlan({
    required int unanswered,
    required List<MapEntry<String, double>> weakest,
  }) {
    final actions = <String>[];

    if (weakest.isNotEmpty) {
      actions.add('Review ${weakest.first.key.toLowerCase()} first.');
    }
    if (weakest.length > 1) {
      actions.add('Then revisit ${weakest[1].key.toLowerCase()}.');
    }
    if (unanswered > 0) {
      actions.add('Work on pacing to reduce unanswered questions.');
    }
    actions.add('Repeat this lesson in timed mode.');
    return actions.take(4).toList();
  }
}

class _McqHeroCard extends StatelessWidget {
  final String category;
  final int lesson;
  final int score;
  final int totalQuestions;
  final String percentLabel;
  final double percent;
  final Color scoreColor;

  const _McqHeroCard({
    required this.category,
    required this.lesson,
    required this.score,
    required this.totalQuestions,
    required this.percentLabel,
    required this.percent,
    required this.scoreColor,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    final progress =
        totalQuestions <= 0 ? 0.0 : (score / totalQuestions).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _blue.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.08),
            blurRadius: 20,
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
              width: 82,
              height: 82,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MCQ EXAM REVIEW',
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
            '$category • Lesson $lesson',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$score / $totalQuestions',
            style: TextStyle(
              color: scoreColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percentLabel%',
            style: TextStyle(
              color: scoreColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _McqInsightsCard extends StatelessWidget {
  final double percent;
  final int unanswered;
  final String insight;
  final List<String> actions;

  const _McqInsightsCard({
    required this.percent,
    required this.unanswered,
    required this.insight,
    required this.actions,
  });

  static const Color _blue = Color(0xFF39C2FF);

  String get _status {
    if (percent >= 85) return 'High Readiness';
    if (percent >= 70) return 'Good Progress';
    if (percent >= 50) return 'Needs Reinforcement';
    return 'Critical Review Needed';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _blue.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFORMANCE INSIGHT',
            style: TextStyle(
              color: _blue,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withOpacity(0.22)),
            ),
            child: Text(
              _status,
              style: const TextStyle(
                color: _blue,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Unanswered: $unanswered',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ACTION PLAN',
            style: TextStyle(
              color: _blue,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 8),
          ...actions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _McqTopicBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, double>> weakest;
  final List<MapEntry<String, double>> strongest;

  const _McqTopicBreakdownCard({
    required this.weakest,
    required this.strongest,
  });

  static const Color _blue = Color(0xFF39C2FF);

  Widget _buildList(
    String title,
    List<MapEntry<String, double>> data,
    Color accent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),
            if (data.isEmpty)
              Text(
                'No data',
                style: TextStyle(color: Colors.white.withOpacity(0.55)),
              )
            else
              ...data.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${e.key} • ${e.value.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      height: 1.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _blue.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOPIC BREAKDOWN',
            style: TextStyle(
              color: _blue,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildList('WEAKEST AREAS', weakest, Colors.redAccent),
              const SizedBox(width: 12),
              _buildList('STRONGEST AREAS', strongest, Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }
}

class _McqTotalsCard extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final int unanswered;

  const _McqTotalsCard({
    required this.answeredCount,
    required this.totalQuestions,
    required this.unanswered,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _blue.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXAM TOTALS',
            style: TextStyle(
              color: _blue,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          _row('Answered', answeredCount.toString()),
          _row('Unanswered', unanswered.toString()),
          _row('Total Questions', totalQuestions.toString()),
        ],
      ),
    );
  }

  Widget _row(String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            right,
            style: const TextStyle(
              color: _blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _McqTopicTotalsCard extends StatelessWidget {
  final List<String> topicKeys;
  final Map<String, int> topicCorrect;
  final Map<String, int> topicTotal;

  const _McqTopicTotalsCard({
    required this.topicKeys,
    required this.topicCorrect,
    required this.topicTotal,
  });

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _blue.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOPIC TOTALS',
            style: TextStyle(
              color: _blue,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          if (topicKeys.isEmpty)
            Text(
              'No topic breakdown available.',
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
            )
          else
            ...topicKeys.map((topic) {
              final got = topicCorrect[topic] ?? 0;
              final max = topicTotal[topic] ?? 0;
              final pct = max > 0 ? (got / max) * 100.0 : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$got / $max (${pct.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
