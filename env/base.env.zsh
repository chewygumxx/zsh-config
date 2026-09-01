#!/bin/false
# vim: expandtab:shiftwidth=4

# 
# 
# ~/.config/zsh/env/base.env.zsh
# 
# 

#
# Sister of ~/.config/environment.d/base.conf
#

path+=(
    "$HOME/.local/bin"
)
export PAGER="less"
export BROWSER="firefox"
export TERMCMD="wezterm"
export EDITOR="nvim"
export VISUAL="$EDITOR"

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
