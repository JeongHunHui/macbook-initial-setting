# 설치 후 직접 해야 하는 작업

자동 설치가 끝나도 macOS 보안 승인과 계정 로그인은 사용자가 직접 해야 한다.

## 필수

- [ ] 시스템 설정 → 개인정보 보호 및 보안 → 입력 모니터링에서 Karabiner 허용
- [ ] 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 Karabiner 허용
- [ ] Karabiner가 안내하는 시스템 확장/드라이버 허용 후 앱 재실행
- [ ] 시스템 설정 → 키보드 → 입력 소스에 `한국어 2벌식` 추가
- [ ] 입력 소스 단축키에서 F18을 입력 소스 전환으로 지정해 Caps Lock 한영 전환 확인
- [ ] Ghostty를 완전히 재실행하고 `tmux` 시작
- [ ] `Option+D/F`, 마우스 pane 클릭, pane 내부 드래그 복사 확인
- [ ] Ghostty의 Reload Configuration 실행 후 Codex에서 `Cmd+←/→`, 여러 줄 `↑/↓` 확인. tmux `show-options -g prefix2`는 `None`이어야 함
- [ ] `gh auth login`으로 GitHub 로그인
- [ ] Codex 로그인 후 `c`, `cr`, `/status` 확인
- [ ] Codex에서 `ㅇㅇ` 직후 Enter 테스트. 누락 시 새 Codex 세션인지와 `disable_paste_burst = true` 확인

## 선택

- [ ] Chrome `chrome://extensions`에서 개발자 모드 활성화 후 `chrome-tmux-tabs` 폴더 로드
- [ ] `chrome://extensions/shortcuts`에서 확장 단축키 지정
- [ ] Rectangle, Scroll Reverser 최초 실행 권한 허용
- [ ] Raycast의 확장·별칭·스니펫 가져오기
- [ ] Docker Desktop, JetBrains 앱, Slack, Notion 등 로그인
- [ ] 재부팅 후 Karabiner/Ghostty/tmux 자동 동작 확인

## 문제 점검 프롬프트

```text
이 저장소의 README.md, TERMINAL.md, MANUAL-CHECKLIST.md를 읽고 현재 Mac의 설치 상태를 읽기 전용으로 점검해줘. 누락된 자동 설정은 내 승인 범위 안에서 적용하고, 관리자 암호·macOS 개인정보 권한·계정 로그인처럼 내가 직접 해야 하는 일은 정확한 메뉴 경로와 검증 명령을 체크리스트로 알려줘. 기존 설정과 사용자 파일은 덮어쓰기 전에 백업하고, 마지막에 실제 검증 결과를 표로 정리해줘.
```
