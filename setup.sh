#!/usr/bin/env bash
set -euo pipefail

echo "=== 맥북 환경 설정 ==="

# 0) sudo 인증
sudo -v || true

# 1) 부팅음 끄기 (Apple Silicon 일부 제한 가능)
if ! sudo nvram StartupMute=%01 2>/dev/null; then
  echo "⚠️  부팅음 설정(nvram) 실패 또는 제한"
else
  echo "🔇 부팅음 끔 ✅"
fi

# 2) Dock 위치 오른쪽
defaults write com.apple.dock orientation right && killall Dock >/dev/null 2>&1 || true
echo "📌 Dock 위치: 오른쪽 ✅"

# 3) 트랙패드 '탭하여 클릭하기' ON
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
killall SystemUIServer >/dev/null 2>&1 || true
echo "🖱️ 탭하여 클릭하기: ON ✅"

# ---------------------------
# Homebrew 설치/업데이트
# ---------------------------
echo "🍺 Homebrew 점검..."
if ! command -v brew >/dev/null 2>&1; then
  echo "➡️  Homebrew 미설치: 설치 진행"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew 설치됨"
fi
brew update

# ---------------------------
# 헬퍼 함수
# ---------------------------
is_formula_installed() { brew list --formula | grep -qx "$1"; }
is_cask_installed()    { brew list --cask    | grep -qx "$1"; }
is_formula_available() { brew info "$1"       >/dev/null 2>&1; }
is_cask_available()    { brew info --cask "$1" >/dev/null 2>&1; }

install_formula() {
  local name="$1"
  if is_formula_installed "$name"; then
    echo "✅ (설치됨) $name"
  else
    if is_formula_available "$name"; then :; fi # shellcheck용
    if is_formula_available "$name"; then
      echo "⬇️  설치: $name"
      brew install "$name" || { echo "❌ 설치 실패: $name"; return 1; }
      echo "✅ 완료: $name"
    else
      echo "❌ 설치 불가(찾을 수 없음): $name"
    fi
  fi
}

install_cask() {
  local token="$1"
  if is_cask_installed "$token"; then
    echo "✅ (설치됨) $token"
  else
    if is_cask_available "$token"; then
      echo "⬇️  설치: $token (cask)"
      if out="$(brew install --cask "$token" 2>&1)"; then
        echo "✅ 완료: $token"
      else
        if echo "$out" | grep -q "already an App at '/Applications/"; then
          echo "⏭️  스킵(/Applications에 이미 존재): $token"
        else
          echo "❌ 설치 실패: $token"
          echo "   └─ 로그: $out"
        fi
      fi
    else
      echo "❌ 설치 불가(찾을 수 없음): $token"
    fi
  fi
}

# ---------------------------
# 설치 대상
# ---------------------------

# 최신 python(=python3) 버전 토큰 사용 — 현재 3.13 제공
FORMULAS=(
  "git"
  "python@3.13"
  "node"
  "fzf"
  "tmux"
  "gh"
)

CASKS=(
  "google-chrome"
  "figma"
  "slack"
  "notion"
  "obsidian"
  "scroll-reverser"
  "rectangle"
  "raycast"
  "visual-studio-code"
  "intellij-idea"   # Ultimate(유료)
  "pycharm"         # Professional(유료)
  "docker"          # Docker Desktop
  "postman"
  "warp"
  "ghostty"
  "cmux"
  "karabiner-elements"
  "font-jetbrains-mono"
)

echo
echo "=============================="
echo "🔧 CLI 패키지 설치 (brew install)"
echo "=============================="
for formula in "${FORMULAS[@]}"; do
  install_formula "$formula"
done

echo
echo "=============================="
echo "🧩 GUI 앱 설치 (brew install --cask)"
echo "=============================="
for cask in "${CASKS[@]}"; do
  install_cask "$cask"
done

