#!/bin/false
# vim: expandtab:shiftwidth=4

# 
# 
# ~/.config/zsh/rc/util/systemd.rc.zsh
# 
# 

[[ -o interactive        ]] || return
(( $+commands[systemctl] )) || return

setopt aliases

alias sysu="systemctl --user"

hash -d sysu="$XDG_CONFIG_HOME/systemd/user"
hash -d envd="$XDG_CONFIG_HOME/environment.d"
