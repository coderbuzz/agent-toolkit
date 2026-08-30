"""End-to-end tests for the public command-line interface."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
TOOLKIT_SCRIPT = TOOLKIT_ROOT / "scripts" / "toolkit.py"


def run_cli(*arguments):
    environment = os.environ.copy()
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    return subprocess.run(
        [sys.executable, str(TOOLKIT_SCRIPT)] + list(arguments),
        cwd=str(TOOLKIT_ROOT),
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


class CliTests(unittest.TestCase):
    def test_validate_command(self):
        result = run_cli("validate")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("validation passed", result.stdout)

    def test_export_and_check_drift_commands(self):
        with tempfile.TemporaryDirectory() as temp:
            result = run_cli("export", "--all", "--bundle", "core", "--output", temp)
            self.assertEqual(0, result.returncode, result.stderr)
            drift = run_cli("check-drift", "--all", "--bundle", "core", "--output", temp)
            self.assertEqual(0, drift.returncode, drift.stderr)
            self.assertIn("No drift: codex", drift.stdout)

    def test_install_defaults_to_dry_run_and_apply_is_explicit(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            preview = run_cli(
                "install",
                "--platform",
                "opencode",
                "--scope",
                "repository",
                "--bundle",
                "quality",
                "--target",
                str(target),
            )
            self.assertEqual(0, preview.returncode, preview.stderr)
            self.assertIn("Dry run only", preview.stdout)
            self.assertFalse(target.exists())

            apply = run_cli(
                "install",
                "--platform",
                "opencode",
                "--scope",
                "repository",
                "--bundle",
                "quality",
                "--target",
                str(target),
                "--apply",
            )
            self.assertEqual(0, apply.returncode, apply.stderr)
            self.assertTrue((target / ".agent-toolkit-install.json").is_file())
            self.assertTrue((target / ".opencode/agents/code-reviewer.md").is_file())

    def test_install_defaults_to_global_scope_without_target(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / "home"
            home.mkdir()
            environment = os.environ.copy()
            environment["HOME"] = str(home)
            result = subprocess.run(
                [
                    sys.executable,
                    str(TOOLKIT_SCRIPT),
                    "install",
                    "--platform",
                    "opencode",
                ],
                cwd=str(TOOLKIT_ROOT),
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("Global install plan", result.stdout)
            self.assertIn("Dry run only", result.stdout)

    def test_conflict_returns_nonzero_without_overwrite(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            target.mkdir()
            agents = target / "AGENTS.md"
            agents.write_text("existing\n", encoding="utf-8")
            result = run_cli(
                "install",
                "--platform",
                "codex",
                "--scope",
                "repository",
                "--target",
                str(target),
                "--apply",
            )
            self.assertNotEqual(0, result.returncode)
            self.assertIn("user-owned", result.stderr)
            self.assertEqual("existing\n", agents.read_text(encoding="utf-8"))

    def test_root_install_sh_script(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            result = subprocess.run(
                [
                    str(TOOLKIT_ROOT / "install.sh"),
                    "--platform",
                    "opencode",
                    "--scope",
                    "repository",
                    "--target",
                    str(target),
                ],
                cwd=str(TOOLKIT_ROOT),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("Dry run only", result.stdout)

    def test_root_uninstall_sh_script(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            # First install
            install_res = run_cli(
                "install",
                "--platform",
                "opencode",
                "--scope",
                "repository",
                "--target",
                str(target),
                "--apply",
            )
            self.assertEqual(0, install_res.returncode, install_res.stderr)
            self.assertTrue((target / ".agent-toolkit-install.json").is_file())

            # Now uninstall using uninstall.sh
            result = subprocess.run(
                [
                    str(TOOLKIT_ROOT / "uninstall.sh"),
                    "--scope",
                    "repository",
                    "--target",
                    str(target),
                    "--apply",
                ],
                cwd=str(TOOLKIT_ROOT),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("Uninstall completed", result.stdout)
            self.assertFalse((target / ".agent-toolkit-install.json").exists())

    def test_global_install_via_shell_script_records_ledger(self):
        """Global install through scripts/install.sh (pure POSIX shell) must
        write a non-empty ledger and preserve user instruction files."""
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / "home"
            home.mkdir()
            environment = os.environ.copy()
            environment["HOME"] = str(home)

            install = subprocess.run(
                [
                    str(TOOLKIT_ROOT / "scripts" / "install.sh"),
                    "--platform",
                    "opencode",
                    "--scope",
                    "global",
                    "--bundle",
                    "core",
                    "--apply",
                ],
                cwd=str(TOOLKIT_ROOT),
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, install.returncode, install.stderr)

            ledger = json.loads((home / ".agent-toolkit-install-opencode.json").read_text())
            self.assertGreater(len(ledger["files"]), 0)
            self.assertTrue((home / ".config/opencode/AGENTS.md").is_file())

            uninstall = subprocess.run(
                [
                    str(TOOLKIT_ROOT / "scripts" / "uninstall.sh"),
                    "--platform",
                    "opencode",
                    "--scope",
                    "global",
                    "--apply",
                ],
                cwd=str(TOOLKIT_ROOT),
                env=environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, uninstall.returncode, uninstall.stderr)
            self.assertIn("Global uninstall completed", uninstall.stdout)
            self.assertFalse((home / ".agent-toolkit-install-opencode.json").exists())


if __name__ == "__main__":
    unittest.main()

