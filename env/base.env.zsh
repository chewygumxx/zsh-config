#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/env/base.env.zsh
#
#

#
# Sister of ~/.config/environment.d/base.conf
#

export path=(
    "$HOME/.local/bin"
    "$XDG_DATA_HOME/cargo/bin"
    "$XDG_DATA_HOME/go/bin"
    "${path[@]}"
)
export PAGER="less"
export BROWSER="firefox"
export TERMCMD="wezterm"
export EDITOR="nvim"
export VISUAL="$EDITOR"

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
