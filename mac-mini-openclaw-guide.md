# 맥미니(모니터 없음) SSH 접속 + OpenClaw 세팅 가이드

맥북에서 **새 맥미니**에 원격 접속하여 OpenClaw을 세팅하는 가이드.

- **제약**: 맥미니에 연결할 모니터가 없고, macOS 초기 설정이 안 된 상태
- **목표**: SSH 접속 → OpenClaw 설치 → Claude API + Slack 연동

---

## 0단계: 맥미니 초기 설정 (TV + Android 폰 활용)

> **상황**: 모니터/키보드/마우스 없음. TV, 맥북, Android 폰만 있음.
> **핵심**: 새 맥미니는 macOS 초기 설정(언어, Apple ID, 계정 생성)을 완료해야 SSH를 켤 수 있다.

### 필요 장비

- HDMI 케이블 (맥미니 ↔ TV 연결용)
- Android 폰 (Bluetooth 키보드 대용)

### 절차

**1) Android 폰에 Bluetooth 키보드 앱 설치**

- Google Play에서 **"Bluetooth Keyboard & Mouse"** (AppGround IO) 설치
- 이 앱은 폰을 Bluetooth HID 키보드+마우스로 변환 (대상 기기에 소프트웨어 설치 불필요)

**2) 맥미니를 TV에 연결**

- HDMI 케이블로 맥미니 뒷면 HDMI 포트 ↔ TV HDMI 포트 연결
- TV 입력을 해당 HDMI로 전환

**3) 맥미니 전원 켜기**

- 전원 연결 후 전원 버튼 누르기
- TV에 macOS 초기 설정 화면이 표시됨
- 맥미니가 자동으로 Bluetooth 키보드/마우스를 검색하기 시작

**4) Android 폰 Bluetooth 페어링**

- Android 앱 열기 → Bluetooth를 켜고 검색 가능 모드로 설정
- TV 화면에 Android 폰이 Bluetooth 기기로 표시되면 선택
- 페어링 코드가 TV에 표시되면 → Android 폰에서 동일 코드 입력하여 확인
- 페어링 완료 → 폰이 키보드+터치패드로 동작

**5) macOS 초기 설정 진행 (~10분)**

Android 폰의 화면 키보드 + 터치패드로 조작하면서 TV 화면 보고 진행:

1. 언어 선택 → 국가/지역 → Wi-Fi 연결
2. Apple ID 로그인 (또는 "나중에 설정")
3. 사용자 계정 이름/비밀번호 생성 ← **이 비밀번호 꼭 기억!** (SSH 접속 시 사용)
4. 나머지 옵션은 기본값으로 진행

**만약 Android 폰 페어링이 안 될 경우**

- 다이소/편의점에서 USB 키보드 구매 (~3,000원)
- 또는 주변에서 아무 USB 키보드 빌리기

### Q: 맥북과 USB-C 케이블로 직접 연결하면?

- **맥북을 맥미니의 모니터/키보드로 사용 → 불가능** (Mac은 USB 호스트만 가능)
- **Thunderbolt Bridge** (케이블로 네트워크 연결) → 초기 설정 **이후**에만 사용 가능

---

## 1단계: 맥미니에서 SSH + 화면 공유 활성화

macOS 초기 설정 완료 후 진행.

### GUI로 (TV 화면 보면서)

```
시스템 설정 → 일반 → 공유 → "원격 로그인" 켜기
시스템 설정 → 일반 → 공유 → "화면 공유" 켜기
```

### 터미널로

```bash
# Spotlight 열기: Cmd + Space → "터미널" 입력 → Enter

# SSH 활성화
sudo systemsetup -setremotelogin on

# 화면 공유 활성화 (향후 GUI 원격 제어용)
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

# IP 주소 확인
ipconfig getifaddr en0
```

표시되는 IP 주소를 메모 (예: `192.168.0.10`)

---

## 2단계: 맥북에서 맥미니 접속

### 방법 A: Wi-Fi 경유 (같은 네트워크)

```bash
ssh 사용자이름@맥미니IP
# 예: ssh jeonghunhui@192.168.0.10
```

### 방법 B: Thunderbolt Bridge (USB-C 케이블 직접 연결)

1. USB-C/Thunderbolt 케이블로 맥북 ↔ 맥미니 연결
2. 양쪽 Mac에서: `시스템 설정 → 네트워크 → Thunderbolt Bridge` 자동 인식
3. 자동으로 `169.254.x.x` 대역 IP가 할당됨
4. SSH 접속:

