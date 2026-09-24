# tmux 단축 명령
alias t='tmux'
alias t0='tmux attach -t 0'

# cmux 에서 처음 연 셸이면 tmux 세션을 cmux 워크스페이스로 맞춘다 (cmux 실행당 한 번)
if [[ -n "$CMUX_WORKSPACE_ID" ]]; then
  _cmux_flag="/tmp/cmux-tmux-synced-$(pgrep -x cmux | head -1)"
  if [[ ! -f "$_cmux_flag" ]]; then
    touch "$_cmux_flag"
    cmux-tmux sync > /dev/null 2>&1 &
  fi
  unset _cmux_flag
fi
