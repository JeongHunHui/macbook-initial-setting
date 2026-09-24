# macbook-initial-setting

맥북 초기 설정을 자동화하는 스크립트입니다.

## 실행 방법

```bash
chmod +x setup.sh
bash ./setup.sh
```

설정 체크리스트와 관련 파일은 [`index.html`](index.html) 대시보드에서도 확인할 수 있습니다.

## 설정되는 사항

### 시스템 설정

- **부팅음**: 끄기 (Apple Silicon에서는 제한될 수 있음)
- **Dock 위치**: 오른쪽으로 이동
- **트랙패드**: '탭하여 클릭하기' 활성화

### 개발 도구 설치 (CLI)

- **Homebrew**: 패키지 관리자 설치
- **Git**: 버전 관리 시스템
- **Python 3.13**: 최신 Python 버전
- **Node.js**: JavaScript 런타임
- **fzf**: 퍼지 검색 도구 (Ctrl+R 히스토리 검색, Ctrl+T 파일 검색)
- **tmux**: 터미널 멀티플렉서
- **gh**: GitHub CLI

### 애플리케이션 설치

- **브라우저**: Google Chrome
- **디자인**: Figma
- **커뮤니케이션**: Slack
- **생산성**: Notion, Obsidian
- **유틸리티**: Scroll Reverser, Rectangle, Raycast
- **개발 도구**:
  - Visual Studio Code
  - Docker Desktop
  - Postman
  - Warp
  - Ghostty (터미널)
- **키 매핑**: Karabiner-Elements

### Dock 고정

다음 앱들이 자동으로 Dock에 고정됩니다:

- Google Chrome, Figma, Slack, Notion, Obsidian
- Visual Studio Code
- Docker, Postman, Warp, Ghostty

### 터미널 설정

tmux, Ghostty, Karabiner 설정을 `dotfiles/install.sh`로 설치하고,
크롬 확장 `chrome-tmux-tabs`를 함께 둡니다. 단축키와 수동 단계는
[`TERMINAL.md`](TERMINAL.md)에 정리되어 있습니다.

### Claude Code 설치 및 설정

- `claude` CLI 설치 (`curl -fsSL https://claude.ai/install.sh | bash`)
- `~/.claude/settings.json` — 권한, 플러그인, 언어 설정
- `~/.claude/hud/omc-hud.mjs` — HUD 상태바 래퍼 스크립트
- `~/.claude/keybindings.json` — 키바인딩 (빈 상태)
- `~/.claude/.omc/hud-config.json` — focused 프리셋

### Oh My Tmux 설정

- [gpakosz/.tmux](https://github.com/gpakosz/.tmux) 클론 및 심링크
- `~/.tmux.conf.local` 자동 생성:
  - **테마**: 다크 그레이/블루 기본 테마
  - **키바인딩**: `Alt+s` 세로 분할, `Alt+w` pane 닫기
  - **마우스**: ON (드래그 선택 → 클립보드 복사)
  - **상태바**: 왼쪽에 Git branch + 현재 경로, 오른쪽에 CPU/MEM 사용률
  - **플러그인**: tmux-cpu (CPU/RAM 모니터링)

### Ghostty 설정

- `~/.config/ghostty/config`에 `macos-option-as-alt = true` 설정
- tmux의 `Alt+s`, `Alt+w` 키바인딩이 정상 동작하도록 Option 키를 Meta로 사용

### 쉘 앨리어스

`~/.zshrc`에 다음 앨리어스가 추가됩니다:

| 앨리어스 | 명령어 |
|---------|--------|
| `gc` | `git checkout` |
| `gr` | `git rebase` |
| `gp` | `git push` |
| `gpo` | `git pull origin` |
| `gs` | `git stash` |
| `c` | `caffeinate -i claude --dangerously-skip-permissions` |
| `t` | `tmux` |
| `cl` | `clear` |

`$HOME/.local/bin`도 PATH에 추가됩니다.

---

## 수동 설치

스크립트로 자동화할 수 없는 항목입니다.

### omc (Oh My Claude Code) 플러그인

Claude Code 실행 후:

```
/install-plugin oh-my-claudecode
/omc-setup
```

### omc HUD 설정

`~/.claude/.omc/hud-config.json`은 스크립트가 생성하지만, 추가 커스터마이징이 필요하면 직접 수정:

```json
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
```

### Bear 노트

App Store에서 수동 설치 후 Dock에 등록:

1. App Store → "Bear" 검색 → 설치
2. Dock에 드래그하여 고정

---

## 맥미니 OpenClaw 세팅

모니터 없는 맥미니에 SSH로 접속하여 OpenClaw(Claude AI + Slack 연동)을 세팅하는 가이드.

- **전체 가이드**: [`mac-mini-openclaw-guide.md`](mac-mini-openclaw-guide.md)
- **자동화 스크립트**: [`mac-mini-openclaw-setup.sh`](mac-mini-openclaw-setup.sh)

### 빠른 시작

```bash
# 1. 맥미니 초기 설정 완료 + SSH 활성화 (가이드 0~1단계 참조)

# 2. 맥북에서 스크립트를 맥미니로 전송
scp mac-mini-openclaw-setup.sh 사용자이름@맥미니IP:~/

# 3. SSH 접속 후 실행
ssh 사용자이름@맥미니IP
bash ~/mac-mini-openclaw-setup.sh

# 4. OpenClaw 온보딩 (수동)
openclaw onboard --install-daemon
```
