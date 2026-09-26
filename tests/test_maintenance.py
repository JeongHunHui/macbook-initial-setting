import importlib.util
from importlib.machinery import SourceFileLoader
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = SourceFileLoader(name, str(ROOT / path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


merge = load('merge_config', 'scripts/merge-codex-config.py')
usage = load('usage', 'dotfiles/tmux/claude-usage.sh')


class InstallTests(unittest.TestCase):
    def setup_run(self, modules, *args):
        return subprocess.run(['bash', str(ROOT / 'setup.sh'), *args],
                              env={**os.environ, 'MAC_INIT_MODULES': modules},
                              capture_output=True, text=True)

    def test_empty_selection_does_nothing(self):
        result = self.setup_run('')
        self.assertEqual(result.returncode, 0)
        self.assertNotIn('Homebrew', result.stdout)

    def test_invalid_selection_fails_before_install(self):
        for selection in ('unknown', 'codex,', ',cli', 'cli,,apps'):
            with self.subTest(selection=selection):
                self.assertEqual(self.setup_run(selection).returncode, 2)

    def test_plan_has_only_selected_dependencies(self):
        result = self.setup_run(' codex ', '--plan')
        self.assertEqual(result.returncode, 0)
        self.assertIn('codex:', result.stdout)
        self.assertNotIn('terminal:', result.stdout)

    def test_merge_preserves_personal_values_and_comments(self):
        original = '# personal\nmodel = "chosen-model"\nmodel_reasoning_effort = "high"\n[tui]\ntheme = "mine"\n[tui.keymap.editor]\nmove_up = "ctrl-p"\n[mcp_servers.mine]\nurl = "https://example.test"\n'
        template = (ROOT / 'dotfiles/codex/config.toml').read_text()
        merged = merge.merge_text(original, template)
        parsed = merge.tomllib.loads(merged)
        self.assertEqual(parsed['model'], 'chosen-model')
        self.assertEqual(parsed['model_reasoning_effort'], 'high')
        self.assertEqual(parsed['mcp_servers']['mine']['url'], 'https://example.test')
        self.assertEqual(parsed['tui']['theme'], 'mine')
        self.assertEqual(parsed['tui']['keymap']['editor']['move_up'], 'up')
        self.assertIn('# personal', merged)
        self.assertEqual(merge.merge_text(merged, template), merged)

    def test_invalid_merge_leaves_file_untouched(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'config.toml'
            path.write_text('broken = [')
            with self.assertRaises(ValueError):
                merge.install(ROOT / 'dotfiles/codex/config.toml', path)
            self.assertEqual(path.read_text(), 'broken = [')

    def test_new_install_creates_parent(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'nested/config.toml'
            merge.install(ROOT / 'dotfiles/codex/config.toml', path)
            self.assertTrue(merge.tomllib.loads(path.read_text())['disable_paste_burst'])


class UsageTests(unittest.TestCase):
    def test_missing_percentage_is_unknown(self):
        out = usage.format_codex_rate_limits({'primary': {'windowDurationMins': 300}})
        self.assertIn('5h:?', out)
        self.assertNotIn('5h:0%', out)

    def test_weekly_primary_is_not_five_hours(self):
        out = usage.format_codex_rate_limits({'primary': {'windowDurationMins': 10080, 'usedPercent': 17}, 'secondary': None})
        self.assertIn('wk:17%', out)
        self.assertIn('5h:-', out)
        self.assertNotIn('wk:0%', out)

    def test_two_windows_from_log(self):
        out = usage.format_codex_rate_limits({'primary': {'window_minutes': 300, 'used_percent': 12}, 'secondary': {'window_minutes': 10080, 'used_percent': 24}})
        self.assertIn('5h:12%', out)
        self.assertIn('wk:24%', out)

    def test_coalesced_app_server_messages(self):
        # A real pipe coalesces several protocol messages in one read.
        # The old TextIOWrapper+select loop could strand a buffered response.
        factory = subprocess.Popen
        server = 'import sys,json,time\njson.loads(sys.stdin.readline())\nprint(json.dumps({"id":0,"result":{}}),flush=True)\nsys.stdin.readline();sys.stdin.readline()\nsys.stdout.write(json.dumps({"method":"notification"})+"\\n"+json.dumps({"id":1,"result":{"rateLimits":{"primary":{"windowDurationMins":10080,"usedPercent":8}}}})+"\\n");sys.stdout.flush()\ntime.sleep(10)'
        def fake(args, **kwargs):
            return factory([os.sys.executable, '-c', server], **kwargs)
        with patch.object(usage.subprocess, 'Popen', side_effect=fake):
            result = usage.fetch_codex_rate_limits()
        self.assertEqual(result['primary']['usedPercent'], 8)

    def test_failure_preserves_snapshot_age(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'cache.json'
            usage.write_cache('wk:10%', path=path, error=True, data_ts=123)
            self.assertEqual(json.loads(path.read_text())['data_ts'], 123)


if __name__ == '__main__':
    unittest.main()
