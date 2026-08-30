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

    def test_packages_no_longer_ship_agent_files(self):
        for platform in sorted(toolkit.VALID_PLATFORMS):
            package = self.export_root / platform
            for path in package.rglob("*"):
                self.assertTrue(
                    "agents/code-reviewer" not in path.as_posix(),
                    "agent roster file leaked into export: {0}".format(path),
                )

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
            target = package / ".agents/skills/start/SKILL.md"
            target.write_text(target.read_text(encoding="utf-8") + "\n<!-- drift -->\n", encoding="utf-8")
            findings = toolkit.check_export_drift("codex", "core", output)
            self.assertTrue(any("Changed files" in finding for finding in findings))

    def test_unknown_package_platform_fails_closed(self):
        errors = toolkit.validate_exported_package(
            self.export_root / "codex", "unknown-platform", "core"
        )
        self.assertEqual(["Unsupported package platform: unknown-platform"], errors)


if __name__ == "__main__":
    unittest.main()
