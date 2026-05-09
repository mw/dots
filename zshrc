autoload -Uz zmv
autoload -Uz vcs_info
autoload -Uz compinit && compinit
autoload -Uz colors && colors
autoload -Uz edit-command-line

zle -N edit-command-line

set -o emacs

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

bindkey "^x^e" edit-command-line

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.history

bindkey "\e[A" up-line-or-search
bindkey "\e[B" down-line-or-search

local WORDCHARS=${WORDCHARS//\//}

alias clip="base64 | tr -d '\n' | awk '{printf \"\033Ptmux;\033\033]52;c;%s\033\\\\\", \$0}'"
alias py="uv run --python 3.12 python"
codex() {
    local dir=$(pwd)
    local override
    local q='"'
    printf -v override 'projects={"%s"={trust_level="trusted"}}' "${dir//$q/\"}"
    nix shell nixpkgs#bun --command bunx -y @openai/codex \
        -c "$override" \
        "$@"
}
wscodex() {
    local ws=$1
    shift
    local ws_root=$(jj root 2>/dev/null)
    local repo_root=$ws_root
    if [[ -f "$ws_root/.jj/repo" ]]; then
        # In a workspace: follow .jj/repo pointer to find the actual repo root.
        repo_root=$(cd "$ws_root/.jj" && cd "$(<repo)" && pwd)
        repo_root=${repo_root:h:h}
    fi
    local dest="$repo_root/.workspace/$ws"
    mkdir -p "$repo_root/.workspace"
    local sock="$PWD/.nvim.sock"
    jj workspace-add "$dest" && cd "$dest" || return
    [[ -e "$sock" && ! -e .nvim.sock ]] && ln -s "$sock" .nvim.sock
    codex "$@"
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
else
    echo "nix not found"
fi
if command -v lsd &> /dev/null; then
    alias ls=lsd
fi
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
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
    _tmux_set_worktree_name() {
        local fallback=${${SHELL##*/}:-zsh}
        local -a worktrees=(
            ${(M)${(f)"$(git -C "$PWD" worktree list --porcelain 2>/dev/null)"}:#worktree *}
        )
        local -a workspaces=(
            ${(f)"$(jj workspace list --ignore-working-copy --no-pager -T 'name ++ "\n"' 2>/dev/null)"}
        )
        (( ${#worktrees} > 1 || ${#workspaces} > 1 )) && {
            tmux rename-window -t "$TMUX_PANE" "${PWD:t}"
            return
        }
        tmux rename-window -t "$TMUX_PANE" "$fallback"
    }
    add-zsh-hook precmd _tmux_set_worktree_name
fi
if command -v fzf-share &> /dev/null; then
    fzf_keys=$(fzf-share)/key-bindings.zsh
    if [[ -e ${fzf_keys} ]]; then
        source ${fzf_keys}
    fi
fi
