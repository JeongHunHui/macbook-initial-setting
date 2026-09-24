# 에이전트용 설치 프롬프트

아래 프롬프트의 `선택 모듈`만 원하는 값으로 바꿔 Codex나 Claude Code에 전달한다.

```text
이 폴더는 macbook-initial-setting 패키지다.

선택 모듈: system,cli,apps,dock,terminal,codex,common

1. README.md, TERMINAL.md, MANUAL-CHECKLIST.md와 모든 설치 스크립트를 먼저 읽어라.
2. 현재 Mac 상태를 읽기 전용으로 점검하고 이미 설치된 항목은 재설치하지 마라.
3. MAC_INIT_MODULES="선택 모듈" bash ./setup.sh 로 선택한 모듈만 설치하라.
4. 기존 dotfile과 설정은 반드시 백업하고, 사용자 고유 토큰이나 인증정보를 출력하거나 덮어쓰지 마라.
5. 설치 중 관리자 암호, 시스템 확장, 입력 모니터링, 손쉬운 사용, OAuth/계정 로그인이 필요하면 자동 우회하지 말고 내가 직접 할 정확한 단계를 알려라.
6. 설치 후 shell 문법, Codex strict config, tmux 설정, Ghostty 설정, Karabiner 파일, Homebrew 설치 상태를 검증하라.
7. 마지막 응답은 자동 완료, 수동 필요, 실패/보류 세 구역으로 나누고 실제 확인 결과를 적어라.
```
