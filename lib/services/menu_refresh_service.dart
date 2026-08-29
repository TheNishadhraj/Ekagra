import '../models/dopamine_menu_model.dart';

/// WI-5.3 — monthly dopamine-menu refresh suggestions.
///
/// Novelty decay is the documented failure mode ("lost its self-care
/// novelty after the first month" — Finch reviews). The fix is not more
/// features: it is "new toys, same box" — 3 reward suggestions the user
/// does not already have, rotated monthly, one tap to add.
///
/// Pure and deterministic: same menu + same month → same suggestions.
/// No persistence of its own; the user's saved menu is the state.
class MenuRefreshService {
  MenuRefreshService._();

  /// Emoji-prefixed selection strings look like '🍫 Eat a snack'; the
  /// comparison key is the text without the emoji.
  static String _bare(String selection) =>
      selection.replaceFirst(RegExp(r'^\S+\s+'), '').trim().toLowerCase();

  static List<DopamineItem> suggestionsFor(
    Set<String> currentSelections,
    int year,
    int month, {
    int count = 3,
  }) {
    final pool = <DopamineItem>[
      ...DopamineMenuDefaults.pool['quick']!,
      ...DopamineMenuDefaults.pool['medium']!,
      ...DopamineMenuDefaults.pool['big']!,
    ];
    final have =
        currentSelections.map(_bare).where((s) => s.isNotEmpty).toSet();
    final fresh = pool
        .where((item) => !have.contains(item.text.toLowerCase()))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id)); // stable order before rotation
    if (fresh.isEmpty) return const [];

    // Rotate by month key so the same three are not suggested forever.
    final monthKey = year * 12 + (month - 1);
    final start = monthKey % fresh.length;
    final rotated = [...fresh.skip(start), ...fresh.take(start)];
    return rotated.take(count).toList(growable: false);
  }
}
