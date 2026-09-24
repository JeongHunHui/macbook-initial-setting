#!/usr/bin/env bash
set -euo pipefail

echo "=== 맥미니 OpenClaw 세팅 ==="
echo "SSH 접속 후 실행하는 자동화 스크립트"
echo

# ---------------------------
# 0) sudo 인증
# ---------------------------
sudo -v || true

# ---------------------------
# 1) Homebrew 설치/업데이트
# ---------------------------
echo "=============================="
echo "🍺 Homebrew 설치..."
echo "=============================="
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
  echo "✅ Homebrew 이미 설치됨"
fi
brew update

# ---------------------------
# 2) Node.js 22 설치
# ---------------------------
echo
echo "=============================="
echo "📦 Node.js 22 설치..."
echo "=============================="
if command -v node >/dev/null 2>&1; then
  NODE_VER="$(node --version)"
  if [[ "$NODE_VER" == v22.* ]]; then
    echo "✅ Node.js $NODE_VER 이미 설치됨"
  else
    echo "⚠️  Node.js $NODE_VER 설치됨 (v22 아님), node@22 설치 진행"
    brew install node@22 || echo "❌ node@22 설치 실패"
  fi
else
  echo "➡️  Node.js 미설치: node@22 설치 진행"
  brew install node@22 || { echo "❌ node@22 설치 실패"; exit 1; }
fi

# node@22가 keg-only인 경우 PATH 설정
if brew list --formula | grep -qx "node@22"; then
  NODE22_PREFIX="$(brew --prefix node@22)"
  if [[ -d "$NODE22_PREFIX/bin" ]] && ! echo "$PATH" | grep -q "$NODE22_PREFIX/bin"; then
    export PATH="$NODE22_PREFIX/bin:$PATH"
    if ! grep -qF "node@22" "$HOME/.zprofile" 2>/dev/null; then
      echo "export PATH=\"$NODE22_PREFIX/bin:\$PATH\"" >> "$HOME/.zprofile"
      echo "📝 node@22 PATH를 ~/.zprofile에 추가"
    fi
  fi
fi

echo "  node: $(node --version)"
echo "  npm:  $(npm --version)"

# ---------------------------
# 3) OpenClaw 설치
# ---------------------------
echo
echo "=============================="
echo "🐾 OpenClaw 설치..."
echo "=============================="
if command -v openclaw >/dev/null 2>&1; then
  echo "✅ OpenClaw 이미 설치됨: $(openclaw --version)"
else
  echo "➡️  OpenClaw 설치 진행 (npm global)"
  npm install -g openclaw@latest || { echo "❌ OpenClaw 설치 실패"; exit 1; }
  echo "✅ OpenClaw 설치 완료: $(openclaw --version)"
fi

# ---------------------------
# 완료 안내
# ---------------------------
echo
echo "=============================="
echo "✅ 자동 설치 완료"
echo "=============================="
echo
echo "다음 단계를 수동으로 진행하세요:"
echo
echo "1) OpenClaw 온보딩 위저드 실행:"
echo "   openclaw onboard --install-daemon"
echo
echo "2) 위저드에서 설정:"
echo "   - 인증: Anthropic(Claude) 선택 → API 키 입력"
echo "   - 게이트웨이: 데몬 설치"
echo "   - 채널: Slack 선택"
echo
echo "3) Slack App 생성 (맥북 브라우저에서):"
echo "   - https://api.slack.com/apps → Create New App"
echo "   - Socket Mode ON → App-Level Token 생성"
echo "   - Bot Token Scopes: chat:write, channels:history, channels:read, im:history, im:read"
echo "   - Event Subscriptions: message.channels, message.im, app_mention"
echo "   - Install to Workspace → Bot Token 복사"
echo
echo "4) 게이트웨이 확인:"
echo "   openclaw gateway status"
echo
echo "상세 가이드: mac-mini-openclaw-guide.md 참조"
