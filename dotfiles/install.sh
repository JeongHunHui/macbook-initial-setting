#!/usr/bin/env bash
# 터미널 설정(tmux, Ghostty, Karabiner)을 홈 디렉터리에 설치한다.
# 기존 파일이 있으면 .bak-<시각> 으로 옮겨 두고 덮어쓴다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"
# ponytail: gpakosz/.tmux 를 이 커밋에 고정한다. 올리려면 커밋만 바꾸고 patch 가 붙는지 확인
TMUX_COMMIT=87dcd13a28aeb5f18baee630e24b3f5765ae3a4f

backup() { [[ -e "$1" || -L "$1" ]] && mv "$1" "$1.bak-$TS" && echo "   백업: $1.bak-$TS"; return 0; }
put() { mkdir -p "$(dirname "$2")"; backup "$2"; sed "s#__HOME__#$HOME#g" "$1" > "$2"; echo "✅ $2"; }

echo "🖥️  tmux (gpakosz/.tmux + 로컬 설정)"
if [[ ! -d "$HOME/.tmux/.git" ]]; then
  backup "$HOME/.tmux"
  git clone -q https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  git -C "$HOME/.tmux" checkout -q "$TMUX_COMMIT"
fi
if git -C "$HOME/.tmux" apply --check "$DIR/tmux/gpakosz.patch" 2>/dev/null; then
  git -C "$HOME/.tmux" apply "$DIR/tmux/gpakosz.patch"
elif git -C "$HOME/.tmux" apply --reverse --check "$DIR/tmux/gpakosz.patch" 2>/dev/null; then
  echo "   tmux 패치 이미 적용됨"
else
  echo "❌ tmux 패치를 적용할 수 없습니다. ~/.tmux 상태와 기준 커밋을 확인하세요." >&2
  exit 1
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

put "$DIR/zsh/tmux.zsh" "$HOME/.config/zsh/tmux.zsh"
LINE='[ -f ~/.config/zsh/tmux.zsh ] && source ~/.config/zsh/tmux.zsh'
grep -qxF "$LINE" "$HOME/.zshrc" 2>/dev/null || echo "$LINE" >> "$HOME/.zshrc"
grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"

echo "✅ 터미널 설정 완료. tmux 는 처음 켤 때 플러그인을 자동으로 받는다."
