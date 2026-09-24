# 터미널 설정

`setup.sh` 가 마지막에 `dotfiles/install.sh` 를 실행해서 아래 설정을 홈 디렉터리에 깐다. 따로 돌려도 된다.

```bash
bash ./dotfiles/install.sh
```

기존 파일이 있으면 `<파일>.bak-<시각>` 으로 옮겨 두고 새로 쓴다. 파일 안의 `__HOME__` 은 설치할 때 실제 홈 경로로 바뀐다.

## 들어 있는 것

| 경로 | 설치 위치 | 내용 |
|------|-----------|------|
| `dotfiles/tmux/gpakosz.patch` | `~/.tmux/.tmux.conf` | [gpakosz/.tmux](https://github.com/gpakosz/.tmux) 를 커밋 `87dcd13` 에 고정해 받은 뒤 붙이는 수정. 보조 prefix `C-a` 끄기, 마우스 켜기 |
| `dotfiles/tmux/tmux.conf.local` | `~/.tmux.conf.local` | 단축키, 상태 표시줄, 플러그인 설정 |
| `dotfiles/tmux/claude-usage.sh` | `~/.tmux/` | 상태 표시줄 오른쪽에 Claude, Codex 사용량 표시. 토큰은 키체인에서 읽는다 |
| `dotfiles/tmux/resurrect-cleanup.sh` | `~/.tmux/` | tmux-resurrect 스냅샷을 최신 10개만 남긴다 |
| `dotfiles/tmux/com.user.tmux-resurrect-cleanup.plist` | `~/Library/LaunchAgents/` | 위 정리 스크립트를 1분마다 돌리는 LaunchAgent |
| `dotfiles/ghostty/config` | `~/.config/ghostty/config` | 왼쪽 Option 을 Alt 로 사용하고 시작 폴더를 `~/Projects`로 지정 |
| `dotfiles/karabiner/karabiner.json` | `~/.config/karabiner/karabiner.json` | 키 매핑 전체 |
| `dotfiles/zsh/tmux.zsh` | `~/.config/zsh/tmux.zsh` | `t`, `t0` 별칭. `.zshrc` 에 source 한 줄이 붙는다 |
| `chrome-tmux-tabs/` | 수동 설치 | tmux 처럼 크롬 탭을 다루는 확장 |

## tmux

prefix 는 기본값 `C-b` 하나만 쓴다. 자주 쓰는 동작은 prefix 없이 왼쪽 Option 으로 누른다.

| 키 | 동작 |
|----|------|
| `⌥S` | 세로로 나누기 (새 패널은 `~` 에서 시작) |
| `⌥C` | 다음 패널로 이동 |
| `⌥Z` | 현재 패널 확대/복귀 |
| `⌥W` | 현재 패널 닫기 |
| `⌥A` | 현재 패널을 새 창으로 떼어내기 (이름 입력) |
| `⌥F` / `⌥D` | 다음 창 / 이전 창 |
| `⌥1` | 패널 가로 균등 배치 |
| `prefix m` | 마우스 켜기/끄기 |

- 마우스로 패널 경계를 끌어 크기를 바꾸는 동작은 막아 두었다.
- 창 이름 자동 변경 끄기, 세션을 닫아도 tmux 에서 튕기지 않기(`detach-on-destroy off`)를 켜 두었다.
- 상태 표시줄 왼쪽은 비워 두고, 오른쪽에 prefix와 마우스 표시, Claude 사용량, CPU, RAM 을 보여 준다.
- 플러그인은 tmux-cpu, tmux-resurrect, tmux-continuum 이다. 1분마다 세션을 저장하고 tmux 를 켜면 자동 복원한다. 패널 내용과 `claude` 프로세스도 복원한다.
- 플러그인은 tmux 를 처음 켤 때 자동으로 받는다.

## Karabiner

| 키 | 조건 | 동작 |
|----|------|------|
| Caps Lock | 항상 | F18 (한영 전환용) |
| `` ` `` | 항상 | `non_us_backslash` |
| 오른쪽 Shift | 항상 | fn |
| 왼쪽 ⌥ + S F D W Z C 1 A | Ghostty 에서 한글 입력 중 | 위 tmux 단축키를 `tmux` 명령으로 바로 실행. 한글 입력기가 Option 키를 먹는 문제를 피한다 |
| `⌥C` | 크롬 | 개발자 도구 (`⌘⌥I`) |
| `⌥S` | 크롬 | 탭 분할 보기 (`⌘⌥N`) |
| `⌥W` | 크롬 | 탭 닫기 (`⌘W`) |

Caps Lock 을 한영 전환으로 쓰려면 시스템 설정 > 키보드 > 단축키 > 입력 소스에서 "이전 입력 소스 선택"을 F18 로 지정한다.

## 크롬 확장 tmux-tabs

tmux 단축키와 같은 손 모양으로 크롬 탭을 다룬다. 탭을 옮길 때마다 현재 그룹만 펴고 나머지 그룹은 접는다.

| 기본 키 | 동작 |
|---------|------|
| `⌥F` / `⌥D` | 다음 탭 / 이전 탭 |
| `⌥A` | 현재 탭을 새 창으로 떼어내기 |
| `⌥1` | 모든 창을 같은 너비로 나란히 배치 |

아래 동작은 기본 키가 없다. `chrome://extensions/shortcuts` 에서 직접 지정한다.

| 동작 | 권장 키 |
|------|---------|
| 방문한 탭 기록 뒤로 / 앞으로 | `⌥O` / `⌥P` |
| 탭 닫고 새로 열기 | `⌥B` |
| 탭 복제, 닫은 탭 다시 열기 | |
| 이름 입력해서 그룹 만들기/이름 바꾸기 | |
| 현재 그룹 안에 새 탭 열기 | |
| 모든 그룹 접기 | |
| 창 왼쪽 너비 넓게/좁게 바꾸기 | |

## 수동으로 해야 하는 것

1. **Karabiner-Elements** 를 한 번 실행하고 시스템 설정 > 개인정보 보호 및 보안에서 입력 모니터링과 드라이버 확장을 허용한다.
2. **크롬 확장** 은 `chrome://extensions` 에서 개발자 모드를 켜고 "압축 해제된 확장 프로그램 로드"로 `chrome-tmux-tabs` 폴더를 고른다. 폴더를 지우면 확장도 사라지므로 저장소 안에 그대로 둔다. 그다음 `chrome://extensions/shortcuts` 에서 단축키를 지정한다.
3. **Ghostty** 에서 `tmux` 를 한 번 실행해 플러그인이 받아지는지 확인한다.