# ---------------------------
# Dock 고정 (연관배열 제거, value 배열만 순회)
# ---------------------------
echo
echo "📌 Dock 고정 작업 시작..."

# 여기에 고정할 앱 경로를 나열 — 존재하면 추가, 없으면 스킵
DOCK_APPS=(
  "/Applications/Google Chrome.app"
  "/Applications/Figma.app"
  "/Applications/Slack.app"
  "/Applications/Notion.app"
  "/Applications/Obsidian.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/IntelliJ IDEA.app"
  "/Applications/PyCharm.app"
  "/Applications/Docker.app"
  "/Applications/Postman.app"
  "/Applications/Warp.app"
  "/Applications/Ghostty.app"
)

dock_has_app() {
  local app="$1"
  defaults read com.apple.dock persistent-apps 2>/dev/null | grep -F "$app" >/dev/null 2>&1
}
dock_add_app() {
  local app_path="$1"
  /usr/bin/defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${app_path}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
}

for app_path in "${DOCK_APPS[@]}"; do
  if [[ -d "$app_path" ]]; then
    if dock_has_app "$app_path"; then
      echo "⏭️  이미 Dock에 있음: $(basename "$app_path")"
    else
      dock_add_app "$app_path"
      echo "📌 Dock 고정: $(basename "$app_path")"
    fi
  else
    echo "⚠️  앱 경로 없음(설치 안 됐을 수 있음): $app_path"
  fi
done

killall Dock >/dev/null 2>&1 || true
echo "✅ Dock 고정 완료"

# ---------------------------
# Claude Code 설치
# ---------------------------
echo
echo "🤖 Claude Code 설치..."
if command -v claude >/dev/null 2>&1; then
  echo "✅ Claude Code 이미 설치됨"
else
  curl -fsSL https://claude.ai/install.sh | bash
  echo "✅ Claude Code 설치 완료"
fi

# ---------------------------
# Oh My Tmux 설치 및 설정
# ---------------------------
echo
echo "🖥️ Oh My Tmux 설치..."
if [[ -d "$HOME/.tmux" ]]; then
  echo "✅ Oh My Tmux 이미 설치됨"
else
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  echo "✅ Oh My Tmux 설치 완료"
fi

echo "📝 tmux.conf.local 설정..."
cat > "$HOME/.tmux.conf.local" << 'TMUXEOF'
# : << 'EOF'
# Oh my tmux!
# https://github.com/gpakosz/.tmux

# -- bindings ------------------------------------------------------------------
tmux_conf_preserve_stock_bindings=false

# -- session creation ----------------------------------------------------------
tmux_conf_new_session_prompt=false
tmux_conf_new_session_retain_current_path=false

# -- windows & pane creation ---------------------------------------------------
tmux_conf_new_window_retain_current_path=false
tmux_conf_new_window_reconnect_ssh=false
tmux_conf_new_pane_retain_current_path=true
tmux_conf_new_pane_reconnect_ssh=false

# -- display -------------------------------------------------------------------
tmux_conf_24b_colour=auto

# -- theming -------------------------------------------------------------------
tmux_conf_theme=enabled

# default theme
tmux_conf_theme_colour_1="#080808"    # dark gray
tmux_conf_theme_colour_2="#303030"    # gray
tmux_conf_theme_colour_3="#8a8a8a"    # light gray
tmux_conf_theme_colour_4="#00afff"    # light blue
tmux_conf_theme_colour_5="#ffff00"    # yellow
tmux_conf_theme_colour_6="#080808"    # dark gray
tmux_conf_theme_colour_7="#e4e4e4"    # white
tmux_conf_theme_colour_8="#080808"    # dark gray
tmux_conf_theme_colour_9="#ffff00"    # yellow
tmux_conf_theme_colour_10="#ff00af"   # pink
tmux_conf_theme_colour_11="#5fff00"   # green
tmux_conf_theme_colour_12="#8a8a8a"   # light gray
tmux_conf_theme_colour_13="#e4e4e4"   # white
tmux_conf_theme_colour_14="#080808"   # dark gray
tmux_conf_theme_colour_15="#080808"   # dark gray
tmux_conf_theme_colour_16="#d70000"   # red
tmux_conf_theme_colour_17="#e4e4e4"   # white

