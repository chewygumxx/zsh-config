#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only
#
#
# ~chewygumxx/dotfiles.git
# ::: :/home/dot_config/zsh/util/systemd.rc.zsh
#
#
[[ -o interactive        ]] || return
(( $+commands[systemctl] )) || return

setopt aliases

alias sysu="systemctl --user"

hash -d sysu="$XDG_CONFIG_HOME/systemd/user"
hash -d envd="$XDG_CONFIG_HOME/environment.d"
