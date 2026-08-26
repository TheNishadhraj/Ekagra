import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/task_model.dart';

/// Spiciness — the granularity slider (WI-3.1, after Goblin Tools'
/// "Magic ToDo"): from "give me the chunks" to "I am fully paralysed,
/// show me 'pick up the sponge'".
enum Spiciness {
  mild,
  medium,
  spicy;

  String get label {
    switch (this) {
      case Spiciness.mild:
        return 'Big steps';
      case Spiciness.medium:
        return 'Normal';
      case Spiciness.spicy:
        return 'Tiny steps';
    }
  }

  /// Step-count bounds, mirrored by template validation in tests so the
  /// data file can never silently drift out of spec.
  (int, int) get bounds {
    switch (this) {
      case Spiciness.mild:
        return (3, 5);
      case Spiciness.medium:
        return (6, 10);
      case Spiciness.spicy:
        return (11, 20);
    }
  }
}

/// One step of a decomposition, with its progress state.
class DecomposedStep {
  const DecomposedStep({required this.title, this.done = false, this.skipped = false});

  final String title;
  final bool done;
  final bool skipped;

  bool get resolved => done || skipped;

  DecomposedStep copyWith({bool? done, bool? skipped}) => DecomposedStep(
        title: title,
        done: done ?? this.done,
        skipped: skipped ?? this.skipped,
      );
}

/// The one-step-at-a-time state machine. The UI shows [currentStep] only;
/// everything else is deliberately out of sight (overwhelm is the enemy).
class DecompositionPlan {
  DecompositionPlan({required this.steps});

  final List<DecomposedStep> steps;

  int resolvedCount => steps.where((s) => s.resolved).length;
  bool get isFinished => steps.isNotEmpty && steps.every((s) => s.resolved);

  /// The next step to face. Null when finished (or empty).
  DecomposedStep? get currentStep {
    for (final s in steps) {
      if (!s.resolved) return s;
    }
    return null;
  }

  int get currentIndex {
    for (var i = 0; i < steps.length; i++) {
      if (!steps[i].resolved) return i;
    }
    return steps.length - 1;
  }
}

/// Local task decomposition — smarter list, not "AI" (WI-3.1).
///
/// Everything happens on-device from a JSON template file the owner can
/// edit without a release. Unknown tasks get the generic 2-minute-rule
/// scaffold. There is no cloud path, no model download, and no UI copy
/// that implies otherwise.
class TaskDecomposer {
  TaskDecomposer._(this._families, this._generic);

  factory TaskDecomposer.fromJson(String jsonText) {
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final generic = _stepsOf(decoded['generic'] as Map<String, dynamic>);
    final families = <String, _Family>{
      for (final f in (decoded['families'] as List<dynamic>))
        (f as Map<String, dynamic>)['id'] as String: _Family.fromJson(f),
    };
    return TaskDecomposer._(families, generic);
  }

  /// Loads the asset, falling back to the built-in generic scaffold if the
  /// asset is missing or unreadable — the feature must never hard-fail.
  static Future<TaskDecomposer> loadDefault() async {
    try {
      final text = await rootBundle.loadString(
        'assets/templates/task_breakdown_templates.json',
      );
      return TaskDecomposer.fromJson(text);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('decomposer: template asset unavailable, using generic ($e)');
      }
      return TaskDecomposer.fallback();
    }
  }

  static TaskDecomposer fallback() => TaskDecomposer._({}, _genericFallback);

  final Map<String, _Family> _families;
  final Map<Spiciness, List<String>> _generic;

  /// Break [title] into steps at [spiciness]. Deterministic: same input,
  /// same steps — this is a tool, not a slot machine.
  List<DecomposedStep> breakdown(String title, Spiciness spiciness) {
    final family = _classify(title);
    final titles = family != null
        ? family.steps[spiciness]!
        : _generic[spiciness]!;
    return titles.map((t) => DecomposedStep(title: t)).toList();
  }

  String? familyIdFor(String title) => _classify(title)?.id;

  _Family? _classify(String title) {
    final lower = title.toLowerCase();
    _Family? best;
    var bestScore = 0;
    for (final family in _families.values) {
      var score = 0;
      for (final kw in family.keywords) {
        if (lower.contains(kw)) score += kw.length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = family;
      }
    }
    return best;
  }

  static Map<Spiciness, List<String>> _stepsOf(Map<String, dynamic> json) {
    return {
      Spiciness.mild:
          (json['mild'] as List<dynamic>).map((e) => e as String).toList(),
      Spiciness.medium:
          (json['medium'] as List<dynamic>).map((e) => e as String).toList(),
      Spiciness.spicy:
          (json['spicy'] as List<dynamic>).map((e) => e as String).toList(),
    };
  }

  /// The 2-minute-rule scaffold used when no family matches.
  static final Map<Spiciness, List<String>> _genericFallback = {
    Spiciness.mild: const [
      'Open what you need',
      "Do the first 2 minutes",
      "Check: done, or what's next?",
    ],
    Spiciness.medium: const [
      'Name the finished thing in one sentence',
      'Open what you need',
      'Do the first 2 minutes',
      'Find the easiest visible piece',
      'Do that piece',
      "Check: done, or what's next?",
    ],
    Spiciness.spicy: const [
      'Put the task on one sticky note',
      'Say the goal out loud',
      'Open what you need',
      'Set a 2-minute timer',
      'Do only what the timer allows',
      'Write down where you stopped',
      'Find the easiest visible piece',
      'Do that piece',
      'Cross it off the note',
      'Set another 2-minute timer',
      'Do the next tiny piece',
      "Check: done, or what's next?",
    ],
  };
}

class _Family {
  _Family({required this.id, required this.keywords, required this.steps});

  factory _Family.fromJson(Map<String, dynamic> json) {
    return _Family(
      id: json['id'] as String,
      keywords: (json['keywords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      steps: TaskDecomposer._stepsOf(json['steps'] as Map<String, dynamic>),
    );
  }

  final String id;
  final List<String> keywords;
  final Map<Spiciness, List<String>> steps;
}
