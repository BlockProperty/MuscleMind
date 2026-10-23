import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import 'osce_models.dart';
import 'osce_result_screen.dart';

class OsceExamReviewScreen extends StatelessWidget {
  final OsceExamResult exam;

  const OsceExamReviewScreen({super.key, required this.exam});

  static const Color _blue = Color(0xFF39C2FF);

  String _fmtDuration(Duration d) {
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _scoreColor(double percent) {
    if (percent >= 85) return Colors.greenAccent;
    if (percent >= 70) return _blue;
    if (percent >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final pctLabel = exam.percent.toStringAsFixed(1);
    final attempts = [...exam.attempts];

    // DOMAIN AGGREGATION (NEW SYSTEM)
    final domainTotals = exam.domainTotals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final weakestDomains = domainTotals.take(3).toList();
    final strongestDomains = domainTotals.reversed.take(3).toList();

    // STATION PERFORMANCE
    final sortedAttempts = [...attempts]..sort((a, b) {
        final aPct = a.result.percent;
        final bPct = b.result.percent;
        return aPct.compareTo(bPct);
      });

    final weakestStations = sortedAttempts.take(2).toList();
    final strongestStations = sortedAttempts.reversed.take(2).toList();

    final insight = _buildInsight(
      percent: exam.percent,
      weakestDomains: weakestDomains,
      weakestStations: weakestStations,
    );

    final actionPlan = _buildActionPlan(
      weakestDomains: weakestDomains,
      weakestStations: weakestStations,
    );

    final scoreColor = _scoreColor(exam.percent);

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text('Exam Review'),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SummaryHeroCard(
                totalScore: exam.totalScore,
                maxScore: exam.maxScore,
                percentLabel: pctLabel,
                durationLabel: _fmtDuration(exam.totalDuration),
                color: scoreColor,
              ),

              const SizedBox(height: 18),

              _InsightsCard(
                insight: insight,
                actionPlan: actionPlan,
                percent: exam.percent,
              ),

              const SizedBox(height: 22),

              Divider(color: _blue.withOpacity(0.18)),

              const SizedBox(height: 18),

              _PerformanceBreakdownCard(
                weakestDomains: weakestDomains,
                strongestDomains: strongestDomains,
                weakestStations: weakestStations,
                strongestStations: strongestStations,
              ),

              const SizedBox(height: 22),

              const Text(
                'STATIONS',
                style: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 12),

              ...attempts.map((a) {
                final r = a.result;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _StationAttemptCard(
                    title: r.stationTitle,
                    subtitle:
                        '${r.lessonTitle} • ${r.percent.toStringAsFixed(1)}% • ${r.score}/${r.total}',
                    badge: _stationBadge(r.percent),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OsceResultScreen(result: r),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInsight({
    required double percent,
    required List<MapEntry<String, int>> weakestDomains,
    required List<OsceStationAttempt> weakestStations,
  }) {
    final weakDomain =
        weakestDomains.isNotEmpty ? weakestDomains.first.key : null;
    final weakStation =
        weakestStations.isNotEmpty ? weakestStations.first.result.stationTitle : null;

    if (percent >= 85) {
      return 'Strong exam-level performance. Maintain consistency and refine execution.';
    }

    if (percent >= 70) {
      return 'Good foundation. ${weakDomain ?? "Some domains"} need refinement. Focus on $weakStation.';
    }

    if (percent >= 50) {
      return 'Developing performance. ${weakDomain ?? "Core domains"} are limiting your score.';
    }

    return 'Rebuild your fundamentals before attempting another full exam.';
  }

  List<String> _buildActionPlan({
    required List<MapEntry<String, int>> weakestDomains,
    required List<OsceStationAttempt> weakestStations,
  }) {
    final actions = <String>[];

    if (weakestStations.isNotEmpty) {
      actions.add('Repeat ${weakestStations.first.result.stationTitle}');
    }

    if (weakestDomains.isNotEmpty) {
      actions.add('Focus on ${weakestDomains.first.key.toLowerCase()}');
    }

    actions.add('Practice under timed conditions');
    actions.add('Repeat full OSCE until consistent');

    return actions;
  }

  String _stationBadge(double pct) {
    if (pct >= 85) return 'Strong';
    if (pct >= 70) return 'Good';
    if (pct >= 50) return 'Needs work';
    return 'Weak';
  }
}

class _SummaryHeroCard extends StatelessWidget {
  final int totalScore;
  final int maxScore;
  final String percentLabel;
  final String durationLabel;
  final Color color;

  const _SummaryHeroCard({
    required this.totalScore,
    required this.maxScore,
    required this.percentLabel,
    required this.durationLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '$percentLabel%',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text('$totalScore / $maxScore',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('Time: $durationLabel',
              style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final String insight;
  final List<String> actionPlan;
  final double percent;

  const _InsightsCard({
    required this.insight,
    required this.actionPlan,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INSIGHTS',
            style: TextStyle(
              color: Color(0xFF39C2FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(insight, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ...actionPlan.map(
            (e) => Text('• $e',
                style: const TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}

class _PerformanceBreakdownCard extends StatelessWidget {
  final List<MapEntry<String, int>> weakestDomains;
  final List<MapEntry<String, int>> strongestDomains;
  final List<OsceStationAttempt> weakestStations;
  final List<OsceStationAttempt> strongestStations;

  const _PerformanceBreakdownCard({
    required this.weakestDomains,
    required this.strongestDomains,
    required this.weakestStations,
    required this.strongestStations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERFORMANCE',
              style: TextStyle(
                  color: Color(0xFF39C2FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            'Weakest Domains: ${weakestDomains.map((e) => e.key).join(", ")}',
            style: const TextStyle(color: Colors.white60),
          ),
          Text(
            'Strongest Domains: ${strongestDomains.map((e) => e.key).join(", ")}',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 10),
          Text(
            'Weakest Stations: ${weakestStations.map((e) => e.result.stationTitle).join(", ")}',
            style: const TextStyle(color: Colors.white60),
          ),
          Text(
            'Strongest Stations: ${strongestStations.map((e) => e.result.stationTitle).join(", ")}',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _StationAttemptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _StationAttemptCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LuxTheme.panel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
            Text(
              badge,
              style: const TextStyle(
                  color: Color(0xFF39C2FF),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}