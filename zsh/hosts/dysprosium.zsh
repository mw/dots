alias g='grep -Isi --color'
alias ls='ls --color'
export PATH=$PATH:~/Code/engtools/
export STAGE=~/Code/depot/build/stage
export GOPATH=~/Code/depot/vendor/golibs:~/Code/depot/extrahop/go
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/rustlib/x86_64-unknown-linux-gnu/lib/

eval $(ssh-agent)>/dev/null
