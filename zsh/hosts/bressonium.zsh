alias g='grep -Isi --color'
alias ls='exa'
export PATH=$PATH:~/Code/engtools/exreview:~/Code/ehit/packages/ehit-atlas-tools/src/
export PATH=~/.go/bin:~/.local/bin:/usr/local/go/bin/:$PATH
export STAGE=~/Code/depot/build/stage
export GOPATH=~/.go:~/Code/depot/vendor/golibs:~/Code/depot/extrahop/go
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/rustlib/x86_64-unknown-linux-gnu/lib/
export DISPLAY=:0.0
export PYTHONPATH=$HOME/.python
source $HOME/.cargo/env>/dev/null
eval $(ssh-agent)>/dev/null
