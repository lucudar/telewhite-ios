#!/usr/bin/env python3
"""Check that every screen of the Telewhite mods menu appends its entries in
ascending stableId order.

ItemListControllerNode asserts on a non-monotonic entry list, and that assert fires
at runtime on a device, an hour of CI after the mistake is made. This reads the two
sources of truth out of the Swift file -- the `stableId` switch and the append order
inside `telewhiteModsEntries` -- and compares them, so the mistake is caught here.

Cases whose stableId is computed from an index (`61 + index`) are checked by their
base value; that is enough to catch a block landing in the wrong range.

Usage: check_mods_order.py <path to TelewhiteModsController.swift>
"""
import io
import re
import sys


def parse_stable_ids(text):
    """case .foo: return 123  ->  {"foo": 123}"""
    body = text[text.index("var stableId: Int32 {"):]
    body = body[:body.index("\n    }\n")]
    ids = {}
    pending = []
    for line in body.splitlines():
        line = line.strip()
        m = re.match(r"case (?:let )?\.(\w+)[^:]*:$", line)
        if m:
            pending.append(m.group(1))
            continue
        m = re.match(r"return (-?\d+)(?:\s*\+\s*index)?$", line)
        if m and pending:
            for name in pending:
                ids[name] = int(m.group(1))
            pending = []
    return ids


def parse_screens(text):
    """case .tab: ... entries.append(.foo(  ->  {"tab": [(name, explicit_id|None), ...]}

    sectionHeader carries its stable id as its first argument, so it is read from the
    call site rather than from the stableId switch.
    """
    body = text[text.index("private func telewhiteModsEntries("):]
    body = body[:body.index("\n    return entries")]
    screens = {}
    current = None
    for line in body.splitlines():
        m = re.match(r"    case \.(\w+):$", line)
        if m:
            current = m.group(1)
            screens[current] = []
            continue
        if current is None:
            continue
        for m in re.finditer(r"entries\.append\(\.(\w+)\((\d+)?", line):
            name, explicit = m.group(1), m.group(2)
            screens[current].append((name, int(explicit) if name == "sectionHeader" and explicit else None))
    return screens


def main():
    text = io.open(sys.argv[1], encoding="utf-8").read()
    ids = parse_stable_ids(text)
    screens = parse_screens(text)
    # Cases whose id is `base + index` repeat their base here; a run of equal values is
    # monotonic by construction, not a defect.
    indexed = set(re.findall(r"case let \.(\w+)\([^)]*\):\s*\n\s*return -?\d+\s*\+\s*index", text))

    problems = 0
    for screen, items in screens.items():
        seq = [(name, explicit if explicit is not None else ids.get(name)) for name, explicit in items]
        unknown = [n for n, v in seq if v is None]
        bad = []
        for (n1, v1), (n2, v2) in zip(seq, seq[1:]):
            if v1 is None or v2 is None:
                continue
            if v1 > v2 or (v1 == v2 and n1 not in indexed):
                bad.append((n1, v1, n2, v2))
        ok = not bad and not unknown
        if not ok:
            problems += 1
        print("%s %-22s %s" % ("OK " if ok else "BAD", screen, [v for _, v in seq]))
        if unknown:
            print("      stableId not found for: %s" % ", ".join(unknown))
        for n1, v1, n2, v2 in bad:
            print("      out of order: %s (%s) -> %s (%s)" % (n1, v1, n2, v2))

    print()
    print("screens: %d, with problems: %d" % (len(screens), problems))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
