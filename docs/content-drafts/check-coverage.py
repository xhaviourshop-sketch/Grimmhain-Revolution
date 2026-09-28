#!/usr/bin/env python3
"""Coverage and parity check for the content drafts in docs/content-drafts/.

Reads the role IDs from godot/core/rules/role_catalog.gd (read only) and checks:
  1. every catalog role has exactly one entry in rolebook/*.md (no missing, no duplicate, no unknown);
  2. every entry has all eight table rows with non-empty DE and EN cells;
  3. numerals per row agree between DE and EN;
  4. GUIDE-TEXTS.md has exactly one row per catalog role in each per-role table;
  5. no em dash or en dash, no forbidden internal term in the text of the drafts.
Exit code 0 only if every check passes. Run from the repository root:
  python docs/content-drafts/check-coverage.py
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DRAFTS = ROOT / "docs" / "content-drafts"
CATALOG = ROOT / "godot" / "core" / "rules" / "role_catalog.gd"

ROWS = ["Fähigkeit", "Zeitpunkt, Limit", "Ziele", "Ausnahmen", "Sieg", "Beispiel 1", "Beispiel 2", "Spielleitung"]
FORBIDDEN = ["—", "–", "Lynch", "lynch", "Kartenschlucker-Regel"]
ALLOWED_FORBIDDEN_FILES = {"TERMINOLOGY.md", "OPEN-ISSUES.md", "README.md", "check-coverage.py"}


def catalog_ids():
    text = CATALOG.read_text(encoding="utf8")
    consts = dict(re.findall(r'^const ([A-Z_]+) := &"([a-z\-]+)"', text, re.M))
    block = text[text.index("const ROLES := {"):text.index("static func has_role")]
    keys = re.findall(r"^\t([A-Z_]+): \{", block, re.M)
    return [consts[k] for k in keys]


def parse_rolebook():
    entries = {}
    dupes = []
    problems = []
    for path in sorted((DRAFTS / "rolebook").glob("*.md")):
        text = path.read_text(encoding="utf8")
        parts = re.split(r"^## `([a-z\-]+)` .*$", text, flags=re.M)
        for i in range(1, len(parts), 2):
            rid, body = parts[i], parts[i + 1]
            if rid in entries:
                dupes.append(rid)
            entries[rid] = (path.name, body)
            rows = {}
            for line in body.splitlines():
                m = re.match(r"^\| ([^|]+?) / [^|]+? \| (.*?) \| (.*) \|$", line)
                if m:
                    rows[m.group(1).strip()] = (m.group(2).strip(), m.group(3).strip())
            for name in ROWS:
                if name not in rows:
                    problems.append(f"{rid}: missing row '{name}'")
                    continue
                de, en = rows[name]
                if not de or not en:
                    problems.append(f"{rid}: empty cell in row '{name}'")
                    continue
                nums_de = sorted(re.findall(r"\d+(?:\.\d+)?", de))
                nums_en = sorted(re.findall(r"\d+(?:\.\d+)?", en))
                if nums_de != nums_en:
                    problems.append(f"{rid}: numerals differ in row '{name}': DE {nums_de} EN {nums_en}")
            if "Quelle:" not in body:
                problems.append(f"{rid}: missing 'Quelle:' line")
    return entries, dupes, problems


def guide_ids():
    path = DRAFTS / "GUIDE-TEXTS.md"
    if not path.exists():
        return None
    ids = []
    for line in path.read_text(encoding="utf8").splitlines():
        m = re.match(r"^\| `([a-z\-]+)` \|", line)
        if m:
            ids.append(m.group(1))
    return ids


def main():
    ok = True
    cat = catalog_ids()
    print(f"catalog roles: {len(cat)} (unique {len(set(cat))})")
    entries, dupes, problems = parse_rolebook()
    missing = [r for r in cat if r not in entries]
    unknown = [r for r in entries if r not in cat]
    print(f"rolebook entries: {len(entries)}; missing {missing}; unknown {unknown}; duplicates {dupes}")
    ok &= not (missing or unknown or dupes)
    for p in problems:
        print("PROBLEM", p)
    ok &= not problems
    g = guide_ids()
    if g is None:
        print("GUIDE-TEXTS.md not found yet")
    else:
        from collections import Counter
        counts = Counter(g)
        gm = [r for r in cat if r not in counts]
        gu = [r for r in counts if r not in cat]
        print(f"guide per-role rows: {len(counts)} roles; missing {gm}; unknown {gu}")
        ok &= not (gm or gu)
        # rows appear once per per-role table; every role must appear equally often
        tables = max(counts.values()) if counts else 0
        odd = [r for r, n in counts.items() if n != tables]
        print(f"guide tables per role: {tables}; roles with a different count {odd}")
        ok &= not odd
    for path in sorted(DRAFTS.rglob("*")):
        if path.suffix in (".md",) and path.name not in ALLOWED_FORBIDDEN_FILES:
            text = path.read_text(encoding="utf8")
            for bad in FORBIDDEN:
                if bad in text:
                    print(f"FORBIDDEN '{bad!r}' in {path.relative_to(ROOT)}")
                    ok = False
    if "kartenschlucker" in "".join(entries):
        print("kartenschlucker must not have an entry")
        ok = False
    print("RESULT", "OK" if ok else "FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
