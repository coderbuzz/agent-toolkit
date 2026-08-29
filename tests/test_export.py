"""Tests for deterministic, platform-native exports."""

import importlib.util
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("agent_toolkit_export", TOOLKIT_ROOT / "scripts" / "toolkit.py")
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)


class ExportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.export_root = Path(cls.temp.name)
        for platform in sorted(toolkit.VALID_PLATFORMS):
            toolkit.export_to_directory(platform, "core", cls.export_root / platform)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_all_core_packages_pass_platform_validation(self):
        for platform in sorted(toolkit.VALID_PLATFORMS):
            with self.subTest(platform=platform):
                self.assertEqual(
                    [],
                    toolkit.validate_exported_package(self.export_root / platform, platform, "core"),
                )

    def test_every_platform_and_bundle_combination_validates(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp)
            for platform in sorted(toolkit.VALID_PLATFORMS):
                for bundle in ("core", "full", "quality"):
                    with self.subTest(platform=platform, bundle=bundle):
                        package = output / (platform + "-" + bundle)
                        toolkit.export_to_directory(platform, bundle, package)
                        self.assertEqual(
                            [],
                            toolkit.validate_exported_package(package, platform, bundle),
                        )

    def test_markdown_agents_start_with_frontmatter(self):
        files = [
            self.export_root / "opencode" / ".opencode/agents/traceability-auditor.md",
            self.export_root / "github-copilot" / ".github/agents/traceability-auditor.agent.md",
            self.export_root / "claude-code" / ".claude/agents/traceability-auditor.md",
            self.export_root / "gemini" / ".gemini/agents/traceability-auditor.md",
        ]
        for path in files:
            with self.subTest(path=path):
                lines = path.read_text(encoding="utf-8").splitlines()
                self.assertEqual("---", lines[0])
                self.assertIn(toolkit.GENERATED_TEXT, lines[1])

    def test_codex_sandboxes_fail_closed(self):
        read_only = (
            self.export_root / "codex" / ".codex/agents/traceability-auditor.toml"
        ).read_text(encoding="utf-8")
        writer = (
            self.export_root / "codex" / ".codex/agents/implementation-engineer.toml"
        ).read_text(encoding="utf-8")
        self.assertIn('sandbox_mode = "read-only"', read_only)
        self.assertIn('sandbox_mode = "workspace-write"', writer)
        self.assertNotIn("danger-full-access", read_only + writer)

    def test_opencode_permissions_fail_closed(self):
        read_only = (
            self.export_root / "opencode" / ".opencode/agents/traceability-auditor.md"
        ).read_text(encoding="utf-8")
        writer = (
            self.export_root / "opencode" / ".opencode/agents/implementation-engineer.md"
        ).read_text(encoding="utf-8")
        self.assertIn("\n  edit: deny\n", read_only)
        self.assertIn("\n  edit: allow\n", writer)
        self.assertIn("\n  bash: ask\n", writer)
        self.assertNotIn("permissions:", read_only + writer)

    def test_gemini_permissions_fail_closed(self):
        read_only = (
            self.export_root / "gemini" / ".gemini/agents/traceability-auditor.md"
        ).read_text(encoding="utf-8")
        writer = (
            self.export_root / "gemini" / ".gemini/agents/implementation-engineer.md"
        ).read_text(encoding="utf-8")
        self.assertIn("\n  edit: deny\n", read_only)
        self.assertIn("\n  edit: allow\n", writer)
        self.assertIn("\n  bash: ask\n", writer)
        self.assertNotIn("permissions:", read_only + writer)

    def test_copilot_tools_are_explicit_and_bounded(self):
        read_only = (
            self.export_root / "github-copilot" / ".github/agents/traceability-auditor.agent.md"
        ).read_text(encoding="utf-8").split("---", 2)[1]
        writer = (
            self.export_root / "github-copilot" / ".github/agents/implementation-engineer.agent.md"
        ).read_text(encoding="utf-8").split("---", 2)[1]
        self.assertIn("tools:", read_only)
        self.assertNotIn('"edit"', read_only)
        self.assertIn('"edit"', writer)

    def test_claude_permission_modes_are_bounded(self):
        read_only = (
            self.export_root / "claude-code" / ".claude/agents/traceability-auditor.md"
        ).read_text(encoding="utf-8")
        writer = (
            self.export_root / "claude-code" / ".claude/agents/implementation-engineer.md"
        ).read_text(encoding="utf-8")
        self.assertIn("permissionMode: plan", read_only)
        self.assertIn("permissionMode: default", writer)
        self.assertNotIn("bypassPermissions", read_only + writer)

    def test_core_excludes_optional_skills_and_full_includes_them(self):
        with tempfile.TemporaryDirectory() as temp:
            full = Path(temp) / "full"
            toolkit.export_to_directory("opencode", "full", full)
            core_optional = self.export_root / "opencode" / ".agents/skills/incident"
            full_optional = full / ".agents/skills/incident/SKILL.md"
            self.assertFalse(core_optional.exists())
            self.assertTrue(full_optional.is_file())

    def test_repeated_exports_are_byte_deterministic(self):
        with tempfile.TemporaryDirectory() as temp:
            first = Path(temp) / "first"
            second = Path(temp) / "second"
            toolkit.export_to_directory("codex", "core", first)
            toolkit.export_to_directory("codex", "core", second)
            self.assertEqual(toolkit.package_files(first), toolkit.package_files(second))

    def test_drift_detection_reports_changed_file(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp)
            package = output / "codex"
            toolkit.export_to_directory("codex", "core", package)
            target = package / ".codex/agents/code-reviewer.toml"
            target.write_text(target.read_text(encoding="utf-8") + "# drift\n", encoding="utf-8")
            findings = toolkit.check_export_drift("codex", "core", output)
            self.assertTrue(any("Changed files" in finding for finding in findings))

    def test_unknown_package_platform_fails_closed(self):
        errors = toolkit.validate_exported_package(
            self.export_root / "codex", "unknown-platform", "core"
        )
        self.assertEqual(["Unsupported package platform: unknown-platform"], errors)


if __name__ == "__main__":
    unittest.main()