# window style
tmux_conf_theme_window_fg="default"
tmux_conf_theme_window_bg="default"
tmux_conf_theme_highlight_focused_pane=false
tmux_conf_theme_focused_pane_bg="$tmux_conf_theme_colour_2"

# pane border style
tmux_conf_theme_pane_border_style=thin
tmux_conf_theme_pane_border="$tmux_conf_theme_colour_2"
tmux_conf_theme_pane_active_border="$tmux_conf_theme_colour_4"
%if #{>=:#{version},3.2}
tmux_conf_theme_pane_active_border="#{?pane_in_mode,$tmux_conf_theme_colour_9,#{?synchronize-panes,$tmux_conf_theme_colour_16,$tmux_conf_theme_colour_4}}"
%endif

# pane indicator colours
tmux_conf_theme_pane_indicator="$tmux_conf_theme_colour_4"
tmux_conf_theme_pane_active_indicator="$tmux_conf_theme_colour_4"

# status line style
tmux_conf_theme_message_fg="$tmux_conf_theme_colour_1"
tmux_conf_theme_message_bg="$tmux_conf_theme_colour_5"
tmux_conf_theme_message_attr="bold"

# status line command style
tmux_conf_theme_message_command_fg="$tmux_conf_theme_colour_5"
tmux_conf_theme_message_command_bg="$tmux_conf_theme_colour_1"
tmux_conf_theme_message_command_attr="bold"

# window modes style
tmux_conf_theme_mode_fg="$tmux_conf_theme_colour_1"
tmux_conf_theme_mode_bg="$tmux_conf_theme_colour_5"
tmux_conf_theme_mode_attr="bold"

# status line style
tmux_conf_theme_status_fg="$tmux_conf_theme_colour_3"
tmux_conf_theme_status_bg="$tmux_conf_theme_colour_1"
tmux_conf_theme_status_attr="none"

# terminal title
tmux_conf_theme_terminal_title="#h ❐ #S ● #I #W"

# window status style
tmux_conf_theme_window_status_fg="$tmux_conf_theme_colour_3"
tmux_conf_theme_window_status_bg="$tmux_conf_theme_colour_1"
tmux_conf_theme_window_status_attr="none"
tmux_conf_theme_window_status_format="#I #W#{?#{||:#{window_bell_flag},#{window_zoomed_flag}}, ,}#{?window_bell_flag,!,}#{?window_zoomed_flag,Z,}"

# window current status style
tmux_conf_theme_window_status_current_fg="$tmux_conf_theme_colour_1"
tmux_conf_theme_window_status_current_bg="$tmux_conf_theme_colour_4"
tmux_conf_theme_window_status_current_attr="bold"
tmux_conf_theme_window_status_current_format="#I #W#{?#{||:#{window_bell_flag},#{window_zoomed_flag}}, ,}#{?window_bell_flag,!,}#{?window_zoomed_flag,Z,}"

# window activity status style
tmux_conf_theme_window_status_activity_fg="default"
tmux_conf_theme_window_status_activity_bg="default"
tmux_conf_theme_window_status_activity_attr="underscore"

# window bell status style
tmux_conf_theme_window_status_bell_fg="$tmux_conf_theme_colour_5"
tmux_conf_theme_window_status_bell_bg="default"
tmux_conf_theme_window_status_bell_attr="blink,bold"

# window last status style
tmux_conf_theme_window_status_last_fg="$tmux_conf_theme_colour_4"
tmux_conf_theme_window_status_last_bg="$tmux_conf_theme_colour_2"
tmux_conf_theme_window_status_last_attr="none"

