"""Tests for global (home-directory) scope installation."""

import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location(
    "agent_toolkit_global", TOOLKIT_ROOT / "scripts" / "toolkit.py"
)
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)

PLATFORMS = ("opencode", "codex", "claude-code", "github-copilot", "omp", "gemini")


class GlobalArgs:
    def __init__(self, platform, target, apply=False, scope="global", bundle="core"):
        self.platform = platform
        self.target = target
        self.apply = apply
        self.scope = scope
        self.bundle = bundle
        self.package = None


class GlobalExportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_shared_skills_use_common_agents_directory(self):
        package = self.root / "opencode"
        metadata = toolkit.export_to_global_directory("opencode", "core", package)
        self.assertEqual("global", metadata["scope"])
        self.assertTrue(metadata["shared_skill_files"])
        for relative in metadata["shared_skill_files"]:
            self.assertTrue(relative.startswith(".agents/skills/"))

    def test_codex_global_uses_toml_merge_file(self):
        package = self.root / "codex"
        metadata = toolkit.export_to_global_directory("codex", "core", package)
        self.assertEqual(1, len(metadata["merge_files"]))
        entry = metadata["merge_files"][0]
        self.assertEqual(".codex/config.toml", entry["target"])
        merge_body = (package / entry["merge_file"]).read_text(encoding="utf-8")
        self.assertIn("[agents.code-reviewer]", merge_body)
        self.assertIn(toolkit.CODEX_BLOCK_BEGIN, merge_body)

    def test_non_codex_global_writes_agent_files(self):
        package = self.root / "claude-code"
        toolkit.export_to_global_directory("claude-code", "core", package)
        self.assertTrue((package / ".claude/agents/code-reviewer.md").is_file())
        instruction = (package / ".claude/CLAUDE.md").read_text(encoding="utf-8")
        self.assertNotIn("@AGENTS.md", instruction)
        self.assertIn("Agent Toolkit", instruction)

    def test_global_instruction_metadata_records_path(self):
        package = self.root / "opencode"
        metadata = toolkit.export_to_global_directory("opencode", "core", package)
        self.assertEqual(".config/opencode/AGENTS.md", metadata["instruction_path"])


class GlobalInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def _install(self, platform, apply=True):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return toolkit.command_install(GlobalArgs(platform, self.home, apply=apply))

    def _uninstall(self, platform, apply=True):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return toolkit.command_uninstall(GlobalArgs(platform, self.home, apply=apply))

    def test_all_platforms_install_and_uninstall_cleanly(self):
        for platform in PLATFORMS:
            self.assertEqual(0, self._install(platform))
        skills_dir = self.home / ".agents/skills"
        self.assertTrue(skills_dir.is_dir())
        for platform in PLATFORMS:
            ledger = self.home / toolkit.ledger_name("global", platform)
            self.assertTrue(ledger.is_file(), platform)
        for platform in PLATFORMS:
            self.assertIn(self._uninstall(platform), (0, 2))
        remaining = [path for path in self.home.rglob("*") if path.is_file()]
        self.assertEqual([], remaining)

    def test_opencode_global_generates_slash_commands(self):
        self._install("opencode")
        commands_dir = self.home / ".config/opencode/commands"
        commands = sorted(path.name for path in commands_dir.glob("*.md"))
        self.assertGreaterEqual(len(commands), 20)
        self.assertIn("start.md", commands)
        start = (commands_dir / "start.md").read_text(encoding="utf-8")
        self.assertIn("---", start)
        self.assertIn("description:", start)
        self.assertIn("`start`", start)
        self._uninstall("opencode")
        self.assertFalse(commands_dir.exists())

    def test_shared_skills_are_reference_counted(self):
        self._install("opencode")
        self._install("claude-code")
        ledger = toolkit.load_json(self.home / toolkit.SHARED_SKILLS_LEDGER_NAME)
        skill = ".agents/skills/start/SKILL.md"
        self.assertEqual(["claude-code", "opencode"], sorted(ledger["files"][skill]["owners"]))
        self._uninstall("opencode")
        self.assertTrue((self.home / skill).is_file())
        ledger = toolkit.load_json(self.home / toolkit.SHARED_SKILLS_LEDGER_NAME)
        self.assertEqual(["claude-code"], ledger["files"][skill]["owners"])
        self._uninstall("claude-code")
        self.assertFalse((self.home / skill).exists())

    def test_second_install_adopts_existing_shared_skill(self):
        self._install("opencode")
        actions, conflicts = toolkit.plan_shared_skills(
            *self._codex_shared_args()
        )
        self.assertFalse(conflicts)
        self.assertTrue(any(action == "shared-adopt" for action, _ in actions))

    def _codex_shared_args(self):
        package = self.root / "codex-pkg"
        metadata = toolkit.export_to_global_directory("codex", "core", package)
        shared = set(metadata["shared_skill_files"])
        return package, self.home, "codex", shared

    def test_user_modified_shared_skill_blocks_reinstall(self):
        self._install("opencode")
        skill = self.home / ".agents/skills/start/SKILL.md"
        skill.write_text(skill.read_text(encoding="utf-8") + "\nuser edit\n", encoding="utf-8")
        package, home, platform, shared = self._codex_shared_args()
        _actions, conflicts = toolkit.plan_shared_skills(package, home, platform, shared)
        self.assertTrue(any("User-modified shared skill" in conflict for conflict in conflicts))

    def test_preview_does_not_mutate_home(self):
        self.assertEqual(0, self._install("opencode", apply=False))
        self.assertEqual([], [path for path in self.home.rglob("*") if path.is_file()])


class CodexMergeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.package = self.root / "codex"
        self.metadata = toolkit.export_to_global_directory("codex", "core", self.package)
        self.entry = self.metadata["merge_files"][0]

    def tearDown(self):
        self.temp.cleanup()

    def _merge(self):
        return toolkit.apply_codex_merge(
            self.package, self.home, self.entry["merge_file"], self.entry["target"]
        )

    def test_merge_creates_config_when_absent(self):
        action = self._merge()
        self.assertEqual("codex-merge-create", action)
        config = self.home / ".codex/config.toml"
        self.assertIn("[agents.code-reviewer]", config.read_text(encoding="utf-8"))

    def test_merge_preserves_user_content_and_is_idempotent(self):
        config = self.home / ".codex/config.toml"
        config.parent.mkdir(parents=True, exist_ok=True)
        config.write_text('model = "gpt-5"\n', encoding="utf-8")
        self.assertEqual("codex-merge-append", self._merge())
        content = config.read_text(encoding="utf-8")
        self.assertIn('model = "gpt-5"', content)
        self.assertIn(toolkit.CODEX_BLOCK_BEGIN, content)
        self.assertEqual("codex-merge-unchanged", self._merge())

    def test_unmerge_removes_block_but_keeps_user_content(self):
        config = self.home / ".codex/config.toml"
        config.parent.mkdir(parents=True, exist_ok=True)
        config.write_text('model = "gpt-5"\n', encoding="utf-8")
        self._merge()
        action = toolkit.apply_codex_unmerge(self.home, self.entry["target"])
        self.assertEqual("codex-unmerge-remove", action)
        content = config.read_text(encoding="utf-8")
        self.assertIn('model = "gpt-5"', content)
        self.assertNotIn(toolkit.CODEX_BLOCK_BEGIN, content)

    def test_unmerge_deletes_config_created_only_for_block(self):
        self._merge()
        toolkit.apply_codex_unmerge(self.home, self.entry["target"])
        self.assertFalse((self.home / ".codex/config.toml").exists())

    def test_malformed_block_is_rejected(self):
        config = self.home / ".codex/config.toml"
        config.parent.mkdir(parents=True, exist_ok=True)
        config.write_text(toolkit.CODEX_BLOCK_BEGIN + "\nbroken\n", encoding="utf-8")
        with self.assertRaisesRegex(toolkit.ToolkitError, "Malformed managed block"):
            toolkit.plan_codex_merge(
                self.package, self.home, self.entry["merge_file"], self.entry["target"]
            )


class InstructionBlockTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.package = self.root / "opencode"
        self.metadata = toolkit.export_to_global_directory("opencode", "core", self.package)
        self.instruction = self.metadata["instruction_path"]

    def tearDown(self):
        self.temp.cleanup()

    def _apply(self):
        return toolkit.apply_instruction_block(self.package, self.home, self.instruction)

    def test_block_created_when_file_absent(self):
        action = self._apply()
        self.assertEqual("instruction-create", action)
        text = (self.home / self.instruction).read_text(encoding="utf-8")
        self.assertIn(toolkit.INSTRUCTION_BLOCK_BEGIN, text)

    def test_block_appends_to_existing_user_file(self):
        user_file = self.home / self.instruction
        user_file.parent.mkdir(parents=True, exist_ok=True)
        user_file.write_text("My personal guidance for this machine.\n", encoding="utf-8")
        self.assertEqual("instruction-append", self._apply())
        text = user_file.read_text(encoding="utf-8")
        self.assertIn("My personal guidance", text)
        self.assertIn(toolkit.INSTRUCTION_BLOCK_BEGIN, text)
        self.assertIn("Agent Toolkit", text)

    def test_block_is_idempotent_and_updates(self):
        user_file = self.home / self.instruction
        user_file.parent.mkdir(parents=True, exist_ok=True)
        user_file.write_text("user line\n", encoding="utf-8")
        self.assertEqual("instruction-append", self._apply())
        self.assertEqual("instruction-unchanged", self._apply())

    def test_unblock_removes_only_managed_block(self):
        user_file = self.home / self.instruction
        user_file.parent.mkdir(parents=True, exist_ok=True)
        user_file.write_text("user line\n", encoding="utf-8")
        self._apply()
        action = toolkit.apply_instruction_unblock(self.home, self.instruction)
        self.assertEqual("instruction-unblock-remove", action)
        text = user_file.read_text(encoding="utf-8")
        self.assertIn("user line", text)
        self.assertNotIn(toolkit.INSTRUCTION_BLOCK_BEGIN, text)

    def test_unblock_deletes_file_if_only_block_present(self):
        self._apply()
        action = toolkit.apply_instruction_unblock(self.home, self.instruction)
        self.assertEqual("instruction-unblock-remove", action)
        self.assertFalse((self.home / self.instruction).exists())

    def test_block_updates_when_source_changes(self):
        user_file = self.home / self.instruction
        user_file.parent.mkdir(parents=True, exist_ok=True)
        user_file.write_text("user line\n", encoding="utf-8")
        self._apply()
        planned, conflicts = toolkit.plan_instruction_block(self.package, self.home, self.instruction)
        self.assertEqual("instruction-unchanged", planned[0])
        self.assertEqual([], conflicts)
        # Simulate a toolkit version change by rewriting the package body.
        body = (self.package / self.instruction).read_text(encoding="utf-8")
        (self.package / self.instruction).write_text(
            body + "\n<!-- updated source -->\n", encoding="utf-8"
        )
        planned, conflicts = toolkit.plan_instruction_block(self.package, self.home, self.instruction)
        self.assertEqual("instruction-update", planned[0])
        self.assertEqual([], conflicts)
        self.assertEqual("instruction-update", toolkit.apply_instruction_block(self.package, self.home, self.instruction))
        text = user_file.read_text(encoding="utf-8")
        self.assertIn("user line", text)
        self.assertIn("updated source", text)

    def test_edits_inside_block_are_replaced_on_update(self):
        user_file = self.home / self.instruction
        user_file.parent.mkdir(parents=True, exist_ok=True)
        user_file.write_text("user line\n", encoding="utf-8")
        self._apply()
        text = user_file.read_text(encoding="utf-8")
        begin = text.find(toolkit.INSTRUCTION_BLOCK_BEGIN)
        end = text.find(toolkit.INSTRUCTION_BLOCK_END, begin)
        modified = text[:end] + " user edit inside block\n" + text[end:]
        user_file.write_text(modified, encoding="utf-8")
        # A reinstall overwrites the managed block (including user edits inside it).
        planned, conflicts = toolkit.plan_instruction_block(self.package, self.home, self.instruction)
        self.assertEqual("instruction-update", planned[0])
        self.assertEqual([], conflicts)
        toolkit.apply_instruction_block(self.package, self.home, self.instruction)
        result = user_file.read_text(encoding="utf-8")
        self.assertIn("user line", result)
        self.assertNotIn("user edit inside block", result)


class OmpPlatformTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def test_omp_registered_as_platform(self):
        manifest = toolkit.load_json(toolkit.TOOLKIT_ROOT / "manifest.json")
        self.assertIn("omp", manifest["platforms"])
        self.assertIn("omp", toolkit.VALID_PLATFORMS)

    def test_omp_agent_renderer_is_omp_compatible(self):
        definitions = toolkit.load_json(
            toolkit.TOOLKIT_ROOT / toolkit.load_json(toolkit.TOOLKIT_ROOT / "manifest.json")["canonical"]["agents"]
        )
        agent = next(a for a in definitions["agents"] if a["id"] == "code-reviewer")
        rendered = toolkit.render_omp_agent(agent, "0.1.0", "abc123")
        self.assertIn("name: code-reviewer", rendered)
        self.assertIn("description:", rendered)
        self.assertIn("tools:", rendered)
        # OMP does not use OpenCode's schema.
        self.assertNotIn("mode: subagent", rendered)
        self.assertNotIn("permission:", rendered)

    def test_omp_global_export_layout(self):
        package = self.root / "omp"
        metadata = toolkit.export_to_global_directory("omp", "core", package)
        self.assertEqual("global", metadata["scope"])
        self.assertTrue((package / ".omp/agent/agents/code-reviewer.md").is_file())
        instruction = (package / ".omp/agent/AGENTS.md").read_text(encoding="utf-8")
        self.assertNotIn("@AGENTS.md", instruction)
        self.assertIn("Agent Toolkit", instruction)
        self.assertTrue(metadata["shared_skill_files"])
        for relative in metadata["shared_skill_files"]:
            self.assertTrue(relative.startswith(".agents/skills/"))

    def test_omp_repo_export_layout(self):
        package = self.root / "omp-repo"
        toolkit.export_to_directory("omp", "core", package)
        self.assertTrue((package / ".omp/agents/code-reviewer.md").is_file())
        instruction = (package / ".omp/AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("Agent Toolkit", instruction)
        self.assertTrue((package / ".omp/skills/start/SKILL.md").is_file())

    def test_omp_global_install_and_uninstall_clean(self):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(0, toolkit.command_install(_OmpArgs("omp", self.home, apply=True)))
        self.assertTrue((self.home / ".omp/agent/agents/code-reviewer.md").is_file())
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            rc = toolkit.command_uninstall(_OmpArgs("omp", self.home, apply=True))
        self.assertIn(rc, (0, 2))
        remaining = [p for p in self.home.rglob("*") if p.is_file()]
        self.assertEqual([], remaining)


class _OmpArgs:
    def __init__(self, platform, target, apply=False, scope="global", bundle="core"):
        self.platform = platform
        self.target = target
        self.apply = apply
        self.scope = scope
        self.bundle = bundle
        self.package = None


if __name__ == "__main__":
    unittest.main()
