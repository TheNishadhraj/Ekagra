import 'dart:io';

import 'package:ekagra/utils/rsd_safe_copy.dart';
import 'package:flutter_test/flutter_test.dart';

/// Files that legitimately DEFINE the forbidden vocabulary and must not be
/// scanned as user-facing copy.
const vocabularyDefinitionFiles = {'design_rules.dart', 'rsd_safe_copy.dart'};

/// Documented, intentional exceptions to Rule 15 — lines that contain forbidden
/// root words in non-shaming contexts (e.g. counter-shame encouragement or technical terms).
const documentedExceptions = <String>{
  "You're not lazy. You're running a different operating system.":
      'counter-shame encouragement ("not lazy")',
  '🔨 Task broken down into small micro-steps!':
      "technical phrase 'broken down' — not shaming",
};

/// Extracts the contents of every quoted string literal in [src], skipping
/// comments, honoring escapes, and normalizing backslash escapes.
List<String> extractStringLiterals(String src) {
  final out = <String>[];
  final buf = StringBuffer();
  var i = 0;
  final n = src.length;

  while (i < n) {
    final c = src[i];

    // Skip line comments
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }

    // Skip block comments
    if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      i += 2;
      while (i < n && !(src[i] == '*' && i + 1 < n && src[i + 1] == '/')) {
        i++;
      }
      i = (i + 2).clamp(0, n);
      continue;
    }

    // Extract single and double quoted string literals
    if (c == '\'' || c == '"') {
      final quote = c;
      i++;
      buf.clear();
      var closed = false;

      while (i < n) {
        final s = src[i];
        if (s == '\\' && i + 1 < n) {
          buf.write(s);
          buf.write(src[i + 1]);
          i += 2;
          continue;
        }
        if (s == quote) {
          closed = true;
          i++;
          break;
        }
        if (s == '\n') {
          break;
        }
        buf.write(s);
        i++;
      }

      if (closed) {
        final content = buf.toString().replaceAll('\\', '');
        if (content.trim().isNotEmpty) {
          out.add(content);
        }
      }
      continue;
    }
    i++;
  }
  return out;
}

void main() {
  group('Rule 15 — no shame in any copy', () {
    test('every user-facing string literal in lib/ passes the RSD audit', () {
      final lib = Directory('lib');
      final violations = <String>[];

      for (final entity in lib.listSync(recursive: true)) {        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final name = entity.uri.pathSegments.last;
        if (vocabularyDefinitionFiles.contains(name)) continue;

        final src = entity.readAsStringSync();
        for (final literal in extractStringLiterals(src)) {
          if (RsdSafeCopy.isSafe(literal)) continue;
          final reason = documentedExceptions[literal];
          if (reason != null) continue;

          violations.add('${entity.path}: "$literal"');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Rule 15 violated in user-facing copy. Fix the string or document it if intentional:\n${violations.join('\n')}',
      );
    });
  });
}
