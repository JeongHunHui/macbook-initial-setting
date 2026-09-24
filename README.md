# macbook-initial-setting

새 Mac을 현재 개발 환경과 같은 상태로 만드는 선택형 설치 패키지다. 시스템 기본값, 개발 도구, 앱, tmux/Ghostty/Karabiner, Codex CLI, 공통 셸 설정을 포함한다.

## 가장 쉬운 실행 방법

1. [SETUP.html](SETUP.html)을 브라우저로 연다.
2. 설치할 항목을 체크한다.
3. 생성된 명령을 이 폴더에서 실행하거나, 생성된 프롬프트를 Codex/Claude Code에 붙여 넣는다.

전체 설치:

```bash
chmod +x setup.sh
bash ./setup.sh
```

선택 설치:

```bash
MAC_INIT_MODULES="system,cli,terminal,codex,common" bash ./setup.sh
```

지원 모듈은 `system`, `cli`, `apps`, `dock`, `terminal`, `codex`, `common`이다.

## 현재 구성

| 영역 | 적용 내용 |
|---|---|
| 시스템 | 부팅음 끄기, Dock 오른쪽, 탭하여 클릭, 빠른 키 반복, 자동 교정/자동 완성 끄기 |
| CLI | Homebrew, Git, Python, Node.js, tmux, fzf, pyenv, pyenv-virtualenv, gh |
| 앱 | Chrome, Figma, Slack, Notion, Obsidian, VS Code, JetBrains 도구, Cursor, Docker, Postman, Ghostty, cmux, Rectangle, Scroll Reverser, Raycast, Karabiner |
| 셸 | fzf 단축키, Git alias, `c`/`cr` Codex YOLO alias, VS Code 외부 편집기 |
| tmux | 마우스 pane 선택, pane 내부 드래그 복사→macOS 클립보드, Option+D/F 창 이동, Option+화살표 비활성화 |
| Ghostty | 왼쪽 Option=Alt, Shift+Enter CSI-u 전달, Option+화살표 비활성화 |
| Codex | Enter 전송, Shift+Enter 줄바꿈, 한글 IME 대응 `disable_paste_burst`, scrollback 친화 설정, Ctrl+G→VS Code |
| Karabiner | Caps Lock→F18, Ghostty에서 한글 입력 중 Option 기반 tmux 명령, Chrome 전용 Option 단축키 |

## 주요 단축키

- `c`: Codex YOLO 모드 실행
- `cr`: 저장된 Codex 세션 선택/재개, 이름을 붙이면 해당 세션 재개
- Codex `Ctrl+G`: VS Code에서 현재 입력 편집
- Codex `Enter`: 전송
- Codex `Shift+Enter`: 줄바꿈
- tmux `Option+D/F`: 이전/다음 window
- tmux 마우스 클릭: pane 이동
- tmux 드래그: 현재 pane 안에서 선택하고 macOS 클립보드로 복사

## 자동화할 수 없는 수동 작업

설치 후 [MANUAL-CHECKLIST.md](MANUAL-CHECKLIST.md)를 따라야 한다. 핵심은 다음과 같다.

1. Karabiner-Elements의 입력 모니터링·손쉬운 사용·드라이버 확장 권한 허용.
2. 시스템 설정에서 한국어 2벌식 입력기를 추가하고 F18을 입력 소스 전환에 연결.
3. GitHub CLI `gh auth login` 실행.
4. Codex 로그인 후 `/status` 확인.
5. Chrome 확장 `chrome-tmux-tabs`를 압축 해제된 확장으로 로드.
6. 유료 JetBrains 앱과 Docker의 최초 실행 설정/로그인.

## 안전성과 재실행

- 설치 스크립트는 기존 dotfile을 `.bak-<시각>`으로 백업한다.
- 이미 설치된 Homebrew 항목은 건너뛴다.
- `common-settings/install.sh`는 여러 번 실행할 수 있다.
- Codex 설정 설치는 기존 `~/.codex/config.toml`을 백업하므로 MCP/개인 설정이 있다면 백업본과 병합한다.

상세 터미널 설명은 [TERMINAL.md](TERMINAL.md), 에이전트 실행 지시는 [SETUP-PROMPT.md](SETUP-PROMPT.md)에 있다.