# status left/right sections separators (plain text, no powerline fonts needed)
tmux_conf_theme_left_separator_main=""
tmux_conf_theme_left_separator_sub="|"
tmux_conf_theme_right_separator_main=""
tmux_conf_theme_right_separator_sub="|"

# status left/right content
tmux_conf_theme_status_left=" ❐ #S "
tmux_conf_theme_status_right=" #{prefix}#{mouse} | CPU:#{cpu_percentage} MEM:#{ram_percentage} "

# status left style
tmux_conf_theme_status_left_fg="$tmux_conf_theme_colour_6,$tmux_conf_theme_colour_7,$tmux_conf_theme_colour_8"
tmux_conf_theme_status_left_bg="$tmux_conf_theme_colour_9,$tmux_conf_theme_colour_10,$tmux_conf_theme_colour_11"
tmux_conf_theme_status_left_attr="bold,none,none"

# status right style
tmux_conf_theme_status_right_fg="#8a8a8a,#e4e4e4,#080808"
tmux_conf_theme_status_right_bg="#080808,#303030,#00afff"
tmux_conf_theme_status_right_attr="none,none,bold"

# indicators
tmux_conf_theme_pairing="⚇"
tmux_conf_theme_pairing_fg="none"
tmux_conf_theme_pairing_bg="none"
tmux_conf_theme_pairing_attr="none"

tmux_conf_theme_prefix="⌨"
tmux_conf_theme_prefix_fg="none"
tmux_conf_theme_prefix_bg="none"
tmux_conf_theme_prefix_attr="none"

tmux_conf_theme_mouse="↗"
tmux_conf_theme_mouse_fg="none"
tmux_conf_theme_mouse_bg="none"
tmux_conf_theme_mouse_attr="none"

tmux_conf_theme_root="!"
tmux_conf_theme_root_fg="none"
tmux_conf_theme_root_bg="none"
tmux_conf_theme_root_attr="bold,blink"

tmux_conf_theme_synchronized="⚏"
tmux_conf_theme_synchronized_fg="none"
tmux_conf_theme_synchronized_bg="none"
tmux_conf_theme_synchronized_attr="none"

# battery
tmux_conf_battery_bar_symbol_full="◼"
tmux_conf_battery_bar_symbol_empty="◻"
tmux_conf_battery_bar_length="auto"
tmux_conf_battery_bar_palette="gradient"
tmux_conf_battery_hbar_palette="gradient"
tmux_conf_battery_vbar_palette="gradient"
tmux_conf_battery_status_charging="↑"
tmux_conf_battery_status_discharging="↓"

# clock
tmux_conf_theme_clock_colour="$tmux_conf_theme_colour_4"
tmux_conf_theme_clock_style="24"

# clipboard
tmux_conf_copy_to_os_clipboard=false

# urlscan
tmux_conf_urlscan_options="--compact --dedupe"

# -- user customizations -------------------------------------------------------

# 윈도우 이름 자동 변경 끄기
set -g allow-rename off #!important

# display a message after toggling mouse support
bind m run "cut -c3- '#{TMUX_CONF}' | sh -s _toggle_mouse" \; display 'mouse #{?#{mouse},on,off}'

# Git branch + current path in status left
set -g status-left "#[fg=colour0,bg=colour11,bold] ❐ #S #[fg=colour11,bg=colour10]#[fg=colour7,bg=colour10]  #(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-') #[fg=colour10,bg=colour5]#[fg=colour0,bg=colour5] #{b:pane_current_path} #[fg=colour5,bg=colour0]" #!important
set -g status-left-length 80 #!important

# -- tpm -----------------------------------------------------------------------
tmux_conf_update_plugins_on_launch=true
tmux_conf_update_plugins_on_reload=true
tmux_conf_uninstall_plugins_on_reload=true

# Plugins
set -g @plugin 'tmux-plugins/tmux-cpu'

