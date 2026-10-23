import 'dart:async';
import 'package:flutter/material.dart';

import 'package:musclemind_app/theme/lux_theme.dart';
import 'package:musclemind_app/widgets/lux_background.dart';
import 'package:musclemind_app/osce/bell.dart';

class RunnerTask {
  final String id;
  final String label;
  final String section;

  const RunnerTask({
    required this.id,
    required this.label,
    required this.section,
  });
}

class StationRunnerScreen extends StatefulWidget {
  final String stationId;
  final String stationTitle;
  final String lessonTitle;
  final String stem;
  final List<dynamic> tasks;
  final int stationSeconds;
  final int warningSeconds;

  const StationRunnerScreen({
    super.key,
    required this.stationId,
    required this.stationTitle,
    required this.lessonTitle,
    required this.stem,
    required this.tasks,
    required this.stationSeconds,
    required this.warningSeconds,
  });

  @override
  State<StationRunnerScreen> createState() => _StationRunnerScreenState();
}

class _StationRunnerScreenState extends State<StationRunnerScreen> {
  static const Color _blue = Color(0xFF39C2FF);

  Timer? _timer;
  int remaining = 0;
  bool _warningPlayed = false;
  bool _timeEnded = false;

  late final List<RunnerTask> _tasks;
  final Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    remaining = widget.stationSeconds;
    _tasks = _normalizeTasks(widget.tasks);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<RunnerTask> _normalizeTasks(List<dynamic> raw) {
    final tasks = <RunnerTask>[];

    if (raw.isEmpty) return tasks;

    if (raw.every((e) => e is String)) {
      for (var i = 0; i < raw.length; i++) {
        final label = raw[i].toString().trim();
        if (label.isEmpty) continue;

        tasks.add(
          RunnerTask(
            id: 'task_${i + 1}',
            label: label,
            section: 'Tasks',
          ),
        );
      }
      return tasks;
    }

    if (raw.every((e) => e is Map)) {
      for (var i = 0; i < raw.length; i++) {
        final m = Map<String, dynamic>.from(raw[i]);
        final label = (m['label'] ?? m['task'] ?? '').toString().trim();

        if (label.isEmpty) continue;

        tasks.add(
          RunnerTask(
            id: (m['id'] ?? 'task_${i + 1}').toString(),
            label: label,
            section: (m['section'] ?? 'Tasks').toString(),
          ),
        );
      }
      return tasks;
    }

    return tasks;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted || _timeEnded) return;

      if (remaining > 0) {
        setState(() => remaining--);

        if (!_warningPlayed && remaining == widget.warningSeconds) {
          _warningPlayed = true;
          try {
            await Bell.ringWarning();
          } catch (_) {}
        }
      } else {
        t.cancel();
        _timeEnded = true;

        try {
          await Bell.ringEnd();
        } catch (_) {}

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('TIME — STOP'),
            content: const Text('Station time has ended.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (remaining <= 60) return const Color(0xFFDC2626);
    if (remaining <= widget.warningSeconds) return const Color(0xFFF59E0B);
    return _blue;
  }

  void _toggle(String id) {
    if (_timeEnded) return;

    setState(() {
      if (_done.contains(id)) {
        _done.remove(id);
      } else {
        _done.add(id);
      }
    });
  }

  void _openStem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: LuxTheme.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _blue.withOpacity(0.22)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'STEM',
                  style: TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.stem.isEmpty
                          ? '(No stem available.)'
                          : widget.stem,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<RunnerTask>>{};
    for (final t in _tasks) {
      grouped.putIfAbsent(t.section, () => []).add(t);
    }

    final completion =
        _tasks.isEmpty ? 0.0 : (_done.length / _tasks.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: LuxTheme.black,
      appBar: AppBar(
        title: const Text('STATION RUNNER'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'View stem',
            onPressed: _openStem,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: LuxTheme.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _timerColor().withOpacity(0.65)),
                  boxShadow: [
                    BoxShadow(
                      color: _timerColor().withOpacity(0.16),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Text(
                  _fmt(remaining),
                  style: TextStyle(
                    color: _timerColor(),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LuxBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LuxTheme.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _blue.withOpacity(0.28)),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stationTitle.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.lessonTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: completion,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_blue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Completed: ${_done.length}/${_tasks.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: LuxTheme.panel,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _blue.withOpacity(0.22),
                              ),
                            ),
                            child: Text(
                              'No tasks available for this station lesson.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.74),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        children: [
                          Text(
                            'CHECKLIST',
                            style: TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...grouped.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: TextStyle(
                                      color: _blue.withOpacity(0.74),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...entry.value.map((task) {
                                    final done = _done.contains(task.id);

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: InkWell(
                                        onTap: () => _toggle(task.id),
                                        borderRadius: BorderRadius.circular(16),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: LuxTheme.panel,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: done
                                                  ? _blue
                                                  : _blue.withOpacity(0.30),
                                              width: done ? 1.4 : 1.0,
                                            ),
                                            boxShadow: done
                                                ? [
                                                    BoxShadow(
                                                      color: _blue
                                                          .withOpacity(0.18),
                                                      blurRadius: 12,
                                                      spreadRadius: 0.5,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                done
                                                    ? Icons.check_circle
                                                    : Icons
                                                        .radio_button_unchecked,
                                                color: _blue,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  task.label,
                                                  style: TextStyle(
                                                    color: done
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withOpacity(0.82),
                                                    height: 1.4,
                                                    fontSize: 14.5,
                                                    fontWeight: done
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
