"""Tests for the OMP/Copilot "Dynamic Persona Activation" convention.

Persona-bound skills must carry a `## Dynamic Persona Activation` block so they
interoperate with ecosystems (e.g. awesome-copilot-id) that lock a chat session
to a skill-driven persona. Utility skills must not carry the block.
"""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location(
    "portable_sdlc_toolkit_persona", TOOLKIT_ROOT / "scripts" / "toolkit.py"
)
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)


MANIFEST = json.loads((TOOLKIT_ROOT / "manifest.json").read_text(encoding="utf-8"))
PERSONA_BOUND = [
    name
    for name, meta in MANIFEST.get("skill_metadata", {}).items()
    if meta.get("persona_bound") is True
]
UTILITY = [
    name
    for name, meta in MANIFEST.get("skill_metadata", {}).items()
    if meta.get("persona_bound") is False
]


class CanonicalPersonaConventionTests(unittest.TestCase):
    def test_every_persona_bound_skill_has_activation_block(self):
        for name in PERSONA_BOUND:
            with self.subTest(skill=name):
                path = TOOLKIT_ROOT / MANIFEST["canonical"]["skills"] / name / "SKILL.md"
                self.assertIn("## Dynamic Persona Activation", path.read_text(encoding="utf-8"))

    def test_no_utility_skill_has_activation_block(self):
        for name in UTILITY:
            with self.subTest(skill=name):
                path = TOOLKIT_ROOT / MANIFEST["canonical"]["skills"] / name / "SKILL.md"
                self.assertNotIn("## Dynamic Persona Activation", path.read_text(encoding="utf-8"))

    def test_validate_skills_enforces_convention(self):
        errors = []
        toolkit.validate_skills(MANIFEST, errors)
        self.assertEqual([], errors)


class ExportedPersonaConventionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.export_root = Path(cls.temp.name)
        for platform in ("omp", "github-copilot", "opencode", "claude-code", "codex"):
            toolkit.export_to_directory(platform, "full", cls.export_root / platform)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def _skill_path(self, platform, skill):
        import re

        adapter = json.loads(
            (TOOLKIT_ROOT / "platforms" / platform / "adapter.json").read_text(encoding="utf-8")
        )
        pattern = adapter["skill_path"]
        base = re.sub(r"\{[^}]+\}", skill, pattern)
        return self.export_root / platform / base / "SKILL.md"

    def test_persona_bound_skill_carries_block_in_exports(self):
        for platform in ("omp", "github-copilot"):
            with self.subTest(platform=platform):
                text = self._skill_path(platform, "sdlc-review").read_text(encoding="utf-8")
                self.assertIn("## Dynamic Persona Activation", text)

    def test_utility_skill_lacks_block_in_exports(self):
        for platform in ("omp", "github-copilot"):
            with self.subTest(platform=platform):
                text = self._skill_path(platform, "sdlc-memory").read_text(encoding="utf-8")
                self.assertNotIn("## Dynamic Persona Activation", text)


if __name__ == "__main__":
    unittest.main()