# tmux-cpu 설정
set -g @cpu_percentage_format "%3.0f%%"
set -g @ram_percentage_format "%3.0f%%"

# -- custom key bindings -------------------------------------------------------

# Alt+s: 세로 분할 (vertical split, 좌/우)
bind -n M-s split-window -h

# Alt+w: pane 닫기
bind -n M-w kill-pane

# -- mouse copy to clipboard --------------------------------------------------
set -g mouse on #!important
set -g set-clipboard on
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy" #!important
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy" #!important
TMUXEOF
echo "✅ tmux.conf.local 설정 완료"

# tpm 플러그인 자동 설치 트리거
if command -v tmux >/dev/null 2>&1 && [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "📦 tpm 플러그인 설치 트리거..."
  tmux new-session -d -s _tpm_install 2>/dev/null || true
  sleep 2
  tmux kill-session -t _tpm_install 2>/dev/null || true
  echo "✅ tpm 플러그인 설치 트리거 완료"
fi

# ---------------------------
# Ghostty 설정 (Option as Meta)
# ---------------------------
echo
echo "👻 Ghostty 설정..."
mkdir -p "$HOME/.config/ghostty"
GHOSTTY_CONF="$HOME/.config/ghostty/config"
if [ ! -f "$GHOSTTY_CONF" ] || ! grep -q "macos-option-as-alt" "$GHOSTTY_CONF"; then
  echo "macos-option-as-alt = true" >> "$GHOSTTY_CONF"
  echo "✅ Ghostty macos-option-as-alt 설정 완료"
else
  echo "⏭️  Ghostty 설정 이미 존재"
fi

# ---------------------------
# zshrc 앨리어스 추가
# ---------------------------
echo
echo "🐚 zshrc 앨리어스 설정..."
if ! grep -q "alias gc=" "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" << 'ALIASEOF'

# custom aliases
alias gc='git checkout'
alias gr='git rebase'
alias gp='git push'
alias gpo='git pull origin'
alias gs='git stash'
alias c='caffeinate -i claude --dangerously-skip-permissions'
alias t='tmux'
alias cl='clear'
export PATH="$HOME/.local/bin:$PATH"
ALIASEOF
  echo "✅ zshrc 앨리어스 추가 완료"
else
  echo "⏭️  zshrc 앨리어스 이미 설정됨"
fi

# ---------------------------
# Claude Code 설정 파일 생성
# ---------------------------
echo
echo "⚙️ Claude Code 설정..."

# settings.json
mkdir -p "$HOME/.claude"
if [[ ! -f "$HOME/.claude/settings.json" ]]; then
  cat > "$HOME/.claude/settings.json" << 'SETTINGSEOF'
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:raw.githubusercontent.com)",
      "Bash(python3:*)",
      "Bash(find:*)",
      "Skill(commit)",
      "Bash(git commit:*)",
      "Bash(git push)",
      "Bash(git push:*)",
      "Bash(git remote:*)",
      "Bash(gh:*)",
      "Bash(grep:*)",
      "Bash(poetry run python:*)",
      "Bash(poetry run pytest:*)",
      "WebSearch",
      "Bash(claude mcp:*)",
      "Bash(xargs:*)"
    ],
    "defaultMode": "default"
  },
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/hud/omc-hud.mjs"
  },
  "enabledPlugins": {
    "oh-my-claudecode@omc": true,
    "clarify@plugins-for-claude-natives": true,
    "session-wrap@plugins-for-claude-natives": true
  },
  "language": "korean",
  "alwaysThinkingEnabled": true,
  "autoUpdatesChannel": "latest"
}
SETTINGSEOF
  echo "✅ settings.json 생성 완료"
else
  echo "⏭️  settings.json 이미 존재"
fi

