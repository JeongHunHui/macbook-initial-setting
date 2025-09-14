# macbook-initial-setting

맥북 초기 설정을 자동화하는 스크립트입니다.

## 실행 방법

```bash
chmod +x setup.sh
bash ./setup.sh
```

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

### 애플리케이션 설치
- **브라우저**: Google Chrome
- **디자인**: Figma
- **커뮤니케이션**: Slack
- **생산성**: Notion, Obsidian
- **유틸리티**: Scroll Reverser, Rectangle, Raycast
- **개발 도구**:
  - Visual Studio Code
  - IntelliJ IDEA Ultimate (유료)
  - PyCharm Professional (유료)
  - DataGrip (유료)
  - Cursor
  - Docker Desktop
  - Postman
  - Warp

### Dock 고정
다음 앱들이 자동으로 Dock에 고정됩니다:
- Google Chrome
- Figma
- Slack
- Notion
- Obsidian
- Visual Studio Code
- IntelliJ IDEA
- PyCharm
- DataGrip
- Cursor
- Docker
- Postman
- Warp

**참고**: Scroll Reverser, Rectangle, Raycast는 설치되지만 Dock에는 자동 고정되지 않습니다.

## 특징

- **중복 설치 방지**: 이미 설치된 패키지/앱은 건너뜀
- **중복 Dock 고정 방지**: 이미 Dock에 있는 앱은 재고정하지 않음
- **안전한 실행**: 실패 시에도 전체 스크립트가 중단되지 않음
- **상세한 로그**: 각 단계별 진행 상황을 명확하게 표시

## 주의사항

1. **JetBrains 제품**: IntelliJ IDEA Ultimate, PyCharm Professional, DataGrip은 유료 제품입니다
2. **권한**: 일부 시스템 설정 변경을 위해 sudo 권한이 필요할 수 있습니다
3. **재부팅**: 모든 설정이 완전히 적용되려면 시스템 재부팅을 권장합니다
