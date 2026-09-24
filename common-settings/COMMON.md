# 공통 설정

회사와 상관없이 어느 맥에서나 쓰는 셸, git, 키보드, 창 배치 설정이다. 터미널 설정(`dotfiles/`, [TERMINAL.md](../TERMINAL.md))과 따로 돌린다.

```bash
bash ./common-settings/install.sh
```

여러 번 돌려도 된다. 앱 설정은 통째로 바꾸지 않고 아래에 적힌 키만 덮어쓴다.

## 설치되는 것

| 항목 | 내용 |
|------|------|
| brew | fzf, pyenv, pyenv-virtualenv, gh, Rectangle, Scroll Reverser, Raycast |
| oh-my-zsh | 없으면 설치. 테마 `robbyrussell`, 플러그인 `git` 기본값 그대로 |
| `zsh/common.zsh` | `~/.config/zsh/common.zsh` 로 복사하고 `.zshrc` 에 source 한 줄을 붙인다 |
| `git/ignore` | `~/.config/git/ignore`. 모든 저장소에서 `.venv`, `.claude/settings.local.json` 무시 |
| git 이름과 이메일 | 비어 있으면 설치할 때 물어본다 |
| gh 별칭 | `gh co` = `gh pr checkout` |
| `macos/defaults.sh` | 키보드, 입력, 시스템 단축키 |
| `apps/*.plist` | Rectangle, Scroll Reverser 설정 |
| Raycast | 호출 키 `⌘ Space` |
| `karabiner/iterm2-option-meta.json` | iTerm2 에서 한글 입력 중에도 Option 을 Meta 로 쓰는 규칙. 켜져 있지 않은 상태로 넣어 둔다 |

## 셸

| 별칭 | 명령 |
|------|------|
| `gf` | `git fetch --all --prune` |
| `gc` | `git checkout` |
| `gr` | `git rebase` |
| `gp` | `git push` |
| `gpo` | `git pull origin` |
| `gs` | `git stash` |
| `cl` | `clear` |
| `c` | 잠자기를 막고 Codex 실행 (YOLO 모드) |
| `cr` | 위와 같고 저장된 Codex 세션 이어하기. 뒤에 세션 이름 지정 가능 |

- fzf 로 `Ctrl R` 명령 기록 검색, `Ctrl T` 파일 찾기, `Alt C` 폴더 이동을 쓴다.
- `EDITOR` 와 `VISUAL` 은 `code --wait` 이다.
- nvm 은 처음 부를 때 불러온다. 대신 설치된 가장 최신 node 는 바로 쓸 수 있게 PATH 에 넣는다.

## macOS 키보드

- 키 반복을 가장 빠르게 한다. 반복 2, 첫 반복까지 15.
- 자동 대문자, 마침표 자동 입력, 따옴표와 줄표 바꾸기, 맞춤법 자동 고침, 문장 자동 완성을 끈다.
- Tab 으로 대화 상자의 모든 버튼을 오간다.

## 단축키

### 시스템

| 키 | 동작 |
|----|------|
| `Caps Lock` | 한영 전환. Karabiner 가 F18 로 바꾸고 macOS 가 F18 을 "다음 입력 소스"로 받는다 |
| `Ctrl Space` | 이전 입력 소스 |
| `⌘ Space` | Raycast. Spotlight 의 `⌘ Space` 는 끈다 |
| `⌘ ⌥ Space` | Finder 검색 창 (기본값) |
| `⌘ ⇧ S` | 선택 영역을 캡처해서 클립보드로 |
| `⌘ ⇧ 4` | 선택 영역을 캡처해서 파일로 (기본값) |

### Rectangle

기본 단축키(`Ctrl ⌥` + 방향키로 반쪽, `Ctrl ⌥ Enter` 로 최대화 등) 위에 아래를 더했다. 로그인할 때 자동으로 켜진다.

| 키 | 동작 |
|----|------|
| `Ctrl ⌥ A` / `S` | 왼쪽 위 / 오른쪽 위 4분의 1 |
| `Ctrl ⌥ Z` / `X` | 왼쪽 아래 / 오른쪽 아래 4분의 1 |
| `Ctrl ⌥ 1` / `2` / `3` | 3분할 왼쪽 / 가운데 / 오른쪽 |
| `Ctrl ⌥ 4` | 왼쪽 3분의 2 |
| `Ctrl ⌥ B` / `N` | 할 일 창 켜기, 끄기 / 다시 배치 |

### Scroll Reverser

마우스 휠 방향만 뒤집고 트랙패드는 그대로 둔다.

## 손으로 해야 하는 것

1. **한국어 입력기 추가.** 시스템 설정 > 키보드 > 입력 소스에서 "한국어 2벌식"을 추가한다. Karabiner 규칙이 이 입력기를 기준으로 동작한다.
2. **앱 권한.** Rectangle 과 Scroll Reverser 를 처음 켜면 손쉬운 사용 권한을 묻는다. 허용한다.
3. **Raycast 나머지 설정.** 확장, 별칭, 스니펫은 파일로 옮길 수 없다. 기존 맥의 Raycast 에서 Settings > Advanced > Export 로 `.rayconfig` 를 만들고 새 맥에서 Import 한다.
4. **GitHub 로그인.** `gh auth login` 을 실행한다.
5. 단축키가 바로 안 먹으면 로그아웃했다가 다시 들어온다.

## setup.sh 에 붙이기

`setup.sh` 의 터미널 설정 설치 줄 아래에 한 줄을 더하면 처음 세팅할 때 같이 돈다.

```bash
bash "$(dirname "$0")/common-settings/install.sh" || echo "❌ 공통 설정 설치 실패"
```
