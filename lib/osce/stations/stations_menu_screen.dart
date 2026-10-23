import 'package:flutter/material.dart';

import '../../core/subscription_guard.dart';
import '../../screens/paywall_screen.dart';
import '../../theme/lux_theme.dart';
import '../../widgets/lux_background.dart';
import '../../widgets/shimmer.dart';

import '../exam/exam_runner_screen.dart';
import 'station_lessons_screen.dart';

class StationsMenuScreen extends StatelessWidget {
  static const String routeName = '/stations';

  const StationsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stations = <_StationMenuItem>[
      _station(
        title: 'Station 1 — Therapeutic Exercise',
        subtitle: 'Exercise prescription & demonstration',
        icon: Icons.fitness_center,
        id: 'therapeutic_exercise',
      ),
      _station(
        title: 'Station 2 — Client Interview',
        subtitle: 'Health history & communication',
        icon: Icons.record_voice_over,
        id: 'client_interview',
      ),
      _station(
        title: 'Station 3 — Assessment 1',
        subtitle: 'Orthopedic assessment (part 1)',
        icon: Icons.fact_check,
        id: 'assessment_1',
      ),
      _station(
        title: 'Station 4 — Assessment 2',
        subtitle: 'Orthopedic assessment (part 2)',
        icon: Icons.assignment_turned_in,
        id: 'assessment_2',
      ),
      _station(
        title: 'Station 5 — Initial Treatment & Consent',
        subtitle: 'Consent + clinical reasoning',
        icon: Icons.description,
        id: 'initial_treatment_consent',
      ),
      _station(
        title: 'Station 6 — Treatment',
        subtitle: 'Hands-on treatment execution',
        icon: Icons.healing,
        id: 'treatment',
      ),
      _station(
        title: 'Station 7 — Techniques',
        subtitle: 'Technique protocols & application',
        icon: Icons.pan_tool_alt,
        id: 'techniques',
      ),
    ];

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text('OSCE Stations'),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _OsceHeroCard(),

              const SizedBox(height: 22),
              const _BlueDivider(),
              const SizedBox(height: 16),

              // 🔥 PRIMARY ACTION
              _PrimaryOsceAction(
                title: 'START FULL EXAM',
                subtitle: 'Simulate full OSCE under real exam timing',
                icon: Icons.play_circle_fill,
                onTap: () {
                  if (!SubscriptionGuard.isPremium) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaywallScreen(),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExamRunnerScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // 🔥 STATIONS
              ...stations.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _StationCard(item: item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _StationMenuItem _station({
    required String title,
    required String subtitle,
    required IconData icon,
    required String id,
  }) {
    return _StationMenuItem(
      title: title,
      subtitle: subtitle,
      icon: icon,
      builder: (_) => StationLessonsScreen(
        stationId: id,
        stationTitle: title,
      ),
    );
  }
}

class _OsceHeroCard extends StatelessWidget {
  const _OsceHeroCard();

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF39C2FF);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandBlue.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: brandBlue.withOpacity(0.08),
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
                  color: brandBlue.withOpacity(0.22),
                  blurRadius: 32,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo/musclemind_icon.png',
              width: 92,
              height: 92,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'OSCE PRACTICE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brandBlue,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Practice individual stations or simulate a full OSCE exam experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryOsceAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryOsceAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF39C2FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Shimmer(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: brandBlue.withOpacity(0.55)),
              boxShadow: [
                BoxShadow(
                  color: brandBlue.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: brandBlue),
                  ),
                  child: Icon(icon, color: brandBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: brandBlue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    const Color brandBlue = Color(0xFF39C2FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: item.builder),
          );
        },
        child: Shimmer(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: brandBlue.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: brandBlue),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: brandBlue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: brandBlue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueDivider extends StatelessWidget {
  const _BlueDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: const Color(0xFF39C2FF).withOpacity(0.18));
  }
}

class _StationMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;

  _StationMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });
}
