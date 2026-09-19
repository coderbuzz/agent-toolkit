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
            self.assertTrue((target / ".agents/skills/grill/SKILL.md").is_file())

    def _run_install(self, home, *extra):
        environment = os.environ.copy()
        environment["HOME"] = str(home)
        return subprocess.run(
            [sys.executable, str(TOOLKIT_SCRIPT), "install", "--platform", "opencode", *extra],
            cwd=str(TOOLKIT_ROOT),
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )

    def test_install_defaults_to_repository_scope_and_demands_a_target(self):
        """A missing --target must fail, never fall back to writing into HOME."""
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / "home"
            home.mkdir()
            result = self._run_install(home)
            self.assertNotEqual(0, result.returncode, result.stdout)
            self.assertIn("--target is required for repository scope", result.stderr)
            self.assertEqual([], list(home.iterdir()), "home must be untouched")

    def test_global_scope_still_defaults_its_target_to_home(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / "home"
            home.mkdir()
            result = self._run_install(home, "--scope", "global")
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