```bash
ssh 사용자이름@169.254.x.x
```

Wi-Fi 없이도 10Gbps 고속 연결 가능.

### (선택) SSH 키 설정 - 비밀번호 없이 접속

```bash
# 맥북에서
ssh-keygen -t ed25519 -C "macbook-to-macmini"
ssh-copy-id 사용자이름@맥미니IP

# 이후 비밀번호 없이 접속
ssh 사용자이름@맥미니IP
```

### (선택) 화면 공유로 GUI 접속

```bash
# 맥북 Finder → 이동 → 서버에 연결 (Cmd+K)
# vnc://맥미니IP 입력
```

맥미니 화면을 맥북에서 GUI로 제어 가능 (모니터 완전 대체).

**여기부터 모니터 완전 불필요. 모든 작업을 맥북에서 원격으로 진행.**

---

## 3~6단계: 자동화 스크립트 실행

SSH 접속 후, 아래 스크립트로 개발 환경 + OpenClaw 설치를 한 번에 처리할 수 있다.

```bash
# 맥북에서 스크립트를 맥미니로 전송
scp mac-mini-openclaw-setup.sh 사용자이름@맥미니IP:~/

# SSH 접속
ssh 사용자이름@맥미니IP

# 스크립트 실행
chmod +x ~/mac-mini-openclaw-setup.sh
bash ~/mac-mini-openclaw-setup.sh
```

스크립트가 처리하는 항목:

- Homebrew 설치
- Node.js 22 설치
- OpenClaw 설치 (npm)

스크립트 실행 후 수동으로 진행할 항목:

- `openclaw onboard --install-daemon` (인터랙티브 위저드)
- Claude API 키 등록
- Slack App 생성 및 토큰 연동

상세 내용은 아래 참조.

---

## 수동 설정: OpenClaw 온보딩

### API 키 발급

1. https://console.anthropic.com 접속 (맥북 브라우저에서)
2. API Keys → 새 키 생성 → 복사

### 온보딩 위저드

```bash
openclaw onboard --install-daemon
```

위저드에서 순서대로:

1. **인증** - Anthropic(Claude) 선택, API 키 입력
2. **게이트웨이** - 데몬 설치
3. **채널** - Slack 선택

### 설정 확인/수정

```bash
cat ~/.openclaw/openclaw.json
```

수동 수정 필요 시:

```json
{
  "agent": {
    "model": "anthropic/claude-sonnet-4-5"
  }
}
```

---

## 수동 설정: Slack 채널 연결

### 1) Slack App 생성 (맥북 브라우저에서)

1. https://api.slack.com/apps → "Create New App" → "From scratch"
2. 앱 이름: "OpenClaw" + 워크스페이스 선택

### 2) Socket Mode 활성화

1. 좌측 "Socket Mode" → ON
2. App-Level Token 생성 (`connections:write` 스코프) → `xapp-...` 토큰 복사

### 3) Bot Token 권한

"OAuth & Permissions" → Bot Token Scopes:

- `chat:write`
- `channels:history`
- `channels:read`
- `im:history`
- `im:read`

### 4) 이벤트 구독

"Event Subscriptions" → ON → Bot Events:

- `message.channels`
- `message.im`
- `app_mention`

### 5) 앱 설치

"Install App" → "Install to Workspace" → `xoxb-...` Bot Token 복사

### 6) OpenClaw에 토큰 등록 (SSH로 맥미니에서)

온보딩에서 입력했으면 생략. 수동 설정:

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "botToken": "xoxb-...",
      "appToken": "xapp-...",
      "signingSecret": "..."
    }
  }
}
```

### 7) 게이트웨이 재시작 + 테스트

```bash
openclaw gateway restart
```

Slack에서 봇에게 DM → 응답 확인

---

## 검증 체크리스트

| # | 항목 | 확인 방법 |
|---|------|----------|
| 1 | SSH 접속 | `ssh 사용자@IP` 성공 |
| 2 | Node.js | `node --version` → v22.x.x |
| 3 | OpenClaw | `openclaw --version` |
| 4 | 게이트웨이 | `openclaw gateway status` → running |
| 5 | Claude API | 대시보드에서 테스트 메시지 |
| 6 | Slack | Slack DM → 봇 응답 확인 |

---

## 참고 자료

- [OpenClaw 공식 문서](https://docs.openclaw.ai/start/getting-started)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Slack 채널 설정](https://docs.openclaw.ai/channels/slack)
- [Anthropic API 설정](https://docs.openclaw.ai/providers/anthropic)
