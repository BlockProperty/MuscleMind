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

  const McqExamReviewScreen({super.key, required this.category, required this.lesson, required this.score, required this.totalQuestions, required this.answeredCount, required this.topicCorrect, required this.topicTotal});

  static const Color _blue = LuxTheme.accentGlow;

  Color _scoreColor(double p) => p >= 85 ? const Color(0xFF54E6A5) : p >= 70 ? _blue : p >= 50 ? const Color(0xFFFFB547) : const Color(0xFFFF6B6B);
  String _status(double p) => p >= 85 ? 'Strong Performance' : p >= 70 ? 'Good Progress' : p >= 50 ? 'Needs Reinforcement' : 'Focused Review Needed';

  @override
  Widget build(BuildContext context) {
    final percent = totalQuestions <= 0 ? 0.0 : score / totalQuestions * 100;
    final unanswered = math.max(0, totalQuestions - answeredCount);
    final incorrect = math.max(0, answeredCount - score);
    final topicKeys = <String>{...topicCorrect.keys, ...topicTotal.keys}.toList()..sort();
    final topicPercent = <String, double>{};
    for (final k in topicKeys) {
      final total = topicTotal[k] ?? 0;
      if (total > 0) topicPercent[k] = ((topicCorrect[k] ?? 0) / total) * 100;
    }
    final sorted = topicPercent.entries.toList()..sort((a,b) => a.value.compareTo(b.value));
    final weak = sorted.take(3).toList();
    final strong = sorted.reversed.take(3).toList();
    final color = _scoreColor(percent);

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(title: const Text('Exam Results'), centerTitle: true),
      body: LuxBackground(child: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _Hero(category: category, lesson: lesson, score: score, total: totalQuestions, percent: percent, color: color, status: _status(percent)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Metric(icon: Icons.check_circle_outline_rounded, value: '$score', label: 'Correct', color: const Color(0xFF54E6A5))),
            const SizedBox(width: 9),
            Expanded(child: _Metric(icon: Icons.close_rounded, value: '$incorrect', label: 'Incorrect', color: const Color(0xFFFF6B6B))),
            const SizedBox(width: 9),
            Expanded(child: _Metric(icon: Icons.help_outline_rounded, value: '$unanswered', label: 'Unanswered', color: const Color(0xFFFFB547))),
          ]),
          const SizedBox(height: 14),
          _Section(title: 'PERFORMANCE INSIGHT', icon: Icons.psychology_alt_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_insight(percent, unanswered, weak), style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('NEXT STEPS', style: TextStyle(color: _blue, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            ..._actions(unanswered, weak).map((x) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.arrow_forward_rounded, color: _blue, size: 15), const SizedBox(width: 8), Expanded(child: Text(x, style: const TextStyle(color: LuxTheme.textSecondary, height: 1.35, fontWeight: FontWeight.w600)))]))),
          ])),
          const SizedBox(height: 14),
          _Section(
            title: topicPercent.length == 1 ? 'TOPIC PERFORMANCE' : 'TOPIC HIGHLIGHTS',
            icon: Icons.insights_outlined,
            child: topicPercent.length == 1
                ? _SingleTopicPerformance(entry: topicPercent.entries.first)
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _TopicBox(title: 'REVIEW FIRST', entries: weak, color: const Color(0xFFFF6B6B))),
                    const SizedBox(width: 9),
                    Expanded(child: _TopicBox(title: 'STRONGEST', entries: strong, color: const Color(0xFF54E6A5))),
                  ]),
          ),
          const SizedBox(height: 14),
          _Section(title: 'DETAILED BREAKDOWN', icon: Icons.bar_chart_rounded, child: topicKeys.isEmpty ? const Text('No topic breakdown is available.', style: TextStyle(color: LuxTheme.textSecondary)) : Column(children: topicKeys.map((k) {
            final got = topicCorrect[k] ?? 0; final total = topicTotal[k] ?? 0; final p = total == 0 ? 0.0 : got / total; final pct = (p * 100).round();
            return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [Row(children: [Expanded(child: Text(k, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700))), Text('$got/$total • $pct%', style: const TextStyle(color: _blue, fontSize: 11.5, fontWeight: FontWeight.w800))]), const SizedBox(height: 7), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: p, minHeight: 6, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(_blue)))]));
          }).toList())),
          const SizedBox(height: 18),
          ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.replay_rounded), label: const Text('RETRY LESSON'), style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: const Color(0xFF06131E), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded), label: const Text('BACK TO LESSON'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: _blue.withValues(alpha: .6)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
        ],
      ))),
    );
  }

  String _insight(double p, int unanswered, List<MapEntry<String,double>> weak) {
    final topic = weak.isEmpty ? null : weak.first.key;
    if (p >= 85) return 'Strong recall and decision-making. Keep practicing under timed conditions to maintain accuracy and consistency.';
    if (p >= 70) return topic == null ? 'Good progress overall. Tighten weaker concepts and keep building consistency.' : 'Good progress overall. Improving $topic should raise your score further.';
    if (p >= 50) return topic == null ? 'Your foundation is developing. Review key concepts, then repeat this lesson.' : '$topic is currently your lowest-performing area. Focused review there is recommended before your next attempt.';
    return unanswered > 0 ? 'Knowledge gaps and pacing may both be affecting this attempt. Review the fundamentals and work toward answering every question.' : 'This result suggests important knowledge gaps. Review the fundamentals carefully, then retest.';
  }

  List<String> _actions(int unanswered, List<MapEntry<String,double>> weak) {
    final a = <String>[];
    if (weak.isNotEmpty) a.add(weak.length == 1 ? 'Review ${weak.first.key} before your next attempt.' : 'Review ${weak.first.key} first.');
    if (weak.length > 1) a.add('Then revisit ${weak[1].key}.');
    if (unanswered > 0) a.add('Improve pacing so fewer questions remain unanswered.');
    a.add('Repeat this lesson under the 60-minute timer.');
    return a.take(4).toList();
  }
}

