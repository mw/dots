alias g='grep -Isi --color'
alias ls='exa'
source $HOME/.cargo/env>/dev/null
export LOCALE_ARCHIVE=/lib/locale/locale-archive
export PATH=$PATH:~/.local/bin
export FZF_TMUX=1
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"

bwcopy() {
    if [[ -z ${BW_SESSION} ]]; then
        export BW_SESSION=$(bw unlock --raw)
    fi
    if hash bw 2>/dev/null; then
        export DISPLAY=:0.0
        bw get item "$(bw list items | jq '.[] | "\(.name) | username: \(.login.username) | id: \(.id)" ' | fzf-tmux | awk '{print $(NF -0)}' | sed 's/\"//g')" | jq -j '.login.password' | xclip
    fi
}
