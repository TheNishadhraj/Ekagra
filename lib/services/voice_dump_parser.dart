import '../config/constants.dart';
import '../models/task_model.dart';

/// Transcript-to-tasks parser ("yap mode" core, WI-2.1).
///
/// This is the brain of voice capture, built and shipped independently of
/// the microphone: it turns one long unstructured stream — spoken or
/// typed — into confirmable task cards with dates. Runs 100% on-device,
/// no network, nothing to send anywhere ("Your words never leave this
/// phone" is a structural claim, not a promise).
///
/// Grammar understood (deliberately tiny and forgiving):
/// - fragment splits: newlines, "and then", "also", "oh and", "plus",
///   "then", semicolons
/// - fillers dropped: "um", "uh", "like", "hmm"
/// - dates: today, tonight, tomorrow, this week, next week, "by Friday",
///   "on Thursday", weekday names, "someday"
/// - template matching maps fragments to the quick-add canon in
///   EkagraConstants.commonTaskTemplates when they clearly mean one.
class VoiceDumpParser {
  List<ParsedFragment> parse(String transcript, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final fragments = _split(transcript);
    final out = <ParsedFragment>[];

    for (final raw in fragments) {
      var text = _stripFillers(raw);
      if (!_isRealThought(text)) continue;

      final date = _extractDate(text, today);
      text = date?.cleanedTitle ?? text;
      text = _tidy(text);
      if (!_isRealThought(text)) continue;

      out.add(
        ParsedFragment(
          title: text,
          schedule: date?.schedule ?? TaskScheduleType.anytime,
          deadline: date?.deadline,
          matchedTemplate: _matchTemplate(text),
        ),
      );
    }
    return out;
  }

  // ── Splitting ─────────────────────────────────────────────────────────────

  static const _splitPattern =
      r'\n+|(?:\s+and\s+then\s+)|(?:\s+oh\s+and\s+)|(?:\s+and\s+also\s+)'
      r'|(?:\s+also\s+)|(?:\s+plus\s+)|(?:,\s*then\s+)|(?:;\s*)|(?:,\s+)'
      r'|(?:\s+and\s+)';

  List<String> _split(String transcript) {
    if (transcript.trim().isEmpty) return const [];
    return transcript
        .replaceAll(RegExp(_splitPattern, caseSensitive: false), '\u0001')
        .split('\u0001')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ── Filler stripping ──────────────────────────────────────────────────────

  static const _fillers = {'um', 'uh', 'hmm', 'er', 'ah', 'like'};

  String _stripFillers(String text) {
    final words = text.split(RegExp(r'\s+'));
    final kept = words.where((w) => !_fillers.contains(_word(w)));
    return kept.join(' ');
  }

  String _word(String w) => w
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _isRealThought(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.length < 2) return false;
    // A lone "ok", "tv" or "hmm hm" is an acknowledgement, not a thought.
    // Keep anything with a real word (>=3 letters) or a digit in it.
    final words = text.split(RegExp(r'[^A-Za-z0-9]+'))..removeWhere((w) => w.isEmpty);
    return words.any((w) => w.length >= 3 || RegExp(r'\d').hasMatch(w));
  }

  // ── Date extraction ───────────────────────────────────────────────────────