# hud/omc-hud.mjs
mkdir -p "$HOME/.claude/hud"
if [[ ! -f "$HOME/.claude/hud/omc-hud.mjs" ]]; then
  cat > "$HOME/.claude/hud/omc-hud.mjs" << 'HUDEOF'
#!/usr/bin/env node
/**
 * OMC HUD - Statusline Script
 * Wrapper that imports from plugin cache or development paths
 */

import { existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

async function main() {
  const home = homedir();

  // 1. Try plugin cache first (marketplace: omc, plugin: oh-my-claudecode)
  const pluginCacheBase = join(home, ".claude/plugins/cache/omc/oh-my-claudecode");
  if (existsSync(pluginCacheBase)) {
    try {
      const versions = readdirSync(pluginCacheBase);
      if (versions.length > 0) {
        const latestVersion = versions.sort().reverse()[0];
        const pluginPath = join(pluginCacheBase, latestVersion, "dist/hud/index.js");
        if (existsSync(pluginPath)) {
          await import(pluginPath);
          return;
        }
      }
    } catch { /* continue */ }
  }

  // 2. Fallback: simple status
  process.stdout.write("OMC");
}

main().catch(() => process.stdout.write("OMC"));
HUDEOF
  echo "✅ omc-hud.mjs 생성 완료"
else
  echo "⏭️  omc-hud.mjs 이미 존재"
fi

# keybindings.json
if [[ ! -f "$HOME/.claude/keybindings.json" ]]; then
  cat > "$HOME/.claude/keybindings.json" << 'KBEOF'
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "$docs": "https://code.claude.com/docs/en/keybindings",
  "bindings": []
}
KBEOF
  echo "✅ keybindings.json 생성 완료"
else
  echo "⏭️  keybindings.json 이미 존재"
fi

# .omc/hud-config.json
mkdir -p "$HOME/.claude/.omc"
if [[ ! -f "$HOME/.claude/.omc/hud-config.json" ]]; then
  cat > "$HOME/.claude/.omc/hud-config.json" << 'OMCEOF'
{
  "preset": "focused",
  "elements": {
    "omcLabel": false,
    "prdStory": false,
    "sessionHealth": false,
    "useBars": false,
    "gitBranch": false
  }
}
OMCEOF
  echo "✅ hud-config.json 생성 완료"
else
  echo "⏭️  hud-config.json 이미 존재"
fi

echo "✅ Claude Code 설정 완료"

# ---------------------------
# 터미널 설정 (tmux, Ghostty, Karabiner, cmux 연동)
# ---------------------------
echo
echo "=============================="
echo "🖥️  터미널 설정 설치"
echo "=============================="
bash "$(dirname "$0")/dotfiles/install.sh" || echo "❌ 터미널 설정 설치 실패"

# ---------------------------
# fzf 쉘 통합 설정
# ---------------------------
FZF_LINE='source <(fzf --zsh)'
if command -v fzf >/dev/null 2>&1; then
  if ! grep -qF "$FZF_LINE" "$HOME/.zshrc" 2>/dev/null; then
    echo "" >> "$HOME/.zshrc"
    echo "# fzf shell integration" >> "$HOME/.zshrc"
    echo "$FZF_LINE" >> "$HOME/.zshrc"
    echo "✅ fzf 쉘 통합 ~/.zshrc에 추가"
  else
    echo "⏭️  fzf 쉘 통합 이미 설정됨"
  fi
fi

echo
echo "=============================="
echo "✅ 전체 작업 완료"
echo "   - CLI: git, python@3.13, node, fzf, tmux, gh"
echo "   - GUI: Chrome, Figma, Slack, Notion, Obsidian, VSCode, JetBrains, Docker, Postman, Warp, Ghostty, cmux"
echo "   - 설정: Oh My Tmux, Ghostty, Karabiner, cmux, Claude Code, zshrc 앨리어스"
echo "   - 수동 설치 필요: omc 플러그인, Bear 노트 (README.md 참고)"
echo "=============================="
