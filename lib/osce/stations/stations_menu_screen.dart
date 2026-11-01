import 'package:flutter/material.dart';

import '../../core/subscription_guard.dart';
import '../../screens/paywall_screen.dart';
import '../../theme/lux_theme.dart';
import '../../widgets/lux_background.dart';

import '../exam/exam_runner_screen.dart';
import 'station_lessons_screen.dart';

class StationsMenuScreen extends StatelessWidget {
  static const String routeName = '/stations';
  const StationsMenuScreen({super.key});

  static const Color _blue = LuxTheme.accentGlow;

  @override
  Widget build(BuildContext context) {
    final stations = <_StationMenuItem>[
      _station(number: 1, title: 'Therapeutic Exercise', subtitle: 'Exercise prescription & demonstration', icon: Icons.fitness_center_rounded, id: 'therapeutic_exercise'),
      _station(number: 2, title: 'Client Interview', subtitle: 'Health history & communication', icon: Icons.record_voice_over_rounded, id: 'client_interview'),
      _station(number: 3, title: 'Assessment 1', subtitle: 'Orthopedic assessment • part 1', icon: Icons.fact_check_outlined, id: 'assessment_1'),
      _station(number: 4, title: 'Assessment 2', subtitle: 'Orthopedic assessment • part 2', icon: Icons.assignment_turned_in_outlined, id: 'assessment_2'),
      _station(number: 5, title: 'Initial Treatment & Consent', subtitle: 'Consent & clinical reasoning', icon: Icons.description_outlined, id: 'initial_treatment_consent'),
      _station(number: 6, title: 'Treatment', subtitle: 'Hands-on treatment execution', icon: Icons.healing_rounded, id: 'treatment'),
      _station(number: 7, title: 'Techniques', subtitle: 'Technique protocols & application', icon: Icons.pan_tool_alt_rounded, id: 'techniques'),
    ];

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(title: const Text('OSCE Practice'), centerTitle: true),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              const _OsceHero(),
              const SizedBox(height: 16),
              _FullExamCard(
                onTap: () {
                  if (!SubscriptionGuard.isPremium) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamRunnerScreen()));
                },
              ),
              const SizedBox(height: 22),
              const Row(children: [
                Expanded(child: Text('PRACTICE BY STATION', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
                Text('7 STATIONS', style: TextStyle(color: _blue, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .8)),
              ]),
              const SizedBox(height: 6),
              const Text('Choose a station, select a lesson, and practice the timed flow.', style: TextStyle(color: LuxTheme.textSecondary, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 14),
              ...stations.map((item) => Padding(padding: const EdgeInsets.only(bottom: 11), child: _StationCard(item: item))),
            ],
          ),
        ),
      ),
    );
  }

  static _StationMenuItem _station({required int number, required String title, required String subtitle, required IconData icon, required String id}) {
    return _StationMenuItem(
      number: number,
      title: title,
      subtitle: subtitle,
      icon: icon,
      builder: (_) => StationLessonsScreen(stationId: id, stationTitle: 'Station $number — $title'),
    );
  }
}

class _OsceHero extends StatelessWidget {
  const _OsceHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .62)),
        boxShadow: [BoxShadow(color: LuxTheme.accentGlow.withValues(alpha: .09), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(shape: BoxShape.circle, color: LuxTheme.accentGlow.withValues(alpha: .10), border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .65))),
          child: const Icon(Icons.medical_services_outlined, color: LuxTheme.accentGlow, size: 30),
        ),
        const SizedBox(height: 13),
        const Text('OSCE TRAINING', style: TextStyle(color: LuxTheme.accentGlow, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
        const SizedBox(height: 5),
        const Text('Practice. Perform. Refine.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Build confidence across all seven stations with realistic timing, station prompts, and structured practice.', textAlign: TextAlign.center, style: TextStyle(color: LuxTheme.textSecondary, fontSize: 12.5, height: 1.45)),
        const SizedBox(height: 15),
        const Row(children: [
          Expanded(child: _HeroStat(icon: Icons.door_front_door_outlined, value: '2 min', label: 'Door time')),
          SizedBox(width: 8),
          Expanded(child: _HeroStat(icon: Icons.timer_outlined, value: '10 min', label: 'Station')),
          SizedBox(width: 8),
          Expanded(child: _HeroStat(icon: Icons.notifications_active_outlined, value: '3 min', label: 'Warning')),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(color: LuxTheme.black.withValues(alpha: .35), borderRadius: BorderRadius.circular(14), border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .28))),
      child: Column(children: [
        Icon(icon, color: LuxTheme.accentGlow, size: 17),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: LuxTheme.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _FullExamCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FullExamCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: LuxTheme.accentGlow.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LuxTheme.accentGlow, width: 1.4),
            boxShadow: [BoxShadow(color: LuxTheme.accentGlow.withValues(alpha: .12), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            Container(width: 50, height: 50, decoration: const BoxDecoration(color: LuxTheme.accentGlow, shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF06131E), size: 31)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FULL EXAM RUN', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: .6)),
              SizedBox(height: 4),
              Text('Run all 7 stations in sequence with exam-style timing.', style: TextStyle(color: LuxTheme.textSecondary, fontSize: 11.5, height: 1.35)),
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: LuxTheme.accentGlow, size: 17),
          ]),
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final _StationMenuItem item;
  const _StationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: item.builder)),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: LuxTheme.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .38))),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: LuxTheme.accentGlow.withValues(alpha: .09), borderRadius: BorderRadius.circular(14), border: Border.all(color: LuxTheme.accentGlow.withValues(alpha: .38))),
              child: Stack(alignment: Alignment.center, children: [
                Icon(item.icon, color: LuxTheme.accentGlow, size: 22),
                Positioned(right: 3, top: 2, child: Container(width: 16, height: 16, alignment: Alignment.center, decoration: const BoxDecoration(color: LuxTheme.accentGlow, shape: BoxShape.circle), child: Text('${item.number}', style: const TextStyle(color: Color(0xFF06131E), fontSize: 9, fontWeight: FontWeight.w900)))),
              ]),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(item.subtitle, style: const TextStyle(color: LuxTheme.textSecondary, fontSize: 11.5, height: 1.3)),
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: LuxTheme.accentGlow, size: 24),
          ]),
        ),
      ),
    );
  }
}

class _StationMenuItem {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  _StationMenuItem({required this.number, required this.title, required this.subtitle, required this.icon, required this.builder});
}
