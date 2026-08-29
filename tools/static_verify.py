#!/usr/bin/env python3
"""Static verifier for the Ekagra Flutter repo.

WHY THIS EXISTS
---------------
The authoring environment for the 2026-08-25 gap-solutions work order had no
Dart toolchain and no pub.dev egress, so `flutter analyze` / `flutter test`
could not be executed there. This script re-implements, in Python, the checks
that CI runs for real once the workflow file is active:

  1. Delimiter balance with a real Dart mini-lexer (strings, raw strings,
     triple-quoted strings, ${} interpolation nesting, comments).
  2. Relative + package import resolution against the file system and
     pubspec.yaml dependencies.
  3. Rule 3 red-colour grep (same pattern as the CI job).
  4. print() grep (same pattern as the CI job).
  5. Shame-free copy scan over user-facing strings, mirroring the extractor
     in test/design_rules_test.dart.
  6. "AI"-claim scan while the selection engine is not a model.
  7. Formatter-adjacent hygiene: no tabs, no trailing whitespace.

This is NOT a substitute for running the real suite — see
docs/Engineering_Assessment.md §6. It is the same static-verification
approach the repo previously documented, kept in-tree so the next agent can
re-run it before CI exists on a branch.
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LIB = REPO / "lib"

FAILURES = []


def fail(msg: str) -> None:
    FAILURES.append(msg)
    print(f"  FAIL {msg}")


# ── 1. Dart mini-lexer ──────────────────────────────────────────────────────

class DartLexer:
    """Strips comments and yields code spans, tracking string boundaries."""

    def __init__(self, src: str):
        self.src = src
        self.n = len(src)
        self.i = 0
        self.line = 1

    def strip_comments(self) -> tuple[str, list[tuple[int, int, int, int]]]:
        """Returns (code_with_comments_blanked, [(line, col_start, col_end)] comment spans)."""
        out = []
        spans = []
        while self.i < self.n:
            c = self.src[self.i]
            if c == "\n":
                self.line += 1
                out.append(c)
                self.i += 1
            elif self.src.startswith("//", self.i):
                start_col = len(out)
                while self.i < self.n and self.src[self.i] != "\n":
                    out.append(" ")
                    self.i += 1
                spans.append((self.line, start_col, len(out)))
            elif self.src.startswith("/*", self.i):
                start_line = self.line
                start_col = len(out)
                out.append(" ")
                out.append(" ")
                self.i += 2
                while self.i < self.n and not self.src.startswith("*/", self.i):
                    if self.src[self.i] == "\n":
                        self.line += 1
                        out.append("\n")
                    else:
                        out.append(" ")
                    self.i += 1
                if self.i < self.n:
                    out.append(" ")
                    out.append(" ")
                    self.i += 2
                spans.append((start_line, start_col, len(out)))
            elif c in "'\"" or self._raw_string_at():
                s = self._scan_string()
                out.append(s)
            else:
                out.append(c)
                self.i += 1
        return "".join(out), spans

    def _raw_string_at(self) -> bool:
        # r'...' / r"..." — identifier 'r' immediately before a quote.
        if self.src[self.i] != "r":
            return False
        if self.i + 1 < self.n and self.src[self.i + 1] in "'\"":
            return True
        return False

    def _scan_string(self) -> str:
        """Consume a string literal (raw or normal, triple or single),
        returning blanks of the same length so positions stay stable.
        Interpolations ${...} may contain nested strings; recursion handles
        them. Raises on unterminated strings."""
        start_line = self.line
        j = self.i
        raw = False
        if self.src[j] == "r" and self.src[j + 1] in "'\"":
            raw = True
            j += 1
        q = self.src[j]
        triple = self.src.startswith(q * 3, j)
        terminator = q * 3 if triple else q
        j += len(terminator)
        buf = []
        buf_len = self.i  # prefix length consumed so far
        while j < self.n:
            if self.src.startswith(terminator, j):
                j += len(terminator)
                total = j - self.i
                self.i = j
                # Newlines inside triple strings still advance line count.
                return " " * total
            ch = self.src[j]
            if ch == "\n":
                self.line += 1
                if not triple:
                    raise SyntaxError(
                        f"unterminated string starting line {start_line}")
                j += 1
                continue
            if not raw and ch == "\\":
                j += 2
                continue
            if ch == "$" and j + 1 < self.n and self.src[j + 1] == "{":
                # Interpolation: consume as code until matching brace,
                # allowing nested strings.
                depth = 0
                j += 2
                while j < self.n:
                    ch2 = self.src[j]
                    if ch2 == "{":
                        depth += 1
                        j += 1
                    elif ch2 == "}":
                        if depth == 0:
                            j += 1
                            break
                        depth -= 1
                        j += 1
                    elif ch2 in "'\"" :
                        # Nested string — reuse the scanner on a sub-lexer.
                        sub = DartLexer(self.src)
                        sub.i = j
                        sub.line = self.line
                        sub._scan_string()
                        j = sub.i
                        self.line = sub.line
                    elif ch2 == "\n":
                        self.line += 1
                        j += 1
                    else:
                        j += 1
                else:
                    raise SyntaxError(
                        f"unterminated interpolation starting line {start_line}")
                continue
            j += 1
        raise SyntaxError(f"unterminated string starting line {start_line}")


def check_balance(path: Path) -> None:
    src = path.read_text(encoding="utf-8")
    lexer = DartLexer(src)
    try:
        code, _spans = lexer.strip_comments()
    except SyntaxError as e:
        fail(f"{path.relative_to(REPO)}: {e}")
        return
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for idx, ch in enumerate(code):
        if ch in "([{":
            stack.append((ch, idx))
        elif ch in ")]}":
            if not stack or stack[-1][0] != pairs[ch]:
                line = code.count("\n", 0, idx) + 1
                fail(f"{path.relative_to(REPO)}:{line}: unbalanced '{ch}'")
                return
            stack.pop()
    if stack:
        ch, idx = stack[-1]
        line = code.count("\n", 0, idx) + 1
        fail(f"{path.relative_to(REPO)}:{line}: unclosed '{ch}'")


# ── 2. Import resolution ────────────────────────────────────────────────────

def pubspec_packages() -> set[str]:
    text = (REPO / "pubspec.yaml").read_text(encoding="utf-8")
    deps = set()
    section = None
    for line in text.splitlines():
        if re.match(r"^dependencies:\s*$", line):
            section = "deps"
            continue
        if re.match(r"^dev_dependencies:\s*$", line):
            section = "dev"
            continue
        if re.match(r"^\S", line):
            section = None
            continue
        m = re.match(r"^\s+([A-Za-z0-9_]+):\s*(.*)$", line)
        if m and section in ("deps", "dev"):
            deps.add(m.group(1))
    return deps


def check_imports(path: Path, packages: set[str]) -> None:
    src = path.read_text(encoding="utf-8")
    lexer = DartLexer(src)
    code, _ = lexer.strip_comments()
    for m in re.finditer(
            r"(?:^|\n)\s*(?:import|export)\s+(['\"])([^'\"]+)\1", code):
        target = m.group(2)
        if target.startswith("dart:"):
            continue
        if target.startswith("package:"):
            pkg, _, rest = target[len("package:"):].partition("/")
            if pkg == "ekagra":
                if not (LIB / rest).is_file() and not (LIB / rest).is_dir():
                    fail(f"{path.relative_to(REPO)}: missing package target {target}")
            elif pkg not in packages:
                fail(f"{path.relative_to(REPO)}: package '{pkg}' not in pubspec ({target})")
            continue
        # Relative import.
        resolved = (path.parent / target).resolve()
        if not resolved.is_file():
            fail(f"{path.relative_to(REPO)}: missing relative target {target}")


# ── 3–6. Content checks (mirror CI + design_rules_test) ────────────────────

RED_RE = re.compile(r"Colors\.red|0xFFFF0000")
PRINT_RE = re.compile(r"^\s*print\(", re.MULTILINE)

# Mirrors RsdSafeCopy._forbidden + DesignRules constants.
FORBIDDEN = [
    "streak", "overdue", "failed", "missed", "lazy", "failure", "broken",
    "behind", "should have", "why didn't you", "you broke", "start over",
    "incomplete", "pending",
]
AI_RE = re.compile(r"\bA\.?I\.?\b|artificial intelligence|GPT", re.IGNORECASE)

# Mirrors the extractor in test/design_rules_test.dart.
EXTRACT_RE = re.compile(
    r"""(?:Text|Text\.rich|SnackBar\(\s*content:\s*Text|label|title|subtitle|"""
    r"""hintText|semanticLabel)\s*[:(]\s*(?:const\s+)?['"]""")


def user_facing_strings(code: str, path: Path) -> list[str]:
    out = []
    for m in EXTRACT_RE.finditer(code):
        start = m.end() - 1
        quote = code[start]
        buf = []
        i = start + 1
        while i < len(code):
            ch = code[i]
            if ch == "\\":
                i += 2
                continue
            if ch == quote or ch == "\n":
                break
            buf.append(ch)
            i += 1
        text = "".join(buf).strip()
        if len(text) > 2:
            out.append(text)
    return out


def check_content(path: Path, is_ui_file: bool) -> None:
    rel = path.relative_to(REPO)
    src = path.read_text(encoding="utf-8")
    if RED_RE.search(src):
        fail(f"{rel}: Rule 3 — red colour reference")
    if PRINT_RE.search(src):
        fail(f"{rel}: stray print() call")
    if "\t" in src:
        fail(f"{rel}: tab character (formatter uses spaces)")
    for line_no, line in enumerate(src.splitlines(), 1):
        if line != line.rstrip():
            fail(f"{rel}:{line_no}: trailing whitespace")
    if is_ui_file:
        lexer = DartLexer(src)
        code, _ = lexer.strip_comments()
        name = path.name
        if name in ("rsd_safe_copy.dart", "design_rules.dart"):
            return
        for text in user_facing_strings(code, path):
            low = text.lower()
            for word in FORBIDDEN:
                if word in low:
                    fail(f"{rel}: forbidden word '{word}' in \"{text}\"")
                    break
            if AI_RE.search(text):
                fail(f"{rel}: unsupported model claim in \"{text}\"")


def main() -> int:
    dart_files = sorted(
        p for p in (REPO / "lib").rglob("*.dart"))
    dart_files += sorted(p for p in (REPO / "test").rglob("*.dart"))
    print(f"Checking {len(dart_files)} Dart files…")

    packages = pubspec_packages()
    for path in dart_files:
        check_balance(path)
        check_imports(path, packages)

    lib_files = sorted((REPO / "lib").rglob("*.dart"))
    for path in lib_files:
        rel_str = path.relative_to(REPO).as_posix()
        is_ui = ("/screens/" in rel_str or "/widgets/" in rel_str
                 or "/utils/" in rel_str or "/config/constants" in rel_str)
        check_content(path, is_ui)

    # pubspec asset folders must exist
    text = (REPO / "pubspec.yaml").read_text(encoding="utf-8")
    for m in re.finditer(r"^\s+-\s+(assets/[^\s#]+)", text, re.MULTILINE):
        asset = REPO / m.group(1)
        if not asset.exists():
            fail(f"pubspec asset path missing on disk: {m.group(1)}")

    print()
    if FAILURES:
        print(f"✗ {len(FAILURES)} static verification failure(s)")
        return 1
    print("✓ static verification clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
