"""Tests that AGENT-INSTALL.md stays true to the code it describes.

The install protocol is prose executed by a language model, so a drifted
sentence is a broken installer with no stack trace. Every constant the document
quotes is asserted against its definition here.
"""

import importlib.util
import json
import re
import unittest
from pathlib import Path


TOOLKIT_ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("agent_toolkit", TOOLKIT_ROOT / "scripts" / "toolkit.py")
toolkit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(toolkit)

PROTOCOL = (TOOLKIT_ROOT / "AGENT-INSTALL.md").read_text(encoding="utf-8")
MANIFEST = toolkit.load_json(TOOLKIT_ROOT / "manifest.json")


class ProtocolConstantsTests(unittest.TestCase):
    def test_filenames_are_quoted_exactly(self):
        for value in (
            toolkit.PACKAGE_METADATA_NAME,
            toolkit.FILES_MANIFEST_NAME,
            toolkit.LEDGER_NAME,
            toolkit.SHARED_SKILLS_LEDGER_NAME,
        ):
            with self.subTest(value=value):
                self.assertIn("`{0}`".format(value), PROTOCOL)

    def test_global_ledger_name_pattern_is_documented(self):
        rendered = toolkit.ledger_name("global", "<platform>")
        self.assertIn("`{0}`".format(rendered), PROTOCOL)

    def test_instruction_block_markers_are_quoted_exactly(self):
        self.assertIn(toolkit.INSTRUCTION_BLOCK_BEGIN, PROTOCOL)
        self.assertIn(toolkit.INSTRUCTION_BLOCK_END, PROTOCOL)

    def test_default_scope_and_bundle_match_the_manifest(self):
        policy = MANIFEST["install_policy"]
        self.assertEqual(toolkit.DEFAULT_SCOPE, policy["default_scope"])
        self.assertIn("| Default scope | `{0}` |".format(policy["default_scope"]), PROTOCOL)
        self.assertIn("| Default bundle | `{0}` |".format(policy["default_bundle"]), PROTOCOL)

    def test_every_platform_is_listed_and_no_extras_are_invented(self):
        documented = set(re.findall(r"^\| `([a-z-]+)` \| `", PROTOCOL, re.MULTILINE))
        self.assertEqual(set(MANIFEST["platforms"]), documented)

    def test_bundle_sizes_are_accurate(self):
        for bundle in MANIFEST["bundles"]:
            size = len(toolkit.bundle_skill_names(MANIFEST, bundle))
            with self.subTest(bundle=bundle):
                self.assertRegex(
                    PROTOCOL,
                    r"\| `{0}` \| {1} \|".format(re.escape(bundle), size),
                    "bundle {0} should be documented as holding {1} skills".format(bundle, size),
                )

    def test_documented_paths_match_the_adapters(self):
        for platform in MANIFEST["platforms"]:
            adapter = toolkit.load_json(TOOLKIT_ROOT / "platforms" / platform / "adapter.json")
            row = next(
                line for line in PROTOCOL.splitlines()
                if line.startswith("| `{0}` |".format(platform))
            )
            with self.subTest(platform=platform):
                self.assertIn("`{0}`".format(adapter["skill_path"]), row)
                self.assertIn("`~/{0}`".format(adapter["global"]["instruction_path"]), row)
                self.assertIn("`~/{0}`".format(adapter["global"]["skill_path"]), row)
                command = adapter["global"].get("command_path")
                if command:
                    self.assertIn("`~/{0}`".format(command), row)


class FilesManifestTests(unittest.TestCase):
    def _packages(self):
        dist = TOOLKIT_ROOT / "dist"
        for platform in sorted(MANIFEST["platforms"]):
            yield "repository", platform, dist / platform
            yield "global", platform, dist / "global" / platform

    def test_every_package_ships_a_files_manifest_that_matches_its_contents(self):
        for scope, platform, package in self._packages():
            with self.subTest(scope=scope, platform=platform):
                path = package / toolkit.FILES_MANIFEST_NAME
                self.assertTrue(path.is_file(), "missing {0}".format(path))
                entries = toolkit.load_json(path)
                self.assertEqual(1, entries["schema_version"])
                listed = {item["path"]: item["sha256"] for item in entries["files"]}
                actual = toolkit.package_files(package, include_metadata=False)
                self.assertEqual(actual, listed, "files manifest does not match the package")

    def test_roles_cover_the_files_that_need_special_handling(self):
        """A shared skill installed as a regular file would break refcounting."""
        for scope, platform, package in self._packages():
            with self.subTest(scope=scope, platform=platform):
                entries = toolkit.load_json(package / toolkit.FILES_MANIFEST_NAME)
                roles = {item["path"]: item["role"] for item in entries["files"]}
                self.assertLessEqual(
                    set(roles.values()),
                    {"regular", "shared-skill", "instruction-block", "command"},
                )
                if scope != "global":
                    self.assertEqual({"regular"}, set(roles.values()))
                    continue
                metadata = toolkit.load_json(package / toolkit.PACKAGE_METADATA_NAME)
                for relative in metadata["shared_skill_files"]:
                    self.assertEqual("shared-skill", roles[relative])
                self.assertEqual("instruction-block", roles[metadata["instruction_path"]])

    def test_manifest_lets_an_agent_fetch_a_package_without_git(self):
        """The listing must be self-sufficient: no walking, no guessing."""
        package = TOOLKIT_ROOT / "dist" / "opencode"
        entries = toolkit.load_json(package / toolkit.FILES_MANIFEST_NAME)
        for item in entries["files"]:
            toolkit.safe_relative_path(item["path"])
            self.assertRegex(item["sha256"], r"^[0-9a-f]{64}$")
        self.assertIn("AGENTS.md", {item["path"] for item in entries["files"]})


class RemovedInstallerTests(unittest.TestCase):
    def test_shell_entrypoints_are_gone(self):
        """3.0.0 installs by prompt; the 2.0.0 scripts live on release/2.0.0."""
        for relative in (
            "install.sh", "install.ps1", "uninstall.sh", "uninstall.ps1",
            "scripts/install.sh", "scripts/install.ps1",
            "scripts/uninstall.sh", "scripts/uninstall.ps1",
            "scripts/setup.sh", "scripts/toolkit-lib.sh",
        ):
            with self.subTest(relative=relative):
                self.assertFalse((TOOLKIT_ROOT / relative).exists())

    def test_readmes_point_agents_at_the_protocol(self):
        for name in ("README.md", "README.id.md"):
            with self.subTest(name=name):
                text = (TOOLKIT_ROOT / name).read_text(encoding="utf-8")
                self.assertIn("AGENT-INSTALL.md", text)
                self.assertIn("coderbuzz/agent-toolkit", text)


if __name__ == "__main__":
    unittest.main()
