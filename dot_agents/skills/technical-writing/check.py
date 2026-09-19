#!/usr/bin/env python3
"""Deterministic pre-pass for the writing skill, POS-aware via spaCy.

Flags: unapproved STE words (matched by lemma AND part of speech), em dashes,
emojis, sentences over 20 words, a mean sentence length over 15, three or more
commas in a sentence, and two clauses joined by a comma plus so, which, but, or and. Code fences, inline code, table rows, and
single-line quotations are ignored (quoted text is someone else's wording).
Regions between <!-- writing: off --> and <!-- writing: on --> are exempt, for
canonical text that must not be edited. Exemptions are budgeted: every exempt
region is reported, more than two per file is a finding, unclosed is a finding.
Usage: python check.py <file>   or   type text | python check.py
Exit code 1 when anything is flagged, 0 when clean.
"""

import json
import re
import sys
from bisect import bisect
from pathlib import Path

import spacy

HERE = Path(__file__).parent
SENTENCE_MAX = 20  # ceiling per sentence
SENTENCE_MEAN_MAX = 15  # flag a file whose mean sentence length passes this; aim for 12 to 14

POS_MAP = {
    "n": {"NOUN", "PROPN"},
    "v": {"VERB", "AUX"},
    "adj": {"ADJ"},
    "adv": {"ADV"},
    "prep": {"ADP"},
    "conj": {"CCONJ", "SCONJ"},
    "art": {"DET"},
    "pron": {"PRON"},
    "num": {"NUM"},
    "interj": {"INTJ"},
}

PARENS = re.compile(r"\(([^()]*)\)")
QUALIFIER = re.compile(r"^[a-z][a-z &,]*$")


def strip_code(text):
    """Blank out fenced blocks, inline code, table rows, blockquotes, and
    single-line quotations, preserving lines.

    Blockquotes go for the same reason as quotations: a `>` line holds
    someone else's wording, or structured metadata, and neither is prose
    this checker governs. Without this, a wiki article's `> Sources:` and
    `> Raw:` citation lines parse as one enormous sentence and bury the
    real findings.
    """
    text = re.sub(r"```.*?```", lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)
    text = re.sub(r"`[^`]*`", lambda m: " " * len(m.group(0)), text)
    # [ \t]* not \s*: in multiline mode \s* eats the newline of the blank line
    # above a table or quote block, shifting every reported line number.
    text = re.sub(r"(?m)^[ \t]*\|.*$", "", text)
    text = re.sub(r"(?m)^[ \t]*>.*$", "", text)
    for quote in (r'"[^"\n]{1,300}"', r"“[^”\n]{1,300}”"):
        text = re.sub(quote, lambda m: " " * len(m.group(0)), text)
    return text


PRAGMA_OFF = re.compile(r"<!--\s*writing:\s*off\b[^>]*-->")
PRAGMA_ON = re.compile(r"<!--\s*writing:\s*on\b[^>]*-->")
PRAGMA_BUDGET = 2


def apply_pragmas(text):
    """Blank regions between writing:off/on pragmas, preserving lines.

    Returns (text, block_count, findings). The budget rules live here: over
    PRAGMA_BUDGET regions per file flags, and an unclosed off-pragma flags.
    """
    events = sorted(
        [(m.start(), m.end(), "off") for m in PRAGMA_OFF.finditer(text)]
        + [(m.start(), m.end(), "on") for m in PRAGMA_ON.finditer(text)]
    )
    out, pos, blocks, findings, open_at = [], 0, 0, [], None
    for start, end, kind in events:
        if kind == "off" and open_at is None:
            out.append(text[pos:start])
            open_at, pos = start, start
        elif kind == "on" and open_at is not None:
            out.append(re.sub(r"[^\n]", " ", text[pos:end]))
            pos, blocks, open_at = end, blocks + 1, None
    if open_at is not None:
        out.append(re.sub(r"[^\n]", " ", text[pos:]))
        pos, blocks = len(text), blocks + 1
        line = text.count("\n", 0, open_at) + 1
        findings.append((line, "unclosed writing:off pragma (exempts to end of file)"))
    out.append(text[pos:])
    if blocks > PRAGMA_BUDGET:
        findings.append((1, f"{blocks} exemption regions (budget is {PRAGMA_BUDGET} per file)"))
    return "".join(out), blocks, findings


def load_glossary():
    """Skill-level glossary plus an optional project-level one in the cwd."""
    phrases = []
    for path in (HERE / "technical-nouns.txt", Path.cwd() / "technical-nouns.txt"):
        if path.exists():
            phrases += [
                line.strip()
                for line in path.read_text(encoding="utf-8").splitlines()
                if line.strip() and not line.startswith("#")
            ]
    return phrases


