"""Vendor the antislop skills from an upstream checkout into .agents/skills/.

Usage:
    python3 scripts/vendor-anti-slop.py <path-to-anti-slop-checkout>

Applies exactly the adaptations recorded in vendor/anti-slop.json, and proves the
rule text is otherwise untouched by comparing the word sequence before and after.
Re-running it is safe; it rewrites the vendored files from upstream every time.
"""
import re
import shutil
import sys
import pathlib

UPSTREAM = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "../anti-slop")
DEST = pathlib.Path(__file__).resolve().parent.parent / ".agents" / "skills"
LIMIT = 120

FRONTMATTER = {
    "antislop": (
        "Filter generic AI slop out of UI, copy, and code. The core rule set "
        "(R-01 to R-38), the liveliness dials, and the delivery gate. Use when "
        "generating or editing an interface, prose, or code comments, and load "
        "the matching companion skill for depth.",
        "both", "slop filter",
    ),
    "antislop-ui": (
        "Depth on the UI and visual concern for antislop: color, layout, "
        "components, decoration, and motion. Use when building or editing any "
        "interface. Load together with the antislop core.",
        "both", "ui slop filter",
    ),
    "antislop-copywriting": (
        "Depth on the copy and text concern for antislop: headlines, tone, CTAs, "
        "and the patterns that make prose read as AI-written. Use when writing or "
        "editing prose. Load together with the antislop core.",
        "both", "copy slop filter",
    ),
    "antislop-code": (
        "Code comment hygiene for antislop: remove generic AI-slop comments, keep "
        "the ones carrying real information, never touch executable code. Use when "
        "writing or editing code comments. Load together with the antislop core.",
        "both", "comment slop filter",
    ),
    "antislop-human": (
        "Depth on the human and accessibility concern for antislop: contrast, "
        "keyboard, focus, and states. Includes the contrast checker. Use when "
        "building or editing UI. Load together with the antislop core.",
        "both", "accessibility filter",
    ),
    "antislop-layoutmobile": (
        "Depth on the responsive layout concern for antislop: breakpoints, grids, "
        "overflow, tap targets, and navigation from phone to desktop. Use for "
        "layouts that must reflow. Load together with the antislop core.",
        "both", "responsive layout filter",
    ),
}

INSTALL_NOTE = """## Installation

This skill is installed and removed by the Agent Toolkit, not by this file.
See `AGENT-INSTALL.md` in the toolkit repository for the install, update, and
uninstall procedure. The companion skills (`antislop-ui`,
`antislop-copywriting`, `antislop-code`, `antislop-human`,
`antislop-layoutmobile`) ship alongside this one and load on demand.
"""


def strip_install_wizard(text):
    lines = text.split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("## First-Run Install Wizard"))
    end = next(i for i, l in enumerate(lines) if l.startswith("## Two Usage Modes"))
    sep = end - 1
    while lines[sep].strip() == "":
        sep -= 1
    assert lines[sep].strip() == "---", repr(lines[sep])
    lines[start:sep] = INSTALL_NOTE.split("\n")
    return "\n".join(lines)


def enforce_hard_gate_r02(text):
    """Remove the em dash exceptions that contradict R-02.

    The core states R-02 as a Hard Gate: the em dash is forbidden in any text,
    and breaking a Hard Gate is a FAIL regardless of purpose. This skill then
    grants a voice override in three places, so an agent that loads both can
    reasonably conclude em dashes are sometimes allowed. In practice they do.

    The "false positive" note is left alone: it is about detecting AI in someone
    else's writing, not about what this agent may write.
    """
    replacements = [
        ("- **Voice override:** if the user provides a writing sample that uses em dashes at a certain "
         "frequency, match the sample's frequency instead of cutting them all (see Voice calibration).",
         "- **No voice override:** R-02 is a Hard Gate, so it holds even when the user's own sample uses "
         "em dashes. Match the sample's rhythm and vocabulary, and still replace every em dash. Say that you did."),
        ("3. The sample outranks this skill's style rules. If the sample uses em dashes, keep them at roughly "
         "the sample's frequency (R-02 still applies to any copy the user did not authorize; when the user's "
         "own voice uses them, the voice wins).",
         "3. The sample outranks this skill's style rules, but not the core's Hard Gates. Match its habits; "
         "still replace every em dash (R-02). A Hard Gate is not a style preference, so a sample cannot "
         "license one."),
        ("- [ ] No em dashes in the output (R-02), unless the user's own sample voice uses them",
         "- [ ] No em dashes in the output (R-02). No exceptions: a Hard Gate holds even against the user's "
         "own sample voice"),
    ]
    for old, new in replacements:
        assert old in text, "upstream wording changed; re-check this adaptation"
        text = text.replace(old, new, 1)
    return text


