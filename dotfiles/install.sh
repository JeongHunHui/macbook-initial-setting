#!/usr/bin/env bash
# 터미널 설정(tmux, Ghostty, Karabiner, cmux 연동)을 홈 디렉터리에 설치한다.
# 기존 파일이 있으면 .bak-<시각> 으로 옮겨 두고 덮어쓴다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"
# ponytail: gpakosz/.tmux 를 이 커밋에 고정한다. 올리려면 커밋만 바꾸고 patch 가 붙는지 확인
TMUX_COMMIT=87dcd13a28aeb5f18baee630e24b3f5765ae3a4f
INSTALL_TERMINAL="${INSTALL_TERMINAL:-1}"
INSTALL_CODEX="${INSTALL_CODEX:-1}"

backup() { [[ -e "$1" || -L "$1" ]] && mv "$1" "$1.bak-$TS" && echo "   백업: $1.bak-$TS"; return 0; }
put() { mkdir -p "$(dirname "$2")"; backup "$2"; sed "s#__HOME__#$HOME#g" "$1" > "$2"; echo "✅ $2"; }

if [[ "$INSTALL_TERMINAL" == 1 ]]; then
echo "🖥️  tmux (gpakosz/.tmux + 로컬 설정)"
if [[ ! -d "$HOME/.tmux/.git" ]]; then
  backup "$HOME/.tmux"
  git clone -q https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  git -C "$HOME/.tmux" checkout -q "$TMUX_COMMIT"
  git -C "$HOME/.tmux" apply "$DIR/tmux/gpakosz.patch"
fi
[[ "$(readlink "$HOME/.tmux.conf" 2>/dev/null)" == "$HOME/.tmux/.tmux.conf" ]] || { backup "$HOME/.tmux.conf"; ln -s "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"; }
put "$DIR/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
install -m 755 "$DIR/tmux/claude-usage.sh" "$DIR/tmux/resurrect-cleanup.sh" "$HOME/.tmux/"
[[ -d "$HOME/.tmux/plugins/tpm" ]] || git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

PLIST="$HOME/Library/LaunchAgents/com.user.tmux-resurrect-cleanup.plist"
put "$DIR/tmux/com.user.tmux-resurrect-cleanup.plist" "$PLIST"
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "👻 Ghostty"
put "$DIR/ghostty/config" "$HOME/.config/ghostty/config"
mkdir -p "$HOME/Projects"

echo "⌨️  Karabiner"
put "$DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

echo "🔗 cmux 연동"
put "$DIR/bin/cmux-tmux" "$HOME/.local/bin/cmux-tmux"
chmod +x "$HOME/.local/bin/cmux-tmux"
put "$DIR/zsh/tmux.zsh" "$HOME/.config/zsh/tmux.zsh"
LINE='[ -f ~/.config/zsh/tmux.zsh ] && source ~/.config/zsh/tmux.zsh'
grep -qxF "$LINE" "$HOME/.zshrc" 2>/dev/null || echo "$LINE" >> "$HOME/.zshrc"
grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

if [[ "$INSTALL_CODEX" == 1 ]]; then
  echo "🤖 Codex CLI 설정"
  put "$DIR/codex/config.toml" "$HOME/.codex/config.toml"
fi

echo "✅ 선택한 터미널/Codex 설정 완료"
