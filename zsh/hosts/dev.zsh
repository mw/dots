alias ls='exa'
source $HOME/.cargo/env>/dev/null
export PATH=~/.local/bin:~/go/bin:$PATH
export FZF_TMUX=1
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
