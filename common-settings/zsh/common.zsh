# 어느 맥에서나 쓰는 공통 셸 설정. ~/.zshrc 끝에서 source 한다.

# fzf: Ctrl+R 명령 기록 검색, Ctrl+T 파일 찾기, Alt+C 폴더 이동
command -v fzf >/dev/null && source <(fzf --zsh)

# git
alias gf='git fetch --all --prune'
alias gc='git checkout'
alias gr='git rebase'
alias gp='git push'
alias gpo='git pull origin'
alias gs='git stash'

# 기타
alias cl='clear'
alias c='caffeinate -dimsu codex --dangerously-bypass-approvals-and-sandbox'
alias cr='caffeinate -dimsu codex resume --dangerously-bypass-approvals-and-sandbox'

export VISUAL="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code --wait"
export EDITOR="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code --wait"
export PATH="$HOME/.local/bin:$PATH"

# pyenv
if command -v pyenv >/dev/null; then
  export PYENV_ROOT="$HOME/.pyenv"
  eval "$(pyenv init -)"
  command -v pyenv-virtualenv-init >/dev/null && eval "$(pyenv virtualenv-init -)"
fi

# nvm: 셸 시작을 늦추지 않도록 처음 부를 때 불러온다
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _node_bin="$(ls -d "$NVM_DIR"/versions/node/*/bin 2>/dev/null | sort -V | tail -1)"
  [ -n "$_node_bin" ] && export PATH="$_node_bin:$PATH"   # 설치된 가장 최신 node 를 먼저 잡는다
  unset _node_bin
  nvm() { unset -f nvm; \. "$NVM_DIR/nvm.sh"; nvm "$@"; }
fi
