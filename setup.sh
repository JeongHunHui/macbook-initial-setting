#!/usr/bin/env bash
set -euo pipefail

echo "=== 맥북 환경 설정 ==="

# 선택 설치: 쉼표로 구분. 기본값은 전체 설치.
# 예: MAC_INIT_MODULES="system,cli,terminal,codex" bash ./setup.sh
MAC_INIT_MODULES="${MAC_INIT_MODULES-system,cli,apps,dock,terminal,codex,common}"
MAC_INIT_MODULES="${MAC_INIT_MODULES//[[:space:]]/}"
if [[ -z "$MAC_INIT_MODULES" ]]; then
  echo "선택된 모듈이 없어 아무 작업도 하지 않습니다."
  exit 0
fi
IFS=',' read -r -a selected_modules <<< "$MAC_INIT_MODULES"
case "$MAC_INIT_MODULES" in ,*|*,|*,,*) echo "빈 모듈 이름은 사용할 수 없습니다." >&2; exit 2 ;; esac
for module in "${selected_modules[@]}"; do
  case "$module" in system|cli|apps|dock|terminal|codex|common) ;; *) echo "알 수 없는 모듈: $module" >&2; exit 2 ;; esac
done
if [[ "${1:-}" == --plan ]]; then
  echo "선택 모듈: $MAC_INIT_MODULES"
  [[ ",$MAC_INIT_MODULES," != *",terminal,"* ]] || echo "terminal: Git, tmux, Python, Ghostty, JetBrains Mono, Karabiner, cmux"
  [[ ",$MAC_INIT_MODULES," != *",codex,"* ]] || echo "codex: Python, Codex CLI, VS Code, c/cr 및 편집기 설정"
  exit 0
fi
[[ $# -eq 0 ]] || { echo "사용법: bash setup.sh [--plan]" >&2; exit 2; }
[[ "$(uname -s)" == Darwin ]] || { echo "macOS 전용 설치 스크립트입니다." >&2; exit 2; }
enabled() { [[ ",$MAC_INIT_MODULES," == *",$1,"* ]]; }
failures=()
echo "선택 모듈: $MAC_INIT_MODULES"

if enabled system; then
  # 시스템 설정에 필요한 관리자 인증
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
fi

# ---------------------------
# Homebrew 설치/업데이트
# ---------------------------
if enabled cli || enabled apps || enabled terminal || enabled codex || enabled common; then
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
brew update || failures+=("Homebrew 업데이트")
fi

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
    if is_formula_available "$name"; then
      echo "⬇️  설치: $name"
      brew install "$name" || { echo "❌ 설치 실패: $name"; failures+=("$name"); return 0; }
      echo "✅ 완료: $name"
    else
      echo "❌ 설치 불가(찾을 수 없음): $name"
      failures+=("$name")
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
          failures+=("$token")
          echo "   └─ 로그: $out"
        fi
      fi
    else
      echo "❌ 설치 불가(찾을 수 없음): $token"
      failures+=("$token")
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
  "tmux"
  "gh"
  "fzf"
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
  "datagrip"        # 단일 유료판
  "cursor"
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
if enabled cli; then
  for formula in "${FORMULAS[@]}"; do install_formula "$formula"; done
else
  echo "⏭️  cli 모듈 건너뜀"
fi

echo
echo "=============================="
echo "🧩 GUI 앱 설치 (brew install --cask)"
echo "=============================="
if enabled apps; then
  for cask in "${CASKS[@]}"; do install_cask "$cask"; done
else
  echo "⏭️  apps 모듈 건너뜀"
fi

# ---------------------------
# Dock 고정 (연관배열 제거, value 배열만 순회)
# ---------------------------
if enabled dock; then
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
  "/Applications/DataGrip.app"
  "/Applications/Cursor.app"
  "/Applications/Docker.app"
  "/Applications/Postman.app"
  "/Applications/Warp.app"
  "/Applications/Ghostty.app"
)

dock_has_app() {
  local app="$1"
  local escaped="${app// /%20}"
  defaults read com.apple.dock persistent-apps 2>/dev/null | grep -F -e "$app" -e "$escaped" >/dev/null 2>&1
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
fi

# ---------------------------
# 터미널 설정 (tmux, Ghostty, Karabiner, cmux 연동)
# ---------------------------
if enabled terminal; then
  for formula in git tmux python@3.13; do install_formula "$formula"; done
  for cask in ghostty font-jetbrains-mono karabiner-elements cmux; do install_cask "$cask"; done
fi
if enabled codex; then
  install_formula python@3.13
  command -v codex >/dev/null 2>&1 || install_cask codex
  install_cask visual-studio-code
fi
echo
echo "=============================="
echo "🖥️  터미널 설정 설치"
echo "=============================="
if enabled terminal || enabled codex; then
  INSTALL_TERMINAL="$(enabled terminal && echo 1 || echo 0)" \
  INSTALL_CODEX="$(enabled codex && echo 1 || echo 0)" \
    bash "$(dirname "$0")/dotfiles/install.sh" || failures+=("터미널/Codex 설정")
fi

if enabled common; then
  echo
  echo "=============================="
  echo "⚙️  공통 macOS·셸 설정 설치"
  echo "=============================="
  bash "$(dirname "$0")/common-settings/install.sh" || failures+=("공통 설정")
fi

echo
echo "=============================="
echo "선택 작업 종료"
echo "   - 선택 모듈: $MAC_INIT_MODULES"
echo "   - Karabiner 권한, 계정 로그인, 크롬 확장은 MANUAL-CHECKLIST.md 참고"
echo "=============================="
if (( ${#failures[@]} )); then
  printf '❌ 실패: %s\n' "${failures[@]}"
  exit 1
fi
echo "✅ 선택 모듈 설치 완료"
