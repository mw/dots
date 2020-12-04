export GOROOT=/usr/local/opt/go/libexec
export GOPATH=/Users/marc/.go/
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.7/site-packages
export PATH=/usr/local/go/bin:$PATH:$GOPATH/bin:/usr/local/sbin
export FZF_TMUX=1
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"

bwcopy() {
    query=$@;
    if [[ -z ${BW_SESSION} ]]; then
        export BW_SESSION=$(bw unlock --raw)
    fi
    if hash bw 2>/dev/null; then
        bw get item "$(bw list items | jq '.[] | "\(.name) | username: \(.login.username) | id: \(.id)"' | sed 's/\"//g' | fzf-tmux -q "$query" | awk '{print $(NF)}' | sed 's/\"//g')" | jq -j '.login.password' | pbcopy
    fi
}
