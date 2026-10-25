import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import '../osce/stations/stations_menu_screen.dart';
import 'osce_exam_guide_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _accent = LuxTheme.accentGlow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      body: LuxBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  onSettings: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const _BrandHero(),
                const SizedBox(height: 18),
                const Text(
                  'Choose your training mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Build knowledge, rehearse clinical performance, and prepare for exam day.',
                  style: TextStyle(
                    color: LuxTheme.textSecondary,
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _TrainingCard(
                  icon: Icons.quiz_outlined,
                  eyebrow: 'KNOWLEDGE',
                  title: 'MCQ Practice',
                  subtitle: 'Focused lessons, timed practice and comprehensive review.',
                  detail: '6 categories • 50 questions per lesson',
                  onTap: () => Navigator.of(context).pushNamed('/category'),
                ),
                const SizedBox(height: 12),
                _TrainingCard(
                  icon: Icons.medical_services_outlined,
                  eyebrow: 'CLINICAL PERFORMANCE',
                  title: 'OSCE Stations',
                  subtitle: 'Rehearse station flow, timing and hands-on clinical reasoning.',
                  detail: 'Practice mode • Exam simulation',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StationsMenuScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _TrainingCard(
                  icon: Icons.route_outlined,
                  eyebrow: 'EXAM STRATEGY',
                  title: 'OSCE Blueprint',
                  subtitle: 'Review a structured step-by-step guide before you enter a station.',
                  detail: 'Premium exam preparation guide',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OsceExamGuideScreen()),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const _ExamReadyBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSettings;
  const _TopBar({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MUSCLEMIND',
                style: TextStyle(
                  color: HomeScreen._accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Massage Therapy Exam Prep',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Settings',
          onPressed: onSettings,
          style: IconButton.styleFrom(
            backgroundColor: LuxTheme.panel,
            foregroundColor: HomeScreen._accent,
            side: BorderSide(color: HomeScreen._accent.withValues(alpha: 0.65)),
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LuxTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HomeScreen._accent.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: HomeScreen._accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LuxTheme.black,
              border: Border.all(color: HomeScreen._accent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: HomeScreen._accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo/musclemind_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Train with purpose.\nPerform with confidence.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'MCQ knowledge and OSCE performance preparation in one focused space.',
                  style: TextStyle(
                    color: LuxTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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

class _TrainingCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  const _TrainingCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: LuxTheme.panel,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: HomeScreen._accent.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: HomeScreen._accent.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: LuxTheme.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: HomeScreen._accent.withValues(alpha: 0.72)),
                ),
                child: Icon(icon, color: HomeScreen._accent, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: HomeScreen._accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LuxTheme.textSecondary,
                        fontSize: 12.8,
                        height: 1.38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Padding(
                padding: EdgeInsets.only(top: 13),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: HomeScreen._accent,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamReadyBanner extends StatelessWidget {
  const _ExamReadyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: LuxTheme.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HomeScreen._accent.withValues(alpha: 0.38)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: HomeScreen._accent),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Small, consistent practice sessions can make exam-day decisions feel more familiar.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
