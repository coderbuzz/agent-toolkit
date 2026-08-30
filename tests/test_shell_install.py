"""End-to-end tests for the zero-dependency shell and PowerShell installers.

The POSIX installers must behave like scripts/toolkit.py: same ledger bytes,
same conflict rules, same managed-block semantics. PowerShell parity is
verified when a pwsh binary is available.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
INSTALL_SH = TOOLKIT_ROOT / "scripts" / "install.sh"
UNINSTALL_SH = TOOLKIT_ROOT / "scripts" / "uninstall.sh"
INSTALL_PS1 = TOOLKIT_ROOT / "scripts" / "install.ps1"
UNINSTALL_PS1 = TOOLKIT_ROOT / "scripts" / "uninstall.ps1"


def run_sh(script, *arguments, home=None):
    environment = os.environ.copy()
    if home is not None:
        environment["HOME"] = str(home)
    return subprocess.run(
        [str(script)] + [str(item) for item in arguments],
        cwd=str(TOOLKIT_ROOT),
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


class NoPythonRegressionTests(unittest.TestCase):
    def test_installers_never_invoke_python(self):
        for path in (
            INSTALL_SH,
            UNINSTALL_SH,
            INSTALL_PS1,
            UNINSTALL_PS1,
            TOOLKIT_ROOT / "scripts" / "setup.sh",
            TOOLKIT_ROOT / "install.sh",
            TOOLKIT_ROOT / "uninstall.sh",
        ):
            with self.subTest(script=path.name):
                for line in path.read_text(encoding="utf-8").splitlines():
                    if "python" not in line and "toolkit.py" not in line:
                        continue
                    stripped = line.strip()
                    # Guidance text that TELLS maintainers how to regenerate
                    # dist is fine; invoking a Python runtime is not.
                    self.assertTrue(
                        stripped.startswith("#")
                        or stripped.startswith("echo")
                        or stripped.startswith("printf")
                        or stripped.startswith("tk_die")
                        or stripped.startswith("Fail ")
                        or stripped.startswith("Write-Error")
                        or stripped.startswith("Write-Host")
                        or stripped.startswith('echo "Maintainers'),
                        "installer line invokes python: {0}".format(line),
                    )


class ShellRepositoryInstallTests(unittest.TestCase):
    def test_repository_install_matches_python_installer_byte_for_byte(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            shell_target = root / "shell"
            python_target = root / "python"
            shell = run_sh(
                INSTALL_SH,
                "--platform", "opencode",
                "--scope", "repository",
                "--target", shell_target,
                "--apply",
            )
            self.assertEqual(0, shell.returncode, shell.stderr)
            python = subprocess.run(
                [
                    sys.executable,
                    str(TOOLKIT_ROOT / "scripts" / "toolkit.py"),
                    "install",
                    "--package",
                    str(TOOLKIT_ROOT / "dist" / "opencode"),
                    "--scope",
                    "repository",
                    "--target",
                    str(python_target),
                    "--apply",
                ],
                cwd=str(TOOLKIT_ROOT),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, python.returncode, python.stderr)
            shell_ledger = shell_target / ".agent-toolkit-install.json"
            python_ledger = python_target / ".agent-toolkit-install.json"
            self.assertEqual(
                python_ledger.read_bytes(),
                shell_ledger.read_bytes(),
                "shell and python ledgers must be byte-identical",
            )
            shell_files = sorted(
                path.relative_to(shell_target).as_posix()
                for path in shell_target.rglob("*")
                if path.is_file()
            )
            python_files = sorted(
                path.relative_to(python_target).as_posix()
                for path in python_target.rglob("*")
                if path.is_file()
            )
            self.assertEqual(python_files, shell_files)

    def test_repository_uninstall_removes_only_managed_files(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            self.assertEqual(
                0,
                run_sh(
                    INSTALL_SH,
                    "--platform", "opencode",
                    "--scope", "repository",
                    "--target", target,
                    "--apply",
                ).returncode,
            )
            user_file = target / "user-notes.txt"
            user_file.write_text("keep me\n", encoding="utf-8")
            result = run_sh(
                UNINSTALL_SH,
                "--scope", "repository",
                "--target", target,
                "--apply",
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("Uninstall completed", result.stdout)
            self.assertFalse((target / ".agent-toolkit-install.json").exists())
            self.assertEqual("keep me\n", user_file.read_text(encoding="utf-8"))

    def test_stale_managed_file_is_removed_on_reinstall(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            target = root / "target"
            package = root / "package"
            shutil.copytree(TOOLKIT_ROOT / "dist" / "opencode", package)
            self.assertEqual(
                0,
                run_sh(
                    INSTALL_SH,
                    "--package", package,
                    "--scope", "repository",
                    "--target", target,
                    "--apply",
                ).returncode,
            )
            removed = target / ".opencode" / "agents" / "code-reviewer.md"
            removed.unlink()
            (package / ".opencode" / "agents" / "code-reviewer.md").unlink()
            result = run_sh(
                INSTALL_SH,
                "--package", package,
                "--scope", "repository",
                "--target", target,
                "--apply",
            )
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("already-removed", result.stdout)
            self.assertFalse(removed.exists())

    def test_existing_user_file_differs_blocks_install(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            target.mkdir()
            agents = target / "AGENTS.md"
            agents.write_text("existing\n", encoding="utf-8")
            result = run_sh(
                INSTALL_SH,
                "--platform", "opencode",
                "--scope", "repository",
                "--target", target,
                "--apply",
            )
            self.assertEqual(1, result.returncode)
            self.assertIn("user-owned", result.stderr)
            self.assertEqual("existing\n", agents.read_text(encoding="utf-8"))


class ShellGlobalInstallTests(unittest.TestCase):
    def _install(self, platform, home, apply=True):
        arguments = ["--platform", platform]
        if apply:
            arguments.append("--apply")
        return run_sh(INSTALL_SH, *arguments, home=home)

    def _uninstall(self, platform, home):
        return run_sh(
            UNINSTALL_SH,
            "--scope", "global",
            "--platform", platform,
            "--apply",
            home=home,
        )

    def test_global_install_appends_block_to_user_instruction_file(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            instruction = home / ".config" / "opencode" / "AGENTS.md"
            instruction.parent.mkdir(parents=True)
            instruction.write_text("My personal guidance.\n", encoding="utf-8")

            result = self._install("opencode", home)
            self.assertEqual(0, result.returncode, result.stderr)

            ledger = json.loads(
                (home / ".agent-toolkit-install-opencode.json").read_text(encoding="utf-8")
            )
            self.assertGreater(len(ledger["files"]), 0)
            text = instruction.read_text(encoding="utf-8")
            self.assertTrue(text.startswith("My personal guidance.\n"))
            self.assertIn("# >>> agent-toolkit instructions", text)

            uninstall = self._uninstall("opencode", home)
            self.assertEqual(0, uninstall.returncode, uninstall.stderr)
            self.assertIn("Global uninstall completed", uninstall.stdout)
            # The block separator may leave one trailing blank line behind,
            # exactly like the Python installer; user content must survive.
            text = instruction.read_text(encoding="utf-8")
            self.assertTrue(text.startswith("My personal guidance.\n"))
            self.assertNotIn("agent-toolkit", text)
            self.assertFalse((home / ".agent-toolkit-install-opencode.json").exists())

    def test_shared_skills_are_reference_counted_across_platforms(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            self.assertEqual(0, self._install("opencode", home).returncode)
            second = self._install("claude-code", home)
            self.assertEqual(0, second.returncode, second.stderr)
            self.assertIn("shared-adopt", second.stdout)

            shared_ledger = json.loads(
                (home / ".agent-toolkit-shared-skills.json").read_text(encoding="utf-8")
            )
            skill = ".agents/skills/start/SKILL.md"
            self.assertEqual(
                ["claude-code", "opencode"],
                sorted(shared_ledger["files"][skill]["owners"]),
            )

            self.assertEqual(0, self._uninstall("opencode", home).returncode)
            self.assertTrue((home / skill).is_file())
            shared_ledger = json.loads(
                (home / ".agent-toolkit-shared-skills.json").read_text(encoding="utf-8")
            )
            self.assertEqual(["claude-code"], shared_ledger["files"][skill]["owners"])

            self.assertEqual(0, self._uninstall("claude-code", home).returncode)
            self.assertFalse((home / skill).exists())
            remaining = [path for path in home.rglob("*") if path.is_file()]
            self.assertEqual([], remaining)

    def test_user_modified_shared_skill_blocks_reinstall(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            self.assertEqual(0, self._install("opencode", home).returncode)
            skill = home / ".agents" / "skills" / "start" / "SKILL.md"
            skill.write_text(
                skill.read_text(encoding="utf-8") + "\nuser edit\n", encoding="utf-8"
            )
            result = self._install("gemini", home)
            self.assertEqual(1, result.returncode)
            self.assertIn("User-modified shared skill", result.stderr)

    def test_codex_config_merge_preserves_user_toml(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            config = home / ".codex" / "config.toml"
            config.parent.mkdir(parents=True)
            config.write_text('model = "gpt-5"\n', encoding="utf-8")

            install = self._install("codex", home)
            self.assertEqual(0, install.returncode, install.stderr)
            self.assertIn("codex-merge-append", install.stdout)
            text = config.read_text(encoding="utf-8")
            self.assertIn('model = "gpt-5"', text)
            self.assertIn("[agents.code-reviewer]", text)

            uninstall = self._uninstall("codex", home)
            self.assertEqual(0, uninstall.returncode, uninstall.stderr)
            text = config.read_text(encoding="utf-8")
            self.assertIn('model = "gpt-5"', text)
            self.assertNotIn("[agents.code-reviewer]", text)

    def test_global_ledger_matches_python_installer_byte_for_byte(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            shell_home = root / "shell-home"
            python_home = root / "python-home"
            shell_home.mkdir()
            python_home.mkdir()
            self.assertEqual(
                0,
                run_sh(
                    INSTALL_SH,
                    "--platform", "opencode",
                    "--apply",
                    home=shell_home,
                ).returncode,
            )
            python = subprocess.run(
                [
                    sys.executable,
                    str(TOOLKIT_ROOT / "scripts" / "toolkit.py"),
                    "install",
                    "--package",
                    str(TOOLKIT_ROOT / "dist" / "global" / "opencode"),
                    "--scope",
                    "global",
                    "--target",
                    str(python_home),
                    "--apply",
                ],
                cwd=str(TOOLKIT_ROOT),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )
            self.assertEqual(0, python.returncode, python.stderr)
            self.assertEqual(
                (python_home / ".agent-toolkit-install-opencode.json").read_bytes(),
                (shell_home / ".agent-toolkit-install-opencode.json").read_bytes(),
                "global ledgers must be byte-identical",
            )
            self.assertEqual(
                (python_home / ".agent-toolkit-shared-skills.json").read_bytes(),
                (shell_home / ".agent-toolkit-shared-skills.json").read_bytes(),
                "shared ledgers must be byte-identical",
            )


@unittest.skipUnless(shutil.which("pwsh"), "pwsh is not available")
class PowerShellInstallerTests(unittest.TestCase):
    def _pwsh(self, script, *arguments, home=None):
        environment = os.environ.copy()
        if home is not None:
            environment["HOME"] = str(home)
        return subprocess.run(
            ["pwsh", "-NoProfile", "-File", str(script)]
            + [str(item) for item in arguments],
            cwd=str(TOOLKIT_ROOT),
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )

    def test_repository_install_dry_run_then_apply(self):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / "target"
            preview = self._pwsh(INSTALL_PS1, "--platform", "opencode", "--scope", "repository", "--target", target)
            self.assertEqual(0, preview.returncode, preview.stderr)
            self.assertIn("Dry run only", preview.stdout)
            self.assertFalse(target.exists())

            apply = self._pwsh(
                INSTALL_PS1,
                "--platform", "opencode",
                "--scope", "repository",
                "--target", target,
                "--apply",
            )
            self.assertEqual(0, apply.returncode, apply.stderr)
            self.assertTrue((target / ".agent-toolkit-install.json").is_file())

            uninstall = self._pwsh(
                UNINSTALL_PS1,
                "--scope", "repository",
                "--target", target,
                "--apply",
            )
            self.assertEqual(0, uninstall.returncode, uninstall.stderr)
            self.assertFalse((target / ".agent-toolkit-install.json").exists())

    def test_global_install_matches_shell_installer(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            ps_home = root / "ps-home"
            sh_home = root / "sh-home"
            ps_home.mkdir()
            sh_home.mkdir()
            instruction = ps_home / ".config" / "opencode" / "AGENTS.md"
            instruction.parent.mkdir(parents=True)
            instruction.write_text("user line\n", encoding="utf-8")
            sh_instruction = sh_home / ".config" / "opencode" / "AGENTS.md"
            sh_instruction.parent.mkdir(parents=True)
            sh_instruction.write_text("user line\n", encoding="utf-8")

            ps = self._pwsh(INSTALL_PS1, "--platform", "opencode", "--apply", home=ps_home)
            self.assertEqual(0, ps.returncode, ps.stderr)
            self.assertEqual(
                0,
                run_sh(INSTALL_SH, "--platform", "opencode", "--apply", home=sh_home).returncode,
            )
            self.assertEqual(
                (sh_home / ".agent-toolkit-install-opencode.json").read_bytes(),
                (ps_home / ".agent-toolkit-install-opencode.json").read_bytes(),
            )
            self.assertEqual(
                (sh_home / ".agent-toolkit-shared-skills.json").read_bytes(),
                (ps_home / ".agent-toolkit-shared-skills.json").read_bytes(),
            )
            self.assertEqual(
                sh_instruction.read_bytes(),
                instruction.read_bytes(),
            )

            uninstall = self._pwsh(
                UNINSTALL_PS1, "--scope", "global", "--platform", "opencode", "--apply", home=ps_home
            )
            self.assertEqual(0, uninstall.returncode, uninstall.stderr)
            # Same trailing-separator tolerance as the shell installer test.
            text = instruction.read_text(encoding="utf-8")
            self.assertTrue(text.startswith("user line\n"))
            self.assertNotIn("agent-toolkit", text)
            # Only the user's own instruction file may remain (plus pwsh's
            # own .cache/.local telemetry dirs).
            remaining = [
                path
                for path in ps_home.rglob("*")
                if path.is_file()
                and ".cache" not in path.parts
                and ".local" not in path.parts
                and path != instruction
            ]
            self.assertEqual([], remaining)


if __name__ == "__main__":
    unittest.main()
