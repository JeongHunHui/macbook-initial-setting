#!/bin/bash
# tmux-resurrect 스냅샷을 최신 10개만 유지 (나머지 자동 삭제)
# 복원은 항상 'last' 심볼릭링크(=최신본)를 쓰므로 오래된 파일 삭제는 안전하다.
DIR="$HOME/.local/share/tmux/resurrect"
[ -d "$DIR" ] || exit 0
cd "$DIR" || exit 0
ls -1t tmux_resurrect_*.txt 2>/dev/null | tail -n +11 | while IFS= read -r f; do
  rm -f -- "$f"
done
