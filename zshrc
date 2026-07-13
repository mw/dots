autoload -Uz zmv
autoload -Uz vcs_info
autoload -Uz compinit
autoload -Uz colors && colors
autoload -Uz edit-command-line

zle -N edit-command-line

set -o emacs

if [[ -n ~/.zcompdump(#qNmh-24) ]]; then
  compinit -C
else
  compinit
fi

setopt c_bases
setopt rmstarsilent
setopt autocd
setopt complete_in_word
setopt hist_save_no_dups
setopt hist_ignore_space
setopt extended_history
setopt inc_append_history
setopt list_packed
setopt octal_zeroes
setopt promptsubst
setopt autopushd pushdminus pushdsilent pushdtohome

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST
zstyle :compinstall filename "$HOME/.zshrc"

export EDITOR=nvim
export DIRSTACKSIZE=8
export CLICOLOR=1
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BAT_STYLE=plain
export FZF_DEFAULT_COMMAND='rg --files'
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#506080"
export UV_FROZEN=1

bindkey "^x^e" edit-command-line

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.history

bindkey "\e[A" up-line-or-search
bindkey "\e[B" down-line-or-search

local WORDCHARS=${WORDCHARS//[\/#]}

alias clip="base64 | tr -d '\n' | awk '{printf \"\033Ptmux;\033\033]52;c;%s\033\\\\\", \$0}'"
alias py="uv run --python 3.12 python"
pi() {
    pnpm dlx --config.ignore-scripts=true \
        --config.minimum-release-age=2880 -y \
        @earendil-works/pi-coding-agent "$@"
}
codex() {
    local dir=$(pwd)
    local override
    local q='"'
    printf -v override 'projects={"%s"={trust_level="trusted"}}' "${dir//$q/\"}"
    pnpm dlx -y @openai/codex -c "$override" "$@"
}

stty start ""
stty stop ""

function preexec() {
    local -a cmd; cmd=(${(z)1})
    tab_name=$cmd[1]:t
}

if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

if [ -e ${HOME}/.nix-profile/etc/profile.d/nix.sh ]; then
    source ${HOME}/.nix-profile/etc/profile.d/nix.sh;
elif [ -e /etc/profile.d/nix.sh ]; then
    source /etc/profile.d/nix.sh;
fi
if command -v nix &> /dev/null; then
    nix profile list | grep 'basepkgs' >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        nix profile install ${HOME}/dots#basepkgs
    fi
    export TERMINFO_DIRS=${HOME}/.nix-profile/share/terminfo
    export MSB_PATH=$(command -v msb)
else
    echo "nix not found"
fi
if command -v lsd &> /dev/null; then
    alias ls=lsd
fi
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi
autoload -Uz add-zsh-hook
zmodload zsh/datetime

typeset -gF _prompt_cmd_start=0

prompt_preexec() {
    _prompt_cmd_start=$EPOCHREALTIME
}

_prompt_jj_segment() {
    jj --ignore-working-copy root >/dev/null 2>&1 || return 1
    jj log --revisions @ --no-graph --ignore-working-copy \
        --color always --limit 1 --template '
      separate(" ",
        change_id.shortest(4),
        bookmarks,
        concat(
          if(conflict, "󰞇 "),
          if(divergent, ""),
          if(hidden, "󰘓 "),
          if(immutable, ""),
          if(empty, "ø ")
        ),
      )
    ' 2>/dev/null
}

prompt_precmd() {
    local exit_code=$?

    local vcs=""
    local jj_out=$(_prompt_jj_segment)
    [[ -n $jj_out ]] && vcs=" $jj_out"

    local duration=""
    if (( _prompt_cmd_start > 0 )); then
        local elapsed=$(( EPOCHREALTIME - _prompt_cmd_start ))
        _prompt_cmd_start=0
        if (( elapsed >= 2.0 )); then
            local secs=$(( elapsed + 0.5 ))
            secs=${secs%%.*}
            duration=" %F{yellow}took ${secs}s%f"
        fi
    fi

    local jobs_str=""
    local jn=$(jobs -l 2>/dev/null | wc -l)
    if (( jn > 0 )); then
        jobs_str="%F{blue}✦${jn}%f "
    fi

    local status_str=""
    (( exit_code != 0 )) && status_str="%F{red}✗%f "

    local p1=$'\n%F{cyan}%~%f'"${vcs}${duration}"
    local p2=$'\n'"${jobs_str}${status_str}%F{green}❯%f "
    PROMPT="${p1}${p2}"
    PS2="%F{green}❯%f "
}

add-zsh-hook preexec prompt_preexec
add-zsh-hook precmd prompt_precmd

if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi
if command -v ssh-agent &> /dev/null && [[ -z ${SSH_AUTH_SOCK:-} ]]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
    if ! ssh-add -l >/dev/null 2>&1; then
        [ -S "$SSH_AUTH_SOCK" ] && rm "$SSH_AUTH_SOCK"
        eval "$(ssh-agent -a "$SSH_AUTH_SOCK")" >/dev/null
    fi
fi
if [[ -f ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.nix-profile/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [[ -f ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.nix-profile/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if [[ -n $TMUX ]]; then
    _tmux_set_window_name() {
        local name=${${PWD/#$HOME/'~'}:t}
        tmux rename-window -t "$TMUX_PANE" "$name"
    }
    add-zsh-hook precmd _tmux_set_window_name
fi
if command -v fzf-share &> /dev/null; then
    fzf_keys=$(fzf-share)/key-bindings.zsh
    if [[ -e ${fzf_keys} ]]; then
        source ${fzf_keys}
    fi
fi
