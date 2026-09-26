# Codex 모듈만 설치해도 세션 명령과 외부 편집기를 사용할 수 있다.
export PATH="$HOME/.local/bin:$PATH"
alias c='caffeinate -dimsu codex --dangerously-bypass-approvals-and-sandbox'
alias cr='caffeinate -dimsu codex resume --dangerously-bypass-approvals-and-sandbox'
export VISUAL='mac-init-editor'
export EDITOR='mac-init-editor'
