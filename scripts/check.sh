#!/usr/bin/env bash
# Repository-only checks: no installers, windows, account requests, or user config writes.
set -euo pipefail
cd "$(dirname "$0")/.."
python_bin="${MAC_INIT_PYTHON:-python3}"
if command -v brew >/dev/null 2>&1; then
  candidate="$(brew --prefix)/bin/python3.13"
  [[ ! -x "$candidate" ]] || python_bin="$candidate"
fi
"$python_bin" -c 'import tomllib' || { echo 'Python 3.11 이상이 필요합니다.' >&2; exit 1; }
for script in setup.sh mac-mini-openclaw-setup.sh dotfiles/install.sh dotfiles/bin/mac-init-editor dotfiles/tmux/resurrect-cleanup.sh common-settings/install.sh common-settings/macos/defaults.sh scripts/check.sh; do
  bash -n "$script"
done
for script in dotfiles/bin/cmux-tmux dotfiles/zsh/*.zsh common-settings/zsh/*.zsh; do zsh -n "$script"; done
"$python_bin" - <<'PY'
import ast, json, plistlib, tomllib
from pathlib import Path
for path in Path('.').rglob('*'):
    if not path.is_file() or any(p.startswith('.') or p in ('node_modules', '__pycache__') for p in path.parts):
        continue
    if path.suffix == '.json': json.loads(path.read_text())
    elif path.suffix == '.plist': plistlib.loads(path.read_bytes())
    elif path.suffix == '.toml': tomllib.loads(path.read_text())
    elif path.suffix == '.py' or path.name == 'claude-usage.sh': ast.parse(path.read_text())
print('Shell, JSON, plist, TOML, Python syntax: PASS')
PY
"$python_bin" -m unittest discover -s tests -v
node tests/check-setup-ui.cjs
for script in chrome-tmux-tabs/*.js; do node --check "$script"; done
git diff --check
echo 'Repository checks: PASS'
