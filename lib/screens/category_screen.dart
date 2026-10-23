import 'package:flutter/material.dart';

import '../theme/lux_theme.dart';
import '../widgets/lux_background.dart';
import '../widgets/shimmer.dart';
import 'lesson_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  static const List<_CategoryItem> categories = [
    _CategoryItem(
      title: "Standards of Practice",
      subtitle: "Ethics, professionalism, consent, documentation",
      icon: Icons.verified_user_outlined,
    ),
    _CategoryItem(
      title: "Myology",
      subtitle: "Origins, insertions, actions, innervations",
      icon: Icons.accessibility_new_outlined,
    ),
    _CategoryItem(
      title: "Massage Techniques and Treatments",
      subtitle: "Applications, methods, indications, treatment planning",
      icon: Icons.pan_tool_alt_outlined,
    ),
    _CategoryItem(
      title: "Assessments and Conditions",
      subtitle: "Orthopedic testing, clinical reasoning, presentations",
      icon: Icons.fact_check_outlined,
    ),
    _CategoryItem(
      title: "Remedial Exercise",
      subtitle: "Stretching, strengthening, corrective exercise principles",
      icon: Icons.fitness_center_outlined,
    ),
    _CategoryItem(
      title: "Comprehensive Review",
      subtitle: "Mixed review across major exam domains",
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text("MCQ Categories"),
        centerTitle: true,
      ),
      body: LuxBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _header(),
              const SizedBox(height: 22),
              Divider(color: _blue.withOpacity(0.18)),
              const SizedBox(height: 16),
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryCard(category: category),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.18),
                  blurRadius: 26,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo/musclemind_icon.png',
              width: 74,
              height: 74,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "MCQ PRACTICE",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _blue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose a category and sharpen your exam confidence with focused question practice.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;

  const _CategoryCard({required this.category});

  static const Color _blue = Color(0xFF39C2FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonScreen(category: category.title),
            ),
          );
        },
        child: Shimmer(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LuxTheme.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withOpacity(0.40)),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconCircle(category.icon),
                const SizedBox(width: 16),
                Expanded(child: _textBlock()),
                const SizedBox(width: 10),
                _arrowButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _blue),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.20),
            blurRadius: 14,
          ),
        ],
      ),
      child: Icon(icon, color: _blue),
    );
  }

  Widget _textBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _blue,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          category.subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.70),
            fontSize: 12.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _arrowButton() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _blue.withOpacity(0.75)),
        color: _blue.withOpacity(0.06),
      ),
      child: const Icon(
        Icons.arrow_forward,
        color: _blue,
        size: 20,
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _CategoryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