def load_entries(include_dict):
    """Yield (phrase, key, suggestion, pos_classes). phrase of one word = POS-checked.

    include_dict: also load the full dictionary (--ste). Default mode uses only
    the curated substitution table: the anti-slop core.
    """
    entries = []
    if include_dict:
        dict_path = HERE / "dictionary.json"
        if dict_path.exists():
            data = json.loads(dict_path.read_text(encoding="utf-8"))
            for key, val in data.get("unapproved", {}).items():
                groups = PARENS.findall(key)
                pos = groups[-1] if groups else ""
                head = PARENS.sub("", key).strip()
                if len(groups) >= 2 and QUALIFIER.match(groups[-1]) and QUALIFIER.match(groups[-2]):
                    # little (a little) (adj) -> "a little"; provided (that) (conj) -> "provided that"
                    if head.lower() in groups[-2].lower():
                        phrase, pos_classes = groups[-2], None
                    else:
                        phrase, pos_classes = f"{head} {groups[-2]}", None
                elif " " in head:
                    phrase, pos_classes = head, None
                else:
                    phrase = head
                    pos_classes = set()
                    for p in pos.split("&"):
                        pos_classes |= POS_MAP.get(p.strip(), set())
                use = val.get("use", [])
                suggestion = " | ".join(use) if isinstance(use, list) else str(use)
                if not suggestion:
                    suggestion = val.get("note") or "no approved alternative"
                entries.append((phrase.lower(), key, suggestion, pos_classes))

    seen = {e[0] for e in entries}
    ste = (HERE / "ste100.md").read_text(encoding="utf-8").splitlines()
    start = next((i for i, l in enumerate(ste) if l.startswith("## Substitution table")), -1)
    if start != -1:
        for line in ste[start + 1 :]:
            if line.startswith("## "):
                break
            m = re.match(r"^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$", line)
            if not m or m.group(1).strip("- ") == "" or "unapproved" in m.group(1).lower():
                continue
            bad, good = m.group(1).strip(), m.group(2).strip()
            if bad.lower() not in seen:
                entries.append((bad.lower(), bad, good, None))
    # Longest phrases first so they claim their spans before component words.
    entries.sort(key=lambda e: -len(e[0]))
    return entries


def spans_for(text, phrase):
    return [(m.start(), m.end()) for m in re.finditer(rf"\b{re.escape(phrase)}\b", text, re.I)]


def markdown_lines(text):
    """One clean line per markdown line: structure markers stripped, and a
    terminator appended where the line lacks one. Keeps line numbers stable."""
    out = []
    for line in text.split("\n"):
        s = re.sub(r"^\s*#{1,6}\s*", "", line)  # heading hashes
        s = re.sub(r"^\s*([-*+]|\d+\.)\s+", "", s)  # list markers
        s = re.sub(r"^\s*>\s?", "", s)  # blockquote
        s = s.rstrip()
        if s and not s.endswith((".", "!", "?")):
            s += "."
        out.append(s)
    return "\n".join(out)


