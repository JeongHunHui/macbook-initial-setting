#!/usr/bin/env bash
# 공통 셸, git, macOS 키보드, 앱 설정을 설치한다. 여러 번 돌려도 된다.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_TAG="$(date +%Y%m%d%H%M%S)-$$"
copy_config() {
  cmp -s "$1" "$2" && return 0
  [[ ! -f "$2" ]] || cp -p "$2" "$2.bak-$BACKUP_TAG"
  cp "$1" "$2"
}

echo "🍺 brew 패키지"
for f in fzf pyenv pyenv-virtualenv gh; do brew list --formula "$f" >/dev/null 2>&1 || brew install "$f"; done
for c in rectangle scroll-reverser raycast; do brew list --cask "$c" >/dev/null 2>&1 || brew install --cask "$c" || true; done

echo "🐚 zsh"
[[ -d "$HOME/.oh-my-zsh" ]] || RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mkdir -p "$HOME/.config/zsh"
copy_config "$DIR/zsh/common.zsh" "$HOME/.config/zsh/common.zsh"
LINE='[ -f ~/.config/zsh/common.zsh ] && source ~/.config/zsh/common.zsh'
touch "$HOME/.zshrc"
grep -qxF "$LINE" "$HOME/.zshrc" || echo "$LINE" >> "$HOME/.zshrc"

echo "🔀 git, gh"
mkdir -p "$HOME/.config/git"
[[ ! -f "$HOME/.config/git/ignore" ]] || cp -p "$HOME/.config/git/ignore" "$HOME/.config/git/ignore.bak-$BACKUP_TAG"
touch "$HOME/.config/git/ignore"
while IFS= read -r pattern || [[ -n "$pattern" ]]; do
  grep -qxF -- "$pattern" "$HOME/.config/git/ignore" || printf '%s\n' "$pattern" >> "$HOME/.config/git/ignore"
done < "$DIR/git/ignore"
if [[ -z "$(git config --global user.name || true)" && -t 0 ]]; then
  read -rp "git 이름: " n; read -rp "git 이메일: " e
  git config --global user.name "$n"; git config --global user.email "$e"
fi
gh alias set co 'pr checkout' --clobber >/dev/null 2>&1 || true

echo "⌨️  macOS"
bash "$DIR/macos/defaults.sh"

echo "🪟 앱 설정"
for p in "$DIR"/apps/*.plist; do
  d="$(basename "$p" .plist)"
  mkdir -p "$HOME/.config/mac-init/backups"
  defaults export "$d" "$HOME/.config/mac-init/backups/$d-$BACKUP_TAG.plist" 2>/dev/null || true
  app_name=""
  case "$d" in
    *Rectangle) app_name="Rectangle" ;;
    *scroll-reverser) app_name="Scroll Reverser" ;;
  esac
  [[ -z "$app_name" ]] || killall "$app_name" 2>/dev/null || true
  # 기존 설정 위에 이 키들만 덮어쓴다 (통째로 바꾸지 않음)
  python3 - "$d" "$p" <<'PY'
import plistlib, subprocess, sys
dom, src = sys.argv[1:]
cur = subprocess.run(["defaults", "export", dom, "-"], capture_output=True).stdout
merged = plistlib.loads(cur) if cur else {}
merged.update(plistlib.load(open(src, "rb")))
subprocess.run(["defaults", "import", dom, "-"], input=plistlib.dumps(merged), check=True)
PY
  echo "✅ $d"
done
defaults write com.raycast.macos raycastGlobalHotkey "Command-49"
open -a Rectangle 2>/dev/null || true
open -a "Scroll Reverser" 2>/dev/null || true

echo "⌨️  Karabiner 추가 규칙 (켜려면 Karabiner > Complex Modifications > Add rule)"
mkdir -p "$HOME/.config/karabiner/assets/complex_modifications"
for rule in "$DIR/karabiner/"*.json; do
  copy_config "$rule" "$HOME/.config/karabiner/assets/complex_modifications/$(basename "$rule")"
done

echo "✅ 공통 설정 완료. 새 터미널을 열면 셸 설정이 적용된다."
