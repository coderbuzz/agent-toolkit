"""Tests for canonical toolkit validation and security primitives."""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("portable_sdlc_toolkit", TOOLKIT_ROOT / "scripts" / "toolkit.py")
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)


class ValidationTests(unittest.TestCase):
    def test_canonical_toolkit_passes(self):
        self.assertEqual([], toolkit.validate_toolkit())

    def test_manifest_inventory_is_complete(self):
        manifest = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")
        self.assertEqual(26, len(toolkit.all_skill_names(manifest)))
        self.assertEqual(12, len(manifest["agents"]))
        self.assertEqual(
            {"codex", "opencode", "github-copilot", "claude-code", "omp", "gemini"},
            set(manifest["platforms"]),
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
            ".agents/skills/project-discovery/SKILL.md",
            toolkit.safe_relative_path(".agents/skills/project-discovery/SKILL.md").as_posix(),
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
                self.assertEqual({"name", "description"}, set(metadata))

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


if __name__ == "__main__":
    unittest.main()
