autoload -Uz zmv
autoload -Uz vcs_info
autoload -Uz compinit && compinit
autoload -Uz colors && colors

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
zstyle ':completion:*' list-colors no=00 fi=00 di=01\;34 pi=33 so=01\;35 bd=00\;35 cd=00\;34 or=00\;41 mi=00\;45 ex=01\;32
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:killall:*' menu yes select
zstyle ':completion:*:killall:*' command 'ps --forest -u $USER -o cmd'
zstyle ':completion:*:descriptions' format '%U%d%u'
zstyle ':completion:*:warnings' format '%Bno matches for: %d%b'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:xdvi:*' menu yes select
zstyle ':completion:*:*:xdvi:*' file-sort time
zstyle ':completion:*:rm:*' ignore-line yes
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~' '*?.old' '*?.pro'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'

zstyle :compinstall filename "$HOME/.zshrc"

export EDITOR=nvim
export DIRSTACKSIZE=8
export CLICOLOR=1
export LSCOLORS=dxfxcxdxbxegedabagacad
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export BAT_STYLE=plain
export FZF_DEFAULT_COMMAND='rg --files'

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.history

bindkey "\e[A" up-line-or-search
bindkey "\e[B" down-line-or-search

local WORDCHARS=${WORDCHARS//\//}

logcheck=30
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
if command -v fzf-share &> /dev/null; then
    fzf_keys=$(fzf-share)/key-bindings.zsh
    if [[ -e ${fzf_keys} ]]; then
        source ${fzf_keys}
    fi
fi
