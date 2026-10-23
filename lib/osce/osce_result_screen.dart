import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import 'osce_models.dart';

class OsceResultScreen extends StatelessWidget {
  final OsceResult result;

  const OsceResultScreen({super.key, required this.result});

  static const Color _blue = Color(0xFF39C2FF);

  Color _scoreColor(double percent) {
    if (percent >= 85) return Colors.greenAccent;
    if (percent >= 70) return _blue;
    if (percent >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final percent = result.percent;
    final percentLabel = percent.toStringAsFixed(1);

    final domains = result.domains.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final weakest = domains.take(2).toList();
    final strongest = domains.reversed.take(2).toList();

    final insight = _buildInsight(percent, weakest);
    final actions = _buildActionPlan(weakest);

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: Text(result.stationTitle),
      ),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ResultHeroCard(
                score: result.score,
                total: result.total,
                percent: percent,
                percentLabel: percentLabel,
                color: _scoreColor(percent),
              ),

              const SizedBox(height: 18),

              _InsightsCard(
                insight: insight,
                actions: actions,
                percent: percent,
                color: _scoreColor(percent),
              ),

              const SizedBox(height: 18),

              _PerformanceMiniBreakdown(
                weakest: weakest,
                strongest: strongest,
              ),

              const SizedBox(height: 22),
              Divider(color: _blue.withOpacity(0.18)),
              const SizedBox(height: 18),

              _DomainBreakdownCard(domains: result.domains),

              const SizedBox(height: 22),

              const Text(
                "FEEDBACK",
                style: TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              if (result.feedback.isEmpty)
                _EmptyCard(text: "No feedback generated.")
              else
                ...result.feedback.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FeedbackCard(text: f),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInsight(double percent, List<MapEntry<String, int>> weakest) {
    final weak = weakest.isNotEmpty ? weakest.first.key : null;

    if (percent >= 85) {
      return "Excellent execution. You are exam ready.";
    }
    if (percent >= 70) {
      return "Strong performance. ${weak != null ? "$weak needs refinement." : ""}";
    }
    if (percent >= 50) {
      return "Developing performance. ${weak != null ? "$weak is limiting your score." : ""}";
    }
    return "High risk performance. Rebuild your fundamentals.";
  }

  List<String> _buildActionPlan(List<MapEntry<String, int>> weakest) {
    final actions = <String>[];

    if (weakest.isNotEmpty) {
      actions.add("Focus on ${weakest.first.key.toLowerCase()} first");
    }
    if (weakest.length > 1) {
      actions.add("Then improve ${weakest[1].key.toLowerCase()}");
    }

    actions.add("Repeat this station until consistent");
    actions.add("Practice under timed conditions");

    return actions;
  }
}

class _DomainBreakdownCard extends StatelessWidget {
  final Map<String, int> domains;

  const _DomainBreakdownCard({required this.domains});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: domains.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  e.value.toString(),
                  style: const TextStyle(
                    color: Color(0xFF39C2FF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final String text;

  const _FeedbackCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  final int score;
  final int total;
  final double percent;
  final String percentLabel;
  final Color color;

  const _ResultHeroCard({
    required this.score,
    required this.total,
    required this.percent,
    required this.percentLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '$percentLabel%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $total',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final String insight;
  final List<String> actions;
  final double percent;
  final Color color;

  const _InsightsCard({
    required this.insight,
    required this.actions,
    required this.percent,
    required this.color,
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
            "INSIGHTS",
            style: TextStyle(
              color: Color(0xFF39C2FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(insight, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "• $a",
                style: const TextStyle(color: Colors.white60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceMiniBreakdown extends StatelessWidget {
  final List<MapEntry<String, int>> weakest;
  final List<MapEntry<String, int>> strongest;

  const _PerformanceMiniBreakdown({
    required this.weakest,
    required this.strongest,
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
            "PERFORMANCE SNAPSHOT",
            style: TextStyle(
              color: Color(0xFF39C2FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Weakest: ${weakest.map((e) => e.key).join(', ')}",
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            "Strongest: ${strongest.map((e) => e.key).join(', ')}",
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}