def neutralize_platform_vars(text):
    """Drop the Claude-Code-specific CLAUDE_SKILL_DIR variable."""
    old_cmd = 'python3 "${CLAUDE_SKILL_DIR}/contrast-check.py" "#FFFFFF" "#777777"'
    new_cmd = 'python3 contrast-check.py "#FFFFFF" "#777777"'
    old_note = ("If the `${CLAUDE_SKILL_DIR}` variable is not available in this agent, point the "
                "script path at this skill's folder directly. The script exists")
    new_note = "Run it from this skill's folder, or give the full path to it. The script exists"
    assert old_cmd in text and old_note in text
    return text.replace(old_cmd, new_cmd).replace(old_note, new_note)


def rewrite_frontmatter(text, name):
    desc, invocation, role = FRONTMATTER[name]
    lines = text.split("\n")
    assert lines[0] == "---"
    body = lines[lines.index("---", 1) + 1:]
    folded, cur = [], "  "
    for w in desc.split():
        if len(cur) + len(w) + 1 > 78:
            folded.append(cur.rstrip())
            cur = "  "
        cur += w + " "
    folded.append(cur.rstrip())
    fm = ["---", f"name: {name}", "description: >-", *folded,
          f"invocation: {invocation}", f"role: {role}", "---"]
    return "\n".join(fm + body)


def split_prefix(line):
    """Return (first_prefix, continuation_prefix, text).

    A list item inside a blockquote keeps the quote marker on every line and
    indents the continuation under the list marker, so the item does not rely on
    lazy continuation to stay one paragraph.
    """
    m = re.match(r"^(>\s*)((?:[-*]\s+|\d+\.\s+)?)(.*)$", line)
    if m:
        quote, marker, text = m.groups()
        return quote + marker, quote + " " * len(marker), text
    m = re.match(r"^(\s*)([-*]\s+|\d+\.\s+)(.*)$", line)
    if m:
        indent, marker, text = m.groups()
        return indent + marker, indent + " " * len(marker), text
    indent, text = re.match(r"^(\s*)(.*)$", line).groups()
    return indent, indent, text


def wrap_line(line):
    first, cont, text = split_prefix(line)
    words = text.split()
    if not words:
        return [line]
    out, cur, prefix = [], first, first
    for w in words:
        candidate = cur + w if cur == prefix else cur + " " + w
        if len(candidate) > LIMIT and cur != prefix:
            out.append(cur)
            prefix = cont
            cur = cont + w
        else:
            cur = candidate
    out.append(cur)
    return out


def rewrap(text):
    out, in_code, in_fm, n = [], False, False, 0
    for i, line in enumerate(text.split("\n")):
        if i == 0 and line == "---":
            in_fm = True
            out.append(line)
            continue
        if in_fm:
            out.append(line)
            in_fm = line != "---"
            continue
        if line.lstrip().startswith("```"):
            in_code = not in_code
            out.append(line)
            continue
        # tables cannot be wrapped without breaking them; code blocks are verbatim
        if in_code or len(line) <= LIMIT or line.lstrip().startswith("|"):
            out.append(line)
            continue
        out.extend(wrap_line(line))
        n += 1
    return "\n".join(out), n


def content_tokens(text):
    """Word sequence per block. Blockquote markers are structural, not content."""
    result, in_code = [], False
    for line in text.split("\n"):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            result.append(("FENCE", line.strip()))
            continue
        if in_code:
            result.append(("CODE", line))
        else:
            result.extend(("W", w) for w in re.sub(r"^\s*>+\s*", "", line).split())
    return result


failures = []
for name in FRONTMATTER:
    src = UPSTREAM / "skills" / name / "SKILL.md"
    dst_dir = DEST / name
    dst_dir.mkdir(parents=True, exist_ok=True)
    (dst_dir / "agents").mkdir(exist_ok=True)

    text = src.read_text(encoding="utf-8")
    if name == "antislop":
        text = strip_install_wizard(text)
    if name == "antislop-copywriting":
        text = enforce_hard_gate_r02(text)
    if name == "antislop-human":
        text = neutralize_platform_vars(text)
        shutil.copyfile(UPSTREAM / "skills" / name / "contrast-check.py",
                        dst_dir / "contrast-check.py")

    adapted = rewrite_frontmatter(text, name)
    wrapped, n = rewrap(adapted)
    (dst_dir / "SKILL.md").write_text(wrapped, encoding="utf-8")

    # prose after the frontmatter must be word-identical to the adapted input
    body_before = adapted.split("\n---\n", 1)[1]
    body_after = wrapped.split("\n---\n", 1)[1]
    identical = content_tokens(body_before) == content_tokens(body_after)
    over = [i for i, l in enumerate(wrapped.split("\n"), 1)
            if len(l) > LIMIT and not l.lstrip().startswith("|")]
    print(f"{name:24} rewrapped={n:4}  words-identical={identical}  over-120(non-table)={len(over)}")
    if not identical or over:
        failures.append(name)

sys.exit("FAILED: " + ", ".join(failures) if failures else 0)
