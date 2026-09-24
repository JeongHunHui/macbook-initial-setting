# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

맥북 초기 개발 환경 설정을 자동화하는 셸 스크립트 프로젝트. 시스템 설정, CLI 도구, GUI 앱 설치, Dock 고정, 개발 도구 설정을 한 번에 처리한다.

## Project Structure

```
.
├── setup.sh                    # 맥북 자동화 스크립트 (시스템 설정 → CLI 설치 → GUI 설치 → Dock 고정 → 도구 설정)
├── mac-mini-openclaw-setup.sh  # 맥미니 OpenClaw 세팅 스크립트 (Homebrew → Node.js 22 → OpenClaw)
├── mac-mini-openclaw-guide.md  # 맥미니 헤드리스 SSH + OpenClaw 세팅 가이드
├── README.md                   # 사용법, 설치 목록, 수동 설치 안내
└── CLAUDE.md                   # Claude Code 가이드
```

## Key Architecture Decisions

- 단일 `setup.sh` 스크립트로 모든 설정을 순차 실행
- Homebrew를 패키지 관리의 핵심으로 사용 (formula + cask)
- 헬퍼 함수(`install_formula`, `install_cask`, `dock_has_app`, `dock_add_app`)로 로직 분리
- 멱등성 보장: 이미 설치된 패키지/앱/Dock 항목은 건너뜀

## Development Guidelines

- 셸 스크립트는 `#!/usr/bin/env bash`와 `set -euo pipefail`을 사용
- 개별 설치 실패가 전체 스크립트를 중단하지 않도록 에러 핸들링 필요
- 새 패키지 추가 시 `FORMULAS` 또는 `CASKS` 배열에 추가하고, Dock 고정이 필요하면 `DOCK_APPS` 배열에도 추가
- README.md의 설치 목록도 함께 업데이트할 것

## Common Commands

```bash
# 문법 검사
bash -n setup.sh
bash -n mac-mini-openclaw-setup.sh

# 맥북 스크립트 실행
chmod +x setup.sh
bash ./setup.sh

# 맥미니 스크립트 실행 (SSH 접속 후)
chmod +x mac-mini-openclaw-setup.sh
bash ./mac-mini-openclaw-setup.sh
```

## Install Targets

- **CLI (formula)**: git, python@3.13, node, fzf, tmux, gh
- **GUI (cask)**: google-chrome, figma, slack, notion, obsidian, scroll-reverser, rectangle, raycast, visual-studio-code, intellij-idea, pycharm, docker, postman, warp, ghostty, cmux, karabiner-elements, font-jetbrains-mono
