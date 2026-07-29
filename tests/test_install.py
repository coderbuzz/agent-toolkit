"""Tests for safe package installation and removal."""

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest import mock


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("portable_sdlc_toolkit_install", TOOLKIT_ROOT / "scripts" / "toolkit.py")
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.package = self.root / "package"
        self.target = self.root / "target"
        toolkit.export_to_directory("codex", "core", self.package)

    def tearDown(self):
        self.temp.cleanup()

    def test_install_plan_does_not_mutate_target(self):
        actions, conflicts, ledger = toolkit.plan_install(self.package, self.target)
        self.assertFalse(conflicts)
        self.assertTrue(actions)
        self.assertFalse(self.target.exists())
        self.assertEqual("codex", ledger["platform"])

    def test_apply_is_idempotent_for_managed_files(self):
        toolkit.apply_install(self.package, self.target)
        managed = self.target / ".codex/agents/sdlc-code-reviewer.toml"
        initial_hash = toolkit.file_sha256(managed)
        initial_mtime = managed.stat().st_mtime_ns
        actions = toolkit.apply_install(self.package, self.target)
        self.assertTrue(all(action in ("unchanged", "already-removed") for action, _ in actions))
        self.assertEqual(initial_hash, toolkit.file_sha256(managed))
        self.assertEqual(initial_mtime, managed.stat().st_mtime_ns)

    def test_existing_different_user_file_is_a_conflict(self):
        self.target.mkdir()
        (self.target / "AGENTS.md").write_text("user guidance\n", encoding="utf-8")
        _actions, conflicts, _ledger = toolkit.plan_install(self.package, self.target)
        self.assertTrue(any("user-owned" in conflict for conflict in conflicts))
        with self.assertRaisesRegex(toolkit.ToolkitError, "Install conflicts"):
            toolkit.apply_install(self.package, self.target)
        self.assertEqual("user guidance\n", (self.target / "AGENTS.md").read_text(encoding="utf-8"))

    def test_existing_identical_user_file_is_not_claimed_or_uninstalled(self):
        self.target.mkdir()
        user_owned = self.target / "AGENTS.md"
        shutil.copyfile(str(self.package / "AGENTS.md"), str(user_owned))
        actions = toolkit.apply_install(self.package, self.target)
        self.assertIn(("preserve-identical-user-owned", "AGENTS.md"), actions)
        ledger = toolkit.load_json(self.target / toolkit.LEDGER_NAME)
        self.assertNotIn("AGENTS.md", ledger["files"])
        toolkit.apply_uninstall(self.target)
        self.assertTrue(user_owned.is_file())

    def test_modified_managed_file_blocks_reinstall(self):
        toolkit.apply_install(self.package, self.target)
        managed = self.target / ".codex/agents/sdlc-code-reviewer.toml"
        managed.write_text(managed.read_text(encoding="utf-8") + "# user change\n", encoding="utf-8")
        _actions, conflicts, _ledger = toolkit.plan_install(self.package, self.target)
        self.assertTrue(any("User-modified managed file" in conflict for conflict in conflicts))

    def test_uninstall_preserves_modified_managed_file(self):
        toolkit.apply_install(self.package, self.target)
        preserved = self.target / ".codex/agents/sdlc-code-reviewer.toml"
        preserved.write_text(preserved.read_text(encoding="utf-8") + "# keep\n", encoding="utf-8")
        _actions, warnings = toolkit.apply_uninstall(self.target)
        self.assertTrue(preserved.is_file())
        self.assertTrue(any("Preserving modified" in warning for warning in warnings))
        self.assertFalse((self.target / toolkit.LEDGER_NAME).exists())
        self.assertFalse((self.target / ".codex/agents/sdlc-product-manager.toml").exists())

    def test_repeated_uninstall_is_harmless(self):
        toolkit.apply_install(self.package, self.target)
        toolkit.apply_uninstall(self.target)
        actions, warnings = toolkit.apply_uninstall(self.target)
        self.assertEqual([], actions)
        self.assertEqual([], warnings)

    def test_ledger_path_traversal_is_rejected(self):
        self.target.mkdir()
        ledger = {
            "schema_version": 1,
            "files": {"../outside": "0" * 64},
        }
        (self.target / toolkit.LEDGER_NAME).write_text(json.dumps(ledger), encoding="utf-8")
        with self.assertRaisesRegex(toolkit.ToolkitError, "Unsafe relative path"):
            toolkit.plan_uninstall(self.target)

    def test_symlink_escape_is_reported_as_conflict(self):
        self.target.mkdir()
        outside = self.root / "outside"
        outside.mkdir()
        (self.target / ".agents").symlink_to(outside, target_is_directory=True)
        _actions, conflicts, _ledger = toolkit.plan_install(self.package, self.target)
        self.assertTrue(any("escapes target root" in conflict or "symlinked" in conflict for conflict in conflicts))
        self.assertEqual([], list(outside.iterdir()))

    def test_partial_copy_failure_rolls_back(self):
        original_copyfile = shutil.copyfile
        calls = {"count": 0}

        def fail_on_second(source, destination):
            calls["count"] += 1
            if calls["count"] == 2:
                raise OSError("simulated copy failure")
            return original_copyfile(source, destination)

        with mock.patch.object(toolkit.shutil, "copyfile", side_effect=fail_on_second):
            with self.assertRaisesRegex(toolkit.ToolkitError, "rolled back"):
                toolkit.apply_install(self.package, self.target)
        self.assertFalse((self.target / toolkit.LEDGER_NAME).exists())
        remaining_files = [path for path in self.target.rglob("*") if path.is_file()]
        self.assertEqual([], remaining_files)


if __name__ == "__main__":
    unittest.main()