class _Hero extends StatelessWidget {
  final String category, status; final int lesson, score, total; final double percent; final Color color;
  const _Hero({required this.category, required this.lesson, required this.score, required this.total, required this.percent, required this.color, required this.status});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(24), border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .75)), boxShadow: [BoxShadow(color: LuxTheme.accentGlow.withValues(alpha: .1), blurRadius: 24, offset: const Offset(0,10))]), child: Column(children: [Text(category.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: LuxTheme.accentGlow, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.3)), const SizedBox(height: 5), Text('Lesson $lesson Results', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 18), Container(width: 128, height: 128, decoration: BoxDecoration(shape: BoxShape.circle, color: LuxTheme.black.withValues(alpha: .45), border: Border.all(color: color, width: 5), boxShadow: [BoxShadow(color: color.withValues(alpha: .15), blurRadius: 24)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900)), Text('$score / $total', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800))])), const SizedBox(height: 14), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withValues(alpha: .55))), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)))]));
}

class _Metric extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _Metric({required this.icon, required this.value, required this.label, required this.color});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13), decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: color.withValues(alpha: .45))), child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 6), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: LuxTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700))]));
}

class _Section extends StatelessWidget {
  final String title; final IconData icon; final Widget child;
  const _Section({required this.title, required this.icon, required this.child});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: LuxTheme.accentGlow, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: LuxTheme.accentGlow, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1))]), const SizedBox(height: 13), child]));
}

class _SingleTopicPerformance extends StatelessWidget {
  final MapEntry<String, double> entry;
  const _SingleTopicPerformance({required this.entry});

  @override
  Widget build(BuildContext context) {
    final progress = (entry.value / 100).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: LuxTheme.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .42)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
          Text('${entry.value.toStringAsFixed(0)}%', style: const TextStyle(color: LuxTheme.accentGlow, fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(LuxTheme.accentGlow))),
        const SizedBox(height: 9),
        const Text('Your performance for this lesson topic.', style: TextStyle(color: LuxTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _TopicBox extends StatelessWidget {
  final String title; final List<MapEntry<String,double>> entries; final Color color;
  const _TopicBox({required this.title, required this.entries, required this.color});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: LuxTheme.black.withValues(alpha: .35), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withValues(alpha: .38))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .7)), const SizedBox(height: 8), if (entries.isEmpty) const Text('No topic data', style: TextStyle(color: LuxTheme.textSecondary, fontSize: 11)) else ...entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text('${e.key}\n${e.value.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3, fontWeight: FontWeight.w700))))]));
}