  static const _weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  _DateSpec? _extractDate(String text, DateTime today) {
    final lower = text.toLowerCase();

    if (_containsWord(lower, 'someday')) {
      return _DateSpec(
        schedule: TaskScheduleType.someday,
        deadline: null,
        cleanedTitle: _removePhrase(text, 'someday'),
      );
    }
    if (_containsWord(lower, 'tonight')) {
      return _DateSpec(
        schedule: TaskScheduleType.today,
        deadline: _endOfDay(today),
        cleanedTitle: _removePhrase(text, 'tonight'),
      );
    }
    if (_containsWord(lower, 'today')) {
      return _DateSpec(
        schedule: TaskScheduleType.today,
        deadline: _endOfDay(today),
        cleanedTitle: _removePhrase(text, 'today'),
      );
    }
    if (_containsWord(lower, 'tomorrow')) {
      final when = today.add(const Duration(days: 1));
      return _DateSpec(
        schedule: TaskScheduleType.today,
        deadline: _endOfDay(when),
        cleanedTitle: _removePhrase(text, 'tomorrow'),
      );
    }
    if (lower.contains('next week')) {
      return _DateSpec(
        schedule: TaskScheduleType.thisWeek,
        deadline: _endOfDay(today.add(const Duration(days: 7))),
        cleanedTitle: _removePhrase(text, 'next week'),
      );
    }
    if (lower.contains('this week')) {
      return _DateSpec(
        schedule: TaskScheduleType.thisWeek,
        deadline: _endOfDay(today.add(const Duration(days: 7))),
        cleanedTitle: _removePhrase(text, 'this week'),
      );
    }

    // "by Friday" / "on Thursday" / bare weekday.
    for (var i = 0; i < _weekdays.length; i++) {
      final day = _weekdays[i];
      final by = RegExp('\\bby\\s+$day\\b');
      final on = RegExp('\\bon\\s+$day\\b');
      if (by.hasMatch(lower)) {
        var title = text.replaceAll(RegExp(by.pattern, caseSensitive: false), '');
        title = _removeLeadingJunk(title);
        return _DateSpec(
          schedule: TaskScheduleType.today,
          deadline: _endOfDay(_nextOccurrence(i, today)),
          cleanedTitle: title,
        );
      }
      if (on.hasMatch(lower)) {
        var title = text.replaceAll(RegExp(on.pattern, caseSensitive: false), '');
        title = _removeLeadingJunk(title);
        return _DateSpec(
          schedule: TaskScheduleType.today,
          deadline: _endOfDay(_nextOccurrence(i, today)),
          cleanedTitle: title,
        );
      }
    }
    return null;
  }

  DateTime _nextOccurrence(int targetWeekday, DateTime today) {
    final ahead = (targetWeekday - today.weekday + 7) % 7;
    return today.add(Duration(days: ahead));
  }

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  bool _containsWord(String lower, String word) =>
      RegExp('\\b$word\\b').hasMatch(lower);

  String _removePhrase(String text, String phrase) =>
      _removeLeadingJunk(text.replaceAll(RegExp('\\b$phrase\\b', caseSensitive: false), ''));

  String _removeLeadingJunk(String text) =>
      text.replaceFirst(RegExp(r'^[\s,.\-–—:]+'), '').trim();

  // ── Template matching ─────────────────────────────────────────────────────

  static const Map<String, String> _templateKeywords = {
    'email': 'Reply to emails',
    'mail': 'Reply to emails',
    'inbox': 'Reply to emails',
    'water': 'Drink water',
    'hydrate': 'Drink water',
    'med': 'Take medication',
    'meds': 'Take medication',
    'prescription': 'Take medication',
    'tidy': 'Quick tidy (10 min)',
    'clean': 'Quick tidy (10 min)',
    'call': 'Call someone',
    'phone': 'Call someone',
    'ring': 'Call someone',
    'groceries': 'Groceries',
    'grocery': 'Groceries',
    'shopping': 'Groceries',
    'bill': 'Pay a bill',
    'pay': 'Pay a bill',
    'rent': 'Pay a bill',
    'walk': 'Move body',
    'gym': 'Move body',
    'exercise': 'Move body',
    'stretch': 'Move body',
    'prep': 'Prep tomorrow',
    'rest': 'Brain rest',
    'break': 'Brain rest',
  };

  String? _matchTemplate(String title) {
    final lower = title.toLowerCase();
    for (final entry in _templateKeywords.entries) {
      // Plural-tolerant whole-word match ("emails" -> "email").
      if (RegExp('\\b${entry.key}s?\\b').hasMatch(lower)) {
        final canonical = entry.value;
        if (EkagraConstants.commonTaskTemplates.contains(canonical)) {
          return canonical;
        }
      }
    }
    return null;
  }

  // ── Tidying ───────────────────────────────────────────────────────────────

  String _tidy(String text) {
    var t = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    t = t.replaceAll(RegExp(r'[,;:\-–—]+$'), '').trim();
    if (t.isNotEmpty) {
      t = t[0].toUpperCase() + t.substring(1);
    }
    return t;
  }
}

class ParsedFragment {
  const ParsedFragment({
    required this.title,
    required this.schedule,
    this.deadline,
    this.matchedTemplate,
  });

  final String title;
  final TaskScheduleType schedule;
  final DateTime? deadline;

  /// Canonical quick-add template this fragment clearly means, if any.
  /// The UI may offer it as a one-tap alternative — never a replacement.
  final String? matchedTemplate;
}

class _DateSpec {
  const _DateSpec({
    required this.schedule,
    required this.deadline,
    required this.cleanedTitle,
  });

  final TaskScheduleType schedule;
  final DateTime? deadline;
  final String cleanedTitle;
}
