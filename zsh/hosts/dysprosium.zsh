alias g='grep -Isi --color'
alias ls='ls --color'
export PATH=$PATH:~/Code/engtools/
export PATH=~/.go/bin:/usr/local/go/bin/:$PATH
export STAGE=~/Code/depot/build/stage
export GOPATH=~/.go:~/Code/depot/vendor/golibs:~/Code/depot/extrahop/go
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/rustlib/x86_64-unknown-linux-gnu/lib/
source $HOME/.cargo/env>/dev/null
eval $(ssh-agent)>/dev/null