def main():
    unknown_mode = "--unknown" in sys.argv
    ste_mode = "--ste" in sys.argv
    path_arg = next((a for a in sys.argv[1:] if not a.startswith("--")), None)
    raw = Path(path_arg).read_text(encoding="utf-8") if path_arg else sys.stdin.read()
    raw, exempt_blocks, pragma_findings = apply_pragmas(raw)
    text = strip_code(raw)
    text = markdown_lines(text)
    line_starts = [m.start() for m in re.finditer(r"^", text, re.M)] or [0]
    line_of = lambda idx: bisect(line_starts, idx)

    findings = []  # (line, message)
    claimed = []

    def overlaps(start, end):
        return any(start < ce and end > cs for cs, ce in claimed)

    for phrase in load_glossary():
        for start, end in spans_for(text, phrase):
            claimed.append((start, end))  # technical nouns never flag

    entries = load_entries(ste_mode)
    nlp = spacy.load("en_core_web_sm", disable=["ner"])

    # Phrase entries first (regex on text); single words afterwards (POS-checked).
    single = []
    for phrase, key, suggestion, pos_classes in entries:
        if " " in phrase or pos_classes is None:
            for start, end in spans_for(text, phrase):
                if not overlaps(start, end):
                    claimed.append((start, end))
                    findings.append((line_of(start), f'unapproved "{key}" -> use "{suggestion}"'))
        else:
            single.append((phrase, key, suggestion, pos_classes))

    by_word = {}
    for phrase, key, suggestion, pos_classes in single:
        by_word.setdefault(phrase, []).append((key, suggestion, pos_classes))

    doc = nlp(text)
    line_docs = list(nlp.pipe(text.split("\n")))
    for token in doc:
        word = token.lemma_.lower()
        for key, suggestion, pos_classes in by_word.get(word, by_word.get(token.lower_, [])):
            if token.pos_ in pos_classes and not overlaps(token.idx, token.idx + len(token.text)):
                claimed.append((token.idx, token.idx + len(token.text)))
                findings.append((line_of(token.idx), f'unapproved "{key}" -> use "{suggestion}"'))
                break  # one flag per occurrence

    for m in re.finditer("—", text):
        findings.append((line_of(m.start()), "em dash (unslop rule 13: new sentence or comma, never a colon or parentheses)"))
    for i, ch in enumerate(text):
        o = ord(ch)
        if 0x1F000 <= o <= 0x1FAFF or 0x2600 <= o <= 0x27BF or o == 0xFE0F:
            findings.append((line_of(i), "emoji (house rule)"))
    JOINERS = {"so", "which", "but"}
    lengths = []
    for i, line_doc in enumerate(line_docs):
        for sent in line_doc.sents:
            words = [t for t in sent if not t.is_punct]
            if len(words) < 3:
                continue
            lengths.append(len(words))
            if len(words) > SENTENCE_MAX:
                findings.append((i + 1, f"{len(words)}-word sentence (max {SENTENCE_MAX}, aim for 12 to 14)"))
            commas = [t for t in sent if t.text == ","]
            verdict = words and words[0].lower_ in ("good", "bad", "neutral")
            if len(commas) - (1 if verdict else 0) >= 4:
                findings.append((i + 1, f"{len(commas)} commas in one sentence (one clause per sentence)"))
            toks = list(sent)
            verb_seen = False
            for k, t in enumerate(toks):
                if t.pos_ in ("VERB", "AUX"):
                    verb_seen = True
                if t.text != "," or k + 1 >= len(toks):
                    continue
                nxt = toks[k + 1].lower_
                if nxt in JOINERS:
                    findings.append((i + 1, f'clause joined with ", {nxt}" (end the sentence, start the next with the reason)'))
                elif nxt == "and" and verb_seen and k + 2 < len(toks) and toks[k + 2].pos_ in ("PRON", "DET", "PROPN", "NOUN"):
                    after = toks[k + 2 : k + 7]
                    if any(a.pos_ in ("VERB", "AUX") and a.dep_ in ("conj", "ROOT", "ccomp") for a in after):
                        findings.append((i + 1, 'two clauses joined with ", and" (one clause per sentence)'))
    mean_len = round(sum(lengths) / len(lengths), 1) if lengths else 0
    if lengths and mean_len > SENTENCE_MEAN_MAX:
        findings.append((1, f"mean sentence length {mean_len} words over {len(lengths)} sentences (target 12 to 14)"))

    findings.extend(pragma_findings)
    findings.sort()
    for line, message in findings:
        print(f"line {line}: {message}")
    if exempt_blocks:
        print(f"note: {exempt_blocks} region(s) exempted by writing:off pragma")

    if unknown_mode:
        known = set()
        dict_path = HERE / "dictionary.json"
        if dict_path.exists():
            data = json.loads(dict_path.read_text(encoding="utf-8"))
            for section in ("approved", "unapproved"):
                for key, val in data.get(section, {}).items():
                    known.add(PARENS.sub("", key).strip().lower())
                    for form in val.get("forms", []):
                        known.add(form.lower())
        for phrase in load_glossary():
            known.update(phrase.lower().split())

        unknown = {}
        for token in doc:
            if not token.is_alpha or token.is_stop or len(token.text) < 3:
                continue
            lemma = token.lemma_.lower()
            if lemma not in known and token.lower_ not in known:
                word = token.lower_
                prev = unknown.get(word)
                unknown[word] = (token.pos_, (prev[1] + 1) if prev else 1, prev[2] if prev else line_of(token.idx))
        if unknown:
            print("\nunknown words (not in dictionary or glossary; declare as technical nouns or rephrase):")
            for word, (pos, count, line) in sorted(unknown.items(), key=lambda kv: -kv[1][1]):
                print(f"  {word} ({pos.lower()}) x{count}, first at line {line}")

    if lengths:
        print(f"note: mean sentence length {mean_len} words over {len(lengths)} sentences")
    print("clean" if not findings else f"{len(findings)} finding(s)")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
