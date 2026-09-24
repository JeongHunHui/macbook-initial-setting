#!/usr/bin/env bash
# 키보드, 입력, 시스템 단축키 설정
set -euo pipefail

# 키 반복을 가장 빠르게
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

# 자동 고침 끄기
for k in NSAutomaticCapitalizationEnabled NSAutomaticDashSubstitutionEnabled NSAutomaticInlinePredictionEnabled \
         NSAutomaticPeriodSubstitutionEnabled NSAutomaticQuoteSubstitutionEnabled NSAutomaticSpellingCorrectionEnabled; do
  defaults write -g "$k" -bool false
done

# Tab 으로 모든 버튼 이동
defaults write -g AppleKeyboardUIMode -int 2

# 시스템 단축키. parameters = (문자, 키 코드, 보조 키)
hotkey() {
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><$2/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>$3</integer><integer>$4</integer><integer>$5</integer></array></dict></dict>"
}
hotkey 60 true  32    49 262144    # 이전 입력 소스: Ctrl+Space
hotkey 61 true  65535 79 8388608   # 다음 입력 소스: F18 (Karabiner 가 Caps Lock 을 F18 로 바꾼다)
hotkey 64 false 65535 49 1048576   # Spotlight: Cmd+Space 끔 (Raycast 가 쓴다)
hotkey 31 true  115   1  1179648   # 선택 영역 캡처해서 클립보드로: Cmd+Shift+S

# 로그아웃 없이 단축키 바로 적용
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null || true
echo "✅ macOS 키보드와 단축키"
