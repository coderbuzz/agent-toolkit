"""Tests for canonical toolkit validation and security primitives."""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("agent_toolkit", TOOLKIT_ROOT / "scripts" / "toolkit.py")
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)


class ValidationTests(unittest.TestCase):
    def test_canonical_toolkit_passes(self):
        self.assertEqual([], toolkit.validate_toolkit())

    def test_manifest_inventory_is_complete(self):
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        names = toolkit.all_skill_names(manifest)
        self.assertEqual(31, len(names))
        self.assertEqual(sorted(set(names)), sorted(names), "skill names must be unique")
        self.assertEqual(
            {"codex", "opencode", "github-copilot", "claude-code", "omp", "gemini", "zcode"},
            set(manifest["platforms"]),
        )

    def test_every_manifest_skill_group_is_collected(self):
        """A group absent from SKILL_GROUPS is silently ignored everywhere."""
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        self.assertEqual(set(manifest["skills"]), set(toolkit.SKILL_GROUPS))

    def test_antislop_ships_in_the_core_bundle(self):
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        core = toolkit.bundle_skill_names(manifest, "core")
        self.assertEqual(
            [
                "antislop",
                "antislop-ui",
                "antislop-copywriting",
                "antislop-code",
                "antislop-human",
                "antislop-layoutmobile",
            ],
            [name for name in core if name.startswith("antislop")],
        )

    def test_strict_json_rejects_duplicate_keys(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "duplicate.json"
            path.write_text('{"value": 1, "value": 2}', encoding="utf-8")
            with self.assertRaisesRegex(toolkit.ToolkitError, "Duplicate JSON key"):
                toolkit.load_json(path)

    def test_strict_json_rejects_non_finite_numbers(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "invalid.json"
            path.write_text('{"value": NaN}', encoding="utf-8")
            with self.assertRaisesRegex(toolkit.ToolkitError, "Non-finite"):
                toolkit.load_json(path)

    def test_safe_relative_path_rejects_escape_forms(self):
        unsafe = ["../escape", "/absolute", "folder/../escape", "C:/escape", "a\\b", ""]
        for value in unsafe:
            with self.subTest(value=value):
                with self.assertRaises(toolkit.ToolkitError):
                    toolkit.safe_relative_path(value)

    def test_safe_relative_path_accepts_nested_portable_path(self):
        self.assertEqual(
            ".agents/skills/discover/SKILL.md",
            toolkit.safe_relative_path(".agents/skills/discover/SKILL.md").as_posix(),
        )

    def test_filesystem_root_is_not_an_operation_target(self):
        with self.assertRaisesRegex(toolkit.ToolkitError, "filesystem root"):
            toolkit.safe_operation_root(Path("/"), "install target")

    def test_all_skill_frontmatter_names_match_directories(self):
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        skill_root = TOOLKIT_ROOT / manifest["canonical"]["skills"]
        for name in toolkit.all_skill_names(manifest):
            with self.subTest(skill=name):
                metadata = toolkit.parse_frontmatter(skill_root / name / "SKILL.md")
                self.assertEqual(name, metadata["name"])

    def test_adapter_descriptors_have_unique_platform_ids(self):
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        adapter_ids = []
        for platform in manifest["platforms"]:
            adapter = toolkit.load_json(TOOLKIT_ROOT / "platforms" / platform / "adapter.json")
            adapter_ids.append(adapter["id"])
        self.assertEqual(len(adapter_ids), len(set(adapter_ids)))
        self.assertEqual(set(manifest["platforms"]), set(adapter_ids))

    def test_manifest_json_is_deterministically_serializable(self):
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        serialized = json.dumps(manifest, sort_keys=True, separators=(",", ":"))
        self.assertEqual(serialized, json.dumps(json.loads(serialized), sort_keys=True, separators=(",", ":")))


class HouseStyleTests(unittest.TestCase):
    """The toolkit must obey the rules it ships.

    R-02 in the antislop core forbids the em dash in any text, and states it as a
    Hard Gate. Shipping skills and documentation that break it undermines the
    rule in front of the people we are asking to follow it.
    """

    #: The antislop skills quote R-02 in order to define it, which the rule exempts.
    CARVE_OUT = "antislop"

    def _our_text_files(self):
        for pattern in ("*.md", "llms.txt", "NOTICE"):
            for path in TOOLKIT_ROOT.rglob(pattern):
                relative = path.relative_to(TOOLKIT_ROOT).as_posix()
                if relative.startswith("dist/") or self.CARVE_OUT in relative:
                    continue
                if relative.startswith(".git/"):
                    continue
                yield relative, path

    def test_no_em_dashes_in_our_own_writing(self):
        offenders = {}
        for relative, path in self._our_text_files():
            count = path.read_text(encoding="utf-8").count("\u2014")
            if count:
                offenders[relative] = count
        self.assertEqual(
            {}, offenders,
            "R-02 forbids the em dash; use a comma, period, colon, or parentheses",
        )

    def test_the_installed_pointer_obeys_r02(self):
        """AGENTS.md ships to every user, so a violation there is the most visible."""
        self.assertNotIn("\u2014", (TOOLKIT_ROOT / "AGENTS.md").read_text(encoding="utf-8"))

    def test_r02_has_no_voice_override_in_the_vendored_skill(self):
        """The core calls R-02 a Hard Gate, so the skill must not grant exceptions."""
        text = (TOOLKIT_ROOT / ".agents" / "skills" / "antislop-copywriting" / "SKILL.md").read_text(
            encoding="utf-8"
        )
        for escape_hatch in (
            "unless the user's own sample voice uses them",
            "instead of cutting them all",
            "the voice\n   wins",
        ):
            self.assertNotIn(escape_hatch, text)


if __name__ == "__main__":
    unittest.main()
