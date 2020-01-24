autoload -Uz zmv
autoload -Uz vcs_info
autoload -Uz promptinit && promptinit
autoload -Uz compinit && compinit
autoload -Uz colors && colors

setopt c_bases
setopt rmstarsilent
setopt autocd
setopt extendedglob
setopt complete_in_word
setopt hist_save_no_dups
setopt hist_ignore_space
setopt extended_history
setopt inc_append_history
setopt list_packed
setopt octal_zeroes
setopt promptsubst
setopt autopushd pushdminus pushdsilent pushdtohome

set -o emacs

zstyle ':vcs_info:*' enable git hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr "%{$fg[blue]%} ⊕%{$reset_color%}"
zstyle ':vcs_info:*' unstagedstr "%{$fg[cyan]%}⊖%{$reset_color%}"
zstyle ':vcs_info:*' formats "%u%c %b"
zstyle ':vcs_info:*' actionformats "%u%c %b (%a)"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*:(all-|)files' ignored-patterns '(|*/)CVS'

zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

zstyle ':completion:*' list-colors no=00 fi=00 di=01\;34 pi=33 so=01\;35 bd=00\;35 cd=00\;34 or=00\;41 mi=00\;45 ex=01\;32
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'

zstyle ':completion:*:cd:*' ignored-patterns '(*/)#CVS'
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

export SHELL=zsh
export SVN_EDITOR=vim
export EDITOR=vim
export DIRSTACKSIZE=8
export CLICOLOR=1
export LSCOLORS=dxfxcxdxbxegedabagacad

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.history

bindkey "\e[A" up-line-or-search
bindkey "\e[B" down-line-or-search

export LANG=en_US.utf-8
export LC_ALL=en_US.utf-8
export LD_LIBRARY_PATH=~/lib:$PATH
export C_INCLUDE_PATH=~/include:$PATH
export CXX_INCLUDE_PATH=~/include:$PATH
export PATH=~/bin:~/.cargo/bin:/usr/local/bin:/usr/local/share/npm/bin:$PATH
export RUST_SRC_PATH=~/Vendor/rust/src/

local WORDCHARS=${WORDCHARS//\//}

alias l='ls'
alias s='ls'
alias sl='ls'
alias less='less -R'
alias g='grep -Isi --color'
alias z='_z'
fn() { find . -name "$**"; }

logcheck=30
stty start ""
stty stop ""

local zsh_path="$HOME/dots/zsh"
for file ($zsh_path/*.{z,}sh(N))
    source $file

local hostname=$(hostname)
if [[ -f "$zsh_path/hosts/$hostname.zsh" ]]; then
    source "$zsh_path/hosts/$hostname.zsh"
fi

if [[ -f .localenv.sh ]]; then
    source .localenv.sh
fi

function screen_set() {
    if [[ $TERM == "screen" ]]; then
        print -nR $'\033k'$1$'\033'\\$'\033]0;'$1$'\a'
    fi
}


source ~/dots/zsh/z.sh

function preexec() {
    local -a cmd; cmd=(${(z)1})
    tab_name=$cmd[1]:t
    screen_set $tab_name
    z --add "$(pwd -P)"
}

function precmd() {
    screen_set $PWD:t
    vcs_info
}

promptinit

PROMPT=' %{$fg[cyan]%}%1/%{$reset_color%}%{$fg_bold[white]%} › %{$reset_color%}'
RPROMPT='%(?.. %? ↵ )% %{$fg[blue]%} ${vcs_info_msg_0_} %{$reset_color%}'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
